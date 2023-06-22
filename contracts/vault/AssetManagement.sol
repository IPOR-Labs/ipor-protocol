// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.20;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/IERC20MetadataUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@ipor-protocol/contracts/interfaces/IProxyImplementation.sol";
import "@ipor-protocol/contracts/interfaces/IIvToken.sol";
import "@ipor-protocol/contracts/interfaces/IStrategy.sol";
import "@ipor-protocol/contracts/interfaces/IAssetManagementInternal.sol";
import "@ipor-protocol/contracts/interfaces/IAssetManagement.sol";
import "@ipor-protocol/contracts/libraries/Constants.sol";
import "@ipor-protocol/contracts/libraries/math/IporMath.sol";
import "@ipor-protocol/contracts/libraries/errors/IporErrors.sol";
import "@ipor-protocol/contracts/libraries/errors/AssetManagementErrors.sol";
import "@ipor-protocol/contracts/security/IporOwnableUpgradeable.sol";
import "@ipor-protocol/contracts/security/PauseManager.sol";

/// @title AssetManagement represents Asset Management module responsible for investing AmmTreasury's cash in external DeFi protocols.
abstract contract AssetManagement is
    Initializable,
    PausableUpgradeable,
    ReentrancyGuardUpgradeable,
    UUPSUpgradeable,
    IporOwnableUpgradeable,
    IAssetManagement,
    IAssetManagementInternal,
    IProxyImplementation
{
    using SafeERC20Upgradeable for IERC20Upgradeable;

    address internal _asset;
    IIvToken internal _ivToken;

    address internal _ammTreasury;
    address internal _strategyAave;
    address internal _strategyCompound;

    modifier onlyAmmTreasury() {
        require(_msgSender() == _ammTreasury, IporErrors.CALLER_NOT_AMM_TREASURY);
        _;
    }

    modifier onlyPauseGuardian() {
        require(PauseManager.isPauseGuardian(_msgSender()), IporErrors.CALLER_NOT_GUARDIAN);
        _;
    }

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    /**
     * @dev Deploy IPORVault.
     * @notice Deploy IPORVault.
     * @param asset underlying token like DAI, USDT etc.
     */
    function initialize(
        address asset,
        address ivToken,
        address strategyAave,
        address strategyCompound
    ) public initializer {
        __Pausable_init();
        __Ownable_init();
        __UUPSUpgradeable_init();

        require(asset != address(0), IporErrors.WRONG_ADDRESS);
        require(ivToken != address(0), IporErrors.WRONG_ADDRESS);
        require(_getDecimals() == IERC20MetadataUpgradeable(asset).decimals(), IporErrors.WRONG_DECIMALS);

        IIvToken iivToken = IIvToken(ivToken);
        require(asset == iivToken.getAsset(), IporErrors.ADDRESSES_MISMATCH);

        _asset = asset;
        _ivToken = iivToken;

        _strategyAave = _setStrategy(_strategyAave, strategyAave);
        _strategyCompound = _setStrategy(_strategyCompound, strategyCompound);
    }

    function getVersion() external pure override returns (uint256) {
        return 2_000;
    }

    function getAsset() external view override returns (address) {
        return _asset;
    }

    function getIvToken() external view returns (address) {
        return address(_ivToken);
    }

    function getAmmTreasury() external view override returns (address) {
        return _ammTreasury;
    }

    function getStrategyAave() external view override returns (address) {
        return _strategyAave;
    }

    function getStrategyCompound() external view override returns (address) {
        return _strategyCompound;
    }

    function totalBalance(address who) external view override returns (uint256) {
        return _totalBalance(who);
    }

    function calculateExchangeRate() external view override returns (uint256 exchangeRate) {
        IStrategy strategyAave = IStrategy(_strategyAave);
        IStrategy strategyCompound = IStrategy(_strategyCompound);
        (, exchangeRate, , ) = _calcExchangeRate(strategyAave, strategyCompound);
    }

    /**
     * @dev to deposit asset in higher apy strategy.
     * @notice only AmmTreasury can deposit
     * @param amount underlying token amount represented in 18 decimals
     */
    function deposit(
        uint256 amount
    ) external override whenNotPaused onlyAmmTreasury returns (uint256 vaultBalance, uint256 depositedAmount) {
        require(amount > 0, IporErrors.VALUE_NOT_GREATER_THAN_ZERO);
        uint256 assetAmount = IporMath.convertWadToAssetDecimals(amount, _getDecimals());
        require(assetAmount > 0, IporErrors.VALUE_NOT_GREATER_THAN_ZERO);

        (address strategyMaxApy, address strategyAaveAddr, address strategyCompoundAddr) = _getMaxApyStrategy();

        (
            ,
            uint256 exchangeRate,
            uint256 assetBalanceAaveStrategy,
            uint256 assetBalanceCompoundStrategy
        ) = _calcExchangeRate(IStrategy(strategyAaveAddr), IStrategy(strategyCompoundAddr));

        uint256 ivTokenAmount = IporMath.division(amount * 1e18, exchangeRate);

        IERC20Upgradeable(_asset).safeTransferFrom(_msgSender(), address(this), assetAmount);

        depositedAmount = IStrategy(strategyMaxApy).deposit(amount);

        _ivToken.mint(_msgSender(), ivTokenAmount);

        emit Deposit(block.timestamp, _msgSender(), strategyMaxApy, exchangeRate, depositedAmount, ivTokenAmount);

        vaultBalance = assetBalanceAaveStrategy + assetBalanceCompoundStrategy + depositedAmount;
    }

    function withdraw(
        uint256 amount
    ) external override whenNotPaused onlyAmmTreasury returns (uint256 withdrawnAmount, uint256 vaultBalance) {
        require(amount > 0, IporErrors.VALUE_NOT_GREATER_THAN_ZERO);

        IIvToken ivToken = _ivToken;
        IERC20Upgradeable asset = IERC20Upgradeable(_asset);
        IStrategy strategyAave = IStrategy(_strategyAave);
        IStrategy strategyCompound = IStrategy(_strategyCompound);

        (
            uint256 ivTokenTotalSupply,
            ,
            uint256 assetBalanceAaveStrategy,
            uint256 assetBalanceCompoundStrategy
        ) = _calcExchangeRate(strategyAave, strategyCompound);

        uint256 senderIvTokens = ivToken.balanceOf(_msgSender());

        (address selectedStrategy, uint256 selectedWithdrawAmount, ) = _selectStrategyAndWithdrawAmount(
            amount,
            assetBalanceAaveStrategy,
            assetBalanceCompoundStrategy
        );

        if (selectedWithdrawAmount > 0) {
            //Transfer from Strategy to AssetManagement
            uint256 ivTokenWithdrawnAmount;
            (ivTokenWithdrawnAmount, vaultBalance) = _withdrawFromStrategy(
                selectedStrategy,
                selectedWithdrawAmount,
                ivTokenTotalSupply,
                strategyAave,
                strategyCompound
            );

            if (ivTokenWithdrawnAmount > senderIvTokens) {
                ivToken.burn(_msgSender(), senderIvTokens);
            } else {
                ivToken.burn(_msgSender(), ivTokenWithdrawnAmount);
            }

            uint256 assetBalanceAssetManagement = asset.balanceOf(address(this));

            if (assetBalanceAssetManagement > 0) {
                //Always transfer all assets from AssetManagement to AmmTreasury
                asset.safeTransfer(_msgSender(), assetBalanceAssetManagement);
                withdrawnAmount = IporMath.convertToWad(assetBalanceAssetManagement, _getDecimals());
            }
        }

        return (withdrawnAmount, vaultBalance);
    }

    function withdrawAll()
        external
        override
        whenNotPaused
        onlyAmmTreasury
        returns (uint256 withdrawnAmount, uint256 vaultBalance)
    {
        address msgSender = _msgSender();
        IIvToken ivToken = _ivToken;
        IERC20Upgradeable asset = IERC20Upgradeable(_asset);
        IStrategy strategyAave = IStrategy(_strategyAave);
        IStrategy strategyCompound = IStrategy(_strategyCompound);

        (
            uint256 ivTokenTotalSupply,
            ,
            uint256 assetBalanceAaveStrategy,
            uint256 assetBalanceCompoundStrategy
        ) = _calcExchangeRate(strategyAave, strategyCompound);

        uint256 assetBalanceStrategiesSum = assetBalanceAaveStrategy + assetBalanceCompoundStrategy;

        if (assetBalanceStrategiesSum > 0) {
            if (assetBalanceAaveStrategy > 0) {
                (, vaultBalance) = _withdrawFromStrategy(
                    _strategyAave,
                    assetBalanceAaveStrategy,
                    ivTokenTotalSupply,
                    strategyAave,
                    strategyCompound
                );
            }

            if (assetBalanceCompoundStrategy > 0) {
                (, vaultBalance) = _withdrawFromStrategy(
                    _strategyCompound,
                    assetBalanceCompoundStrategy,
                    ivTokenTotalSupply,
                    strategyAave,
                    strategyCompound
                );
            }
        }

        ivToken.burn(msgSender, ivToken.balanceOf(msgSender));

        uint256 assetBalanceAssetManagement = asset.balanceOf(address(this));

        //Always transfer all assets from AssetManagement to AmmTreasury
        asset.safeTransfer(msgSender, assetBalanceAssetManagement);

        withdrawnAmount = IporMath.convertToWad(assetBalanceAssetManagement, _getDecimals());
    }

    function migrateAssetToStrategyWithMaxApy() external whenNotPaused onlyOwner {
        (address strategyMaxApy, address strategyAave, address strategyCompound) = _getMaxApyStrategy();

        address from;

        if (strategyMaxApy == strategyAave) {
            from = strategyCompound;
            uint256 assetAmount = IStrategy(strategyCompound).balanceOf();
            require(assetAmount > 0, IporErrors.VALUE_NOT_GREATER_THAN_ZERO);
            IStrategy(strategyCompound).withdraw(assetAmount);
        } else {
            from = strategyAave;
            uint256 assetAmount = IStrategy(strategyAave).balanceOf();
            require(assetAmount > 0, IporErrors.VALUE_NOT_GREATER_THAN_ZERO);
            IStrategy(strategyAave).withdraw(assetAmount);
        }

        /// @dev Temporary on AssetManagement wallet.
        uint256 assetManagementAssetAmount = IERC20Upgradeable(_asset).balanceOf(address(this));
        uint256 wadAssetManagementAssetAmount = IporMath.convertToWad(assetManagementAssetAmount, _getDecimals());
        IStrategy(strategyMaxApy).deposit(wadAssetManagementAssetAmount);

        emit AssetMigrated(address(strategyMaxApy), wadAssetManagementAssetAmount);
    }

    function setStrategyAave(address newStrategyAddr) external override whenNotPaused onlyOwner {
        _strategyAave = _setStrategy(_strategyAave, newStrategyAddr);
    }

    function setStrategyCompound(address newStrategyAddr) external override whenNotPaused onlyOwner {
        _strategyCompound = _setStrategy(_strategyCompound, newStrategyAddr);
    }

    function setAmmTreasury(address newAmmTreasury) external override whenNotPaused onlyOwner {
        require(newAmmTreasury != address(0), IporErrors.WRONG_ADDRESS);
        _ammTreasury = newAmmTreasury;
        emit AmmTreasuryChanged(newAmmTreasury);
    }

    function pause() external override onlyPauseGuardian {
        _pause();
    }

    function unpause() external override onlyOwner {
        _unpause();
    }

    function getImplementation() external view override returns (address) {
        return StorageSlotUpgradeable.getAddressSlot(_IMPLEMENTATION_SLOT).value;
    }

    function _getDecimals() internal pure virtual returns (uint256);

    // Find highest apy strategy to deposit underlying asset
    function _getMaxApyStrategy()
        internal
        view
        returns (address strategyMaxApy, address strategyAave, address strategyCompound)
    {
        strategyAave = _strategyAave;
        strategyCompound = _strategyCompound;
        strategyMaxApy = strategyAave;

        if (IStrategy(strategyAave).getApy() < IStrategy(strategyCompound).getApy()) {
            strategyMaxApy = strategyCompound;
        } else {
            strategyMaxApy = strategyAave;
        }
    }

    function _totalBalance(address who) internal view returns (uint256) {
        IStrategy strategyAave = IStrategy(_strategyAave);
        IStrategy strategyCompound = IStrategy(_strategyCompound);
        (, uint256 exchangeRate, , ) = _calcExchangeRate(strategyAave, strategyCompound);
        return IporMath.division(_ivToken.balanceOf(who) * exchangeRate, 1e18);
    }

    function _setStrategy(
        address oldStrategyAddress,
        address newStrategyAddress
    ) internal nonReentrant returns (address) {
        require(newStrategyAddress != address(0), IporErrors.WRONG_ADDRESS);

        IERC20Upgradeable asset = IERC20Upgradeable(_asset);

        IStrategy newStrategy = IStrategy(newStrategyAddress);

        require(newStrategy.getAsset() == address(asset), AssetManagementErrors.ASSET_MISMATCH);

        IERC20Upgradeable newShareToken = IERC20Upgradeable(newStrategy.getShareToken());

        asset.safeApprove(newStrategyAddress, 0);
        asset.safeApprove(newStrategyAddress, type(uint256).max);

        newShareToken.safeApprove(newStrategyAddress, 0);
        newShareToken.safeApprove(newStrategyAddress, type(uint256).max);

        //when this is not initialize setup
        if (oldStrategyAddress != address(0)) {
            _transferFromOldToNewStrategy(oldStrategyAddress, newStrategyAddress);
            _revokeStrategyAllowance(oldStrategyAddress);
        }

        emit StrategyChanged(newStrategyAddress, address(newShareToken));

        return newStrategyAddress;
    }

    function _transferFromOldToNewStrategy(address oldStrategyAddress, address newStrategyAddress) internal {
        uint256 assetAmount = IStrategy(oldStrategyAddress).balanceOf();

        if (assetAmount > 0) {
            IStrategy(oldStrategyAddress).withdraw(assetAmount);
            uint256 assetManagementAssetAmount = IERC20Upgradeable(_asset).balanceOf(address(this));
            IStrategy(newStrategyAddress).deposit(IporMath.convertToWad(assetManagementAssetAmount, _getDecimals()));
        }
    }

    function _revokeStrategyAllowance(address strategyAddress) internal {
        IERC20Upgradeable(_asset).safeApprove(strategyAddress, 0);
        IERC20Upgradeable(IStrategy(strategyAddress).getShareToken()).safeApprove(strategyAddress, 0);
    }

    /**
     * @notice Withdraws asset amount from given strategyAddress to AssetManagement
     * @param selectedStrategyAddress strategy address
     * @param amount asset amount which will be withdraw from Strategy, represented in 18 decimals
     * @param ivTokenTotalSupply current IV Token total supply, represented in 18 decimals
     * @param strategyAave AAVE Strategy address
     * @param strategyCompound Compound Strategy address
     * @return ivTokenWithdrawnAmount final withdrawn IV Token amount, represented in 18 decimals
     */
    function _withdrawFromStrategy(
        address selectedStrategyAddress,
        uint256 amount,
        uint256 ivTokenTotalSupply,
        IStrategy strategyAave,
        IStrategy strategyCompound
    ) internal nonReentrant returns (uint256 ivTokenWithdrawnAmount, uint256 totalBalanceAmount) {
        if (amount > 0) {
            //Withdraw from Strategy to AssetManagement
            uint256 withdrawnAmount = IStrategy(selectedStrategyAddress).withdraw(amount);

            /// @dev when in future more strategies then change this calculation
            totalBalanceAmount = strategyAave.balanceOf() + strategyCompound.balanceOf();

            uint256 totalBalanceWithWithdrawnAmount = totalBalanceAmount + withdrawnAmount;

            uint256 exchangeRate;

            /// @dev after withdraw balance could change which influence on exchange rate
            /// so exchange rate have to be calculated again
            if (totalBalanceWithWithdrawnAmount == 0 || ivTokenTotalSupply == 0) {
                exchangeRate = 1e18;
            } else {
                exchangeRate = IporMath.division(totalBalanceWithWithdrawnAmount * 1e18, ivTokenTotalSupply);
            }

            ivTokenWithdrawnAmount = IporMath.division(withdrawnAmount * 1e18, exchangeRate);

            emit Withdraw(
                block.timestamp,
                selectedStrategyAddress,
                _msgSender(),
                exchangeRate,
                withdrawnAmount,
                ivTokenWithdrawnAmount
            );
        }
    }

    function _calcExchangeRate(
        IStrategy strategyAave,
        IStrategy strategyCompound
    )
        internal
        view
        returns (
            uint256 ivTokenTotalSupply,
            uint256 exchangeRate,
            uint256 assetBalanceAaveStrategy,
            uint256 assetBalanceCompoundStrategy
        )
    {
        assetBalanceAaveStrategy = strategyAave.balanceOf();
        assetBalanceCompoundStrategy = strategyCompound.balanceOf();

        uint256 totalAssetBalance = assetBalanceAaveStrategy + assetBalanceCompoundStrategy;

        ivTokenTotalSupply = _ivToken.totalSupply();

        if (totalAssetBalance == 0 || ivTokenTotalSupply == 0) {
            exchangeRate = 1e18;
        } else {
            exchangeRate = IporMath.division(totalAssetBalance * 1e18, ivTokenTotalSupply);
        }
    }

    function _selectStrategyAndWithdrawAmount(
        uint256 amount,
        uint256 assetBalanceAaveStrategy,
        uint256 assetBalanceCompoundStrategy
    ) internal view returns (address, uint256, uint256) {
        (address strategyMaxApy, address strategyAave, address strategyCompound) = _getMaxApyStrategy();

        if (strategyMaxApy == strategyCompound && amount <= assetBalanceAaveStrategy) {
            return (strategyAave, amount, assetBalanceAaveStrategy);
        } else if (amount <= assetBalanceCompoundStrategy) {
            return (strategyCompound, amount, assetBalanceCompoundStrategy);
        }

        if (strategyMaxApy == strategyAave && amount <= assetBalanceAaveStrategy) {
            return (strategyAave, amount, assetBalanceAaveStrategy);
        }

        if (assetBalanceAaveStrategy < assetBalanceCompoundStrategy) {
            return (strategyCompound, assetBalanceCompoundStrategy, assetBalanceCompoundStrategy);
        } else {
            return (strategyAave, assetBalanceAaveStrategy, assetBalanceAaveStrategy);
        }
    }

    //solhint-disable no-empty-blocks
    function _authorizeUpgrade(address) internal override onlyOwner {}

    function addPauseGuardian(address _guardian) external onlyOwner {
        PauseManager.addPauseGuardian(_guardian);
    }

    function removePauseGuardian(address _guardian) external onlyOwner {
        PauseManager.removePauseGuardian(_guardian);
    }
}

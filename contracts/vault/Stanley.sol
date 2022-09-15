// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.16;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/IERC20MetadataUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "../libraries/errors/IporErrors.sol";
import "../libraries/errors/StanleyErrors.sol";
import "../libraries/Constants.sol";
import "../libraries/math/IporMath.sol";
import "../interfaces/IIvToken.sol";
import "../interfaces/IStanleyInternal.sol";
import "../interfaces/IStanley.sol";
import "../interfaces/IStrategy.sol";
import "../security/IporOwnableUpgradeable.sol";

/// @title Stanley represents Asset Management module responsible for investing Milton's cash in external DeFi protocols.
abstract contract Stanley is
    Initializable,
    PausableUpgradeable,
    ReentrancyGuardUpgradeable,
    UUPSUpgradeable,
    IporOwnableUpgradeable,
    IStanley,
    IStanleyInternal
{
    using SafeERC20Upgradeable for IERC20Upgradeable;

    address internal _asset;
    IIvToken internal _ivToken;

    address internal _milton;
    address internal _strategyAave;
    address internal _strategyCompound;

    modifier onlyMilton() {
        require(_msgSender() == _milton, IporErrors.CALLER_NOT_MILTON);
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
        require(
            _getDecimals() == IERC20MetadataUpgradeable(asset).decimals(),
            IporErrors.WRONG_DECIMALS
        );

        IIvToken iivToken = IIvToken(ivToken);
        require(asset == iivToken.getAsset(), IporErrors.ADDRESSES_MISMATCH);

        _asset = asset;
        _ivToken = iivToken;

        _strategyAave = _setStrategy(_strategyAave, strategyAave);
        _strategyCompound = _setStrategy(_strategyCompound, strategyCompound);
    }

    function getVersion() external pure override returns (uint256) {
        return 2;
    }

    function getAsset() external view override returns (address) {
        return _asset;
    }

    function getMilton() external view override returns (address) {
        return _milton;
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
     * @notice only owner can deposit.
     * @param amount underlying token amount represented in 18 decimals
     */
    function deposit(uint256 amount)
        external
        override
        whenNotPaused
        onlyMilton
        returns (uint256 vaultBalance, uint256 depositedAmount)
    {
        require(amount > 0, IporErrors.VALUE_NOT_GREATER_THAN_ZERO);
        uint256 assetAmount = IporMath.convertWadToAssetDecimals(amount, _getDecimals());
        require(assetAmount > 0, IporErrors.VALUE_NOT_GREATER_THAN_ZERO);

        (
            address strategyMaxApy,
            address strategyAaveAddr,
            address strategyCompoundAddr
        ) = _getMaxApyStrategy();

        (
            ,
            uint256 exchangeRate,
            uint256 assetBalanceAaveStrategy,
            uint256 assetBalanceCompoundStrategy
        ) = _calcExchangeRate(IStrategy(strategyAaveAddr), IStrategy(strategyCompoundAddr));

        uint256 ivTokenAmount = IporMath.division(amount * Constants.D18, exchangeRate);

        IERC20Upgradeable(_asset).safeTransferFrom(_msgSender(), address(this), assetAmount);

        depositedAmount = IStrategy(strategyMaxApy).deposit(amount);

        _ivToken.mint(_msgSender(), ivTokenAmount);

        emit Deposit(
            block.timestamp,
            _msgSender(),
            strategyMaxApy,
            exchangeRate,
            depositedAmount,
            ivTokenAmount
        );

        vaultBalance = assetBalanceAaveStrategy + assetBalanceCompoundStrategy + depositedAmount;
    }

    function withdraw(uint256 amount)
        external
        override
        whenNotPaused
        onlyMilton
        returns (uint256 withdrawnAmount, uint256 vaultBalance)
    {
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

        (
            address selectedStrategy,
            uint256 selectedWithdrawAmount,

        ) = _selectStrategyAndWithdrawAmount(
                amount,
                assetBalanceAaveStrategy,
                assetBalanceCompoundStrategy
            );

        if (selectedWithdrawAmount > 0) {
            //Transfer from Strategy to Stanley
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

            uint256 assetBalanceStanley = asset.balanceOf(address(this));

            if (assetBalanceStanley > 0) {
                //Always transfer all assets from Stanley to Milton
                asset.safeTransfer(_msgSender(), assetBalanceStanley);
                withdrawnAmount = IporMath.convertToWad(assetBalanceStanley, _getDecimals());
            }
        }

        return (withdrawnAmount, vaultBalance);
    }

    function withdrawAll()
        external
        override
        whenNotPaused
        onlyMilton
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

        uint256 assetBalanceStanley = asset.balanceOf(address(this));

        //Always transfer all assets from Stanley to Milton
        asset.safeTransfer(msgSender, assetBalanceStanley);

        withdrawnAmount = IporMath.convertToWad(assetBalanceStanley, _getDecimals());
    }

    function migrateAssetToStrategyWithMaxApr() external whenNotPaused onlyOwner {
        (
            address strategyMaxApy,
            address strategyAave,
            address strategyCompound
        ) = _getMaxApyStrategy();

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

        /// @dev Temporary on Stanley wallet.
        uint256 stanleyAssetAmount = IERC20Upgradeable(_asset).balanceOf(address(this));
        uint256 wadStanleyAssetAmount = IporMath.convertToWad(stanleyAssetAmount, _getDecimals());
        IStrategy(strategyMaxApy).deposit(wadStanleyAssetAmount);

        emit AssetMigrated(_msgSender(), from, address(strategyMaxApy), wadStanleyAssetAmount);
    }

    function setStrategyAave(address newStrategyAddr) external override whenNotPaused onlyOwner {
        _strategyAave = _setStrategy(_strategyAave, newStrategyAddr);
    }

    function setStrategyCompound(address newStrategyAddr)
        external
        override
        whenNotPaused
        onlyOwner
    {
        _strategyCompound = _setStrategy(_strategyCompound, newStrategyAddr);
    }

    function setMilton(address newMilton) external override whenNotPaused onlyOwner {
        require(newMilton != address(0), IporErrors.WRONG_ADDRESS);
        address oldMilton = _milton;
        _milton = newMilton;
        emit MiltonChanged(_msgSender(), oldMilton, newMilton);
    }

    function pause() external override onlyOwner {
        _pause();
    }

    function unpause() external override onlyOwner {
        _unpause();
    }

    function _getDecimals() internal pure virtual returns (uint256);

    // Find highest apy strategy to deposit underlying asset
    function _getMaxApyStrategy()
        internal
        view
        returns (
            address strategyMaxApy,
            address strategyAave,
            address strategyCompound
        )
    {
        strategyAave = _strategyAave;
        strategyCompound = _strategyCompound;
        strategyMaxApy = strategyAave;

        if (IStrategy(strategyAave).getApr() < IStrategy(strategyCompound).getApr()) {
            strategyMaxApy = strategyCompound;
        } else {
            strategyMaxApy = strategyAave;
        }
    }

    function _totalBalance(address who) internal view returns (uint256) {
        IStrategy strategyAave = IStrategy(_strategyAave);
        IStrategy strategyCompound = IStrategy(_strategyCompound);
        (, uint256 exchangeRate, , ) = _calcExchangeRate(strategyAave, strategyCompound);
        return IporMath.division(_ivToken.balanceOf(who) * exchangeRate, Constants.D18);
    }

    function _setStrategy(address oldStrategyAddr, address newStrategyAddr)
        internal
        nonReentrant
        returns (address)
    {
        require(newStrategyAddr != address(0), IporErrors.WRONG_ADDRESS);

        IERC20Upgradeable asset = IERC20Upgradeable(_asset);

        IStrategy newStrategy = IStrategy(newStrategyAddr);

        require(newStrategy.getAsset() == address(asset), StanleyErrors.ASSET_MISMATCH);

        IERC20Upgradeable newShareToken = IERC20Upgradeable(newStrategy.getShareToken());

        asset.safeApprove(newStrategyAddr, 0);
        asset.safeApprove(newStrategyAddr, type(uint256).max);

        newShareToken.safeApprove(newStrategyAddr, 0);
        newShareToken.safeApprove(newStrategyAddr, type(uint256).max);

        //when first initialization then old
        if (oldStrategyAddr != address(0)) {
            uint256 assetAmount = IStrategy(oldStrategyAddr).balanceOf();

            require(assetAmount > 0, IporErrors.VALUE_NOT_GREATER_THAN_ZERO);

            IStrategy(oldStrategyAddr).withdraw(assetAmount);

            uint256 stanleyAssetAmount = asset.balanceOf(address(this));

            IStrategy(newStrategyAddr).deposit(
                IporMath.convertToWad(stanleyAssetAmount, _getDecimals())
            );

            asset.safeApprove(oldStrategyAddr, 0);
            IERC20Upgradeable(IStrategy(oldStrategyAddr).getShareToken()).safeApprove(
                oldStrategyAddr,
                0
            );
        }

        emit StrategyChanged(
            _msgSender(),
            oldStrategyAddr,
            newStrategyAddr,
            address(newShareToken)
        );

        return newStrategyAddr;
    }

    /**
     * @notice Withdraws asset amount from given strategyAddress to Stanley
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
    ) internal nonReentrant returns (uint256 ivTokenWithdrawnAmount, uint256 totalBalance) {
        if (amount > 0) {
            //Withdraw from Strategy to Stanley
            uint256 withdrawnAmount = IStrategy(selectedStrategyAddress).withdraw(amount);

            /// @dev when in future more strategies then change this calculation
            totalBalance = strategyAave.balanceOf() + strategyCompound.balanceOf();

            uint256 totalBalanceWithWithdrawnAmount = totalBalance + withdrawnAmount;

            uint256 exchangeRate;

            /// @dev after withdraw balance could change which influence on exchange rate
            /// so exchange rate have to be calculated again
            if (totalBalanceWithWithdrawnAmount == 0 || ivTokenTotalSupply == 0) {
                exchangeRate = Constants.D18;
            } else {
                exchangeRate = IporMath.division(
                    totalBalanceWithWithdrawnAmount * Constants.D18,
                    ivTokenTotalSupply
                );
            }

            ivTokenWithdrawnAmount = IporMath.division(
                withdrawnAmount * Constants.D18,
                exchangeRate
            );

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

    function _calcExchangeRate(IStrategy strategyAave, IStrategy strategyCompound)
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
            exchangeRate = Constants.D18;
        } else {
            exchangeRate = IporMath.division(totalAssetBalance * Constants.D18, ivTokenTotalSupply);
        }
    }

    function _selectStrategyAndWithdrawAmount(
        uint256 amount,
        uint256 assetBalanceAaveStrategy,
        uint256 assetBalanceCompoundStrategy
    )
        internal
        view
        returns (
            address,
            uint256,
            uint256
        )
    {
        (
            address strategyMaxApy,
            address strategyAave,
            address strategyCompound
        ) = _getMaxApyStrategy();

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
}

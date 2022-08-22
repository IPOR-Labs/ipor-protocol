// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.15;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
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
import "hardhat/console.sol";

/// @title Stanley represents Asset Management module resposnible for investing Milton's cash in external DeFi protocols.
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
        require(_getDecimals() == ERC20Upgradeable(asset).decimals(), IporErrors.WRONG_DECIMALS);

        IIvToken iivToken = IIvToken(ivToken);
        require(asset == iivToken.getAsset(), IporErrors.ADDRESSES_MISMATCH);

        _asset = asset;
        _ivToken = iivToken;

        _setStrategyAave(strategyAave);
        _setStrategyCompound(strategyCompound);
    }

    function totalBalance(address who) external view override returns (uint256) {
        return _totalBalance(who);
    }

    function calculateExchangeRate() external view override returns (uint256 exchangeRate) {
        (exchangeRate, , ) = _calcExchangeRate();
    }

    /**
     * @dev to deposit asset in higher apy strategy.
     * @notice only owner can deposit.
     * @param amount underlying token amount represented in 18 decimals
     */
    function deposit(uint256 amount) external override whenNotPaused onlyMilton returns (uint256) {
        require(amount > 0, IporErrors.VALUE_NOT_GREATER_THAN_ZERO);
        (IStrategy strategyMaxApy, , ) = _getMaxApyStrategy();

        (
            uint256 exchangeRate,
            uint256 assetBalanceAave,
            uint256 assetBalanceCompound
        ) = _calcExchangeRate();

        uint256 ivTokenAmount = IporMath.division(amount * Constants.D18, exchangeRate);

        _depositToStrategy(strategyMaxApy, amount);

        _ivToken.mint(_msgSender(), ivTokenAmount);

        emit Deposit(
            block.timestamp,
            _msgSender(),
            address(strategyMaxApy),
            exchangeRate,
            amount,
            ivTokenAmount
        );

        return assetBalanceAave + assetBalanceCompound + amount;
    }

    function withdraw(uint256 amount)
        external
        override
        whenNotPaused
        onlyMilton
        returns (uint256 withdrawnAmount, uint256 balance)
    {
        require(amount > 0, IporErrors.VALUE_NOT_GREATER_THAN_ZERO);
        address msgSender = _msgSender();
        IIvToken ivToken = _ivToken;
        IERC20Upgradeable asset = IERC20Upgradeable(_asset);

        (
            uint256 exchangeRate,
            uint256 assetBalanceAave,
            uint256 assetBalanceCompound
        ) = _calcExchangeRate();

        uint256 ivTokenAmount = IporMath.division(amount * Constants.D18, exchangeRate);
        uint256 senderIvTokens = ivToken.balanceOf(msgSender);

        if (senderIvTokens < ivTokenAmount) {
            amount = IporMath.divisionWithoutRound(senderIvTokens * exchangeRate, Constants.D18);
        }

        (
            IStrategy establishedStrategy,
            uint256 establishedWithdrawnAmount
        ) = _establishStrategyAndWithdrawnAmount(amount, assetBalanceAave, assetBalanceCompound);

        if (establishedWithdrawnAmount > 0) {
            uint256 ivTokenWithdrawnAmount = IporMath.division(
                establishedWithdrawnAmount * Constants.D18,
                exchangeRate
            );

            ivToken.burn(msgSender, ivTokenWithdrawnAmount);

            //Tranfer from Strategy to Stanley
            _withdrawFromStrategy(
                address(establishedStrategy),
                establishedWithdrawnAmount,
                ivTokenWithdrawnAmount,
                exchangeRate
            );

            //Always transfer everything from Stanley to Milton
            asset.safeTransfer(msgSender, asset.balanceOf(address(this)));
        }

        withdrawnAmount = establishedWithdrawnAmount;
        balance = assetBalanceAave + assetBalanceCompound - establishedWithdrawnAmount;

        return (withdrawnAmount, balance);
    }

    function _establishStrategyAndWithdrawnAmount(
        uint256 amount,
        uint256 assetBalanceAave,
        uint256 assetBalanceCompound
    ) internal view returns (IStrategy, uint256) {
        (
            IStrategy strategyMaxApy,
            IStrategy strategyAave,
            IStrategy strategyCompound
        ) = _getMaxApyStrategy();

        if (address(strategyMaxApy) == _strategyCompound && amount <= assetBalanceAave) {
            return (strategyAave, amount);
        } else if (amount <= assetBalanceCompound) {
            return (strategyCompound, amount);
        }

        if (address(strategyMaxApy) == _strategyAave && amount <= assetBalanceAave) {
            return (strategyAave, amount);
        }

        if (assetBalanceAave < assetBalanceCompound) {
            return (strategyCompound, assetBalanceCompound);
        } else {
            return (strategyAave, assetBalanceAave);
        }
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

        uint256 assetBalanceAave = strategyAave.balanceOf();
        uint256 assetBalanceCompound = strategyCompound.balanceOf();
        uint256 assetBalanceStrategiesSum = assetBalanceAave + assetBalanceCompound;

        (uint256 exchangeRate, , ) = _calcExchangeRate();

        ivToken.burn(msgSender, ivToken.balanceOf(msgSender));

        if (assetBalanceStrategiesSum > 0) {
            if (assetBalanceAave > 0) {
                uint256 ivTokenAmountAave = IporMath.division(
                    assetBalanceAave * Constants.D18,
                    exchangeRate
                );
                _withdrawFromStrategy(
                    address(strategyAave),
                    assetBalanceAave,
                    ivTokenAmountAave,
                    exchangeRate
                );
            }

            if (assetBalanceCompound > 0) {
                uint256 ivTokenAmountCompound = IporMath.division(
                    assetBalanceCompound * Constants.D18,
                    exchangeRate
                );

                _withdrawFromStrategy(
                    address(strategyCompound),
                    assetBalanceCompound,
                    ivTokenAmountCompound,
                    exchangeRate
                );
            }
        }

        uint256 assetBalanceStanley = asset.balanceOf(address(this));

        console.log("[stanley-withdrawAll]assetBalanceStanley=", assetBalanceStanley);

        if (assetBalanceStanley > 0) {
            // Tranfer from Stanley to Milton
            asset.safeTransfer(msgSender, assetBalanceStanley);

            withdrawnAmount = IporMath.convertToWad(assetBalanceStanley, _getDecimals());

            console.log("[stanley-withdrawAll]assetBalanceAave=", assetBalanceAave);
            console.log("[stanley-withdrawAll]assetBalanceCompound=", assetBalanceCompound);
        } else {
            require(
                assetBalanceStrategiesSum > 0,
                StanleyErrors.INCONSISTENT_BALANCE_WITH_STRATEGIES
            );

            console.log("[stanley-withdrawAll]assetBalanceAave=", assetBalanceAave);
            console.log("[stanley-withdrawAll]assetBalanceCompound=", assetBalanceCompound);
        }

        vaultBalance = 0;
    }

    function getVersion() external pure override returns (uint256) {
        return 2;
    }

    function getAsset() external view override returns (address) {
        return _asset;
    }

    function migrateAssetToStrategyWithMaxApr() external whenNotPaused onlyOwner {
        (
            IStrategy strategyMaxApy,
            IStrategy strategyAave,
            IStrategy strategyCompound
        ) = _getMaxApyStrategy();

        uint256 decimals = _getDecimals();
        address from;

        if (address(strategyMaxApy) == address(strategyAave)) {
            from = address(strategyCompound);
            uint256 shares = strategyCompound.balanceOf();
            require(shares > 0, IporErrors.VALUE_NOT_GREATER_THAN_ZERO);
            strategyCompound.withdraw(shares);
        } else {
            from = address(strategyAave);
            uint256 shares = strategyAave.balanceOf();
            require(shares > 0, IporErrors.VALUE_NOT_GREATER_THAN_ZERO);
            strategyAave.withdraw(shares);
        }

        uint256 amount = ERC20Upgradeable(_asset).balanceOf(address(this));
        uint256 wadAmount = IporMath.convertToWad(amount, decimals);

        _depositToStrategy(strategyMaxApy, wadAmount);

        emit AssetMigrated(_msgSender(), from, address(strategyMaxApy), wadAmount);
    }

    function setStrategyAave(address strategyAddress) external override whenNotPaused onlyOwner {
        _setStrategyAave(strategyAddress);
    }

    function setStrategyCompound(address strategy) external override whenNotPaused onlyOwner {
        _setStrategyCompound(strategy);
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
            IStrategy strategyMaxApy,
            IStrategy strategyAave,
            IStrategy strategyCompound
        )
    {
        strategyAave = IStrategy(_strategyAave);
        strategyCompound = IStrategy(_strategyCompound);
        strategyMaxApy = strategyAave;
        if (strategyAave.getApr() < strategyCompound.getApr()) {
            strategyMaxApy = strategyCompound;
        } else {
            strategyMaxApy = strategyAave;
        }
    }

    function _totalBalance(address who) internal view returns (uint256) {
        (uint256 exchangeRate, , ) = _calcExchangeRate();
        return IporMath.division(_ivToken.balanceOf(who) * exchangeRate, Constants.D18);
    }

    /**
     * @dev to migrate all asset from current strategy to another higher apy strategy.
     * @notice only owner can migrate.
     */
    function _setStrategyCompound(address newStrategy) internal nonReentrant {
        require(newStrategy != address(0), IporErrors.WRONG_ADDRESS);

        address oldStrategy = _strategyCompound;

        IERC20Upgradeable asset = IERC20Upgradeable(_asset);

        IStrategy strategy = IStrategy(newStrategy);

        require(strategy.getAsset() == address(asset), StanleyErrors.ASSET_MISMATCH);

        if (oldStrategy != address(0)) {
            asset.safeApprove(oldStrategy, 0);
            IERC20Upgradeable(IStrategy(oldStrategy).getShareToken()).safeApprove(oldStrategy, 0);
        }

        IERC20Upgradeable newShareToken = IERC20Upgradeable(IStrategy(newStrategy).getShareToken());
        _strategyCompound = newStrategy;

        asset.safeApprove(newStrategy, 0);
        asset.safeApprove(newStrategy, type(uint256).max);

        newShareToken.safeApprove(newStrategy, 0);
        newShareToken.safeApprove(newStrategy, type(uint256).max);

        emit StrategyChanged(_msgSender(), oldStrategy, newStrategy, address(newShareToken));
    }

    function _setStrategyAave(address newStrategy) internal nonReentrant {
        require(newStrategy != address(0), IporErrors.WRONG_ADDRESS);

        address oldStrategy = _strategyAave;

        IERC20Upgradeable asset = ERC20Upgradeable(_asset);

        IStrategy strategy = IStrategy(newStrategy);

        require(strategy.getAsset() == address(asset), StanleyErrors.ASSET_MISMATCH);
        if (oldStrategy != address(0)) {
            asset.safeApprove(oldStrategy, 0);
            IERC20Upgradeable(IStrategy(oldStrategy).getShareToken()).safeApprove(oldStrategy, 0);
        }

        IERC20Upgradeable newShareToken = IERC20Upgradeable(strategy.getShareToken());
        _strategyAave = newStrategy;

        asset.safeApprove(newStrategy, 0);
        asset.safeApprove(newStrategy, type(uint256).max);

        newShareToken.safeApprove(newStrategy, 0);
        newShareToken.safeApprove(newStrategy, type(uint256).max);

        emit StrategyChanged(_msgSender(), oldStrategy, newStrategy, address(newShareToken));
    }

    /**
     * @notice Withdraws asset amount from given strategyAddress to Stanley
     * @param strategyAddress strategy address
     * @param ivTokenAmount ivToken amount which is calculated for asset amount for given exchange rate
     * @param exchangeRate current exchange rate for IV Token
     */
    function _withdrawFromStrategy(
        address strategyAddress,
        uint256 amount,
        uint256 ivTokenAmount,
        uint256 exchangeRate
    ) internal nonReentrant {
        if (amount > 0) {
            //Withdraw from Strategy to Stanley
            IStrategy(strategyAddress).withdraw(amount);

            emit Withdraw(
                block.timestamp,
                strategyAddress,
                _msgSender(),
                exchangeRate,
                amount,
                ivTokenAmount
            );
        }
    }

    /**  Internal Methods */
    /**
     * @dev to deposit asset in current strategy.
     * @notice internal method.
     * @param strategyAddress strategy from amount to deposit
     * @param wadAmount _amount is _asset token like DAI.
     */
    function _depositToStrategy(IStrategy strategyAddress, uint256 wadAmount) internal {
        uint256 amount = IporMath.convertWadToAssetDecimals(wadAmount, _getDecimals());
        IERC20Upgradeable(_asset).safeTransferFrom(_msgSender(), address(this), amount);
        strategyAddress.deposit(IporMath.convertToWad(amount, _getDecimals()));
    }

    function _calcExchangeRate()
        internal
        view
        returns (
            uint256 exchangeRate,
            uint256 assetBalanceAave,
            uint256 assetBalanceCompound
        )
    {
        assetBalanceAave = IStrategy(_strategyAave).balanceOf();
        assetBalanceCompound = IStrategy(_strategyCompound).balanceOf();

        console.log("[_calcExchangeRate]assetBalanceAave=", assetBalanceAave);
        console.log("[_calcExchangeRate]assetBalanceCompound=", assetBalanceCompound);

        uint256 totalAssetBalance = assetBalanceAave + assetBalanceCompound;

        console.log("[_calcExchangeRate]totalAssetBalance=", totalAssetBalance);

        uint256 ivTokenBalance = _ivToken.totalSupply();

        if (totalAssetBalance == 0 || ivTokenBalance == 0) {
            exchangeRate = Constants.D18;
        } else {
            exchangeRate = IporMath.division(totalAssetBalance * Constants.D18, ivTokenBalance);
        }
        console.log("[_calcExchangeRate]exchangeRate=", exchangeRate);
    }

    //solhint-disable no-empty-blocks
    function _authorizeUpgrade(address) internal override onlyOwner {}
}

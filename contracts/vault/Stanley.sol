// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.9;

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
    UUPSUpgradeable,
    PausableUpgradeable,
    ReentrancyGuardUpgradeable,
    IporOwnableUpgradeable,
    IStanley,
    IStanleyInternal
{
    using SafeERC20Upgradeable for IERC20Upgradeable;

    address internal _asset;
    IIvToken internal _ivToken;

    address internal _milton;
    address internal _strategyAave;
    address internal _aaveShareToken;
    address internal _strategyCompound;
    address internal _compoundShareToken;

    modifier onlyMilton() {
        require(msg.sender == _getMilton(), IporErrors.CALLER_NOT_MILTON);
        _;
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
        __Ownable_init();

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
    //  TODO: ADD tests for amount = 0
    function deposit(uint256 amount) external override whenNotPaused onlyMilton returns (uint256) {
        require(amount != 0, IporErrors.VALUE_NOT_GREATER_THAN_ZERO);

        (IStrategy strategyMaxApy, , ) = _getMaxApyStrategy();

        (
            uint256 exchangeRate,
            uint256 assetBalanceAave,
            uint256 assetBalanceCompound
        ) = _calcExchangeRate();

        uint256 ivTokenAmount = IporMath.division(amount * Constants.D18, exchangeRate);

        _depositToStrategy(strategyMaxApy, amount);

        _ivToken.mint(msg.sender, ivTokenAmount);

        emit Deposit(
            block.timestamp,
            msg.sender,
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
        require(amount != 0, IporErrors.VALUE_NOT_GREATER_THAN_ZERO);

        IIvToken ivToken = _ivToken;

        (
            IStrategy strategyMaxApy,
            IStrategy strategyAave,
            IStrategy strategyCompound
        ) = _getMaxApyStrategy();

        (
            uint256 exchangeRate,
            uint256 assetBalanceAave,
            uint256 assetBalanceCompound
        ) = _calcExchangeRate();

        uint256 ivTokenAmount = IporMath.division(amount * Constants.D18, exchangeRate);
        uint256 senderIvTokens = ivToken.balanceOf(msg.sender);

        if (senderIvTokens < ivTokenAmount) {
            amount = IporMath.divisionWithoutRound(senderIvTokens * exchangeRate, Constants.D18);
            ivTokenAmount = senderIvTokens;
        }

        if (address(strategyMaxApy) == _getStrategyCompound() && amount <= assetBalanceAave) {
            ivToken.burn(msg.sender, ivTokenAmount);
            _withdrawFromStrategy(address(strategyAave), amount, ivTokenAmount, exchangeRate, true);

            withdrawnAmount = amount;
            balance = assetBalanceAave + assetBalanceCompound - withdrawnAmount;

            return (withdrawnAmount, balance);
        } else if (amount <= assetBalanceCompound) {
            ivToken.burn(msg.sender, ivTokenAmount);
            _withdrawFromStrategy(
                address(strategyCompound),
                amount,
                ivTokenAmount,
                exchangeRate,
                true
            );

            withdrawnAmount = amount;
            balance = assetBalanceAave + assetBalanceCompound - withdrawnAmount;

            return (withdrawnAmount, balance);
        }

        if (address(strategyMaxApy) == _getStrategyAave() && amount <= assetBalanceAave) {
            ivToken.burn(msg.sender, ivTokenAmount);
            _withdrawFromStrategy(address(strategyAave), amount, ivTokenAmount, exchangeRate, true);

            withdrawnAmount = amount;
            balance = assetBalanceAave + assetBalanceCompound - withdrawnAmount;

            return (withdrawnAmount, balance);
        }

        if (assetBalanceAave < assetBalanceCompound) {
            uint256 ivTokenAmountPart = IporMath.division(
                assetBalanceCompound * Constants.D18,
                exchangeRate
            );

            _ivToken.burn(msg.sender, ivTokenAmountPart);
            _withdrawFromStrategy(
                address(strategyCompound),
                assetBalanceCompound,
                ivTokenAmountPart,
                exchangeRate,
                true
            );

            withdrawnAmount = assetBalanceCompound;
        } else {
            // TODO: Add tests for DAI(18 decimals) and for USDT (6 decimals)
            uint256 ivTokenAmountPart = IporMath.division(
                assetBalanceAave * Constants.D18,
                exchangeRate
            );
            ivToken.burn(msg.sender, ivTokenAmountPart);
            _withdrawFromStrategy(
                address(strategyAave),
                assetBalanceAave,
                ivTokenAmountPart,
                exchangeRate,
                true
            );
            withdrawnAmount = assetBalanceAave;
        }

        balance = assetBalanceAave + assetBalanceCompound - withdrawnAmount;

        return (withdrawnAmount, balance);
    }

    function withdrawAll()
        external
        override
        whenNotPaused
        onlyMilton
        returns (uint256 withdrawnAmount, uint256 vaultBalance)
    {
        IStrategy strategyAave = IStrategy(_getStrategyAave());

        (uint256 exchangeRate, , ) = _calcExchangeRate();

        uint256 assetBalanceAave = strategyAave.balanceOf();
        uint256 ivTokenAmountAave = IporMath.division(
            assetBalanceAave * Constants.D18,
            exchangeRate
        );

        _ivToken.burn(msg.sender, _ivToken.balanceOf(msg.sender));
        _withdrawFromStrategy(
            address(strategyAave),
            assetBalanceAave,
            ivTokenAmountAave,
            exchangeRate,
            false
        );

        IStrategy strategyCompound = IStrategy(_getStrategyCompound());

        uint256 assetBalanceCompound = strategyCompound.balanceOf();
        uint256 ivTokenAmountCompound = IporMath.division(
            assetBalanceCompound * Constants.D18,
            exchangeRate
        );

        _withdrawFromStrategy(
            address(strategyCompound),
            assetBalanceCompound,
            ivTokenAmountCompound,
            exchangeRate,
            false
        );

        uint256 balance = ERC20Upgradeable(_asset).balanceOf(address(this));

        if (balance != 0) {
            IERC20Upgradeable(_asset).safeTransfer(msg.sender, balance);
            uint256 wadBalance = IporMath.convertToWad(balance, _getDecimals());
            withdrawnAmount = assetBalanceAave + assetBalanceCompound + wadBalance;
        } else {
            withdrawnAmount = assetBalanceAave + assetBalanceCompound;
        }

        vaultBalance = 0;
    }

    function getVersion() external pure override returns (uint256) {
        return 1;
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
            console.log("shares: ", shares);
            strategyCompound.withdraw(IporMath.convertToWad(shares, decimals));
        } else {
            from = address(strategyAave);
            uint256 shares = strategyAave.balanceOf();
            require(shares > 0, IporErrors.VALUE_NOT_GREATER_THAN_ZERO);
            strategyAave.withdraw(IporMath.convertToWad(shares, decimals));
        }

        uint256 amount = ERC20Upgradeable(_asset).balanceOf(address(this));
        uint256 wadAmount = IporMath.convertToWad(amount, decimals);
        _depositToStrategy(strategyMaxApy, wadAmount);

        emit AssetMigrated(msg.sender, from, address(strategyMaxApy), wadAmount);
    }

    function setStrategyAave(address strategyAddress) external override whenNotPaused onlyOwner {
        _setStrategyAave(strategyAddress);
    }

    function setStrategyCompound(address strategy) external override whenNotPaused onlyOwner {
        _setStrategyCompound(strategy);
    }

    function setMilton(address newMilton) external override whenNotPaused onlyOwner {
        require(newMilton != address(0), IporErrors.WRONG_ADDRESS);
        address oldMilton = _getMilton();
        _milton = newMilton;
        emit MiltonChanged(msg.sender, oldMilton, newMilton);
    }

    function pause() external override onlyOwner {
        _pause();
    }

    function unpause() external override onlyOwner {
        _unpause();
    }

    function _getMilton() internal view virtual returns (address) {
        return _milton;
    }

    function _getStrategyAave() internal view virtual returns (address) {
        return _strategyAave;
    }

    function _getStrategyCompound() internal view virtual returns (address) {
        return _strategyCompound;
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
        strategyAave = IStrategy(_getStrategyAave());
        strategyCompound = IStrategy(_getStrategyCompound());
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

        address oldStrategy = _getStrategyCompound();
        address oldShareToken = _compoundShareToken;

        IERC20Upgradeable asset = IERC20Upgradeable(_asset);

        IStrategy strategy = IStrategy(newStrategy);
        IERC20Upgradeable shareToken = IERC20Upgradeable(oldShareToken);

        require(strategy.getAsset() == address(asset), StanleyErrors.ASSET_MISMATCH);

        if (oldStrategy != address(0)) {
            asset.safeApprove(oldStrategy, 0);
            shareToken.safeApprove(oldStrategy, 0);
        }

        IERC20Upgradeable newShareToken = IERC20Upgradeable(IStrategy(newStrategy).getShareToken());
        _strategyCompound = newStrategy;
        _compoundShareToken = address(newShareToken);

        asset.safeApprove(newStrategy, 0);
        asset.safeApprove(newStrategy, type(uint256).max);

        newShareToken.safeApprove(newStrategy, 0);
        newShareToken.safeApprove(newStrategy, type(uint256).max);

        emit StrategyChanged(msg.sender, oldStrategy, newStrategy, address(newShareToken));
    }

    function _setStrategyAave(address newStrategy) internal nonReentrant {
        require(newStrategy != address(0), IporErrors.WRONG_ADDRESS);

        address oldStrategy = _getStrategyAave();
        address oldShareToken = _aaveShareToken;

        IERC20Upgradeable asset = ERC20Upgradeable(_asset);

        IStrategy strategy = IStrategy(newStrategy);

        require(strategy.getAsset() == address(asset), StanleyErrors.ASSET_MISMATCH);

        if (oldStrategy != address(0)) {
            asset.safeApprove(oldStrategy, 0);
            IERC20Upgradeable(oldShareToken).safeApprove(oldStrategy, 0);
        }

        IERC20Upgradeable newShareToken = IERC20Upgradeable(strategy.getShareToken());
        _aaveShareToken = address(newShareToken);
        _strategyAave = newStrategy;

        asset.safeApprove(newStrategy, 0);
        asset.safeApprove(newStrategy, type(uint256).max);

        newShareToken.safeApprove(newStrategy, 0);
        newShareToken.safeApprove(newStrategy, type(uint256).max);

        emit StrategyChanged(msg.sender, oldStrategy, newStrategy, address(newShareToken));
    }

    /**
     * @dev to withdraw asset from current strategy.
     * @notice internal method.
     * @param strategyAddress strategy from amount to withdraw
     * @param amount is interest bearing token like aDAI, cDAI etc.
     */
    function _withdrawFromStrategy(
        address strategyAddress,
        uint256 amount,
        uint256 ivTokenAmount,
        uint256 exchangeRate,
        bool transfer
    ) internal nonReentrant {
        if (amount != 0) {
            IStrategy(strategyAddress).withdraw(amount);

            IERC20Upgradeable asset = IERC20Upgradeable(_asset);

            uint256 balance = asset.balanceOf(address(this));

            if (transfer) {
                asset.safeTransfer(msg.sender, balance);
            }
            emit Withdraw(
                block.timestamp,
                strategyAddress,
                msg.sender,
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
        _depositToStrategy(strategyAddress, wadAmount, amount);
    }

    function _depositToStrategy(
        IStrategy strategyAddress,
        uint256 wadAmount,
        uint256 amount
    ) internal {
        IERC20Upgradeable(_asset).safeTransferFrom(msg.sender, address(this), amount);
        strategyAddress.deposit(wadAmount);
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
        assetBalanceAave = IStrategy(_getStrategyAave()).balanceOf();
        assetBalanceCompound = IStrategy(_getStrategyCompound()).balanceOf();

        uint256 totalAssetBalance = assetBalanceAave + assetBalanceCompound;

        uint256 ivTokenBalance = _ivToken.totalSupply();

        if (totalAssetBalance == 0 || ivTokenBalance == 0) {
            exchangeRate = Constants.D18;
        } else {
            exchangeRate = IporMath.division(totalAssetBalance * Constants.D18, ivTokenBalance);
        }
    }

    //solhint-disable no-empty-blocks
    function _authorizeUpgrade(address) internal override onlyOwner {}
}

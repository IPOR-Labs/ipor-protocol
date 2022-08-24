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
        IStrategy strategyAave = IStrategy(_strategyAave);
        IStrategy strategyCompound = IStrategy(_strategyCompound);
        (, exchangeRate, , ) = _calcExchangeRate(strategyAave, strategyCompound);
    }

    /**
     * @dev to deposit asset in higher apy strategy.
     * @notice only owner can deposit.
     * @param amount underlying token amount represented in 18 decimals
     */
    function deposit(uint256 amount) external override whenNotPaused onlyMilton returns (uint256) {
        require(amount > 0, IporErrors.VALUE_NOT_GREATER_THAN_ZERO);
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

        _depositToStrategy(strategyMaxApy, amount);

        console.log("[deposit]strategyMaxApy=", strategyMaxApy);
        console.log("[deposit]exchangeRate=", exchangeRate);
        console.log("[deposit]ivTokenAmount=", ivTokenAmount);

        _ivToken.mint(_msgSender(), ivTokenAmount);

        emit Deposit(
            block.timestamp,
            _msgSender(),
            strategyMaxApy,
            exchangeRate,
            amount,
            ivTokenAmount
        );

        return assetBalanceAaveStrategy + assetBalanceCompoundStrategy + amount;
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
            uint256 exchangeRate,
            uint256 assetBalanceAaveStrategy,
            uint256 assetBalanceCompoundStrategy
        ) = _calcExchangeRate(strategyAave, strategyCompound);

        uint256 senderIvTokens = ivToken.balanceOf(_msgSender());

        if (senderIvTokens < IporMath.division(amount * Constants.D18, exchangeRate)) {
            amount = IporMath.divisionWithoutRound(senderIvTokens * exchangeRate, Constants.D18);
        }

        (
            address selectedStrategy,
            uint256 selectedWithdrawAmount,

        ) = _selectStrategyAndWithdrawAmount(
                amount,
                assetBalanceAaveStrategy,
                assetBalanceCompoundStrategy
            );

        if (selectedWithdrawAmount > 0) {
            //Tranfer from Strategy to Stanley
            uint256 ivTokenWithdrawnAmount;
            (ivTokenWithdrawnAmount, vaultBalance) = _withdrawFromStrategy(
                selectedStrategy,
                selectedWithdrawAmount,
                ivTokenTotalSupply,
                strategyAave,
                strategyCompound
            );

            console.log("XXX ivTokenWithdrawnAmount=", ivTokenWithdrawnAmount);
            console.log("XXX ivToken actual balance=", ivToken.balanceOf(_msgSender()));

            if (ivTokenWithdrawnAmount > senderIvTokens) {
                ivToken.burn(_msgSender(), senderIvTokens);
            } else {
                ivToken.burn(_msgSender(), ivTokenWithdrawnAmount);
            }

            uint256 assetBalanceStanley = asset.balanceOf(address(this));

            if (assetBalanceStanley > 0) {
                //Always transfer everything from Stanley to Milton
                asset.safeTransfer(_msgSender(), assetBalanceStanley);
                withdrawnAmount = IporMath.convertToWad(assetBalanceStanley, _getDecimals());
            }
        }
        console.log("XXX withdrawnAmount=", withdrawnAmount);

        console.log("XXX assetBalanceAaveStrategy V2=", strategyAave.balanceOf());
        console.log("XXX assetBalanceCompoundStrategy V2=", strategyCompound.balanceOf());
        console.log("XXX vaultBalance=", vaultBalance);
        console.log("XXX ivToken last calc=", ivToken.balanceOf(_msgSender()));
        //TODO: powinnimy wypłacać ivTokeny a nie stable bo nie zgadza sie wtedy na 2 strony,
        //gdybysmy wyplacali tokeny to przynajmniej zgadzalo by sie po stronie ivTokenow

        // balance = strategyAave.balanceOf() + strategyCompound.balanceOf();

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

        console.log("[stanley-withdrawAll]assetBalanceStanley=", assetBalanceStanley);

        //Always transfer everything from Stanley to Milton
        asset.safeTransfer(msgSender, assetBalanceStanley);

        withdrawnAmount = IporMath.convertToWad(assetBalanceStanley, _getDecimals());

        console.log("[stanley-withdrawAll]assetBalanceAaveStrategy=", assetBalanceAaveStrategy);
        console.log(
            "[stanley-withdrawAll]assetBalanceCompoundStrategy=",
            assetBalanceCompoundStrategy
        );
    }

    function getVersion() external pure override returns (uint256) {
        return 2;
    }

    function getAsset() external view override returns (address) {
        return _asset;
    }

    function migrateAssetToStrategyWithMaxApr() external whenNotPaused onlyOwner {
        (
            address strategyMaxApy,
            address strategyAave,
            address strategyCompound
        ) = _getMaxApyStrategy();

        uint256 decimals = _getDecimals();
        address from;

        if (strategyMaxApy == strategyAave) {
            from = strategyCompound;
            uint256 shares = IStrategy(strategyCompound).balanceOf();
            require(shares > 0, IporErrors.VALUE_NOT_GREATER_THAN_ZERO);
            IStrategy(strategyCompound).withdraw(shares);
        } else {
            from = strategyAave;
            uint256 shares = IStrategy(strategyAave).balanceOf();
            require(shares > 0, IporErrors.VALUE_NOT_GREATER_THAN_ZERO);
            IStrategy(strategyAave).withdraw(shares);
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
     * @param selectedStrategyAddress strategy address
     * @param amount asset amount which will be withdraw from Strategy, represented in 18 decimals
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
            console.log("xxx _withdrawFromStrategy amount=", amount);
            //Withdraw from Strategy to Stanley
            uint256 withdrawnAmount = IStrategy(selectedStrategyAddress).withdraw(amount);

            console.log("xxx _withdrawFromStrategy withdrawnAmount=", withdrawnAmount);

            totalBalance = strategyAave.balanceOf() + strategyCompound.balanceOf();

            uint256 totalBalanceWithWithdrawnAmount = totalBalance + withdrawnAmount;

            console.log("xxx _withdrawFromStrategy totalBalance=", totalBalance);
            console.log(
                "xxx _withdrawFromStrategy totalBalanceWithWithdrawnAmount=",
                totalBalanceWithWithdrawnAmount
            );

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

    /**
     * @dev to deposit asset in current strategy.
     * @notice internal method.
     * @param strategyAddress strategy from amount to deposit
     * @param wadAmount _amount is _asset token like DAI.
     */
    function _depositToStrategy(address strategyAddress, uint256 wadAmount) internal {
        uint256 amount = IporMath.convertWadToAssetDecimals(wadAmount, _getDecimals());
        IERC20Upgradeable(_asset).safeTransferFrom(_msgSender(), address(this), amount);
        IStrategy(strategyAddress).deposit(IporMath.convertToWad(amount, _getDecimals()));
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

        console.log("[_calcExchangeRate]assetBalanceAaveStrategy=", assetBalanceAaveStrategy);
        console.log(
            "[_calcExchangeRate]assetBalanceCompoundStrategy=",
            assetBalanceCompoundStrategy
        );

        uint256 totalAssetBalance = assetBalanceAaveStrategy + assetBalanceCompoundStrategy;

        console.log("[_calcExchangeRate]totalAssetBalance=", totalAssetBalance);

        ivTokenTotalSupply = _ivToken.totalSupply();

        console.log("[_calcExchangeRate]ivTokenBalance=", ivTokenTotalSupply);

        if (totalAssetBalance == 0 || ivTokenTotalSupply == 0) {
            exchangeRate = Constants.D18;
        } else {
            exchangeRate = IporMath.division(totalAssetBalance * Constants.D18, ivTokenTotalSupply);
        }
        console.log("[_calcExchangeRate]exchangeRate=", exchangeRate);
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

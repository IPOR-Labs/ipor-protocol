// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.16;
import "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "../libraries/Constants.sol";
import "../libraries/errors/IporErrors.sol";
import "../libraries/errors/MiltonErrors.sol";
import "../libraries/errors/JosephErrors.sol";
import "../libraries/math/IporMath.sol";
import "../libraries/AssetManagementLogic.sol";
import "../libraries/AmmLib.sol";
import "../interfaces/types/IporTypes.sol";
import "../interfaces/types/AmmTypes.sol";
import "../interfaces/IIpToken.sol";
import "../interfaces/IMilton.sol";
import "../interfaces/IMiltonInternal.sol";
import "../interfaces/IAmmPoolsService.sol";
import "../interfaces/IMiltonStorage.sol";
import "../governance/AmmConfigurationManager.sol";

contract AmmPoolsService is IAmmPoolsService {
    using SafeCast for int256;
    using SafeCast for uint256;
    using SafeERC20Upgradeable for IERC20Upgradeable;
    using AmmLib for AmmTypes.AmmPoolCoreModel;

    address internal immutable _usdt;
    uint256 internal immutable _usdtDecimals;
    address internal immutable _usdtIpToken;
    address internal immutable _usdtAmmStorage;
    address internal immutable _usdtAmmTreasury;
    address internal immutable _usdtAssetManagement;
    uint256 internal immutable _usdtRedeemFeeRate;
    uint256 internal immutable _usdtRedeemLpMaxUtilizationRate;

    address internal immutable _usdc;
    uint256 internal immutable _usdcDecimals;
    address internal immutable _usdcIpToken;
    address internal immutable _usdcAmmStorage;
    address internal immutable _usdcAmmTreasury;
    address internal immutable _usdcAssetManagement;
    uint256 internal immutable _usdcRedeemFeeRate;
    uint256 internal immutable _usdcRedeemLpMaxUtilizationRate;

    address internal immutable _dai;
    uint256 internal immutable _daiDecimals;
    address internal immutable _daiIpToken;
    address internal immutable _daiAmmStorage;
    address internal immutable _daiAmmTreasury;
    address internal immutable _daiAssetManagement;
    uint256 internal immutable _daiRedeemFeeRate;
    uint256 internal immutable _daiRedeemLpMaxUtilizationRate;

    address internal immutable _iporOracle;

    struct PoolConfiguration {
        address asset;
        uint256 decimals;
        address ipToken;
        address ammStorage;
        address ammTreasury;
        address assetManagement;
        uint256 redeemFeeRate;
        uint256 redeemLpMaxUtilizationRate;
    }

    constructor(
        PoolConfiguration memory usdtPoolCfg,
        PoolConfiguration memory usdcPoolCfg,
        PoolConfiguration memory daiPoolCfg,
        address iporOracle
    ) {
        require(usdtPoolCfg.asset != address(0), string.concat(IporErrors.WRONG_ADDRESS, " USDT pool asset"));
        require(usdtPoolCfg.ipToken != address(0), string.concat(IporErrors.WRONG_ADDRESS, " USDT pool ipToken"));
        require(usdtPoolCfg.ammStorage != address(0), string.concat(IporErrors.WRONG_ADDRESS, " USDT pool ammStorage"));
        require(
            usdtPoolCfg.ammTreasury != address(0),
            string.concat(IporErrors.WRONG_ADDRESS, " USDT pool ammTreasury")
        );
        require(
            usdtPoolCfg.assetManagement != address(0),
            string.concat(IporErrors.WRONG_ADDRESS, " USDT pool assetManagement")
        );

        require(usdcPoolCfg.asset != address(0), string.concat(IporErrors.WRONG_ADDRESS, " USDC pool asset"));
        require(usdcPoolCfg.ipToken != address(0), string.concat(IporErrors.WRONG_ADDRESS, " USDC pool ipToken"));
        require(usdcPoolCfg.ammStorage != address(0), string.concat(IporErrors.WRONG_ADDRESS, " USDC pool ammStorage"));
        require(
            usdcPoolCfg.ammTreasury != address(0),
            string.concat(IporErrors.WRONG_ADDRESS, " USDC pool ammTreasury")
        );
        require(
            usdcPoolCfg.assetManagement != address(0),
            string.concat(IporErrors.WRONG_ADDRESS, " USDC pool assetManagement")
        );

        require(daiPoolCfg.asset != address(0), string.concat(IporErrors.WRONG_ADDRESS, " DAI pool asset"));
        require(daiPoolCfg.ipToken != address(0), string.concat(IporErrors.WRONG_ADDRESS, " DAI pool ipToken"));
        require(daiPoolCfg.ammStorage != address(0), string.concat(IporErrors.WRONG_ADDRESS, " DAI pool ammStorage"));
        require(daiPoolCfg.ammTreasury != address(0), string.concat(IporErrors.WRONG_ADDRESS, " DAI pool ammTreasury"));
        require(
            daiPoolCfg.assetManagement != address(0),
            string.concat(IporErrors.WRONG_ADDRESS, " DAI pool assetManagement")
        );

        _usdt = usdtPoolCfg.asset;
        _usdtDecimals = usdtPoolCfg.decimals;
        _usdtIpToken = usdtPoolCfg.ipToken;
        _usdtAmmStorage = usdtPoolCfg.ammStorage;
        _usdtAmmTreasury = usdtPoolCfg.ammTreasury;
        _usdtAssetManagement = usdtPoolCfg.assetManagement;
        _usdtRedeemFeeRate = usdtPoolCfg.redeemFeeRate;
        _usdtRedeemLpMaxUtilizationRate = usdtPoolCfg.redeemLpMaxUtilizationRate;

        _usdc = usdcPoolCfg.asset;
        _usdcDecimals = usdcPoolCfg.decimals;
        _usdcIpToken = usdcPoolCfg.ipToken;
        _usdcAmmStorage = usdcPoolCfg.ammStorage;
        _usdcAmmTreasury = usdcPoolCfg.ammTreasury;
        _usdcAssetManagement = usdcPoolCfg.assetManagement;
        _usdcRedeemFeeRate = usdcPoolCfg.redeemFeeRate;
        _usdcRedeemLpMaxUtilizationRate = usdcPoolCfg.redeemLpMaxUtilizationRate;

        _dai = daiPoolCfg.asset;
        _daiDecimals = daiPoolCfg.decimals;
        _daiIpToken = daiPoolCfg.ipToken;
        _daiAmmStorage = daiPoolCfg.ammStorage;
        _daiAmmTreasury = daiPoolCfg.ammTreasury;
        _daiAssetManagement = daiPoolCfg.assetManagement;
        _daiRedeemFeeRate = daiPoolCfg.redeemFeeRate;
        _daiRedeemLpMaxUtilizationRate = daiPoolCfg.redeemLpMaxUtilizationRate;

        _iporOracle = iporOracle;
    }

    function provideLiquidity(
        address asset,
        address onBehalfOf,
        uint256 assetAmount
    ) external override {
        PoolConfiguration memory poolCfg = getPoolConfiguration(asset);
        AmmTypes.AmmPoolCoreModel memory model;

        model.asset = asset;
        model.ipToken = poolCfg.ipToken;
        model.ammStorage = poolCfg.ammStorage;
        model.assetManagement = poolCfg.assetManagement;
        model.iporOracle = _iporOracle;

        IporTypes.MiltonBalancesMemory memory balance = model.getAccruedBalance();

        uint256 exchangeRate = model.getExchangeRate(balance.liquidityPool);

        require(exchangeRate > 0, MiltonErrors.LIQUIDITY_POOL_IS_EMPTY);

        uint256 wadAssetAmount = IporMath.convertToWad(assetAmount, poolCfg.decimals);

        IMiltonStorage(poolCfg.ammStorage).addLiquidity(
            onBehalfOf,
            wadAssetAmount,
            AmmConfigurationManager.getAmmPoolsMaxLiquidityPoolBalance(poolCfg.asset) * Constants.D18,
            AmmConfigurationManager.getAmmPoolsMaxLpAccountContribution(poolCfg.asset) * Constants.D18
        );

        IERC20Upgradeable(poolCfg.asset).safeTransferFrom(msg.sender, poolCfg.ammTreasury, assetAmount);

        uint256 ipTokenAmount = IporMath.division(wadAssetAmount * Constants.D18, exchangeRate);

        IIpToken(poolCfg.ipToken).mint(onBehalfOf, ipTokenAmount);

        /// @dev Order of the following two functions is important, first safeTransferFrom, then rebalanceIfNeededAfterProvideLiquidity.
        _rebalanceIfNeededAfterProvideLiquidity(poolCfg, balance.vault, wadAssetAmount);

        emit ProvideLiquidity(
            block.timestamp,
            onBehalfOf,
            poolCfg.ammTreasury,
            exchangeRate,
            wadAssetAmount,
            ipTokenAmount
        );
    }

    function redeem(
        address asset,
        address onBehalfOf,
        uint256 ipTokenAmount
    ) external override {
        PoolConfiguration memory poolCfg = getPoolConfiguration(asset);

        require(
            ipTokenAmount > 0 && ipTokenAmount <= IIpToken(poolCfg.ipToken).balanceOf(msg.sender),
            JosephErrors.CANNOT_REDEEM_IP_TOKEN_TOO_LOW
        );

        AmmTypes.AmmPoolCoreModel memory model;

        model.asset = asset;
        model.ipToken = poolCfg.ipToken;
        model.ammStorage = poolCfg.ammStorage;
        model.assetManagement = poolCfg.assetManagement;
        model.iporOracle = _iporOracle;

        IporTypes.MiltonBalancesMemory memory balance = model.getAccruedBalance();

        uint256 exchangeRate = model.getExchangeRate(balance.liquidityPool);

        require(exchangeRate > 0, MiltonErrors.LIQUIDITY_POOL_IS_EMPTY);

        AmmTypes.RedeemMoney memory redeemMoney = _calculateRedeemMoney(
            poolCfg.decimals,
            ipTokenAmount,
            exchangeRate,
            poolCfg.redeemFeeRate
        );

        uint256 wadAmmTreasuryErc20Balance = IporMath.convertToWad(
            IERC20Upgradeable(poolCfg.asset).balanceOf(poolCfg.ammTreasury),
            poolCfg.decimals
        );

        require(
            wadAmmTreasuryErc20Balance + balance.vault > redeemMoney.wadRedeemAmount,
            JosephErrors.INSUFFICIENT_ERC20_BALANCE
        );

        _rebalanceIfNeededBeforeRedeem(poolCfg, wadAmmTreasuryErc20Balance, balance.vault, redeemMoney.wadRedeemAmount);

        require(
            _calculateRedeemedUtilizationRate(
                balance.liquidityPool,
                balance.totalCollateralPayFixed + balance.totalCollateralReceiveFixed,
                redeemMoney.wadRedeemAmount
            ) <= poolCfg.redeemLpMaxUtilizationRate,
            JosephErrors.REDEEM_LP_UTILIZATION_EXCEEDED
        );

        IIpToken(poolCfg.ipToken).burn(msg.sender, ipTokenAmount);

        IMiltonStorage(poolCfg.ammStorage).subtractLiquidity(redeemMoney.wadRedeemAmount);

        IERC20Upgradeable(asset).safeTransferFrom(poolCfg.ammTreasury, onBehalfOf, redeemMoney.redeemAmount);

        emit Redeem(
            block.timestamp,
            poolCfg.ammTreasury,
            onBehalfOf,
            exchangeRate,
            redeemMoney.wadAssetAmount,
            ipTokenAmount,
            redeemMoney.wadRedeemFee,
            redeemMoney.wadRedeemAmount
        );
    }

    function rebalance(address asset) external override {
        require(
            AmmConfigurationManager.isAmmPoolsAppointedToRebalance(asset, msg.sender),
            JosephErrors.CALLER_NOT_APPOINTED_TO_REBALANCE
        );

        PoolConfiguration memory poolCfg = getPoolConfiguration(asset);

        uint256 wadAmmTreasuryAssetBalance = IporMath.convertToWad(
            IERC20Upgradeable(poolCfg.asset).balanceOf(poolCfg.ammTreasury),
            poolCfg.decimals
        );

        uint256 totalBalance = wadAmmTreasuryAssetBalance +
            IStanley(poolCfg.assetManagement).totalBalance(poolCfg.ammTreasury);

        require(totalBalance > 0, JosephErrors.STANLEY_BALANCE_IS_EMPTY);

        uint256 ratio = IporMath.division(wadAmmTreasuryAssetBalance * Constants.D18, totalBalance);

        uint256 miltonStanleyBalanceRatio = AmmConfigurationManager.getAmmPoolsAndAssetManagementRatio(poolCfg.asset);

        if (ratio > miltonStanleyBalanceRatio) {
            uint256 assetAmount = wadAmmTreasuryAssetBalance -
                IporMath.division(miltonStanleyBalanceRatio * totalBalance, Constants.D18);
            if (assetAmount > 0) {
                IMiltonInternal(poolCfg.ammTreasury).depositToStanley(assetAmount);
            }
        } else {
            uint256 assetAmount = IporMath.division(miltonStanleyBalanceRatio * totalBalance, Constants.D18) -
                wadAmmTreasuryAssetBalance;
            if (assetAmount > 0) {
                IMiltonInternal(poolCfg.ammTreasury).withdrawFromStanley(assetAmount);
            }
        }
    }

    function getPoolConfiguration(address asset) public view returns (PoolConfiguration memory) {
        if (asset == _usdt) {
            return
                PoolConfiguration({
                    asset: _usdt,
                    decimals: _usdtDecimals,
                    ipToken: _usdtIpToken,
                    ammStorage: _usdtAmmStorage,
                    ammTreasury: _usdtAmmTreasury,
                    assetManagement: _usdtAssetManagement,
                    redeemFeeRate: _usdtRedeemFeeRate,
                    redeemLpMaxUtilizationRate: _usdtRedeemLpMaxUtilizationRate
                });
        } else if (asset == _usdc) {
            return
                PoolConfiguration({
                    asset: _usdc,
                    decimals: _usdcDecimals,
                    ipToken: _usdcIpToken,
                    ammStorage: _usdcAmmStorage,
                    ammTreasury: _usdcAmmTreasury,
                    assetManagement: _usdcAssetManagement,
                    redeemFeeRate: _usdcRedeemFeeRate,
                    redeemLpMaxUtilizationRate: _usdcRedeemLpMaxUtilizationRate
                });
        } else if (asset == _dai) {
            return
                PoolConfiguration({
                    asset: _dai,
                    decimals: _daiDecimals,
                    ipToken: _daiIpToken,
                    ammStorage: _daiAmmStorage,
                    ammTreasury: _daiAmmTreasury,
                    assetManagement: _daiAssetManagement,
                    redeemFeeRate: _daiRedeemFeeRate,
                    redeemLpMaxUtilizationRate: _daiRedeemLpMaxUtilizationRate
                });
        } else {
            revert("AmmPoolsLens: asset not supported");
        }
    }

    /// @dev Calculate redeem money
    /// @param ipTokenAmount Amount of ipToken to redeem
    /// @param exchangeRate Exchange rate of ipToken
    /// @return redeemMoney Redeem money struct
    function _calculateRedeemMoney(
        uint256 assetDecimals,
        uint256 ipTokenAmount,
        uint256 exchangeRate,
        uint256 cfgRedeemFeeRate
    ) internal view returns (AmmTypes.RedeemMoney memory redeemMoney) {
        uint256 wadAssetAmount = IporMath.division(ipTokenAmount * exchangeRate, Constants.D18);
        uint256 wadRedeemFee = IporMath.division(wadAssetAmount * cfgRedeemFeeRate, Constants.D18);
        uint256 redeemAmount = IporMath.convertWadToAssetDecimals(wadAssetAmount - wadRedeemFee, assetDecimals);

        return
            AmmTypes.RedeemMoney({
                wadAssetAmount: wadAssetAmount,
                wadRedeemFee: wadRedeemFee,
                redeemAmount: redeemAmount,
                wadRedeemAmount: IporMath.convertToWad(redeemAmount, assetDecimals)
            });
    }

    function _rebalanceIfNeededAfterProvideLiquidity(
        PoolConfiguration memory poolCfg,
        uint256 vaultBalance,
        uint256 wadOperationAmount
    ) internal {
        uint256 autoRebalanceThreshold = AmmConfigurationManager.getAmmPoolsAutoRebalanceThreshold(poolCfg.asset) *
            Constants.D21;

        if (autoRebalanceThreshold > 0 && wadOperationAmount >= autoRebalanceThreshold) {
            int256 rebalanceAmount = _calculateRebalanceAmountAfterProvideLiquidity(
                poolCfg.asset,
                IporMath.convertToWad(
                    IERC20Upgradeable(poolCfg.asset).balanceOf(poolCfg.ammTreasury),
                    poolCfg.decimals
                ),
                vaultBalance
            );

            if (rebalanceAmount > 0) {
                IMiltonInternal(poolCfg.ammTreasury).depositToStanley(rebalanceAmount.toUint256());
            }
        }
    }

    /// @notice Calculate rebalance amount for provide liquidity
    /// @param asset Asset address (pool context)
    /// @param wadAmmTreasuryErc20BalanceAfterDeposit Milton erc20 balance in wad, Notice: this is balance after provide liquidity operation!
    /// @param vaultBalance Vault balance in wad, Stanley's accrued balance.
    function _calculateRebalanceAmountAfterProvideLiquidity(
        address asset,
        uint256 wadAmmTreasuryErc20BalanceAfterDeposit,
        uint256 vaultBalance
    ) internal view returns (int256) {
        uint256 ratio = AmmConfigurationManager.getAmmPoolsAndAssetManagementRatio(asset);
        return
            IporMath.divisionInt(
                (wadAmmTreasuryErc20BalanceAfterDeposit + vaultBalance).toInt256() *
                    (Constants.D18_INT - ratio.toInt256()),
                Constants.D18_INT
            ) - vaultBalance.toInt256();
    }

    function _rebalanceIfNeededBeforeRedeem(
        PoolConfiguration memory poolCfg,
        uint256 wadAmmTreasuryErc20Balance,
        uint256 vaultBalance,
        uint256 wadOperationAmount
    ) internal {
        uint256 autoRebalanceThreshold = AmmConfigurationManager.getAmmPoolsAutoRebalanceThreshold(poolCfg.asset) *
            Constants.D21;

        if (
            wadOperationAmount > wadAmmTreasuryErc20Balance ||
            (autoRebalanceThreshold > 0 && wadOperationAmount >= autoRebalanceThreshold)
        ) {
            int256 rebalanceAmount = AssetManagementLogic.calculateRebalanceAmountBeforeWithdraw(
                poolCfg.asset,
                wadAmmTreasuryErc20Balance,
                vaultBalance,
                wadOperationAmount
            );

            if (rebalanceAmount < 0) {
                IMiltonInternal(poolCfg.ammTreasury).withdrawFromStanley((-rebalanceAmount).toUint256());
            }
        }
    }

    function _calculateRedeemedUtilizationRate(
        uint256 totalLiquidityPoolBalance,
        uint256 totalCollateralBalance,
        uint256 redeemedAmount
    ) internal pure returns (uint256) {
        uint256 denominator = totalLiquidityPoolBalance - redeemedAmount;
        if (denominator > 0) {
            return
                IporMath.division(totalCollateralBalance * Constants.D18, totalLiquidityPoolBalance - redeemedAmount);
        } else {
            return Constants.MAX_VALUE;
        }
    }
}

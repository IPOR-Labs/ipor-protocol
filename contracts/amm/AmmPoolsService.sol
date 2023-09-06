// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.20;
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/IERC20MetadataUpgradeable.sol";
import "../interfaces/types/IporTypes.sol";
import "../interfaces/types/AmmTypes.sol";
import "../interfaces/IIpToken.sol";
import "../interfaces/IAmmTreasury.sol";
import "../interfaces/IAmmPoolsService.sol";
import "../interfaces/IAmmStorage.sol";
import "../libraries/Constants.sol";
import "../libraries/errors/IporErrors.sol";
import "../libraries/errors/AmmErrors.sol";
import "../libraries/errors/AmmPoolsErrors.sol";
import "../libraries/math/IporMath.sol";
import "../libraries/AssetManagementLogic.sol";
import "../libraries/AmmLib.sol";
import "../governance/AmmConfigurationManager.sol";
import "../libraries/IporContractValidator.sol";

contract AmmPoolsService is IAmmPoolsService {
    using IporContractValidator for address;
    using SafeCast for int256;
    using SafeCast for uint256;
    using SafeCast for uint32;
    using SafeERC20Upgradeable for IERC20Upgradeable;
    using AmmLib for AmmTypes.AmmPoolCoreModel;

    address internal immutable _usdt;
    uint256 internal immutable _usdtDecimals;
    address internal immutable _usdtIpToken;
    address internal immutable _usdtAmmStorage;
    address internal immutable _usdtAmmTreasury;
    address internal immutable _usdtAssetManagement;
    uint256 internal immutable _usdtRedeemFeeRate;
    uint256 internal immutable _usdtRedeemLpMaxCollateralRatio;

    address internal immutable _usdc;
    uint256 internal immutable _usdcDecimals;
    address internal immutable _usdcIpToken;
    address internal immutable _usdcAmmStorage;
    address internal immutable _usdcAmmTreasury;
    address internal immutable _usdcAssetManagement;
    uint256 internal immutable _usdcRedeemFeeRate;
    uint256 internal immutable _usdcRedeemLpMaxCollateralRatio;

    address internal immutable _dai;
    uint256 internal immutable _daiDecimals;
    address internal immutable _daiIpToken;
    address internal immutable _daiAmmStorage;
    address internal immutable _daiAmmTreasury;
    address internal immutable _daiAssetManagement;
    uint256 internal immutable _daiRedeemFeeRate;
    uint256 internal immutable _daiRedeemLpMaxCollateralRatio;

    address internal immutable _iporOracle;

    constructor(
        AmmPoolsServicePoolConfiguration memory usdtPoolCfg,
        AmmPoolsServicePoolConfiguration memory usdcPoolCfg,
        AmmPoolsServicePoolConfiguration memory daiPoolCfg,
        address iporOracle
    ) {
        _usdt = usdtPoolCfg.asset.checkAddress();
        _usdtDecimals = usdtPoolCfg.decimals;
        _usdtIpToken = usdtPoolCfg.ipToken.checkAddress();
        _usdtAmmStorage = usdtPoolCfg.ammStorage.checkAddress();
        _usdtAmmTreasury = usdtPoolCfg.ammTreasury.checkAddress();
        _usdtAssetManagement = usdtPoolCfg.assetManagement.checkAddress();
        _usdtRedeemFeeRate = usdtPoolCfg.redeemFeeRate;
        _usdtRedeemLpMaxCollateralRatio = usdtPoolCfg.redeemLpMaxCollateralRatio;

        _usdc = usdcPoolCfg.asset.checkAddress();
        _usdcDecimals = usdcPoolCfg.decimals;
        _usdcIpToken = usdcPoolCfg.ipToken.checkAddress();
        _usdcAmmStorage = usdcPoolCfg.ammStorage.checkAddress();
        _usdcAmmTreasury = usdcPoolCfg.ammTreasury.checkAddress();
        _usdcAssetManagement = usdcPoolCfg.assetManagement.checkAddress();
        _usdcRedeemFeeRate = usdcPoolCfg.redeemFeeRate;
        _usdcRedeemLpMaxCollateralRatio = usdcPoolCfg.redeemLpMaxCollateralRatio;

        _dai = daiPoolCfg.asset.checkAddress();
        _daiDecimals = daiPoolCfg.decimals;
        _daiIpToken = daiPoolCfg.ipToken.checkAddress();
        _daiAmmStorage = daiPoolCfg.ammStorage.checkAddress();
        _daiAmmTreasury = daiPoolCfg.ammTreasury.checkAddress();
        _daiAssetManagement = daiPoolCfg.assetManagement.checkAddress();
        _daiRedeemFeeRate = daiPoolCfg.redeemFeeRate;
        _daiRedeemLpMaxCollateralRatio = daiPoolCfg.redeemLpMaxCollateralRatio;

        _iporOracle = iporOracle.checkAddress();

        require(
            _usdtRedeemFeeRate <= 1e18 && _usdcRedeemFeeRate <= 1e18 && _daiRedeemFeeRate <= 1e18,
            AmmPoolsErrors.CFG_INVALID_REDEEM_FEE_RATE
        );
        require(
            _usdtRedeemLpMaxCollateralRatio <= 1e18 &&
                _usdcRedeemLpMaxCollateralRatio <= 1e18 &&
                _daiRedeemLpMaxCollateralRatio <= 1e18,
            AmmPoolsErrors.CFG_INVALID_REDEEM_LP_MAX_COLLATERAL_RATIO
        );
    }

    function getAmmPoolServiceConfiguration(
        address asset
    ) external view override returns (AmmPoolsServicePoolConfiguration memory) {
        return _getPoolConfiguration(asset);
    }

    function provideLiquidityUsdt(address beneficiary, uint256 assetAmount) external override {
        _provideLiquidity(_usdt, beneficiary, assetAmount);
    }

    function provideLiquidityUsdc(address beneficiary, uint256 assetAmount) external override {
        _provideLiquidity(_usdc, beneficiary, assetAmount);
    }

    function provideLiquidityDai(address beneficiary, uint256 assetAmount) external override {
        _provideLiquidity(_dai, beneficiary, assetAmount);
    }

    function redeemFromAmmPoolUsdt(address beneficiary, uint256 ipTokenAmount) external override {
        _redeem(_usdt, beneficiary, ipTokenAmount);
    }

    function redeemFromAmmPoolUsdc(address beneficiary, uint256 ipTokenAmount) external override {
        _redeem(_usdc, beneficiary, ipTokenAmount);
    }

    function redeemFromAmmPoolDai(address beneficiary, uint256 ipTokenAmount) external override {
        _redeem(_dai, beneficiary, ipTokenAmount);
    }

    function rebalanceBetweenAmmTreasuryAndAssetManagement(address asset) external override {
        require(
            AmmConfigurationManager.isAppointedToRebalanceInAmm(asset, msg.sender),
            AmmPoolsErrors.CALLER_NOT_APPOINTED_TO_REBALANCE
        );

        AmmPoolsServicePoolConfiguration memory poolCfg = _getPoolConfiguration(asset);

        StorageLib.AmmPoolsParamsValue memory ammPoolsParamsCfg = AmmConfigurationManager.getAmmPoolsParams(
            poolCfg.asset
        );

        uint256 wadAmmTreasuryAssetBalance = IporMath.convertToWad(
            IERC20Upgradeable(poolCfg.asset).balanceOf(poolCfg.ammTreasury),
            poolCfg.decimals
        );

        uint256 totalBalance = wadAmmTreasuryAssetBalance + IAssetManagementDsr(poolCfg.assetManagement).totalBalance();

        require(totalBalance > 0, AmmPoolsErrors.ASSET_MANAGEMENT_BALANCE_IS_EMPTY);

        uint256 ratio = IporMath.division(wadAmmTreasuryAssetBalance * 1e18, totalBalance);

        /// @dev 1e14 explanation: ammTreasuryAndAssetManagementRatio represents percentage in 2 decimals, example 45% = 4500, so to achieve number in 18 decimals we need to multiply by 1e14
        uint256 ammTreasuryAssetManagementBalanceRatio = uint256(ammPoolsParamsCfg.ammTreasuryAndAssetManagementRatio) *
            1e14;

        if (ratio > ammTreasuryAssetManagementBalanceRatio) {
            uint256 wadAssetAmount = wadAmmTreasuryAssetBalance -
                IporMath.division(ammTreasuryAssetManagementBalanceRatio * totalBalance, 1e18);
            if (wadAssetAmount > 0) {
                IAmmTreasury(poolCfg.ammTreasury).depositToAssetManagementInternal(wadAssetAmount);
            }
        } else {
            uint256 wadAssetAmount = IporMath.division(ammTreasuryAssetManagementBalanceRatio * totalBalance, 1e18) -
                wadAmmTreasuryAssetBalance;
            if (wadAssetAmount > 0) {
                IAmmTreasury(poolCfg.ammTreasury).withdrawFromAssetManagementInternal(wadAssetAmount);
            }
        }
    }

    function _provideLiquidity(address asset, address beneficiary, uint256 assetAmount) internal {
        AmmPoolsServicePoolConfiguration memory poolCfg = _getPoolConfiguration(asset);
        StorageLib.AmmPoolsParamsValue memory ammPoolsParamsCfg = AmmConfigurationManager.getAmmPoolsParams(
            poolCfg.asset
        );
        AmmTypes.AmmPoolCoreModel memory model;

        model.asset = asset;
        model.ipToken = poolCfg.ipToken;
        model.ammStorage = poolCfg.ammStorage;
        model.ammTreasury = poolCfg.ammTreasury;
        model.assetManagement = poolCfg.assetManagement;
        model.iporOracle = _iporOracle;

        IporTypes.AmmBalancesMemory memory balance = model.getAccruedBalance();
        uint256 exchangeRate = model.getExchangeRate(balance.liquidityPool);
        require(exchangeRate > 0, AmmErrors.LIQUIDITY_POOL_IS_EMPTY);

        uint256 wadAssetAmount = IporMath.convertToWad(assetAmount, poolCfg.decimals);

        IAmmStorage(poolCfg.ammStorage).addLiquidityInternal(
            beneficiary,
            wadAssetAmount,
            uint256(ammPoolsParamsCfg.maxLiquidityPoolBalance) * 1e18
        );

        IERC20Upgradeable(poolCfg.asset).safeTransferFrom(msg.sender, poolCfg.ammTreasury, assetAmount);

        uint256 ipTokenAmount = IporMath.division(wadAssetAmount * 1e18, exchangeRate);

        IIpToken(poolCfg.ipToken).mint(beneficiary, ipTokenAmount);

        /// @dev Order of the following two functions is important, first safeTransferFrom, then rebalanceIfNeededAfterProvideLiquidity.
        _rebalanceIfNeededAfterProvideLiquidity(poolCfg, ammPoolsParamsCfg, balance.vault, wadAssetAmount);

        emit ProvideLiquidity(
            block.timestamp,
            beneficiary,
            poolCfg.ammTreasury,
            exchangeRate,
            wadAssetAmount,
            ipTokenAmount
        );
    }

    function _redeem(address asset, address beneficiary, uint256 ipTokenAmount) internal {
        AmmPoolsServicePoolConfiguration memory poolCfg = _getPoolConfiguration(asset);

        require(
            ipTokenAmount > 0 && ipTokenAmount <= IIpToken(poolCfg.ipToken).balanceOf(msg.sender),
            AmmPoolsErrors.CANNOT_REDEEM_IP_TOKEN_TOO_LOW
        );

        AmmTypes.AmmPoolCoreModel memory model;

        model.asset = asset;
        model.ipToken = poolCfg.ipToken;
        model.ammStorage = poolCfg.ammStorage;
        model.ammTreasury = poolCfg.ammTreasury;
        model.assetManagement = poolCfg.assetManagement;
        model.iporOracle = _iporOracle;

        IporTypes.AmmBalancesMemory memory balance = model.getAccruedBalance();

        uint256 exchangeRate = model.getExchangeRate(balance.liquidityPool);

        require(exchangeRate > 0, AmmErrors.LIQUIDITY_POOL_IS_EMPTY);

        AmmTypes.RedeemAmount memory redeemAmountStruct = _calculateRedeemAmount(
            poolCfg.decimals,
            ipTokenAmount,
            exchangeRate,
            poolCfg.redeemFeeRate
        );

        require(
            redeemAmountStruct.redeemAmount > 0 && redeemAmountStruct.wadRedeemAmount > 0,
            AmmPoolsErrors.CANNOT_REDEEM_ASSET_AMOUNT_TOO_LOW
        );

        uint256 wadAmmTreasuryErc20Balance = IporMath.convertToWad(
            IERC20Upgradeable(poolCfg.asset).balanceOf(poolCfg.ammTreasury),
            poolCfg.decimals
        );

        require(
            wadAmmTreasuryErc20Balance + balance.vault > redeemAmountStruct.wadRedeemAmount,
            AmmPoolsErrors.INSUFFICIENT_ERC20_BALANCE
        );

        _rebalanceIfNeededBeforeRedeem(
            poolCfg,
            wadAmmTreasuryErc20Balance,
            balance.vault,
            redeemAmountStruct.wadRedeemAmount
        );

        require(
            _calculateRedeemedCollateralRatio(
                balance.liquidityPool,
                balance.totalCollateralPayFixed + balance.totalCollateralReceiveFixed,
                redeemAmountStruct.wadRedeemAmount
            ) <= poolCfg.redeemLpMaxCollateralRatio,
            AmmPoolsErrors.REDEEM_LP_COLLATERAL_RATIO_EXCEEDED
        );

        IIpToken(poolCfg.ipToken).burn(msg.sender, ipTokenAmount);

        IAmmStorage(poolCfg.ammStorage).subtractLiquidityInternal(redeemAmountStruct.wadRedeemAmount);

        IERC20Upgradeable(asset).safeTransferFrom(poolCfg.ammTreasury, beneficiary, redeemAmountStruct.redeemAmount);

        emit Redeem(
            block.timestamp,
            poolCfg.ammTreasury,
            beneficiary,
            exchangeRate,
            redeemAmountStruct.wadAssetAmount,
            ipTokenAmount,
            redeemAmountStruct.wadRedeemFee,
            redeemAmountStruct.wadRedeemAmount
        );
    }

    function _getPoolConfiguration(address asset) internal view returns (AmmPoolsServicePoolConfiguration memory) {
        if (asset == _usdt) {
            return
                AmmPoolsServicePoolConfiguration({
                    asset: _usdt,
                    decimals: _usdtDecimals,
                    ipToken: _usdtIpToken,
                    ammStorage: _usdtAmmStorage,
                    ammTreasury: _usdtAmmTreasury,
                    assetManagement: _usdtAssetManagement,
                    redeemFeeRate: _usdtRedeemFeeRate,
                    redeemLpMaxCollateralRatio: _usdtRedeemLpMaxCollateralRatio
                });
        } else if (asset == _usdc) {
            return
                AmmPoolsServicePoolConfiguration({
                    asset: _usdc,
                    decimals: _usdcDecimals,
                    ipToken: _usdcIpToken,
                    ammStorage: _usdcAmmStorage,
                    ammTreasury: _usdcAmmTreasury,
                    assetManagement: _usdcAssetManagement,
                    redeemFeeRate: _usdcRedeemFeeRate,
                    redeemLpMaxCollateralRatio: _usdcRedeemLpMaxCollateralRatio
                });
        } else if (asset == _dai) {
            return
                AmmPoolsServicePoolConfiguration({
                    asset: _dai,
                    decimals: _daiDecimals,
                    ipToken: _daiIpToken,
                    ammStorage: _daiAmmStorage,
                    ammTreasury: _daiAmmTreasury,
                    assetManagement: _daiAssetManagement,
                    redeemFeeRate: _daiRedeemFeeRate,
                    redeemLpMaxCollateralRatio: _daiRedeemLpMaxCollateralRatio
                });
        } else {
            revert(IporErrors.ASSET_NOT_SUPPORTED);
        }
    }

    /// @dev Calculate redeem amount
    /// @param ipTokenAmount Amount of ipToken to redeem
    /// @param exchangeRate Exchange rate of ipToken
    /// @return redeemAmount Redeem struct
    function _calculateRedeemAmount(
        uint256 assetDecimals,
        uint256 ipTokenAmount,
        uint256 exchangeRate,
        uint256 cfgRedeemFeeRate
    ) internal pure returns (AmmTypes.RedeemAmount memory redeemAmount) {
        uint256 wadAssetAmount = IporMath.division(ipTokenAmount * exchangeRate, 1e18);
        uint256 wadRedeemFee = IporMath.division(wadAssetAmount * cfgRedeemFeeRate, 1e18);
        uint256 redeemAmountLocal = IporMath.convertWadToAssetDecimals(wadAssetAmount - wadRedeemFee, assetDecimals);

        return
            AmmTypes.RedeemAmount({
                wadAssetAmount: wadAssetAmount,
                wadRedeemFee: wadRedeemFee,
                redeemAmount: redeemAmountLocal,
                wadRedeemAmount: IporMath.convertToWad(redeemAmountLocal, assetDecimals)
            });
    }

    function _rebalanceIfNeededAfterProvideLiquidity(
        AmmPoolsServicePoolConfiguration memory poolCfg,
        StorageLib.AmmPoolsParamsValue memory ammPoolsParamsCfg,
        uint256 vaultBalance,
        uint256 wadOperationAmount
    ) internal {
        /// @dev 1e21 explanation: autoRebalanceThresholdInThousands represents value in thousands without decimals, example threshold=10 it is 10_000*1e18, so to achieve number in 18 decimals we need to multiply by 1e21
        uint256 autoRebalanceThreshold = uint256(ammPoolsParamsCfg.autoRebalanceThresholdInThousands) * 1e21;

        if (autoRebalanceThreshold > 0 && wadOperationAmount >= autoRebalanceThreshold) {
            int256 rebalanceAmount = _calculateRebalanceAmountAfterProvideLiquidity(
                poolCfg.asset,
                IporMath.convertToWad(
                    IERC20Upgradeable(poolCfg.asset).balanceOf(poolCfg.ammTreasury),
                    poolCfg.decimals
                ),
                vaultBalance,
                /// @dev 1e14 explanation: ammTreasuryAndAssetManagementRatio represents percentage in 2 decimals, example 45% = 4500, so to achieve number in 18 decimals we need to multiply by 1e14
                uint256(ammPoolsParamsCfg.ammTreasuryAndAssetManagementRatio) * 1e14
            );

            if (rebalanceAmount > 0) {
                IAmmTreasury(poolCfg.ammTreasury).depositToAssetManagementInternal(rebalanceAmount.toUint256());
            }
        }
    }

    /// @notice Calculate rebalance amount for liquidity provisioning
    /// @param asset Asset address (pool context)
    /// @param wadAmmTreasuryErc20BalanceAfterDeposit AmmTreasury erc20 balance in wad, Notice: this balance is after providing liquidity operation!
    /// @param vaultBalance Vault balance in wad, AssetManagement's accrued balance.
    function _calculateRebalanceAmountAfterProvideLiquidity(
        address asset,
        uint256 wadAmmTreasuryErc20BalanceAfterDeposit,
        uint256 vaultBalance,
        uint256 wadAmmTreasuryAndAssetManagementRatio
    ) internal pure returns (int256) {
        return
            IporMath.divisionInt(
                (wadAmmTreasuryErc20BalanceAfterDeposit + vaultBalance).toInt256() *
                    (1e18 - wadAmmTreasuryAndAssetManagementRatio.toInt256()),
                1e18
            ) - vaultBalance.toInt256();
    }

    function _rebalanceIfNeededBeforeRedeem(
        AmmPoolsServicePoolConfiguration memory poolCfg,
        uint256 wadAmmTreasuryErc20Balance,
        uint256 vaultBalance,
        uint256 wadOperationAmount
    ) internal {
        StorageLib.AmmPoolsParamsValue memory ammPoolsParamsCfg = AmmConfigurationManager.getAmmPoolsParams(
            poolCfg.asset
        );

        /// @dev 1e21 explanation: autoRebalanceThresholdInThousands represents value in thousands without decimals, example threshold=10 it is 10_000*1e18, so to achieve number in 18 decimals we need to multiply by 1e21
        uint256 autoRebalanceThreshold = uint256(ammPoolsParamsCfg.autoRebalanceThresholdInThousands) * 1e21;

        if (
            wadOperationAmount > wadAmmTreasuryErc20Balance ||
            (autoRebalanceThreshold > 0 && wadOperationAmount >= autoRebalanceThreshold)
        ) {
            int256 rebalanceAmount = AssetManagementLogic.calculateRebalanceAmountBeforeWithdraw(
                wadAmmTreasuryErc20Balance,
                vaultBalance,
                wadOperationAmount,
                /// @dev 1e14 explanation: ammTreasuryAndAssetManagementRatio represents percentage in 2 decimals, example 45% = 4500, so to achieve number in 18 decimals we need to multiply by 1e14
                uint256(ammPoolsParamsCfg.ammTreasuryAndAssetManagementRatio) * 1e14
            );

            if (rebalanceAmount < 0) {
                IAmmTreasury(poolCfg.ammTreasury).withdrawFromAssetManagementInternal((-rebalanceAmount).toUint256());
            }
        }
    }

    function _calculateRedeemedCollateralRatio(
        uint256 totalLiquidityPoolBalance,
        uint256 totalCollateralBalance,
        uint256 redeemedAmount
    ) internal pure returns (uint256) {
        if (totalLiquidityPoolBalance <= redeemedAmount) {
            return Constants.MAX_VALUE;
        }

        return IporMath.division(totalCollateralBalance * 1e18, totalLiquidityPoolBalance - redeemedAmount);
    }
}

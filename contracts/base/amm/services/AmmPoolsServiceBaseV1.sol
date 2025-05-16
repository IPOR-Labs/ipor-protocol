// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.26;

import {IERC20Metadata} from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import {SafeERC20Upgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import {IERC20Upgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import {IERC4626} from "@openzeppelin/contracts/interfaces/IERC4626.sol";
import {IProvideLiquidityEvents} from "../../../interfaces/IProvideLiquidityEvents.sol";
import {IAmmTreasuryBaseV2} from "../../../base/interfaces/IAmmTreasuryBaseV2.sol";
import "../../../interfaces/types/IporTypes.sol";
import "../../../interfaces/types/AmmTypes.sol";
import "../../../interfaces/IIpToken.sol";
import "../../../interfaces/IAmmTreasury.sol";
import "../../../interfaces/IAmmPoolsService.sol";
import "../../../interfaces/IAmmStorage.sol";
import "../../../libraries/Constants.sol";
import "../../../libraries/errors/IporErrors.sol";
import "../../../libraries/errors/AmmErrors.sol";
import "../../../libraries/errors/AmmPoolsErrors.sol";
import "../../../libraries/math/IporMath.sol";
import "../../../libraries/IporContractValidator.sol";
import "../../../libraries/AssetManagementLogic.sol";
import "../../../libraries/AmmLib.sol";
import "../../../governance/AmmConfigurationManager.sol";

/// @title Base contract for AMM pools service for Pools with one asset and Asset Management support with one underlying asset same as pool asset.
/// @notice This contract is used for providing liquidity and redeeming liquidity from AMM pools including configured rebalancing between AMM Treasury and Asset Management (like Plasma Vault from Ipor Fusion).
/// @dev It is not recommended to use service contract directly, should be used only through IporProtocolRouter.
contract AmmPoolsServiceBaseV1 is IProvideLiquidityEvents {
    using IporContractValidator for address;
    using SafeCast for int256;
    using SafeCast for uint256;
    using SafeCast for uint32;
    using SafeERC20Upgradeable for IERC20Upgradeable;
    using AmmLib for AmmTypes.AmmPoolCoreModel;

    address public immutable asset;
    uint256 public immutable assetDecimals;
    address public immutable ipToken;
    address public immutable ammTreasury;
    address public immutable ammStorage;
    address public immutable ammAssetManagement;

    address public immutable iporOracle;
    address public immutable iporProtocolRouter;

    uint256 public immutable redeemFeeRate;

    /// @dev Multiplier for auto rebalance threshold param. For stables (USDC, USDC, DAI, USDM, etc) it is 1000 - means in thousands (1000x), for ETH, wstETH etc. is 1 - (1x)
    uint256 public immutable autoRebalanceThresholdMultiplier;

    constructor(
        address asset_,
        address ipToken_,
        address ammTreasury_,
        address ammStorage_,
        address ammAssetManagement_,
        address iporOracle_,
        address iporProtocolRouter_,
        uint256 redeemFeeRate_,
        uint256 autoRebalanceThresholdMultiplier_
    ) {
        asset = asset_.checkAddress();
        assetDecimals = IERC20Metadata(asset).decimals();
        ipToken = ipToken_.checkAddress();
        ammTreasury = ammTreasury_.checkAddress();
        ammStorage = ammStorage_.checkAddress();
        ammAssetManagement = ammAssetManagement_.checkAddress();
        iporOracle = iporOracle_.checkAddress();
        iporProtocolRouter = iporProtocolRouter_.checkAddress();
        redeemFeeRate = redeemFeeRate_;
        autoRebalanceThresholdMultiplier = autoRebalanceThresholdMultiplier_;

        require(redeemFeeRate_ <= 1e18, AmmPoolsErrors.CFG_INVALID_REDEEM_FEE_RATE);

        /// @dev pool asset must match the underlying asset in the AmmAssetManagement vault
        address ammAssetManagementAsset = IERC4626(ammAssetManagement).asset();
        if (ammAssetManagementAsset != asset) {
            revert IporErrors.AssetMismatch(ammAssetManagementAsset, asset);
        }
    }

    function _provideLiquidity(address beneficiary, uint256 assetAmount) internal virtual {
        StorageLib.AmmPoolsParamsValue memory ammPoolsParamsCfg = AmmConfigurationManager.getAmmPoolsParams(asset);

        uint256 actualLiquidityPoolBalance = IAmmTreasuryBaseV2(ammTreasury).getLiquidityPoolBalance();

        uint256 wadAssetAmount = IporMath.convertToWad(assetAmount, assetDecimals);

        uint256 newPoolBalance = actualLiquidityPoolBalance + wadAssetAmount;

        require(
            newPoolBalance <= uint256(ammPoolsParamsCfg.maxLiquidityPoolBalance) * 1e18,
            AmmErrors.LIQUIDITY_POOL_BALANCE_IS_TOO_HIGH
        );

        uint256 exchangeRate = _getExchangeRate(actualLiquidityPoolBalance);

        IERC20Upgradeable(asset).safeTransferFrom(msg.sender, ammTreasury, assetAmount);

        uint256 ipTokenAmount = IporMath.division(wadAssetAmount * 1e18, exchangeRate);

        IIpToken(ipToken).mint(beneficiary, ipTokenAmount);

        /// @dev Order of the following two functions is important, first safeTransferFrom, then rebalanceIfNeededAfterProvideLiquidity.
        _rebalanceIfNeededAfterProvideLiquidity(ammPoolsParamsCfg, wadAssetAmount);

        emit ProvideLiquidity(asset, msg.sender, beneficiary, ammTreasury, exchangeRate, wadAssetAmount, ipTokenAmount);
    }

    function _redeem(address beneficiary, uint256 ipTokenAmount) internal virtual {
        require(
            ipTokenAmount > 0 && ipTokenAmount <= IIpToken(ipToken).balanceOf(msg.sender),
            AmmPoolsErrors.CANNOT_REDEEM_IP_TOKEN_TOO_LOW
        );
        require(beneficiary != address(0), IporErrors.WRONG_ADDRESS);

        uint256 actualLiquidityPoolBalance = IAmmTreasuryBaseV2(ammTreasury).getLiquidityPoolBalance();

        uint256 exchangeRate = _getExchangeRate(actualLiquidityPoolBalance);

        uint256 wadAssetAmount = IporMath.division(ipTokenAmount * exchangeRate, 1e18);

        uint256 amountToRedeem = IporMath.convertWadToAssetDecimals(
            IporMath.division(wadAssetAmount * (1e18 - redeemFeeRate), 1e18),
            assetDecimals
        );

        uint256 wadAmountToRedeem = IporMath.convertToWad(amountToRedeem, assetDecimals);

        require(amountToRedeem > 0 && wadAmountToRedeem > 0, AmmPoolsErrors.CANNOT_REDEEM_ASSET_AMOUNT_TOO_LOW);

        _rebalanceIfNeededBeforeRedeem(wadAmountToRedeem);

        IIpToken(ipToken).burn(msg.sender, ipTokenAmount);

        IERC20Upgradeable(asset).safeTransferFrom(ammTreasury, beneficiary, amountToRedeem);

        emit Redeem(
            asset,
            ammTreasury,
            msg.sender,
            beneficiary,
            exchangeRate,
            wadAssetAmount,
            wadAmountToRedeem,
            ipTokenAmount
        );
    }

    function _rebalanceBetweenAmmTreasuryAndAssetManagement() internal virtual {
        require(
            AmmConfigurationManager.isAppointedToRebalanceInAmm(asset, msg.sender),
            AmmPoolsErrors.CALLER_NOT_APPOINTED_TO_REBALANCE
        );

        StorageLib.AmmPoolsParamsValue memory ammPoolsParamsCfg = AmmConfigurationManager.getAmmPoolsParams(asset);

        uint256 wadAmmTreasuryAssetBalance = IporMath.convertToWad(
            IERC20Upgradeable(asset).balanceOf(ammTreasury),
            assetDecimals
        );

        uint256 wadTotalBalance = wadAmmTreasuryAssetBalance +
            IporMath.convertToWad(IERC4626(ammAssetManagement).maxWithdraw(ammTreasury), assetDecimals);

        require(wadTotalBalance > 0, AmmPoolsErrors.ASSET_MANAGEMENT_BALANCE_IS_EMPTY);

        uint256 ratio = IporMath.division(wadAmmTreasuryAssetBalance * 1e18, wadTotalBalance);

        /// @dev 1e14 explanation: ammTreasuryAndAssetManagementRatio represents percentage in 2 decimals, example 45% = 4500, so to achieve number in 18 decimals we need to multiply by 1e14
        uint256 ammTreasuryAssetManagementBalanceRatio = uint256(ammPoolsParamsCfg.ammTreasuryAndAssetManagementRatio) *
                    1e14;

        if (ratio > ammTreasuryAssetManagementBalanceRatio) {
            uint256 wadAssetAmount = wadAmmTreasuryAssetBalance -
                                IporMath.division(ammTreasuryAssetManagementBalanceRatio * wadTotalBalance, 1e18);
            if (wadAssetAmount > 0) {
                IAmmTreasuryBaseV2(ammTreasury).depositToAssetManagementInternal(wadAssetAmount);
            }
        } else {
            uint256 wadAssetAmount = IporMath.division(ammTreasuryAssetManagementBalanceRatio * wadTotalBalance, 1e18) -
                        wadAmmTreasuryAssetBalance;
            if (wadAssetAmount > 0) {
                IAmmTreasuryBaseV2(ammTreasury).withdrawFromAssetManagementInternal(wadAssetAmount);
            }
        }
    }

    function _getExchangeRate(uint256 actualLiquidityPoolBalance) internal view returns (uint256) {
        AmmTypes.AmmPoolCoreModel memory model = AmmTypes.AmmPoolCoreModel({
            asset: asset,
            assetDecimals: 18,
            ipToken: ipToken,
            ammStorage: ammStorage,
            ammTreasury: ammTreasury,
            assetManagement: ammAssetManagement,
            iporOracle: iporOracle
        });
        return model.getExchangeRate(actualLiquidityPoolBalance);
    }

    function _rebalanceIfNeededAfterProvideLiquidity(
        StorageLib.AmmPoolsParamsValue memory ammPoolsParamsCfg,
        uint256 wadOperationAmount
    ) internal {
        /// @dev 1e18 * autoRebalanceThresholdMultiplier explanation: autoRebalanceThreshold represents value without decimals, selected asset can have different multiplier, for example for stables is 1000x, value in thousands, for ETH, wstETH etc. is 1x
        uint256 autoRebalanceThreshold = uint256(ammPoolsParamsCfg.autoRebalanceThreshold) *
            1e18 *
            autoRebalanceThresholdMultiplier;

        if (autoRebalanceThreshold > 0 && wadOperationAmount >= autoRebalanceThreshold) {
            int256 rebalanceAmount = AssetManagementLogic.calculateRebalanceAmountAfterProvideLiquidity(
                IporMath.convertToWad(IERC20Upgradeable(asset).balanceOf(ammTreasury), assetDecimals),
                /// @dev Notice! Plasma Vault underlying asset is the same as the pool asset
                IporMath.convertToWad(IERC4626(ammAssetManagement).maxWithdraw(ammTreasury), assetDecimals),
                /// @dev 1e14 explanation: ammTreasuryAndAssetManagementRatio represents percentage in 2 decimals, example 45% = 4500, so to achieve number in 18 decimals we need to multiply by 1e14
                uint256(ammPoolsParamsCfg.ammTreasuryAndAssetManagementRatio) * 1e14
            );

            if (rebalanceAmount > 0) {
                IAmmTreasuryBaseV2(ammTreasury).depositToAssetManagementInternal(rebalanceAmount.toUint256());
            }
        }
    }

    function _rebalanceIfNeededBeforeRedeem(uint256 wadOperationAmount) internal {
        uint256 wadAmmTreasuryErc20Balance = IporMath.convertToWad(
            IERC20Upgradeable(asset).balanceOf(ammTreasury),
            assetDecimals
        );

        StorageLib.AmmPoolsParamsValue memory ammPoolsParamsCfg = AmmConfigurationManager.getAmmPoolsParams(asset);

        /// @dev 1e18 * autoRebalanceThresholdMultiplier explanation: autoRebalanceThreshold represents value without decimals, selected asset can have different multiplier, for example for stables is 1000x, value in thousands, for ETH, wstETH etc. is 1x
        uint256 autoRebalanceThreshold = uint256(ammPoolsParamsCfg.autoRebalanceThreshold) *
            1e18 *
            autoRebalanceThresholdMultiplier;

        if (
            wadOperationAmount > wadAmmTreasuryErc20Balance ||
            (autoRebalanceThreshold > 0 && wadOperationAmount >= autoRebalanceThreshold)
        ) {
            int256 rebalanceAmount = AssetManagementLogic.calculateRebalanceAmountBeforeWithdraw(
                wadAmmTreasuryErc20Balance,
                /// @dev Notice! Plasma Vault underlying asset is the same as the pool asset
                IporMath.convertToWad(IERC4626(ammAssetManagement).maxWithdraw(ammTreasury), assetDecimals),
                wadOperationAmount,
                /// @dev 1e14 explanation: ammTreasuryAndAssetManagementRatio represents percentage in 2 decimals, example 45% = 4500, so to achieve number in 18 decimals we need to multiply by 1e14
                uint256(ammPoolsParamsCfg.ammTreasuryAndAssetManagementRatio) * 1e14
            );

            if (rebalanceAmount < 0) {
                IAmmTreasuryBaseV2(ammTreasury).withdrawFromAssetManagementInternal((- rebalanceAmount).toUint256());
            }
        }
    }
}

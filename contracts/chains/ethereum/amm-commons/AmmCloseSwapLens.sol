// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.26;

import "@openzeppelin/contracts/utils/Address.sol";

import "../../../interfaces/types/IporTypes.sol";
import "../../../interfaces/types/AmmTypes.sol";
import "../../../interfaces/IIporOracle.sol";
import "../../../interfaces/IAmmCloseSwapLens.sol";
import "../../../interfaces/IAmmCloseSwapService.sol";
import "../../../libraries/errors/IporErrors.sol";
import "../../../libraries/IporContractValidator.sol";
import "../../../libraries/AmmCloseSwapServicePoolConfigurationLib.sol";
import "../../../amm/libraries/SwapCloseLogicLib.sol";
import "../../../base/types/AmmTypesBaseV1.sol";
import "../../../base/amm/libraries/SwapLogicBaseV1.sol";
import "../../../base/amm/libraries/SwapCloseLogicLibBaseV1.sol";
import "../../../base/amm/services/AmmCloseSwapServiceBaseV1.sol";

/// @dev It is not recommended to use service contract directly, should be used only through IporProtocolRouter.
contract AmmCloseSwapLens is IAmmCloseSwapLens {
    using Address for address;
    using IporContractValidator for address;
    using SwapLogicBaseV1 for AmmTypesBaseV1.Swap;
    using AmmCloseSwapServicePoolConfigurationLib for IAmmCloseSwapLens.AmmCloseSwapServicePoolConfiguration;

    address public immutable usdt;
    address public immutable usdc;
    address public immutable dai;
    address public immutable stETH;
    address public immutable iporOracle;

    constructor(
        address usdt_,
        address usdc_,
        address dai_,
        address stETH_,
        address iporOracle_
    ) {
        usdt = usdt_.checkAddress();
        usdc = usdc_.checkAddress();
        dai = dai_.checkAddress();
        stETH = stETH_.checkAddress();
        iporOracle = iporOracle_.checkAddress();
    }

    function getAmmCloseSwapServicePoolConfiguration(
        address asset_
    ) external view override returns (AmmCloseSwapServicePoolConfiguration memory) {
        StorageLibBaseV1.AssetServicesValue memory servicesCfg = StorageLibBaseV1.getAssetServicesStorage().value[
            asset_
        ];

        if (servicesCfg.ammCloseSwapService != address(0)) {
            return IAmmCloseSwapService(servicesCfg.ammCloseSwapService).getPoolConfiguration();
        } else {
            revert IporErrors.UnsupportedAsset(IporErrors.ASSET_NOT_SUPPORTED, asset_);
        }
    }

    function getClosingSwapDetails(
        address asset,
        address account,
        AmmTypes.SwapDirection direction,
        uint256 swapId,
        uint256 closeTimestamp,
        AmmTypes.CloseSwapRiskIndicatorsInput calldata riskIndicatorsInput
    ) external view override returns (AmmTypes.ClosingSwapDetails memory closingSwapDetails) {
        if (asset == usdt || asset == usdc || asset == dai) {
            closingSwapDetails = _getClosingSwapDetailsForStable(
                asset,
                account,
                direction,
                swapId,
                closeTimestamp,
                riskIndicatorsInput
            );
        } else if (asset == stETH) {
            closingSwapDetails = _getClosingSwapDetailsForStEth(
                account,
                direction,
                swapId,
                closeTimestamp,
                riskIndicatorsInput
            );
        } else {
            revert IporErrors.UnsupportedAsset(IporErrors.ASSET_NOT_SUPPORTED, asset);
        }
    }

    function _getClosingSwapDetailsForStable(
        address asset,
        address account,
        AmmTypes.SwapDirection direction,
        uint256 swapId,
        uint256 closeTimestamp,
        AmmTypes.CloseSwapRiskIndicatorsInput calldata riskIndicatorsInput
    ) internal view returns (AmmTypes.ClosingSwapDetails memory closingSwapDetails) {
        StorageLibBaseV1.AssetServicesValue memory servicesCfg = StorageLibBaseV1.getAssetServicesStorage().value[
            asset
        ];

        if (servicesCfg.ammCloseSwapService == address(0)) {
            revert IporErrors.UnsupportedAsset(IporErrors.ASSET_NOT_SUPPORTED, asset);
        }

        IAmmCloseSwapLens.AmmCloseSwapServicePoolConfiguration memory poolCfg = IAmmCloseSwapService(
            servicesCfg.ammCloseSwapService
        ).getPoolConfiguration();

        IporTypes.AccruedIpor memory accruedIpor = IIporOracle(iporOracle).getAccruedIndex(
            block.timestamp,
            poolCfg.asset
        );

        AmmTypes.Swap memory swap = IAmmStorage(poolCfg.ammStorage).getSwap(direction, swapId);

        require(swap.id > 0, AmmErrors.INCORRECT_SWAP_ID);

        int256 swapPnlValueToDate;

        if (direction == AmmTypes.SwapDirection.PAY_FIXED_RECEIVE_FLOATING) {
            swapPnlValueToDate = SwapLogicBaseV1.calculatePnlPayFixed(
                swap.openTimestamp,
                swap.collateral,
                swap.notional,
                swap.fixedInterestRate,
                swap.ibtQuantity,
                block.timestamp,
                accruedIpor.ibtPrice
            );
        } else if (direction == AmmTypes.SwapDirection.PAY_FLOATING_RECEIVE_FIXED) {
            swapPnlValueToDate = SwapLogicBaseV1.calculatePnlReceiveFixed(
                swap.openTimestamp,
                swap.collateral,
                swap.notional,
                swap.fixedInterestRate,
                swap.ibtQuantity,
                block.timestamp,
                accruedIpor.ibtPrice
            );
        } else {
            revert(AmmErrors.UNSUPPORTED_DIRECTION);
        }

        (closingSwapDetails.closableStatus, closingSwapDetails.swapUnwindRequired) = SwapCloseLogicLibBaseV1
            .getClosableStatusForSwap(
                AmmTypesBaseV1.ClosableSwapInput({
                    account: account,
                    asset: poolCfg.asset,
                    closeTimestamp: closeTimestamp,
                    swapBuyer: swap.buyer,
                    swapOpenTimestamp: swap.openTimestamp,
                    swapCollateral: swap.collateral,
                    swapTenor: swap.tenor,
                    swapState: swap.state,
                    swapPnlValueToDate: swapPnlValueToDate,
                    minLiquidationThresholdToCloseBeforeMaturityByCommunity: poolCfg
                        .minLiquidationThresholdToCloseBeforeMaturityByCommunity,
                    minLiquidationThresholdToCloseBeforeMaturityByBuyer: poolCfg
                        .minLiquidationThresholdToCloseBeforeMaturityByBuyer,
                    timeBeforeMaturityAllowedToCloseSwapByCommunity: poolCfg
                        .timeBeforeMaturityAllowedToCloseSwapByCommunity,
                    timeBeforeMaturityAllowedToCloseSwapByBuyer: poolCfg.getTimeBeforeMaturityAllowedToCloseSwapByBuyer(
                        swap.tenor
                    ),
                    timeAfterOpenAllowedToCloseSwapWithUnwinding: poolCfg
                        .getTimeAfterOpenAllowedToCloseSwapWithUnwinding(swap.tenor)
                })
            );

        if (closingSwapDetails.swapUnwindRequired == true) {
            (
                closingSwapDetails.swapUnwindPnlValue,
                closingSwapDetails.swapUnwindOpeningFeeAmount,
                closingSwapDetails.swapUnwindFeeLPAmount,
                closingSwapDetails.swapUnwindFeeTreasuryAmount,
                closingSwapDetails.pnlValue
            ) = SwapCloseLogicLib.calculateSwapUnwindWhenUnwindRequired(
                AmmTypes.UnwindParams({
                    messageSigner: StorageLibBaseV1.getMessageSignerStorage().value,
                    spreadRouter: poolCfg.spread,
                    ammStorage: poolCfg.ammStorage,
                    ammTreasury: poolCfg.ammTreasury,
                    direction: direction,
                    closeTimestamp: closeTimestamp,
                    swapPnlValueToDate: swapPnlValueToDate,
                    indexValue: accruedIpor.indexValue,
                    swap: swap,
                    poolCfg: poolCfg,
                    riskIndicatorsInputs: riskIndicatorsInput
                })
            );
        } else {
            closingSwapDetails.pnlValue = swapPnlValueToDate;
        }
    }

    function _getClosingSwapDetailsForStEth(
        address account,
        AmmTypes.SwapDirection direction,
        uint256 swapId,
        uint256 closeTimestamp,
        AmmTypes.CloseSwapRiskIndicatorsInput calldata riskIndicatorsInput
    ) internal view returns (AmmTypes.ClosingSwapDetails memory closingSwapDetails) {
        StorageLibBaseV1.AssetServicesValue memory servicesCfg = StorageLibBaseV1.getAssetServicesStorage().value[
            stETH
        ];

        if (servicesCfg.ammCloseSwapService == address(0)) {
            revert IporErrors.UnsupportedAsset(IporErrors.ASSET_NOT_SUPPORTED, stETH);
        }

        IAmmCloseSwapLens.AmmCloseSwapServicePoolConfiguration memory poolCfg = IAmmCloseSwapService(
            servicesCfg.ammCloseSwapService
        ).getPoolConfiguration();

        IporTypes.AccruedIpor memory accruedIpor = IIporOracle(iporOracle).getAccruedIndex(
            block.timestamp,
            poolCfg.asset
        );

        AmmTypesBaseV1.Swap memory swap = IAmmStorageBaseV1(poolCfg.ammStorage).getSwap(direction, swapId);

        require(swap.id > 0, AmmErrors.INCORRECT_SWAP_ID);

        int256 swapPnlValueToDate = swap.calculatePnl(block.timestamp, accruedIpor.ibtPrice);

        (closingSwapDetails.closableStatus, closingSwapDetails.swapUnwindRequired) = SwapCloseLogicLibBaseV1
            .getClosableStatusForSwap(
                AmmTypesBaseV1.ClosableSwapInput({
                    account: account,
                    asset: poolCfg.asset,
                    closeTimestamp: closeTimestamp,
                    swapBuyer: swap.buyer,
                    swapOpenTimestamp: swap.openTimestamp,
                    swapCollateral: swap.collateral,
                    swapTenor: swap.tenor,
                    swapState: swap.state,
                    swapPnlValueToDate: swapPnlValueToDate,
                    minLiquidationThresholdToCloseBeforeMaturityByCommunity: poolCfg
                        .minLiquidationThresholdToCloseBeforeMaturityByCommunity,
                    minLiquidationThresholdToCloseBeforeMaturityByBuyer: poolCfg
                        .minLiquidationThresholdToCloseBeforeMaturityByBuyer,
                    timeBeforeMaturityAllowedToCloseSwapByCommunity: poolCfg
                        .timeBeforeMaturityAllowedToCloseSwapByCommunity,
                    timeBeforeMaturityAllowedToCloseSwapByBuyer: poolCfg.getTimeBeforeMaturityAllowedToCloseSwapByBuyer(
                        swap.tenor
                    ),
                    timeAfterOpenAllowedToCloseSwapWithUnwinding: poolCfg
                        .getTimeAfterOpenAllowedToCloseSwapWithUnwinding(swap.tenor)
                })
            );

        if (closingSwapDetails.swapUnwindRequired == true) {
            (
                closingSwapDetails.swapUnwindPnlValue,
                closingSwapDetails.swapUnwindOpeningFeeAmount,
                closingSwapDetails.swapUnwindFeeLPAmount,
                closingSwapDetails.swapUnwindFeeTreasuryAmount,
                closingSwapDetails.pnlValue
            ) = SwapCloseLogicLibBaseV1.calculateSwapUnwindWhenUnwindRequired(
                AmmTypesBaseV1.UnwindParams({
                    asset: poolCfg.asset,
                    messageSigner: StorageLibBaseV1.getMessageSignerStorage().value,
                    spread: poolCfg.spread,
                    ammStorage: poolCfg.ammStorage,
                    ammTreasury: poolCfg.ammTreasury,
                    closeTimestamp: closeTimestamp,
                    swapPnlValueToDate: swapPnlValueToDate,
                    indexValue: accruedIpor.indexValue,
                    swap: swap,
                    unwindingFeeRate: poolCfg.unwindingFeeRate,
                    unwindingFeeTreasuryPortionRate: poolCfg.unwindingFeeTreasuryPortionRate,
                    riskIndicatorsInputs: riskIndicatorsInput
                })
            );
        } else {
            closingSwapDetails.pnlValue = swapPnlValueToDate;
        }
    }
}

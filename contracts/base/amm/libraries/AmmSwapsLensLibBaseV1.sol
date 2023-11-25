// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.20;
import "../../../interfaces/IAmmSwapsLens.sol";
import {IAmmSwapsLens} from "../../../interfaces/IAmmSwapsLens.sol";
import "../../../interfaces/IIporOracle.sol";
import "../../../libraries/math/IporMath.sol";
import "../../../libraries/RiskIndicatorsValidatorLib.sol";
import "../../types/AmmTypesBaseV1.sol";
import "../../interfaces/IAmmStorageBaseV1.sol";
import "../../interfaces/ISpreadBaseV1.sol";
import "../../interfaces/IAmmTreasuryBaseV1.sol";
import "./SwapLogicBaseV1.sol";

library AmmSwapsLensLibBaseV1 {
    using SwapLogicBaseV1 for AmmTypesBaseV1.Swap;
    using RiskIndicatorsValidatorLib for AmmTypes.RiskIndicatorsInputs;

    function getBalancesForOpenSwap(
        address ammStorage,
        address ammTreasury
    ) internal view returns (IporTypes.AmmBalancesForOpenSwapMemory memory) {
        AmmTypesBaseV1.AmmBalanceForOpenSwap memory balance = IAmmStorageBaseV1(ammStorage).getBalancesForOpenSwap();
        return
            IporTypes.AmmBalancesForOpenSwapMemory({
                totalCollateralPayFixed: balance.totalCollateralPayFixed,
                totalNotionalPayFixed: balance.totalNotionalPayFixed,
                totalCollateralReceiveFixed: balance.totalCollateralReceiveFixed,
                totalNotionalReceiveFixed: balance.totalNotionalReceiveFixed,
                liquidityPool: IAmmTreasuryBaseV1(ammTreasury).getLiquidityPoolBalance()
            });
    }

    function getOfferedRate(
        IAmmSwapsLens.SwapLensPoolConfiguration memory poolCfg,
        uint256 indexValue,
        IporTypes.SwapTenor tenor,
        uint256 swapNotional,
        address messageSigner,
        AmmTypes.OpenSwapRiskIndicators memory swapRiskIndicatorsPayFixed,
        AmmTypes.OpenSwapRiskIndicators memory swapRiskIndicatorsReceiveFixed
    ) internal view returns (uint256 offeredRatePayFixed, uint256 offeredRateReceiveFixed) {
        AmmTypesBaseV1.AmmBalanceForOpenSwap memory balance = IAmmStorageBaseV1(poolCfg.ammStorage)
            .getBalancesForOpenSwap();
        uint256 liquidityPoolBalance = IAmmTreasuryBaseV1(poolCfg.ammTreasury).getLiquidityPoolBalance();

        offeredRatePayFixed = ISpreadBaseV1(poolCfg.spread).calculateOfferedRatePayFixed(
            ISpreadBaseV1.SpreadInputs({
                asset: poolCfg.asset,
                swapNotional: swapNotional,
                demandSpreadFactor: swapRiskIndicatorsPayFixed.demandSpreadFactor,
                baseSpreadPerLeg: swapRiskIndicatorsPayFixed.baseSpreadPerLeg,
                totalCollateralPayFixed: balance.totalCollateralPayFixed,
                totalCollateralReceiveFixed: balance.totalCollateralReceiveFixed,
                liquidityPoolBalance: liquidityPoolBalance,
                iporIndexValue: indexValue,
                fixedRateCapPerLeg: swapRiskIndicatorsPayFixed.fixedRateCapPerLeg,
                tenor: tenor
            })
        );

        offeredRateReceiveFixed = ISpreadBaseV1(poolCfg.spread).calculateOfferedRateReceiveFixed(
            ISpreadBaseV1.SpreadInputs({
                asset: poolCfg.asset,
                swapNotional: swapNotional,
                demandSpreadFactor: swapRiskIndicatorsReceiveFixed.demandSpreadFactor,
                baseSpreadPerLeg: swapRiskIndicatorsReceiveFixed.baseSpreadPerLeg,
                totalCollateralPayFixed: balance.totalCollateralPayFixed,
                totalCollateralReceiveFixed: balance.totalCollateralReceiveFixed,
                liquidityPoolBalance: liquidityPoolBalance,
                iporIndexValue: indexValue,
                fixedRateCapPerLeg: swapRiskIndicatorsReceiveFixed.fixedRateCapPerLeg,
                tenor: tenor
            })
        );
    }

    function getSwaps(
        address iporOracle,
        address ammStorage,
        address asset,
        address account,
        uint256 offset,
        uint256 chunkSize
    ) external view returns (uint256 totalCount, IAmmSwapsLens.IporSwap[] memory swaps) {
        IAmmStorageBaseV1 ammStorageBaseV1 = IAmmStorageBaseV1(ammStorage);
        (uint256 count, AmmStorageTypes.IporSwapId[] memory swapIds) = ammStorageBaseV1.getSwapIds(
            account,
            offset,
            chunkSize
        );
        return (count, _mapSwaps(iporOracle, asset, ammStorageBaseV1, swapIds));
    }

    function getPnlPayFixed(
        address iporOracle,
        address ammStorage,
        address asset,
        uint256 swapId
    ) internal view returns (int256) {
        uint256 accruedIbtPrice = IIporOracle(iporOracle).calculateAccruedIbtPrice(asset, block.timestamp);

        AmmTypesBaseV1.Swap memory swapBaseV1 = IAmmStorageBaseV1(ammStorage).getSwap(
            AmmTypes.SwapDirection.PAY_FIXED_RECEIVE_FLOATING,
            swapId
        );

        require(swapBaseV1.id > 0, AmmErrors.INCORRECT_SWAP_ID);

        return swapBaseV1.calculatePnlPayFixed(block.timestamp, accruedIbtPrice);
    }

    function getPnlReceiveFixed(
        address iporOracle,
        address ammStorage,
        address asset,
        uint256 swapId
    ) internal view returns (int256) {
        uint256 accruedIbtPrice = IIporOracle(iporOracle).calculateAccruedIbtPrice(asset, block.timestamp);

        AmmTypesBaseV1.Swap memory swapBaseV1 = IAmmStorageBaseV1(ammStorage).getSwap(
            AmmTypes.SwapDirection.PAY_FLOATING_RECEIVE_FIXED,
            swapId
        );

        require(swapBaseV1.id > 0, AmmErrors.INCORRECT_SWAP_ID);

        return swapBaseV1.calculatePnlReceiveFixed(block.timestamp, accruedIbtPrice);
    }

    function _mapSwaps(
        address iporOracle,
        address asset,
        IAmmStorageBaseV1 ammStorage,
        AmmStorageTypes.IporSwapId[] memory swapIds
    ) private view returns (IAmmSwapsLens.IporSwap[] memory swaps) {
        uint256 accruedIbtPrice = IIporOracle(iporOracle).calculateAccruedIbtPrice(asset, block.timestamp);
        uint256 swapCount = swapIds.length;

        IAmmSwapsLens.IporSwap[] memory mappedSwaps = new IAmmSwapsLens.IporSwap[](swapCount);
        AmmStorageTypes.IporSwapId memory swapId;
        AmmTypesBaseV1.Swap memory swap;
        int256 swapValue;

        for (uint256 i; i != swapCount; ) {
            swapId = swapIds[i];

            if (swapId.direction == 0) {
                swap = ammStorage.getSwap(AmmTypes.SwapDirection.PAY_FIXED_RECEIVE_FLOATING, swapId.id);
                swapValue = swap.calculatePnlPayFixed(block.timestamp, accruedIbtPrice);
                mappedSwaps[i] = _mapSwap(asset, swap, swapValue);
            } else {
                swap = ammStorage.getSwap(AmmTypes.SwapDirection.PAY_FLOATING_RECEIVE_FIXED, swapId.id);
                swapValue = swap.calculatePnlReceiveFixed(block.timestamp, accruedIbtPrice);
                mappedSwaps[i] = _mapSwap(asset, swap, swapValue);
            }
            unchecked {
                ++i;
            }
        }
        return mappedSwaps;
    }

    function _mapSwap(
        address asset,
        AmmTypesBaseV1.Swap memory swap,
        int256 pnlValue
    ) private pure returns (IAmmSwapsLens.IporSwap memory) {
        return
            IAmmSwapsLens.IporSwap({
                id: swap.id,
                asset: asset,
                buyer: swap.buyer,
                collateral: swap.collateral,
                notional: swap.notional,
                leverage: IporMath.division(swap.notional * 1e18, swap.collateral),
                direction: uint256(swap.direction),
                ibtQuantity: swap.ibtQuantity,
                fixedInterestRate: swap.fixedInterestRate,
                pnlValue: pnlValue,
                openTimestamp: swap.openTimestamp,
                endTimestamp: SwapLogicBaseV1.getSwapEndTimestamp(swap.openTimestamp, swap.tenor),
                liquidationDepositAmount: swap.wadLiquidationDepositAmount,
                state: uint256(swap.state)
            });
    }
}

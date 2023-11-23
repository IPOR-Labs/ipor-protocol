// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.20;
import "../../../interfaces/IAmmSwapsLens.sol";
import {IAmmSwapsLens} from "../../../interfaces/IAmmSwapsLens.sol";
import "../../../interfaces/IIporOracle.sol";
import "../../../libraries/math/IporMath.sol";
import "../../../libraries/RiskIndicatorsValidatorLib.sol";
import "../../types/AmmTypesGenOne.sol";
import "../../interfaces/IAmmStorageGenOne.sol";
import "../../interfaces/ISpreadGenOne.sol";
import "../../interfaces/IAmmTreasuryGenOne.sol";
import "./SwapLogicGenOne.sol";

library AmmSwapsLensLibGenOne {
    using SwapLogicGenOne for AmmTypesGenOne.Swap;
    using RiskIndicatorsValidatorLib for AmmTypes.RiskIndicatorsInputs;

    function getBalancesForOpenSwap(
        address ammStorage,
        address ammTreasury
    ) internal view returns (IporTypes.AmmBalancesForOpenSwapMemory memory) {
        AmmTypesGenOne.AmmBalanceForOpenSwap memory balance = IAmmStorageGenOne(ammStorage).getBalancesForOpenSwap();
        return
            IporTypes.AmmBalancesForOpenSwapMemory({
                totalCollateralPayFixed: balance.totalCollateralPayFixed,
                totalNotionalPayFixed: balance.totalNotionalPayFixed,
                totalCollateralReceiveFixed: balance.totalCollateralReceiveFixed,
                totalNotionalReceiveFixed: balance.totalNotionalReceiveFixed,
                liquidityPool: IAmmTreasuryGenOne(ammTreasury).getLiquidityPoolBalance()
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
        AmmTypesGenOne.AmmBalanceForOpenSwap memory balance = IAmmStorageGenOne(poolCfg.ammStorage)
            .getBalancesForOpenSwap();
        uint256 liquidityPoolBalance = IAmmTreasuryGenOne(poolCfg.ammTreasury).getLiquidityPoolBalance();

        offeredRatePayFixed = ISpreadGenOne(poolCfg.spread).calculateOfferedRatePayFixed(
            ISpreadGenOne.SpreadInputs({
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

        offeredRateReceiveFixed = ISpreadGenOne(poolCfg.spread).calculateOfferedRateReceiveFixed(
            ISpreadGenOne.SpreadInputs({
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
        IAmmStorageGenOne ammStorageGenOne = IAmmStorageGenOne(ammStorage);
        (uint256 count, AmmStorageTypes.IporSwapId[] memory swapIds) = ammStorageGenOne.getSwapIds(
            account,
            offset,
            chunkSize
        );
        return (count, _mapSwaps(iporOracle, asset, ammStorageGenOne, swapIds));
    }

    function getPnlPayFixed(
        address iporOracle,
        address ammStorage,
        address asset,
        uint256 swapId
    ) internal view returns (int256) {
        uint256 accruedIbtPrice = IIporOracle(iporOracle).calculateAccruedIbtPrice(asset, block.timestamp);

        AmmTypesGenOne.Swap memory swapGenOne = IAmmStorageGenOne(ammStorage).getSwap(
            AmmTypes.SwapDirection.PAY_FIXED_RECEIVE_FLOATING,
            swapId
        );

        require(swapGenOne.id > 0, AmmErrors.INCORRECT_SWAP_ID);

        return swapGenOne.calculatePnlPayFixed(block.timestamp, accruedIbtPrice);
    }

    function getPnlReceiveFixed(
        address iporOracle,
        address ammStorage,
        address asset,
        uint256 swapId
    ) internal view returns (int256) {
        uint256 accruedIbtPrice = IIporOracle(iporOracle).calculateAccruedIbtPrice(asset, block.timestamp);

        AmmTypesGenOne.Swap memory swapGenOne = IAmmStorageGenOne(ammStorage).getSwap(
            AmmTypes.SwapDirection.PAY_FLOATING_RECEIVE_FIXED,
            swapId
        );

        require(swapGenOne.id > 0, AmmErrors.INCORRECT_SWAP_ID);

        return swapGenOne.calculatePnlReceiveFixed(block.timestamp, accruedIbtPrice);
    }

    function _mapSwaps(
        address iporOracle,
        address asset,
        IAmmStorageGenOne ammStorage,
        AmmStorageTypes.IporSwapId[] memory swapIds
    ) private view returns (IAmmSwapsLens.IporSwap[] memory swaps) {
        uint256 accruedIbtPrice = IIporOracle(iporOracle).calculateAccruedIbtPrice(asset, block.timestamp);
        uint256 swapCount = swapIds.length;

        IAmmSwapsLens.IporSwap[] memory mappedSwaps = new IAmmSwapsLens.IporSwap[](swapCount);
        AmmStorageTypes.IporSwapId memory swapId;
        AmmTypesGenOne.Swap memory swap;
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
        AmmTypesGenOne.Swap memory swap,
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
                endTimestamp: swap.getSwapEndTimestamp(),
                liquidationDepositAmount: swap.wadLiquidationDepositAmount,
                state: uint256(swap.state)
            });
    }
}

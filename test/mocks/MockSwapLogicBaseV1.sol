// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.20;

import "../../contracts/interfaces/types/IporTypes.sol";
import "../../contracts/base/amm/libraries/SwapLogicBaseV1.sol";
import "../../contracts/base/amm/libraries/SwapCloseLogicLibBaseV1.sol";

contract MockSwapLogicBaseV1 {
    function calculateSwapAmount(
        IporTypes.SwapTenor tenor,
        uint256 totalAmount,
        uint256 leverage,
        uint256 wadLiquidationDepositAmount,
        uint256 iporPublicationFeeAmount,
        uint256 openingFeeRate
    ) public view returns (uint256 collateral, uint256 notional, uint256 openingFee) {
        return
            SwapLogicBaseV1.calculateSwapAmount(
                tenor,
                totalAmount,
                leverage,
                wadLiquidationDepositAmount,
                iporPublicationFeeAmount,
                openingFeeRate
            );
    }

    function calculateInterest(
        AmmTypesBaseV1.Swap memory swap,
        uint256 closingTimestamp,
        uint256 mdIbtPrice
    ) public pure returns (uint256 interestFixed, uint256 interestFloating) {
        return
            SwapLogicBaseV1.calculateInterest(
                swap.openTimestamp,
                swap.notional,
                swap.fixedInterestRate,
                swap.ibtQuantity,
                closingTimestamp,
                mdIbtPrice
            );
    }

    function calculatePnlPayFixed(
        AmmTypesBaseV1.Swap memory swap,
        uint256 closingTimestamp,
        uint256 mdIbtPrice
    ) public pure returns (int256 swapValue) {
        swapValue = SwapLogicBaseV1.calculatePnlPayFixed(
            swap.openTimestamp,
            swap.collateral,
            swap.notional,
            swap.fixedInterestRate,
            swap.ibtQuantity,
            closingTimestamp,
            mdIbtPrice
        );
    }

    function calculatePnlReceiveFixed(
        AmmTypesBaseV1.Swap memory swap,
        uint256 closingTimestamp,
        uint256 mdIbtPrice
    ) public pure returns (int256 swapValue) {
        swapValue = SwapLogicBaseV1.calculatePnlReceiveFixed(
            swap.openTimestamp,
            swap.collateral,
            swap.notional,
            swap.fixedInterestRate,
            swap.ibtQuantity,
            closingTimestamp,
            mdIbtPrice
        );
    }

    function calculateSwapUnwindPnlValue(
        AmmTypesBaseV1.Swap memory swap,
        AmmTypes.SwapDirection direction,
        uint256 closingTimestamp,
        uint256 oppositeLegFixedRate
    ) public pure returns (int256 swapUnwindAmount) {
        swapUnwindAmount = SwapCloseLogicLibBaseV1.calculateSwapUnwindPnlValue(
            swap,
            closingTimestamp,
            oppositeLegFixedRate
        );
    }

    function calculateSwapUnwindOpeningFeeAmount(
        uint256 swapOpenTimestamp,
        uint256 swapNotional,
        IporTypes.SwapTenor swapTenor,
        uint256 closingTimestamp,
        uint256 openingFeeRateCfg
    ) public pure returns (uint256 swapOpeningFeeAmount) {
        swapOpeningFeeAmount = SwapCloseLogicLibBaseV1.calculateSwapUnwindOpeningFeeAmount(
            swapOpenTimestamp,
            swapNotional,
            swapTenor,
            closingTimestamp,
            openingFeeRateCfg
        );
    }
}

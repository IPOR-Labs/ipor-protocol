// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.20;

import "../../contracts/interfaces/types/IporTypes.sol";
import "../../contracts/amm/libraries/SwapCloseLogicLib.sol";
import "../../contracts/base/amm/libraries/SwapLogicBaseV1.sol";

contract MockIporSwapLogic {
    function calculateSwapAmount(
        IporTypes.SwapTenor tenor,
        uint256 totalAmount,
        uint256 leverage,
        uint256 liquidationDepositAmount,
        uint256 iporPublicationFeeAmount,
        uint256 openingFeeRate
    ) public view returns (uint256 collateral, uint256 notional, uint256 openingFee) {
        return
            SwapLogicBaseV1.calculateSwapAmount(
                tenor,
                totalAmount,
                leverage,
                liquidationDepositAmount,
                iporPublicationFeeAmount,
                openingFeeRate
            );
    }

    function calculateInterest(
        AmmTypes.Swap memory swap,
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

    function calculateInterestFixed(
        uint256 notional,
        uint256 swapFixedInterestRate,
        uint256 swapPeriodInSeconds
    ) public pure returns (uint256) {
        return SwapLogicBaseV1.calculateInterestFixed(notional, swapFixedInterestRate, swapPeriodInSeconds);
    }

    function calculateInterestFloating(uint256 ibtQuantity, uint256 ibtCurrentPrice) public pure returns (uint256) {
        return SwapLogicBaseV1.calculateInterestFloating(ibtQuantity, ibtCurrentPrice);
    }

    function calculatePnlPayFixed(
        AmmTypes.Swap memory swap,
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
        AmmTypes.Swap memory swap,
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
        AmmTypes.Swap memory swap,
        AmmTypes.SwapDirection direction,
        uint256 closingTimestamp,
        uint256 oppositeLegFixedRate
    ) public pure returns (int256 swapUnwindAmount) {
        swapUnwindAmount = SwapCloseLogicLib.calculateSwapUnwindPnlValue(
            swap,
            direction,
            closingTimestamp,
            oppositeLegFixedRate
        );
    }

    function calculateSwapUnwindOpeningFeeAmount(
        AmmTypes.Swap memory swap,
        uint256 closingTimestamp,
        uint256 openingFeeRateCfg
    ) public pure returns (uint256 swapOpeningFeeAmount) {
        swapOpeningFeeAmount = SwapCloseLogicLibBaseV1.calculateSwapUnwindOpeningFeeAmount(
            swap.openTimestamp,
            swap.notional,
            swap.tenor,
            closingTimestamp,
            openingFeeRateCfg
        );
    }
}

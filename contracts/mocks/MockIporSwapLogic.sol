// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.16;

import "../interfaces/types/IporTypes.sol";
import "../amm/libraries/IporSwapLogic.sol";

contract MockIporSwapLogic {
    function calculateSwapAmount(
        AmmTypes.SwapDuration duration,
        uint256 totalAmount,
        uint256 leverage,
        uint256 liquidationDepositAmount,
        uint256 iporPublicationFeeAmount,
        uint256 openingFeeRate
    )
        public
        pure
        returns (
            uint256 collateral,
            uint256 notional,
            uint256 openingFee
        )
    {
        return
            IporSwapLogic.calculateSwapAmount(
                duration,
                totalAmount,
                leverage,
                liquidationDepositAmount,
                iporPublicationFeeAmount,
                openingFeeRate
            );
    }

    function calculateInterest(
        IporTypes.IporSwapMemory memory swap,
        uint256 closingTimestamp,
        uint256 mdIbtPrice
    ) public pure returns (uint256 interestFixed, uint256 interestFloating) {
        return IporSwapLogic.calculateInterest(swap, closingTimestamp, mdIbtPrice);
    }

    function calculateInterestFixed(
        uint256 notional,
        uint256 swapFixedInterestRate,
        uint256 swapPeriodInSeconds
    ) public pure returns (uint256) {
        return IporSwapLogic.calculateInterestFixed(notional, swapFixedInterestRate, swapPeriodInSeconds);
    }

    function calculateInterestFloating(uint256 ibtQuantity, uint256 ibtCurrentPrice)
        public
        pure
        returns (uint256)
    {
        return IporSwapLogic.calculateInterestFloating(ibtQuantity, ibtCurrentPrice);
    }

    function calculatePayoffPayFixed(
        IporTypes.IporSwapMemory memory swap,
        uint256 closingTimestamp,
        uint256 mdIbtPrice
    ) public pure returns (int256 swapValue) {
        swapValue = IporSwapLogic.calculatePayoffPayFixed(swap, closingTimestamp, mdIbtPrice);
    }

    function calculatePayoffReceiveFixed(
        IporTypes.IporSwapMemory memory swap,
        uint256 closingTimestamp,
        uint256 mdIbtPrice
    ) public pure returns (int256 swapValue) {
        swapValue = IporSwapLogic.calculatePayoffReceiveFixed(swap, closingTimestamp, mdIbtPrice);
    }

    function calculateSwapUnwindValue(
        IporTypes.IporSwapMemory memory swap,
        uint256 closingTimestamp,
        int256 swapPayoffToDate,
        uint256 oppositeLegFixedRate,
        uint256 openingFeeRateForSwapUnwind
    ) public pure returns (int256 swapUnwindValue) {
        swapUnwindValue = IporSwapLogic.calculateSwapUnwindValue(
            swap,
            closingTimestamp,
            swapPayoffToDate,
            oppositeLegFixedRate,
            openingFeeRateForSwapUnwind
        );
    }
}

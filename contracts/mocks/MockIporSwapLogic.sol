// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.13;

import "../interfaces/types/IporTypes.sol";
import "../amm/libraries/IporSwapLogic.sol";

contract MockIporSwapLogic {
    function calculateQuasiInterest(
        IporTypes.IporSwapMemory memory swap,
        uint256 closingTimestamp,
        uint256 mdIbtPrice
    ) public pure returns (uint256 quasiIFixed, uint256 quasiIFloating) {
        return IporSwapLogic.calculateQuasiInterest(swap, closingTimestamp, mdIbtPrice);
    }

    //@notice for final value divide by Constants.D18* Constants.YEAR_IN_SECONDS
    function calculateQuasiInterestFixed(
        uint256 notional,
        uint256 swapFixedInterestRate,
        uint256 swapPeriodInSeconds
    ) public pure returns (uint256) {
        return
            IporSwapLogic.calculateQuasiInterestFixed(
                notional,
                swapFixedInterestRate,
                swapPeriodInSeconds
            );
    }

    //@notice for final value divide by Constants.D18 * Constants.YEAR_IN_SECONDS
    function calculateQuasiInterestFloating(uint256 ibtQuantity, uint256 ibtCurrentPrice)
        public
        pure
        returns (uint256)
    {
        return IporSwapLogic.calculateQuasiInterestFloating(ibtQuantity, ibtCurrentPrice);
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
}

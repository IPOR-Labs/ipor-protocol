// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.9;

import "../libraries/types/DataTypes.sol";
import "../libraries/IporSwapLogic.sol";

contract MockIporSwapLogic {
    function calculateQuasiInterest(
        DataTypes.IporSwapMemory memory swap,
        uint256 closingTimestamp,
        uint256 mdIbtPrice
    ) public pure returns (uint256 quasiIFixed, uint256 quasiIFloating) {
        return IporSwapLogic.calculateQuasiInterest(swap, closingTimestamp, mdIbtPrice);
    }

    //@notice for final value divide by Constants.D18* Constants.YEAR_IN_SECONDS
    function calculateQuasiInterestFixed(
        uint256 notionalAmount,
        uint256 swapFixedInterestRate,
        uint256 swapPeriodInSeconds
    ) public pure returns (uint256) {
        return
            IporSwapLogic.calculateQuasiInterestFixed(
                notionalAmount,
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

    function calculateSwapPayFixedValue(
        DataTypes.IporSwapMemory memory swap,
        uint256 closingTimestamp,
        uint256 mdIbtPrice
    ) public pure returns (int256 swapValue) {
        swapValue = IporSwapLogic.calculateSwapPayFixedValue(swap, closingTimestamp, mdIbtPrice);
    }

    function calculateSwapReceiveFixedValue(
        DataTypes.IporSwapMemory memory swap,
        uint256 closingTimestamp,
        uint256 mdIbtPrice
    ) public pure returns (int256 swapValue) {
        swapValue = IporSwapLogic.calculateSwapReceiveFixedValue(
            swap,
            closingTimestamp,
            mdIbtPrice
        );
    }
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.9;

import "../libraries/types/DataTypes.sol";
import "../libraries/IporSwapLogic.sol";

contract MockIporSwapLogic {
    //@notice for final value divide by Constants.D18* Constants.YEAR_IN_SECONDS
    function calculateQuasiInterestFixed(
        uint256 notionalAmount,
        uint256 derivativeFixedInterestRate,
        uint256 derivativePeriodInSeconds
    ) public pure returns (uint256) {
        return
            IporSwapLogic.calculateQuasiInterestFixed(
                notionalAmount,
                derivativeFixedInterestRate,
                derivativePeriodInSeconds
            );
    }

    //@notice for final value divide by Constants.D18 * Constants.YEAR_IN_SECONDS
    function calculateQuasiInterestFloating(
        uint256 ibtQuantity,
        uint256 ibtCurrentPrice
    ) public pure returns (uint256) {
        return
            IporSwapLogic.calculateQuasiInterestFloating(
                ibtQuantity,
                ibtCurrentPrice
            );
    }

    function calculateInterestForSwapPayFixed(
        DataTypes.IporSwapMemory memory derivative,
        uint256 closingTimestamp,
        uint256 mdIbtPrice
    ) public pure returns (DataTypes.IporDerivativeInterest memory) {
        return
            IporSwapLogic.calculateInterestForSwapPayFixed(
                derivative,
                closingTimestamp,
                mdIbtPrice
            );
    }

	function calculateInterestForSwapReceiveFixed(
        DataTypes.IporSwapMemory memory derivative,
        uint256 closingTimestamp,
        uint256 mdIbtPrice
    ) public pure returns (DataTypes.IporDerivativeInterest memory) {
        return
            IporSwapLogic.calculateInterestForSwapReceiveFixed(
                derivative,
                closingTimestamp,
                mdIbtPrice
            );
    }
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.10;

import "./types/DataTypes.sol";
import "./Constants.sol";

library AmmMath {

    //@notice Division with rounding up on last position, x, and y is with MD
    function division(uint256 x, uint256 y) internal pure returns (uint256 z) {
        z = (x + (y / 2)) / y;
    }

    function divisionInt(int256 x, int256 y) internal pure returns (int256 z) {
        z = (x + (y / 2)) / y;
    }

    function calculateIncomeTax(uint256 derivativeProfit, uint256 incomeTaxPercentage, uint256 multiplicator) internal pure returns (uint256) {
        return division(derivativeProfit * incomeTaxPercentage, multiplicator);
    }

    function calculateIbtQuantity(uint256 notionalAmount, uint256 ibtPrice, uint256 multiplicator) internal pure returns (uint256){
        return division(notionalAmount * multiplicator, ibtPrice);
    }

    function calculateDerivativeAmount(
        uint256 totalAmount,
        uint256 collateralizationFactor,
        uint256 liquidationDepositAmount,
        uint256 iporPublicationFeeAmount,
        uint256 openingFeePercentage,
        uint256 multiplicator
    ) internal pure returns (DataTypes.IporDerivativeAmount memory) {
        uint256 collateral = division(
            (totalAmount - liquidationDepositAmount - iporPublicationFeeAmount) * multiplicator,
            multiplicator + division(collateralizationFactor * openingFeePercentage, multiplicator)
        );
        uint256 notional = division(collateralizationFactor * collateral, multiplicator);
        uint256 openingFeeAmount = division(notional * openingFeePercentage, multiplicator);
        return DataTypes.IporDerivativeAmount(collateral, notional, openingFeeAmount);
    }

    function absoluteValue(int256 value) internal pure returns (uint256) {
        return (uint256)(value < 0 ? - value : value);
    }
}

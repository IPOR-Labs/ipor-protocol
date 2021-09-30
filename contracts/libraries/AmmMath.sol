// SPDX-License-Identifier: agpl-3.0
pragma solidity >=0.8.4 <0.9.0;

import "./types/DataTypes.sol";
import "./Constants.sol";

library AmmMath {

    //@notice Division with rounding up on last position, x, and y is with MD
    function division(uint256 x, uint256 y) public pure returns (uint256 z) {
        z = (x + (y / 2)) / y;
    }

    function divisionInt(int256 x, int256 y) public pure returns (int256 z) {
        z = (x + (y / 2)) / y;
    }

    function calculateIncomeTax(uint256 derivativeProfit, uint256 incomeTaxPercentage) public pure returns (uint256) {
        return division(derivativeProfit * incomeTaxPercentage, Constants.MD);
    }

    function calculateIbtQuantity(uint256 notionalAmount, uint256 ibtPrice) public pure returns (uint256){
        return division(notionalAmount * Constants.MD, ibtPrice);
    }

    function calculateDerivativeAmount(
        uint256 totalAmount,
        uint256 collateralization,
        uint256 liquidationDepositAmount,
        uint256 iporPublicationFeeAmount,
        uint256 openingFeePercentage
    ) internal pure returns (DataTypes.IporDerivativeAmount memory) {
        uint256 openingFeeAmount = division(
            (totalAmount - liquidationDepositAmount - iporPublicationFeeAmount) * openingFeePercentage,
            Constants.MD
        );
        uint256 collateral = totalAmount - liquidationDepositAmount - iporPublicationFeeAmount - openingFeeAmount;
        return DataTypes.IporDerivativeAmount(
            collateral, division(collateralization * collateral, Constants.MD),
            openingFeeAmount
        );
    }

    function absoluteValue(int256 value) internal pure returns (uint256) {
        return (uint256)(value < 0 ? - value : value);
    }
}
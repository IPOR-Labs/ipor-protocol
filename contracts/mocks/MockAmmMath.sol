// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.9;

import "../libraries/types/DataTypes.sol";
import "../libraries/IporMath.sol";

contract MockIporMath {
    //@notice Division with rounding up on last position, x, and y is with MD
    function division(uint256 x, uint256 y) public pure returns (uint256 z) {
        return IporMath.division(x, y);
    }

    function divisionInt(int256 x, int256 y) public pure returns (int256 z) {
        return IporMath.divisionInt(x, y);
    }

    function convertWadToAssetDecimals(uint256 value, uint256 assetDecimals)
        public
        pure
        returns (uint256)
    {
        return IporMath.convertWadToAssetDecimals(value, assetDecimals);
    }

    function convertToWad(uint256 value, uint256 assetDecimals)
        public
        pure
        returns (uint256)
    {
        return IporMath.convertToWad(value, assetDecimals);
    }

    function calculateIncomeTax(
        uint256 derivativeProfit,
        uint256 incomeTaxPercentage
    ) public pure returns (uint256) {
        return
            IporMath.calculateIncomeTax(derivativeProfit, incomeTaxPercentage);
    }

    function calculateIbtQuantity(uint256 notionalAmount, uint256 ibtPrice)
        public
        pure
        returns (uint256)
    {
        return IporMath.calculateIbtQuantity(notionalAmount, ibtPrice);
    }

    function calculateDerivativeAmount(
        uint256 totalAmount,
        uint256 collateralizationFactor,
        uint256 liquidationDepositAmount,
        uint256 iporPublicationFeeAmount,
        uint256 openingFeePercentage
    ) public pure returns (
		uint256 collateral,
		uint256 notional,
		uint256 openingFee) {
        (collateral,notional,openingFee) =
            IporMath.calculateDerivativeAmount(
                totalAmount,
                collateralizationFactor,
                liquidationDepositAmount,
                iporPublicationFeeAmount,
                openingFeePercentage
            );
    }

    function absoluteValue(int256 value) public pure returns (uint256) {
        return IporMath.absoluteValue(value);
    }
}

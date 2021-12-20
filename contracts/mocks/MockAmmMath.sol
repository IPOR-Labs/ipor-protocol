// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.9;

import "../libraries/types/DataTypes.sol";
import "../libraries/AmmMath.sol";

contract MockAmmMath {
    //@notice Division with rounding up on last position, x, and y is with MD
    function division(uint256 x, uint256 y) internal pure returns (uint256 z) {
        return AmmMath.division(x, y);
    }

    function divisionInt(int256 x, int256 y) internal pure returns (int256 z) {
        return AmmMath.divisionInt(x, y);
    }

    function convertWadToAssetDecimals(uint256 value, uint256 assetDecimals)
        internal
        pure
        returns (uint256)
    {
        return AmmMath.convertWadToAssetDecimals(value, assetDecimals);
    }

    function convertToWad(uint256 value, uint256 assetDecimals)
        internal
        pure
        returns (uint256)
    {
        return AmmMath.convertToWad(value, assetDecimals);
    }

    function calculateIncomeTax(
        uint256 derivativeProfit,
        uint256 incomeTaxPercentage
    ) public pure returns (uint256) {
        return
            AmmMath.calculateIncomeTax(derivativeProfit, incomeTaxPercentage);
    }

    function calculateIbtQuantity(uint256 notionalAmount, uint256 ibtPrice)
        public
        pure
        returns (uint256)
    {
        return AmmMath.calculateIbtQuantity(notionalAmount, ibtPrice);
    }

    function calculateDerivativeAmount(
        uint256 totalAmount,
        uint256 collateralizationFactor,
        uint256 liquidationDepositAmount,
        uint256 iporPublicationFeeAmount,
        uint256 openingFeePercentage
    ) public pure returns (DataTypes.IporDerivativeAmount memory) {
        return
            AmmMath.calculateDerivativeAmount(
                totalAmount,
                collateralizationFactor,
                liquidationDepositAmount,
                iporPublicationFeeAmount,
                openingFeePercentage
            );
    }

    function absoluteValue(int256 value) internal pure returns (uint256) {
        return AmmMath.absoluteValue(value);
    }
}

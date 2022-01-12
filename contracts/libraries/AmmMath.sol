// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.9;

import "./types/DataTypes.sol";
import "./Constants.sol";

//TODO: rename to IporMath
library AmmMath {
    //@notice Division with rounding up on last position, x, and y is with MD
    function division(uint256 x, uint256 y) internal pure returns (uint256 z) {
        z = (x + (y / 2)) / y;
    }

    function divisionInt(int256 x, int256 y) internal pure returns (int256 z) {
        z = (x + (y / 2)) / y;
    }

	//@dev x represented as WAD
	//@return y represented as WAD
    function sqrt(uint256 xWad) internal pure returns (uint256 y) {
		uint256 x = xWad * Constants.D18;
        uint256 z = (x + 1) / 2;
        y = x;
        while (z < y) {
            y = z;
            z = (x / z + z) / 2;
        }
    }

    function convertWadToAssetDecimals(uint256 value, uint256 assetDecimals)
        internal
        pure
        returns (uint256)
    {
        if (assetDecimals == 18) {
            return value;
        } else if (assetDecimals > 18) {
            return value * 10**(assetDecimals - 18);
        } else {
            return division(value, 10**(18 - assetDecimals));
        }
    }

    function convertToWad(uint256 value, uint256 assetDecimals)
        internal
        pure
        returns (uint256)
    {
        if (assetDecimals == 18) {
            return value;
        } else if (assetDecimals > 18) {
            return division(value, 10**(assetDecimals - 18));
        } else {
            return value * 10**(18 - assetDecimals);
        }
    }

    //TODO: move to separate library
    function calculateIncomeTax(
        uint256 derivativeProfit,
        uint256 incomeTaxPercentage
    ) internal pure returns (uint256) {
        return division(derivativeProfit * incomeTaxPercentage, Constants.D18);
    }

    //TODO: move to separate library
    function calculateIbtQuantity(uint256 notionalAmount, uint256 ibtPrice)
        internal
        pure
        returns (uint256)
    {
        return division(notionalAmount * Constants.D18, ibtPrice);
    }

    //TODO: move to separate library
    function calculateDerivativeAmount(
        uint256 totalAmount,
        uint256 collateralizationFactor,
        uint256 liquidationDepositAmount,
        uint256 iporPublicationFeeAmount,
        uint256 openingFeePercentage
    ) internal pure returns (DataTypes.IporDerivativeAmount memory) {
        uint256 collateral = division(
            (totalAmount -
                liquidationDepositAmount -
                iporPublicationFeeAmount) * Constants.D18,
            Constants.D18 +
                division(
                    collateralizationFactor * openingFeePercentage,
                    Constants.D18
                )
        );
        uint256 notional = division(
            collateralizationFactor * collateral,
            Constants.D18
        );
        uint256 openingFeeAmount = division(
            notional * openingFeePercentage,
            Constants.D18
        );
        return
            DataTypes.IporDerivativeAmount(
                collateral,
                notional,
                openingFeeAmount
            );
    }

    function absoluteValue(int256 value) internal pure returns (uint256) {
        return (uint256)(value < 0 ? -value : value);
    }
}

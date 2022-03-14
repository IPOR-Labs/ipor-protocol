// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.9;

import "../Constants.sol";

library IporMath {
    //TODO: Milton, MiltonStorage, SoapIndicatorLogic, Joseph, MiltonSpreadModel, Darcy
    //@notice Division with rounding up on last position, x, and y is with MD
    function division(uint256 x, uint256 y) internal pure returns (uint256 z) {
        z = (x + (y / 2)) / y;
    }

    //TODO: MiltonStorage, IporSwapLogic
    function divisionInt(int256 x, int256 y) internal pure returns (int256 z) {
        z = (x + (y / 2)) / y;
    }

    function divisionWithoutRound(uint256 x, uint256 y) internal pure returns (uint256 z) {
        z = x / y;
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

    function convertToWad(uint256 value, uint256 assetDecimals) internal pure returns (uint256) {
        if (value != 0) {
            if (assetDecimals == 18) {
                return value;
            } else if (assetDecimals > 18) {
                return division(value, 10**(assetDecimals - 18));
            } else {
                return value * 10**(18 - assetDecimals);
            }
        } else {
            return value;
        }
    }

    function absoluteValue(int256 value) internal pure returns (uint256) {
        return (uint256)(value < 0 ? -value : value);
    }
}

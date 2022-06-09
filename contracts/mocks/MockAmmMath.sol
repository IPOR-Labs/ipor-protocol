// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.13;

import "../libraries/math/IporMath.sol";

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

    function convertToWad(uint256 value, uint256 assetDecimals) public pure returns (uint256) {
        return IporMath.convertToWad(value, assetDecimals);
    }

    function absoluteValue(int256 value) public pure returns (uint256) {
        return IporMath.absoluteValue(value);
    }
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.9;

library AmMath {
    function division(uint256 x, uint256 y) internal pure returns (uint256 z) {
        z = (x + (y / 2)) / y;
    }

    function divisionRoundDown(uint256 x, uint256 y)
        internal
        pure
        returns (uint256 z)
    {
        z = x / y;
    }
}

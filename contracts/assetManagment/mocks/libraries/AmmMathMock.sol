// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.9;

import {AmMath} from "../../libraries/AmMath.sol";

contract AmMathMock {
    function division(uint256 x, uint256 y) external pure returns (uint256 z) {
        return AmMath.division(x, y);
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.15;

import "./MockCase6Milton.sol";

contract MockCase6MiltonUsdc is MockCase6Milton {
    function _getDecimals() internal pure virtual override returns (uint256) {
        return 6;
    }
}

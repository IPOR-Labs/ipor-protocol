// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.9;

import "./MockCase3Milton.sol";

contract MockCase3MiltonUsdt is MockCase3Milton {
    function _getDecimals() internal pure virtual override returns (uint256) {
        return 6;
    }
}

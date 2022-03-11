// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.9;

import "./MockCase6Milton.sol";

contract MockCase6MiltonDai is MockCase6Milton {
    function _getDecimals() internal pure virtual override returns (uint256) {
        return 18;
    }
}

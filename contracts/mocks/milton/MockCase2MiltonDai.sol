// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.9;

import "./MockCase2Milton.sol";

contract MockCase2MiltonDai is MockCase2Milton {
    function _getDecimals() internal pure virtual override returns (uint256) {
        return 18;
    }
}

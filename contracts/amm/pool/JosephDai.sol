// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.15;

import "./Joseph.sol";

contract JosephDai is Joseph {
    function _getDecimals() internal pure virtual override returns (uint256) {
        return 18;
    }
}

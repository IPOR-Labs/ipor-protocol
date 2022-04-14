// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.9;

import "./Joseph.sol";

contract JosephUsdt is Joseph {
    function _getDecimals() internal pure virtual override returns (uint256) {
        return 6;
    }
}

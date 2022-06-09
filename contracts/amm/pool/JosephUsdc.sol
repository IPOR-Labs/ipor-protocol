// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.13;

import "./Joseph.sol";

contract JosephUsdc is Joseph {
    function _getDecimals() internal pure virtual override returns (uint256) {
        return 6;
    }
}

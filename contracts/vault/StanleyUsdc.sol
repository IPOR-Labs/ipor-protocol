// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.14;

import "./Stanley.sol";

contract StanleyUsdc is Stanley {
    function _getDecimals() internal pure virtual override returns (uint256) {
        return 6;
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.20;

import "./AssetManagement.sol";

contract AssetManagementUsdc is AssetManagement {
    function _getDecimals() internal pure virtual override returns (uint256) {
        return 6;
    }
}

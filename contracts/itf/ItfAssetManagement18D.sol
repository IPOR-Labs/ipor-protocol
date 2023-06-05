// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.20;

import "./ItfAssetManagement.sol";

contract ItfAssetManagement18D is ItfAssetManagement {
    function _getDecimals() internal pure virtual override returns (uint256) {
        return 18;
    }
}

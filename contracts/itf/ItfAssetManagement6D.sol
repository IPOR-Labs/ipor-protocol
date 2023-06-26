// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.20;

import "contracts/itf/ItfAssetManagement.sol";

contract ItfAssetManagement6D is ItfAssetManagement {
    function _getDecimals() internal pure virtual override returns (uint256) {
        return 6;
    }
}

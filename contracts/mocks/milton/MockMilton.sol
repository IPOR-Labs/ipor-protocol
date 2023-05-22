// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.16;

import "../../itf/ItfMilton.sol";

contract MockMilton is ItfMilton {
    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor(
        address asset,
        uint256 decimals,
        address ammStorage,
        address assetManagement,
        address router
    ) ItfMilton(asset, decimals, ammStorage, assetManagement, router) {}
}

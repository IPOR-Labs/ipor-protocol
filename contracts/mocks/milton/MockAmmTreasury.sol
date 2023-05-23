// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.16;

import "../../itf/ItfAmmTreasury.sol";

contract MockAmmTreasury is ItfAmmTreasury {
    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor(
        address asset,
        uint256 decimals,
        address ammStorage,
        address assetManagement,
        address router
    ) ItfAmmTreasury(asset, decimals, ammStorage, assetManagement, router) {}
}

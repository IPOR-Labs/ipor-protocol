// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.20;

import "../vault/AssetManagement.sol";

abstract contract ItfAssetManagement is AssetManagement {
    function getMaxApyStrategy()
        external
        view
        returns (
            address strategyMaxApy,
            address strategyAave,
            address strategyCompound
        )
    {
        return _getMaxApyStrategy();
    }
}

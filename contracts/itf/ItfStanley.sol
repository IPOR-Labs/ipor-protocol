// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.16;

import "../vault/Stanley.sol";

abstract contract ItfStanley is Stanley {
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

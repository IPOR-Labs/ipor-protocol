// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.15;

import "../vault/Stanley.sol";

abstract contract ItfStanley is Stanley {
    function getMaxApyStrategy()
        external
        view
        returns (
            IStrategy strategyMaxApy,
            IStrategy strategyAave,
            IStrategy strategyCompound
        )
    {
        return _getMaxApyStrategy();
    }
}

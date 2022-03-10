// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.9;

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

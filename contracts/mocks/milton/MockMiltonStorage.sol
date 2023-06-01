// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.16;

import "../../amm/AmmStorage.sol";

contract MockAmmStorage is AmmStorage {
    constructor(
        address iporProtocolRouter, address ammTreasury) AmmStorage(iporProtocolRouter, ammTreasury) {
        require(iporProtocolRouter != address(0), string.concat(IporErrors.WRONG_ADDRESS, " IPOR protocol router address cannot be 0"));
        require(ammTreasury != address(0), string.concat(IporErrors.WRONG_ADDRESS, " AMM treasury address cannot be 0"));
    }

    function getBalance() external view override returns (IporTypes.AmmBalancesMemory memory) {
        return
            IporTypes.AmmBalancesMemory(
                _balances.totalCollateralPayFixed,
                _balances.totalCollateralReceiveFixed,
                0,
                1e18
            );
    }
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.16;

import "../../amm/AmmStorage.sol";

contract MockAmmStorage is AmmStorage {
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

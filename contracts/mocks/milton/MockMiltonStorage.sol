// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.15;

import "../../amm/MiltonStorage.sol";

contract MockMiltonStorage is MiltonStorage {
    function getBalance() external view override returns (IporTypes.MiltonBalancesMemory memory) {
        return
            IporTypes.MiltonBalancesMemory(
                _balances.totalCollateralPayFixed,
                _balances.totalCollateralReceiveFixed,
                0,
                1e18
            );
    }
}

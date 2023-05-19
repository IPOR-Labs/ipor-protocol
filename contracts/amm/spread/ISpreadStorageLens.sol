// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.16;

import "contracts/interfaces/types/IporTypes.sol";
import "./SpreadTypes.sol";

interface ISpreadStorageLens {
    function getWeightedNotional(
    ) external returns (SpreadTypes.TimeWeightedNotionalMemory[] memory timeWeightedNotional, string[] memory keys);
}

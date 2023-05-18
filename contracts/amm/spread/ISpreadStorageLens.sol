// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.16;

import "../../interfaces/types/IporTypes.sol";
import "./SpreadTypes.sol";

interface ISpreadStorageLens {
    function getWeightedNotional(
    ) external returns (SpreadTypes.WeightedNotionalMemory[] memory weightedNotional, string[] memory keys);
}

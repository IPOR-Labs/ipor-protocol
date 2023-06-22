// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.20;

import "@ipor-protocol/contracts/interfaces/types/IporTypes.sol";
import "@ipor-protocol/contracts/amm/spread/SpreadTypes.sol";

interface ISpreadStorageLens {
    function getTimeWeightedNotional(
    ) external returns (SpreadTypes.TimeWeightedNotionalResponse[] memory timeWeightedNotionalResponse);
}

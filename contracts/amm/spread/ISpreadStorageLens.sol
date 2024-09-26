// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.26;

import "../../amm/spread/SpreadTypes.sol";

/// @title Spread interface for storage lens
interface ISpreadStorageLens {
    /// @notice Gets the time-weighted notional for all supported assets and tenors.
    /// @return timeWeightedNotionalResponse The time-weighted notional for all supported assets and tenors.
    function getTimeWeightedNotional()
        external
        returns (SpreadTypes.TimeWeightedNotionalResponse[] memory timeWeightedNotionalResponse);
}

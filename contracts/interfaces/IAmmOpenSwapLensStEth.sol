// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.20;

import "../basic/types/AmmTypesGenOne.sol";

/// @title Interface of the service allowing to open new swaps.
interface IAmmOpenSwapLensStEth {
    /// @notice Returns configuration of the AmmOpenSwapServicePool for specific asset (pool).
    /// @return AmmOpenSwapServicePoolConfigurationStEth structure representing configuration of the AmmOpenSwapServicePoolStEth.
    function getAmmOpenSwapServicePoolConfigurationStEth()
        external
        view
        returns (AmmTypesGenOne.AmmOpenSwapServicePoolConfiguration memory);
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.20;

import "./types/AmmTypes.sol";

/// @title Interface of the service allowing to close swaps.
interface IAmmCloseSwapServiceStable {
    function getPoolConfiguration()
        external
        view
        returns (IAmmCloseSwapLens.AmmCloseSwapServicePoolConfiguration memory);
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.16;

import "./types/IporTypes.sol";
import "./types/AmmTypes.sol";
import "./types/MiltonTypes.sol";

/// @title Interface for interaction with Milton.
interface IMilton {
    function getConfiguration()
        external
        view
        returns (
            address asset,
            uint256 decimals,
            address ammStorage,
            address assetManagement,
            address iporProtocolRouter
        );
}

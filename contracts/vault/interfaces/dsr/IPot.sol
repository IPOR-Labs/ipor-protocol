// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.20;

/// @title The interface for the CORE of Dai Savings Rate.
interface IPot {
    /// @notice The Dai Savings Rate
    function dsr() external view returns (uint256);
}

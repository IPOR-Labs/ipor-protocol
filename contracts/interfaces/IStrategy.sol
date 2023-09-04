// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.20;

/// @title Interface for interaction with  AssetManagement's strategy.
/// @notice Strategy represents an external DeFi protocol and acts as and wrapper that standarizes the API of the external protocol.
interface IStrategy {

    /// @notice Claims rewards. Function can be executed by anyone.
    function doClaim() external;

    /// @notice Gets Treasury address.
    /// @return Treasury address.
    function getTreasury() external view returns (address);

    /// @notice Sets new Treasury address. Function can be executed only by the smart contract Owner.
    /// @param newTreasury new Treasury address
    function setTreasury(address newTreasury) external;

    /// @notice Gets new Treasury Manager address.
    /// @return Treasury Manager address.
    function getTreasuryManager() external view returns (address);

    /// @notice Sets new Treasury Manager address. Function can be executed only by the smart contract Owner.
    /// @param newTreasuryManager new Treasury Manager address
    function setTreasuryManager(address newTreasuryManager) external;

    /// @notice Emmited when doClaim function had been executed.
    /// @param claimedBy account that executes claim action
    /// @param shareToken share token assocciated with one strategy
    /// @param treasury Treasury address where claimed tokens are transferred.
    /// @param amount S
    event DoClaim(address indexed claimedBy, address indexed shareToken, address indexed treasury, uint256 amount);

    /// @notice Emmited when Treasury address has changed
    /// @param newTreasury new Treasury address
    event TreasuryChanged(address newTreasury);

    /// @notice Emmited when Treasury Manager address has changed
    /// @param newTreasuryManager new Treasury Manager address
    event TreasuryManagerChanged(address newTreasuryManager);
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.20;

/// @title Interface for interaction with standalone IPOR smart contract by DAO government with common methods.
interface IIporContractCommonGov {
    /// @notice Pauses current smart contract. It can be executed only by the Owner.
    /// @dev Emits {Paused} event from AssetManagement.
    function pause() external;

    /// @notice Unpauses current smart contract. It can be executed only by the Owner
    /// @dev Emits {Unpaused} event from AssetManagement.
    function unpause() external;

    /// @notice Checks if given account is a pause guardian.
    /// @param account The address of the account to be checked.
    /// @return true if account is a pause guardian.
    function isPauseGuardian(address account) external view returns (bool);

    /// @notice Adds a pause guardian to the list of guardians. Function available only for the Owner.
    /// @param guardian The address of the pause guardian to be added.
    function addPauseGuardian(address guardian) external;

    /// @notice Removes a pause guardian from the list of guardians. Function available only for the Owner.
    /// @param guardian The address of the pause guardian to be removed.
    function removePauseGuardian(address guardian) external;
}

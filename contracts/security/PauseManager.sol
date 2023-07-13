// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.20;

import "../libraries/StorageLib.sol";

/// @title Ipor Protocol Router Pause Manager library
library PauseManager {
    /// @notice Emitted when new pause guardian is added
    /// @param guardian Address of guardian
    event PauseGuardianAdded(address indexed guardian);

    /// @notice Emitted when pause guardian is removed
    /// @param guardian Address of guardian
    event PauseGuardianRemoved(address indexed guardian);

    /// @notice Checks if account is Ipor Protocol Router pause guardian
    /// @param account Address of guardian
    /// @return true if account is Ipor Protocol Router pause guardian
    function isPauseGuardian(address account) internal view returns (bool) {
        mapping(address => bool) storage pauseGuardians = StorageLib.getPauseGuardianStorage();
        return pauseGuardians[account];
    }

    /// @notice Adds Ipor Protocol Router pause guardian
    /// @param newGuardian Address of guardian
    function addPauseGuardian(address newGuardian) internal {
        mapping(address => bool) storage pauseGuardians = StorageLib.getPauseGuardianStorage();
        pauseGuardians[newGuardian] = true;
        emit PauseGuardianAdded(newGuardian);
    }

    /// @notice Removes Ipor Protocol Router pause guardian
    /// @param guardian Address of guardian
    function removePauseGuardian(address guardian) internal {
        mapping(address => bool) storage pauseGuardians = StorageLib.getPauseGuardianStorage();
        pauseGuardians[guardian] = false;
        emit PauseGuardianRemoved(guardian);
    }
}

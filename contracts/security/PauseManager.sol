// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.20;

import "@ipor-protocol/contracts/libraries/StorageLib.sol";

library PauseManager {

    function addPauseGuardian(address _guardian) internal {
        mapping(address => bool) storage pauseGuardians = StorageLib.getPauseGuardianStorage();
        pauseGuardians[_guardian] = true;
        emit PauseGuardianAdded(_guardian);
    }

    function removePauseGuardian(address _guardian) internal {
        mapping(address => bool) storage pauseGuardians = StorageLib.getPauseGuardianStorage();
        pauseGuardians[_guardian] = false;
        emit PauseGuardianRemoved(_guardian);
    }

    function isPauseGuardian(address _guardian) internal view returns (bool) {
        mapping(address => bool) storage pauseGuardians = StorageLib.getPauseGuardianStorage();
        return pauseGuardians[_guardian];
    }

    event PauseGuardianAdded(address indexed guardian);

    event PauseGuardianRemoved(address indexed guardian);
}

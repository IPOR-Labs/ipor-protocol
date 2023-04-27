// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.16;

import "../libraries/StorageLib.sol";

library PauseManager {

    function addGuardian(address _guardian) internal {
        mapping(address => bool) storage guardians = StorageLib.getPauseGuardianStorage();
        guardians[_guardian] = true;
        emit GuardianAdded(_guardian);
    }

    function removeGuardian(address _guardian) internal {
        mapping(address => bool) storage guardians = StorageLib.getPauseGuardianStorage();
        guardians[_guardian] = false;
        emit GuardianRemoved(_guardian);
    }

    function isGuardian(address _guardian) internal view returns (bool) {
        mapping(address => bool) storage guardians = StorageLib.getPauseGuardianStorage();
        return guardians[_guardian];
    }

    event GuardianAdded(address indexed guardian);

    event GuardianRemoved(address indexed guardian);
}

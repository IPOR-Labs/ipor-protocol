// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.20;

import "../../contracts/security/PauseManager.sol";

contract PauseManagerMock {
    function isPauseGuardian(address account) external view returns (bool) {
        return PauseManager.isPauseGuardian(account);
    }

    function addPauseGuardians(address[] calldata newGuardians) external {
        PauseManager.addPauseGuardians(newGuardians);
    }

    function removePauseGuardians(address[] calldata guardians) external {
        PauseManager.removePauseGuardians(guardians);
    }
}

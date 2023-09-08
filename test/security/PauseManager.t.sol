// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.20;

import "forge-std/Test.sol";
import "../../contracts/security/PauseManager.sol";
import "./PauseManagerMock.sol";

contract PauseManagerTest is Test {
    address internal _owner;
    address internal _user1;
    address internal _user2;
    address[] private _pauseGuardians;
    PauseManagerMock internal pauseManagerMock;

    function setUp() public {
        _owner = vm.rememberKey(1);
        _user1 = vm.rememberKey(2);
        _user2 = vm.rememberKey(3);
        _pauseGuardians = new address[](1);
        pauseManagerMock = new PauseManagerMock();
    }

    function testShouldAddPauseGuardian() public {
        // given
        // no pause guardians added
        _pauseGuardians[0] = _user1;
        // when
        vm.expectEmit(true, true, true, true);
        emit PauseGuardiansAdded(_pauseGuardians);
        pauseManagerMock.addPauseGuardians(_pauseGuardians);

        // then
        assertTrue(pauseManagerMock.isPauseGuardian(_user1));
    }

    function testShouldRemovePauseGuardian() public {
        // given
        _pauseGuardians[0] = _user1;
        pauseManagerMock.addPauseGuardians(_pauseGuardians);

        // when
        vm.expectEmit(true, true, true, true);
        emit PauseGuardiansRemoved(_pauseGuardians);
        pauseManagerMock.removePauseGuardians(_pauseGuardians);

        // then
        assertFalse(pauseManagerMock.isPauseGuardian(_user1));
    }

    function testShouldReturnIsPauseGuardianTrue() public {
        // given
        _pauseGuardians[0] = _user1;
        pauseManagerMock.addPauseGuardians(_pauseGuardians);

        // when
        bool result = pauseManagerMock.isPauseGuardian(_user1);

        // then
        assertTrue(result);
    }

    function testShouldReturnIsPauseGuardianFalse() public {
        // given
        address[] memory pauseGuardians = new address[](1);
        pauseGuardians[0] = vm.rememberKey(2);

        pauseManagerMock.addPauseGuardians(pauseGuardians);

        // when
        bool result = pauseManagerMock.isPauseGuardian(_user2);

        // then
        assertFalse(result);
    }

    event PauseGuardiansAdded(address[] indexed pauseGuardians);

    event PauseGuardiansRemoved(address[] indexed pauseGuardians);
}

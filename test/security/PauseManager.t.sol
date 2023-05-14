// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.16;

import "forge-std/Test.sol";
import "../../contracts/security/PauseManager.sol";
import "../../contracts/mocks/tokens/MockTestnetToken.sol";

contract PauseManagerTest is Test {
    address internal _owner;
    address internal _user1;
    address internal _user2;

    function setUp() public {
        _owner = vm.rememberKey(1);
        _user1 = vm.rememberKey(2);
        _user2 = vm.rememberKey(3);
    }

    function testShouldAddPauseGuardian() public {
        // given
        // no pause guardians added

        // when
        vm.expectEmit(true, true, true, true);
        emit PauseGuardianAdded(_user1);
        PauseManager.addPauseGuardian(_user1);

        // then
        assertTrue(PauseManager.isPauseGuardian(_user1));
    }

    function testShouldRemovePauseGuardian() public {
        // given
        PauseManager.addPauseGuardian(_user1);

        // when
        vm.expectEmit(true, true, true, true);
        emit PauseGuardianRemoved(_user1);
        PauseManager.removePauseGuardian(_user1);

        // then
        assertFalse(PauseManager.isPauseGuardian(_user1));
    }

    function testShouldReturnIsPauseGuardianTrue() public {
        // given
        PauseManager.addPauseGuardian(_user1);

        // when
        bool result = PauseManager.isPauseGuardian(_user1);

        // then
        assertTrue(result);
    }

    function testShouldReturnIsPauseGuardianFalse() public {
        // given
        PauseManager.addPauseGuardian(_user1);

        // when
        bool result = PauseManager.isPauseGuardian(_user2);

        // then
        assertFalse(result);
    }

    event PauseGuardianAdded(address indexed PauseGuardian);

    event PauseGuardianRemoved(address indexed PauseGuardian);
}

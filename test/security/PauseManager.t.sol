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

    function testShouldAddGuardian() public {
        // given
        // no guardians added

        // when
        vm.expectEmit(true, true, true, true);
        emit GuardianAdded(_user1);
        PauseManager.addGuardian(_user1);

        // then
        assertTrue(PauseManager.isGuardian(_user1));
    }

    function testShouldRemoveGuardian() public {
        // given
        PauseManager.addGuardian(_user1);

        // when
        vm.expectEmit(true, true, true, true);
        emit GuardianRemoved(_user1);
        PauseManager.removeGuardian(_user1);

        // then
        assertFalse(PauseManager.isGuardian(_user1));
    }

    function testShouldReturnIsGuardianTrue() public {
        // given
        PauseManager.addGuardian(_user1);

        // when
        bool result = PauseManager.isGuardian(_user1);

        // then
        assertTrue(result);
    }

    function testShouldReturnIsGuardianFalse() public {
        // given
        PauseManager.addGuardian(_user1);

        // when
        bool result = PauseManager.isGuardian(_user2);

        // then
        assertFalse(result);
    }

    event GuardianAdded(address indexed guardian);

    event GuardianRemoved(address indexed guardian);
}

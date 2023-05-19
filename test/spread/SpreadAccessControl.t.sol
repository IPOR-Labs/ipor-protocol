// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.16;

import "forge-std/Test.sol";
import "../TestCommons.sol";
import "./SpreadTestSystem.sol";

contract SpreadAccessControlTest is TestCommons {
    SpreadTestSystem internal  _spreadTestSystem;
    address internal _ammAddress;
    address internal _routerAddress;
    address internal _owner;

    function setUp() external {
        _ammAddress = _getUserAddress(10);
        _spreadTestSystem = new SpreadTestSystem(_ammAddress);
        _routerAddress = address(_spreadTestSystem.router());
        _owner = _spreadTestSystem.owner();
    }

    function testShouldSetupOwnerWhenDeployed() external {
        // when
        address routerOwner = SpreadAccessControl(_routerAddress).owner();

        // then
        assertEq(routerOwner, _owner, "router owner should be set");
    }

    function testShouldBeAbleToTransferOwnership() external {
        // given
        address newOwner = _getUserAddress(11);
        address ownerBefore = SpreadAccessControl(_routerAddress).owner();

        // when
        vm.prank(_owner);
        SpreadAccessControl(_routerAddress).transferOwnership(newOwner);
        vm.prank(newOwner);
        SpreadAccessControl(_routerAddress).confirmTransferOwnership();

        // then
        assertEq(SpreadAccessControl(_routerAddress).owner(), newOwner, "router owner should be changed");
        assertEq(ownerBefore, _owner, "router owner should be deployer address");
    }

    function testShouldBeAbleToAddPauseGuardian() external {
        // given
        address newPauseGuardian = _getUserAddress(11);
        bool isPauseGuardianBefore = SpreadAccessControl(_routerAddress).isPauseGuardian(newPauseGuardian);

        // when
        vm.prank(_owner);
        SpreadAccessControl(_routerAddress).addPauseGuardian(newPauseGuardian);


        // then
        assertTrue(SpreadAccessControl(_routerAddress).isPauseGuardian(newPauseGuardian), "pause guardian should be added");
        assertFalse(isPauseGuardianBefore, "pause guardian should not be added");
    }

    function testShouldNotBeAbleToPauseWhenNotPauseGuardian() external {
        // given
        address pauseGuardian = _getUserAddress(11);
        address notPauseGuardian = _getUserAddress(12);
        uint256 isPausedBefore = SpreadAccessControl(_routerAddress).paused();

        // when
        vm.prank(_owner);
        SpreadAccessControl(_routerAddress).addPauseGuardian(pauseGuardian);

        vm.prank(notPauseGuardian);
        vm.expectRevert(bytes(IporErrors.CALLER_NOT_GUARDIAN));
        SpreadAccessControl(_routerAddress).pause();

        // then
        assertTrue(SpreadAccessControl(_routerAddress).isPauseGuardian(pauseGuardian), "pause guardian should be added");
        assertFalse(SpreadAccessControl(_routerAddress).isPauseGuardian(notPauseGuardian), "pause guardian should not be added");
        assertTrue(isPausedBefore == 0, "router should not be paused");
        assertTrue(SpreadAccessControl(_routerAddress).paused() == 0, "router should not be paused");
    }

    // todo Add full set of tests for SpreadAccessControl
}

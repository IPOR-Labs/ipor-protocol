// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.16;

import "forge-std/Test.sol";
import "../TestCommons.sol";
import "../../contracts/mocks/stanley/MockIporOwnableUpgradeable.sol";
import "../../contracts/libraries/errors/IporErrors.sol";

contract IporOwnableUpgradeableTest is Test, TestCommons {
    MockIporOwnableUpgradeable internal _iporOwnableUpgradeable;
    address internal _admin;
    address internal _userOne;
    address internal _userTwo;

    function setUp() public {
        _iporOwnableUpgradeable = new MockIporOwnableUpgradeable();
        _admin = address(this);
        _userOne = _getUserAddress(1);
        _userTwo = _getUserAddress(2);
    }

    function testShouldZeroAddressBeOwnerWhenDeployedWithoutInitialize()
        public
    {
        // given
        // when
        // then
        address owner = _iporOwnableUpgradeable.owner();
        assertEq(owner, address(0));
    }

    function testShouldDeployerBeOwner() public {
        // given
        // when
        _iporOwnableUpgradeable.initialize();
        // then
        address owner = _iporOwnableUpgradeable.owner();
        assertEq(owner, _admin);
    }

    function testShouldNotBePossibleToTransferToZeroAddress() public {
        // given
        _iporOwnableUpgradeable.initialize();
        address ownerBefore = _iporOwnableUpgradeable.owner();

        // when
        vm.expectRevert(abi.encodePacked(IporErrors.WRONG_ADDRESS));
        _iporOwnableUpgradeable.transferOwnership(address(0));

        // then
        address ownerAfter = _iporOwnableUpgradeable.owner();

        assertEq(ownerBefore, _admin);
        assertEq(ownerAfter, _admin);
    }

    function testShouldNotBePossibleToConfirmTheTransferOwnershipFromDifferentAddress()
        public
    {
        // given
        _iporOwnableUpgradeable.initialize();
        address ownerBefore = _iporOwnableUpgradeable.owner();
        _iporOwnableUpgradeable.transferOwnership(_userOne);

        // when
        vm.prank(_userTwo);
        vm.expectRevert(
            abi.encodePacked(IporErrors.SENDER_NOT_APPOINTED_OWNER)
        );
        _iporOwnableUpgradeable.confirmTransferOwnership();

        // then
        address ownerAfter = _iporOwnableUpgradeable.owner();

        assertEq(ownerBefore, _admin);
        assertEq(ownerAfter, _admin);
    }

    function testShouldBeAbleToTransferOwnershipToUserOne() public {
        // given
        _iporOwnableUpgradeable.initialize();
        _iporOwnableUpgradeable.transferOwnership(_userOne);

        // when
        vm.prank(_userOne);
        _iporOwnableUpgradeable.confirmTransferOwnership();

        // then
        address owner = _iporOwnableUpgradeable.owner();
        assertEq(owner, _userOne);
    }

    function testShouldZeroAddressBeOwnerWhenRenounceOwnership() public {
        // given
        _iporOwnableUpgradeable.initialize();
        address ownerBefore = _iporOwnableUpgradeable.owner();

        // when
        _iporOwnableUpgradeable.renounceOwnership();

        // then
        address ownerAfter = _iporOwnableUpgradeable.owner();
        assertEq(ownerBefore, _admin);
        assertEq(ownerAfter, address(0));
    }

    function testShouldNotBeAbleToRenounceOwnershipWhenUserIsNotOwner() public {
        // given
        _iporOwnableUpgradeable.initialize();
        address ownerBefore = _iporOwnableUpgradeable.owner();

        // when
        vm.prank(_userOne);
        vm.expectRevert(abi.encodePacked("Ownable: caller is not the owner"));
        _iporOwnableUpgradeable.renounceOwnership();

        // then
        address ownerAfter = _iporOwnableUpgradeable.owner();
        assertEq(ownerBefore, _admin);
        assertEq(ownerAfter, _admin);
    }

    function testShouldNotBeAbleToConfirmTransferOwnershipWhenRenounceOwnership()
        public
    {
        // given
        _iporOwnableUpgradeable.initialize();
        address ownerBefore = _iporOwnableUpgradeable.owner();

        _iporOwnableUpgradeable.transferOwnership(_userOne);
        _iporOwnableUpgradeable.renounceOwnership();

        // when
        vm.expectRevert(
            abi.encodePacked(IporErrors.SENDER_NOT_APPOINTED_OWNER)
        );
        _iporOwnableUpgradeable.confirmTransferOwnership();

        // then
        address ownerAfter = _iporOwnableUpgradeable.owner();

        assertEq(ownerBefore, _admin);
        assertEq(ownerAfter, address(0));
    }
}

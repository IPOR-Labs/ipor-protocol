// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.20;

import "forge-std/Test.sol";
import "../TestCommons.sol";
import "contracts/security/IporOwnable.sol";
import "contracts/libraries/errors/IporErrors.sol";

contract IporOwnableTest is Test, TestCommons {
    IporOwnable internal _iporOwnable;
    address internal _admin;
    address internal _userOne;
    address internal _userTwo;

    function setUp() public {
        _iporOwnable = new IporOwnable();
        _admin = address(this);
        _userOne = _getUserAddress(1);
        _userTwo = _getUserAddress(2);
    }

    function testShouldBeOwnerOfContract() public {
        // given
        // when
        // then
        address owner = _iporOwnable.owner();
        assertEq(owner, _admin);
    }

    function testShouldNotBePossibleToTransferToZeroAddress() public {
        // given
        address ownerBefore = _iporOwnable.owner();

        // when
        vm.expectRevert(abi.encodePacked(IporErrors.WRONG_ADDRESS));
        _iporOwnable.transferOwnership(address(0));

        // then
        address ownerAfter = _iporOwnable.owner();

        assertEq(ownerBefore, _admin);
        assertEq(ownerAfter, _admin);
    }

    function testShouldNotBePossibleToConfirmTheTransferOwnershipFromDifferentAddress() public {
        // given
        address ownerBefore = _iporOwnable.owner();
        _iporOwnable.transferOwnership(_userOne);

        // when
        vm.prank(_userTwo);
        vm.expectRevert(abi.encodePacked(IporErrors.SENDER_NOT_APPOINTED_OWNER));
        _iporOwnable.confirmTransferOwnership();

        // then
        address ownerAfter = _iporOwnable.owner();

        assertEq(ownerBefore, _admin);
        assertEq(ownerAfter, _admin);
    }

    function testShouldBeAbleToTransferOwnershipToUserOne() public {
        // given
        _iporOwnable.transferOwnership(_userOne);
        vm.prank(_userOne);

        // when
        _iporOwnable.confirmTransferOwnership();

        // then
        address owner = _iporOwnable.owner();
        assertEq(owner, _userOne);
    }

    function testShouldZeroAddressBeOwnerWhenRenounceOwnership() public {
        //given
        address ownerBefore = _iporOwnable.owner();

        //when
        _iporOwnable.renounceOwnership();

        //then
        address ownerAfter = _iporOwnable.owner();

        assertEq(ownerBefore, _admin);
        assertEq(ownerAfter, address(0));
    }

    function testShouldNotBeAbleToRenounceOwnershipWhenUserIsNotOwner() public {
        //given
        address ownerBefore = _iporOwnable.owner();

        // when
        vm.prank(_userOne);
        vm.expectRevert(abi.encodePacked("Ownable: caller is not the owner"));
        _iporOwnable.renounceOwnership();

        //then
        address ownerAfter = _iporOwnable.owner();

        assertEq(ownerBefore, _admin);
        assertEq(ownerAfter, _admin);
    }

    function testShouldNotBeAbleToConfirmTransferOwnershipWhenRenounceOwnership() public {
        //given
        address ownerBefore = _iporOwnable.owner();

        _iporOwnable.transferOwnership(ownerBefore);
        _iporOwnable.renounceOwnership();

        //when
        vm.expectRevert(abi.encodePacked(IporErrors.SENDER_NOT_APPOINTED_OWNER));
        _iporOwnable.confirmTransferOwnership();

        //then
        address ownerAfter = _iporOwnable.owner();

        assertEq(ownerBefore, _admin);
        assertEq(ownerAfter, address(0));
    }
}

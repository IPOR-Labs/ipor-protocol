// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.16;

import "forge-std/Test.sol";
import "../TestCommons.sol";
import "../../contracts/mocks/spread/MockBaseMiltonSpreadModelDai.sol";

contract MiltonSpreadCoreTest is Test, TestCommons {
    MockBaseMiltonSpreadModelDai internal _miltonSpread;
    address internal _admin;
    address internal _userOne;
    address internal _userTwo;

    function setUp() public {
        _miltonSpread = new MockBaseMiltonSpreadModelDai();
        _admin = address(this);
        _userOne = _getUserAddress(1);
        _userTwo = _getUserAddress(2);
    }

	function testShouldTransferOwnership() public {
		// given
		address ownerBefore = _miltonSpread.owner();
		_miltonSpread.transferOwnership(_userOne);
		// when
		vm.prank(_userOne);
		_miltonSpread.confirmTransferOwnership();
		// then
		address ownerAfter = _miltonSpread.owner();
		assertEq(ownerBefore, _admin);
		assertEq(ownerAfter, _userOne);
	}

	function testShouldNotTransferOwnershipWhenSenderNotCurrentOwner() public {
		// given
		address ownerBefore = _miltonSpread.owner();
		// when
		vm.prank(_userTwo);
		vm.expectRevert(abi.encodePacked("Ownable: caller is not the owner"));
		_miltonSpread.transferOwnership(_userOne);
		// then
		address ownerAfter = _miltonSpread.owner();
		assertEq(ownerBefore, _admin);
		assertEq(ownerAfter, _admin);
	}

	function testShouldNotConfirmTransferOwnershipWhenSenderNotAppointedOwner() public {
		// given
		address ownerBefore = _miltonSpread.owner();
		// when
		_miltonSpread.transferOwnership(_userOne);
		vm.prank(_userTwo);
		vm.expectRevert(abi.encodePacked("IPOR_007"));
		_miltonSpread.confirmTransferOwnership();
		// then
		address ownerAfter = _miltonSpread.owner();
		assertEq(ownerBefore, _admin);
		assertEq(ownerAfter, _admin);
	}

	function testShouldNotConfirmTransferOwnershipTwiceWhenSenderNotAppointedOwner() public {
		// given
		address ownerBefore = _miltonSpread.owner();
		// when
		_miltonSpread.transferOwnership(_userOne);
		vm.prank(_userOne);
		_miltonSpread.confirmTransferOwnership();
		vm.expectRevert(abi.encodePacked("IPOR_007"));
		_miltonSpread.confirmTransferOwnership();
		// then
		address ownerAfter = _miltonSpread.owner();
		assertEq(ownerBefore, _admin);
		assertEq(ownerAfter, _userOne);
	}

	function testShouldNotTransferOwnershipWhenSenderAlreadyLostOwnership() public {
		// given
		address ownerBefore = _miltonSpread.owner();
		// when
		_miltonSpread.transferOwnership(_userOne);
		vm.prank(_userOne);
		_miltonSpread.confirmTransferOwnership();
		vm.expectRevert(abi.encodePacked("Ownable: caller is not the owner"));
		_miltonSpread.transferOwnership(_userTwo);
		// then
		address ownerAfter = _miltonSpread.owner();
		assertEq(ownerBefore, _admin);
		assertEq(ownerAfter, _userOne);
	}

	function testShouldHaveRightsToTransferOwnershipWhenSenderStillHasRights() public {
		// given
		address ownerBefore = _miltonSpread.owner();
		// when
		_miltonSpread.transferOwnership(_userOne);
		// then
		address ownerAfter = _miltonSpread.owner();
		assertEq(ownerBefore, _admin);
		assertEq(ownerAfter, _admin);
	}	

	function testShouldReturnProperConstantForDai() public {
		// given
		// when
		int256 payFixedRegionOneBase = _miltonSpread.getPayFixedRegionOneBase();
		int256 payFixedRegionOneSlopeForVolatility = _miltonSpread.getPayFixedRegionOneSlopeForVolatility();
		int256 payFixedRegionOneSlopeForMeanReversion = _miltonSpread.getPayFixedRegionOneSlopeForMeanReversion();
		int256 payFixedRegionTwoBase = _miltonSpread.getPayFixedRegionTwoBase();
		int256 payFixedRegionTwoSlopeForVolatility = _miltonSpread.getPayFixedRegionTwoSlopeForVolatility();
		int256 payFixedRegionTwoSlopeForMeanReversion = _miltonSpread.getPayFixedRegionTwoSlopeForMeanReversion();
		int256 receiveFixedRegionOneBase = _miltonSpread.getReceiveFixedRegionOneBase();
		int256 receiveFixedRegionOneSlopeForVolatility = _miltonSpread.getReceiveFixedRegionOneSlopeForVolatility();
		int256 receiveFixedRegionOneSlopeForMeanReversion = _miltonSpread.getReceiveFixedRegionOneSlopeForMeanReversion();
		int256 receiveFixedRegionTwoBase = _miltonSpread.getReceiveFixedRegionTwoBase();
		int256 receiveFixedRegionTwoSlopeForVolatility = _miltonSpread.getReceiveFixedRegionTwoSlopeForVolatility();
		int256 receiveFixedRegionTwoSlopeForMeanReversion = _miltonSpread.getReceiveFixedRegionTwoSlopeForMeanReversion();
		// then
		assertEq(payFixedRegionOneBase, 223452028860278);
		assertEq(payFixedRegionOneSlopeForVolatility, 66176612458519781376);
		assertEq(payFixedRegionOneSlopeForMeanReversion, -1186134254033851648);
		assertEq(payFixedRegionTwoBase, 145660962344800);
		assertEq(payFixedRegionTwoSlopeForVolatility, 213838820626510938112);
		assertEq(payFixedRegionTwoSlopeForMeanReversion, -963243845920214784);
		assertEq(receiveFixedRegionOneBase, -86557160865515);
		assertEq(receiveFixedRegionOneSlopeForVolatility, -37390455427043344384);
		assertEq(receiveFixedRegionOneSlopeForMeanReversion, -1129730689647621632);
		assertEq(receiveFixedRegionTwoBase, -55994330424481);
		assertEq(receiveFixedRegionTwoSlopeForVolatility, -89741154814986338304);
		assertEq(receiveFixedRegionTwoSlopeForMeanReversion, 37480678662666200);
	}

}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.16;

import "forge-std/Test.sol";
import "../TestCommons.sol";
import "../../contracts/mocks/spread/MockBaseMiltonSpreadModelDai.sol";

contract MiltonSpreadPremiumVAMRTest is Test, TestCommons {
    MockBaseMiltonSpreadModelDai internal _miltonSpread;
    address internal _admin;
    address internal _userOne;

    function setUp() public {
        _miltonSpread = new MockBaseMiltonSpreadModelDai();
        _admin = address(this);
        _userOne = _getUserAddress(1);
    }

	function testShouldCalculateSpreadVolatilityAndMeanReversionPayFixed() public {
		// given
		uint256 emaVar = 1065000000000000000;
		int256 diffIporIndexEma = -7140000000000000000;
		int256 expectedResult = 234616050688066827447;
		// when
		vm.prank(_userOne);
		int256 actualResult = _miltonSpread.mockTestCalculateVolatilityAndMeanReversionPayFixed(emaVar, diffIporIndexEma);
		// then
		assertEq(actualResult, expectedResult);
	}

	function testShouldCalculateSpreadVolatilityAndMeanReversionReceiveFixed() public {
		// given
		uint256 emaVar = 1065000000000000000;
		int256 diffIporIndexEma = -7140000000000000000;
		int256 expectedResult = -95841997917942311442;
		// when
		vm.prank(_userOne);
		int256 actualResult = _miltonSpread.mockTestCalculateVolatilityAndMeanReversionReceiveFixed(emaVar, diffIporIndexEma);
		// then
		assertEq(actualResult, expectedResult);
	}

	function testShouldCalculateSpreadVolatilityAndMeanReversionPayFixedRegionOne() public {
		// given
		uint256 emaVar = 1065000000000000000;
		int256 diffIporIndexEma = -7140000000000000000;
		int256 expectedResult = 78947314294154128210;
		// when
		vm.prank(_userOne);
		int256 actualResult = _miltonSpread.mockTestVolatilityAndMeanReversionPayFixedRegionOne(emaVar, diffIporIndexEma);
		// then
		assertEq(actualResult, expectedResult);
	}

	function testShouldCalculateSpreadVolatilityAndMeanReversionReceiveFixedRegionOne() public {
		// given
		uint256 emaVar = 1065000000000000000;
		int256 diffIporIndexEma = -7140000000000000000;
		int256 expectedResult = -31754644462878008830;
		// when
		vm.prank(_userOne);
		int256 actualResult = _miltonSpread.mockTestVolatilityAndMeanReversionReceiveFixedRegionOne(emaVar, diffIporIndexEma);
		// then
		assertEq(actualResult, expectedResult);
	}

	function testShouldCalculateSpreadVolatilityAndMeanReversionPayFixedRegionTwo() public {
		// given
		uint256 emaVar = 1065000000000000000;
		int256 diffIporIndexEma = -7140000000000000000;
		int256 expectedResult = 234616050688066827447;
		// when
		vm.prank(_userOne);
		int256 actualResult = _miltonSpread.mockTestVolatilityAndMeanReversionPayFixedRegionTwo(emaVar, diffIporIndexEma);
		// then
		assertEq(actualResult, expectedResult);
	}

	function testShouldCalculateSpreadVolatilityAndMeanReversionReceiveFixedRegionTwo() public {
		// given
		uint256 emaVar = 1065000000000000000;
		int256 diffIporIndexEma = -7140000000000000000;
		int256 expectedResult = -95841997917942311442;
		// when
		vm.prank(_userOne);
		int256 actualResult = _miltonSpread.mockTestVolatilityAndMeanReversionReceiveFixedRegionTwo(emaVar, diffIporIndexEma);
		// then
		assertEq(actualResult, expectedResult);
	}

}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.16;

import "forge-std/Test.sol";
import "../TestCommons.sol";
import "../../contracts/mocks/spread/MockBaseMiltonSpreadModelDai.sol";

contract MiltonSpreadPremiumVAMRTest is Test, TestCommons {
    MockBaseMiltonSpreadModelDai internal _miltonSpread;
    address internal _userOne;

    function setUp() public {
        _miltonSpread = new MockBaseMiltonSpreadModelDai();
        _userOne = _getUserAddress(1);
    }

	function testShouldCalculateSpreadVolatilityAndMeanReversionPayFixed() public {
		// given
		uint256 emaVar = 1065000000000000000;
		int256 diffIporIndexEma = -7140000000000000000;
		int256 expectedResult = 319500267139772943892;
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
		int256 expectedResult = -319500250420413078569;
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
		int256 expectedResult = 13916588006818699771;
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
		int256 expectedResult = -7140253477072294644;
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
		int256 expectedResult = 319500267139772943892;
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
		int256 expectedResult = -319500250420413078569;
		// when
		vm.prank(_userOne);
		int256 actualResult = _miltonSpread.mockTestVolatilityAndMeanReversionReceiveFixedRegionTwo(emaVar, diffIporIndexEma);
		// then
		assertEq(actualResult, expectedResult);
	}

}

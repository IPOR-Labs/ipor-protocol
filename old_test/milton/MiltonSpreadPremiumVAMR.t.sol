// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.16;

import "forge-std/Test.sol";
import "../TestCommons.sol";
import "contracts/mocks/spread/MockBaseAmmTreasurySpreadModelDai.sol";

contract AmmTreasurySpreadPremiumVAMRTest is Test, TestCommons {
    MockBaseAmmTreasurySpreadModelDai internal _ammTreasurySpread;
    address internal _userOne;

    function setUp() public {
        _ammTreasurySpread = new MockBaseAmmTreasurySpreadModelDai();
        _userOne = _getUserAddress(1);
    }

    function testShouldCalculateSpreadVolatilityAndMeanReversionPayFixed() public {
        // given
        uint256 emaVar = 1065000000000000000;
        int256 diffIporIndexEma = -7140000000000000000;
        int256 expectedResult = 319500267139772943892;
        // when
        vm.prank(_userOne);
        int256 actualResult = _ammTreasurySpread.mockTestCalculateVolatilityAndMeanReversionPayFixed(
            emaVar,
            diffIporIndexEma
        );
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
        int256 actualResult = _ammTreasurySpread.mockTestCalculateVolatilityAndMeanReversionReceiveFixed(
            emaVar,
            diffIporIndexEma
        );
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
        int256 actualResult = _ammTreasurySpread.mockTestVolatilityAndMeanReversionPayFixedRegionOne(
            emaVar,
            diffIporIndexEma
        );
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
        int256 actualResult = _ammTreasurySpread.mockTestVolatilityAndMeanReversionReceiveFixedRegionOne(
            emaVar,
            diffIporIndexEma
        );
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
        int256 actualResult = _ammTreasurySpread.mockTestVolatilityAndMeanReversionPayFixedRegionTwo(
            emaVar,
            diffIporIndexEma
        );
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
        int256 actualResult = _ammTreasurySpread.mockTestVolatilityAndMeanReversionReceiveFixedRegionTwo(
            emaVar,
            diffIporIndexEma
        );
        // then
        assertEq(actualResult, expectedResult);
    }
}

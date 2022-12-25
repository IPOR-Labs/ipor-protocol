// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.16;

import "forge-std/Test.sol";
import "../TestCommons.sol";
import "../../contracts/libraries/Constants.sol";
import "../../contracts/mocks/spread/MockBaseMiltonSpreadModelDai.sol";
import "../../contracts/interfaces/types/IporTypes.sol";

contract MiltonSpreadReceiveFixedTest is Test, TestCommons {
    MockBaseMiltonSpreadModelDai internal _miltonSpread;
    address internal _userOne;

    function setUp() public {
        _miltonSpread = new MockBaseMiltonSpreadModelDai();
        _userOne = _getUserAddress(1);
    }

	function testShouldCalculateQuoteValueReceiveFixedSpreadPremiumsNegativeAndAbsoluteValueSpreadPremiumLowerThanIporIndexAndEMAGreaterThanQuoteValue() public {
		// given
		uint256 liquidityPoolBalance = 15000 * Constants.D18;
		uint256 swapCollateral = 10000 * Constants.D18;
		uint256 openingFee = 20 * Constants.D18;
		IporTypes.AccruedIpor memory accruedIpor = IporTypes.AccruedIpor(
			3 * 10**16, // indexValue: 3%
			1 * 10**18, // ibtPrice: 1
			1 * 10**16, // exponentialMovingAverage: 1%
			1 * 10**13 // exponentialWeightedMovingVariance: 0.00001%
		);
		IporTypes.MiltonBalancesMemory memory accruedBalance = IporTypes.MiltonBalancesMemory(
			10000 * Constants.D18 + swapCollateral, // totalCollateralPayFixed 
			13000 * Constants.D18, // totalCollateralReceiveFixed
			liquidityPoolBalance + openingFee, // liquidityPool
			0 // vault
		);
		uint256 expectedQuoteValue = 10000000000000000;
		// when
		vm.prank(_userOne);
		uint256 actualQuotedValue = _miltonSpread.calculateQuoteReceiveFixed(accruedIpor, accruedBalance);
		// then
		assertEq(actualQuotedValue, expectedQuoteValue);
        //Actual EMA higher than Quote Value for this particular test case.
		assertGe(accruedIpor.exponentialMovingAverage, actualQuotedValue);
	}

	function testShouldCalculateQuoteValueReceiveFixedSpreadPremiumsNegativeAndAbsoluteValueSpreadPremiumGreaterIporIndexAndNormalEmvarAndQuoteLowerThanZero() public{
		// given
		uint256 liquidityPoolBalance = 15000 * Constants.D18;
		uint256 swapCollateral = 10000 * Constants.D18;
		uint256 openingFee = 20 * Constants.D18;
		IporTypes.AccruedIpor memory accruedIpor = IporTypes.AccruedIpor(
			9 * 10**16, // indexValue: 9%
			1 * 10**18, // ibtPrice: 1
			1 * 10**16, // exponentialMovingAverage: 1%
			1 * 10**12 // exponentialWeightedMovingVariance: 0.000001%
		);
		IporTypes.MiltonBalancesMemory memory accruedBalance = IporTypes.MiltonBalancesMemory(
			10000 * Constants.D18 + swapCollateral, // totalCollateralPayFixed 
			13000 * Constants.D18, // totalCollateralReceiveFixed
			liquidityPoolBalance + openingFee, // liquidityPool
			0 // vault
		);
		uint256 expectedQuoteValue = 10000000000000000;
		// when
		vm.prank(_userOne);
		uint256 actualQuotedValue = _miltonSpread.calculateQuoteReceiveFixed(accruedIpor, accruedBalance);
		// then
		assertEq(actualQuotedValue, expectedQuoteValue);
        //Actual EMA cannot be lower than Quote Value for this particular test case.
		assertGe(accruedIpor.exponentialMovingAverage, actualQuotedValue);
	}

	function testShouldCalculateQuoteValueReceiveFixedSpreadPremiumsNegativeAndAbsoluteValueSpreadPremiumGreaterThanIporIndex() public {
		// given
		uint256 liquidityPoolBalance = 15000 * Constants.D18;
		uint256 swapCollateral = 10000 * Constants.D18;
		uint256 openingFee = 20 * Constants.D18;
		IporTypes.AccruedIpor memory accruedIpor = IporTypes.AccruedIpor(
			4 * 10**16, // indexValue: 4%
			1 * 10**18, // ibtPrice: 1
			3 * 10**16, // exponentialMovingAverage: 3%
			1 * 10**15 // exponentialWeightedMovingVariance: 0.001%
		);
		IporTypes.MiltonBalancesMemory memory accruedBalance = IporTypes.MiltonBalancesMemory(
			10000 * Constants.D18 + swapCollateral, // totalCollateralPayFixed 
			13000 * Constants.D18, // totalCollateralReceiveFixed
			liquidityPoolBalance + openingFee, // liquidityPool
			0 // vault
		);
		uint256 expectedQuoteValue = 0;
		// when
		vm.prank(_userOne);
		uint256 actualQuotedValue = _miltonSpread.calculateQuoteReceiveFixed(accruedIpor, accruedBalance);
		// then
		assertEq(actualQuotedValue, expectedQuoteValue);
	}

	function testShouldCalculateQuoteValueReceiveFixedSpreadPremiumsNegativeAndAbsoluteValueSpreadPremiumLowerThanIporIndex() public {
		// given
		uint256 liquidityPoolBalance = 15000 * Constants.D18;
		uint256 swapCollateral = 10000 * Constants.D18;
		uint256 openingFee = 20 * Constants.D18;
		IporTypes.AccruedIpor memory accruedIpor = IporTypes.AccruedIpor(
			4 * 10**16, // indexValue: 4%
			1 * 10**18, // ibtPrice: 1
			3 * 10**16, // exponentialMovingAverage: 3%
			1 * 10**12 // exponentialWeightedMovingVariance: 0.000001%
		);
		IporTypes.MiltonBalancesMemory memory accruedBalance = IporTypes.MiltonBalancesMemory(
			10000 * Constants.D18 + swapCollateral, // totalCollateralPayFixed 
			13000 * Constants.D18, // totalCollateralReceiveFixed
			liquidityPoolBalance + openingFee, // liquidityPool
			0 // vault
		);
		uint256 expectedQuoteValue = 30000000000000000;
		// when
		vm.prank(_userOne);
		uint256 actualQuotedValue = _miltonSpread.calculateQuoteReceiveFixed(accruedIpor, accruedBalance);
		// then
		assertEq(actualQuotedValue, expectedQuoteValue);
        //Actual Quote Value cannot be higher than 2xIndex Value for this particular test case.
		assertGe(accruedIpor.indexValue * 2, actualQuotedValue);
	}

}

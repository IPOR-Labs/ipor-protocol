// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.20;

import "forge-std/Test.sol";
import "../TestCommons.sol";
import "contracts/libraries/Constants.sol";
import "contracts/mocks/spread/MockBaseAmmTreasurySpreadModelDai.sol";
import "contracts/interfaces/types/IporTypes.sol";

contract AmmTreasurySpreadReceiveFixedTest is Test, TestCommons {
    MockBaseAmmTreasurySpreadModelDai internal _ammTreasurySpread;
    address internal _userOne;

    function setUp() public {
        _ammTreasurySpread = new MockBaseAmmTreasurySpreadModelDai();
        _userOne = _getUserAddress(1);
    }

	function testShouldCalculateQuoteValueReceiveFixedSpreadPremiumsNegativeAndAbsoluteValueSpreadPremiumLowerThanIporIndexAndEMAGreaterThanQuoteValue() public {
		// given
		uint256 liquidityPoolBalance = 15000 * 1e18;
		uint256 swapCollateral = 10000 * 1e18;
		uint256 openingFee = 20 * 1e18;
		IporTypes.AccruedIpor memory accruedIpor = IporTypes.AccruedIpor(
			3 * 10**16, // indexValue: 3%
			1 * 10**18 // ibtPrice: 1
		);
		IporTypes.AmmBalancesMemory memory accruedBalance = IporTypes.AmmBalancesMemory(
			10000 * 1e18 + swapCollateral, // totalCollateralPayFixed
			13000 * 1e18, // totalCollateralReceiveFixed
			liquidityPoolBalance + openingFee, // liquidityPool
			0 // vault
		);
		uint256 expectedQuoteValue = 10000000000000000;
		// when
		vm.prank(_userOne);
		uint256 actualQuotedValue = _ammTreasurySpread.calculateQuoteReceiveFixed(accruedIpor, accruedBalance);
		// then
		assertEq(actualQuotedValue, expectedQuoteValue);
	}

	function testShouldCalculateQuoteValueReceiveFixedSpreadPremiumsNegativeAndAbsoluteValueSpreadPremiumGreaterIporIndexAndNormalEmvarAndQuoteLowerThanZero() public{
		// given
		uint256 liquidityPoolBalance = 15000 * 1e18;
		uint256 swapCollateral = 10000 * 1e18;
		uint256 openingFee = 20 * 1e18;
		IporTypes.AccruedIpor memory accruedIpor = IporTypes.AccruedIpor(
			9 * 10**16, // indexValue: 9%
			1 * 10**18 // ibtPrice: 1
		);
		IporTypes.AmmBalancesMemory memory accruedBalance = IporTypes.AmmBalancesMemory(
			10000 * 1e18 + swapCollateral, // totalCollateralPayFixed
			13000 * 1e18, // totalCollateralReceiveFixed
			liquidityPoolBalance + openingFee, // liquidityPool
			0 // vault
		);
		uint256 expectedQuoteValue = 10000000000000000;
		// when
		vm.prank(_userOne);
		uint256 actualQuotedValue = _ammTreasurySpread.calculateQuoteReceiveFixed(accruedIpor, accruedBalance);
		// then
		assertEq(actualQuotedValue, expectedQuoteValue);
	}

	function testShouldCalculateQuoteValueReceiveFixedSpreadPremiumsNegativeAndAbsoluteValueSpreadPremiumGreaterThanIporIndex() public {
		// given
		uint256 liquidityPoolBalance = 15000 * 1e18;
		uint256 swapCollateral = 10000 * 1e18;
		uint256 openingFee = 20 * 1e18;
		IporTypes.AccruedIpor memory accruedIpor = IporTypes.AccruedIpor(
			4 * 10**16, // indexValue: 4%
			1 * 10**18 // ibtPrice: 1
		);
		IporTypes.AmmBalancesMemory memory accruedBalance = IporTypes.AmmBalancesMemory(
			10000 * 1e18 + swapCollateral, // totalCollateralPayFixed
			13000 * 1e18, // totalCollateralReceiveFixed
			liquidityPoolBalance + openingFee, // liquidityPool
			0 // vault
		);
		uint256 expectedQuoteValue = 0;
		// when
		vm.prank(_userOne);
		uint256 actualQuotedValue = _ammTreasurySpread.calculateQuoteReceiveFixed(accruedIpor, accruedBalance);
		// then
		assertEq(actualQuotedValue, expectedQuoteValue);
	}

	function testShouldCalculateQuoteValueReceiveFixedSpreadPremiumsNegativeAndAbsoluteValueSpreadPremiumLowerThanIporIndex() public {
		// given
		uint256 liquidityPoolBalance = 15000 * 1e18;
		uint256 swapCollateral = 10000 * 1e18;
		uint256 openingFee = 20 * 1e18;
		IporTypes.AccruedIpor memory accruedIpor = IporTypes.AccruedIpor(
			4 * 10**16, // indexValue: 4%
			1 * 10**18 // ibtPrice: 1
		);
		IporTypes.AmmBalancesMemory memory accruedBalance = IporTypes.AmmBalancesMemory(
			10000 * 1e18 + swapCollateral, // totalCollateralPayFixed
			13000 * 1e18, // totalCollateralReceiveFixed
			liquidityPoolBalance + openingFee, // liquidityPool
			0 // vault
		);
		uint256 expectedQuoteValue = 30000000000000000;
		// when
		vm.prank(_userOne);
		uint256 actualQuotedValue = _ammTreasurySpread.calculateQuoteReceiveFixed(accruedIpor, accruedBalance);
		// then
		assertEq(actualQuotedValue, expectedQuoteValue);
        //Actual Quote Value cannot be higher than 2xIndex Value for this particular test case.
		assertGe(accruedIpor.indexValue * 2, actualQuotedValue);
	}

}

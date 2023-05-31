// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.16;

import "forge-std/Test.sol";
import "../TestCommons.sol";
import "contracts/libraries/Constants.sol";
import "contracts/mocks/spread/MockBaseAmmTreasurySpreadModelDai.sol";
import "contracts/interfaces/types/IporTypes.sol";

contract AmmTreasurySpreadPayFixedTest is Test, TestCommons {
    MockBaseAmmTreasurySpreadModelDai internal _ammTreasurySpread;
    address internal _userOne;

    function setUp() public {
        _ammTreasurySpread = new MockBaseAmmTreasurySpreadModelDai();
        _userOne = _getUserAddress(1);
    }

    function testShouldCalculateQuoteValuePayFixedSpreadPremiumsPositiveAndBiggerThanIpor() public {
        // given
        uint256 liquidityPoolBalance = 15000 * 1e18;
        uint256 swapCollateral = 10000 * 1e18;
        uint256 openingFee = 20 * 1e18;
        IporTypes.AccruedIpor memory accruedIpor = IporTypes.AccruedIpor(
            13 * 10**16, // indexValue: 13%
            1 * 10**18, // ibtPrice: 1
            1 * 10**16, // exponentialMovingAverage: 1%
            15 * 10**15 // exponentialWeightedMovingVariance: 0.15%
        );
        IporTypes.AmmBalancesMemory memory accruedBalance = IporTypes.AmmBalancesMemory(
            10000 * 1e18 + swapCollateral, // totalCollateralPayFixed
            13000 * 1e18, // totalCollateralReceiveFixed
            liquidityPoolBalance + openingFee, // liquidityPool
            0 // vault
        );
        uint256 expectedQuoteValue = 4630250241405252731;
        // when
        vm.prank(_userOne);
        uint256 actualQuotedValue = _ammTreasurySpread.calculateQuotePayFixed(accruedIpor, accruedBalance);
        // then
        assertEq(actualQuotedValue, expectedQuoteValue);
        assertLe(accruedIpor.indexValue, actualQuotedValue);
    }

    function testShouldCalculateQuoteValuePayFixedSpreadPremiumsPositive() public {
        // given
        uint256 liquidityPoolBalance = 15000 * 1e18;
        uint256 swapCollateral = 10000 * 1e18;
        uint256 openingFee = 20 * 1e18;
        IporTypes.AccruedIpor memory accruedIpor = IporTypes.AccruedIpor(
            2 * 10**16, // indexValue: 2%
            1 * 10**18, // ibtPrice: 1
            1 * 10**16, // exponentialMovingAverage: 1%
            15 * 10**15 // exponentialWeightedMovingVariance: 0.15%
        );
        IporTypes.AmmBalancesMemory memory accruedBalance = IporTypes.AmmBalancesMemory(
            10000 * 1e18 + swapCollateral, // totalCollateralPayFixed
            13000 * 1e18, // totalCollateralReceiveFixed
            liquidityPoolBalance + openingFee, // liquidityPool
            0 // vault
        );
        uint256 expectedQuoteValue = 4520250241405252731;
        // when
        vm.prank(_userOne);
        uint256 actualQuotedValue = _ammTreasurySpread.calculateQuotePayFixed(accruedIpor, accruedBalance);
        // then
        assertEq(actualQuotedValue, expectedQuoteValue);
    }
}

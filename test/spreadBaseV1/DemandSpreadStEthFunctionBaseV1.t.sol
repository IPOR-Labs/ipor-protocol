// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.26;

import "forge-std/Test.sol";
import "../../contracts/base/spread/DemandSpreadStEthLibsBaseV1.sol";


contract DemandSpreadStEthFunctionBaseV1 is Test {


    function testShouldReturn0WhenWeightedNotionalIs0() external {
        //given
        uint weightedNotional = 0;
        uint maxNotional = 10e18;

        //when
        uint demandSpread = DemandSpreadStEthLibsBaseV1.calculateSpreadFunction(maxNotional, weightedNotional);

        //then
        assertEq(demandSpread, 0, "demandSpread should be 0");
    }

    function testShouldReturnAbout8bpsWhenWeightedNotionalIs1e18() external {
        //given
        uint weightedNotional = 1e18;
        uint maxNotional = 10e18;

        //when
        uint demandSpread = DemandSpreadStEthLibsBaseV1.calculateSpreadFunction(maxNotional, weightedNotional);

        //then
        assertEq(demandSpread, 833333333333333, "demandSpread should be 8.33333333333333bps");
    }

    function testShouldReturnAbout16bpsWhenWeightedNotionalIs2e18() external {
        //given
        uint weightedNotional = 2e18;
        uint maxNotional = 10e18;

        //when
        uint demandSpread = DemandSpreadStEthLibsBaseV1.calculateSpreadFunction(maxNotional, weightedNotional);

        //then
        assertEq(demandSpread, 1666666666666666, "demandSpread should be 16.66666666666666bps");
    }

    function testShouldReturnAbout83bpsWhenWeightedNotionalIs5e18() external {
        //given
        uint weightedNotional = 5e18;
        uint maxNotional = 10e18;

        //when
        uint demandSpread = DemandSpreadStEthLibsBaseV1.calculateSpreadFunction(maxNotional, weightedNotional);

        //then
        assertEq(demandSpread, 8333333333333334, "demandSpread should be 83.33333333333334bps");
    }


    function testShouldReturn3000bpsWhenWeightedNotionalIs10e18() external {
        //given
        uint weightedNotional = 10e18;
        uint maxNotional = 10e18;

        //when
        uint demandSpread = DemandSpreadStEthLibsBaseV1.calculateSpreadFunction(maxNotional, weightedNotional);

        //then
        assertEq(demandSpread, 5 * 1e16, "demandSpread should be 500bps");
    }


    function testShouldReturnSpreadBetweenOAnd50bps(uint weightedNotional) external {
        //given
        vm.assume(weightedNotional >= 0);
        vm.assume(weightedNotional <= 2000);
        uint maxNotional = 10_000;

        //when
        uint demandSpread = DemandSpreadStEthLibsBaseV1.calculateSpreadFunction(maxNotional, weightedNotional);

        //then
        assertTrue(demandSpread <= 20e14, "demandSpread should be less than 20bps");
        assertTrue(demandSpread >= 0, "demandSpread should be greater than 0bps");
    }

    function testShouldReturnSpreadBetween100And500bps(uint weightedNotional) external {
        //given
        vm.assume(weightedNotional > 2000);
        vm.assume(weightedNotional <= 5000);
        uint maxNotional = 10_000;

        //when
        uint demandSpread = DemandSpreadStEthLibsBaseV1.calculateSpreadFunction(maxNotional, weightedNotional);

        //then
        assertTrue(demandSpread <= 90e14, "demandSpread should be less than 90bps");
        assertTrue(demandSpread >= 15e14, "demandSpread should be greater than 15bps");
    }

    function testShouldReturnSpreadBetween500And3000bps(uint weightedNotional) external {
        //given
        vm.assume(weightedNotional > 5_000);
        vm.assume(weightedNotional <= 10_000);
        uint maxNotional = 10_000;

        //when
        uint demandSpread = DemandSpreadStEthLibsBaseV1.calculateSpreadFunction(maxNotional, weightedNotional);

        //then
        assertTrue(demandSpread <= 50e15, "demandSpread should be less than 500bps");
        assertTrue(demandSpread >= 80e14, "demandSpread should be greater than 80bps");
    }

}
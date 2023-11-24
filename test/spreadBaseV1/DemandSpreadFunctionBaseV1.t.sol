// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.20;

import "forge-std/Test.sol";
import "../../contracts/base/spread/DemandSpreadLibsBaseV1.sol";


contract DemandSpreadFunctionBaseV1 is Test {

    function testShouldReturn0WhenWeightedNotionalIs0() external {
        //given
        uint weightedNotional = 0;
        uint maxNotional = 10e18;

        //when
        uint demandSpread = DemandSpreadLibsBaseV1.calculateSpreadFunction(maxNotional, weightedNotional);

        //then
        assertEq(demandSpread, 0, "demandSpread should be 0");
    }

    function testShouldReturn50bpsWhenWeightedNotionalIs1e18() external {
        //given
        uint weightedNotional = 1e18;
        uint maxNotional = 10e18;

        //when
        uint demandSpread = DemandSpreadLibsBaseV1.calculateSpreadFunction(maxNotional, weightedNotional);

        //then
        assertEq(demandSpread, 5e15, "demandSpread should be 50bps");
    }

    function testShouldReturn100bpsWhenWeightedNotionalIs2e18() external {
        //given
        uint weightedNotional = 2e18;
        uint maxNotional = 10e18;

        //when
        uint demandSpread = DemandSpreadLibsBaseV1.calculateSpreadFunction(maxNotional, weightedNotional);

        //then
        assertEq(demandSpread, 10e15, "demandSpread should be 100bps");
    }

    function testShouldReturn500bpsWhenWeightedNotionalIs5e18() external {
        //given
        uint weightedNotional = 5e18;
        uint maxNotional = 10e18;

        //when
        uint demandSpread = DemandSpreadLibsBaseV1.calculateSpreadFunction(maxNotional, weightedNotional);

        //then
        assertEq(demandSpread, 50e15, "demandSpread should be 500bps");
    }


    function testShouldReturn3000bpsWhenWeightedNotionalIs10e18() external {
        //given
        uint weightedNotional = 10e18;
        uint maxNotional = 10e18;

        //when
        uint demandSpread = DemandSpreadLibsBaseV1.calculateSpreadFunction(maxNotional, weightedNotional);

        //then
        assertEq(demandSpread, 300e15, "demandSpread should be 3000bps");
    }


    function testShouldReturnSpreadBetweenOAnd50bps(uint weightedNotional) external {
        //given
        vm.assume(weightedNotional >= 0);
        vm.assume(weightedNotional <= 2000);
        uint maxNotional = 10_000;

        //when
        uint demandSpread = DemandSpreadLibsBaseV1.calculateSpreadFunction(maxNotional, weightedNotional);

        //then
        assertTrue(demandSpread <= 10e15, "demandSpread should be less than 100bps");
        assertTrue(demandSpread >= 0, "demandSpread should be greater than 0bps");
    }

    function testShouldReturnSpreadBetween100And500bps(uint weightedNotional) external {
        //given
        vm.assume(weightedNotional > 2000);
        vm.assume(weightedNotional <= 5000);
        uint maxNotional = 10_000;

        //when
        uint demandSpread = DemandSpreadLibsBaseV1.calculateSpreadFunction(maxNotional, weightedNotional);

        //then
        assertTrue(demandSpread <= 50e15, "demandSpread should be less than 500bps");
        assertTrue(demandSpread >= 10e15, "demandSpread should be greater than 100bps");
    }

    function testShouldReturnSpreadBetween500And3000bps(uint weightedNotional) external {
        //given
        vm.assume(weightedNotional > 5_000);
        vm.assume(weightedNotional <= 10_000);
        uint maxNotional = 10_000;

        //when
        uint demandSpread = DemandSpreadLibsBaseV1.calculateSpreadFunction(maxNotional, weightedNotional);

        //then
        assertTrue(demandSpread <= 300e15, "demandSpread should be less than 3000bps");
        assertTrue(demandSpread >= 50e15, "demandSpread should be greater than 500bps");
    }

}
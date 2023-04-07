// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.16;

import "../../TestCommons.sol";
import {DataUtils} from "../../utils/DataUtils.sol";
import "../../../contracts/mocks/MockIporSwapLogic.sol";

contract IporSwapLogicTest is TestCommons, DataUtils {
    MockIporSwapLogic internal _iporSwapLogic;

    function setUp() public {
        _iporSwapLogic = new MockIporSwapLogic();
    }

    function testShouldCalculateVirtualHedgingPositionElapsed10PositivePnLOppositeLegRateHigher()
        public
    {
        // given
        IporTypes.IporSwapMemory memory swap;

        int256 basePayoff = 200 * 1e18;
        int256 oppositeLegFixedRate = 5 * 1e16;

        swap.notional = 500_000 * 1e18;
        swap.fixedInterestRate = 3 * 1e16;
        swap.openTimestamp = block.timestamp;
        swap.endTimestamp = swap.openTimestamp + 28 days;

        uint256 closingTimestamp = swap.openTimestamp + 10 days;

        uint256 hedgingFee = 5 * 1e18;

        //when
        int256 virtualHedgingPosition = _iporSwapLogic.calculateVirtualHedgingPosition(
            swap,
            closingTimestamp,
            basePayoff,
            oppositeLegFixedRate,
            hedgingFee
        );

        //then
        assertEq(virtualHedgingPosition, 688150684931506849315);
    }

    function testShouldCalculateVirtualHedgingPositionElapsed10DaysPositivePnLOppositeLegRateEqual()
        public
    {
        // given
        IporTypes.IporSwapMemory memory swap;

        int256 basePayoff = 200 * 1e18;
        int256 oppositeLegFixedRate = 5 * 1e16;

        swap.notional = 500_000 * 1e18;
        swap.fixedInterestRate = 5 * 1e16;
        swap.openTimestamp = block.timestamp;
        swap.endTimestamp = swap.openTimestamp + 28 days;

        uint256 closingTimestamp = swap.openTimestamp + 10 days;

        uint256 hedgingFee = 5 * 1e18;

        //when
        int256 virtualHedgingPosition = _iporSwapLogic.calculateVirtualHedgingPosition(
            swap,
            closingTimestamp,
            basePayoff,
            oppositeLegFixedRate,
            hedgingFee
        );

        //then
        assertEq(virtualHedgingPosition, 195000000000000000000);
    }

    function testShouldCalculateVirtualHedgingPositionElapsed10DaysPositivePnLOppositeLegRateLower()
        public
    {
        // given
        IporTypes.IporSwapMemory memory swap;

        int256 basePayoff = 200 * 1e18;
        int256 oppositeLegFixedRate = 3 * 1e16;

        swap.notional = 500_000 * 1e18;
        swap.fixedInterestRate = 5 * 1e16;
        swap.openTimestamp = block.timestamp;
        swap.endTimestamp = swap.openTimestamp + 28 days;

        uint256 closingTimestamp = swap.openTimestamp + 10 days;

        uint256 hedgingFee = 5 * 1e18;

        //when
        int256 virtualHedgingPosition = _iporSwapLogic.calculateVirtualHedgingPosition(
            swap,
            closingTimestamp,
            basePayoff,
            oppositeLegFixedRate,
            hedgingFee
        );

        //then
        assertEq(virtualHedgingPosition, -298150684931506849314);
    }

    function testShouldCalculateVirtHedgPosElapsed10NegativePnLOppositeLegRateHigher() public {
        // given
        IporTypes.IporSwapMemory memory swap;

        int256 basePayoff = -200 * 1e18;
        int256 oppositeLegFixedRate = 5 * 1e16;

        swap.notional = 500_000 * 1e18;
        swap.fixedInterestRate = 3 * 1e16;
        swap.openTimestamp = block.timestamp;
        swap.endTimestamp = swap.openTimestamp + 28 days;

        uint256 closingTimestamp = swap.openTimestamp + 10 days;

        uint256 hedgingFee = 5 * 1e18;

        //when
        int256 virtualHedgingPosition = _iporSwapLogic.calculateVirtualHedgingPosition(
            swap,
            closingTimestamp,
            basePayoff,
            oppositeLegFixedRate,
            hedgingFee
        );

        //then
        assertEq(virtualHedgingPosition, 288150684931506849315);
    }

    function testShouldCalculateVirtHedgPositionElapsed10DaysNegativePnLOppositeLegRateEqual()
        public
    {
        // given
        IporTypes.IporSwapMemory memory swap;

        int256 basePayoff = -200 * 1e18;
        int256 oppositeLegFixedRate = 5 * 1e16;

        swap.notional = 500_000 * 1e18;
        swap.fixedInterestRate = 5 * 1e16;
        swap.openTimestamp = block.timestamp;
        swap.endTimestamp = swap.openTimestamp + 28 days;

        uint256 closingTimestamp = swap.openTimestamp + 10 days;

        uint256 hedgingFee = 5 * 1e18;

        //when
        int256 virtualHedgingPosition = _iporSwapLogic.calculateVirtualHedgingPosition(
            swap,
            closingTimestamp,
            basePayoff,
            oppositeLegFixedRate,
            hedgingFee
        );

        //then
        assertEq(virtualHedgingPosition, -205000000000000000000);
    }

    function testShouldCalculateVirtHedgPositionElapsed10DaysNegativePnLOppositeLegRateLower()
        public
    {
        // given
        IporTypes.IporSwapMemory memory swap;

        int256 basePayoff = -200 * 1e18;
        int256 oppositeLegFixedRate = 3 * 1e16;

        swap.notional = 500_000 * 1e18;
        swap.fixedInterestRate = 5 * 1e16;
        swap.openTimestamp = block.timestamp;
        swap.endTimestamp = swap.openTimestamp + 28 days;

        uint256 closingTimestamp = swap.openTimestamp + 10 days;

        uint256 hedgingFee = 5 * 1e18;

        //when
        int256 virtualHedgingPosition = _iporSwapLogic.calculateVirtualHedgingPosition(
            swap,
            closingTimestamp,
            basePayoff,
            oppositeLegFixedRate,
            hedgingFee
        );

        //then
        assertEq(virtualHedgingPosition, -698150684931506849314);
    }

    function testShouldCalculateVirtHedgPosElapsed10NegativePnLOppositeLegRateHigherFlatFeeZero()
        public
    {
        // given
        IporTypes.IporSwapMemory memory swap;

        int256 basePayoff = -200 * 1e18;
        int256 oppositeLegFixedRate = 5 * 1e16;

        swap.notional = 500_000 * 1e18;
        swap.fixedInterestRate = 3 * 1e16;
        swap.openTimestamp = block.timestamp;
        swap.endTimestamp = swap.openTimestamp + 28 days;

        uint256 closingTimestamp = swap.openTimestamp + 10 days;

        uint256 hedgingFee = 0;

        //when
        int256 virtualHedgingPosition = _iporSwapLogic.calculateVirtualHedgingPosition(
            swap,
            closingTimestamp,
            basePayoff,
            oppositeLegFixedRate,
            hedgingFee
        );

        //then
        assertEq(virtualHedgingPosition, 293150684931506849315);
    }

    function testShouldCalculateVirtHedgPositionElapsed10DaysNegativePnLOppositeLegRateEqualFlatFeeZero()
        public
    {
        // given
        IporTypes.IporSwapMemory memory swap;

        int256 basePayoff = -200 * 1e18;
        int256 oppositeLegFixedRate = 5 * 1e16;

        swap.notional = 500_000 * 1e18;
        swap.fixedInterestRate = 5 * 1e16;
        swap.openTimestamp = block.timestamp;
        swap.endTimestamp = swap.openTimestamp + 28 days;

        uint256 closingTimestamp = swap.openTimestamp + 10 days;

        uint256 hedgingFee = 0;

        //when
        int256 virtualHedgingPosition = _iporSwapLogic.calculateVirtualHedgingPosition(
            swap,
            closingTimestamp,
            basePayoff,
            oppositeLegFixedRate,
            hedgingFee
        );

        //then
        assertEq(virtualHedgingPosition, -200000000000000000000);
    }

    function testShouldCalculateVirtHedgPositionElapsed10DaysNegativePnLOppositeLegRateLowerFlatFeeZero()
        public
    {
        // given
        IporTypes.IporSwapMemory memory swap;

        int256 basePayoff = -200 * 1e18;
        int256 oppositeLegFixedRate = 3 * 1e16;

        swap.notional = 500_000 * 1e18;
        swap.fixedInterestRate = 5 * 1e16;
        swap.openTimestamp = block.timestamp;
        swap.endTimestamp = swap.openTimestamp + 28 days;

        uint256 closingTimestamp = swap.openTimestamp + 10 days;

        uint256 hedgingFee = 0;

        //when
        int256 virtualHedgingPosition = _iporSwapLogic.calculateVirtualHedgingPosition(
            swap,
            closingTimestamp,
            basePayoff,
            oppositeLegFixedRate,
            hedgingFee
        );

        //then
        assertEq(virtualHedgingPosition, -693150684931506849314);
    }

    function testShouldCalculateVirtualHedgingPositionElapsed10PositivePnLOppositeLegRateHigherFlatFeeZero()
        public
    {
        // given
        IporTypes.IporSwapMemory memory swap;

        int256 basePayoff = 200 * 1e18;
        int256 oppositeLegFixedRate = 5 * 1e16;

        swap.notional = 500_000 * 1e18;
        swap.fixedInterestRate = 3 * 1e16;
        swap.openTimestamp = block.timestamp;
        swap.endTimestamp = swap.openTimestamp + 28 days;

        uint256 closingTimestamp = swap.openTimestamp + 10 days;

        uint256 hedgingFee = 0;

        //when
        int256 virtualHedgingPosition = _iporSwapLogic.calculateVirtualHedgingPosition(
            swap,
            closingTimestamp,
            basePayoff,
            oppositeLegFixedRate,
            hedgingFee
        );

        //then
        assertEq(virtualHedgingPosition, 693150684931506849315);
    }

    function testShouldCalculateVirtualHedgingPositionElapsed10DaysPositivePnLOppositeLegRateEqualFlatFeeZero()
        public
    {
        // given
        IporTypes.IporSwapMemory memory swap;

        int256 basePayoff = 200 * 1e18;
        int256 oppositeLegFixedRate = 5 * 1e16;

        swap.notional = 500_000 * 1e18;
        swap.fixedInterestRate = 5 * 1e16;
        swap.openTimestamp = block.timestamp;
        swap.endTimestamp = swap.openTimestamp + 28 days;

        uint256 closingTimestamp = swap.openTimestamp + 10 days;

        uint256 hedgingFee = 0;

        //when
        int256 virtualHedgingPosition = _iporSwapLogic.calculateVirtualHedgingPosition(
            swap,
            closingTimestamp,
            basePayoff,
            oppositeLegFixedRate,
            hedgingFee
        );

        //then
        assertEq(virtualHedgingPosition, 200000000000000000000);
    }

    function testShouldCalculateVirtualHedgingPositionElapsed10DaysPositivePnLOppositeLegRateLowerFlatFeeZero()
        public
    {
        // given
        IporTypes.IporSwapMemory memory swap;

        int256 basePayoff = 200 * 1e18;
        int256 oppositeLegFixedRate = 3 * 1e16;

        swap.notional = 500_000 * 1e18;
        swap.fixedInterestRate = 5 * 1e16;
        swap.openTimestamp = block.timestamp;
        swap.endTimestamp = swap.openTimestamp + 28 days;

        uint256 closingTimestamp = swap.openTimestamp + 10 days;

        uint256 hedgingFee = 0;

        //when
        int256 virtualHedgingPosition = _iporSwapLogic.calculateVirtualHedgingPosition(
            swap,
            closingTimestamp,
            basePayoff,
            oppositeLegFixedRate,
            hedgingFee
        );

        //then
        assertEq(virtualHedgingPosition, -293150684931506849314);
    }

    function testShouldCalculateVirtualHedgingPositionElapsed10PnLZeroOppositeLegRateHigher()
        public
    {
        // given
        IporTypes.IporSwapMemory memory swap;

        int256 basePayoff = 0;
        int256 oppositeLegFixedRate = 5 * 1e16;

        swap.notional = 500_000 * 1e18;
        swap.fixedInterestRate = 3 * 1e16;
        swap.openTimestamp = block.timestamp;
        swap.endTimestamp = swap.openTimestamp + 28 days;

        uint256 closingTimestamp = swap.openTimestamp + 10 days;

        uint256 hedgingFee = 5 * 1e18;

        //when
        int256 virtualHedgingPosition = _iporSwapLogic.calculateVirtualHedgingPosition(
            swap,
            closingTimestamp,
            basePayoff,
            oppositeLegFixedRate,
            hedgingFee
        );

        //then
        assertEq(virtualHedgingPosition, 488150684931506849315);
    }

    function testShouldCalculateVirtualHedgingPositionElapsed10DaysPnLZeroOppositeLegRateEqual()
        public
    {
        // given
        IporTypes.IporSwapMemory memory swap;

        int256 basePayoff = 0;
        int256 oppositeLegFixedRate = 5 * 1e16;

        swap.notional = 500_000 * 1e18;
        swap.fixedInterestRate = 5 * 1e16;
        swap.openTimestamp = block.timestamp;
        swap.endTimestamp = swap.openTimestamp + 28 days;

        uint256 closingTimestamp = swap.openTimestamp + 10 days;

        uint256 hedgingFee = 5 * 1e18;

        //when
        int256 virtualHedgingPosition = _iporSwapLogic.calculateVirtualHedgingPosition(
            swap,
            closingTimestamp,
            basePayoff,
            oppositeLegFixedRate,
            hedgingFee
        );

        //then
        assertEq(virtualHedgingPosition, -5000000000000000000);
    }

    function testShouldCalculateVirtualHedgingPositionElapsed10DaysPnLZeroOppositeLegRateLower()
        public
    {
        // given
        IporTypes.IporSwapMemory memory swap;

        int256 basePayoff = 0;
        int256 oppositeLegFixedRate = 3 * 1e16;

        swap.notional = 500_000 * 1e18;
        swap.fixedInterestRate = 5 * 1e16;
        swap.openTimestamp = block.timestamp;
        swap.endTimestamp = swap.openTimestamp + 28 days;

        uint256 closingTimestamp = swap.openTimestamp + 10 days;

        uint256 hedgingFee = 5 * 1e18;

        //when
        int256 virtualHedgingPosition = _iporSwapLogic.calculateVirtualHedgingPosition(
            swap,
            closingTimestamp,
            basePayoff,
            oppositeLegFixedRate,
            hedgingFee
        );

        //then
        assertEq(virtualHedgingPosition, -498150684931506849314);
    }

    function testShouldCalculateVirtualHedgingPositionElapsed10PnLZeroOppositeLegRateHigherFlatFeeZero()
        public
    {
        // given
        IporTypes.IporSwapMemory memory swap;

        int256 basePayoff = 0;
        int256 oppositeLegFixedRate = 5 * 1e16;

        swap.notional = 500_000 * 1e18;
        swap.fixedInterestRate = 3 * 1e16;
        swap.openTimestamp = block.timestamp;
        swap.endTimestamp = swap.openTimestamp + 28 days;

        uint256 closingTimestamp = swap.openTimestamp + 10 days;

        uint256 hedgingFee = 0;

        //when
        int256 virtualHedgingPosition = _iporSwapLogic.calculateVirtualHedgingPosition(
            swap,
            closingTimestamp,
            basePayoff,
            oppositeLegFixedRate,
            hedgingFee
        );

        //then
        assertEq(virtualHedgingPosition, 493150684931506849315);
    }

    function testShouldCalculateVirtualHedgingPositionElapsed10DaysPnLZeroOppositeLegRateEqualFlatFeeZero()
        public
    {
        // given
        IporTypes.IporSwapMemory memory swap;

        int256 basePayoff = 0;
        int256 oppositeLegFixedRate = 5 * 1e16;

        swap.notional = 500_000 * 1e18;
        swap.fixedInterestRate = 5 * 1e16;
        swap.openTimestamp = block.timestamp;
        swap.endTimestamp = swap.openTimestamp + 28 days;

        uint256 closingTimestamp = swap.openTimestamp + 10 days;

        uint256 hedgingFee = 0;

        //when
        int256 virtualHedgingPosition = _iporSwapLogic.calculateVirtualHedgingPosition(
            swap,
            closingTimestamp,
            basePayoff,
            oppositeLegFixedRate,
            hedgingFee
        );

        //then
        assertEq(virtualHedgingPosition, 0);
    }

    function testShouldCalculateVirtualHedgingPositionElapsed10DaysPnLZeroOppositeLegRateLowerFlatFeeZero()
        public
    {
        // given
        IporTypes.IporSwapMemory memory swap;

        int256 basePayoff = 0;
        int256 oppositeLegFixedRate = 3 * 1e16;

        swap.notional = 500_000 * 1e18;
        swap.fixedInterestRate = 5 * 1e16;
        swap.openTimestamp = block.timestamp;
        swap.endTimestamp = swap.openTimestamp + 28 days;

        uint256 closingTimestamp = swap.openTimestamp + 10 days;

        uint256 hedgingFee = 0;

        //when
        int256 virtualHedgingPosition = _iporSwapLogic.calculateVirtualHedgingPosition(
            swap,
            closingTimestamp,
            basePayoff,
            oppositeLegFixedRate,
            hedgingFee
        );

        //then
        assertEq(virtualHedgingPosition, -493150684931506849314);
    }

    function testShouldCalculateVirtualHedgingPositionElapsed10PnL200PayFixedZero() public {
        // given
        IporTypes.IporSwapMemory memory swap;

        int256 basePayoff = 200 * 1e18;
        int256 oppositeLegFixedRate = 5 * 1e16;

        swap.notional = 500_000 * 1e18;
        swap.fixedInterestRate = 0;
        swap.openTimestamp = block.timestamp;
        swap.endTimestamp = swap.openTimestamp + 28 days;

        uint256 closingTimestamp = swap.openTimestamp + 10 days;

        uint256 hedgingFee = 5 * 1e18;

        //when
        int256 virtualHedgingPosition = _iporSwapLogic.calculateVirtualHedgingPosition(
            swap,
            closingTimestamp,
            basePayoff,
            oppositeLegFixedRate,
            hedgingFee
        );

        //then
        assertEq(virtualHedgingPosition, 1427876712328767123288);
    }

    function testShouldCalculateVirtualHedgingPositionElapsed10PnL200OppositeLegZero() public {
        // given
        IporTypes.IporSwapMemory memory swap;

        int256 basePayoff = 200 * 1e18;
        int256 oppositeLegFixedRate = 0;

        swap.notional = 500_000 * 1e18;
        swap.fixedInterestRate = 5 * 1e16;
        swap.openTimestamp = block.timestamp;
        swap.endTimestamp = swap.openTimestamp + 28 days;

        uint256 closingTimestamp = swap.openTimestamp + 10 days;

        uint256 hedgingFee = 5 * 1e18;

        //when
        int256 virtualHedgingPosition = _iporSwapLogic.calculateVirtualHedgingPosition(
            swap,
            closingTimestamp,
            basePayoff,
            oppositeLegFixedRate,
            hedgingFee
        );

        //then
        assertEq(virtualHedgingPosition, -1037876712328767123287);
    }

    function testShouldCalculateVirtualHedgingPositionElapsed10PnLNegative200PayFixedZero() public {
        // given
        IporTypes.IporSwapMemory memory swap;

        int256 basePayoff = -200 * 1e18;
        int256 oppositeLegFixedRate = 5 * 1e16;

        swap.notional = 500_000 * 1e18;
        swap.fixedInterestRate = 0;
        swap.openTimestamp = block.timestamp;
        swap.endTimestamp = swap.openTimestamp + 28 days;

        uint256 closingTimestamp = swap.openTimestamp + 10 days;

        uint256 hedgingFee = 5 * 1e18;

        //when
        int256 virtualHedgingPosition = _iporSwapLogic.calculateVirtualHedgingPosition(
            swap,
            closingTimestamp,
            basePayoff,
            oppositeLegFixedRate,
            hedgingFee
        );

        //then
        assertEq(virtualHedgingPosition, 1027876712328767123288);
    }

    function testShouldCalculateVirtualHedgingPositionElapsed10PnLNegative200OppositeLegZero()
        public
    {
        // given
        IporTypes.IporSwapMemory memory swap;

        int256 basePayoff = -200 * 1e18;
        int256 oppositeLegFixedRate = 0;

        swap.notional = 500_000 * 1e18;
        swap.fixedInterestRate = 5 * 1e16;
        swap.openTimestamp = block.timestamp;
        swap.endTimestamp = swap.openTimestamp + 28 days;

        uint256 closingTimestamp = swap.openTimestamp + 10 days;

        uint256 hedgingFee = 5 * 1e18;

        //when
        int256 virtualHedgingPosition = _iporSwapLogic.calculateVirtualHedgingPosition(
            swap,
            closingTimestamp,
            basePayoff,
            oppositeLegFixedRate,
            hedgingFee
        );

        //then
        assertEq(virtualHedgingPosition, -1437876712328767123287);
    }

    function testShouldCalculateVirtHedgPosPnLZeroClosingInDayWhenOpenedOppositeLegHigher() public {
        // given
        IporTypes.IporSwapMemory memory swap;

        int256 basePayoff = 0;
        int256 oppositeLegFixedRate = 5 * 1e16;

        swap.notional = 500_000 * 1e18;
        swap.fixedInterestRate = 3 * 1e16;
        swap.openTimestamp = block.timestamp;
        swap.endTimestamp = swap.openTimestamp + 28 days;

        uint256 closingTimestamp = swap.openTimestamp;

        uint256 hedgingFee = 5 * 1e18;

        //when
        int256 virtualHedgingPosition = _iporSwapLogic.calculateVirtualHedgingPosition(
            swap,
            closingTimestamp,
            basePayoff,
            oppositeLegFixedRate,
            hedgingFee
        );

        //then
        assertEq(virtualHedgingPosition, 762123287671232876712);
    }

    function testShouldCalculateVirtHedgPosPnLZeroClosingInDayWhenOpenedOppositeLegEqual() public {
        // given
        IporTypes.IporSwapMemory memory swap;

        int256 basePayoff = 0;
        int256 oppositeLegFixedRate = 5 * 1e16;

        swap.notional = 500_000 * 1e18;
        swap.fixedInterestRate = 5 * 1e16;
        swap.openTimestamp = block.timestamp;
        swap.endTimestamp = swap.openTimestamp + 28 days;

        uint256 closingTimestamp = swap.openTimestamp;

        uint256 hedgingFee = 5 * 1e18;

        //when
        int256 virtualHedgingPosition = _iporSwapLogic.calculateVirtualHedgingPosition(
            swap,
            closingTimestamp,
            basePayoff,
            oppositeLegFixedRate,
            hedgingFee
        );

        //then
        assertEq(virtualHedgingPosition, -5000000000000000000);
    }

    function testShouldCalculateVirtHedgPosPnLZeroClosingInDayWhenOpenedOppositeLegLower() public {
        // given
        IporTypes.IporSwapMemory memory swap;

        int256 basePayoff = 0;
        int256 oppositeLegFixedRate = 3 * 1e16;

        swap.notional = 500_000 * 1e18;
        swap.fixedInterestRate = 5 * 1e16;
        swap.openTimestamp = block.timestamp;
        swap.endTimestamp = swap.openTimestamp + 28 days;

        uint256 closingTimestamp = swap.openTimestamp;

        uint256 hedgingFee = 5 * 1e18;

        //when
        int256 virtualHedgingPosition = _iporSwapLogic.calculateVirtualHedgingPosition(
            swap,
            closingTimestamp,
            basePayoff,
            oppositeLegFixedRate,
            hedgingFee
        );

        //then
        assertEq(virtualHedgingPosition, -772123287671232876711);
    }

    function testShouldCalculateVirtHedgPosPnL200ClosingInDayWhenOpenedOppositeLegHigher() public {
        // given
        IporTypes.IporSwapMemory memory swap;

        int256 basePayoff = 200 * 1e18;
        int256 oppositeLegFixedRate = 5 * 1e16;

        swap.notional = 500_000 * 1e18;
        swap.fixedInterestRate = 3 * 1e16;
        swap.openTimestamp = block.timestamp;
        swap.endTimestamp = swap.openTimestamp + 28 days;

        uint256 closingTimestamp = swap.openTimestamp;

        uint256 hedgingFee = 5 * 1e18;

        //when
        int256 virtualHedgingPosition = _iporSwapLogic.calculateVirtualHedgingPosition(
            swap,
            closingTimestamp,
            basePayoff,
            oppositeLegFixedRate,
            hedgingFee
        );

        //then
        assertEq(virtualHedgingPosition, 962123287671232876712);
    }

    function testShouldCalculateVirtHedgPosPnL200ClosingInDayWhenOpenedOppositeLegEqual() public {
        // given
        IporTypes.IporSwapMemory memory swap;

        int256 basePayoff = 200 * 1e18;
        int256 oppositeLegFixedRate = 5 * 1e16;

        swap.notional = 500_000 * 1e18;
        swap.fixedInterestRate = 5 * 1e16;
        swap.openTimestamp = block.timestamp;
        swap.endTimestamp = swap.openTimestamp + 28 days;

        uint256 closingTimestamp = swap.openTimestamp;

        uint256 hedgingFee = 5 * 1e18;

        //when
        int256 virtualHedgingPosition = _iporSwapLogic.calculateVirtualHedgingPosition(
            swap,
            closingTimestamp,
            basePayoff,
            oppositeLegFixedRate,
            hedgingFee
        );

        //then
        assertEq(virtualHedgingPosition, 195000000000000000000);
    }

    function testShouldCalculateVirtHedgPosPnL200ClosingInDayWhenOpenedOppositeLegLower() public {
        // given
        IporTypes.IporSwapMemory memory swap;

        int256 basePayoff = 200 * 1e18;
        int256 oppositeLegFixedRate = 3 * 1e16;

        swap.notional = 500_000 * 1e18;
        swap.fixedInterestRate = 5 * 1e16;
        swap.openTimestamp = block.timestamp;
        swap.endTimestamp = swap.openTimestamp + 28 days;

        uint256 closingTimestamp = swap.openTimestamp;

        uint256 hedgingFee = 5 * 1e18;

        //when
        int256 virtualHedgingPosition = _iporSwapLogic.calculateVirtualHedgingPosition(
            swap,
            closingTimestamp,
            basePayoff,
            oppositeLegFixedRate,
            hedgingFee
        );

        //then
        assertEq(virtualHedgingPosition, -572123287671232876711);
    }

    function testShouldCalculateVirtHedgPosPnLZeroClosingInDayWhenOpenedLegEqualZero() public {
        // given
        IporTypes.IporSwapMemory memory swap;

        int256 basePayoff = 0;
        int256 oppositeLegFixedRate = 5 * 1e16;

        swap.notional = 500_000 * 1e18;
        swap.fixedInterestRate = 0;
        swap.openTimestamp = block.timestamp;
        swap.endTimestamp = swap.openTimestamp + 28 days;

        uint256 closingTimestamp = swap.openTimestamp;

        uint256 hedgingFee = 5 * 1e18;

        //when
        int256 virtualHedgingPosition = _iporSwapLogic.calculateVirtualHedgingPosition(
            swap,
            closingTimestamp,
            basePayoff,
            oppositeLegFixedRate,
            hedgingFee
        );

        //then
        assertEq(virtualHedgingPosition, 1912808219178082191781);
    }

    function testShouldCalculateVirtHedgPosPnLZeroClosingInDayWhenOpenedOppositeLegEqualZero()
        public
    {
        // given
        IporTypes.IporSwapMemory memory swap;

        int256 basePayoff = 0;
        int256 oppositeLegFixedRate = 0;

        swap.notional = 500_000 * 1e18;
        swap.fixedInterestRate = 5 * 1e16;
        swap.openTimestamp = block.timestamp;
        swap.endTimestamp = swap.openTimestamp + 28 days;

        uint256 closingTimestamp = swap.openTimestamp;

        uint256 hedgingFee = 5 * 1e18;

        //when
        int256 virtualHedgingPosition = _iporSwapLogic.calculateVirtualHedgingPosition(
            swap,
            closingTimestamp,
            basePayoff,
            oppositeLegFixedRate,
            hedgingFee
        );

        //then
        assertEq(virtualHedgingPosition, -1922808219178082191780);
    }

    function testShouldCalculateVirtHedgPosPnLZeroClosingInDayWhenOpenedBothLegZero() public {
        // given
        IporTypes.IporSwapMemory memory swap;

        int256 basePayoff = 0;
        int256 oppositeLegFixedRate = 0;

        swap.notional = 500_000 * 1e18;
        swap.fixedInterestRate = 0;
        swap.openTimestamp = block.timestamp;
        swap.endTimestamp = swap.openTimestamp + 28 days;

        uint256 closingTimestamp = swap.openTimestamp;

        uint256 hedgingFee = 5 * 1e18;

        //when
        int256 virtualHedgingPosition = _iporSwapLogic.calculateVirtualHedgingPosition(
            swap,
            closingTimestamp,
            basePayoff,
            oppositeLegFixedRate,
            hedgingFee
        );

        //then
        assertEq(virtualHedgingPosition, -5000000000000000000);
    }

    function testShouldCalculateVirtHedgPosMaturityPnL200OppositeLegHigher() public {
        // given
        IporTypes.IporSwapMemory memory swap;

        int256 basePayoff = 200 * 1e18;
        int256 oppositeLegFixedRate = 5 * 1e16;

        swap.notional = 500_000 * 1e18;
        swap.fixedInterestRate = 3 * 1e16;
        swap.openTimestamp = block.timestamp;
        swap.endTimestamp = swap.openTimestamp + 28 days;

        uint256 closingTimestamp = swap.endTimestamp;

        uint256 hedgingFee = 5 * 1e18;

        //when
        int256 virtualHedgingPosition = _iporSwapLogic.calculateVirtualHedgingPosition(
            swap,
            closingTimestamp,
            basePayoff,
            oppositeLegFixedRate,
            hedgingFee
        );

        //then
        assertEq(virtualHedgingPosition, 195000000000000000000);
    }

    function testShouldCalculateVirtHedgPosMaturityPnL200OppositeLegEqual() public {
        // given
        IporTypes.IporSwapMemory memory swap;

        int256 basePayoff = 200 * 1e18;
        int256 oppositeLegFixedRate = 5 * 1e16;

        swap.notional = 500_000 * 1e18;
        swap.fixedInterestRate = 5 * 1e16;
        swap.openTimestamp = block.timestamp;
        swap.endTimestamp = swap.openTimestamp + 28 days;

        uint256 closingTimestamp = swap.endTimestamp;

        uint256 hedgingFee = 5 * 1e18;

        //when
        int256 virtualHedgingPosition = _iporSwapLogic.calculateVirtualHedgingPosition(
            swap,
            closingTimestamp,
            basePayoff,
            oppositeLegFixedRate,
            hedgingFee
        );

        //then
        assertEq(virtualHedgingPosition, 195000000000000000000);
    }

    function testShouldCalculateVirtHedgPosMaturityPnL200OppositeLegLower() public {
        // given
        IporTypes.IporSwapMemory memory swap;

        int256 basePayoff = 200 * 1e18;
        int256 oppositeLegFixedRate = 3 * 1e16;

        swap.notional = 500_000 * 1e18;
        swap.fixedInterestRate = 5 * 1e16;
        swap.openTimestamp = block.timestamp;
        swap.endTimestamp = swap.openTimestamp + 28 days;

        uint256 closingTimestamp = swap.endTimestamp;

        uint256 hedgingFee = 5 * 1e18;

        //when
        int256 virtualHedgingPosition = _iporSwapLogic.calculateVirtualHedgingPosition(
            swap,
            closingTimestamp,
            basePayoff,
            oppositeLegFixedRate,
            hedgingFee
        );

        //then
        assertEq(virtualHedgingPosition, 195000000000000000000);
    }

    function testShouldCalculateVirtHedgPosMaturityPnL200MinusOppositeLegHigher() public {
        // given
        IporTypes.IporSwapMemory memory swap;

        int256 basePayoff = -200 * 1e18;
        int256 oppositeLegFixedRate = 5 * 1e16;

        swap.notional = 500_000 * 1e18;
        swap.fixedInterestRate = 3 * 1e16;
        swap.openTimestamp = block.timestamp;
        swap.endTimestamp = swap.openTimestamp + 28 days;

        uint256 closingTimestamp = swap.endTimestamp;

        uint256 hedgingFee = 5 * 1e18;

        //when
        int256 virtualHedgingPosition = _iporSwapLogic.calculateVirtualHedgingPosition(
            swap,
            closingTimestamp,
            basePayoff,
            oppositeLegFixedRate,
            hedgingFee
        );

        //then
        assertEq(virtualHedgingPosition, -205000000000000000000);
    }

    function testShouldCalculateVirtHedgPosMaturityPnL200MinusOppositeLegEqual() public {
        // given
        IporTypes.IporSwapMemory memory swap;

        int256 basePayoff = -200 * 1e18;
        int256 oppositeLegFixedRate = 5 * 1e16;

        swap.notional = 500_000 * 1e18;
        swap.fixedInterestRate = 5 * 1e16;
        swap.openTimestamp = block.timestamp;
        swap.endTimestamp = swap.openTimestamp + 28 days;

        uint256 closingTimestamp = swap.endTimestamp;

        uint256 hedgingFee = 5 * 1e18;

        //when
        int256 virtualHedgingPosition = _iporSwapLogic.calculateVirtualHedgingPosition(
            swap,
            closingTimestamp,
            basePayoff,
            oppositeLegFixedRate,
            hedgingFee
        );

        //then
        assertEq(virtualHedgingPosition, -205000000000000000000);
    }

    function testShouldCalculateVirtHedgPosMaturityPnL200MinusOppositeLegLower() public {
        // given
        IporTypes.IporSwapMemory memory swap;

        int256 basePayoff = -200 * 1e18;
        int256 oppositeLegFixedRate = 3 * 1e16;

        swap.notional = 500_000 * 1e18;
        swap.fixedInterestRate = 5 * 1e16;
        swap.openTimestamp = block.timestamp;
        swap.endTimestamp = swap.openTimestamp + 28 days;

        uint256 closingTimestamp = swap.endTimestamp;

        uint256 hedgingFee = 5 * 1e18;

        //when
        int256 virtualHedgingPosition = _iporSwapLogic.calculateVirtualHedgingPosition(
            swap,
            closingTimestamp,
            basePayoff,
            oppositeLegFixedRate,
            hedgingFee
        );

        //then
        assertEq(virtualHedgingPosition, -205000000000000000000);
    }

    function testShouldCalculateVirtHedgPosAfterMaturityPnL200OppositeLegHigher() public {
        // given
        IporTypes.IporSwapMemory memory swap;

        int256 basePayoff = 200 * 1e18;
        int256 oppositeLegFixedRate = 5 * 1e16;

        swap.notional = 500_000 * 1e18;
        swap.fixedInterestRate = 3 * 1e16;
        swap.openTimestamp = block.timestamp;
        swap.endTimestamp = swap.openTimestamp + 28 days;

        uint256 closingTimestamp = swap.endTimestamp + 2 days;

        uint256 hedgingFee = 5 * 1e18;

        //when
        vm.expectRevert(bytes(MiltonErrors.CANNOT_UNWIND_CLOSING_TOO_LATE));
        int256 virtualHedgingPosition = _iporSwapLogic.calculateVirtualHedgingPosition(
            swap,
            closingTimestamp,
            basePayoff,
            oppositeLegFixedRate,
            hedgingFee
        );

        //then
        assertEq(virtualHedgingPosition, 0);
    }

    function testShouldCalculateVirtHedgPosAfterMaturityPnL200OppositeLegEqual() public {
        // given
        IporTypes.IporSwapMemory memory swap;

        int256 basePayoff = 200 * 1e18;
        int256 oppositeLegFixedRate = 5 * 1e16;

        swap.notional = 500_000 * 1e18;
        swap.fixedInterestRate = 5 * 1e16;
        swap.openTimestamp = block.timestamp;
        swap.endTimestamp = swap.openTimestamp + 28 days;

        uint256 closingTimestamp = swap.endTimestamp + 2 days;

        uint256 hedgingFee = 5 * 1e18;

        //when
        vm.expectRevert(bytes(MiltonErrors.CANNOT_UNWIND_CLOSING_TOO_LATE));
        int256 virtualHedgingPosition = _iporSwapLogic.calculateVirtualHedgingPosition(
            swap,
            closingTimestamp,
            basePayoff,
            oppositeLegFixedRate,
            hedgingFee
        );

        //then
        assertEq(virtualHedgingPosition, 0);
    }

    function testShouldCalculateVirtHedgPosAterMaturityPnL200OppositeLegLower() public {
        // given
        IporTypes.IporSwapMemory memory swap;

        int256 basePayoff = 200 * 1e18;
        int256 oppositeLegFixedRate = 3 * 1e16;

        swap.notional = 500_000 * 1e18;
        swap.fixedInterestRate = 5 * 1e16;
        swap.openTimestamp = block.timestamp;
        swap.endTimestamp = swap.openTimestamp + 28 days;

        uint256 closingTimestamp = swap.endTimestamp + 2 days;

        uint256 hedgingFee = 5 * 1e18;

        //when
        vm.expectRevert(bytes(MiltonErrors.CANNOT_UNWIND_CLOSING_TOO_LATE));
        int256 virtualHedgingPosition = _iporSwapLogic.calculateVirtualHedgingPosition(
            swap,
            closingTimestamp,
            basePayoff,
            oppositeLegFixedRate,
            hedgingFee
        );

        //then
        assertEq(virtualHedgingPosition, 0);
    }

    function testShouldCalculateVirtHedgPosAfterMaturityPnL200MinusOppositeLegHigher() public {
        // given
        IporTypes.IporSwapMemory memory swap;

        int256 basePayoff = -200 * 1e18;
        int256 oppositeLegFixedRate = 5 * 1e16;

        swap.notional = 500_000 * 1e18;
        swap.fixedInterestRate = 3 * 1e16;
        swap.openTimestamp = block.timestamp;
        swap.endTimestamp = swap.openTimestamp + 28 days;

        uint256 closingTimestamp = swap.endTimestamp + 2 days;

        uint256 hedgingFee = 5 * 1e18;

        //when
        vm.expectRevert(bytes(MiltonErrors.CANNOT_UNWIND_CLOSING_TOO_LATE));
        int256 virtualHedgingPosition = _iporSwapLogic.calculateVirtualHedgingPosition(
            swap,
            closingTimestamp,
            basePayoff,
            oppositeLegFixedRate,
            hedgingFee
        );

        //then
        assertEq(virtualHedgingPosition, 0);
    }

    function testShouldCalculateVirtHedgPosAfterMaturityPnL200MinusOppositeLegEqual() public {
        // given
        IporTypes.IporSwapMemory memory swap;

        int256 basePayoff = -200 * 1e18;
        int256 oppositeLegFixedRate = 5 * 1e16;

        swap.notional = 500_000 * 1e18;
        swap.fixedInterestRate = 5 * 1e16;
        swap.openTimestamp = block.timestamp;
        swap.endTimestamp = swap.openTimestamp + 28 days;

        uint256 closingTimestamp = swap.endTimestamp + 2 days;

        uint256 hedgingFee = 5 * 1e18;

        //when
        vm.expectRevert(bytes(MiltonErrors.CANNOT_UNWIND_CLOSING_TOO_LATE));
        int256 virtualHedgingPosition = _iporSwapLogic.calculateVirtualHedgingPosition(
            swap,
            closingTimestamp,
            basePayoff,
            oppositeLegFixedRate,
            hedgingFee
        );

        //then
        assertEq(virtualHedgingPosition, 0);
    }

    function testShouldCalculateVirtHedgPosAfterMaturityPnL200MinusOppositeLegLower() public {
        // given
        IporTypes.IporSwapMemory memory swap;

        int256 basePayoff = -200 * 1e18;
        int256 oppositeLegFixedRate = 3 * 1e16;

        swap.notional = 500_000 * 1e18;
        swap.fixedInterestRate = 5 * 1e16;
        swap.openTimestamp = block.timestamp;
        swap.endTimestamp = swap.openTimestamp + 28 days;

        uint256 closingTimestamp = swap.endTimestamp + 2 days;

        uint256 hedgingFee = 5 * 1e18;

        //when
        vm.expectRevert(bytes(MiltonErrors.CANNOT_UNWIND_CLOSING_TOO_LATE));
        int256 virtualHedgingPosition = _iporSwapLogic.calculateVirtualHedgingPosition(
            swap,
            closingTimestamp,
            basePayoff,
            oppositeLegFixedRate,
            hedgingFee
        );

        //then
        assertEq(virtualHedgingPosition, 0);
    }
}

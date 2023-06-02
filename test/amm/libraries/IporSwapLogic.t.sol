// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.20;

import "forge-std/Test.sol";
import {DataUtils} from "../../utils/DataUtils.sol";
import "contracts/mocks/MockIporSwapLogic.sol";

contract IporSwapLogicTest is Test, DataUtils {
    MockIporSwapLogic internal _iporSwapLogic;

    function setUp() public {
        _iporSwapLogic = new MockIporSwapLogic();
    }

    function testShouldCalculateVirtualHedgingSwapElapsed10PositivePnLOppositeLegRateHigher()
        public
    {
        // given
        AmmTypes.Swap memory swap;

        int256 basePayoff = 200 * 1e18;
        uint256 oppositeLegFixedRate = 5 * 1e16;

        swap.notional = 500_000 * 1e18;
        swap.fixedInterestRate = 3 * 1e16;
        swap.openTimestamp = block.timestamp;
        swap.tenor = IporTypes.SwapTenor.DAYS_28;

        uint256 closingTimestamp = swap.openTimestamp + 10 days;

        uint256 hedgingFee = 5 * 1e18;

        //when
        int256 virtualHedgingSwap = _iporSwapLogic.calculateSwapUnwindValue(
            swap,
            closingTimestamp,
            basePayoff,
            oppositeLegFixedRate,
            hedgingFee
        );

        //then
        assertEq(virtualHedgingSwap, 688393962504649529356);
    }

    function testShouldCalculateVirtualHedgingSwapElapsed10DaysPositivePnLOppositeLegRateEqual()
        public
    {
        // given
        AmmTypes.Swap memory swap;

        int256 basePayoff = 200 * 1e18;
        uint256 oppositeLegFixedRate = 5 * 1e16;

        swap.notional = 500_000 * 1e18;
        swap.fixedInterestRate = 5 * 1e16;
        swap.openTimestamp = block.timestamp;
        swap.tenor = IporTypes.SwapTenor.DAYS_28;

        uint256 closingTimestamp = swap.openTimestamp + 10 days;

        uint256 hedgingFee = 5 * 1e18;

        //when
        int256 virtualHedgingSwap = _iporSwapLogic.calculateSwapUnwindValue(
            swap,
            closingTimestamp,
            basePayoff,
            oppositeLegFixedRate,
            hedgingFee
        );

        //then
        assertEq(virtualHedgingSwap, 195000000000000000000);
    }

    function testShouldCalculateVirtualHedgingSwapElapsed10DaysPositivePnLOppositeLegRateLower()
        public
    {
        // given
        AmmTypes.Swap memory swap;

        int256 basePayoff = 200 * 1e18;
        uint256 oppositeLegFixedRate = 3 * 1e16;

        swap.notional = 500_000 * 1e18;
        swap.fixedInterestRate = 5 * 1e16;
        swap.openTimestamp = block.timestamp;
        swap.tenor = IporTypes.SwapTenor.DAYS_28;

        uint256 closingTimestamp = swap.openTimestamp + 10 days;

        uint256 hedgingFee = 5 * 1e18;

        //when
        int256 virtualHedgingSwap = _iporSwapLogic.calculateSwapUnwindValue(
            swap,
            closingTimestamp,
            basePayoff,
            oppositeLegFixedRate,
            hedgingFee
        );

        //then
        assertEq(virtualHedgingSwap, -297907567269122150817);
    }

    function testShouldCalculateVirtHedgPosElapsed10NegativePnLOppositeLegRateHigher() public {
        // given
        AmmTypes.Swap memory swap;

        int256 basePayoff = -200 * 1e18;
        uint256 oppositeLegFixedRate = 5 * 1e16;

        swap.notional = 500_000 * 1e18;
        swap.fixedInterestRate = 3 * 1e16;
        swap.openTimestamp = block.timestamp;
        swap.tenor = IporTypes.SwapTenor.DAYS_28;

        uint256 closingTimestamp = swap.openTimestamp + 10 days;

        uint256 hedgingFee = 5 * 1e18;

        //when
        int256 virtualHedgingSwap = _iporSwapLogic.calculateSwapUnwindValue(
            swap,
            closingTimestamp,
            basePayoff,
            oppositeLegFixedRate,
            hedgingFee
        );

        //then
        assertEq(virtualHedgingSwap, 288393962504649529356);
    }

    function testShouldCalculateVirtHedgPositionElapsed10DaysNegativePnLOppositeLegRateEqual()
        public
    {
        // given
        AmmTypes.Swap memory swap;

        int256 basePayoff = -200 * 1e18;
        uint256 oppositeLegFixedRate = 5 * 1e16;

        swap.notional = 500_000 * 1e18;
        swap.fixedInterestRate = 5 * 1e16;
        swap.openTimestamp = block.timestamp;
        swap.tenor = IporTypes.SwapTenor.DAYS_28;

        uint256 closingTimestamp = swap.openTimestamp + 10 days;

        uint256 hedgingFee = 5 * 1e18;

        //when
        int256 virtualHedgingSwap = _iporSwapLogic.calculateSwapUnwindValue(
            swap,
            closingTimestamp,
            basePayoff,
            oppositeLegFixedRate,
            hedgingFee
        );

        //then
        assertEq(virtualHedgingSwap, -205000000000000000000);
    }

    function testShouldCalculateVirtHedgPositionElapsed10DaysNegativePnLOppositeLegRateLower()
        public
    {
        // given
        AmmTypes.Swap memory swap;

        int256 basePayoff = -200 * 1e18;
        uint256 oppositeLegFixedRate = 3 * 1e16;

        swap.notional = 500_000 * 1e18;
        swap.fixedInterestRate = 5 * 1e16;
        swap.openTimestamp = block.timestamp;
        swap.tenor = IporTypes.SwapTenor.DAYS_28;

        uint256 closingTimestamp = swap.openTimestamp + 10 days;

        uint256 hedgingFee = 5 * 1e18;

        //when
        int256 virtualHedgingSwap = _iporSwapLogic.calculateSwapUnwindValue(
            swap,
            closingTimestamp,
            basePayoff,
            oppositeLegFixedRate,
            hedgingFee
        );

        //then
        assertEq(virtualHedgingSwap, -697907567269122150817);
    }

    function testShouldCalculateVirtHedgPosElapsed10NegativePnLOppositeLegRateHigherFlatFeeZero()
        public
    {
        // given
        AmmTypes.Swap memory swap;

        int256 basePayoff = -200 * 1e18;
        uint256 oppositeLegFixedRate = 5 * 1e16;

        swap.notional = 500_000 * 1e18;
        swap.fixedInterestRate = 3 * 1e16;
        swap.openTimestamp = block.timestamp;
        swap.tenor = IporTypes.SwapTenor.DAYS_28;

        uint256 closingTimestamp = swap.openTimestamp + 10 days;

        uint256 hedgingFee = 0;

        //when
        int256 virtualHedgingSwap = _iporSwapLogic.calculateSwapUnwindValue(
            swap,
            closingTimestamp,
            basePayoff,
            oppositeLegFixedRate,
            hedgingFee
        );

        //then
        assertEq(virtualHedgingSwap, 293393962504649529356);
    }

    function testShouldCalculateVirtHedgPositionElapsed10DaysNegativePnLOppositeLegRateEqualFlatFeeZero()
        public
    {
        // given
        AmmTypes.Swap memory swap;

        int256 basePayoff = -200 * 1e18;
        uint256 oppositeLegFixedRate = 5 * 1e16;

        swap.notional = 500_000 * 1e18;
        swap.fixedInterestRate = 5 * 1e16;
        swap.openTimestamp = block.timestamp;
        swap.tenor = IporTypes.SwapTenor.DAYS_28;

        uint256 closingTimestamp = swap.openTimestamp + 10 days;

        uint256 hedgingFee = 0;

        //when
        int256 virtualHedgingSwap = _iporSwapLogic.calculateSwapUnwindValue(
            swap,
            closingTimestamp,
            basePayoff,
            oppositeLegFixedRate,
            hedgingFee
        );

        //then
        assertEq(virtualHedgingSwap, -200000000000000000000);
    }

    function testShouldCalculateVirtHedgPositionElapsed10DaysNegativePnLOppositeLegRateLowerFlatFeeZero()
        public
    {
        // given
        AmmTypes.Swap memory swap;

        int256 basePayoff = -200 * 1e18;
        uint256 oppositeLegFixedRate = 3 * 1e16;

        swap.notional = 500_000 * 1e18;
        swap.fixedInterestRate = 5 * 1e16;
        swap.openTimestamp = block.timestamp;
        swap.tenor = IporTypes.SwapTenor.DAYS_28;

        uint256 closingTimestamp = swap.openTimestamp + 10 days;

        uint256 hedgingFee = 0;

        //when
        int256 virtualHedgingSwap = _iporSwapLogic.calculateSwapUnwindValue(
            swap,
            closingTimestamp,
            basePayoff,
            oppositeLegFixedRate,
            hedgingFee
        );

        //then
        assertEq(virtualHedgingSwap, -692907567269122150817);
    }

    function testShouldCalculateVirtualHedgingSwapElapsed10PositivePnLOppositeLegRateHigherFlatFeeZero()
        public
    {
        // given
        AmmTypes.Swap memory swap;

        int256 basePayoff = 200 * 1e18;
        uint256 oppositeLegFixedRate = 5 * 1e16;

        swap.notional = 500_000 * 1e18;
        swap.fixedInterestRate = 3 * 1e16;
        swap.openTimestamp = block.timestamp;
        swap.tenor = IporTypes.SwapTenor.DAYS_28;

        uint256 closingTimestamp = swap.openTimestamp + 10 days;

        uint256 hedgingFee = 0;

        //when
        int256 virtualHedgingSwap = _iporSwapLogic.calculateSwapUnwindValue(
            swap,
            closingTimestamp,
            basePayoff,
            oppositeLegFixedRate,
            hedgingFee
        );

        //then
        assertEq(virtualHedgingSwap, 693393962504649529356);
    }

    function testShouldCalculateVirtualHedgingSwapElapsed10DaysPositivePnLOppositeLegRateEqualFlatFeeZero()
        public
    {
        // given
        AmmTypes.Swap memory swap;

        int256 basePayoff = 200 * 1e18;
        uint256 oppositeLegFixedRate = 5 * 1e16;

        swap.notional = 500_000 * 1e18;
        swap.fixedInterestRate = 5 * 1e16;
        swap.openTimestamp = block.timestamp;
        swap.tenor = IporTypes.SwapTenor.DAYS_28;

        uint256 closingTimestamp = swap.openTimestamp + 10 days;

        uint256 hedgingFee = 0;

        //when
        int256 virtualHedgingSwap = _iporSwapLogic.calculateSwapUnwindValue(
            swap,
            closingTimestamp,
            basePayoff,
            oppositeLegFixedRate,
            hedgingFee
        );

        //then
        assertEq(virtualHedgingSwap, 200000000000000000000);
    }

    function testShouldCalculateVirtualHedgingSwapElapsed10DaysPositivePnLOppositeLegRateLowerFlatFeeZero()
        public
    {
        // given
        AmmTypes.Swap memory swap;

        int256 basePayoff = 200 * 1e18;
        uint256 oppositeLegFixedRate = 3 * 1e16;

        swap.notional = 500_000 * 1e18;
        swap.fixedInterestRate = 5 * 1e16;
        swap.openTimestamp = block.timestamp;
        swap.tenor = IporTypes.SwapTenor.DAYS_28;

        uint256 closingTimestamp = swap.openTimestamp + 10 days;

        uint256 hedgingFee = 0;

        //when
        int256 virtualHedgingSwap = _iporSwapLogic.calculateSwapUnwindValue(
            swap,
            closingTimestamp,
            basePayoff,
            oppositeLegFixedRate,
            hedgingFee
        );

        //then
        assertEq(virtualHedgingSwap, -292907567269122150817);
    }

    function testShouldCalculateVirtualHedgingSwapElapsed10PnLZeroOppositeLegRateHigher()
        public
    {
        // given
        AmmTypes.Swap memory swap;

        int256 basePayoff = 0;
        uint256 oppositeLegFixedRate = 5 * 1e16;

        swap.notional = 500_000 * 1e18;
        swap.fixedInterestRate = 3 * 1e16;
        swap.openTimestamp = block.timestamp;
        swap.tenor = IporTypes.SwapTenor.DAYS_28;

        uint256 closingTimestamp = swap.openTimestamp + 10 days;

        uint256 hedgingFee = 5 * 1e18;

        //when
        int256 virtualHedgingSwap = _iporSwapLogic.calculateSwapUnwindValue(
            swap,
            closingTimestamp,
            basePayoff,
            oppositeLegFixedRate,
            hedgingFee
        );

        //then
        assertEq(virtualHedgingSwap, 488393962504649529356);
    }

    function testShouldCalculateVirtualHedgingSwapElapsed10DaysPnLZeroOppositeLegRateEqual()
        public
    {
        // given
        AmmTypes.Swap memory swap;

        int256 basePayoff = 0;
        uint256 oppositeLegFixedRate = 5 * 1e16;

        swap.notional = 500_000 * 1e18;
        swap.fixedInterestRate = 5 * 1e16;
        swap.openTimestamp = block.timestamp;
        swap.tenor = IporTypes.SwapTenor.DAYS_28;

        uint256 closingTimestamp = swap.openTimestamp + 10 days;

        uint256 hedgingFee = 5 * 1e18;

        //when
        int256 virtualHedgingSwap = _iporSwapLogic.calculateSwapUnwindValue(
            swap,
            closingTimestamp,
            basePayoff,
            oppositeLegFixedRate,
            hedgingFee
        );

        //then
        assertEq(virtualHedgingSwap, -5000000000000000000);
    }

    function testShouldCalculateVirtualHedgingSwapElapsed10DaysPnLZeroOppositeLegRateLower()
        public
    {
        // given
        AmmTypes.Swap memory swap;

        int256 basePayoff = 0;
        uint256 oppositeLegFixedRate = 3 * 1e16;

        swap.notional = 500_000 * 1e18;
        swap.fixedInterestRate = 5 * 1e16;
        swap.openTimestamp = block.timestamp;
        swap.tenor = IporTypes.SwapTenor.DAYS_28;

        uint256 closingTimestamp = swap.openTimestamp + 10 days;

        uint256 hedgingFee = 5 * 1e18;

        //when
        int256 virtualHedgingSwap = _iporSwapLogic.calculateSwapUnwindValue(
            swap,
            closingTimestamp,
            basePayoff,
            oppositeLegFixedRate,
            hedgingFee
        );

        //then
        assertEq(virtualHedgingSwap, -497907567269122150817);
    }

    function testShouldCalculateVirtualHedgingSwapElapsed10PnLZeroOppositeLegRateHigherFlatFeeZero()
        public
    {
        // given
        AmmTypes.Swap memory swap;

        int256 basePayoff = 0;
        uint256 oppositeLegFixedRate = 5 * 1e16;

        swap.notional = 500_000 * 1e18;
        swap.fixedInterestRate = 3 * 1e16;
        swap.openTimestamp = block.timestamp;
        swap.tenor = IporTypes.SwapTenor.DAYS_28;

        uint256 closingTimestamp = swap.openTimestamp + 10 days;

        uint256 hedgingFee = 0;

        //when
        int256 virtualHedgingSwap = _iporSwapLogic.calculateSwapUnwindValue(
            swap,
            closingTimestamp,
            basePayoff,
            oppositeLegFixedRate,
            hedgingFee
        );

        //then
        assertEq(virtualHedgingSwap, 493393962504649529356);
    }

    function testShouldCalculateVirtualHedgingSwapElapsed10DaysPnLZeroOppositeLegRateEqualFlatFeeZero()
        public
    {
        // given
        AmmTypes.Swap memory swap;

        int256 basePayoff = 0;
        uint256 oppositeLegFixedRate = 5 * 1e16;

        swap.notional = 500_000 * 1e18;
        swap.fixedInterestRate = 5 * 1e16;
        swap.openTimestamp = block.timestamp;
        swap.tenor = IporTypes.SwapTenor.DAYS_28;

        uint256 closingTimestamp = swap.openTimestamp + 10 days;

        uint256 hedgingFee = 0;

        //when
        int256 virtualHedgingSwap = _iporSwapLogic.calculateSwapUnwindValue(
            swap,
            closingTimestamp,
            basePayoff,
            oppositeLegFixedRate,
            hedgingFee
        );

        //then
        assertEq(virtualHedgingSwap, 0);
    }

    function testShouldCalculateVirtualHedgingSwapElapsed10DaysPnLZeroOppositeLegRateLowerFlatFeeZero()
        public
    {
        // given
        AmmTypes.Swap memory swap;

        int256 basePayoff = 0;
        uint256 oppositeLegFixedRate = 3 * 1e16;

        swap.notional = 500_000 * 1e18;
        swap.fixedInterestRate = 5 * 1e16;
        swap.openTimestamp = block.timestamp;
        swap.tenor = IporTypes.SwapTenor.DAYS_28;

        uint256 closingTimestamp = swap.openTimestamp + 10 days;

        uint256 hedgingFee = 0;

        //when
        int256 virtualHedgingSwap = _iporSwapLogic.calculateSwapUnwindValue(
            swap,
            closingTimestamp,
            basePayoff,
            oppositeLegFixedRate,
            hedgingFee
        );

        //then
        assertEq(virtualHedgingSwap, -492907567269122150817);
    }

    function testShouldCalculateVirtualHedgingSwapElapsed10PnL200PayFixedZero() public {
        // given
        AmmTypes.Swap memory swap;

        int256 basePayoff = 200 * 1e18;
        uint256 oppositeLegFixedRate = 5 * 1e16;

        swap.notional = 500_000 * 1e18;
        swap.fixedInterestRate = 0;
        swap.openTimestamp = block.timestamp;
        swap.tenor = IporTypes.SwapTenor.DAYS_28;

        uint256 closingTimestamp = swap.openTimestamp + 10 days;

        uint256 hedgingFee = 5 * 1e18;

        //when
        int256 virtualHedgingSwap = _iporSwapLogic.calculateSwapUnwindValue(
            swap,
            closingTimestamp,
            basePayoff,
            oppositeLegFixedRate,
            hedgingFee
        );

        //then
        assertEq(virtualHedgingSwap, 1429397947389797852750);
    }

    function testShouldCalculateVirtualHedgingSwapElapsed10PnL200OppositeLegZero() public {
        // given
        AmmTypes.Swap memory swap;

        int256 basePayoff = 200 * 1e18;
        uint256 oppositeLegFixedRate = 0;

        swap.notional = 500_000 * 1e18;
        swap.fixedInterestRate = 5 * 1e16;
        swap.openTimestamp = block.timestamp;
        swap.tenor = IporTypes.SwapTenor.DAYS_28;

        uint256 closingTimestamp = swap.openTimestamp + 10 days;

        uint256 hedgingFee = 5 * 1e18;

        //when
        int256 virtualHedgingSwap = _iporSwapLogic.calculateSwapUnwindValue(
            swap,
            closingTimestamp,
            basePayoff,
            oppositeLegFixedRate,
            hedgingFee
        );

        //then
        assertEq(virtualHedgingSwap, -1036357975873955618668);
    }

    function testShouldCalculateVirtualHedgingSwapElapsed10PnLNegative200PayFixedZero() public {
        // given
        AmmTypes.Swap memory swap;

        int256 basePayoff = -200 * 1e18;
        uint256 oppositeLegFixedRate = 5 * 1e16;

        swap.notional = 500_000 * 1e18;
        swap.fixedInterestRate = 0;
        swap.openTimestamp = block.timestamp;
        swap.tenor = IporTypes.SwapTenor.DAYS_28;

        uint256 closingTimestamp = swap.openTimestamp + 10 days;

        uint256 hedgingFee = 5 * 1e18;

        //when
        int256 virtualHedgingSwap = _iporSwapLogic.calculateSwapUnwindValue(
            swap,
            closingTimestamp,
            basePayoff,
            oppositeLegFixedRate,
            hedgingFee
        );

        //then
        assertEq(virtualHedgingSwap, 1029397947389797852750);
    }

    function testShouldCalculateVirtualHedgingSwapElapsed10PnLNegative200OppositeLegZero()
        public
    {
        // given
        AmmTypes.Swap memory swap;

        int256 basePayoff = -200 * 1e18;
        uint256 oppositeLegFixedRate = 0;

        swap.notional = 500_000 * 1e18;
        swap.fixedInterestRate = 5 * 1e16;
        swap.openTimestamp = block.timestamp;
        swap.tenor = IporTypes.SwapTenor.DAYS_28;

        uint256 closingTimestamp = swap.openTimestamp + 10 days;

        uint256 hedgingFee = 5 * 1e18;

        //when
        int256 virtualHedgingSwap = _iporSwapLogic.calculateSwapUnwindValue(
            swap,
            closingTimestamp,
            basePayoff,
            oppositeLegFixedRate,
            hedgingFee
        );

        //then
        assertEq(virtualHedgingSwap, -1436357975873955618668);
    }

    function testShouldCalculateVirtHedgPosPnLZeroClosingInDayWhenOpenedOppositeLegHigher() public {
        // given
        AmmTypes.Swap memory swap;

        int256 basePayoff = 0;
        uint256 oppositeLegFixedRate = 5 * 1e16;

        swap.notional = 500_000 * 1e18;
        swap.fixedInterestRate = 3 * 1e16;
        swap.openTimestamp = block.timestamp;
        swap.tenor = IporTypes.SwapTenor.DAYS_28;

        uint256 closingTimestamp = swap.openTimestamp;

        uint256 hedgingFee = 5 * 1e18;

        //when
        int256 virtualHedgingSwap = _iporSwapLogic.calculateSwapUnwindValue(
            swap,
            closingTimestamp,
            basePayoff,
            oppositeLegFixedRate,
            hedgingFee
        );

        //then
        assertEq(virtualHedgingSwap, 762712066882048171722);
    }

    function testShouldCalculateVirtHedgPosPnLZeroClosingInDayWhenOpenedOppositeLegEqual() public {
        // given
        AmmTypes.Swap memory swap;

        int256 basePayoff = 0;
        uint256 oppositeLegFixedRate = 5 * 1e16;

        swap.notional = 500_000 * 1e18;
        swap.fixedInterestRate = 5 * 1e16;
        swap.openTimestamp = block.timestamp;
        swap.tenor = IporTypes.SwapTenor.DAYS_28;

        uint256 closingTimestamp = swap.openTimestamp;

        uint256 hedgingFee = 5 * 1e18;

        //when
        int256 virtualHedgingSwap = _iporSwapLogic.calculateSwapUnwindValue(
            swap,
            closingTimestamp,
            basePayoff,
            oppositeLegFixedRate,
            hedgingFee
        );

        //then
        assertEq(virtualHedgingSwap, -5000000000000000000);
    }

    function testShouldCalculateVirtHedgPosPnLZeroClosingInDayWhenOpenedOppositeLegLower() public {
        // given
        AmmTypes.Swap memory swap;

        int256 basePayoff = 0;
        uint256 oppositeLegFixedRate = 3 * 1e16;

        swap.notional = 500_000 * 1e18;
        swap.fixedInterestRate = 5 * 1e16;
        swap.openTimestamp = block.timestamp;
        swap.tenor = IporTypes.SwapTenor.DAYS_28;

        uint256 closingTimestamp = swap.openTimestamp;

        uint256 hedgingFee = 5 * 1e18;

        //when
        int256 virtualHedgingSwap = _iporSwapLogic.calculateSwapUnwindValue(
            swap,
            closingTimestamp,
            basePayoff,
            oppositeLegFixedRate,
            hedgingFee
        );

        //then
        assertEq(virtualHedgingSwap, -771535110374201597255);
    }

    function testShouldCalculateVirtHedgPosPnL200ClosingInDayWhenOpenedOppositeLegHigher() public {
        // given
        AmmTypes.Swap memory swap;

        int256 basePayoff = 200 * 1e18;
        uint256 oppositeLegFixedRate = 5 * 1e16;

        swap.notional = 500_000 * 1e18;
        swap.fixedInterestRate = 3 * 1e16;
        swap.openTimestamp = block.timestamp;
        swap.tenor = IporTypes.SwapTenor.DAYS_28;

        uint256 closingTimestamp = swap.openTimestamp;

        uint256 hedgingFee = 5 * 1e18;

        //when
        int256 virtualHedgingSwap = _iporSwapLogic.calculateSwapUnwindValue(
            swap,
            closingTimestamp,
            basePayoff,
            oppositeLegFixedRate,
            hedgingFee
        );

        //then
        assertEq(virtualHedgingSwap, 962712066882048171722);
    }

    function testShouldCalculateVirtHedgPosPnL200ClosingInDayWhenOpenedOppositeLegEqual() public {
        // given
        AmmTypes.Swap memory swap;

        int256 basePayoff = 200 * 1e18;
        uint256 oppositeLegFixedRate = 5 * 1e16;

        swap.notional = 500_000 * 1e18;
        swap.fixedInterestRate = 5 * 1e16;
        swap.openTimestamp = block.timestamp;
        swap.tenor = IporTypes.SwapTenor.DAYS_28;

        uint256 closingTimestamp = swap.openTimestamp;

        uint256 hedgingFee = 5 * 1e18;

        //when
        int256 virtualHedgingSwap = _iporSwapLogic.calculateSwapUnwindValue(
            swap,
            closingTimestamp,
            basePayoff,
            oppositeLegFixedRate,
            hedgingFee
        );

        //then
        assertEq(virtualHedgingSwap, 195000000000000000000);
    }

    function testShouldCalculateVirtHedgPosPnL200ClosingInDayWhenOpenedOppositeLegLower() public {
        // given
        AmmTypes.Swap memory swap;

        int256 basePayoff = 200 * 1e18;
        uint256 oppositeLegFixedRate = 3 * 1e16;

        swap.notional = 500_000 * 1e18;
        swap.fixedInterestRate = 5 * 1e16;
        swap.openTimestamp = block.timestamp;
        swap.tenor = IporTypes.SwapTenor.DAYS_28;

        uint256 closingTimestamp = swap.openTimestamp;

        uint256 hedgingFee = 5 * 1e18;

        //when
        int256 virtualHedgingSwap = _iporSwapLogic.calculateSwapUnwindValue(
            swap,
            closingTimestamp,
            basePayoff,
            oppositeLegFixedRate,
            hedgingFee
        );

        //then
        assertEq(virtualHedgingSwap, -571535110374201597255);
    }

    function testShouldCalculateVirtHedgPosPnLZeroClosingInDayWhenOpenedLegEqualZero() public {
        // given
        AmmTypes.Swap memory swap;

        int256 basePayoff = 0;
        uint256 oppositeLegFixedRate = 5 * 1e16;

        swap.notional = 500_000 * 1e18;
        swap.fixedInterestRate = 0;
        swap.openTimestamp = block.timestamp;
        swap.tenor = IporTypes.SwapTenor.DAYS_28;

        uint256 closingTimestamp = swap.openTimestamp;

        uint256 hedgingFee = 5 * 1e18;

        //when
        int256 virtualHedgingSwap = _iporSwapLogic.calculateSwapUnwindValue(
            swap,
            closingTimestamp,
            basePayoff,
            oppositeLegFixedRate,
            hedgingFee
        );

        //then
        assertEq(virtualHedgingSwap, 1916490914507168629875);
    }

    function testShouldCalculateVirtHedgPosPnLZeroClosingInDayWhenOpenedOppositeLegEqualZero()
        public
    {
        // given
        AmmTypes.Swap memory swap;

        int256 basePayoff = 0;
        uint256 oppositeLegFixedRate = 0;

        swap.notional = 500_000 * 1e18;
        swap.fixedInterestRate = 5 * 1e16;
        swap.openTimestamp = block.timestamp;
        swap.tenor = IporTypes.SwapTenor.DAYS_28;

        uint256 closingTimestamp = swap.openTimestamp;

        uint256 hedgingFee = 5 * 1e18;

        //when
        int256 virtualHedgingSwap = _iporSwapLogic.calculateSwapUnwindValue(
            swap,
            closingTimestamp,
            basePayoff,
            oppositeLegFixedRate,
            hedgingFee
        );

        //then
        assertEq(virtualHedgingSwap, -1919134928757670748196);
    }

    function testShouldCalculateVirtHedgPosPnLZeroClosingInDayWhenOpenedBothLegZero() public {
        // given
        AmmTypes.Swap memory swap;

        int256 basePayoff = 0;
        uint256 oppositeLegFixedRate = 0;

        swap.notional = 500_000 * 1e18;
        swap.fixedInterestRate = 0;
        swap.openTimestamp = block.timestamp;
        swap.tenor = IporTypes.SwapTenor.DAYS_28;

        uint256 closingTimestamp = swap.openTimestamp;

        uint256 hedgingFee = 5 * 1e18;

        //when
        int256 virtualHedgingSwap = _iporSwapLogic.calculateSwapUnwindValue(
            swap,
            closingTimestamp,
            basePayoff,
            oppositeLegFixedRate,
            hedgingFee
        );

        //then
        assertEq(virtualHedgingSwap, -5000000000000000000);
    }

    function testShouldCalculateVirtHedgPosMaturityPnL200OppositeLegHigher() public {
        // given
        AmmTypes.Swap memory swap;

        int256 basePayoff = 200 * 1e18;
        uint256 oppositeLegFixedRate = 5 * 1e16;

        swap.notional = 500_000 * 1e18;
        swap.fixedInterestRate = 3 * 1e16;
        swap.openTimestamp = block.timestamp;
        swap.tenor = IporTypes.SwapTenor.DAYS_28;

        uint256 closingTimestamp = swap.openTimestamp + 28 days;

        uint256 hedgingFee = 5 * 1e18;

        //when
        int256 virtualHedgingSwap = _iporSwapLogic.calculateSwapUnwindValue(
            swap,
            closingTimestamp,
            basePayoff,
            oppositeLegFixedRate,
            hedgingFee
        );

        //then
        assertEq(virtualHedgingSwap, 195000000000000000000);
    }

    function testShouldCalculateVirtHedgPosMaturityPnL200OppositeLegEqual() public {
        // given
        AmmTypes.Swap memory swap;

        int256 basePayoff = 200 * 1e18;
        uint256 oppositeLegFixedRate = 5 * 1e16;

        swap.notional = 500_000 * 1e18;
        swap.fixedInterestRate = 5 * 1e16;
        swap.openTimestamp = block.timestamp;
        swap.tenor = IporTypes.SwapTenor.DAYS_28;

        uint256 closingTimestamp = swap.openTimestamp + 28 days;

        uint256 hedgingFee = 5 * 1e18;

        //when
        int256 virtualHedgingSwap = _iporSwapLogic.calculateSwapUnwindValue(
            swap,
            closingTimestamp,
            basePayoff,
            oppositeLegFixedRate,
            hedgingFee
        );

        //then
        assertEq(virtualHedgingSwap, 195000000000000000000);
    }

    function testShouldCalculateVirtHedgPosMaturityPnL200OppositeLegLower() public {
        // given
        AmmTypes.Swap memory swap;

        int256 basePayoff = 200 * 1e18;
        uint256 oppositeLegFixedRate = 3 * 1e16;

        swap.notional = 500_000 * 1e18;
        swap.fixedInterestRate = 5 * 1e16;
        swap.openTimestamp = block.timestamp;
        swap.tenor = IporTypes.SwapTenor.DAYS_28;

        uint256 closingTimestamp = swap.openTimestamp + 28 days;

        uint256 hedgingFee = 5 * 1e18;

        //when
        int256 virtualHedgingSwap = _iporSwapLogic.calculateSwapUnwindValue(
            swap,
            closingTimestamp,
            basePayoff,
            oppositeLegFixedRate,
            hedgingFee
        );

        //then
        assertEq(virtualHedgingSwap, 195000000000000000000);
    }

    function testShouldCalculateVirtHedgPosMaturityPnL200MinusOppositeLegHigher() public {
        // given
        AmmTypes.Swap memory swap;

        int256 basePayoff = -200 * 1e18;
        uint256 oppositeLegFixedRate = 5 * 1e16;

        swap.notional = 500_000 * 1e18;
        swap.fixedInterestRate = 3 * 1e16;
        swap.openTimestamp = block.timestamp;
        swap.tenor = IporTypes.SwapTenor.DAYS_28;

        uint256 closingTimestamp = swap.openTimestamp + 28 days;

        uint256 hedgingFee = 5 * 1e18;

        //when
        int256 virtualHedgingSwap = _iporSwapLogic.calculateSwapUnwindValue(
            swap,
            closingTimestamp,
            basePayoff,
            oppositeLegFixedRate,
            hedgingFee
        );

        //then
        assertEq(virtualHedgingSwap, -205000000000000000000);
    }

    function testShouldCalculateVirtHedgPosMaturityPnL200MinusOppositeLegEqual() public {
        // given
        AmmTypes.Swap memory swap;

        int256 basePayoff = -200 * 1e18;
        uint256 oppositeLegFixedRate = 5 * 1e16;

        swap.notional = 500_000 * 1e18;
        swap.fixedInterestRate = 5 * 1e16;
        swap.openTimestamp = block.timestamp;
        swap.tenor = IporTypes.SwapTenor.DAYS_28;

        uint256 closingTimestamp = swap.openTimestamp + 28 days;

        uint256 hedgingFee = 5 * 1e18;

        //when
        int256 virtualHedgingSwap = _iporSwapLogic.calculateSwapUnwindValue(
            swap,
            closingTimestamp,
            basePayoff,
            oppositeLegFixedRate,
            hedgingFee
        );

        //then
        assertEq(virtualHedgingSwap, -205000000000000000000);
    }

    function testShouldCalculateVirtHedgPosMaturityPnL200MinusOppositeLegLower() public {
        // given
        AmmTypes.Swap memory swap;

        int256 basePayoff = -200 * 1e18;
        uint256 oppositeLegFixedRate = 3 * 1e16;

        swap.notional = 500_000 * 1e18;
        swap.fixedInterestRate = 5 * 1e16;
        swap.openTimestamp = block.timestamp;
        swap.tenor = IporTypes.SwapTenor.DAYS_28;

        uint256 closingTimestamp = swap.openTimestamp + 28 days;

        uint256 hedgingFee = 5 * 1e18;

        //when
        int256 virtualHedgingSwap = _iporSwapLogic.calculateSwapUnwindValue(
            swap,
            closingTimestamp,
            basePayoff,
            oppositeLegFixedRate,
            hedgingFee
        );

        //then
        assertEq(virtualHedgingSwap, -205000000000000000000);
    }

    function testShouldCalculateVirtHedgPosAfterMaturityPnL200OppositeLegHigher() public {
        // given
        AmmTypes.Swap memory swap;

        int256 basePayoff = 200 * 1e18;
        uint256 oppositeLegFixedRate = 5 * 1e16;

        swap.notional = 500_000 * 1e18;
        swap.fixedInterestRate = 3 * 1e16;
        swap.openTimestamp = block.timestamp;
        swap.tenor = IporTypes.SwapTenor.DAYS_28;

        uint256 closingTimestamp = swap.openTimestamp + 28 days + 2 days;

        uint256 hedgingFee = 5 * 1e18;

        //when
        vm.expectRevert(bytes(AmmErrors.CANNOT_UNWIND_CLOSING_TOO_LATE));
        int256 virtualHedgingSwap = _iporSwapLogic.calculateSwapUnwindValue(
            swap,
            closingTimestamp,
            basePayoff,
            oppositeLegFixedRate,
            hedgingFee
        );

        //then
        assertEq(virtualHedgingSwap, 0);
    }

    function testShouldCalculateVirtHedgPosAfterMaturityPnL200OppositeLegEqual() public {
        // given
        AmmTypes.Swap memory swap;

        int256 basePayoff = 200 * 1e18;
        uint256 oppositeLegFixedRate = 5 * 1e16;

        swap.notional = 500_000 * 1e18;
        swap.fixedInterestRate = 5 * 1e16;
        swap.openTimestamp = block.timestamp;
        swap.tenor = IporTypes.SwapTenor.DAYS_28;

        uint256 closingTimestamp = swap.openTimestamp + 28 days + 2 days;

        uint256 hedgingFee = 5 * 1e18;

        //when
        vm.expectRevert(bytes(AmmErrors.CANNOT_UNWIND_CLOSING_TOO_LATE));
        int256 virtualHedgingSwap = _iporSwapLogic.calculateSwapUnwindValue(
            swap,
            closingTimestamp,
            basePayoff,
            oppositeLegFixedRate,
            hedgingFee
        );

        //then
        assertEq(virtualHedgingSwap, 0);
    }

    function testShouldCalculateVirtHedgPosAterMaturityPnL200OppositeLegLower() public {
        // given
        AmmTypes.Swap memory swap;

        int256 basePayoff = 200 * 1e18;
        uint256 oppositeLegFixedRate = 3 * 1e16;

        swap.notional = 500_000 * 1e18;
        swap.fixedInterestRate = 5 * 1e16;
        swap.openTimestamp = block.timestamp;
        swap.tenor = IporTypes.SwapTenor.DAYS_28;

        uint256 closingTimestamp = swap.openTimestamp + 28 days + 2 days;

        uint256 hedgingFee = 5 * 1e18;

        //when
        vm.expectRevert(bytes(AmmErrors.CANNOT_UNWIND_CLOSING_TOO_LATE));
        int256 virtualHedgingSwap = _iporSwapLogic.calculateSwapUnwindValue(
            swap,
            closingTimestamp,
            basePayoff,
            oppositeLegFixedRate,
            hedgingFee
        );

        //then
        assertEq(virtualHedgingSwap, 0);
    }

    function testShouldCalculateVirtHedgPosAfterMaturityPnL200MinusOppositeLegHigher() public {
        // given
        AmmTypes.Swap memory swap;

        int256 basePayoff = -200 * 1e18;
        uint256 oppositeLegFixedRate = 5 * 1e16;

        swap.notional = 500_000 * 1e18;
        swap.fixedInterestRate = 3 * 1e16;
        swap.openTimestamp = block.timestamp;
        swap.tenor = IporTypes.SwapTenor.DAYS_28;

        uint256 closingTimestamp = swap.openTimestamp + 28 days + 2 days;

        uint256 hedgingFee = 5 * 1e18;

        //when
        vm.expectRevert(bytes(AmmErrors.CANNOT_UNWIND_CLOSING_TOO_LATE));
        int256 virtualHedgingSwap = _iporSwapLogic.calculateSwapUnwindValue(
            swap,
            closingTimestamp,
            basePayoff,
            oppositeLegFixedRate,
            hedgingFee
        );

        //then
        assertEq(virtualHedgingSwap, 0);
    }

    function testShouldCalculateVirtHedgPosAfterMaturityPnL200MinusOppositeLegEqual() public {
        // given
        AmmTypes.Swap memory swap;

        int256 basePayoff = -200 * 1e18;
        uint256 oppositeLegFixedRate = 5 * 1e16;

        swap.notional = 500_000 * 1e18;
        swap.fixedInterestRate = 5 * 1e16;
        swap.openTimestamp = block.timestamp;
        swap.tenor = IporTypes.SwapTenor.DAYS_28;

        uint256 closingTimestamp = swap.openTimestamp + 28 days + 2 days;

        uint256 hedgingFee = 5 * 1e18;

        //when
        vm.expectRevert(bytes(AmmErrors.CANNOT_UNWIND_CLOSING_TOO_LATE));
        int256 virtualHedgingSwap = _iporSwapLogic.calculateSwapUnwindValue(
            swap,
            closingTimestamp,
            basePayoff,
            oppositeLegFixedRate,
            hedgingFee
        );

        //then
        assertEq(virtualHedgingSwap, 0);
    }

    function testShouldCalculateVirtHedgPosAfterMaturityPnL200MinusOppositeLegLower() public {
        // given
        AmmTypes.Swap memory swap;

        int256 basePayoff = -200 * 1e18;
        uint256 oppositeLegFixedRate = 3 * 1e16;

        swap.notional = 500_000 * 1e18;
        swap.fixedInterestRate = 5 * 1e16;
        swap.openTimestamp = block.timestamp;
        swap.tenor = IporTypes.SwapTenor.DAYS_28;

        uint256 closingTimestamp = swap.openTimestamp + 28 days + 2 days;

        uint256 hedgingFee = 5 * 1e18;

        //when
        vm.expectRevert(bytes(AmmErrors.CANNOT_UNWIND_CLOSING_TOO_LATE));
        int256 virtualHedgingSwap = _iporSwapLogic.calculateSwapUnwindValue(
            swap,
            closingTimestamp,
            basePayoff,
            oppositeLegFixedRate,
            hedgingFee
        );

        //then
        assertEq(virtualHedgingSwap, 0);
    }
}

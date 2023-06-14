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

    function testShouldCalculateSwapUnwindAmountWithoutPayoffToDate() public {
        // given
        AmmTypes.Swap memory swap;

        int256 swapPayoffToDate = 0;
        uint256 oppositeLegFixedRate = 18e15;

        swap.notional = 500_000 * 1e18;
        swap.fixedInterestRate = 2 * 1e16;
        swap.openTimestamp = block.timestamp;
        swap.tenor = IporTypes.SwapTenor.DAYS_28;

        uint256 closingTimestamp = swap.openTimestamp + 5 days;

        //when
        int256 virtualHedgingSwap = _iporSwapLogic.calculateSwapUnwindAmount(
            swap,
            closingTimestamp,
            swapPayoffToDate,
            oppositeLegFixedRate
        );

        //then
        assertEq(virtualHedgingSwap, -63089187650935100324);
    }

    function testShouldCalculateSwapUnwindAmountWithoutPayoffToDateMoreDaysThanTenor() public {
        // given
        AmmTypes.Swap memory swap;

        int256 swapPayoffToDate = 0;
        uint256 oppositeLegFixedRate = 18e15;

        swap.notional = 500_000 * 1e18;
        swap.fixedInterestRate = 2 * 1e16;
        swap.openTimestamp = block.timestamp;
        swap.tenor = IporTypes.SwapTenor.DAYS_28;

        uint256 closingTimestamp = swap.openTimestamp + 30 days;

        //when
        vm.expectRevert("IPOR_333");
        int256 virtualHedgingSwap = _iporSwapLogic.calculateSwapUnwindAmount(
            swap,
            closingTimestamp,
            swapPayoffToDate,
            oppositeLegFixedRate
        );
    }

    function testShouldCalculateSwapUnwindAmountWithPayoffToDate() public {
        // given
        AmmTypes.Swap memory swap;

        uint256 oppositeLegFixedRate = 18e15;

        swap.notional = 500_000 * 1e18;
        swap.fixedInterestRate = 2 * 1e16;
        swap.openTimestamp = block.timestamp;
        swap.tenor = IporTypes.SwapTenor.DAYS_28;

        uint256 closingTimestamp = swap.openTimestamp + 5 days;

        int256 swapPayoffToDate = 0;

        //when
        int256 virtualHedgingSwap = _iporSwapLogic.calculateSwapUnwindAmount(
            swap,
            closingTimestamp,
            swapPayoffToDate,
            oppositeLegFixedRate
        );

        //then
        assertEq(virtualHedgingSwap, -63089187650935100324);
    }

    function testShouldCalculateVirtualHedgingSwapElapsed10PositivePnLOppositeLegRateHigher() public {
        // given
        AmmTypes.Swap memory swap;

        int256 swapPayoffToDate = 200 * 1e18;
        uint256 oppositeLegFixedRate = 5 * 1e16;

        swap.notional = 500_000 * 1e18;
        swap.fixedInterestRate = 3 * 1e16;
        swap.openTimestamp = block.timestamp;
        swap.tenor = IporTypes.SwapTenor.DAYS_28;

        uint256 closingTimestamp = swap.openTimestamp + 10 days;

        //when
        int256 virtualHedgingSwap = _iporSwapLogic.calculateSwapUnwindAmount(
            swap,
            closingTimestamp,
            swapPayoffToDate,
            oppositeLegFixedRate
        );

        //then
        assertEq(virtualHedgingSwap, 694124455447701456257);
    }

    function testShouldCalculateVirtualHedgingSwapElapsed10DaysPositivePnLOppositeLegRateEqual() public {
        // given
        AmmTypes.Swap memory swap;

        int256 swapPayoffToDate = 200 * 1e18;
        uint256 oppositeLegFixedRate = 5 * 1e16;

        swap.notional = 500_000 * 1e18;
        swap.fixedInterestRate = 5 * 1e16;
        swap.openTimestamp = block.timestamp;
        swap.tenor = IporTypes.SwapTenor.DAYS_28;

        uint256 closingTimestamp = swap.openTimestamp + 10 days;

        //when
        int256 virtualHedgingSwap = _iporSwapLogic.calculateSwapUnwindAmount(
            swap,
            closingTimestamp,
            swapPayoffToDate,
            oppositeLegFixedRate
        );

        //then
        assertEq(virtualHedgingSwap, 195000000000000000000 + 5e18);
    }

    function testShouldCalculateVirtualHedgingSwapElapsed10DaysPositivePnLOppositeLegRateLower() public {
        // given
        AmmTypes.Swap memory swap;

        int256 swapPayoffToDate = 200 * 1e18;
        uint256 oppositeLegFixedRate = 3 * 1e16;

        swap.notional = 500_000 * 1e18;
        swap.fixedInterestRate = 5 * 1e16;
        swap.openTimestamp = block.timestamp;
        swap.tenor = IporTypes.SwapTenor.DAYS_28;

        uint256 closingTimestamp = swap.openTimestamp + 10 days;

        //when
        int256 virtualHedgingSwap = _iporSwapLogic.calculateSwapUnwindAmount(
            swap,
            closingTimestamp,
            swapPayoffToDate,
            oppositeLegFixedRate
        );

        //then
        assertEq(virtualHedgingSwap, -294124455447701456257);
    }

    function testShouldCalculateVirtHedgPosElapsed10NegativePnLOppositeLegRateHigher() public {
        // given
        AmmTypes.Swap memory swap;

        int256 swapPayoffToDate = -200 * 1e18;
        uint256 oppositeLegFixedRate = 5 * 1e16;

        swap.notional = 500_000 * 1e18;
        swap.fixedInterestRate = 3 * 1e16;
        swap.openTimestamp = block.timestamp;
        swap.tenor = IporTypes.SwapTenor.DAYS_28;

        uint256 closingTimestamp = swap.openTimestamp + 10 days;

        //when
        int256 virtualHedgingSwap = _iporSwapLogic.calculateSwapUnwindAmount(
            swap,
            closingTimestamp,
            swapPayoffToDate,
            oppositeLegFixedRate
        );

        //then
        assertEq(virtualHedgingSwap, 294124455447701456257);
    }

    function testShouldCalculateVirtHedgPositionElapsed10DaysNegativePnLOppositeLegRateEqual() public {
        // given
        AmmTypes.Swap memory swap;

        int256 swapPayoffToDate = -200 * 1e18;
        uint256 oppositeLegFixedRate = 5 * 1e16;

        swap.notional = 500_000 * 1e18;
        swap.fixedInterestRate = 5 * 1e16;
        swap.openTimestamp = block.timestamp;
        swap.tenor = IporTypes.SwapTenor.DAYS_28;

        uint256 closingTimestamp = swap.openTimestamp + 10 days;

        //when
        int256 virtualHedgingSwap = _iporSwapLogic.calculateSwapUnwindAmount(
            swap,
            closingTimestamp,
            swapPayoffToDate,
            oppositeLegFixedRate
        );

        //then
        assertEq(virtualHedgingSwap, -200000000000000000000);
    }

    function testShouldCalculateVirtHedgPositionElapsed10DaysNegativePnLOppositeLegRateLower() public {
        // given
        AmmTypes.Swap memory swap;

        int256 swapPayoffToDate = -200 * 1e18;
        uint256 oppositeLegFixedRate = 3 * 1e16;

        swap.notional = 500_000 * 1e18;
        swap.fixedInterestRate = 5 * 1e16;
        swap.openTimestamp = block.timestamp;
        swap.tenor = IporTypes.SwapTenor.DAYS_28;

        uint256 closingTimestamp = swap.openTimestamp + 10 days;

        //when
        int256 virtualHedgingSwap = _iporSwapLogic.calculateSwapUnwindAmount(
            swap,
            closingTimestamp,
            swapPayoffToDate,
            oppositeLegFixedRate
        );

        //then
        assertEq(virtualHedgingSwap, -694124455447701456257);
    }

    function testShouldCalculateVirtualHedgingSwapElapsed10PnLZeroOppositeLegRateHigher() public {
        // given
        AmmTypes.Swap memory swap;

        int256 swapPayoffToDate = 0;
        uint256 oppositeLegFixedRate = 5 * 1e16;

        swap.notional = 500_000 * 1e18;
        swap.fixedInterestRate = 3 * 1e16;
        swap.openTimestamp = block.timestamp;
        swap.tenor = IporTypes.SwapTenor.DAYS_28;

        uint256 closingTimestamp = swap.openTimestamp + 10 days;

        //when
        int256 virtualHedgingSwap = _iporSwapLogic.calculateSwapUnwindAmount(
            swap,
            closingTimestamp,
            swapPayoffToDate,
            oppositeLegFixedRate
        );

        //then
        assertEq(virtualHedgingSwap, 494124455447701456257);
    }

    function testShouldCalculateVirtualHedgingSwapElapsed10DaysPnLZeroOppositeLegRateEqual() public {
        // given
        AmmTypes.Swap memory swap;

        int256 swapPayoffToDate = 0;
        uint256 oppositeLegFixedRate = 5 * 1e16;

        swap.notional = 500_000 * 1e18;
        swap.fixedInterestRate = 5 * 1e16;
        swap.openTimestamp = block.timestamp;
        swap.tenor = IporTypes.SwapTenor.DAYS_28;

        uint256 closingTimestamp = swap.openTimestamp + 10 days;

        //when
        int256 virtualHedgingSwap = _iporSwapLogic.calculateSwapUnwindAmount(
            swap,
            closingTimestamp,
            swapPayoffToDate,
            oppositeLegFixedRate
        );

        //then
        assertEq(virtualHedgingSwap, -5000000000000000000 + 5e18);
    }

    function testShouldCalculateVirtualHedgingSwapElapsed10DaysPnLZeroOppositeLegRateLower() public {
        // given
        AmmTypes.Swap memory swap;

        int256 swapPayoffToDate = 0;
        uint256 oppositeLegFixedRate = 3 * 1e16;

        swap.notional = 500_000 * 1e18;
        swap.fixedInterestRate = 5 * 1e16;
        swap.openTimestamp = block.timestamp;
        swap.tenor = IporTypes.SwapTenor.DAYS_28;

        uint256 closingTimestamp = swap.openTimestamp + 10 days;

        //when
        int256 virtualHedgingSwap = _iporSwapLogic.calculateSwapUnwindAmount(
            swap,
            closingTimestamp,
            swapPayoffToDate,
            oppositeLegFixedRate
        );

        //then
        assertEq(virtualHedgingSwap, -494124455447701456257);
    }

    function testShouldCalculateVirtualHedgingSwapElapsed10PnL200PayFixedZero() public {
        // given
        AmmTypes.Swap memory swap;

        int256 swapPayoffToDate = 200 * 1e18;
        uint256 oppositeLegFixedRate = 5 * 1e16;

        swap.notional = 500_000 * 1e18;
        swap.fixedInterestRate = 0;
        swap.openTimestamp = block.timestamp;
        swap.tenor = IporTypes.SwapTenor.DAYS_28;

        uint256 closingTimestamp = swap.openTimestamp + 10 days;

        //when
        int256 virtualHedgingSwap = _iporSwapLogic.calculateSwapUnwindAmount(
            swap,
            closingTimestamp,
            swapPayoffToDate,
            oppositeLegFixedRate
        );

        //then
        assertEq(virtualHedgingSwap, 1429397947389797852750 + 5e18);
    }

    function testShouldCalculateVirtualHedgingSwapElapsed10PnL200OppositeLegZero() public {
        // given
        AmmTypes.Swap memory swap;

        int256 swapPayoffToDate = 200 * 1e18;
        uint256 oppositeLegFixedRate = 0;

        swap.notional = 500_000 * 1e18;
        swap.fixedInterestRate = 5 * 1e16;
        swap.openTimestamp = block.timestamp;
        swap.tenor = IporTypes.SwapTenor.DAYS_28;

        uint256 closingTimestamp = swap.openTimestamp + 10 days;

        //when
        int256 virtualHedgingSwap = _iporSwapLogic.calculateSwapUnwindAmount(
            swap,
            closingTimestamp,
            swapPayoffToDate,
            oppositeLegFixedRate
        );

        //then
        assertEq(virtualHedgingSwap, -1034397947389797852750);
    }

    function testShouldCalculateVirtualHedgingSwapElapsed10PnLNegative200PayFixedZero() public {
        // given
        AmmTypes.Swap memory swap;

        int256 swapPayoffToDate = -200 * 1e18;
        uint256 oppositeLegFixedRate = 5 * 1e16;

        swap.notional = 500_000 * 1e18;
        swap.fixedInterestRate = 0;
        swap.openTimestamp = block.timestamp;
        swap.tenor = IporTypes.SwapTenor.DAYS_28;

        uint256 closingTimestamp = swap.openTimestamp + 10 days;

        //when
        int256 virtualHedgingSwap = _iporSwapLogic.calculateSwapUnwindAmount(
            swap,
            closingTimestamp,
            swapPayoffToDate,
            oppositeLegFixedRate
        );

        //then
        assertEq(virtualHedgingSwap, 1029397947389797852750 + 5e18);
    }

    function testShouldCalculateVirtualHedgingSwapElapsed10PnLNegative200OppositeLegZero() public {
        // given
        AmmTypes.Swap memory swap;

        int256 swapPayoffToDate = -200 * 1e18;
        uint256 oppositeLegFixedRate = 0;

        swap.notional = 500_000 * 1e18;
        swap.fixedInterestRate = 5 * 1e16;
        swap.openTimestamp = block.timestamp;
        swap.tenor = IporTypes.SwapTenor.DAYS_28;

        uint256 closingTimestamp = swap.openTimestamp + 10 days;

        //when
        int256 virtualHedgingSwap = _iporSwapLogic.calculateSwapUnwindAmount(
            swap,
            closingTimestamp,
            swapPayoffToDate,
            oppositeLegFixedRate
        );

        //then
        assertEq(virtualHedgingSwap, -1434397947389797852750);
    }

    function testShouldCalculateVirtHedgPosPnLZeroClosingInDayWhenOpenedOppositeLegHigher() public {
        // given
        AmmTypes.Swap memory swap;

        int256 swapPayoffToDate = 0;
        uint256 oppositeLegFixedRate = 5 * 1e16;

        swap.notional = 500_000 * 1e18;
        swap.fixedInterestRate = 3 * 1e16;
        swap.openTimestamp = block.timestamp;
        swap.tenor = IporTypes.SwapTenor.DAYS_28;

        uint256 closingTimestamp = swap.openTimestamp;

        //when
        int256 virtualHedgingSwap = _iporSwapLogic.calculateSwapUnwindAmount(
            swap,
            closingTimestamp,
            swapPayoffToDate,
            oppositeLegFixedRate
        );

        //then
        assertEq(virtualHedgingSwap, 769480890874670652244);
    }

    function testShouldCalculateVirtHedgPosPnLZeroClosingInDayWhenOpenedOppositeLegEqual() public {
        // given
        AmmTypes.Swap memory swap;

        int256 swapPayoffToDate = 0;
        uint256 oppositeLegFixedRate = 5 * 1e16;

        swap.notional = 500_000 * 1e18;
        swap.fixedInterestRate = 5 * 1e16;
        swap.openTimestamp = block.timestamp;
        swap.tenor = IporTypes.SwapTenor.DAYS_28;

        uint256 closingTimestamp = swap.openTimestamp;

        //when
        int256 virtualHedgingSwap = _iporSwapLogic.calculateSwapUnwindAmount(
            swap,
            closingTimestamp,
            swapPayoffToDate,
            oppositeLegFixedRate
        );

        //then
        assertEq(virtualHedgingSwap, -5000000000000000000 + 5e18);
    }

    function testShouldCalculateVirtHedgPosPnLZeroClosingInDayWhenOpenedOppositeLegLower() public {
        // given
        AmmTypes.Swap memory swap;

        int256 swapPayoffToDate = 0;
        uint256 oppositeLegFixedRate = 3 * 1e16;

        swap.notional = 500_000 * 1e18;
        swap.fixedInterestRate = 5 * 1e16;
        swap.openTimestamp = block.timestamp;
        swap.tenor = IporTypes.SwapTenor.DAYS_28;

        uint256 closingTimestamp = swap.openTimestamp;

        //when
        int256 virtualHedgingSwap = _iporSwapLogic.calculateSwapUnwindAmount(
            swap,
            closingTimestamp,
            swapPayoffToDate,
            oppositeLegFixedRate
        );

        //then
        assertEq(virtualHedgingSwap, -769480890874670652244);
    }

    function testShouldCalculateVirtHedgPosPnL200ClosingInDayWhenOpenedOppositeLegHigher() public {
        // given
        AmmTypes.Swap memory swap;

        int256 swapPayoffToDate = 200 * 1e18;
        uint256 oppositeLegFixedRate = 5 * 1e16;

        swap.notional = 500_000 * 1e18;
        swap.fixedInterestRate = 3 * 1e16;
        swap.openTimestamp = block.timestamp;
        swap.tenor = IporTypes.SwapTenor.DAYS_28;

        uint256 closingTimestamp = swap.openTimestamp;

        //when
        int256 virtualHedgingSwap = _iporSwapLogic.calculateSwapUnwindAmount(
            swap,
            closingTimestamp,
            swapPayoffToDate,
            oppositeLegFixedRate
        );

        //then
        assertEq(virtualHedgingSwap, 969480890874670652244);
    }

    function testShouldCalculateVirtHedgPosPnL200ClosingInDayWhenOpenedOppositeLegEqual() public {
        // given
        AmmTypes.Swap memory swap;

        int256 swapPayoffToDate = 200 * 1e18;
        uint256 oppositeLegFixedRate = 5 * 1e16;

        swap.notional = 500_000 * 1e18;
        swap.fixedInterestRate = 5 * 1e16;
        swap.openTimestamp = block.timestamp;
        swap.tenor = IporTypes.SwapTenor.DAYS_28;

        uint256 closingTimestamp = swap.openTimestamp;

        //when
        int256 virtualHedgingSwap = _iporSwapLogic.calculateSwapUnwindAmount(
            swap,
            closingTimestamp,
            swapPayoffToDate,
            oppositeLegFixedRate
        );

        //then
        assertEq(virtualHedgingSwap, 195000000000000000000 + 5e18);
    }

    function testShouldCalculateVirtHedgPosPnL200ClosingInDayWhenOpenedOppositeLegLower() public {
        // given
        AmmTypes.Swap memory swap;

        int256 swapPayoffToDate = 200 * 1e18;
        uint256 oppositeLegFixedRate = 3 * 1e16;

        swap.notional = 500_000 * 1e18;
        swap.fixedInterestRate = 5 * 1e16;
        swap.openTimestamp = block.timestamp;
        swap.tenor = IporTypes.SwapTenor.DAYS_28;

        uint256 closingTimestamp = swap.openTimestamp;

        //when
        int256 virtualHedgingSwap = _iporSwapLogic.calculateSwapUnwindAmount(
            swap,
            closingTimestamp,
            swapPayoffToDate,
            oppositeLegFixedRate
        );

        //then
        assertEq(virtualHedgingSwap, -569480890874670652244);
    }

    function testShouldCalculateVirtHedgPosPnLZeroClosingInDayWhenOpenedLegEqualZero() public {
        // given
        AmmTypes.Swap memory swap;

        int256 swapPayoffToDate = 0;
        uint256 oppositeLegFixedRate = 5 * 1e16;

        swap.notional = 500_000 * 1e18;
        swap.fixedInterestRate = 0;
        swap.openTimestamp = block.timestamp;
        swap.tenor = IporTypes.SwapTenor.DAYS_28;

        uint256 closingTimestamp = swap.openTimestamp;

        //when
        int256 virtualHedgingSwap = _iporSwapLogic.calculateSwapUnwindAmount(
            swap,
            closingTimestamp,
            swapPayoffToDate,
            oppositeLegFixedRate
        );

        //then
        assertEq(virtualHedgingSwap, 1916490914507168629875 + 5e18);
    }

    function testShouldCalculateVirtHedgPosPnLZeroClosingInDayWhenOpenedOppositeLegEqualZero() public {
        // given
        AmmTypes.Swap memory swap;

        int256 swapPayoffToDate = 0;
        uint256 oppositeLegFixedRate = 0;

        swap.notional = 500_000 * 1e18;
        swap.fixedInterestRate = 5 * 1e16;
        swap.openTimestamp = block.timestamp;
        swap.tenor = IporTypes.SwapTenor.DAYS_28;

        uint256 closingTimestamp = swap.openTimestamp;

        //when
        int256 virtualHedgingSwap = _iporSwapLogic.calculateSwapUnwindAmount(
            swap,
            closingTimestamp,
            swapPayoffToDate,
            oppositeLegFixedRate
        );

        //then
        assertEq(virtualHedgingSwap, -1921490914507168629875);
    }

    function testShouldCalculateVirtHedgPosPnLZeroClosingInDayWhenOpenedBothLegZero() public {
        // given
        AmmTypes.Swap memory swap;

        int256 swapPayoffToDate = 0;
        uint256 oppositeLegFixedRate = 0;

        swap.notional = 500_000 * 1e18;
        swap.fixedInterestRate = 0;
        swap.openTimestamp = block.timestamp;
        swap.tenor = IporTypes.SwapTenor.DAYS_28;

        uint256 closingTimestamp = swap.openTimestamp;

        //when
        int256 virtualHedgingSwap = _iporSwapLogic.calculateSwapUnwindAmount(
            swap,
            closingTimestamp,
            swapPayoffToDate,
            oppositeLegFixedRate
        );

        //then
        assertEq(virtualHedgingSwap, -5000000000000000000 + 5e18);
    }

    function testShouldCalculateVirtHedgPosMaturityPnL200OppositeLegHigher() public {
        // given
        AmmTypes.Swap memory swap;

        int256 swapPayoffToDate = 200 * 1e18;
        uint256 oppositeLegFixedRate = 5 * 1e16;

        swap.notional = 500_000 * 1e18;
        swap.fixedInterestRate = 3 * 1e16;
        swap.openTimestamp = block.timestamp;
        swap.tenor = IporTypes.SwapTenor.DAYS_28;

        uint256 closingTimestamp = swap.openTimestamp + 28 days;

        //when
        int256 virtualHedgingSwap = _iporSwapLogic.calculateSwapUnwindAmount(
            swap,
            closingTimestamp,
            swapPayoffToDate,
            oppositeLegFixedRate
        );

        //then
        assertEq(virtualHedgingSwap, 195000000000000000000 + 5e18);
    }

    function testShouldCalculateVirtHedgPosMaturityPnL200OppositeLegEqual() public {
        // given
        AmmTypes.Swap memory swap;

        int256 swapPayoffToDate = 200 * 1e18;
        uint256 oppositeLegFixedRate = 5 * 1e16;

        swap.notional = 500_000 * 1e18;
        swap.fixedInterestRate = 5 * 1e16;
        swap.openTimestamp = block.timestamp;
        swap.tenor = IporTypes.SwapTenor.DAYS_28;

        uint256 closingTimestamp = swap.openTimestamp + 28 days;

        //when
        int256 virtualHedgingSwap = _iporSwapLogic.calculateSwapUnwindAmount(
            swap,
            closingTimestamp,
            swapPayoffToDate,
            oppositeLegFixedRate
        );

        //then
        assertEq(virtualHedgingSwap, 200000000000000000000);
    }

    function testShouldCalculateVirtHedgPosMaturityPnL200OppositeLegLower() public {
        // given
        AmmTypes.Swap memory swap;

        int256 swapPayoffToDate = 200 * 1e18;
        uint256 oppositeLegFixedRate = 3 * 1e16;

        swap.notional = 500_000 * 1e18;
        swap.fixedInterestRate = 5 * 1e16;
        swap.openTimestamp = block.timestamp;
        swap.tenor = IporTypes.SwapTenor.DAYS_28;

        uint256 closingTimestamp = swap.openTimestamp + 28 days;

        //when
        int256 virtualHedgingSwap = _iporSwapLogic.calculateSwapUnwindAmount(
            swap,
            closingTimestamp,
            swapPayoffToDate,
            oppositeLegFixedRate
        );

        //then
        assertEq(virtualHedgingSwap, 200000000000000000000);
    }

    function testShouldCalculateVirtHedgPosMaturityPnL200MinusOppositeLegHigher() public {
        // given
        AmmTypes.Swap memory swap;

        int256 swapPayoffToDate = -200 * 1e18;
        uint256 oppositeLegFixedRate = 5 * 1e16;

        swap.notional = 500_000 * 1e18;
        swap.fixedInterestRate = 3 * 1e16;
        swap.openTimestamp = block.timestamp;
        swap.tenor = IporTypes.SwapTenor.DAYS_28;

        uint256 closingTimestamp = swap.openTimestamp + 28 days;

        //when
        int256 virtualHedgingSwap = _iporSwapLogic.calculateSwapUnwindAmount(
            swap,
            closingTimestamp,
            swapPayoffToDate,
            oppositeLegFixedRate
        );

        //then
        assertEq(virtualHedgingSwap, -200000000000000000000);
    }

    function testShouldCalculateVirtHedgPosMaturityPnL200MinusOppositeLegEqual() public {
        // given
        AmmTypes.Swap memory swap;

        int256 swapPayoffToDate = -200 * 1e18;
        uint256 oppositeLegFixedRate = 5 * 1e16;

        swap.notional = 500_000 * 1e18;
        swap.fixedInterestRate = 5 * 1e16;
        swap.openTimestamp = block.timestamp;
        swap.tenor = IporTypes.SwapTenor.DAYS_28;

        uint256 closingTimestamp = swap.openTimestamp + 28 days;

        //when
        int256 virtualHedgingSwap = _iporSwapLogic.calculateSwapUnwindAmount(
            swap,
            closingTimestamp,
            swapPayoffToDate,
            oppositeLegFixedRate
        );

        //then
        assertEq(virtualHedgingSwap, -200000000000000000000);
    }

    function testShouldCalculateVirtHedgPosMaturityPnL200MinusOppositeLegLower() public {
        // given
        AmmTypes.Swap memory swap;

        int256 swapPayoffToDate = -200 * 1e18;
        uint256 oppositeLegFixedRate = 3 * 1e16;

        swap.notional = 500_000 * 1e18;
        swap.fixedInterestRate = 5 * 1e16;
        swap.openTimestamp = block.timestamp;
        swap.tenor = IporTypes.SwapTenor.DAYS_28;

        uint256 closingTimestamp = swap.openTimestamp + 28 days;

        //when
        int256 virtualHedgingSwap = _iporSwapLogic.calculateSwapUnwindAmount(
            swap,
            closingTimestamp,
            swapPayoffToDate,
            oppositeLegFixedRate
        );

        //then
        assertEq(virtualHedgingSwap, -200000000000000000000);
    }

    function testShouldCalculateVirtHedgPosAfterMaturityPnL200OppositeLegHigher() public {
        // given
        AmmTypes.Swap memory swap;

        int256 swapPayoffToDate = 200 * 1e18;
        uint256 oppositeLegFixedRate = 5 * 1e16;

        swap.notional = 500_000 * 1e18;
        swap.fixedInterestRate = 3 * 1e16;
        swap.openTimestamp = block.timestamp;
        swap.tenor = IporTypes.SwapTenor.DAYS_28;

        uint256 closingTimestamp = swap.openTimestamp + 28 days + 2 days;

        //when
        vm.expectRevert(bytes(AmmErrors.CANNOT_UNWIND_CLOSING_TOO_LATE));
        int256 virtualHedgingSwap = _iporSwapLogic.calculateSwapUnwindAmount(
            swap,
            closingTimestamp,
            swapPayoffToDate,
            oppositeLegFixedRate
        );

        //then
        assertEq(virtualHedgingSwap, 0);
    }

    function testShouldCalculateVirtHedgPosAfterMaturityPnL200OppositeLegEqual() public {
        // given
        AmmTypes.Swap memory swap;

        int256 swapPayoffToDate = 200 * 1e18;
        uint256 oppositeLegFixedRate = 5 * 1e16;

        swap.notional = 500_000 * 1e18;
        swap.fixedInterestRate = 5 * 1e16;
        swap.openTimestamp = block.timestamp;
        swap.tenor = IporTypes.SwapTenor.DAYS_28;

        uint256 closingTimestamp = swap.openTimestamp + 28 days + 2 days;

        //when
        vm.expectRevert(bytes(AmmErrors.CANNOT_UNWIND_CLOSING_TOO_LATE));
        int256 virtualHedgingSwap = _iporSwapLogic.calculateSwapUnwindAmount(
            swap,
            closingTimestamp,
            swapPayoffToDate,
            oppositeLegFixedRate
        );

        //then
        assertEq(virtualHedgingSwap, 0);
    }

    function testShouldCalculateVirtHedgPosAterMaturityPnL200OppositeLegLower() public {
        // given
        AmmTypes.Swap memory swap;

        int256 swapPayoffToDate = 200 * 1e18;
        uint256 oppositeLegFixedRate = 3 * 1e16;

        swap.notional = 500_000 * 1e18;
        swap.fixedInterestRate = 5 * 1e16;
        swap.openTimestamp = block.timestamp;
        swap.tenor = IporTypes.SwapTenor.DAYS_28;

        uint256 closingTimestamp = swap.openTimestamp + 28 days + 2 days;

        //when
        vm.expectRevert(bytes(AmmErrors.CANNOT_UNWIND_CLOSING_TOO_LATE));
        int256 virtualHedgingSwap = _iporSwapLogic.calculateSwapUnwindAmount(
            swap,
            closingTimestamp,
            swapPayoffToDate,
            oppositeLegFixedRate
        );

        //then
        assertEq(virtualHedgingSwap, 0);
    }

    function testShouldCalculateVirtHedgPosAfterMaturityPnL200MinusOppositeLegHigher() public {
        // given
        AmmTypes.Swap memory swap;

        int256 swapPayoffToDate = -200 * 1e18;
        uint256 oppositeLegFixedRate = 5 * 1e16;

        swap.notional = 500_000 * 1e18;
        swap.fixedInterestRate = 3 * 1e16;
        swap.openTimestamp = block.timestamp;
        swap.tenor = IporTypes.SwapTenor.DAYS_28;

        uint256 closingTimestamp = swap.openTimestamp + 28 days + 2 days;

        //when
        vm.expectRevert(bytes(AmmErrors.CANNOT_UNWIND_CLOSING_TOO_LATE));
        int256 virtualHedgingSwap = _iporSwapLogic.calculateSwapUnwindAmount(
            swap,
            closingTimestamp,
            swapPayoffToDate,
            oppositeLegFixedRate
        );

        //then
        assertEq(virtualHedgingSwap, 0);
    }

    function testShouldCalculateVirtHedgPosAfterMaturityPnL200MinusOppositeLegEqual() public {
        // given
        AmmTypes.Swap memory swap;

        int256 swapPayoffToDate = -200 * 1e18;
        uint256 oppositeLegFixedRate = 5 * 1e16;

        swap.notional = 500_000 * 1e18;
        swap.fixedInterestRate = 5 * 1e16;
        swap.openTimestamp = block.timestamp;
        swap.tenor = IporTypes.SwapTenor.DAYS_28;

        uint256 closingTimestamp = swap.openTimestamp + 28 days + 2 days;

        //when
        vm.expectRevert(bytes(AmmErrors.CANNOT_UNWIND_CLOSING_TOO_LATE));
        int256 virtualHedgingSwap = _iporSwapLogic.calculateSwapUnwindAmount(
            swap,
            closingTimestamp,
            swapPayoffToDate,
            oppositeLegFixedRate
        );

        //then
        assertEq(virtualHedgingSwap, 0);
    }

    function testShouldCalculateVirtHedgPosAfterMaturityPnL200MinusOppositeLegLower() public {
        // given
        AmmTypes.Swap memory swap;

        int256 swapPayoffToDate = -200 * 1e18;
        uint256 oppositeLegFixedRate = 3 * 1e16;

        swap.notional = 500_000 * 1e18;
        swap.fixedInterestRate = 5 * 1e16;
        swap.openTimestamp = block.timestamp;
        swap.tenor = IporTypes.SwapTenor.DAYS_28;

        uint256 closingTimestamp = swap.openTimestamp + 28 days + 2 days;

        //when
        vm.expectRevert(bytes(AmmErrors.CANNOT_UNWIND_CLOSING_TOO_LATE));
        int256 virtualHedgingSwap = _iporSwapLogic.calculateSwapUnwindAmount(
            swap,
            closingTimestamp,
            swapPayoffToDate,
            oppositeLegFixedRate
        );

        //then
        assertEq(virtualHedgingSwap, 0);
    }

    function testShouldCalculateSwapUnwindOpeningFeeAmount5daysLeft() public {
        //given
        AmmTypes.Swap memory swap;

        swap.notional = 500_000 * 1e18;
        swap.openTimestamp = block.timestamp;
        swap.tenor = IporTypes.SwapTenor.DAYS_28;

        uint256 openingFeeRate = 5 * 1e14;
        uint256 closeTimestamp = block.timestamp + 23 days;

        //when
        uint256 swapOpeningFeeAmount = _iporSwapLogic.calculateSwapUnwindOpeningFeeAmount(
            swap,
            closeTimestamp,
            openingFeeRate
        );

        //then
        assertEq(swapOpeningFeeAmount, 3424657534246575250);
    }

    function testShouldCalculateSwapUnwindOpeningFeeAmount18daysPassedTenor28() public {
        //given
        AmmTypes.Swap memory swap;

        swap.notional = 500_000 * 1e18;
        swap.openTimestamp = block.timestamp;
        swap.tenor = IporTypes.SwapTenor.DAYS_28;

        uint256 openingFeeRate = 5 * 1e14;
        uint256 closeTimestamp = block.timestamp + 18 days;

        //when
        uint256 swapOpeningFeeAmount = _iporSwapLogic.calculateSwapUnwindOpeningFeeAmount(
            swap,
            closeTimestamp,
            openingFeeRate
        );

        //then
        assertEq(swapOpeningFeeAmount, 6849315068493150750);
    }

    function testShouldCalculateSwapUnwindOpeningFeeAmount18daysPassedTenor60() public {
        //given
        AmmTypes.Swap memory swap;

        swap.notional = 500_000 * 1e18;
        swap.openTimestamp = block.timestamp;
        swap.tenor = IporTypes.SwapTenor.DAYS_60;

        uint256 openingFeeRate = 5 * 1e14;
        uint256 closeTimestamp = block.timestamp + 18 days;

        //when
        uint256 swapOpeningFeeAmount = _iporSwapLogic.calculateSwapUnwindOpeningFeeAmount(
            swap,
            closeTimestamp,
            openingFeeRate
        );

        //then
        assertEq(swapOpeningFeeAmount, 28767123287671233000);
    }

    function testShouldCalculateSwapUnwindOpeningFeeAmount18daysPassedTenor90() public {
        //given
        AmmTypes.Swap memory swap;

        swap.notional = 500_000 * 1e18;
        swap.openTimestamp = block.timestamp;
        swap.tenor = IporTypes.SwapTenor.DAYS_90;

        uint256 openingFeeRate = 5 * 1e14;
        uint256 closeTimestamp = block.timestamp + 18 days;

        //when
        uint256 swapOpeningFeeAmount = _iporSwapLogic.calculateSwapUnwindOpeningFeeAmount(
            swap,
            closeTimestamp,
            openingFeeRate
        );

        //then
        assertEq(swapOpeningFeeAmount, 49315068493150685000);
    }
}

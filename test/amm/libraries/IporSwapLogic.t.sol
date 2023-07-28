// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.20;

import "forge-std/Test.sol";
import {DataUtils} from "../../utils/DataUtils.sol";
import "../../mocks/MockIporSwapLogic.sol";

contract IporSwapLogicTest is Test, DataUtils {
    MockIporSwapLogic internal _iporSwapLogic;

    function setUp() public {
        _iporSwapLogic = new MockIporSwapLogic();
    }

    function testShouldCalculateSwapUnwindAmountForPayFixedSwap18daysOppositeLegFixedRateHigher() public {
        // given
        AmmTypes.Swap memory swap;

        uint256 oppositeLegFixedRate = 32 * 1e15;

        swap.notional = 1_000_000 * 1e18;
        swap.fixedInterestRate = 3 * 1e16;
        swap.openTimestamp = block.timestamp;
        swap.tenor = IporTypes.SwapTenor.DAYS_28;

        uint256 closingTimestamp = swap.openTimestamp + 18 days;

        //when
        int256 swapUnwindPnlValue = _iporSwapLogic.calculateSwapUnwindPnlValue(
            swap,
            AmmTypes.SwapDirection.PAY_FIXED_RECEIVE_FLOATING,
            closingTimestamp,
            oppositeLegFixedRate
        );

        //then
        assertEq(swapUnwindPnlValue, 54841078135006506434);
    }

    function testShouldCalculateSwapUnwindAmountForPayFixedSwap18daysOppositeLegFixedRateLower() public {
        // given
        AmmTypes.Swap memory swap;

        uint256 oppositeLegFixedRate = 29 * 1e15;

        swap.notional = 1_000_000 * 1e18;
        swap.fixedInterestRate = 3 * 1e16;
        swap.openTimestamp = block.timestamp;
        swap.tenor = IporTypes.SwapTenor.DAYS_28;

        uint256 closingTimestamp = swap.openTimestamp + 18 days;

        //when
        int256 swapUnwindPnlValue = _iporSwapLogic.calculateSwapUnwindPnlValue(
            swap,
            AmmTypes.SwapDirection.PAY_FIXED_RECEIVE_FLOATING,
            closingTimestamp,
            oppositeLegFixedRate
        );

        //then
        assertEq(swapUnwindPnlValue, -27419412216617141908);
    }

    function testShouldCalculateSwapUnwindAmountForPayFixedSwap18daysOppositeLegFixedRateTheSame() public {
        // given
        AmmTypes.Swap memory swap;

        uint256 oppositeLegFixedRate = 3 * 1e16;

        swap.notional = 1_000_000 * 1e18;
        swap.fixedInterestRate = 3 * 1e16;
        swap.openTimestamp = block.timestamp;
        swap.tenor = IporTypes.SwapTenor.DAYS_28;

        uint256 closingTimestamp = swap.openTimestamp + 18 days;

        //when
        int256 swapUnwindPnlValue = _iporSwapLogic.calculateSwapUnwindPnlValue(
            swap,
            AmmTypes.SwapDirection.PAY_FIXED_RECEIVE_FLOATING,
            closingTimestamp,
            oppositeLegFixedRate
        );

        //then
        assertEq(swapUnwindPnlValue, 0);
    }

    function testShouldCalculateSwapUnwindAmountForReceiveFixedSwap18daysOppositeLegFixedRateHigher() public {
        // given
        AmmTypes.Swap memory swap;

        uint256 oppositeLegFixedRate = 32 * 1e15;

        swap.notional = 1_000_000 * 1e18;
        swap.fixedInterestRate = 28 * 1e15;
        swap.openTimestamp = block.timestamp;
        swap.tenor = IporTypes.SwapTenor.DAYS_28;

        uint256 closingTimestamp = swap.openTimestamp + 18 days;

        //when
        int256 swapUnwindPnlValue = _iporSwapLogic.calculateSwapUnwindPnlValue(
            swap,
            AmmTypes.SwapDirection.PAY_FLOATING_RECEIVE_FIXED,
            closingTimestamp,
            oppositeLegFixedRate
        );

        //then
        assertEq(swapUnwindPnlValue, -109679151361757278217);
    }

    function testShouldCalculateSwapUnwindAmountForReceiveFixedSwap18daysOppositeLegFixedRateLower() public {
        // given
        AmmTypes.Swap memory swap;

        uint256 oppositeLegFixedRate = 29 * 1e15;

        swap.notional = 1_000_000 * 1e18;
        swap.fixedInterestRate = 32 * 1e15;
        swap.openTimestamp = block.timestamp;
        swap.tenor = IporTypes.SwapTenor.DAYS_28;

        uint256 closingTimestamp = swap.openTimestamp + 18 days;

        //when
        int256 swapUnwindPnlValue = _iporSwapLogic.calculateSwapUnwindPnlValue(
            swap,
            AmmTypes.SwapDirection.PAY_FLOATING_RECEIVE_FIXED,
            closingTimestamp,
            oppositeLegFixedRate
        );

        //then
        assertEq(swapUnwindPnlValue, 82260490351623648342);
    }

    function testShouldCalculateSwapUnwindAmountForReceiveFixedSwap18daysOppositeLegFixedRateTheSame() public {
        // given
        AmmTypes.Swap memory swap;

        uint256 oppositeLegFixedRate = 3 * 1e16;

        swap.notional = 1_000_000 * 1e18;
        swap.fixedInterestRate = 3 * 1e16;
        swap.openTimestamp = block.timestamp;
        swap.tenor = IporTypes.SwapTenor.DAYS_28;

        uint256 closingTimestamp = swap.openTimestamp + 18 days;

        //when
        int256 swapUnwindPnlValue = _iporSwapLogic.calculateSwapUnwindPnlValue(
            swap,
            AmmTypes.SwapDirection.PAY_FLOATING_RECEIVE_FIXED,
            closingTimestamp,
            oppositeLegFixedRate
        );

        //then
        assertEq(swapUnwindPnlValue, 0);
    }

    function testShouldCalculateSwapUnwindAmountMoreDaysThanTenorForPayFixedSwap() public {
        // given
        AmmTypes.Swap memory swap;

        uint256 oppositeLegFixedRate = 18e15;

        swap.notional = 500_000 * 1e18;
        swap.fixedInterestRate = 2 * 1e16;
        swap.openTimestamp = block.timestamp;
        swap.tenor = IporTypes.SwapTenor.DAYS_28;

        uint256 closingTimestamp = swap.openTimestamp + 30 days;

        //when
        vm.expectRevert("IPOR_329");
        int256 swapUnwindPnlValue = _iporSwapLogic.calculateSwapUnwindPnlValue(
            swap,
            AmmTypes.SwapDirection.PAY_FIXED_RECEIVE_FLOATING,
            closingTimestamp,
            oppositeLegFixedRate
        );
    }

    function testShouldCalculateSwapUnwindPnlValueElapsed10OppositeLegRateHigherForPayFixedSwap() public {
        // given
        AmmTypes.Swap memory swap;

        uint256 oppositeLegFixedRate = 5 * 1e16;

        swap.notional = 500_000 * 1e18;
        swap.fixedInterestRate = 3 * 1e16;
        swap.openTimestamp = block.timestamp;
        swap.tenor = IporTypes.SwapTenor.DAYS_28;

        uint256 closingTimestamp = swap.openTimestamp + 10 days;

        //when
        int256 swapUnwindPnlValue = _iporSwapLogic.calculateSwapUnwindPnlValue(
            swap,
            AmmTypes.SwapDirection.PAY_FIXED_RECEIVE_FLOATING,
            closingTimestamp,
            oppositeLegFixedRate
        );

        //then
        assertEq(swapUnwindPnlValue, 494124455447701456257);
    }

    function testShouldCalculateSwapUnwindPnlValueElapsed10DaysOppositeLegRateLowerForPayFixedSwap() public {
        // given
        AmmTypes.Swap memory swap;

        uint256 oppositeLegFixedRate = 3 * 1e16;

        swap.notional = 500_000 * 1e18;
        swap.fixedInterestRate = 5 * 1e16;
        swap.openTimestamp = block.timestamp;
        swap.tenor = IporTypes.SwapTenor.DAYS_28;

        uint256 closingTimestamp = swap.openTimestamp + 10 days;

        //when
        int256 swapUnwindPnlValue = _iporSwapLogic.calculateSwapUnwindPnlValue(
            swap,
            AmmTypes.SwapDirection.PAY_FIXED_RECEIVE_FLOATING,
            closingTimestamp,
            oppositeLegFixedRate
        );

        //then
        assertEq(swapUnwindPnlValue, -494124455447701456257);
    }

    function testShouldCalculateVirtHedgPosElapsed10OppositeLegRateHigherForPayFixedSwap() public {
        // given
        AmmTypes.Swap memory swap;

        uint256 oppositeLegFixedRate = 5 * 1e16;

        swap.notional = 500_000 * 1e18;
        swap.fixedInterestRate = 3 * 1e16;
        swap.openTimestamp = block.timestamp;
        swap.tenor = IporTypes.SwapTenor.DAYS_28;

        uint256 closingTimestamp = swap.openTimestamp + 10 days;

        //when
        int256 swapUnwindPnlValue = _iporSwapLogic.calculateSwapUnwindPnlValue(
            swap,
            AmmTypes.SwapDirection.PAY_FIXED_RECEIVE_FLOATING,
            closingTimestamp,
            oppositeLegFixedRate
        );

        //then
        assertEq(swapUnwindPnlValue, 494124455447701456257);
    }

    function testShouldCalculateVirtHedgPositionElapsed10DaysOppositeLegRateEqualForPayFixedSwap() public {
        // given
        AmmTypes.Swap memory swap;

        uint256 oppositeLegFixedRate = 5 * 1e16;

        swap.notional = 500_000 * 1e18;
        swap.fixedInterestRate = 5 * 1e16;
        swap.openTimestamp = block.timestamp;
        swap.tenor = IporTypes.SwapTenor.DAYS_28;

        uint256 closingTimestamp = swap.openTimestamp + 10 days;

        //when
        int256 swapUnwindPnlValue = _iporSwapLogic.calculateSwapUnwindPnlValue(
            swap,
            AmmTypes.SwapDirection.PAY_FIXED_RECEIVE_FLOATING,
            closingTimestamp,
            oppositeLegFixedRate
        );

        //then
        assertEq(swapUnwindPnlValue, 0);
    }

    function testShouldCalculateVirtHedgPositionElapsed10DaysOppositeLegRateLowerForPayFixedSwap() public {
        // given
        AmmTypes.Swap memory swap;

        uint256 oppositeLegFixedRate = 3 * 1e16;

        swap.notional = 500_000 * 1e18;
        swap.fixedInterestRate = 5 * 1e16;
        swap.openTimestamp = block.timestamp;
        swap.tenor = IporTypes.SwapTenor.DAYS_28;

        uint256 closingTimestamp = swap.openTimestamp + 10 days;

        //when
        int256 swapUnwindPnlValue = _iporSwapLogic.calculateSwapUnwindPnlValue(
            swap,
            AmmTypes.SwapDirection.PAY_FIXED_RECEIVE_FLOATING,
            closingTimestamp,
            oppositeLegFixedRate
        );

        //then
        assertEq(swapUnwindPnlValue, -494124455447701456257);
    }

    function testShouldCalculateSwapUnwindPnlValueElapsed10DaysOppositeLegRateEqualForPayFixedSwap() public {
        // given
        AmmTypes.Swap memory swap;

        uint256 oppositeLegFixedRate = 5 * 1e16;

        swap.notional = 500_000 * 1e18;
        swap.fixedInterestRate = 5 * 1e16;
        swap.openTimestamp = block.timestamp;
        swap.tenor = IporTypes.SwapTenor.DAYS_28;

        uint256 closingTimestamp = swap.openTimestamp + 10 days;

        //when
        int256 swapUnwindPnlValue = _iporSwapLogic.calculateSwapUnwindPnlValue(
            swap,
            AmmTypes.SwapDirection.PAY_FIXED_RECEIVE_FLOATING,
            closingTimestamp,
            oppositeLegFixedRate
        );

        //then
        assertEq(swapUnwindPnlValue, -5000000000000000000 + 5e18);
    }

    function testShouldCalculateSwapUnwindPnlValueElapsed10PayFixedZeroForPayFixedSwap() public {
        // given
        AmmTypes.Swap memory swap;

        uint256 oppositeLegFixedRate = 5 * 1e16;

        swap.notional = 500_000 * 1e18;
        swap.fixedInterestRate = 0;
        swap.openTimestamp = block.timestamp;
        swap.tenor = IporTypes.SwapTenor.DAYS_28;

        uint256 closingTimestamp = swap.openTimestamp + 10 days;

        //when
        int256 swapUnwindPnlValue = _iporSwapLogic.calculateSwapUnwindPnlValue(
            swap,
            AmmTypes.SwapDirection.PAY_FIXED_RECEIVE_FLOATING,
            closingTimestamp,
            oppositeLegFixedRate
        );

        //then
        assertEq(swapUnwindPnlValue, 1234397947389797852750);
    }

    function testShouldCalculateSwapUnwindPnlValueElapsed10OppositeLegZeroForPayFixedSwap() public {
        // given
        AmmTypes.Swap memory swap;

        uint256 oppositeLegFixedRate = 0;

        swap.notional = 500_000 * 1e18;
        swap.fixedInterestRate = 5 * 1e16;
        swap.openTimestamp = block.timestamp;
        swap.tenor = IporTypes.SwapTenor.DAYS_28;

        uint256 closingTimestamp = swap.openTimestamp + 10 days;

        //when
        int256 swapUnwindPnlValue = _iporSwapLogic.calculateSwapUnwindPnlValue(
            swap,
            AmmTypes.SwapDirection.PAY_FIXED_RECEIVE_FLOATING,
            closingTimestamp,
            oppositeLegFixedRate
        );

        //then
        assertEq(swapUnwindPnlValue, -1234397947389797852750);
    }

    function testShouldCalculateVirtHedgPosClosingInDayWhenOpenedOppositeLegHigherForPayFixedSwap() public {
        // given
        AmmTypes.Swap memory swap;

        uint256 oppositeLegFixedRate = 5 * 1e16;

        swap.notional = 500_000 * 1e18;
        swap.fixedInterestRate = 3 * 1e16;
        swap.openTimestamp = block.timestamp;
        swap.tenor = IporTypes.SwapTenor.DAYS_28;

        uint256 closingTimestamp = swap.openTimestamp;

        //when
        int256 swapUnwindPnlValue = _iporSwapLogic.calculateSwapUnwindPnlValue(
            swap,
            AmmTypes.SwapDirection.PAY_FIXED_RECEIVE_FLOATING,
            closingTimestamp,
            oppositeLegFixedRate
        );

        //then
        assertEq(swapUnwindPnlValue, 769480890874670652244);
    }

    function testShouldCalculateVirtHedgPosClosingInDayWhenOpenedOppositeLegLowerForPayFixedSwap() public {
        // given
        AmmTypes.Swap memory swap;

        uint256 oppositeLegFixedRate = 3 * 1e16;

        swap.notional = 500_000 * 1e18;
        swap.fixedInterestRate = 5 * 1e16;
        swap.openTimestamp = block.timestamp;
        swap.tenor = IporTypes.SwapTenor.DAYS_28;

        uint256 closingTimestamp = swap.openTimestamp;

        //when
        int256 swapUnwindPnlValue = _iporSwapLogic.calculateSwapUnwindPnlValue(
            swap,
            AmmTypes.SwapDirection.PAY_FIXED_RECEIVE_FLOATING,
            closingTimestamp,
            oppositeLegFixedRate
        );

        //then
        assertEq(swapUnwindPnlValue, -769480890874670652244);
    }

    function testShouldCalculateVirtHedgPosClosingInDayWhenOpenedLegEqualZeroForPayFixedSwap() public {
        // given
        AmmTypes.Swap memory swap;

        uint256 oppositeLegFixedRate = 5 * 1e16;

        swap.notional = 500_000 * 1e18;
        swap.fixedInterestRate = 0;
        swap.openTimestamp = block.timestamp;
        swap.tenor = IporTypes.SwapTenor.DAYS_28;

        uint256 closingTimestamp = swap.openTimestamp;

        //when
        int256 swapUnwindPnlValue = _iporSwapLogic.calculateSwapUnwindPnlValue(
            swap,
            AmmTypes.SwapDirection.PAY_FIXED_RECEIVE_FLOATING,
            closingTimestamp,
            oppositeLegFixedRate
        );

        //then
        assertEq(swapUnwindPnlValue, 1916490914507168629875 + 5e18);
    }

    function testShouldCalculateVirtHedgPosClosingInDayWhenOpenedOppositeLegEqualZeroForPayFixedSwap() public {
        // given
        AmmTypes.Swap memory swap;

        uint256 oppositeLegFixedRate = 0;

        swap.notional = 500_000 * 1e18;
        swap.fixedInterestRate = 5 * 1e16;
        swap.openTimestamp = block.timestamp;
        swap.tenor = IporTypes.SwapTenor.DAYS_28;

        uint256 closingTimestamp = swap.openTimestamp;

        //when
        int256 swapUnwindPnlValue = _iporSwapLogic.calculateSwapUnwindPnlValue(
            swap,
            AmmTypes.SwapDirection.PAY_FIXED_RECEIVE_FLOATING,
            closingTimestamp,
            oppositeLegFixedRate
        );

        //then
        assertEq(swapUnwindPnlValue, -1921490914507168629875);
    }

    function testShouldCalculateVirtHedgPosClosingInDayWhenOpenedBothLegZeroForPayFixedSwap() public {
        // given
        AmmTypes.Swap memory swap;

        uint256 oppositeLegFixedRate = 0;

        swap.notional = 500_000 * 1e18;
        swap.fixedInterestRate = 0;
        swap.openTimestamp = block.timestamp;
        swap.tenor = IporTypes.SwapTenor.DAYS_28;

        uint256 closingTimestamp = swap.openTimestamp;

        //when
        int256 swapUnwindPnlValue = _iporSwapLogic.calculateSwapUnwindPnlValue(
            swap,
            AmmTypes.SwapDirection.PAY_FIXED_RECEIVE_FLOATING,
            closingTimestamp,
            oppositeLegFixedRate
        );

        //then
        assertEq(swapUnwindPnlValue, -5000000000000000000 + 5e18);
    }

    function testShouldCalculateVirtHedgPosMaturityOppositeLegHigherForPayFixedSwap() public {
        // given
        AmmTypes.Swap memory swap;

        uint256 oppositeLegFixedRate = 5 * 1e16;

        swap.notional = 500_000 * 1e18;
        swap.fixedInterestRate = 3 * 1e16;
        swap.openTimestamp = block.timestamp;
        swap.tenor = IporTypes.SwapTenor.DAYS_28;

        uint256 closingTimestamp = swap.openTimestamp + 28 days;

        //when
        int256 swapUnwindPnlValue = _iporSwapLogic.calculateSwapUnwindPnlValue(
            swap,
            AmmTypes.SwapDirection.PAY_FIXED_RECEIVE_FLOATING,
            closingTimestamp,
            oppositeLegFixedRate
        );

        //then
        assertEq(swapUnwindPnlValue, 0);
    }

    function testShouldCalculateVirtHedgPosMaturityOppositeLegEqualForPayFixedSwap() public {
        // given
        AmmTypes.Swap memory swap;

        uint256 oppositeLegFixedRate = 5 * 1e16;

        swap.notional = 500_000 * 1e18;
        swap.fixedInterestRate = 5 * 1e16;
        swap.openTimestamp = block.timestamp;
        swap.tenor = IporTypes.SwapTenor.DAYS_28;

        uint256 closingTimestamp = swap.openTimestamp + 28 days;

        //when
        int256 swapUnwindPnlValue = _iporSwapLogic.calculateSwapUnwindPnlValue(
            swap,
            AmmTypes.SwapDirection.PAY_FIXED_RECEIVE_FLOATING,
            closingTimestamp,
            oppositeLegFixedRate
        );

        //then
        assertEq(swapUnwindPnlValue, 0);
    }

    function testShouldCalculateVirtHedgPosMaturityOppositeLegLowerForPayFixedSwap() public {
        // given
        AmmTypes.Swap memory swap;

        uint256 oppositeLegFixedRate = 3 * 1e16;

        swap.notional = 500_000 * 1e18;
        swap.fixedInterestRate = 5 * 1e16;
        swap.openTimestamp = block.timestamp;
        swap.tenor = IporTypes.SwapTenor.DAYS_28;

        uint256 closingTimestamp = swap.openTimestamp + 28 days;

        //when
        int256 swapUnwindPnlValue = _iporSwapLogic.calculateSwapUnwindPnlValue(
            swap,
            AmmTypes.SwapDirection.PAY_FIXED_RECEIVE_FLOATING,
            closingTimestamp,
            oppositeLegFixedRate
        );

        //then
        assertEq(swapUnwindPnlValue, 0);
    }

    function testShouldCalculateVirtHedgPosAfterMaturityOppositeLegHigherForPayFixedSwap() public {
        // given
        AmmTypes.Swap memory swap;

        uint256 oppositeLegFixedRate = 5 * 1e16;

        swap.notional = 500_000 * 1e18;
        swap.fixedInterestRate = 3 * 1e16;
        swap.openTimestamp = block.timestamp;
        swap.tenor = IporTypes.SwapTenor.DAYS_28;

        uint256 closingTimestamp = swap.openTimestamp + 28 days + 2 days;

        //when
        vm.expectRevert(bytes(AmmErrors.CANNOT_UNWIND_CLOSING_TOO_LATE));
        int256 swapUnwindPnlValue = _iporSwapLogic.calculateSwapUnwindPnlValue(
            swap,
            AmmTypes.SwapDirection.PAY_FIXED_RECEIVE_FLOATING,
            closingTimestamp,
            oppositeLegFixedRate
        );

        //then
        assertEq(swapUnwindPnlValue, 0);
    }

    function testShouldCalculateVirtHedgPosAfterMaturityOppositeLegEqualForPayFixedSwap() public {
        // given
        AmmTypes.Swap memory swap;

        uint256 oppositeLegFixedRate = 5 * 1e16;

        swap.notional = 500_000 * 1e18;
        swap.fixedInterestRate = 5 * 1e16;
        swap.openTimestamp = block.timestamp;
        swap.tenor = IporTypes.SwapTenor.DAYS_28;

        uint256 closingTimestamp = swap.openTimestamp + 28 days + 2 days;

        //when
        vm.expectRevert(bytes(AmmErrors.CANNOT_UNWIND_CLOSING_TOO_LATE));
        int256 swapUnwindPnlValue = _iporSwapLogic.calculateSwapUnwindPnlValue(
            swap,
            AmmTypes.SwapDirection.PAY_FIXED_RECEIVE_FLOATING,
            closingTimestamp,
            oppositeLegFixedRate
        );

        //then
        assertEq(swapUnwindPnlValue, 0);
    }

    function testShouldCalculateVirtHedgPosAterMaturityOppositeLegLowerForPayFixedSwap() public {
        // given
        AmmTypes.Swap memory swap;

        uint256 oppositeLegFixedRate = 3 * 1e16;

        swap.notional = 500_000 * 1e18;
        swap.fixedInterestRate = 5 * 1e16;
        swap.openTimestamp = block.timestamp;
        swap.tenor = IporTypes.SwapTenor.DAYS_28;

        uint256 closingTimestamp = swap.openTimestamp + 28 days + 2 days;

        //when
        vm.expectRevert(bytes(AmmErrors.CANNOT_UNWIND_CLOSING_TOO_LATE));
        int256 swapUnwindPnlValue = _iporSwapLogic.calculateSwapUnwindPnlValue(
            swap,
            AmmTypes.SwapDirection.PAY_FIXED_RECEIVE_FLOATING,
            closingTimestamp,
            oppositeLegFixedRate
        );

        //then
        assertEq(swapUnwindPnlValue, 0);
    }

    function testShouldCalculateVirtHedgPosAfterMaturityOppositeLegLowerForPayFixedSwap() public {
        // given
        AmmTypes.Swap memory swap;

        uint256 oppositeLegFixedRate = 3 * 1e16;

        swap.notional = 500_000 * 1e18;
        swap.fixedInterestRate = 5 * 1e16;
        swap.openTimestamp = block.timestamp;
        swap.tenor = IporTypes.SwapTenor.DAYS_28;

        uint256 closingTimestamp = swap.openTimestamp + 28 days + 2 days;

        //when
        vm.expectRevert(bytes(AmmErrors.CANNOT_UNWIND_CLOSING_TOO_LATE));
        int256 swapUnwindPnlValue = _iporSwapLogic.calculateSwapUnwindPnlValue(
            swap,
            AmmTypes.SwapDirection.PAY_FIXED_RECEIVE_FLOATING,
            closingTimestamp,
            oppositeLegFixedRate
        );

        //then
        assertEq(swapUnwindPnlValue, 0);
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
        uint256 swapOpeningFeeAmount = _iporSwapLogic.calculateSwapUnwindFeeAmount(
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
        uint256 swapOpeningFeeAmount = _iporSwapLogic.calculateSwapUnwindFeeAmount(
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
        uint256 swapOpeningFeeAmount = _iporSwapLogic.calculateSwapUnwindFeeAmount(
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
        uint256 swapOpeningFeeAmount = _iporSwapLogic.calculateSwapUnwindFeeAmount(
            swap,
            closeTimestamp,
            openingFeeRate
        );

        //then
        assertEq(swapOpeningFeeAmount, 49315068493150685000);
    }

    function testShouldCalculateSwapUnwindAmountMoreDaysThanTenorForReceiveFixedSwap() public {
        // given
        AmmTypes.Swap memory swap;

        uint256 oppositeLegFixedRate = 18e15;

        swap.notional = 500_000 * 1e18;
        swap.fixedInterestRate = 2 * 1e16;
        swap.openTimestamp = block.timestamp;
        swap.tenor = IporTypes.SwapTenor.DAYS_28;

        uint256 closingTimestamp = swap.openTimestamp + 30 days;

        //when
        vm.expectRevert("IPOR_329");
        int256 swapUnwindPnlValue = _iporSwapLogic.calculateSwapUnwindPnlValue(
            swap,
            AmmTypes.SwapDirection.PAY_FLOATING_RECEIVE_FIXED,
            closingTimestamp,
            oppositeLegFixedRate
        );
    }

    function testShouldCalculateSwapUnwindPnlValueElapsed10OppositeLegRateHigherForReceiveFixedSwap() public {
        // given
        AmmTypes.Swap memory swap;

        uint256 oppositeLegFixedRate = 5 * 1e16;

        swap.notional = 500_000 * 1e18;
        swap.fixedInterestRate = 3 * 1e16;
        swap.openTimestamp = block.timestamp;
        swap.tenor = IporTypes.SwapTenor.DAYS_28;

        uint256 closingTimestamp = swap.openTimestamp + 10 days;

        //when
        int256 swapUnwindPnlValue = _iporSwapLogic.calculateSwapUnwindPnlValue(
            swap,
            AmmTypes.SwapDirection.PAY_FLOATING_RECEIVE_FIXED,
            closingTimestamp,
            oppositeLegFixedRate
        );

        //then
        assertEq(swapUnwindPnlValue, -494124455447701456257);
    }

    function testShouldCalculateSwapUnwindPnlValueElapsed10DaysOppositeLegRateLowerForReceiveFixedSwap() public {
        // given
        AmmTypes.Swap memory swap;

        uint256 oppositeLegFixedRate = 3 * 1e16;

        swap.notional = 500_000 * 1e18;
        swap.fixedInterestRate = 5 * 1e16;
        swap.openTimestamp = block.timestamp;
        swap.tenor = IporTypes.SwapTenor.DAYS_28;

        uint256 closingTimestamp = swap.openTimestamp + 10 days;

        //when
        int256 swapUnwindPnlValue = _iporSwapLogic.calculateSwapUnwindPnlValue(
            swap,
            AmmTypes.SwapDirection.PAY_FLOATING_RECEIVE_FIXED,
            closingTimestamp,
            oppositeLegFixedRate
        );

        //then
        assertEq(swapUnwindPnlValue, 494124455447701456257);
    }

    function testShouldCalculateVirtHedgPosElapsed10OppositeLegRateHigherForReceiveFixedSwap() public {
        // given
        AmmTypes.Swap memory swap;

        uint256 oppositeLegFixedRate = 5 * 1e16;

        swap.notional = 500_000 * 1e18;
        swap.fixedInterestRate = 3 * 1e16;
        swap.openTimestamp = block.timestamp;
        swap.tenor = IporTypes.SwapTenor.DAYS_28;

        uint256 closingTimestamp = swap.openTimestamp + 10 days;

        //when
        int256 swapUnwindPnlValue = _iporSwapLogic.calculateSwapUnwindPnlValue(
            swap,
            AmmTypes.SwapDirection.PAY_FLOATING_RECEIVE_FIXED,
            closingTimestamp,
            oppositeLegFixedRate
        );

        //then
        assertEq(swapUnwindPnlValue, -494124455447701456257);
    }

    function testShouldCalculateVirtHedgPositionElapsed10DaysOppositeLegRateEqualForReceiveFixedSwap() public {
        // given
        AmmTypes.Swap memory swap;

        uint256 oppositeLegFixedRate = 5 * 1e16;

        swap.notional = 500_000 * 1e18;
        swap.fixedInterestRate = 5 * 1e16;
        swap.openTimestamp = block.timestamp;
        swap.tenor = IporTypes.SwapTenor.DAYS_28;

        uint256 closingTimestamp = swap.openTimestamp + 10 days;

        //when
        int256 swapUnwindPnlValue = _iporSwapLogic.calculateSwapUnwindPnlValue(
            swap,
            AmmTypes.SwapDirection.PAY_FLOATING_RECEIVE_FIXED,
            closingTimestamp,
            oppositeLegFixedRate
        );

        //then
        assertEq(swapUnwindPnlValue, 0);
    }

    function testShouldCalculateVirtHedgPositionElapsed10DaysOppositeLegRateLowerForReceiveFixedSwap() public {
        // given
        AmmTypes.Swap memory swap;

        uint256 oppositeLegFixedRate = 3 * 1e16;

        swap.notional = 500_000 * 1e18;
        swap.fixedInterestRate = 5 * 1e16;
        swap.openTimestamp = block.timestamp;
        swap.tenor = IporTypes.SwapTenor.DAYS_28;

        uint256 closingTimestamp = swap.openTimestamp + 10 days;

        //when
        int256 swapUnwindPnlValue = _iporSwapLogic.calculateSwapUnwindPnlValue(
            swap,
            AmmTypes.SwapDirection.PAY_FLOATING_RECEIVE_FIXED,
            closingTimestamp,
            oppositeLegFixedRate
        );

        //then
        assertEq(swapUnwindPnlValue, 494124455447701456257);
    }

    function testShouldCalculateSwapUnwindPnlValueElapsed10DaysOppositeLegRateEqualForReceiveFixedSwap() public {
        // given
        AmmTypes.Swap memory swap;

        uint256 oppositeLegFixedRate = 5 * 1e16;

        swap.notional = 500_000 * 1e18;
        swap.fixedInterestRate = 5 * 1e16;
        swap.openTimestamp = block.timestamp;
        swap.tenor = IporTypes.SwapTenor.DAYS_28;

        uint256 closingTimestamp = swap.openTimestamp + 10 days;

        //when
        int256 swapUnwindPnlValue = _iporSwapLogic.calculateSwapUnwindPnlValue(
            swap,
            AmmTypes.SwapDirection.PAY_FLOATING_RECEIVE_FIXED,
            closingTimestamp,
            oppositeLegFixedRate
        );

        //then
        assertEq(swapUnwindPnlValue, 0);
    }

    function testShouldCalculateSwapUnwindPnlValueElapsed10PayFixedZeroForReceiveFixedSwap() public {
        // given
        AmmTypes.Swap memory swap;

        uint256 oppositeLegFixedRate = 5 * 1e16;

        swap.notional = 500_000 * 1e18;
        swap.fixedInterestRate = 0;
        swap.openTimestamp = block.timestamp;
        swap.tenor = IporTypes.SwapTenor.DAYS_28;

        uint256 closingTimestamp = swap.openTimestamp + 10 days;

        //when
        int256 swapUnwindPnlValue = _iporSwapLogic.calculateSwapUnwindPnlValue(
            swap,
            AmmTypes.SwapDirection.PAY_FLOATING_RECEIVE_FIXED,
            closingTimestamp,
            oppositeLegFixedRate
        );

        //then
        assertEq(swapUnwindPnlValue, -1234397947389797852750);
    }

    function testShouldCalculateSwapUnwindPnlValueElapsed10OppositeLegZeroForReceiveFixedSwap() public {
        // given
        AmmTypes.Swap memory swap;

        uint256 oppositeLegFixedRate = 0;

        swap.notional = 500_000 * 1e18;
        swap.fixedInterestRate = 5 * 1e16;
        swap.openTimestamp = block.timestamp;
        swap.tenor = IporTypes.SwapTenor.DAYS_28;

        uint256 closingTimestamp = swap.openTimestamp + 10 days;

        //when
        int256 swapUnwindPnlValue = _iporSwapLogic.calculateSwapUnwindPnlValue(
            swap,
            AmmTypes.SwapDirection.PAY_FLOATING_RECEIVE_FIXED,
            closingTimestamp,
            oppositeLegFixedRate
        );

        //then
        assertEq(swapUnwindPnlValue, 1234397947389797852750);
    }

    function testShouldCalculateVirtHedgPosClosingInDayWhenOpenedOppositeLegHigherForReceiveFixedSwap() public {
        // given
        AmmTypes.Swap memory swap;

        uint256 oppositeLegFixedRate = 5 * 1e16;

        swap.notional = 500_000 * 1e18;
        swap.fixedInterestRate = 3 * 1e16;
        swap.openTimestamp = block.timestamp;
        swap.tenor = IporTypes.SwapTenor.DAYS_28;

        uint256 closingTimestamp = swap.openTimestamp;

        //when
        int256 swapUnwindPnlValue = _iporSwapLogic.calculateSwapUnwindPnlValue(
            swap,
            AmmTypes.SwapDirection.PAY_FLOATING_RECEIVE_FIXED,
            closingTimestamp,
            oppositeLegFixedRate
        );

        //then
        assertEq(swapUnwindPnlValue, -769480890874670652244);
    }

    function testShouldCalculateVirtHedgPosClosingInDayWhenOpenedOppositeLegLowerForReceiveFixedSwap() public {
        // given
        AmmTypes.Swap memory swap;

        uint256 oppositeLegFixedRate = 3 * 1e16;

        swap.notional = 500_000 * 1e18;
        swap.fixedInterestRate = 5 * 1e16;
        swap.openTimestamp = block.timestamp;
        swap.tenor = IporTypes.SwapTenor.DAYS_28;

        uint256 closingTimestamp = swap.openTimestamp;

        //when
        int256 swapUnwindPnlValue = _iporSwapLogic.calculateSwapUnwindPnlValue(
            swap,
            AmmTypes.SwapDirection.PAY_FLOATING_RECEIVE_FIXED,
            closingTimestamp,
            oppositeLegFixedRate
        );

        //then
        assertEq(swapUnwindPnlValue, 769480890874670652244);
    }

    function testShouldCalculateVirtHedgPosClosingInDayWhenOpenedLegEqualZeroForReceiveFixedSwap() public {
        // given
        AmmTypes.Swap memory swap;

        uint256 oppositeLegFixedRate = 5 * 1e16;

        swap.notional = 500_000 * 1e18;
        swap.fixedInterestRate = 0;
        swap.openTimestamp = block.timestamp;
        swap.tenor = IporTypes.SwapTenor.DAYS_28;

        uint256 closingTimestamp = swap.openTimestamp;

        //when
        int256 swapUnwindPnlValue = _iporSwapLogic.calculateSwapUnwindPnlValue(
            swap,
            AmmTypes.SwapDirection.PAY_FLOATING_RECEIVE_FIXED,
            closingTimestamp,
            oppositeLegFixedRate
        );

        //then
        assertEq(swapUnwindPnlValue, -1921490914507168629875);
    }

    function testShouldCalculateVirtHedgPosClosingInDayWhenOpenedOppositeLegEqualZeroForReceiveFixedSwap() public {
        // given
        AmmTypes.Swap memory swap;

        uint256 oppositeLegFixedRate = 0;

        swap.notional = 500_000 * 1e18;
        swap.fixedInterestRate = 5 * 1e16;
        swap.openTimestamp = block.timestamp;
        swap.tenor = IporTypes.SwapTenor.DAYS_28;

        uint256 closingTimestamp = swap.openTimestamp;

        //when
        int256 swapUnwindPnlValue = _iporSwapLogic.calculateSwapUnwindPnlValue(
            swap,
            AmmTypes.SwapDirection.PAY_FLOATING_RECEIVE_FIXED,
            closingTimestamp,
            oppositeLegFixedRate
        );

        //then
        assertEq(swapUnwindPnlValue, 1921490914507168629875);
    }

    function testShouldCalculateVirtHedgPosClosingInDayWhenOpenedBothLegZeroForReceiveFixedSwap() public {
        // given
        AmmTypes.Swap memory swap;

        uint256 oppositeLegFixedRate = 0;

        swap.notional = 500_000 * 1e18;
        swap.fixedInterestRate = 0;
        swap.openTimestamp = block.timestamp;
        swap.tenor = IporTypes.SwapTenor.DAYS_28;

        uint256 closingTimestamp = swap.openTimestamp;

        //when
        int256 swapUnwindPnlValue = _iporSwapLogic.calculateSwapUnwindPnlValue(
            swap,
            AmmTypes.SwapDirection.PAY_FLOATING_RECEIVE_FIXED,
            closingTimestamp,
            oppositeLegFixedRate
        );

        //then
        assertEq(swapUnwindPnlValue, 0);
    }

    function testShouldCalculateVirtHedgPosMaturityOppositeLegHigherForReceiveFixedSwap() public {
        // given
        AmmTypes.Swap memory swap;

        uint256 oppositeLegFixedRate = 5 * 1e16;

        swap.notional = 500_000 * 1e18;
        swap.fixedInterestRate = 3 * 1e16;
        swap.openTimestamp = block.timestamp;
        swap.tenor = IporTypes.SwapTenor.DAYS_28;

        uint256 closingTimestamp = swap.openTimestamp + 28 days;

        //when
        int256 swapUnwindPnlValue = _iporSwapLogic.calculateSwapUnwindPnlValue(
            swap,
            AmmTypes.SwapDirection.PAY_FLOATING_RECEIVE_FIXED,
            closingTimestamp,
            oppositeLegFixedRate
        );

        //then
        assertEq(swapUnwindPnlValue, 0);
    }

    function testShouldCalculateVirtHedgPosMaturityOppositeLegEqualForReceiveFixedSwap() public {
        // given
        AmmTypes.Swap memory swap;

        uint256 oppositeLegFixedRate = 5 * 1e16;

        swap.notional = 500_000 * 1e18;
        swap.fixedInterestRate = 5 * 1e16;
        swap.openTimestamp = block.timestamp;
        swap.tenor = IporTypes.SwapTenor.DAYS_28;

        uint256 closingTimestamp = swap.openTimestamp + 28 days;

        //when
        int256 swapUnwindPnlValue = _iporSwapLogic.calculateSwapUnwindPnlValue(
            swap,
            AmmTypes.SwapDirection.PAY_FLOATING_RECEIVE_FIXED,
            closingTimestamp,
            oppositeLegFixedRate
        );

        //then
        assertEq(swapUnwindPnlValue, 0);
    }

    function testShouldCalculateVirtHedgPosMaturityOppositeLegLowerForReceiveFixedSwap() public {
        // given
        AmmTypes.Swap memory swap;

        uint256 oppositeLegFixedRate = 3 * 1e16;

        swap.notional = 500_000 * 1e18;
        swap.fixedInterestRate = 5 * 1e16;
        swap.openTimestamp = block.timestamp;
        swap.tenor = IporTypes.SwapTenor.DAYS_28;

        uint256 closingTimestamp = swap.openTimestamp + 28 days;

        //when
        int256 swapUnwindPnlValue = _iporSwapLogic.calculateSwapUnwindPnlValue(
            swap,
            AmmTypes.SwapDirection.PAY_FLOATING_RECEIVE_FIXED,
            closingTimestamp,
            oppositeLegFixedRate
        );

        //then
        assertEq(swapUnwindPnlValue, 0);
    }

    function testShouldCalculateVirtHedgPosAfterMaturityOppositeLegHigherForReceiveFixedSwap() public {
        // given
        AmmTypes.Swap memory swap;

        uint256 oppositeLegFixedRate = 5 * 1e16;

        swap.notional = 500_000 * 1e18;
        swap.fixedInterestRate = 3 * 1e16;
        swap.openTimestamp = block.timestamp;
        swap.tenor = IporTypes.SwapTenor.DAYS_28;

        uint256 closingTimestamp = swap.openTimestamp + 28 days + 2 days;

        //when
        vm.expectRevert(bytes(AmmErrors.CANNOT_UNWIND_CLOSING_TOO_LATE));
        int256 swapUnwindPnlValue = _iporSwapLogic.calculateSwapUnwindPnlValue(
            swap,
            AmmTypes.SwapDirection.PAY_FLOATING_RECEIVE_FIXED,
            closingTimestamp,
            oppositeLegFixedRate
        );

        //then
        assertEq(swapUnwindPnlValue, 0);
    }

    function testShouldCalculateVirtHedgPosAfterMaturityOppositeLegEqualForReceiveFixedSwap() public {
        // given
        AmmTypes.Swap memory swap;

        uint256 oppositeLegFixedRate = 5 * 1e16;

        swap.notional = 500_000 * 1e18;
        swap.fixedInterestRate = 5 * 1e16;
        swap.openTimestamp = block.timestamp;
        swap.tenor = IporTypes.SwapTenor.DAYS_28;

        uint256 closingTimestamp = swap.openTimestamp + 28 days + 2 days;

        //when
        vm.expectRevert(bytes(AmmErrors.CANNOT_UNWIND_CLOSING_TOO_LATE));
        int256 swapUnwindPnlValue = _iporSwapLogic.calculateSwapUnwindPnlValue(
            swap,
            AmmTypes.SwapDirection.PAY_FLOATING_RECEIVE_FIXED,
            closingTimestamp,
            oppositeLegFixedRate
        );

        //then
        assertEq(swapUnwindPnlValue, 0);
    }

    function testShouldCalculateVirtHedgPosAterMaturityOppositeLegLowerForReceiveFixedSwap() public {
        // given
        AmmTypes.Swap memory swap;

        uint256 oppositeLegFixedRate = 3 * 1e16;

        swap.notional = 500_000 * 1e18;
        swap.fixedInterestRate = 5 * 1e16;
        swap.openTimestamp = block.timestamp;
        swap.tenor = IporTypes.SwapTenor.DAYS_28;

        uint256 closingTimestamp = swap.openTimestamp + 28 days + 2 days;

        //when
        vm.expectRevert(bytes(AmmErrors.CANNOT_UNWIND_CLOSING_TOO_LATE));
        int256 swapUnwindPnlValue = _iporSwapLogic.calculateSwapUnwindPnlValue(
            swap,
            AmmTypes.SwapDirection.PAY_FLOATING_RECEIVE_FIXED,
            closingTimestamp,
            oppositeLegFixedRate
        );

        //then
        assertEq(swapUnwindPnlValue, 0);
    }

    function testShouldCalculateVirtHedgPosAfterMaturityOppositeLegLowerForReceiveFixedSwap() public {
        // given
        AmmTypes.Swap memory swap;

        uint256 oppositeLegFixedRate = 3 * 1e16;

        swap.notional = 500_000 * 1e18;
        swap.fixedInterestRate = 5 * 1e16;
        swap.openTimestamp = block.timestamp;
        swap.tenor = IporTypes.SwapTenor.DAYS_28;

        uint256 closingTimestamp = swap.openTimestamp + 28 days + 2 days;

        //when
        vm.expectRevert(bytes(AmmErrors.CANNOT_UNWIND_CLOSING_TOO_LATE));
        int256 swapUnwindPnlValue = _iporSwapLogic.calculateSwapUnwindPnlValue(
            swap,
            AmmTypes.SwapDirection.PAY_FLOATING_RECEIVE_FIXED,
            closingTimestamp,
            oppositeLegFixedRate
        );

        //then
        assertEq(swapUnwindPnlValue, 0);
    }

    function testShouldNotCalculateSwapUnwindOpeningFeeAmountWrongCloseTimestamp() public {
        //given
        AmmTypes.Swap memory swap;

        swap.notional = 500_000 * 1e18;
        swap.openTimestamp = block.timestamp;
        swap.tenor = IporTypes.SwapTenor.DAYS_28;

        uint256 openingFeeRate = 5 * 1e14;
        uint256 closeTimestamp = block.timestamp - 1;

        //when
        vm.expectRevert(bytes(AmmErrors.CLOSING_TIMESTAMP_LOWER_THAN_SWAP_OPEN_TIMESTAMP));
        uint256 swapOpeningFeeAmount = _iporSwapLogic.calculateSwapUnwindFeeAmount(
            swap,
            closeTimestamp,
            openingFeeRate
        );
    }
}

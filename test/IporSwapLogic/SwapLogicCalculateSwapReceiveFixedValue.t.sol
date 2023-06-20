// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.20;

import {DataUtils} from "../utils/DataUtils.sol";
import "../TestCommons.sol";
import "../utils/TestConstants.sol";
import "@ipor-protocol/contracts/mocks/MockIporSwapLogic.sol";
import "@ipor-protocol/contracts/interfaces/types/IporTypes.sol";

contract IporSwapLogicCalculateSwapReceiveFixedValue is TestCommons, DataUtils {
    MockIporSwapLogic internal _iporSwapLogic;

    function setUp() public {
        _iporSwapLogic = new MockIporSwapLogic();
    }

    function testShouldCalculateInterestCase1() public {
        // given
        AmmTypes.Swap memory swap = AmmTypes.Swap(
            TestConstants.ZERO, // id
            _admin, // buyer
            block.timestamp, // openTimestamp
            IporTypes.SwapTenor.DAYS_28,
            TestConstants.ZERO, // idsIndex
            TestConstants.USD_50_000_18DEC, // collateral
            9870300000000000000000 * 10, // notional
            987030000000000000000, // ibtQuantity
            40000000000000000, // fixedInterestRate
            TestConstants.TC_LIQUIDATION_DEPOSIT_AMOUNT_18DEC, // liquidationDepositAmount
            IporTypes.SwapState.ACTIVE
        );
        // when
        int256 swapValue = _iporSwapLogic.calculatePayoffReceiveFixed(
            swap, swap.openTimestamp + TestConstants.SWAP_DEFAULT_PERIOD_IN_SECONDS, 1 * TestConstants.D18
        );
        // then
        assertEq(swapValue, 50000000000000000000000);
    }

    function testShouldCalculateInterestCase2WhenSameTimestampAndIBTPriceIncreasesAnd18Decimals() public {
        // given
        AmmTypes.Swap memory swap = AmmTypes.Swap(
            TestConstants.ZERO, // id
            _admin, // buyer
            block.timestamp, // openTimestamp
            IporTypes.SwapTenor.DAYS_28,
            TestConstants.ZERO, // idsIndex
            TestConstants.USD_50_000_18DEC, // collateral
            9870300000000000000000 * 10, // notional
            987030000000000000000, // ibtQuantity
            TestConstants.PERCENTAGE_4_18DEC, // fixedInterestRate
            TestConstants.TC_LIQUIDATION_DEPOSIT_AMOUNT_18DEC, // liquidationDepositAmount
            IporTypes.SwapState.ACTIVE
        );
        // when
        int256 swapValue = _iporSwapLogic.calculatePayoffReceiveFixed(swap, swap.openTimestamp, 125 * TestConstants.D18);
        // then
        assertEq(swapValue, -24675750000000000000000);
    }

    function testShouldCalculateInterestWhen25DaysLaterIBTPriceHasNotChangedAnd18Decimals() public {
        // given
        AmmTypes.Swap memory swap = AmmTypes.Swap(
            TestConstants.ZERO, // id
            _admin, // buyer
            block.timestamp, // openTimestamp
            IporTypes.SwapTenor.DAYS_28,
            TestConstants.ZERO, // idsIndex
            TestConstants.USD_50_000_18DEC, // collateral
            9870300000000000000000 * 10, // notional
            987030000000000000000, // ibtQuantity
            TestConstants.PERCENTAGE_4_18DEC, // fixedInterestRate
            TestConstants.TC_LIQUIDATION_DEPOSIT_AMOUNT_18DEC, // liquidationDepositAmount
            IporTypes.SwapState.ACTIVE
        );
        // when
        int256 swapValue = _iporSwapLogic.calculatePayoffReceiveFixed(
            swap, swap.openTimestamp + TestConstants.PERIOD_25_DAYS_IN_SECONDS, 100 * TestConstants.D18
        );
        // then
        assertEq(swapValue, 270789953843120398784);
    }

    function testShouldCalculateInterestWhen25DaysLaterIBTPriceHasChangedAnd18Decimals() public {
        // given
        AmmTypes.Swap memory swap = AmmTypes.Swap(
            TestConstants.ZERO, // id
            _admin, // buyer
            block.timestamp, // openTimestamp
            IporTypes.SwapTenor.DAYS_28,
            TestConstants.ZERO, // idsIndex
            TestConstants.USD_50_000_18DEC, // collateral
            9870300000000000000000 * 10, // notional
            987030000000000000000, // ibtQuantity
            TestConstants.PERCENTAGE_4_18DEC, // fixedInterestRate
            TestConstants.TC_LIQUIDATION_DEPOSIT_AMOUNT_18DEC, // liquidationDepositAmount
            IporTypes.SwapState.ACTIVE
        );
        // when
        int256 swapValue = _iporSwapLogic.calculatePayoffReceiveFixed(
            swap, swap.openTimestamp + TestConstants.PERIOD_25_DAYS_IN_SECONDS, 125 * TestConstants.D18
        );
        // then
        assertEq(swapValue, -24404960046156879601216);
    }

    function testShouldCalculateInterestWhenHugeIPOR25DaysLaterAndIBTPriceHasChangedAndUserLosesAnd18Decimals()
    public
    {
        // given
        AmmTypes.Swap memory swap = AmmTypes.Swap(
            TestConstants.ZERO, // id
            _admin, // buyer
            block.timestamp, // openTimestamp
            IporTypes.SwapTenor.DAYS_28,
            TestConstants.ZERO, // idsIndex
            TestConstants.USD_50_000_18DEC, // collateral
            98703 * TestConstants.D18, // notional
            98703 * TestConstants.D16, // ibtQuantity
            TestConstants.PERCENTAGE_366_18DEC, // fixedInterestRate
            TestConstants.TC_LIQUIDATION_DEPOSIT_AMOUNT_18DEC, // liquidationDepositAmount
            IporTypes.SwapState.ACTIVE
        );
        // when
        int256 swapValue = _iporSwapLogic.calculatePayoffReceiveFixed(
            swap, swap.openTimestamp + TestConstants.PERIOD_25_DAYS_IN_SECONDS, 125 * TestConstants.D18
        );
        // then
        assertEq(swapValue, 3445246712749083726618);
    }

    function testShouldCalculateInterestWhen100DaysLaterIBTPriceHasNotChangedAnd18Decimals() public {
        // given
        AmmTypes.Swap memory swap = AmmTypes.Swap(
            TestConstants.ZERO, // id
            _admin, // buyer
            block.timestamp, // openTimestamp
            IporTypes.SwapTenor.DAYS_28,
            TestConstants.ZERO, // idsIndex
            TestConstants.USD_50_000_18DEC, // collateral
            9870300000000000000000 * 10, // notional
            987030000000000000000, // ibtQuantity
            TestConstants.PERCENTAGE_4_18DEC, // fixedInterestRate
            TestConstants.TC_LIQUIDATION_DEPOSIT_AMOUNT_18DEC, // liquidationDepositAmount
            IporTypes.SwapState.ACTIVE
        );
        // when
        int256 swapValue = _iporSwapLogic.calculatePayoffReceiveFixed(
            swap, swap.openTimestamp + 4 * TestConstants.PERIOD_25_DAYS_IN_SECONDS, 120 * TestConstants.D18
        );
        // then
        assertEq(swapValue, -18652974581413050198561);
    }

    function testShouldCalculateInterestWhen100DaysLaterIBTPriceHasChangedAnd18Decimals() public {
        // given
        AmmTypes.Swap memory swap = AmmTypes.Swap(
            TestConstants.ZERO, // id
            _admin, // buyer
            block.timestamp, // openTimestamp
            IporTypes.SwapTenor.DAYS_28,
            TestConstants.ZERO, // idsIndex
            TestConstants.USD_50_000_18DEC, // collateral
            9870300000000000000000 * 10, // notional
            987030000000000000000, // ibtQuantity
            TestConstants.PERCENTAGE_4_18DEC, // fixedInterestRate
            TestConstants.TC_LIQUIDATION_DEPOSIT_AMOUNT_18DEC, // liquidationDepositAmount
            IporTypes.SwapState.ACTIVE
        );
        // when
        int256 swapValue = _iporSwapLogic.calculatePayoffReceiveFixed(
            swap, swap.openTimestamp + 4 * TestConstants.PERIOD_25_DAYS_IN_SECONDS, 120 * TestConstants.D18
        );
        // then
        assertEq(swapValue, -18652974581413050198561);
    }

    function testShouldCalculateInterestWhen100DaysLaterIBTPriceHasChangedAnd6Decimals() public {
        // given
        AmmTypes.Swap memory swap = AmmTypes.Swap(
            TestConstants.ZERO, // id
            _admin, // buyer
            block.timestamp, // openTimestamp
            IporTypes.SwapTenor.DAYS_28,
            TestConstants.ZERO, // idsIndex
            TestConstants.USD_50_000_18DEC, // collateral
            9870300000000000000000 * 10, // notional
            987030000000000000000, // ibtQuantity
            TestConstants.PERCENTAGE_4_18DEC, // fixedInterestRate
            TestConstants.TC_LIQUIDATION_DEPOSIT_AMOUNT_18DEC, // liquidationDepositAmount
            IporTypes.SwapState.ACTIVE
        );
        // when
        int256 swapValue = _iporSwapLogic.calculatePayoffReceiveFixed(
            swap, swap.openTimestamp + 4 * TestConstants.PERIOD_25_DAYS_IN_SECONDS, 120 * TestConstants.D18
        );
        // then
        assertEq(swapValue, -18652974581413050198561);
    }
}

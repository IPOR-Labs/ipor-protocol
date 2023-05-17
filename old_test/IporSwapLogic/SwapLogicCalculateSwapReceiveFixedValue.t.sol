// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.16;

import {DataUtils} from "../utils/DataUtils.sol";
import "../TestCommons.sol";
import "../utils/TestConstants.sol";
import "contracts/mocks/MockIporSwapLogic.sol";
import "contracts/interfaces/types/IporTypes.sol";

contract IporSwapLogicCalculateSwapReceiveFixedValue is TestCommons, DataUtils {
    MockIporSwapLogic internal _iporSwapLogic;

    function setUp() public {
        _iporSwapLogic = new MockIporSwapLogic();
    }

    function testShouldCalculateInterestCase1() public {
        // given
        IporTypes.IporSwapMemory memory swap = IporTypes.IporSwapMemory(
            TestConstants.ZERO, // id
            _admin, // buyer
            block.timestamp, // openTimestamp
            block.timestamp + TestConstants.SWAP_DEFAULT_PERIOD_IN_SECONDS, // closeTimestamp
            TestConstants.ZERO, // idsIndex
            TestConstants.USD_50_000_18DEC, // collateral
            9870300000000000000000 * 10, // notional
            987030000000000000000, // ibtQuantity
            40000000000000000, // fixedInterestRate
            TestConstants.TC_LIQUIDATION_DEPOSIT_AMOUNT_18DEC, // liquidationDepositAmount
            1 // state
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
        IporTypes.IporSwapMemory memory swap = IporTypes.IporSwapMemory(
            TestConstants.ZERO, // id
            _admin, // buyer
            block.timestamp, // openTimestamp
            block.timestamp + TestConstants.SWAP_DEFAULT_PERIOD_IN_SECONDS, // closeTimestamp
            TestConstants.ZERO, // idsIndex
            TestConstants.USD_50_000_18DEC, // collateral
            9870300000000000000000 * 10, // notional
            987030000000000000000, // ibtQuantity
            TestConstants.PERCENTAGE_4_18DEC, // fixedInterestRate
            TestConstants.TC_LIQUIDATION_DEPOSIT_AMOUNT_18DEC, // liquidationDepositAmount
            1 // state
        );
        // when
        int256 swapValue = _iporSwapLogic.calculatePayoffReceiveFixed(swap, swap.openTimestamp, 125 * TestConstants.D18);
        // then
        assertEq(swapValue, -24675750000000000000000);
    }

    function testShouldCalculateInterestWhen25DaysLaterIBTPriceHasNotChangedAnd18Decimals() public {
        // given
        IporTypes.IporSwapMemory memory swap = IporTypes.IporSwapMemory(
            TestConstants.ZERO, // id
            _admin, // buyer
            block.timestamp, // openTimestamp
            block.timestamp + TestConstants.SWAP_DEFAULT_PERIOD_IN_SECONDS, // closeTimestamp
            TestConstants.ZERO, // idsIndex
            TestConstants.USD_50_000_18DEC, // collateral
            9870300000000000000000 * 10, // notional
            987030000000000000000, // ibtQuantity
            TestConstants.PERCENTAGE_4_18DEC, // fixedInterestRate
            TestConstants.TC_LIQUIDATION_DEPOSIT_AMOUNT_18DEC, // liquidationDepositAmount
            1 // state
        );
        // when
        int256 swapValue = _iporSwapLogic.calculatePayoffReceiveFixed(
            swap, swap.openTimestamp + TestConstants.PERIOD_25_DAYS_IN_SECONDS, 100 * TestConstants.D18
        );
        // then
        assertEq(swapValue, 270419178082191780822);
    }

    function testShouldCalculateInterestWhen25DaysLaterIBTPriceHasChangedAnd18Decimals() public {
        // given
        IporTypes.IporSwapMemory memory swap = IporTypes.IporSwapMemory(
            TestConstants.ZERO, // id
            _admin, // buyer
            block.timestamp, // openTimestamp
            block.timestamp + TestConstants.SWAP_DEFAULT_PERIOD_IN_SECONDS, // closeTimestamp
            TestConstants.ZERO, // idsIndex
            TestConstants.USD_50_000_18DEC, // collateral
            9870300000000000000000 * 10, // notional
            987030000000000000000, // ibtQuantity
            TestConstants.PERCENTAGE_4_18DEC, // fixedInterestRate
            TestConstants.TC_LIQUIDATION_DEPOSIT_AMOUNT_18DEC, // liquidationDepositAmount
            1 // state
        );
        // when
        int256 swapValue = _iporSwapLogic.calculatePayoffReceiveFixed(
            swap, swap.openTimestamp + TestConstants.PERIOD_25_DAYS_IN_SECONDS, 125 * TestConstants.D18
        );
        // then
        assertEq(swapValue, -24405330821917808219178);
    }

    function testShouldCalculateInterestWhenHugeIPOR25DaysLaterAndIBTPriceHasChangedAndUserLosesAnd18Decimals()
        public
    {
        // given
        IporTypes.IporSwapMemory memory swap = IporTypes.IporSwapMemory(
            TestConstants.ZERO, // id
            _admin, // buyer
            block.timestamp, // openTimestamp
            block.timestamp + TestConstants.SWAP_DEFAULT_PERIOD_IN_SECONDS, // closeTimestamp
            TestConstants.ZERO, // idsIndex
            TestConstants.USD_50_000_18DEC, // collateral
            9870300000000000000000 * 10, // notional
            987030000000000000000, // ibtQuantity
            3650000000000000000 + TestConstants.PERCENTAGE_1_18DEC, // fixedInterestRate
            TestConstants.TC_LIQUIDATION_DEPOSIT_AMOUNT_18DEC, // liquidationDepositAmount
            1 // state
        );
        // when
        int256 swapValue = _iporSwapLogic.calculatePayoffReceiveFixed(
            swap, swap.openTimestamp + TestConstants.PERIOD_25_DAYS_IN_SECONDS, 125 * TestConstants.D18
        );
        // then
        assertEq(swapValue, 67604794520547945205);
    }

    function testShouldCalculateInterestWhen100DaysLaterIBTPriceHasNotChangedAnd18Decimals() public {
        // given
        IporTypes.IporSwapMemory memory swap = IporTypes.IporSwapMemory(
            TestConstants.ZERO, // id
            _admin, // buyer
            block.timestamp, // openTimestamp
            block.timestamp + TestConstants.SWAP_DEFAULT_PERIOD_IN_SECONDS, // closeTimestamp
            TestConstants.ZERO, // idsIndex
            TestConstants.USD_50_000_18DEC, // collateral
            9870300000000000000000 * 10, // notional
            987030000000000000000, // ibtQuantity
            TestConstants.PERCENTAGE_4_18DEC, // fixedInterestRate
            TestConstants.TC_LIQUIDATION_DEPOSIT_AMOUNT_18DEC, // liquidationDepositAmount
            1 // state
        );
        // when
        int256 swapValue = _iporSwapLogic.calculatePayoffReceiveFixed(
            swap, swap.openTimestamp + 4 * TestConstants.PERIOD_25_DAYS_IN_SECONDS, 120 * TestConstants.D18
        );
        // then
        assertEq(swapValue, -18658923287671232876712);
    }

    function testShouldCalculateInterestWhen100DaysLaterIBTPriceHasChangedAnd18Decimals() public {
        // given
        IporTypes.IporSwapMemory memory swap = IporTypes.IporSwapMemory(
            TestConstants.ZERO, // id
            _admin, // buyer
            block.timestamp, // openTimestamp
            block.timestamp + TestConstants.SWAP_DEFAULT_PERIOD_IN_SECONDS, // closeTimestamp
            TestConstants.ZERO, // idsIndex
            TestConstants.USD_50_000_18DEC, // collateral
            9870300000000000000000 * 10, // notional
            987030000000000000000, // ibtQuantity
            TestConstants.PERCENTAGE_4_18DEC, // fixedInterestRate
            TestConstants.TC_LIQUIDATION_DEPOSIT_AMOUNT_18DEC, // liquidationDepositAmount
            1 // state
        );
        // when
        int256 swapValue = _iporSwapLogic.calculatePayoffReceiveFixed(
            swap, swap.openTimestamp + 4 * TestConstants.PERIOD_25_DAYS_IN_SECONDS, 120 * TestConstants.D18
        );
        // then
        assertEq(swapValue, -18658923287671232876712);
    }

    function testShouldCalculateInterestWhen100DaysLaterIBTPriceHasChangedAnd6Decimals() public {
        // given
        IporTypes.IporSwapMemory memory swap = IporTypes.IporSwapMemory(
            TestConstants.ZERO, // id
            _admin, // buyer
            block.timestamp, // openTimestamp
            block.timestamp + TestConstants.SWAP_DEFAULT_PERIOD_IN_SECONDS, // closeTimestamp
            TestConstants.ZERO, // idsIndex
            TestConstants.USD_50_000_18DEC, // collateral
            9870300000000000000000 * 10, // notional
            987030000000000000000, // ibtQuantity
            TestConstants.PERCENTAGE_4_18DEC, // fixedInterestRate
            TestConstants.TC_LIQUIDATION_DEPOSIT_AMOUNT_18DEC, // liquidationDepositAmount
            1 // state
        );
        // when
        int256 swapValue = _iporSwapLogic.calculatePayoffReceiveFixed(
            swap, swap.openTimestamp + 4 * TestConstants.PERIOD_25_DAYS_IN_SECONDS, 120 * TestConstants.D18
        );
        // then
        assertEq(swapValue, -18658923287671232876712);
    }
}

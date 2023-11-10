// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.20;

import {DataUtils} from "../../utils/DataUtils.sol";
import "../../TestCommons.sol";
import "../../utils/TestConstants.sol";
import "../../mocks/MockSwapLogicGenOne.sol";
import "../../../contracts/interfaces/types/IporTypes.sol";

contract IporSwapLogicCalculateSwapPayFixedValue is TestCommons, DataUtils {
    MockSwapLogicGenOne internal _iporSwapLogic;

    function setUp() public {
        _iporSwapLogic = new MockSwapLogicGenOne();
    }

    function testShouldCalculateInterestCase1() public {
        // given
        AmmTypesGenOne.Swap memory swap = AmmTypesGenOne.Swap(
            TestConstants.ZERO, // id
            _admin, // buyer
            block.timestamp, // openTimestamp
            IporTypes.SwapTenor.DAYS_28,
            AmmTypes.SwapDirection.PAY_FIXED_RECEIVE_FLOATING,
            TestConstants.ZERO, // idsIndex
            TestConstants.USD_50_000_18DEC, // collateral
            9870300000000000000000 * 10, // notional
            987030000000000000000, // ibtQuantity
            40000000000000000, // fixedInterestRate
            TestConstants.TC_LIQUIDATION_DEPOSIT_AMOUNT_18DEC, // liquidationDepositAmount
            IporTypes.SwapState.ACTIVE
        );
        // when
        int256 swapValue = _iporSwapLogic.calculatePnlPayFixed(
            swap,
            block.timestamp + TestConstants.SWAP_DEFAULT_PERIOD_IN_SECONDS,
            1 * TestConstants.D18
        );
        // then
        assertEq(swapValue, -50000000000000000000000);
    }

    function testShouldCalculateInterestCase2WhenSameTimestampAndIBTPriceIncreasesAnd18Decimals() public {
        // given
        AmmTypesGenOne.Swap memory swap = AmmTypesGenOne.Swap(
            TestConstants.ZERO, // id
            _admin, // buyer
            block.timestamp, // openTimestamp
            IporTypes.SwapTenor.DAYS_28,
            AmmTypes.SwapDirection.PAY_FIXED_RECEIVE_FLOATING,
            TestConstants.ZERO, // idsIndex
            TestConstants.USD_50_000_18DEC, // collateral
            9870300000000000000000 * 10, // notional
            987030000000000000000, // ibtQuantity
            TestConstants.PERCENTAGE_4_18DEC, // fixedInterestRate
            TestConstants.TC_LIQUIDATION_DEPOSIT_AMOUNT_18DEC, // liquidationDepositAmount
            IporTypes.SwapState.ACTIVE
        );
        // when
        int256 swapValue = _iporSwapLogic.calculatePnlPayFixed(swap, swap.openTimestamp, 125 * TestConstants.D18);
        // then
        assertEq(swapValue, 24675750000000000000000);
    }

    function testShouldCalculateInterestWhen25DaysLaterIBTPriceHasNotChangedAnd18Decimals() public {
        // given
        AmmTypesGenOne.Swap memory swap = AmmTypesGenOne.Swap(
            TestConstants.ZERO, // id
            _admin, // buyer
            block.timestamp, // openTimestamp
            IporTypes.SwapTenor.DAYS_28,
            AmmTypes.SwapDirection.PAY_FIXED_RECEIVE_FLOATING,
            TestConstants.ZERO, // idsIndex
            TestConstants.USD_50_000_18DEC, // collateral
            9870300000000000000000 * 10, // notional
            987030000000000000000, // ibtQuantity
            TestConstants.PERCENTAGE_4_18DEC, // fixedInterestRate
            TestConstants.TC_LIQUIDATION_DEPOSIT_AMOUNT_18DEC, // liquidationDepositAmount
            IporTypes.SwapState.ACTIVE
        );
        // when
        int256 swapValue = _iporSwapLogic.calculatePnlPayFixed(
            swap,
            swap.openTimestamp + TestConstants.PERIOD_25_DAYS_IN_SECONDS,
            100 * TestConstants.D18
        );
        // then
        assertEq(swapValue, -270789953843120398784);
    }

    function testShouldCalculateInterestWhen25DaysLaterIBTPriceHasChangedAnd18Decimals() public {
        // given
        AmmTypesGenOne.Swap memory swap = AmmTypesGenOne.Swap(
            TestConstants.ZERO, // id
            _admin, // buyer
            block.timestamp, // openTimestamp
            IporTypes.SwapTenor.DAYS_28,
            AmmTypes.SwapDirection.PAY_FIXED_RECEIVE_FLOATING,
            TestConstants.ZERO, // idsIndex
            TestConstants.USD_50_000_18DEC, // collateral
            9870300000000000000000 * 10, // notional
            987030000000000000000, // ibtQuantity
            TestConstants.PERCENTAGE_4_18DEC, // fixedInterestRate
            TestConstants.TC_LIQUIDATION_DEPOSIT_AMOUNT_18DEC, // liquidationDepositAmount
            IporTypes.SwapState.ACTIVE
        );
        // when
        int256 swapValue = _iporSwapLogic.calculatePnlPayFixed(
            swap,
            swap.openTimestamp + TestConstants.PERIOD_25_DAYS_IN_SECONDS,
            125 * TestConstants.D18
        );
        // then
        assertEq(swapValue, 24404960046156879601216);
    }

    function testShouldCalculateInterestWhenHugeIPOR25DaysLaterAndIBTPriceChangedAndUserLosesAnd18Decimals() public {
        // given
        AmmTypesGenOne.Swap memory swap = AmmTypesGenOne.Swap(
            TestConstants.ZERO, // id
            _admin, // buyer
            block.timestamp, // openTimestamp
            IporTypes.SwapTenor.DAYS_28,
            AmmTypes.SwapDirection.PAY_FIXED_RECEIVE_FLOATING,
            TestConstants.ZERO, // idsIndex
            TestConstants.USD_50_000_18DEC, // collateral
            9870300000000000000000 * 10, // notional
            987030000000000000000, // ibtQuantity
            3650000000000000000 + TestConstants.PERCENTAGE_1_18DEC, // fixedInterestRate
            TestConstants.TC_LIQUIDATION_DEPOSIT_AMOUNT_18DEC, // liquidationDepositAmount
            IporTypes.SwapState.ACTIVE
        );
        // when
        int256 swapValue = _iporSwapLogic.calculatePnlPayFixed(
            swap,
            swap.openTimestamp + TestConstants.PERIOD_25_DAYS_IN_SECONDS,
            125 * TestConstants.D18
        );
        // then
        assertEq(swapValue, -3445246712749083726618);
    }

    function testShouldCalculateInterestWhen100DaysLaterIBTPriceHasNotChangedAnd18Decimals() public {
        // given
        AmmTypesGenOne.Swap memory swap = AmmTypesGenOne.Swap(
            TestConstants.ZERO, // id
            _admin, // buyer
            block.timestamp, // openTimestamp
            IporTypes.SwapTenor.DAYS_28,
            AmmTypes.SwapDirection.PAY_FIXED_RECEIVE_FLOATING,
            TestConstants.ZERO, // idsIndex
            TestConstants.USD_50_000_18DEC, // collateral
            9870300000000000000000 * 10, // notional
            987030000000000000000, // ibtQuantity
            TestConstants.PERCENTAGE_4_18DEC, // fixedInterestRate
            TestConstants.TC_LIQUIDATION_DEPOSIT_AMOUNT_18DEC, // liquidationDepositAmount
            IporTypes.SwapState.ACTIVE
        );
        // when
        int256 swapValue = _iporSwapLogic.calculatePnlPayFixed(
            swap,
            swap.openTimestamp + 4 * TestConstants.PERIOD_25_DAYS_IN_SECONDS,
            120 * TestConstants.D18
        );
        // then
        assertEq(swapValue, 18652974581413050198561);
    }

    function testShouldCalculateInterestWhen100DaysLaterIBTPriceHasChangedAnd18Decimals() public {
        // given
        AmmTypesGenOne.Swap memory swap = AmmTypesGenOne.Swap(
            TestConstants.ZERO, // id
            _admin, // buyer
            block.timestamp, // openTimestamp
            IporTypes.SwapTenor.DAYS_28,
            AmmTypes.SwapDirection.PAY_FIXED_RECEIVE_FLOATING,
            TestConstants.ZERO, // idsIndex
            TestConstants.USD_50_000_18DEC, // collateral
            9870300000000000000000 * 10, // notional
            987030000000000000000, // ibtQuantity
            TestConstants.PERCENTAGE_4_18DEC, // fixedInterestRate
            TestConstants.TC_LIQUIDATION_DEPOSIT_AMOUNT_18DEC, // liquidationDepositAmount
            IporTypes.SwapState.ACTIVE
        );
        // when
        int256 swapValue = _iporSwapLogic.calculatePnlPayFixed(
            swap,
            swap.openTimestamp + 4 * TestConstants.PERIOD_25_DAYS_IN_SECONDS,
            120 * TestConstants.D18
        );
        // then
        assertEq(swapValue, 18652974581413050198561);
    }

    function testShouldCalculateInterestWhen100DaysLaterIBTPriceHasChangedAnd6Decimals() public {
        // given
        AmmTypesGenOne.Swap memory swap = AmmTypesGenOne.Swap(
            TestConstants.ZERO, // id
            _admin, // buyer
            block.timestamp, // openTimestamp
            IporTypes.SwapTenor.DAYS_28,
            AmmTypes.SwapDirection.PAY_FIXED_RECEIVE_FLOATING,
            TestConstants.ZERO, // idsIndex
            TestConstants.USD_50_000_18DEC, // collateral
            9870300000000000000000 * 10, // notional
            987030000000000000000, // ibtQuantity
            TestConstants.PERCENTAGE_4_18DEC, // fixedInterestRate
            TestConstants.TC_LIQUIDATION_DEPOSIT_AMOUNT_18DEC, // liquidationDepositAmount
            IporTypes.SwapState.ACTIVE
        );
        // when
        int256 swapValue = _iporSwapLogic.calculatePnlPayFixed(
            swap,
            swap.openTimestamp + 4 * TestConstants.PERIOD_25_DAYS_IN_SECONDS,
            120 * TestConstants.D18
        );
        // then
        assertEq(swapValue, 18652974581413050198561);
    }
}

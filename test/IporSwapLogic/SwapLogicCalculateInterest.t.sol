// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.20;

import {DataUtils} from "../utils/DataUtils.sol";
import "../TestCommons.sol";
import "../utils/TestConstants.sol";
import "../mocks/MockIporSwapLogic.sol";
import "../../contracts/interfaces/types/IporTypes.sol";

contract IporSwapLogicCalculateInterest is TestCommons, DataUtils {
    MockIporSwapLogic internal _iporSwapLogic;

    function setUp() public {
        _iporSwapLogic = new MockIporSwapLogic();
    }

    function testShouldCalculateQuasiInterestWhenHugeIporAndIBTPriceChanges25DaysLaterAndUserLosesAnd18Decimals()
        public
    {
        // given
        AmmTypes.Swap memory swap = AmmTypes.Swap(
            TestConstants.ZERO, // id
            _admin, // buyer
            block.timestamp, // openTimestamp
            IporTypes.SwapTenor.DAYS_28,
            AmmTypes.SwapDirection.PAY_FIXED_RECEIVE_FLOATING,
            TestConstants.ZERO, // idsIndex
            TestConstants.USD_50_000_18DEC, // collateral
            9870300000000000000000 * 10, // notional
            987030000000000000000, // ibtQuantity
            365 * TestConstants.D16 + 1 * TestConstants.D16, // fixedInterestRate jjj
            TestConstants.TC_LIQUIDATION_DEPOSIT_AMOUNT_18DEC, // liquidationDepositAmount
            IporTypes.SwapState.ACTIVE
        );
        // when
        (uint256 iFixed, uint256 iFloating) = _iporSwapLogic.calculateInterest(
            swap,
            swap.openTimestamp + TestConstants.PERIOD_25_DAYS_IN_SECONDS,
            125 * TestConstants.D18
        );
        // then
        assertEq(iFixed, 126823996712749083726618);
        assertEq(iFloating, 123378750000000000000000);
    }

    function testShouldCalculateQuasiInterestWhenIBTPriceHasNotChanged100DaysLaterAnd18Decimals() public {
        // given
        AmmTypes.Swap memory swap = AmmTypes.Swap(
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
        (uint256 iFixed, uint256 iFloating) = _iporSwapLogic.calculateInterest(
            swap,
            swap.openTimestamp + TestConstants.PERIOD_25_DAYS_IN_SECONDS * 4,
            120 * TestConstants.D18
        );
        // then
        assertEq(iFixed, 99790625418586949801439);
        assertEq(iFloating, 118443600000000000000000);
    }

    function testShouldCalculateQuasiInterestCase1() public {
        // given
        AmmTypes.Swap memory swap = AmmTypes.Swap(
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
        (uint256 iFixed, uint256 iFloating) = _iporSwapLogic.calculateInterest(
            swap,
            swap.openTimestamp + TestConstants.SWAP_DEFAULT_PERIOD_IN_SECONDS,
            1 * TestConstants.D18
        );
        // then
        assertEq(iFixed, 99006334631564019729172);
        assertEq(iFloating, 987030000000000000000);
    }

    function testShouldRevertWhenClosingTimestampIsLowerThanOpenTimestamp() public {
        // given
        AmmTypes.Swap memory swap = AmmTypes.Swap(
            TestConstants.ZERO, // id
            _admin, // buyer
            block.timestamp + TestConstants.PERIOD_50_DAYS_IN_SECONDS, // openTimestamp
            IporTypes.SwapTenor.DAYS_90,
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
        vm.expectRevert("IPOR_319");
        _iporSwapLogic.calculateInterest(
            swap,
            swap.openTimestamp - TestConstants.SWAP_DEFAULT_PERIOD_IN_SECONDS,
            1 * TestConstants.D18
        );
    }

    function testShouldCalculateQuasiInterestCase2WhenSameTimestampAndIBTPriceIncreasesAnd18DecimalsCase1() public {
        // given
        AmmTypes.Swap memory swap = AmmTypes.Swap(
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
        (uint256 iFixed, uint256 iFloating) = _iporSwapLogic.calculateInterest(
            swap,
            swap.openTimestamp,
            125 * TestConstants.D18
        );
        // then
        assertEq(iFixed, 98703000000000000000000);
        assertEq(iFloating, 123378750000000000000000);
    }

    function testShouldCalculateQuasiInterestWhenIBTPriceHasNotChanged25DaysLaterAnd18Decimals() public {
        // given
        AmmTypes.Swap memory swap = AmmTypes.Swap(
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
        (uint256 iFixed, uint256 iFloating) = _iporSwapLogic.calculateInterest(
            swap,
            swap.openTimestamp + TestConstants.PERIOD_25_DAYS_IN_SECONDS,
            100 * TestConstants.D18
        );
        // then
        assertEq(iFixed, 98973789953843120398784);
        assertEq(iFloating, 98703000000000000000000);
    }

    function testShouldCalculateQuasiInterestWhenIBTPriceHasChanged25DaysLaterAnd18Decimals() public {
        // given
        AmmTypes.Swap memory swap = AmmTypes.Swap(
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
        (uint256 iFixed, uint256 iFloating) = _iporSwapLogic.calculateInterest(
            swap,
            swap.openTimestamp + TestConstants.PERIOD_25_DAYS_IN_SECONDS,
            125 * TestConstants.D18
        );
        // then
        assertEq(iFixed, 98973789953843120398784);
        assertEq(iFloating, 123378750000000000000000);
    }

    function testShouldCalculateQuasiInterestWhenIBTPriceHasChanged50DaysLaterAnd18Decimals() public {
        // given
        AmmTypes.Swap memory swap = AmmTypes.Swap(
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
        (uint256 iFixed, uint256 iFloating) = _iporSwapLogic.calculateInterest(
            swap,
            swap.openTimestamp + TestConstants.PERIOD_50_DAYS_IN_SECONDS,
            125 * TestConstants.D18
        );
        // then
        assertEq(iFixed, 99245322815187556454398);
        assertEq(iFloating, 123378750000000000000000);
    }

    function testShouldCalculateQuasiInterestWhenIBTPriceHasChanged50DaysLaterAnd6Decimals() public {
        // given
        AmmTypes.Swap memory swap = AmmTypes.Swap(
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
        (uint256 iFixed, uint256 iFloating) = _iporSwapLogic.calculateInterest(
            swap,
            swap.openTimestamp + TestConstants.PERIOD_50_DAYS_IN_SECONDS,
            125 * TestConstants.D18
        );
        // then
        assertEq(iFixed, 99245322815187556454398);
        assertEq(iFloating, 123378750000000000000000);
    }
}

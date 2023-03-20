// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.16;

import {DataUtils} from "../utils/DataUtils.sol";
import "../TestCommons.sol";
import "../utils/TestConstants.sol";
import "../../contracts/mocks/MockIporSwapLogic.sol";
import "../../contracts/interfaces/types/IporTypes.sol";

contract IporSwapLogicCalculateQuasiInterest is TestCommons, DataUtils {
    MockIporSwapLogic internal _iporSwapLogic;

    function setUp() public {
        _iporSwapLogic = new MockIporSwapLogic();
    }

    function testShouldCalculateQuasiInterestWhenHugeIporAndIBTPriceChanges25DaysLaterAndUserLosesAnd18Decimals()
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
            365 * TestConstants.D16 + 1 * TestConstants.D16, // fixedInterestRate jjj
            TestConstants.TC_LIQUIDATION_DEPOSIT_AMOUNT_18DEC, // liquidationDepositAmount
            1 // state
        );
        // when
        (uint256 quasiIFixed, uint256 quasiIFloating) = _iporSwapLogic.calculateQuasiInterest(
            swap, swap.openTimestamp + TestConstants.PERIOD_25_DAYS_IN_SECONDS, 125 * TestConstants.D18
        );
        // then
        assertEq(quasiIFixed, 3893004244800000000000000000000000000000000000000);
        assertEq(quasiIFloating, 3890872260000000000000000000000000000000000000000);
    }

    function testShouldCalculateQuasiInterestWhenIBTPriceHasNotChanged100DaysLaterAnd18Decimals() public {
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
        (uint256 quasiIFixed, uint256 quasiIFloating) = _iporSwapLogic.calculateQuasiInterest(
            swap, swap.openTimestamp + TestConstants.PERIOD_25_DAYS_IN_SECONDS * 4, 120 * TestConstants.D18
        );
        // then
        assertEq(quasiIFixed, 3146809564800000000000000000000000000000000000000);
        assertEq(quasiIFloating, 3735237369600000000000000000000000000000000000000);
    }

    function testShouldCalculateQuasiInterestCase1() public {
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
        (uint256 quasiIFixed, uint256 quasiIFloating) = _iporSwapLogic.calculateQuasiInterest(
            swap, swap.openTimestamp + TestConstants.SWAP_DEFAULT_PERIOD_IN_SECONDS, 1 * TestConstants.D18
        );
        // then
        assertEq(quasiIFixed, 3122249099904000000000000000000000000000000000000);
        assertEq(quasiIFloating, 31126978080000000000000000000000000000000000000);
    }

    function testShouldRevertWhenClosingTimestampIsLowerThanOpenTimestamp() public {
        // given
        IporTypes.IporSwapMemory memory swap = IporTypes.IporSwapMemory(
			TestConstants.ZERO, // id
			_admin, // buyer
			block.timestamp + TestConstants.PERIOD_50_DAYS_IN_SECONDS, // openTimestamp
			block.timestamp + TestConstants.PERIOD_75_DAYS_IN_SECONDS, // closeTimestamp
			TestConstants.ZERO, // idsIndex
			TestConstants.USD_50_000_18DEC, // collateral
			9870300000000000000000 * 10, // notional
			987030000000000000000, // ibtQuantity
			TestConstants.PERCENTAGE_4_18DEC, // fixedInterestRate
			TestConstants.TC_LIQUIDATION_DEPOSIT_AMOUNT_18DEC, // liquidationDepositAmount
			1 // state
		);
		// when
		vm.expectRevert("IPOR_319");
		_iporSwapLogic.calculateQuasiInterest(
			swap, 
			swap.openTimestamp - TestConstants.SWAP_DEFAULT_PERIOD_IN_SECONDS,
			1 * TestConstants.D18
		);
	}

    function testShouldCalculateQuasiInterestCase2WhenSameTimestampAndIBTPriceIncreasesAnd18DecimalsCase1() public {
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
        (uint256 quasiIFixed, uint256 quasiIFloating) =
            _iporSwapLogic.calculateQuasiInterest(swap, swap.openTimestamp, 125 * TestConstants.D18);
        // then
        assertEq(quasiIFixed, 3112697808000000000000000000000000000000000000000);
        assertEq(quasiIFloating, 3890872260000000000000000000000000000000000000000);
    }

    function testShouldCalculateQuasiInterestWhenIBTPriceHasNotChanged25DaysLaterAnd18Decimals() public {
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
        (uint256 quasiIFixed, uint256 quasiIFloating) = _iporSwapLogic.calculateQuasiInterest(
            swap, swap.openTimestamp + TestConstants.PERIOD_25_DAYS_IN_SECONDS, 100 * TestConstants.D18
        );
        // then
        assertEq(quasiIFixed, 3121225747200000000000000000000000000000000000000);
        assertEq(quasiIFloating, 3112697808000000000000000000000000000000000000000);
    }

    function testShouldCalculateQuasiInterestWhenIBTPriceHasChanged25DaysLaterAnd18Decimals() public {
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
        (uint256 quasiIFixed, uint256 quasiIFloating) = _iporSwapLogic.calculateQuasiInterest(
            swap, swap.openTimestamp + TestConstants.PERIOD_25_DAYS_IN_SECONDS, 125 * TestConstants.D18
        );
        // then
        assertEq(quasiIFixed, 3121225747200000000000000000000000000000000000000);
        assertEq(quasiIFloating, 3890872260000000000000000000000000000000000000000);
    }

    function testShouldCalculateQuasiInterestWhenIBTPriceHasChanged50DaysLaterAnd18Decimals() public {
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
        (uint256 quasiIFixed, uint256 quasiIFloating) = _iporSwapLogic.calculateQuasiInterest(
            swap, swap.openTimestamp + TestConstants.PERIOD_50_DAYS_IN_SECONDS, 125 * TestConstants.D18
        );
        // then
        assertEq(quasiIFixed, 3129753686400000000000000000000000000000000000000);
        assertEq(quasiIFloating, 3890872260000000000000000000000000000000000000000);
    }

    function testShouldCalculateQuasiInterestWhenIBTPriceHasChanged50DaysLaterAnd6Decimals() public {
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
        (uint256 quasiIFixed, uint256 quasiIFloating) = _iporSwapLogic.calculateQuasiInterest(
            swap, swap.openTimestamp + TestConstants.PERIOD_50_DAYS_IN_SECONDS, 125 * TestConstants.D18
        );
        // then
        assertEq(quasiIFixed, 3129753686400000000000000000000000000000000000000);
        assertEq(quasiIFloating, 3890872260000000000000000000000000000000000000000);
    }
}

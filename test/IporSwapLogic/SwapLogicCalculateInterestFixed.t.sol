// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.20;

import {DataUtils} from "../utils/DataUtils.sol";
import "test/TestCommons.sol";
import "../utils/TestConstants.sol";
import "test/mocks/MockIporSwapLogic.sol";

contract IporSwapLogicCalculateInterestFixed is TestCommons, DataUtils {
    MockIporSwapLogic internal _iporSwapLogic;

    function setUp() public {
        _iporSwapLogic = new MockIporSwapLogic();
    }

    function testShouldCalculateInterestFixedCase1() public {
        // given
        // when
        uint256 iFixed =
        _iporSwapLogic.calculateInterestFixed(98703 * TestConstants.D18, TestConstants.PERCENTAGE_4_18DEC, 0);
        // then
        assertEq(iFixed, 98703000000000000000000);
    }

    function testShouldCalculateInterestFixedCase2() public {
        // given
        // when
        uint256 iFixed = _iporSwapLogic.calculateInterestFixed(
            98703 * TestConstants.D18, TestConstants.PERCENTAGE_4_18DEC, TestConstants.SWAP_DEFAULT_PERIOD_IN_SECONDS
        );
        // then
        assertEq(iFixed, 99006334631564019729172);
    }

    function testShouldCalculateInterestFixedCase3() public {
        // given
        // when
        uint256 iFixed = _iporSwapLogic.calculateInterestFixed(
            98703 * TestConstants.D18, TestConstants.PERCENTAGE_4_18DEC, TestConstants.YEAR_IN_SECONDS
        );
        // then
        assertEq(iFixed, 102731145845111295248331);
    }
}

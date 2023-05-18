// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.16;

import {DataUtils} from "../utils/DataUtils.sol";
import "../TestCommons.sol";
import "../utils/TestConstants.sol";
import "contracts/mocks/MockIporSwapLogic.sol";

contract IporSwapLogicCalculateQuasiInterestFixed is TestCommons, DataUtils {
    MockIporSwapLogic internal _iporSwapLogic;

    function setUp() public {
        _iporSwapLogic = new MockIporSwapLogic();
    }

    function testShouldCalculateInterestFixedCase1() public {
        // given
        // when
        uint256 quasiIFixed =
            _iporSwapLogic.calculateQuasiInterestFixed(98703 * TestConstants.D18, TestConstants.PERCENTAGE_4_18DEC, 0);
        // then
        assertEq(quasiIFixed, 3112697808000000000000000000000000000000000000000);
    }

    function testShouldCalculateInterestFixedCase2() public {
        // given
        // when
        uint256 quasiIFixed = _iporSwapLogic.calculateQuasiInterestFixed(
            98703 * TestConstants.D18, TestConstants.PERCENTAGE_4_18DEC, TestConstants.SWAP_DEFAULT_PERIOD_IN_SECONDS
        );
        // then
        assertEq(quasiIFixed, 3122249099904000000000000000000000000000000000000);
    }

    function testShouldCalculateInterestFixedCase3() public {
        // given
        // when
        uint256 quasiIFixed = _iporSwapLogic.calculateQuasiInterestFixed(
            98703 * TestConstants.D18, TestConstants.PERCENTAGE_4_18DEC, TestConstants.YEAR_IN_SECONDS
        );
        // then
        assertEq(quasiIFixed, 3237205720320000000000000000000000000000000000000);
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.26;

import {DataUtils} from "../utils/DataUtils.sol";
import "../../test/TestCommons.sol";
import "../utils/TestConstants.sol";
import "../mocks/MockIporSwapLogic.sol";

contract IporSwapLogicCalculateInterestFloating is TestCommons, DataUtils {
    MockIporSwapLogic internal _iporSwapLogic;

    function setUp() public {
        _iporSwapLogic = new MockIporSwapLogic();
    }

    function testShouldCalculateInterestFloatingCase1() public {
        // given
        // when
        uint256 iFloating =
        _iporSwapLogic.calculateInterestFloating(987030000000000000000, 100 * TestConstants.D18);
        // then
        assertEq(iFloating, 98703000000000000000000);
    }

    function testShouldCalculateInterestFloatingCase2() public {
        // given
        // when
        uint256 iFloating =
        _iporSwapLogic.calculateInterestFloating(987030000000000000000, 150 * TestConstants.D18);
        // then
        assertEq(iFloating, 148054500000000000000000);
    }

    function testShouldCalculateInterestFloatingCase3() public {
        // given
        // when
        uint256 iFloating = _iporSwapLogic.calculateInterestFloating(987030000, 100 * TestConstants.D18);
        // then
        assertEq(iFloating, 98703000000);
    }

    function testShouldCalculateInterestFloatingCase4() public {
        // given
        // when
        uint256 iFloating =
        _iporSwapLogic.calculateInterestFloating(987030000, 150 * TestConstants.N1__0_6DEC);
        // then
        assertEq(iFloating, 0);
    }
}

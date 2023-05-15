// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.16;

import {DataUtils} from "../utils/DataUtils.sol";
import "../TestCommons.sol";
import "../utils/TestConstants.sol";
import "../../contracts/mocks/MockIporSwapLogic.sol";

contract IporSwapLogicCalculateQuasiInterestFloating is TestCommons, DataUtils {
    MockIporSwapLogic internal _iporSwapLogic;

    function setUp() public {
        _iporSwapLogic = new MockIporSwapLogic();
    }

    function testShouldCalculateInterestFloatingCase1() public {
        // given
        // when
        uint256 quasiIFloating =
            _iporSwapLogic.calculateQuasiInterestFloating(987030000000000000000, 100 * TestConstants.D18);
        // then
        assertEq(quasiIFloating, 3112697808000000000000000000000000000000000000000);
    }

    function testShouldCalculateInterestFloatingCase2() public {
        // given
        // when
        uint256 quasiIFloating =
            _iporSwapLogic.calculateQuasiInterestFloating(987030000000000000000, 150 * TestConstants.D18);
        // then
        assertEq(quasiIFloating, 4669046712000000000000000000000000000000000000000);
    }

    function testShouldCalculateInterestFloatingCase3() public {
        // given
        // when
        uint256 quasiIFloating = _iporSwapLogic.calculateQuasiInterestFloating(987030000, 100 * TestConstants.D18);
        // then
        assertEq(quasiIFloating, 3112697808000000000000000000000000000);
    }

    function testShouldCalculateInterestFloatingCase4() public {
        // given
        // when
        uint256 quasiIFloating =
            _iporSwapLogic.calculateQuasiInterestFloating(987030000, 150 * TestConstants.N1__0_6DEC);
        // then
        assertEq(quasiIFloating, 4669046712000000000000000);
    }
}

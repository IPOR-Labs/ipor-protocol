// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.16;

import "./TestCommons.sol";
import {DataUtils} from "./utils/DataUtils.sol";
import "./utils/TestConstants.sol";
import "../contracts/mocks/MockIporLogic.sol";
import "../contracts/interfaces/types/IporOracleTypes.sol";

contract IporLogicTest is TestCommons, DataUtils {
    MockIporLogic internal _iporLogic;

    function setUp() public {
        _iporLogic = new MockIporLogic();
    }

    function testShouldAccrueIbtPrice18Decimals() public {
        // given
        IporOracleTypes.IPOR memory ipor;
        ipor.quasiIbtPrice = uint128(TestConstants.YEAR_IN_SECONDS * TestConstants.D18);
        ipor.exponentialMovingAverage = uint64(TestConstants.P_0_3_DEC18);
        ipor.exponentialWeightedMovingVariance = uint64(TestConstants.P_0_3_DEC18);
        ipor.indexValue = uint64(TestConstants.P_0_3_DEC18);
        ipor.lastUpdateTimestamp = uint32(block.timestamp);
        uint256 accrueTimestamp = block.timestamp + TestConstants.PERIOD_25_DAYS_IN_SECONDS;
        // when
        uint256 accrueQuasiIbtPrice = _iporLogic.accrueQuasiIbtPrice(ipor, accrueTimestamp);
        // then
        assertEq(accrueQuasiIbtPrice, 31600800000000000000000000);
    }

    function testShouldAccrueIbtPriceWhen2Calculations18Decimals() public {
        // given
        IporOracleTypes.IPOR memory ipor;
        ipor.quasiIbtPrice = uint128(TestConstants.YEAR_IN_SECONDS * TestConstants.D18);
        ipor.exponentialMovingAverage = uint64(TestConstants.P_0_3_DEC18);
        ipor.exponentialWeightedMovingVariance = uint64(TestConstants.P_0_3_DEC18);
        ipor.indexValue = uint64(TestConstants.P_0_3_DEC18);
        ipor.lastUpdateTimestamp = uint32(block.timestamp);
        uint256 accrueTimestampFirst = block.timestamp + TestConstants.PERIOD_25_DAYS_IN_SECONDS;
        uint256 accrueTimestampSecond = block.timestamp + TestConstants.PERIOD_50_DAYS_IN_SECONDS;
        uint256 accrueQuasiIbtPriceFirst = _iporLogic.accrueQuasiIbtPrice(ipor, accrueTimestampFirst);
        // when
        uint256 accrueQuasiIbtPriceSecond = _iporLogic.accrueQuasiIbtPrice(ipor, accrueTimestampSecond);
        // then
        assertEq(accrueQuasiIbtPriceSecond, 31665600000000000000000000);
    }

    function testShouldCalculateExponentialMovingAverageWhen2Calculations18Decimals() public {
        // given
        uint256 exponentialMovingAverage = TestConstants.P_0_3_DEC18;
        uint256 indexValue = TestConstants.P_0_05_DEC18;
        uint256 alpha = TestConstants.P_0_01_DEC18;
        uint256 expectedExponentialMovingAverage = 49800000000000000;
        // when
        uint256 actualExponentialMovingAverage =
            _iporLogic.calculateExponentialMovingAverage(exponentialMovingAverage, indexValue, alpha);
        // then
        assertEq(actualExponentialMovingAverage, expectedExponentialMovingAverage);
    }

    function testShouldCalculateExponentialWeightedMovingVarianceWhenSimpleCase1And18Decimals() public {
        // given
        uint256 lastExponentialWeightedMovingVariance = TestConstants.ZERO;
        uint256 exponentialMovingAverage = 113000000000000000;
        uint256 indexValue = TestConstants.P_0_5_DEC18;
        uint256 alpha = TestConstants.P_0_1_DEC18;
        uint256 expectedExponentialWeightedMovingVariance = 13479210000000000;
        // when
        uint256 actualExponentialWeightedMovingVariance = _iporLogic.calculateExponentialWeightedMovingVariance(
            lastExponentialWeightedMovingVariance, exponentialMovingAverage, indexValue, alpha
        );
        // then
        assertEq(actualExponentialWeightedMovingVariance, expectedExponentialWeightedMovingVariance);
    }

    function testShouldCalculateExponentialWeightedMovingVarianceWhenTwoCalculationsAnd18Decimals() public {
        // given
        uint256 alpha = TestConstants.P_0_1_DEC18;
        uint256 firstExponentialWeightedMovingVariance = 13479210000000000;
        uint256 firstExponentialMovingAverage = TestConstants.P_0_005_DEC18;
        uint256 firstIndexValue = TestConstants.P_0_05_DEC18;
        uint256 expectedExponentialWeightedMovingVariance = 373539600000000;
        // first calculation
        uint256 actualFirstExponentialWeightedMovingVariance = _iporLogic.calculateExponentialWeightedMovingVariance(
            firstExponentialWeightedMovingVariance, firstExponentialMovingAverage, firstIndexValue, alpha
        );
        uint256 secondLastExponentialWeightedMovingVariance = actualFirstExponentialWeightedMovingVariance;
        uint256 secondExponentialMovingAverage = 10500000000000000;
        uint256 secondIndexValue = TestConstants.P_0_06_DEC18;
        // when
        // second calculation
        uint256 actualSecondExponentialWeightedMovingVariance = _iporLogic.calculateExponentialWeightedMovingVariance(
            secondLastExponentialWeightedMovingVariance, secondExponentialMovingAverage, secondIndexValue, alpha
        );
        // then
        assertEq(actualSecondExponentialWeightedMovingVariance, expectedExponentialWeightedMovingVariance);
    }

    function testShouldCalculateExponentialWeightedMovingVarianceWhenIporIndexIsLowerThanExponentialMovingAverageAnd18Decimals(
    ) public {
        // given
        uint256 alpha = TestConstants.P_0_1_DEC18;
        uint256 lastExponentialWeightedMovingVariance = 13479210000000000;
        uint256 exponentialMovingAverage = TestConstants.P_0_005_DEC18;
        uint256 indexValue = TestConstants.P_0_004_DEC18;
        uint256 expectedExponentialWeightedMovingVariance = 1348011000000000;
        // when
        uint256 actualExponentialWeightedMovingVariance = _iporLogic.calculateExponentialWeightedMovingVariance(
            lastExponentialWeightedMovingVariance, exponentialMovingAverage, indexValue, alpha
        );
        // then
        assertEq(actualExponentialWeightedMovingVariance, expectedExponentialWeightedMovingVariance);
    }

    function testShouldCalculateExponentialWeightedMovingVarianceWhenIporIndexIsEqualToExponentialMovingAverageAnd18Decimals(
    ) public {
        // given
        uint256 alpha = TestConstants.P_0_1_DEC18;
        uint256 lastExponentialWeightedMovingVariance = 13479210000000000;
        uint256 exponentialMovingAverage = TestConstants.P_0_005_DEC18;
        uint256 indexValue = TestConstants.P_0_005_DEC18;
        uint256 expectedExponentialWeightedMovingVariance = 1347921000000000;
        // when
        uint256 actualExponentialWeightedMovingVariance = _iporLogic.calculateExponentialWeightedMovingVariance(
            lastExponentialWeightedMovingVariance, exponentialMovingAverage, indexValue, alpha
        );
        // then
        assertEq(actualExponentialWeightedMovingVariance, expectedExponentialWeightedMovingVariance);
    }

    function testShouldCalculateExponentialWeightedMovingVarianceWhenIporIndexIsGreaterThanExponentialMovingAverageAndAlphaIsEqualToZeroAnd18Decimals(
    ) public {
        // given
        uint256 alpha = TestConstants.ZERO;
        uint256 lastExponentialWeightedMovingVariance = 13479210000000000;
        uint256 exponentialMovingAverage = TestConstants.P_0_005_DEC18;
        uint256 indexValue = TestConstants.P_0_006_DEC18;
        uint256 expectedExponentialWeightedMovingVariance = TestConstants.ZERO;
        // when
        uint256 actualExponentialWeightedMovingVariance = _iporLogic.calculateExponentialWeightedMovingVariance(
            lastExponentialWeightedMovingVariance, exponentialMovingAverage, indexValue, alpha
        );
        // then
        assertEq(actualExponentialWeightedMovingVariance, expectedExponentialWeightedMovingVariance);
    }

    function testShouldCalculateExponentialWeightedMovingVarianceWhenIporIndexIsGreaterThanExponentialMovingAverageAndAlphaIsEqualToOneAnd18Decimals(
    ) public {
        // given
        uint256 alpha = TestConstants.D18;
        uint256 lastExponentialWeightedMovingVariance = 13479210000000000;
        uint256 exponentialMovingAverage = TestConstants.P_0_005_DEC18;
        uint256 indexValue = TestConstants.P_0_006_DEC18;
        uint256 expectedExponentialWeightedMovingVariance = 13479210000000000;
        // when
        uint256 actualExponentialWeightedMovingVariance = _iporLogic.calculateExponentialWeightedMovingVariance(
            lastExponentialWeightedMovingVariance, exponentialMovingAverage, indexValue, alpha
        );
        // then
        assertEq(actualExponentialWeightedMovingVariance, expectedExponentialWeightedMovingVariance);
    }

    function testShouldNotCalculateExponentialWeightedMovingVarianceWhenExponentialWeightedMovingVarianceIsGreaterThanOneAnd18Decimals(
    ) public {
        // given
        uint256 alpha = 250000000000000000;
        uint256 lastExponentialWeightedMovingVariance = TestConstants.D18;
        uint256 exponentialMovingAverage = TestConstants.D18;
        uint256 indexValue = 4 * TestConstants.D18;
        // when
        vm.expectRevert("IPOR_324");
        _iporLogic.calculateExponentialWeightedMovingVariance(
            lastExponentialWeightedMovingVariance, exponentialMovingAverage, indexValue, alpha
        );
    }

    function testShouldNotCalculaetExponentialWeightedMovingVarianceWhenAlphaIsGreaterThanOneAnd18Decimals() public {
        // given
        uint256 alpha = 1000000000000000001;
        uint256 lastExponentialWeightedMovingVariance = TestConstants.ZERO;
        uint256 exponentialMovingAverage = 113000000000000000;
        uint256 indexValue = TestConstants.P_0_5_DEC18;
        // when
        vm.expectRevert("IPOR_325");
        _iporLogic.calculateExponentialWeightedMovingVariance(
            lastExponentialWeightedMovingVariance, exponentialMovingAverage, indexValue, alpha
        );
    }
}

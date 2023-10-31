// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.20;

import "./TestCommons.sol";
import "../contracts/oracles/libraries/IporLogic.sol";
import "./utils/TestConstants.sol";
import "../contracts/interfaces/types/IporOracleTypes.sol";

contract IporLogicTest is TestCommons {
//    function testShouldAccrueIbtPrice18Decimals() public {
//        // given
//        IporOracleTypes.IPOR memory ipor;
//        ipor.quasiIbtPrice = uint128(TestConstants.YEAR_IN_SECONDS * TestConstants.D18);
//        ipor.indexValue = uint64(TestConstants.P_0_3_DEC18);
//        ipor.lastUpdateTimestamp = uint32(block.timestamp);
//        uint256 accrueTimestamp = block.timestamp + TestConstants.PERIOD_25_DAYS_IN_SECONDS;
//        // when
//        uint256 accrueQuasiIbtPrice = IporLogic.accrueQuasiIbtPrice(ipor, accrueTimestamp);
//        // then
//        assertEq(accrueQuasiIbtPrice, 31600800000000000000000000);
//    }
//
//    function testShouldAccrueIbtPriceWhen2Calculations18Decimals() public {
//        // given
//        IporOracleTypes.IPOR memory ipor;
//        ipor.quasiIbtPrice = uint128(TestConstants.YEAR_IN_SECONDS * TestConstants.D18);
//        ipor.indexValue = uint64(TestConstants.P_0_3_DEC18);
//        ipor.lastUpdateTimestamp = uint32(block.timestamp);
//        uint256 accrueTimestampSecond = block.timestamp + TestConstants.PERIOD_50_DAYS_IN_SECONDS;
//        // when
//        uint256 accrueQuasiIbtPriceSecond = IporLogic.accrueQuasiIbtPrice(ipor, accrueTimestampSecond);
//        // then
//        assertEq(accrueQuasiIbtPriceSecond, 31665600000000000000000000);
//    }
}

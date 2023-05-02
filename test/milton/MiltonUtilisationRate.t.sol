// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.16;

import "../TestCommons.sol";
import {DataUtils} from "../utils/DataUtils.sol";
import {SwapUtils} from "../utils/SwapUtils.sol";
import "../utils/TestConstants.sol";

import "../../contracts/amm/MiltonStorage.sol";

contract MiltonUtilisationRateTest is TestCommons, DataUtils, SwapUtils {
    function setUp() public {
        _admin = address(this);
        _userOne = _getUserAddress(1);
        _userTwo = _getUserAddress(2);
        _userThree = _getUserAddress(3);
        _liquidityProvider = _getUserAddress(4);
        _users = usersToArray(_admin, _userOne, _userTwo, _userThree, _liquidityProvider);
    }

    function testShouldOpenPayFixedPositionWhenLiquidityPoolUtilizationPerLegIsNotExceededAndDefaultUtilization()
        public
    {
        // given
        IporProtocolFactory.IporProtocol memory iporProtocol;
        IporProtocolFactory.TestCaseConfig memory cfg;

        cfg.miltonTestCase = BuilderUtils.MiltonTestCase.CASE0;
        cfg.approvalsForUsers = _users;
        cfg.iporOracleUpdater = _userOne;

        iporProtocol = _iporProtocolFactory.getDaiInstance(cfg);

        iporProtocol.spreadModel.setCalculateQuotePayFixed(TestConstants.PERCENTAGE_4_18DEC);

        vm.prank(_userOne);
        iporProtocol.iporOracle.itfUpdateIndex(
            address(iporProtocol.asset),
            TestConstants.PERCENTAGE_3_18DEC,
            block.timestamp
        );

        vm.prank(_liquidityProvider);
        iporProtocol.joseph.itfProvideLiquidity(TestConstants.USD_28_000_18DEC, block.timestamp);

        // when
        vm.prank(_userTwo);
        iporProtocol.milton.itfOpenSwapPayFixed(
            block.timestamp,
            TestConstants.TC_TOTAL_AMOUNT_10_000_18DEC,
            TestConstants.PERCENTAGE_6_18DEC,
            TestConstants.LEVERAGE_18DEC
        );
    }

    function testShouldOpenReceiveFixedPositionWhenLiquidityPoolUtilizationPerLegIsNotExceededAndDefaultUtilization()
        public
    {
        // given
        IporProtocolFactory.IporProtocol memory iporProtocol;
        IporProtocolFactory.TestCaseConfig memory cfg;

        cfg.miltonTestCase = BuilderUtils.MiltonTestCase.CASE0;
        cfg.approvalsForUsers = _users;
        cfg.iporOracleUpdater = _userOne;

        iporProtocol = _iporProtocolFactory.getDaiInstance(cfg);

        iporProtocol.spreadModel.setCalculateQuoteReceiveFixed(TestConstants.PERCENTAGE_2_18DEC);

        vm.prank(_userOne);
        iporProtocol.iporOracle.itfUpdateIndex(
            address(iporProtocol.asset),
            TestConstants.PERCENTAGE_3_18DEC,
            block.timestamp
        );

        vm.prank(_liquidityProvider);
        iporProtocol.joseph.itfProvideLiquidity(TestConstants.USD_28_000_18DEC, block.timestamp);

        // when
        vm.prank(_userTwo);
        iporProtocol.milton.itfOpenSwapReceiveFixed(
            block.timestamp,
            TestConstants.TC_TOTAL_AMOUNT_10_000_18DEC,
            TestConstants.PERCENTAGE_1_18DEC,
            TestConstants.LEVERAGE_18DEC
        );
    }

    function testShouldOpenPayFixedPositionWhenLiquidityPoolUtilizationPerLegIsNotExceededAndCustomUtilization()
        public
    {
        // given
        IporProtocolFactory.IporProtocol memory iporProtocol;
        IporProtocolFactory.TestCaseConfig memory cfg;

        cfg.miltonTestCase = BuilderUtils.MiltonTestCase.CASE6;
        cfg.approvalsForUsers = _users;
        cfg.iporOracleUpdater = _userOne;

        iporProtocol = _iporProtocolFactory.getDaiInstance(cfg);

        iporProtocol.spreadModel.setCalculateQuotePayFixed(TestConstants.PERCENTAGE_4_18DEC);

        vm.prank(_userOne);
        iporProtocol.iporOracle.itfUpdateIndex(
            address(iporProtocol.asset),
            TestConstants.PERCENTAGE_3_18DEC,
            block.timestamp
        );
        vm.prank(_liquidityProvider);
        iporProtocol.joseph.itfProvideLiquidity(TestConstants.USD_100_000_18DEC, block.timestamp);

        // when
        vm.prank(_userTwo);
        iporProtocol.milton.itfOpenSwapPayFixed(
            block.timestamp,
            TestConstants.TC_TOTAL_AMOUNT_10_000_18DEC,
            TestConstants.PERCENTAGE_6_18DEC,
            TestConstants.LEVERAGE_18DEC
        );
    }

    function testShouldOpenReceiveFixedPositionWhenLiquidityPoolUtilizationPerLegIsNotExceededAndCustomUtilization()
        public
    {
        // given
        IporProtocolFactory.IporProtocol memory iporProtocol;
        IporProtocolFactory.TestCaseConfig memory cfg;

        cfg.miltonTestCase = BuilderUtils.MiltonTestCase.CASE6;
        cfg.approvalsForUsers = _users;
        cfg.iporOracleUpdater = _userOne;

        iporProtocol = _iporProtocolFactory.getDaiInstance(cfg);

        iporProtocol.spreadModel.setCalculateQuoteReceiveFixed(TestConstants.PERCENTAGE_2_18DEC);

        vm.prank(_userOne);
        iporProtocol.iporOracle.itfUpdateIndex(
            address(iporProtocol.asset),
            TestConstants.PERCENTAGE_3_18DEC,
            block.timestamp
        );

        vm.prank(_liquidityProvider);
        iporProtocol.joseph.itfProvideLiquidity(TestConstants.USD_100_000_18DEC, block.timestamp);

        // when
        vm.prank(_userTwo);
        iporProtocol.milton.itfOpenSwapReceiveFixed(
            block.timestamp,
            TestConstants.TC_TOTAL_AMOUNT_10_000_18DEC,
            TestConstants.PERCENTAGE_1_18DEC,
            TestConstants.LEVERAGE_18DEC
        );
    }

    function testShouldNotOpenPayFixedPositionWhenLiquidityPoolUtilizationPerLegIsExceededAndDefaultUtilization()
        public
    {
        // given
        IporProtocolFactory.IporProtocol memory iporProtocol;
        IporProtocolFactory.TestCaseConfig memory cfg;

        cfg.miltonTestCase = BuilderUtils.MiltonTestCase.CASE0;
        cfg.approvalsForUsers = _users;
        cfg.iporOracleUpdater = _userOne;

        iporProtocol = _iporProtocolFactory.getDaiInstance(cfg);

        vm.prank(_userOne);
        iporProtocol.iporOracle.itfUpdateIndex(
            address(iporProtocol.asset),
            TestConstants.PERCENTAGE_3_18DEC,
            block.timestamp
        );

        vm.prank(_liquidityProvider);
        iporProtocol.joseph.itfProvideLiquidity(TestConstants.USD_28_000_18DEC, block.timestamp);

        // when
        vm.expectRevert("IPOR_303");
        vm.prank(_userTwo);
        iporProtocol.milton.itfOpenSwapPayFixed(
            block.timestamp,
            14000 * TestConstants.D18,
            TestConstants.PERCENTAGE_6_18DEC,
            TestConstants.LEVERAGE_18DEC
        );
    }

    function testShouldNotOpenPayFixedPositionWhenLiquidityPoolUtilizationPerLegIsExceededAndCustomUtilization()
        public
    {
        // given
        IporProtocolFactory.IporProtocol memory iporProtocol;
        IporProtocolFactory.TestCaseConfig memory cfg;

        cfg.miltonTestCase = BuilderUtils.MiltonTestCase.CASE6;
        cfg.approvalsForUsers = _users;
        cfg.iporOracleUpdater = _userOne;

        iporProtocol = _iporProtocolFactory.getDaiInstance(cfg);

        vm.prank(_userOne);
        iporProtocol.iporOracle.itfUpdateIndex(
            address(iporProtocol.asset),
            TestConstants.PERCENTAGE_3_18DEC,
            block.timestamp
        );

        vm.prank(_liquidityProvider);
        iporProtocol.joseph.itfProvideLiquidity(TestConstants.USD_28_000_18DEC, block.timestamp);

        // when
        vm.expectRevert("IPOR_303");
        vm.prank(_userTwo);
        iporProtocol.milton.itfOpenSwapPayFixed(
            block.timestamp,
            TestConstants.TC_TOTAL_AMOUNT_10_000_18DEC,
            TestConstants.PERCENTAGE_6_18DEC,
            TestConstants.LEVERAGE_18DEC
        );
    }

    function testShouldNotOpenReceiveFixedPositionWhenLiquidityPoolUtilizationPerLegIsExceededAndDefaultUtilization()
        public
    {
        // given
        IporProtocolFactory.IporProtocol memory iporProtocol;
        IporProtocolFactory.TestCaseConfig memory cfg;

        cfg.miltonTestCase = BuilderUtils.MiltonTestCase.CASE0;
        cfg.approvalsForUsers = _users;
        cfg.iporOracleUpdater = _userOne;

        iporProtocol = _iporProtocolFactory.getDaiInstance(cfg);

        vm.prank(_userOne);
        iporProtocol.iporOracle.itfUpdateIndex(
            address(iporProtocol.asset),
            TestConstants.PERCENTAGE_3_18DEC,
            block.timestamp
        );

        vm.prank(_liquidityProvider);
        iporProtocol.joseph.itfProvideLiquidity(TestConstants.USD_28_000_18DEC, block.timestamp);

        // when
        vm.expectRevert("IPOR_303");
        vm.prank(_userTwo);
        iporProtocol.milton.itfOpenSwapReceiveFixed(
            block.timestamp,
            14000 * TestConstants.D18,
            TestConstants.PERCENTAGE_1_18DEC,
            TestConstants.LEVERAGE_18DEC
        );
    }

    function testShouldNotOpenReceiveFixedPositionWhenLiquidityPoolUtilizationPerLegIsExceededAndCustomUtilization()
        public
    {
        // given
        IporProtocolFactory.IporProtocol memory iporProtocol;
        IporProtocolFactory.TestCaseConfig memory cfg;

        cfg.miltonTestCase = BuilderUtils.MiltonTestCase.CASE6;
        cfg.approvalsForUsers = _users;
        cfg.iporOracleUpdater = _userOne;

        iporProtocol = _iporProtocolFactory.getDaiInstance(cfg);

        vm.prank(_userOne);
        iporProtocol.iporOracle.itfUpdateIndex(
            address(iporProtocol.asset),
            TestConstants.PERCENTAGE_3_18DEC,
            block.timestamp
        );

        vm.prank(_liquidityProvider);
        iporProtocol.joseph.itfProvideLiquidity(TestConstants.USD_28_000_18DEC, block.timestamp);

        // when
        vm.expectRevert("IPOR_303");
        vm.prank(_userTwo);
        iporProtocol.milton.itfOpenSwapReceiveFixed(
            block.timestamp,
            TestConstants.TC_TOTAL_AMOUNT_10_000_18DEC,
            TestConstants.PERCENTAGE_1_18DEC,
            TestConstants.LEVERAGE_18DEC
        );
    }
}

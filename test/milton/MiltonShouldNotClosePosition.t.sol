// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.16;

import "../TestCommons.sol";
import {DataUtils} from "../utils/DataUtils.sol";
import {SwapUtils} from "../utils/SwapUtils.sol";
import "../utils/TestConstants.sol";
import "../../contracts/amm/MiltonStorage.sol";
import "../../contracts/mocks/spread/MockSpreadModel.sol";

contract MiltonShouldNotClosePositionTest is TestCommons, DataUtils, SwapUtils {
    IporProtocolFactory.IporProtocolConfig private _cfg;
    IporProtocolBuilder.IporProtocol internal _iporProtocol;

    event Transfer(address indexed from, address indexed to, uint256 value);

    function setUp() public {
        _admin = address(this);
        _userOne = _getUserAddress(1);
        _userTwo = _getUserAddress(2);
        _userThree = _getUserAddress(3);
        _liquidityProvider = _getUserAddress(4);
        _users = usersToArray(_admin, _userOne, _userTwo, _userThree, _liquidityProvider);
        _cfg.approvalsForUsers = _users;
        _cfg.iporOracleUpdater = _userOne;
        _cfg.iporRiskManagementOracleUpdater = _userOne;

        _cfg.spreadImplementation = address(
            new MockSpreadModel(TestConstants.ZERO, TestConstants.ZERO, TestConstants.ZERO_INT, TestConstants.ZERO_INT)
        );
    }

    function testShouldNotClosePositionPayFixedDAIWhenNotOwnerAndMiltonLostAndUserEarnedLessThanCollateralBeforeMaturity()
        public
    {
        // given
        _cfg.iporOracleInitialParamsTestCase = BuilderUtils.IporOracleInitialParamsTestCase.CASE5;
        _cfg.miltonTestCase = BuilderUtils.MiltonTestCase.CASE0;
        _iporProtocol = _iporProtocolFactory.getDaiInstance(_cfg);
        _iporProtocol.spreadModel.setCalculateQuotePayFixed(TestConstants.PERCENTAGE_6_18DEC);

        uint256 endTimestamp = block.timestamp + TestConstants.PERIOD_25_DAYS_IN_SECONDS;

        vm.prank(_liquidityProvider);
        _iporProtocol.joseph.itfProvideLiquidity(TestConstants.USD_28_000_18DEC, block.timestamp);

        vm.prank(_userOne);
        _iporProtocol.iporOracle.itfUpdateIndex(
            address(_iporProtocol.asset),
            TestConstants.PERCENTAGE_5_18DEC,
            block.timestamp
        );

        vm.prank(_userTwo);
        _iporProtocol.milton.itfOpenSwapPayFixed(
            block.timestamp,
            TestConstants.TC_TOTAL_AMOUNT_10_000_18DEC,
            9 * TestConstants.D17,
            TestConstants.LEVERAGE_18DEC
        );

        vm.startPrank(_userOne);
        _iporProtocol.iporOracle.itfUpdateIndex(
            address(_iporProtocol.asset),
            TestConstants.PERCENTAGE_120_18DEC,
            block.timestamp
        );
        _iporProtocol.iporOracle.itfUpdateIndex(
            address(_iporProtocol.asset),
            TestConstants.PERCENTAGE_6_18DEC,
            endTimestamp
        );
        vm.stopPrank();

        // when
        vm.expectRevert("IPOR_331");
        vm.prank(_userThree);
        _iporProtocol.milton.itfCloseSwapPayFixed(1, endTimestamp);
    }

    function testShouldNotClosePositionPayFixedDAIWhenNotOwnerAndMiltonLostAndUserEarnedLessThanCollateral7HoursBeforeMaturity()
        public
    {
        // given
        _cfg.iporOracleInitialParamsTestCase = BuilderUtils.IporOracleInitialParamsTestCase.CASE5;
        _cfg.miltonTestCase = BuilderUtils.MiltonTestCase.CASE0;
        _iporProtocol = _iporProtocolFactory.getDaiInstance(_cfg);
        _iporProtocol.spreadModel.setCalculateQuotePayFixed(TestConstants.PERCENTAGE_6_18DEC);

        uint256 endTimestamp = block.timestamp + TestConstants.PERIOD_27_DAYS_17_HOURS_IN_SECONDS;

        vm.prank(_liquidityProvider);
        _iporProtocol.joseph.itfProvideLiquidity(TestConstants.USD_28_000_18DEC, block.timestamp);

        vm.prank(_userOne);
        _iporProtocol.iporOracle.itfUpdateIndex(
            address(_iporProtocol.asset),
            TestConstants.PERCENTAGE_5_18DEC,
            block.timestamp
        );

        vm.prank(_userTwo);
        _iporProtocol.milton.itfOpenSwapPayFixed(
            block.timestamp,
            TestConstants.TC_TOTAL_AMOUNT_10_000_18DEC,
            9 * TestConstants.D17,
            TestConstants.LEVERAGE_18DEC
        );

        vm.startPrank(_userOne);
        _iporProtocol.iporOracle.itfUpdateIndex(
            address(_iporProtocol.asset),
            TestConstants.PERCENTAGE_120_18DEC,
            block.timestamp
        );
        _iporProtocol.iporOracle.itfUpdateIndex(
            address(_iporProtocol.asset),
            TestConstants.PERCENTAGE_6_18DEC,
            endTimestamp
        );
        vm.stopPrank();

        // when
        vm.expectRevert("IPOR_331");
        vm.prank(_userThree);
        _iporProtocol.milton.itfCloseSwapPayFixed(1, endTimestamp);
    }

    function testShouldNotClosePositionPayFixedDAIWhenNotOwnerAndMiltonEarnedAndUserLostLessThanCollateralBeforeMaturity()
        public
    {
        // given
        _cfg.iporOracleInitialParamsTestCase = BuilderUtils.IporOracleInitialParamsTestCase.CASE4;
        _cfg.miltonTestCase = BuilderUtils.MiltonTestCase.CASE0;
        _iporProtocol = _iporProtocolFactory.getDaiInstance(_cfg);
        _iporProtocol.spreadModel.setCalculateQuotePayFixed(TestConstants.PERCENTAGE_121_18DEC);

        uint256 endTimestamp = block.timestamp + TestConstants.PERIOD_25_DAYS_IN_SECONDS;

        vm.prank(_liquidityProvider);
        _iporProtocol.joseph.itfProvideLiquidity(TestConstants.USD_28_000_18DEC, block.timestamp);

        vm.prank(_userOne);
        _iporProtocol.iporOracle.itfUpdateIndex(
            address(_iporProtocol.asset),
            TestConstants.PERCENTAGE_120_18DEC,
            block.timestamp
        );

        vm.prank(_userTwo);
        _iporProtocol.milton.itfOpenSwapPayFixed(
            block.timestamp,
            TestConstants.TC_TOTAL_AMOUNT_10_000_18DEC,
            TestConstants.PERCENTAGE_121_18DEC,
            TestConstants.LEVERAGE_18DEC
        );

        vm.startPrank(_userOne);
        _iporProtocol.iporOracle.itfUpdateIndex(
            address(_iporProtocol.asset),
            TestConstants.PERCENTAGE_5_18DEC,
            block.timestamp
        );
        _iporProtocol.iporOracle.itfUpdateIndex(
            address(_iporProtocol.asset),
            TestConstants.PERCENTAGE_6_18DEC,
            endTimestamp
        );
        vm.stopPrank();

        // when
        vm.expectRevert("IPOR_331");
        vm.prank(_userThree);
        _iporProtocol.milton.itfCloseSwapPayFixed(1, endTimestamp);
    }

    function testShouldNotClosePositionReceiveFixedDAIWhenNotOwnerAndMiltonLostAndUserEarnedLessThanCollateralBeforeMaturity()
        public
    {
        // given
        _cfg.iporOracleInitialParamsTestCase = BuilderUtils.IporOracleInitialParamsTestCase.CASE4;
        _cfg.miltonTestCase = BuilderUtils.MiltonTestCase.CASE0;
        _iporProtocol = _iporProtocolFactory.getDaiInstance(_cfg);
        _iporProtocol.spreadModel.setCalculateQuoteReceiveFixed(TestConstants.PERCENTAGE_119_18DEC);

        uint256 endTimestamp = block.timestamp + TestConstants.PERIOD_25_DAYS_IN_SECONDS;

        vm.prank(_liquidityProvider);
        _iporProtocol.joseph.itfProvideLiquidity(TestConstants.USD_28_000_18DEC, block.timestamp);

        vm.prank(_userOne);
        _iporProtocol.iporOracle.itfUpdateIndex(
            address(_iporProtocol.asset),
            TestConstants.PERCENTAGE_120_18DEC,
            block.timestamp
        );

        vm.prank(_userTwo);
        _iporProtocol.milton.itfOpenSwapReceiveFixed(
            block.timestamp,
            TestConstants.TC_TOTAL_AMOUNT_10_000_18DEC,
            TestConstants.PERCENTAGE_1_18DEC,
            TestConstants.LEVERAGE_18DEC
        );

        vm.startPrank(_userOne);
        _iporProtocol.iporOracle.itfUpdateIndex(
            address(_iporProtocol.asset),
            TestConstants.PERCENTAGE_5_18DEC,
            block.timestamp
        );
        _iporProtocol.iporOracle.itfUpdateIndex(
            address(_iporProtocol.asset),
            TestConstants.PERCENTAGE_6_18DEC,
            endTimestamp
        );
        vm.stopPrank();

        // when
        vm.expectRevert("IPOR_331");
        vm.prank(_userThree);
        _iporProtocol.milton.itfCloseSwapReceiveFixed(1, endTimestamp);
    }

    function testShouldNotClosePositionReceiveFixedDAIWhenNotOwnerAndMiltonLostAndUserEarnedLessThanCollateral7HoursBeforeMaturity()
        public
    {
        // given
        _cfg.iporOracleInitialParamsTestCase = BuilderUtils.IporOracleInitialParamsTestCase.CASE4;
        _cfg.miltonTestCase = BuilderUtils.MiltonTestCase.CASE0;
        _iporProtocol = _iporProtocolFactory.getDaiInstance(_cfg);
        _iporProtocol.spreadModel.setCalculateQuoteReceiveFixed(TestConstants.PERCENTAGE_119_18DEC);

        uint256 endTimestamp = block.timestamp + TestConstants.PERIOD_27_DAYS_17_HOURS_IN_SECONDS;

        vm.prank(_liquidityProvider);
        _iporProtocol.joseph.itfProvideLiquidity(TestConstants.USD_28_000_18DEC, block.timestamp);

        vm.prank(_userOne);
        _iporProtocol.iporOracle.itfUpdateIndex(
            address(_iporProtocol.asset),
            TestConstants.PERCENTAGE_120_18DEC,
            block.timestamp
        );

        vm.prank(_userTwo);
        _iporProtocol.milton.itfOpenSwapReceiveFixed(
            block.timestamp,
            TestConstants.TC_TOTAL_AMOUNT_10_000_18DEC,
            TestConstants.PERCENTAGE_1_18DEC,
            TestConstants.LEVERAGE_18DEC
        );

        vm.startPrank(_userOne);
        _iporProtocol.iporOracle.itfUpdateIndex(
            address(_iporProtocol.asset),
            TestConstants.PERCENTAGE_5_18DEC,
            block.timestamp
        );
        _iporProtocol.iporOracle.itfUpdateIndex(
            address(_iporProtocol.asset),
            TestConstants.PERCENTAGE_6_18DEC,
            endTimestamp
        );
        vm.stopPrank();

        // when
        vm.expectRevert("IPOR_331");
        vm.prank(_userThree);
        _iporProtocol.milton.itfCloseSwapReceiveFixed(1, endTimestamp);
    }

    function testShouldNotClosePositionReceiveFixedDAIWhenNotOwnerAndMiltonEarnedAndUserLostLessThanCollateralBeforeMaturity()
        public
    {
        // given
        _cfg.iporOracleInitialParamsTestCase = BuilderUtils.IporOracleInitialParamsTestCase.CASE5;
        _cfg.miltonTestCase = BuilderUtils.MiltonTestCase.CASE0;
        _iporProtocol = _iporProtocolFactory.getDaiInstance(_cfg);
        _iporProtocol.spreadModel.setCalculateQuoteReceiveFixed(TestConstants.PERCENTAGE_4_18DEC);

        uint256 endTimestamp = block.timestamp + TestConstants.PERIOD_25_DAYS_IN_SECONDS;

        vm.prank(_liquidityProvider);
        _iporProtocol.joseph.itfProvideLiquidity(TestConstants.USD_28_000_18DEC, block.timestamp);

        vm.prank(_userOne);
        _iporProtocol.iporOracle.itfUpdateIndex(
            address(_iporProtocol.asset),
            TestConstants.PERCENTAGE_5_18DEC,
            block.timestamp
        );

        vm.prank(_userTwo);
        _iporProtocol.milton.itfOpenSwapReceiveFixed(
            block.timestamp,
            TestConstants.TC_TOTAL_AMOUNT_10_000_18DEC,
            TestConstants.PERCENTAGE_1_18DEC,
            TestConstants.LEVERAGE_18DEC
        );

        vm.startPrank(_userOne);
        _iporProtocol.iporOracle.itfUpdateIndex(
            address(_iporProtocol.asset),
            TestConstants.PERCENTAGE_120_18DEC,
            block.timestamp
        );
        _iporProtocol.iporOracle.itfUpdateIndex(
            address(_iporProtocol.asset),
            TestConstants.PERCENTAGE_6_18DEC,
            endTimestamp
        );
        vm.stopPrank();

        // when
        vm.expectRevert("IPOR_331");
        vm.prank(_userThree);
        _iporProtocol.milton.itfCloseSwapReceiveFixed(1, endTimestamp);
    }

    function testShouldNotClosePositionPayFixedWhenIncorrectSwapId() public {
        // given
        _cfg.iporOracleInitialParamsTestCase = BuilderUtils.IporOracleInitialParamsTestCase.DEFAULT;
        _cfg.miltonTestCase = BuilderUtils.MiltonTestCase.CASE0;
        _iporProtocol = _iporProtocolFactory.getDaiInstance(_cfg);
        _iporProtocol.spreadModel.setCalculateQuotePayFixed(TestConstants.PERCENTAGE_4_18DEC);

        uint256 endTimestamp = block.timestamp + TestConstants.PERIOD_25_DAYS_IN_SECONDS;

        vm.prank(_userOne);
        _iporProtocol.iporOracle.itfUpdateIndex(
            address(_iporProtocol.asset),
            TestConstants.PERCENTAGE_3_18DEC,
            block.timestamp
        );

        vm.prank(_liquidityProvider);
        _iporProtocol.joseph.itfProvideLiquidity(TestConstants.USD_28_000_18DEC, block.timestamp);

        vm.prank(_userTwo);
        _iporProtocol.milton.itfOpenSwapPayFixed(
            block.timestamp,
            TestConstants.TC_TOTAL_AMOUNT_10_000_18DEC,
            9 * TestConstants.D17,
            TestConstants.LEVERAGE_18DEC
        );

        // when
        vm.expectRevert("IPOR_306");
        vm.prank(_userThree);
        _iporProtocol.milton.itfCloseSwapPayFixed(TestConstants.ZERO, endTimestamp);
    }

    function testShouldNotClosePositionPayFixedWhenIncorrectStatus() public {
        // given
        _cfg.iporOracleInitialParamsTestCase = BuilderUtils.IporOracleInitialParamsTestCase.DEFAULT;
        _cfg.miltonTestCase = BuilderUtils.MiltonTestCase.CASE0;
        _iporProtocol = _iporProtocolFactory.getDaiInstance(_cfg);
        _iporProtocol.spreadModel.setCalculateQuotePayFixed(TestConstants.PERCENTAGE_4_18DEC);

        uint256 endTimestamp = block.timestamp + TestConstants.PERIOD_50_DAYS_IN_SECONDS;

        vm.prank(_userOne);
        _iporProtocol.iporOracle.itfUpdateIndex(
            address(_iporProtocol.asset),
            TestConstants.PERCENTAGE_3_18DEC,
            block.timestamp
        );

        vm.prank(_liquidityProvider);
        _iporProtocol.joseph.itfProvideLiquidity(2 * TestConstants.USD_28_000_18DEC, block.timestamp);

        vm.prank(_userTwo);
        _iporProtocol.milton.itfOpenSwapPayFixed(
            block.timestamp,
            TestConstants.TC_TOTAL_AMOUNT_10_000_18DEC,
            9 * TestConstants.D17,
            TestConstants.LEVERAGE_18DEC
        );

        vm.prank(_userTwo);
        _iporProtocol.milton.itfOpenSwapPayFixed(
            block.timestamp + TestConstants.PERIOD_25_DAYS_IN_SECONDS,
            TestConstants.TC_TOTAL_AMOUNT_10_000_18DEC,
            9 * TestConstants.D17,
            TestConstants.LEVERAGE_18DEC
        );

        _iporProtocol.milton.addSwapLiquidator(_userThree);

        // when
        vm.startPrank(_userThree);
        _iporProtocol.milton.itfCloseSwapPayFixed(1, endTimestamp);
        vm.expectRevert("IPOR_307");
        _iporProtocol.milton.itfCloseSwapPayFixed(1, endTimestamp);
        vm.stopPrank();
    }

    function testShouldNotClosePositionReceiveFixedWhenIncorrectStatus() public {
        //given
        _cfg.iporOracleInitialParamsTestCase = BuilderUtils.IporOracleInitialParamsTestCase.DEFAULT;
        _cfg.miltonTestCase = BuilderUtils.MiltonTestCase.CASE0;
        _iporProtocol = _iporProtocolFactory.getDaiInstance(_cfg);
        _iporProtocol.spreadModel.setCalculateQuoteReceiveFixed(TestConstants.PERCENTAGE_2_18DEC);

        uint256 endTimestamp = block.timestamp + TestConstants.PERIOD_50_DAYS_IN_SECONDS;

        vm.prank(_userOne);
        _iporProtocol.iporOracle.itfUpdateIndex(
            address(_iporProtocol.asset),
            TestConstants.PERCENTAGE_3_18DEC,
            block.timestamp
        );

        vm.prank(_liquidityProvider);
        _iporProtocol.joseph.itfProvideLiquidity(2 * TestConstants.USD_28_000_18DEC, block.timestamp);

        vm.prank(_userTwo);
        _iporProtocol.milton.itfOpenSwapReceiveFixed(
            block.timestamp,
            TestConstants.TC_TOTAL_AMOUNT_10_000_18DEC,
            TestConstants.PERCENTAGE_1_18DEC,
            TestConstants.LEVERAGE_18DEC
        );

        vm.prank(_userTwo);
        _iporProtocol.milton.itfOpenSwapReceiveFixed(
            block.timestamp + TestConstants.PERIOD_25_DAYS_IN_SECONDS,
            TestConstants.TC_TOTAL_AMOUNT_10_000_18DEC,
            TestConstants.PERCENTAGE_1_18DEC,
            TestConstants.LEVERAGE_18DEC
        );

        _iporProtocol.milton.addSwapLiquidator(_userThree);

        // when
        vm.startPrank(_userThree);
        _iporProtocol.milton.itfCloseSwapReceiveFixed(1, endTimestamp);

        vm.expectRevert("IPOR_307");
        _iporProtocol.milton.itfCloseSwapReceiveFixed(1, endTimestamp);
        vm.stopPrank();
    }

    function testShouldNotClosepositionWhenSwapDoesNotExist() public {
        //given
        _cfg.iporOracleInitialParamsTestCase = BuilderUtils.IporOracleInitialParamsTestCase.DEFAULT;
        //        _cfg.miltonImplementation = address(new _iporProtocol.milton());
        _iporProtocol = _iporProtocolFactory.getDaiInstance(_cfg);

        uint256 endTimestamp = block.timestamp + TestConstants.PERIOD_25_DAYS_IN_SECONDS;

        // when
        vm.expectRevert("IPOR_306");
        vm.prank(_userThree);
        _iporProtocol.milton.itfCloseSwapPayFixed(TestConstants.ZERO, endTimestamp);
    }

    function testShouldNotClosePositionPayFixedSingleIdFunctionDAIWhenContractIsPaused() public {
        // given
        _cfg.iporOracleInitialParamsTestCase = BuilderUtils.IporOracleInitialParamsTestCase.CASE5;
        _cfg.miltonTestCase = BuilderUtils.MiltonTestCase.CASE3;
        _iporProtocol = _iporProtocolFactory.getDaiInstance(_cfg);
        _iporProtocol.spreadModel.setCalculateQuotePayFixed(TestConstants.PERCENTAGE_6_18DEC);

        uint256 endTimestamp = block.timestamp + TestConstants.PERIOD_25_DAYS_IN_SECONDS;

        vm.prank(_liquidityProvider);
        _iporProtocol.joseph.itfProvideLiquidity(TestConstants.USD_1_000_000_18DEC, block.timestamp);

        vm.prank(_userTwo);
        _iporProtocol.milton.itfOpenSwapPayFixed(
            block.timestamp,
            TestConstants.TC_TOTAL_AMOUNT_10_000_18DEC,
            9 * TestConstants.D17,
            TestConstants.LEVERAGE_18DEC
        );

        vm.prank(_userOne);
        _iporProtocol.iporOracle.itfUpdateIndex(
            address(_iporProtocol.asset),
            TestConstants.PERCENTAGE_160_18DEC,
            block.timestamp
        );

        vm.warp(endTimestamp);

        // when
        vm.prank(_admin);
        _iporProtocol.milton.pause();

        // then
        vm.expectRevert("Pausable: paused");
        vm.prank(_userTwo);
        _iporProtocol.milton.closeSwapPayFixed(1);
    }

    function testShouldNotClosePositionsPayFixedMultipleIdsFunctionDAIWhenContractIsPaused() public {
        // given
        _cfg.iporOracleInitialParamsTestCase = BuilderUtils.IporOracleInitialParamsTestCase.CASE5;
        _cfg.miltonTestCase = BuilderUtils.MiltonTestCase.CASE3;
        _iporProtocol = _iporProtocolFactory.getDaiInstance(_cfg);
        _iporProtocol.spreadModel.setCalculateQuotePayFixed(TestConstants.PERCENTAGE_6_18DEC);

        uint256 endTimestamp = block.timestamp + TestConstants.PERIOD_25_DAYS_IN_SECONDS;
        uint256 swapsToCreate = 1;

        vm.prank(_liquidityProvider);
        _iporProtocol.joseph.itfProvideLiquidity(TestConstants.USD_1_000_000_18DEC, block.timestamp);

        for (uint256 i = 0; i < swapsToCreate; i++) {
            vm.prank(_userTwo);
            _iporProtocol.milton.itfOpenSwapPayFixed(
                block.timestamp,
                TestConstants.TC_TOTAL_AMOUNT_10_000_18DEC,
                9 * TestConstants.D17,
                TestConstants.LEVERAGE_18DEC
            );
        }

        vm.prank(_userOne);
        _iporProtocol.iporOracle.itfUpdateIndex(
            address(_iporProtocol.asset),
            TestConstants.PERCENTAGE_160_18DEC,
            block.timestamp
        );

        vm.warp(endTimestamp);

        uint256[] memory payFixedSwapIds = new uint256[](swapsToCreate);
        payFixedSwapIds[0] = 1;

        uint256[] memory receiveFixedSwapIds;

        // when
        vm.prank(_admin);
        _iporProtocol.milton.pause();

        // then
        vm.expectRevert("Pausable: paused");
        vm.prank(_userTwo);
        _iporProtocol.milton.closeSwaps(payFixedSwapIds, receiveFixedSwapIds);
    }

    function testShouldNotClosePositionReceiveFixedSingleIdFunctionDAIWhenContractIsPaused() public {
        // given
        _cfg.iporOracleInitialParamsTestCase = BuilderUtils.IporOracleInitialParamsTestCase.CASE5;
        _cfg.miltonTestCase = BuilderUtils.MiltonTestCase.CASE3;
        _iporProtocol = _iporProtocolFactory.getDaiInstance(_cfg);
        _iporProtocol.spreadModel.setCalculateQuoteReceiveFixed(TestConstants.PERCENTAGE_4_18DEC);

        uint256 endTimestamp = block.timestamp + TestConstants.PERIOD_25_DAYS_IN_SECONDS;

        vm.prank(_liquidityProvider);
        _iporProtocol.joseph.itfProvideLiquidity(TestConstants.USD_1_000_000_18DEC, block.timestamp);

        vm.prank(_userTwo);
        _iporProtocol.milton.itfOpenSwapReceiveFixed(
            block.timestamp,
            TestConstants.TC_TOTAL_AMOUNT_10_000_18DEC,
            TestConstants.ZERO,
            TestConstants.LEVERAGE_18DEC
        );

        vm.prank(_userOne);
        _iporProtocol.iporOracle.itfUpdateIndex(
            address(_iporProtocol.asset),
            TestConstants.PERCENTAGE_160_18DEC,
            block.timestamp
        );

        vm.warp(endTimestamp);

        // when
        vm.prank(_admin);
        _iporProtocol.milton.pause();

        // then
        vm.expectRevert("Pausable: paused");
        vm.prank(_userTwo);
        _iporProtocol.milton.closeSwapReceiveFixed(1);
    }

    function testShouldNotClosePositionsReceiveFixedMultipleIdsFunctionDAIWhenContractIsPaused() public {
        // given
        _cfg.iporOracleInitialParamsTestCase = BuilderUtils.IporOracleInitialParamsTestCase.CASE5;
        _cfg.miltonTestCase = BuilderUtils.MiltonTestCase.CASE3;
        _iporProtocol = _iporProtocolFactory.getDaiInstance(_cfg);
        _iporProtocol.spreadModel.setCalculateQuoteReceiveFixed(TestConstants.PERCENTAGE_4_18DEC);

        uint256 endTimestamp = block.timestamp + TestConstants.PERIOD_25_DAYS_IN_SECONDS;
        uint256 swapsToCreate = 1;

        vm.prank(_liquidityProvider);
        _iporProtocol.joseph.itfProvideLiquidity(TestConstants.USD_1_000_000_18DEC, block.timestamp);

        for (uint256 i = 0; i < swapsToCreate; i++) {
            vm.prank(_userTwo);
            _iporProtocol.milton.itfOpenSwapReceiveFixed(
                block.timestamp,
                TestConstants.TC_TOTAL_AMOUNT_10_000_18DEC,
                TestConstants.ZERO,
                TestConstants.LEVERAGE_18DEC
            );
        }

        vm.prank(_userOne);
        _iporProtocol.iporOracle.itfUpdateIndex(
            address(_iporProtocol.asset),
            TestConstants.PERCENTAGE_160_18DEC,
            block.timestamp
        );

        vm.warp(endTimestamp);

        uint256[] memory receiveFixedSwapIds = new uint256[](swapsToCreate);
        receiveFixedSwapIds[0] = 1;

        uint256[] memory payFixedSwapIds;

        // when
        vm.prank(_admin);
        _iporProtocol.milton.pause();

        // then
        vm.expectRevert("Pausable: paused");
        vm.prank(_userTwo);
        _iporProtocol.milton.closeSwaps(payFixedSwapIds, receiveFixedSwapIds);
    }

    function testShouldNotClosePositionsPayFixedMultipleIdsWithEmergencyFunctionWhenContractIsPaused() public {
        // given
        _cfg.iporOracleInitialParamsTestCase = BuilderUtils.IporOracleInitialParamsTestCase.CASE5;
        _cfg.miltonTestCase = BuilderUtils.MiltonTestCase.CASE3;
        _iporProtocol = _iporProtocolFactory.getDaiInstance(_cfg);
        _iporProtocol.spreadModel.setCalculateQuotePayFixed(TestConstants.PERCENTAGE_6_18DEC);

        uint256 endTimestamp = block.timestamp + TestConstants.PERIOD_25_DAYS_IN_SECONDS;
        uint256 swapsToCreate = 1;

        vm.prank(_liquidityProvider);
        _iporProtocol.joseph.itfProvideLiquidity(TestConstants.USD_1_000_000_18DEC, block.timestamp);

        for (uint256 i = 0; i < swapsToCreate; i++) {
            vm.prank(_userTwo);
            _iporProtocol.milton.itfOpenSwapPayFixed(
                block.timestamp,
                TestConstants.TC_TOTAL_AMOUNT_10_000_18DEC,
                9 * TestConstants.D17,
                TestConstants.LEVERAGE_18DEC
            );
        }

        vm.prank(_userOne);
        _iporProtocol.iporOracle.itfUpdateIndex(
            address(_iporProtocol.asset),
            TestConstants.PERCENTAGE_160_18DEC,
            block.timestamp
        );

        vm.warp(endTimestamp);
        uint256[] memory payFixedSwapIds = new uint256[](swapsToCreate);
        payFixedSwapIds[0] = 1;

        // when
        vm.prank(_admin);
        _iporProtocol.milton.pause();

        // then
        vm.expectRevert("Ownable: caller is not the owner");
        vm.prank(_userTwo);
        _iporProtocol.milton.emergencyCloseSwapsPayFixed(payFixedSwapIds);
    }

    function testShouldNotClosePositionPayFixedSingleIdWithEmergencyFunctionWhenContractIsPaused() public {
        // given
        _cfg.iporOracleInitialParamsTestCase = BuilderUtils.IporOracleInitialParamsTestCase.CASE5;
        _cfg.miltonTestCase = BuilderUtils.MiltonTestCase.CASE3;
        _iporProtocol = _iporProtocolFactory.getDaiInstance(_cfg);
        _iporProtocol.spreadModel.setCalculateQuotePayFixed(TestConstants.PERCENTAGE_6_18DEC);

        uint256 endTimestamp = block.timestamp + TestConstants.PERIOD_25_DAYS_IN_SECONDS;

        vm.prank(_liquidityProvider);
        _iporProtocol.joseph.itfProvideLiquidity(TestConstants.USD_1_000_000_18DEC, block.timestamp);

        vm.prank(_userTwo);
        _iporProtocol.milton.itfOpenSwapPayFixed(
            block.timestamp,
            TestConstants.TC_TOTAL_AMOUNT_10_000_18DEC,
            9 * TestConstants.D17,
            TestConstants.LEVERAGE_18DEC
        );

        vm.prank(_userOne);
        _iporProtocol.iporOracle.itfUpdateIndex(
            address(_iporProtocol.asset),
            TestConstants.PERCENTAGE_160_18DEC,
            block.timestamp
        );
        vm.warp(endTimestamp);

        // when
        vm.prank(_admin);
        _iporProtocol.milton.pause();

        // then
        vm.expectRevert("Ownable: caller is not the owner");
        vm.prank(_userTwo);
        _iporProtocol.milton.emergencyCloseSwapPayFixed(1);
    }

    function testShouldNotClosePositionsReceiveFixedMultipleIdsWithEmergencyFunctionWhenContractIsPaused() public {
        // given
        _cfg.iporOracleInitialParamsTestCase = BuilderUtils.IporOracleInitialParamsTestCase.CASE5;
        _cfg.miltonTestCase = BuilderUtils.MiltonTestCase.CASE3;
        _iporProtocol = _iporProtocolFactory.getDaiInstance(_cfg);
        _iporProtocol.spreadModel.setCalculateQuoteReceiveFixed(TestConstants.PERCENTAGE_4_18DEC);

        uint256 endTimestamp = block.timestamp + TestConstants.PERIOD_25_DAYS_IN_SECONDS;
        uint256 swapsToCreate = 1;

        vm.prank(_liquidityProvider);
        _iporProtocol.joseph.itfProvideLiquidity(TestConstants.USD_1_000_000_18DEC, block.timestamp);

        iterateOpenSwapsReceiveFixed(
            _userTwo,
            _iporProtocol.milton,
            1,
            TestConstants.TC_TOTAL_AMOUNT_10_000_18DEC,
            TestConstants.LEVERAGE_18DEC
        );

        vm.prank(_userOne);
        _iporProtocol.iporOracle.itfUpdateIndex(
            address(_iporProtocol.asset),
            TestConstants.PERCENTAGE_160_18DEC,
            block.timestamp
        );

        vm.warp(endTimestamp);
        uint256[] memory receiveFixedSwapIds = new uint256[](swapsToCreate);
        receiveFixedSwapIds[0] = 1;

        // when
        vm.prank(_admin);
        _iporProtocol.milton.pause();

        // then
        vm.expectRevert("Ownable: caller is not the owner");
        vm.prank(_userTwo);
        _iporProtocol.milton.emergencyCloseSwapsReceiveFixed(receiveFixedSwapIds);
    }

    function testShouldNotClosePositionReceiveFixedSingleIdWithEmergencyFunctionWhenContractIsPaused() public {
        // given
        _cfg.iporOracleInitialParamsTestCase = BuilderUtils.IporOracleInitialParamsTestCase.CASE5;
        _cfg.miltonTestCase = BuilderUtils.MiltonTestCase.CASE3;
        _iporProtocol = _iporProtocolFactory.getDaiInstance(_cfg);
        _iporProtocol.spreadModel.setCalculateQuoteReceiveFixed(TestConstants.PERCENTAGE_4_18DEC);

        uint256 endTimestamp = block.timestamp + TestConstants.PERIOD_25_DAYS_IN_SECONDS;

        vm.prank(_liquidityProvider);
        _iporProtocol.joseph.itfProvideLiquidity(TestConstants.USD_1_000_000_18DEC, block.timestamp);

        vm.prank(_userTwo);
        _iporProtocol.milton.itfOpenSwapReceiveFixed(
            block.timestamp,
            TestConstants.TC_TOTAL_AMOUNT_10_000_18DEC,
            TestConstants.ZERO,
            TestConstants.LEVERAGE_18DEC
        );

        vm.prank(_userOne);
        _iporProtocol.iporOracle.itfUpdateIndex(
            address(_iporProtocol.asset),
            TestConstants.PERCENTAGE_160_18DEC,
            block.timestamp
        );

        vm.warp(endTimestamp);

        // when
        vm.prank(_admin);
        _iporProtocol.milton.pause();

        // then
        vm.expectRevert("Ownable: caller is not the owner");
        vm.prank(_userTwo);
        _iporProtocol.milton.emergencyCloseSwapReceiveFixed(1);
    }

    function testShouldNotClosePositionsByOwnerPayFixedMultipleIdsFunctionWithEmergencyFunctionWhenContractIsNotPaused()
        public
    {
        // given
        _cfg.iporOracleInitialParamsTestCase = BuilderUtils.IporOracleInitialParamsTestCase.CASE5;
        _cfg.miltonTestCase = BuilderUtils.MiltonTestCase.CASE3;
        _iporProtocol = _iporProtocolFactory.getDaiInstance(_cfg);
        _iporProtocol.spreadModel.setCalculateQuotePayFixed(TestConstants.PERCENTAGE_6_18DEC);

        uint256 endTimestamp = block.timestamp + TestConstants.PERIOD_25_DAYS_IN_SECONDS;
        uint256 swapsToCreate = 1;

        vm.prank(_liquidityProvider);
        _iporProtocol.joseph.itfProvideLiquidity(TestConstants.USD_1_000_000_18DEC, block.timestamp);

        for (uint256 i = 0; i < swapsToCreate; i++) {
            vm.prank(_userTwo);
            _iporProtocol.milton.itfOpenSwapPayFixed(
                block.timestamp,
                TestConstants.TC_TOTAL_AMOUNT_10_000_18DEC,
                9 * TestConstants.D17,
                TestConstants.LEVERAGE_18DEC
            );
        }

        vm.prank(_userOne);
        _iporProtocol.iporOracle.itfUpdateIndex(
            address(_iporProtocol.asset),
            TestConstants.PERCENTAGE_160_18DEC,
            block.timestamp
        );

        vm.warp(endTimestamp);
        uint256[] memory payFixedSwapIds = new uint256[](swapsToCreate);
        payFixedSwapIds[0] = 1;

        // when
        vm.expectRevert("Pausable: not paused");
        vm.prank(_admin);
        _iporProtocol.milton.emergencyCloseSwapsPayFixed(payFixedSwapIds);
    }

    function testShouldNotClosePositionByOwnerPayFixedSingleIdFunctionWithEmergencyFunctionWhenContractIsNotPaused()
        public
    {
        // given
        _cfg.iporOracleInitialParamsTestCase = BuilderUtils.IporOracleInitialParamsTestCase.CASE5;
        _cfg.miltonTestCase = BuilderUtils.MiltonTestCase.CASE3;
        _iporProtocol = _iporProtocolFactory.getDaiInstance(_cfg);
        _iporProtocol.spreadModel.setCalculateQuotePayFixed(TestConstants.PERCENTAGE_6_18DEC);

        uint256 endTimestamp = block.timestamp + TestConstants.PERIOD_25_DAYS_IN_SECONDS;

        vm.prank(_liquidityProvider);
        _iporProtocol.joseph.itfProvideLiquidity(TestConstants.USD_1_000_000_18DEC, block.timestamp);

        vm.prank(_userTwo);
        _iporProtocol.milton.itfOpenSwapPayFixed(
            block.timestamp,
            TestConstants.TC_TOTAL_AMOUNT_10_000_18DEC,
            9 * TestConstants.D17,
            TestConstants.LEVERAGE_18DEC
        );

        vm.prank(_userOne);
        _iporProtocol.iporOracle.itfUpdateIndex(
            address(_iporProtocol.asset),
            TestConstants.PERCENTAGE_160_18DEC,
            block.timestamp
        );

        vm.warp(endTimestamp);

        // when
        vm.expectRevert("Pausable: not paused");
        vm.prank(_admin);
        _iporProtocol.milton.emergencyCloseSwapPayFixed(1);
    }

    function testShouldNotClosePositionsReceiveFixedByOwnerMultipleIdsFunctionWithEmergencyFunctionWhenContractIsNotPaused()
        public
    {
        // given
        _cfg.iporOracleInitialParamsTestCase = BuilderUtils.IporOracleInitialParamsTestCase.CASE5;
        _cfg.miltonTestCase = BuilderUtils.MiltonTestCase.CASE3;
        _iporProtocol = _iporProtocolFactory.getDaiInstance(_cfg);
        _iporProtocol.spreadModel.setCalculateQuoteReceiveFixed(TestConstants.PERCENTAGE_4_18DEC);

        uint256 endTimestamp = block.timestamp + TestConstants.PERIOD_25_DAYS_IN_SECONDS;
        uint256 swapsToCreate = 1;
        prepareApproveForUsersDai(
            _users,
            _iporProtocol.asset,
            address(_iporProtocol.joseph),
            address(_iporProtocol.milton)
        );

        vm.prank(_liquidityProvider);
        _iporProtocol.joseph.itfProvideLiquidity(TestConstants.USD_1_000_000_18DEC, block.timestamp);

        for (uint256 i = 0; i < swapsToCreate; i++) {
            vm.prank(_userTwo);
            _iporProtocol.milton.itfOpenSwapReceiveFixed(
                block.timestamp,
                TestConstants.TC_TOTAL_AMOUNT_10_000_18DEC,
                TestConstants.ZERO,
                TestConstants.LEVERAGE_18DEC
            );
        }

        vm.prank(_userOne);
        _iporProtocol.iporOracle.itfUpdateIndex(
            address(_iporProtocol.asset),
            TestConstants.PERCENTAGE_160_18DEC,
            block.timestamp
        );

        vm.warp(endTimestamp);
        uint256[] memory receiveFixedSwapIds = new uint256[](swapsToCreate);
        receiveFixedSwapIds[0] = 1;

        // when
        vm.expectRevert("Pausable: not paused");
        vm.prank(_admin);
        _iporProtocol.milton.emergencyCloseSwapsReceiveFixed(receiveFixedSwapIds);
    }

    function testShouldNotClosePositionReceiveFixedByOwnerSingleIdFunctionWithEmergencyFunctionWhenContractIsNotPaused()
        public
    {
        // given
        _cfg.iporOracleInitialParamsTestCase = BuilderUtils.IporOracleInitialParamsTestCase.CASE5;
        _cfg.miltonTestCase = BuilderUtils.MiltonTestCase.CASE3;
        _iporProtocol = _iporProtocolFactory.getDaiInstance(_cfg);
        _iporProtocol.spreadModel.setCalculateQuoteReceiveFixed(TestConstants.PERCENTAGE_4_18DEC);

        uint256 endTimestamp = block.timestamp + TestConstants.PERIOD_25_DAYS_IN_SECONDS;

        vm.prank(_liquidityProvider);
        _iporProtocol.joseph.itfProvideLiquidity(TestConstants.USD_1_000_000_18DEC, block.timestamp);

        vm.prank(_userTwo);
        _iporProtocol.milton.itfOpenSwapReceiveFixed(
            block.timestamp,
            TestConstants.TC_TOTAL_AMOUNT_10_000_18DEC,
            TestConstants.ZERO,
            TestConstants.LEVERAGE_18DEC
        );

        vm.prank(_userOne);
        _iporProtocol.iporOracle.itfUpdateIndex(
            address(_iporProtocol.asset),
            TestConstants.PERCENTAGE_160_18DEC,
            block.timestamp
        );

        vm.warp(endTimestamp);

        // when
        vm.expectRevert("Pausable: not paused");
        vm.prank(_admin);
        _iporProtocol.milton.emergencyCloseSwapReceiveFixed(1);
    }

    function testShouldNotClosePositionDAIWhenERC20AmountExceedsMiltonBalanceOnDAIToken() public {
        // given
        _cfg.iporOracleInitialParamsTestCase = BuilderUtils.IporOracleInitialParamsTestCase.CASE5;
        _cfg.miltonTestCase = BuilderUtils.MiltonTestCase.CASE0;
        _iporProtocol = _iporProtocolFactory.getDaiInstance(_cfg);
        _iporProtocol.spreadModel.setCalculateQuotePayFixed(TestConstants.PERCENTAGE_6_18DEC);

        uint256 endTimestamp = block.timestamp + TestConstants.PERIOD_27_DAYS_17_HOURS_IN_SECONDS;

        vm.prank(_liquidityProvider);
        _iporProtocol.joseph.itfProvideLiquidity(TestConstants.USD_28_000_18DEC, block.timestamp);

        vm.prank(_userOne);
        _iporProtocol.iporOracle.itfUpdateIndex(
            address(_iporProtocol.asset),
            TestConstants.PERCENTAGE_5_18DEC,
            block.timestamp
        );

        vm.prank(_userTwo);
        _iporProtocol.milton.itfOpenSwapPayFixed(
            block.timestamp,
            TestConstants.TC_TOTAL_AMOUNT_10_000_18DEC,
            9 * TestConstants.D17,
            TestConstants.LEVERAGE_18DEC
        );

        vm.startPrank(_userOne);
        _iporProtocol.iporOracle.itfUpdateIndex(
            address(_iporProtocol.asset),
            TestConstants.PERCENTAGE_120_18DEC,
            block.timestamp
        );
        _iporProtocol.iporOracle.itfUpdateIndex(
            address(_iporProtocol.asset),
            TestConstants.PERCENTAGE_6_18DEC,
            endTimestamp
        );
        vm.stopPrank();

        deal(address(_iporProtocol.asset), address(_iporProtocol.milton), 6044629100000000000000000);
        uint256 miltonDaiBalanceAfterOpen = _iporProtocol.asset.balanceOf(address(_iporProtocol.milton));
        vm.prank(address(_iporProtocol.milton));
        _iporProtocol.asset.transfer(_admin, miltonDaiBalanceAfterOpen);

        // when
        vm.expectRevert("ERC20: transfer amount exceeds balance");
        vm.prank(_userTwo);
        _iporProtocol.milton.itfCloseSwapPayFixed(1, endTimestamp);
    }
}

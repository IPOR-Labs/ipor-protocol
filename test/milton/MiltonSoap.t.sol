// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.16;

import "../TestCommons.sol";
import {DataUtils} from "../utils/DataUtils.sol";
import {SwapUtils} from "../utils/SwapUtils.sol";
import "../utils/TestConstants.sol";
import "../../contracts/amm/MiltonStorage.sol";
import "../../contracts/itf/ItfIporOracle.sol";
import "../../contracts/tokens/IpToken.sol";
import "../../contracts/mocks/spread/MockSpreadModel.sol";
import "../../contracts/mocks/tokens/MockTestnetToken.sol";
import "../../contracts/mocks/stanley/MockCase0Stanley.sol";
import "../../contracts/mocks/stanley/MockCase1Stanley.sol";
import "../../contracts/mocks/milton/MockCase0MiltonDai.sol";
import "../../contracts/mocks/milton/MockCase0MiltonUsdt.sol";
import "../../contracts/mocks/joseph/MockCase0JosephDai.sol";
import "../../contracts/mocks/joseph/MockCase0JosephUsdt.sol";

contract MiltonSoapTest is TestCommons, DataUtils, SwapUtils {
    IporProtocolFactory.IporProtocolConfig private _cfg;
    IporProtocolFactory.AmmConfig private _ammCfg;
    IporProtocolBuilder.IporProtocol internal _iporProtocol;

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

        _ammCfg.iporOracleUpdater = _userOne;
        _ammCfg.iporRiskManagementOracleUpdater = _userOne;

        _ammCfg.miltonDaiTestCase = BuilderUtils.MiltonTestCase.CASE0;
        _ammCfg.miltonUsdcTestCase = BuilderUtils.MiltonTestCase.CASE0;
        _ammCfg.miltonUsdtTestCase = BuilderUtils.MiltonTestCase.CASE0;
    }

    function testShouldCalculateSoapWhenNoDerivativesSoapEqualZero() public {
        // given
        _cfg.iporOracleInitialParamsTestCase = BuilderUtils.IporOracleInitialParamsTestCase.CASE5;
        _cfg.miltonTestCase = BuilderUtils.MiltonTestCase.CASE0;
        _iporProtocol = _iporProtocolFactory.getDaiInstance(_cfg);

        // when
        (, , int256 soap) = calculateSoap(_userTwo, block.timestamp, _iporProtocol.milton);
        // then
        assertEq(soap, TestConstants.ZERO_INT);
    }

    function testShouldCalculateSoapDAIPayFixedWhenAddPositionThenCalculate() public {
        _cfg.iporOracleInitialParamsTestCase = BuilderUtils.IporOracleInitialParamsTestCase.CASE5;
        _cfg.miltonTestCase = BuilderUtils.MiltonTestCase.CASE0;
        _iporProtocol = _iporProtocolFactory.getDaiInstance(_cfg);
        _iporProtocol.spreadModel.setCalculateQuotePayFixed(TestConstants.PERCENTAGE_6_18DEC);

        vm.prank(_userOne);
        _iporProtocol.iporOracle.itfUpdateIndex(
            address(_iporProtocol.asset),
            TestConstants.PERCENTAGE_5_18DEC,
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
        (, , int256 soap) = calculateSoap(_userTwo, block.timestamp, _iporProtocol.milton);

        // then
        assertEq(soap, TestConstants.ZERO_INT);
    }

    function testShouldCalculateSoapDAIPayFixedWhenAddPositionThenCalculateAfter25Days() public {
        // given
        _cfg.iporOracleInitialParamsTestCase = BuilderUtils.IporOracleInitialParamsTestCase.DEFAULT;
        _cfg.miltonTestCase = BuilderUtils.MiltonTestCase.CASE0;
        _iporProtocol = _iporProtocolFactory.getDaiInstance(_cfg);
        _iporProtocol.spreadModel.setCalculateQuotePayFixed(TestConstants.PERCENTAGE_4_18DEC);

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

        int256 expectedSoapBalance = -68267191075554066595;

        // when
        (, , int256 soap) = calculateSoap(
            _userTwo,
            block.timestamp + TestConstants.PERIOD_25_DAYS_IN_SECONDS,
            _iporProtocol.milton
        );

        // then
        assertEq(soap, expectedSoapBalance);
    }

    function testShouldCalculateSoapDAIReceiveFixedWhenAddPositionThenCalculate() public {
        // given
        _cfg.iporOracleInitialParamsTestCase = BuilderUtils.IporOracleInitialParamsTestCase.DEFAULT;
        _cfg.miltonTestCase = BuilderUtils.MiltonTestCase.CASE0;
        _iporProtocol = _iporProtocolFactory.getDaiInstance(_cfg);
        _iporProtocol.spreadModel.setCalculateQuotePayFixed(TestConstants.ZERO);
        _iporProtocol.spreadModel.setCalculateQuoteReceiveFixed(TestConstants.PERCENTAGE_2_18DEC);

        vm.prank(_userOne);
        _iporProtocol.iporOracle.itfUpdateIndex(
            address(_iporProtocol.asset),
            TestConstants.PERCENTAGE_3_18DEC,
            block.timestamp
        );

        vm.prank(_liquidityProvider);
        _iporProtocol.joseph.itfProvideLiquidity(TestConstants.USD_28_000_18DEC, block.timestamp);

        vm.prank(_userTwo);
        _iporProtocol.milton.itfOpenSwapReceiveFixed(
            block.timestamp,
            TestConstants.TC_TOTAL_AMOUNT_10_000_18DEC,
            TestConstants.PERCENTAGE_1_18DEC,
            TestConstants.LEVERAGE_18DEC
        );

        int256 expectedSoapBalance = TestConstants.ZERO_INT;

        // when
        (, , int256 soap) = calculateSoap(_userTwo, block.timestamp, _iporProtocol.milton);

        // then
        assertEq(soap, expectedSoapBalance);
    }

    function testShouldCalculateSoapDAIReceiveFixedWhenAddPositionThenCalculateAfter25Days() public {
        // given
        _cfg.iporOracleInitialParamsTestCase = BuilderUtils.IporOracleInitialParamsTestCase.DEFAULT;
        _cfg.miltonTestCase = BuilderUtils.MiltonTestCase.CASE0;
        _iporProtocol = _iporProtocolFactory.getDaiInstance(_cfg);
        _iporProtocol.spreadModel.setCalculateQuotePayFixed(TestConstants.ZERO);
        _iporProtocol.spreadModel.setCalculateQuoteReceiveFixed(TestConstants.PERCENTAGE_2_18DEC);

        int256 expectedSoapBalance = -68267191075554025635;

        vm.prank(_liquidityProvider);
        _iporProtocol.joseph.itfProvideLiquidity(TestConstants.USD_28_000_18DEC, block.timestamp);

        vm.prank(_userOne);
        _iporProtocol.iporOracle.itfUpdateIndex(
            address(_iporProtocol.asset),
            TestConstants.PERCENTAGE_3_18DEC,
            block.timestamp
        );

        vm.prank(_userTwo);
        _iporProtocol.milton.itfOpenSwapReceiveFixed(
            block.timestamp,
            TestConstants.TC_TOTAL_AMOUNT_10_000_18DEC,
            TestConstants.PERCENTAGE_1_18DEC,
            TestConstants.LEVERAGE_18DEC
        );

        // when
        (, , int256 soap) = calculateSoap(
            _userTwo,
            block.timestamp + TestConstants.PERIOD_25_DAYS_IN_SECONDS,
            _iporProtocol.milton
        );

        // then
        assertEq(soap, expectedSoapBalance);
    }

    function testShouldCalculateSoapDAIPayFixedWhenAddAndRemovePosition() public {
        // given
        _cfg.iporOracleInitialParamsTestCase = BuilderUtils.IporOracleInitialParamsTestCase.DEFAULT;
        _cfg.miltonTestCase = BuilderUtils.MiltonTestCase.CASE0;
        _iporProtocol = _iporProtocolFactory.getDaiInstance(_cfg);
        _iporProtocol.spreadModel.setCalculateQuotePayFixed(TestConstants.PERCENTAGE_2_18DEC);
        _iporProtocol.spreadModel.setCalculateQuoteReceiveFixed(TestConstants.ZERO);

        int256 expectedSoapBalance = TestConstants.ZERO_INT;

        vm.prank(_liquidityProvider);
        _iporProtocol.joseph.itfProvideLiquidity(TestConstants.USD_28_000_18DEC, block.timestamp);

        vm.prank(_userOne);
        _iporProtocol.iporOracle.itfUpdateIndex(
            address(_iporProtocol.asset),
            TestConstants.PERCENTAGE_3_18DEC,
            block.timestamp
        );

        vm.prank(_userTwo);
        _iporProtocol.milton.itfOpenSwapPayFixed(
            block.timestamp,
            TestConstants.TC_TOTAL_AMOUNT_10_000_18DEC,
            9 * TestConstants.D17,
            TestConstants.LEVERAGE_18DEC
        );

        // when
        _iporProtocol.milton.itfCloseSwapPayFixed(1, block.timestamp + TestConstants.PERIOD_25_DAYS_IN_SECONDS);
        (, , int256 soap) = calculateSoap(
            _userTwo,
            block.timestamp + TestConstants.PERIOD_25_DAYS_IN_SECONDS,
            _iporProtocol.milton
        );

        // then
        assertEq(soap, expectedSoapBalance);
    }

    function testShouldCalculateSoapDAIReceiveFixedWhenAddAndRemovePosition() public {
        // given
        _cfg.iporOracleInitialParamsTestCase = BuilderUtils.IporOracleInitialParamsTestCase.DEFAULT;
        _cfg.miltonTestCase = BuilderUtils.MiltonTestCase.CASE0;
        _iporProtocol = _iporProtocolFactory.getDaiInstance(_cfg);
        _iporProtocol.spreadModel.setCalculateQuotePayFixed(TestConstants.ZERO);
        _iporProtocol.spreadModel.setCalculateQuoteReceiveFixed(TestConstants.PERCENTAGE_2_18DEC);

        int256 expectedSoapBalance = TestConstants.ZERO_INT;

        vm.prank(_liquidityProvider);
        _iporProtocol.joseph.itfProvideLiquidity(TestConstants.USD_28_000_18DEC, block.timestamp);

        vm.prank(_userOne);
        _iporProtocol.iporOracle.itfUpdateIndex(
            address(_iporProtocol.asset),
            TestConstants.PERCENTAGE_3_18DEC,
            block.timestamp
        );

        vm.prank(_userTwo);
        _iporProtocol.milton.itfOpenSwapReceiveFixed(
            block.timestamp,
            TestConstants.TC_TOTAL_AMOUNT_10_000_18DEC,
            TestConstants.PERCENTAGE_1_18DEC,
            TestConstants.LEVERAGE_18DEC
        );

        vm.prank(_liquidityProvider);
        _iporProtocol.joseph.itfProvideLiquidity(TestConstants.TC_TOTAL_AMOUNT_10_000_18DEC, block.timestamp);

        // when
        _iporProtocol.milton.itfCloseSwapReceiveFixed(1, block.timestamp + TestConstants.PERIOD_25_DAYS_IN_SECONDS);
        (, , int256 soap) = calculateSoap(
            _userTwo,
            block.timestamp + TestConstants.PERIOD_25_DAYS_IN_SECONDS,
            _iporProtocol.milton
        );

        // then
        assertEq(soap, expectedSoapBalance);
    }

    function testShouldCalculateSoapWhenDAIPayFixedAndDAIReceiveFixed18Decimals() public {
        // given
        _cfg.iporOracleInitialParamsTestCase = BuilderUtils.IporOracleInitialParamsTestCase.DEFAULT;
        _cfg.miltonTestCase = BuilderUtils.MiltonTestCase.CASE0;

        _iporProtocol = _iporProtocolFactory.getDaiInstance(_cfg);
        _iporProtocol.spreadModel.setCalculateQuotePayFixed(TestConstants.PERCENTAGE_4_18DEC);
        _iporProtocol.spreadModel.setCalculateQuoteReceiveFixed(TestConstants.PERCENTAGE_2_18DEC);

        int256 expectedSoapBalance = -136534382151108092230;

        vm.prank(_liquidityProvider);
        _iporProtocol.joseph.itfProvideLiquidity(2 * TestConstants.USD_28_000_18DEC, block.timestamp);

        vm.prank(_userOne);
        _iporProtocol.iporOracle.itfUpdateIndex(
            address(_iporProtocol.asset),
            TestConstants.PERCENTAGE_3_18DEC,
            block.timestamp
        );

        // when
        vm.prank(_userTwo);
        _iporProtocol.milton.itfOpenSwapPayFixed(
            block.timestamp,
            TestConstants.TC_TOTAL_AMOUNT_10_000_18DEC,
            9 * TestConstants.D17,
            TestConstants.LEVERAGE_18DEC
        );

        vm.prank(_userTwo);
        _iporProtocol.milton.itfOpenSwapReceiveFixed(
            block.timestamp,
            TestConstants.TC_TOTAL_AMOUNT_10_000_18DEC,
            TestConstants.PERCENTAGE_1_18DEC,
            TestConstants.LEVERAGE_18DEC
        );

        (, , int256 soap) = calculateSoap(
            _userTwo,
            block.timestamp + TestConstants.PERIOD_25_DAYS_IN_SECONDS,
            _iporProtocol.milton
        );

        // then
        assertEq(soap, expectedSoapBalance);
    }

    function testShouldCalculateSoapWhenUSDTPayFixedAndUSDTReceiveFixed6Decimals() public {
        // given
        _cfg.iporOracleInitialParamsTestCase = BuilderUtils.IporOracleInitialParamsTestCase.DEFAULT;
        _cfg.miltonTestCase = BuilderUtils.MiltonTestCase.CASE0;

        _iporProtocol = _iporProtocolFactory.getUsdtInstance(_cfg);
        _iporProtocol.spreadModel.setCalculateQuotePayFixed(TestConstants.PERCENTAGE_4_18DEC);
        _iporProtocol.spreadModel.setCalculateQuoteReceiveFixed(TestConstants.PERCENTAGE_2_18DEC);

        int256 expectedSoapBalance = -136534382151108092230;

        vm.prank(_liquidityProvider);
        _iporProtocol.joseph.itfProvideLiquidity(2 * TestConstants.USD_28_000_6DEC, block.timestamp);

        vm.prank(_userOne);
        _iporProtocol.iporOracle.itfUpdateIndex(
            address(_iporProtocol.asset),
            TestConstants.PERCENTAGE_3_18DEC,
            block.timestamp
        );

        vm.prank(_userTwo);
        _iporProtocol.milton.itfOpenSwapPayFixed(
            block.timestamp,
            TestConstants.TC_TOTAL_AMOUNT_10_000_6DEC,
            9 * TestConstants.D17,
            TestConstants.LEVERAGE_18DEC
        );

        vm.prank(_userTwo);
        _iporProtocol.milton.itfOpenSwapReceiveFixed(
            block.timestamp,
            TestConstants.TC_TOTAL_AMOUNT_10_000_6DEC,
            TestConstants.PERCENTAGE_1_18DEC,
            TestConstants.LEVERAGE_18DEC
        );

        (, , int256 soap) = calculateSoap(
            _userTwo,
            block.timestamp + TestConstants.PERIOD_25_DAYS_IN_SECONDS,
            _iporProtocol.milton
        );

        // then
        assertEq(soap, expectedSoapBalance);
    }

    function testShouldCalculateSoapWhenDAIPayFixedAndUSDTPayFixed() public {
        //given
        IporProtocolFactory.Amm memory amm = _iporProtocolFactory.getFullInstance(_ammCfg);

        IporProtocolBuilder.IporProtocol memory ammUsdt = amm.usdt;
        IporProtocolBuilder.IporProtocol memory ammDai = amm.dai;

        _iporProtocolFactory.setupUsers(_cfg, ammUsdt);
        _iporProtocolFactory.setupUsers(_cfg, ammDai);

        ammUsdt.spreadModel.setCalculateQuotePayFixed(TestConstants.PERCENTAGE_4_18DEC);
        ammUsdt.spreadModel.setCalculateQuoteReceiveFixed(TestConstants.ZERO);

        ammDai.spreadModel.setCalculateQuotePayFixed(TestConstants.PERCENTAGE_4_18DEC);
        ammDai.spreadModel.setCalculateQuoteReceiveFixed(TestConstants.ZERO);

        int256 expectedSoapUsdt = -68267191075554066595;
        int256 expectedSoapDai = -68267191075554066595;
        uint256 endTimestamp = block.timestamp + TestConstants.PERIOD_25_DAYS_IN_SECONDS;

        vm.startPrank(_liquidityProvider);
        ammUsdt.joseph.itfProvideLiquidity(TestConstants.USD_28_000_6DEC, block.timestamp);
        ammDai.joseph.itfProvideLiquidity(TestConstants.USD_28_000_18DEC, block.timestamp);
        vm.stopPrank();

        vm.startPrank(_userOne);
        amm.iporOracle.itfUpdateIndex(address(ammUsdt.asset), TestConstants.PERCENTAGE_3_18DEC, block.timestamp);
        amm.iporOracle.itfUpdateIndex(address(ammDai.asset), TestConstants.PERCENTAGE_3_18DEC, block.timestamp);
        vm.stopPrank();

        // when
        vm.prank(_userTwo);
        ammUsdt.milton.itfOpenSwapPayFixed(
            block.timestamp,
            TestConstants.TC_TOTAL_AMOUNT_10_000_6DEC,
            9 * TestConstants.D17,
            10 * Constants.D18
        );

        vm.prank(_userTwo);
        ammDai.milton.itfOpenSwapPayFixed(
            block.timestamp,
            TestConstants.TC_TOTAL_AMOUNT_10_000_18DEC,
            9 * TestConstants.D17,
            10 * Constants.D18
        );

        (, , int256 soapUsdt) = calculateSoap(_userTwo, endTimestamp, ammUsdt.milton);
        (, , int256 soapDai) = calculateSoap(_userTwo, endTimestamp, ammDai.milton);

        // then
        assertEq(soapUsdt, expectedSoapUsdt);
        assertEq(soapDai, expectedSoapDai);
    }

    function testShouldCalculateSoapWhenDAIPayFixedAndDAIReceiveFixedAndClosePayFixed() public {
        // given
        _cfg.iporOracleInitialParamsTestCase = BuilderUtils.IporOracleInitialParamsTestCase.DEFAULT;
        _cfg.miltonTestCase = BuilderUtils.MiltonTestCase.CASE0;

        _iporProtocol = _iporProtocolFactory.getDaiInstance(_cfg);
        _iporProtocol.spreadModel.setCalculateQuotePayFixed(TestConstants.PERCENTAGE_4_18DEC);
        _iporProtocol.spreadModel.setCalculateQuoteReceiveFixed(TestConstants.PERCENTAGE_2_18DEC);

        int256 expectedSoapBalance = -68267191075554025635;

        uint256 endTimestamp = block.timestamp + TestConstants.PERIOD_25_DAYS_IN_SECONDS;

        vm.prank(_liquidityProvider);
        _iporProtocol.joseph.itfProvideLiquidity(2 * TestConstants.USD_28_000_18DEC, block.timestamp);

        vm.prank(_userOne);
        _iporProtocol.iporOracle.itfUpdateIndex(
            address(_iporProtocol.asset),
            TestConstants.PERCENTAGE_3_18DEC,
            block.timestamp
        );

        vm.prank(_userTwo);
        _iporProtocol.milton.itfOpenSwapPayFixed(
            block.timestamp,
            TestConstants.TC_TOTAL_AMOUNT_10_000_18DEC,
            9 * TestConstants.D17,
            TestConstants.LEVERAGE_18DEC
        );

        vm.prank(_userTwo);
        _iporProtocol.milton.itfOpenSwapReceiveFixed(
            block.timestamp,
            TestConstants.TC_TOTAL_AMOUNT_10_000_18DEC,
            TestConstants.PERCENTAGE_1_18DEC,
            TestConstants.LEVERAGE_18DEC
        );

        // when
        _iporProtocol.milton.itfCloseSwapPayFixed(1, endTimestamp);
        (, , int256 soap) = calculateSoap(_userTwo, endTimestamp, _iporProtocol.milton);

        // then
        assertEq(soap, expectedSoapBalance);
    }

    function testShouldCalculateSoapWhenDAIPayFixedAndDAIReceiveFixedAndCloseReceiveFixed() public {
        // given
        _cfg.iporOracleInitialParamsTestCase = BuilderUtils.IporOracleInitialParamsTestCase.DEFAULT;
        _cfg.miltonTestCase = BuilderUtils.MiltonTestCase.CASE0;

        _iporProtocol = _iporProtocolFactory.getDaiInstance(_cfg);
        _iporProtocol.spreadModel.setCalculateQuotePayFixed(TestConstants.PERCENTAGE_4_18DEC);
        _iporProtocol.spreadModel.setCalculateQuoteReceiveFixed(TestConstants.PERCENTAGE_2_18DEC);

        int256 expectedSoapBalance = -68267191075554066595;

        uint256 endTimestamp = block.timestamp + TestConstants.PERIOD_25_DAYS_IN_SECONDS;

        vm.prank(_liquidityProvider);
        _iporProtocol.joseph.itfProvideLiquidity(2 * TestConstants.USD_28_000_18DEC, block.timestamp);

        vm.prank(_userOne);
        _iporProtocol.iporOracle.itfUpdateIndex(
            address(_iporProtocol.asset),
            TestConstants.PERCENTAGE_3_18DEC,
            block.timestamp
        );

        vm.prank(_userTwo);
        _iporProtocol.milton.itfOpenSwapPayFixed(
            block.timestamp,
            TestConstants.TC_TOTAL_AMOUNT_10_000_18DEC,
            9 * TestConstants.D17,
            TestConstants.LEVERAGE_18DEC
        );

        vm.prank(_userTwo);
        _iporProtocol.milton.itfOpenSwapReceiveFixed(
            block.timestamp,
            TestConstants.TC_TOTAL_AMOUNT_10_000_18DEC,
            TestConstants.PERCENTAGE_1_18DEC,
            TestConstants.LEVERAGE_18DEC
        );

        // when
        _iporProtocol.milton.itfCloseSwapReceiveFixed(2, endTimestamp);

        // then
        (, , int256 soap) = calculateSoap(_userTwo, endTimestamp, _iporProtocol.milton);
        assertEq(soap, expectedSoapBalance);
    }

    function testShouldCalculateSoapWhenDAIPayFixedAndUSDTReceiveFixedAndRemoveReceiveFixedPositionAfter25Days()
        public
    {
        // given
        IporProtocolFactory.Amm memory amm = _iporProtocolFactory.getFullInstance(_ammCfg);

        IporProtocolBuilder.IporProtocol memory ammUsdt = amm.usdt;
        IporProtocolBuilder.IporProtocol memory ammDai = amm.dai;

        _iporProtocolFactory.setupUsers(_cfg, ammUsdt);
        _iporProtocolFactory.setupUsers(_cfg, ammDai);

        amm.usdt.spreadModel.setCalculateQuotePayFixed(TestConstants.PERCENTAGE_4_18DEC);
        amm.usdt.spreadModel.setCalculateQuoteReceiveFixed(TestConstants.PERCENTAGE_2_18DEC);
        amm.dai.spreadModel.setCalculateQuotePayFixed(TestConstants.PERCENTAGE_4_18DEC);
        amm.dai.spreadModel.setCalculateQuoteReceiveFixed(TestConstants.PERCENTAGE_2_18DEC);

        int256 expectedSoapUsdt = TestConstants.ZERO_INT;
        int256 expectedSoapDai = -68267191075554066595;
        uint256 endTimestamp = block.timestamp + TestConstants.PERIOD_25_DAYS_IN_SECONDS;

        vm.startPrank(_liquidityProvider);
        ammUsdt.joseph.itfProvideLiquidity(TestConstants.USD_28_000_6DEC, block.timestamp);
        ammDai.joseph.itfProvideLiquidity(TestConstants.USD_28_000_18DEC, block.timestamp);
        vm.stopPrank();

        vm.startPrank(_userOne);
        amm.iporOracle.itfUpdateIndex(address(ammUsdt.asset), TestConstants.PERCENTAGE_3_18DEC, block.timestamp);
        amm.iporOracle.itfUpdateIndex(address(ammDai.asset), TestConstants.PERCENTAGE_3_18DEC, block.timestamp);
        vm.stopPrank();

        vm.prank(_userTwo);
        ammUsdt.milton.itfOpenSwapReceiveFixed(
            block.timestamp,
            TestConstants.TC_TOTAL_AMOUNT_10_000_6DEC,
            TestConstants.PERCENTAGE_1_18DEC,
            TestConstants.LEVERAGE_18DEC
        );

        vm.prank(_userTwo);
        ammDai.milton.itfOpenSwapPayFixed(
            block.timestamp,
            TestConstants.TC_TOTAL_AMOUNT_10_000_18DEC,
            9 * TestConstants.D17,
            TestConstants.LEVERAGE_18DEC
        );

        vm.prank(_liquidityProvider);
        ammUsdt.joseph.itfProvideLiquidity(TestConstants.TC_TOTAL_AMOUNT_10_000_6DEC, block.timestamp);

        // when
        ammUsdt.milton.itfCloseSwapReceiveFixed(1, endTimestamp);

        // then
        (, , int256 soapUsdt) = calculateSoap(_userTwo, endTimestamp, ammUsdt.milton);
        (, , int256 soapDai) = calculateSoap(_userTwo, endTimestamp, ammDai.milton);
        assertEq(soapUsdt, expectedSoapUsdt);
        assertEq(soapDai, expectedSoapDai);
    }

    function testShouldCalculateSoapWhenDAIPayFixedAndChangeIbtPriceAndWait25DaysAndThenCalculateSoap18Decimals()
        public
    {
        // given
        _cfg.iporOracleInitialParamsTestCase = BuilderUtils.IporOracleInitialParamsTestCase.DEFAULT;
        _cfg.miltonTestCase = BuilderUtils.MiltonTestCase.CASE0;

        _iporProtocol = _iporProtocolFactory.getDaiInstance(_cfg);
        _iporProtocol.spreadModel.setCalculateQuotePayFixed(TestConstants.PERCENTAGE_4_18DEC);
        _iporProtocol.spreadModel.setCalculateQuoteReceiveFixed(TestConstants.ZERO);

        int256 expectedSoapBalance = 7918994164764269327487;
        uint256 endTimestamp = block.timestamp + TestConstants.PERIOD_25_DAYS_IN_SECONDS;

        vm.prank(_liquidityProvider);
        _iporProtocol.joseph.itfProvideLiquidity(TestConstants.USD_28_000_18DEC, block.timestamp);

        vm.prank(_userOne);
        _iporProtocol.iporOracle.itfUpdateIndex(
            address(_iporProtocol.asset),
            TestConstants.PERCENTAGE_3_18DEC,
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
        (, , int256 soap) = calculateSoap(_userTwo, endTimestamp, _iporProtocol.milton);

        // then
        assertEq(soap, expectedSoapBalance);
    }

    function testShouldCalculateSoapWhenUSDTPayFixedAndChangeIbtPriceAndWait25DaysAndThenCalculateSoap6Decimals()
        public
    {
        // given
        _cfg.iporOracleInitialParamsTestCase = BuilderUtils.IporOracleInitialParamsTestCase.DEFAULT;
        _cfg.miltonTestCase = BuilderUtils.MiltonTestCase.CASE0;

        _iporProtocol = _iporProtocolFactory.getUsdtInstance(_cfg);
        _iporProtocol.spreadModel.setCalculateQuotePayFixed(TestConstants.PERCENTAGE_4_18DEC);
        _iporProtocol.spreadModel.setCalculateQuoteReceiveFixed(TestConstants.ZERO);

        int256 expectedSoapBalance = 7918994164764269327487;
        uint256 endTimestamp = block.timestamp + TestConstants.PERIOD_25_DAYS_IN_SECONDS;

        vm.prank(_userOne);
        _iporProtocol.iporOracle.itfUpdateIndex(
            address(_iporProtocol.asset),
            TestConstants.PERCENTAGE_3_18DEC,
            block.timestamp
        );

        vm.prank(_liquidityProvider);
        _iporProtocol.joseph.itfProvideLiquidity(TestConstants.USD_28_000_6DEC, block.timestamp);

        vm.prank(_userTwo);
        _iporProtocol.milton.itfOpenSwapPayFixed(
            block.timestamp,
            TestConstants.TC_TOTAL_AMOUNT_10_000_6DEC,
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
        (, , int256 soap) = calculateSoap(_userTwo, endTimestamp, _iporProtocol.milton);

        // then
        assertEq(soap, expectedSoapBalance);
    }

    function testShouldCalculateSoapWhenDAIPayFixedAndChangeIbtPriceAndCalculateSoapAfter28DaysAndCalculateSoapAfter50DaysAndCompare()
        public
    {
        // given
        _cfg.iporOracleInitialParamsTestCase = BuilderUtils.IporOracleInitialParamsTestCase.DEFAULT;
        _cfg.miltonTestCase = BuilderUtils.MiltonTestCase.CASE0;

        _iporProtocol = _iporProtocolFactory.getDaiInstance(_cfg);
        _iporProtocol.spreadModel.setCalculateQuotePayFixed(TestConstants.PERCENTAGE_4_18DEC);
        _iporProtocol.spreadModel.setCalculateQuoteReceiveFixed(TestConstants.ZERO);

        int256 expectedSoapBalanceAfter28Days = 7935378290622402313573;
        int256 expectedSoapBalanceAfter50Days = 8055528546915377478426;

        vm.prank(_liquidityProvider);
        _iporProtocol.joseph.itfProvideLiquidity(TestConstants.USD_28_000_18DEC, block.timestamp);

        vm.prank(_userOne);
        _iporProtocol.iporOracle.itfUpdateIndex(
            address(_iporProtocol.asset),
            TestConstants.PERCENTAGE_3_18DEC,
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
            block.timestamp + TestConstants.PERIOD_25_DAYS_IN_SECONDS
        );
        vm.stopPrank();

        // when

        // then
        (, , int256 soap28Days) = calculateSoap(
            _userTwo,
            block.timestamp + TestConstants.PERIOD_28_DAYS_IN_SECONDS,
            _iporProtocol.milton
        );

        assertEq(soap28Days, expectedSoapBalanceAfter28Days);
        (, , int256 soap50Days) = calculateSoap(
            _userTwo,
            block.timestamp + TestConstants.PERIOD_50_DAYS_IN_SECONDS,
            _iporProtocol.milton
        );
        assertEq(soap50Days, expectedSoapBalanceAfter50Days);
    }

    function testShouldCalculateSoapWhenDAIPayFixedAndWait25DaysAndDAIPayFixedAndWait25DaysAndThenCalculateSoap()
        public
    {
        // given
        _cfg.iporOracleInitialParamsTestCase = BuilderUtils.IporOracleInitialParamsTestCase.DEFAULT;
        _cfg.miltonTestCase = BuilderUtils.MiltonTestCase.CASE0;

        _iporProtocol = _iporProtocolFactory.getDaiInstance(_cfg);
        _iporProtocol.spreadModel.setCalculateQuotePayFixed(TestConstants.PERCENTAGE_4_18DEC);
        _iporProtocol.spreadModel.setCalculateQuoteReceiveFixed(TestConstants.ZERO);

        int256 expectedSoapBalanceAfter50Days = -205221535441070939562;

        vm.prank(_liquidityProvider);
        _iporProtocol.joseph.itfProvideLiquidity(2 * TestConstants.USD_28_000_18DEC, block.timestamp);

        // when
        vm.prank(_userOne);
        _iporProtocol.iporOracle.itfUpdateIndex(
            address(_iporProtocol.asset),
            TestConstants.PERCENTAGE_3_18DEC,
            block.timestamp
        );

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

        // then
        (, , int256 soap50Days) = calculateSoap(
            _userTwo,
            block.timestamp + TestConstants.PERIOD_50_DAYS_IN_SECONDS,
            _iporProtocol.milton
        );
        assertEq(soap50Days, expectedSoapBalanceAfter50Days);
    }

    function testShouldCalculateSoapWhenDAYPayFixedAndWait25DaysAndUpdateIPORAndDAIPayFixedAndWait25DaysAndUpdateIPORAndThenCalculateSoap()
        public
    {
        // given
        _cfg.iporOracleInitialParamsTestCase = BuilderUtils.IporOracleInitialParamsTestCase.DEFAULT;
        _cfg.miltonTestCase = BuilderUtils.MiltonTestCase.CASE0;

        _iporProtocol = _iporProtocolFactory.getDaiInstance(_cfg);
        _iporProtocol.spreadModel.setCalculateQuotePayFixed(TestConstants.PERCENTAGE_4_18DEC);
        _iporProtocol.spreadModel.setCalculateQuoteReceiveFixed(TestConstants.ZERO);

        int256 expectedSoapBalanceAfter50Days = -205221535441070939562;

        vm.prank(_liquidityProvider);
        _iporProtocol.joseph.itfProvideLiquidity(2 * TestConstants.USD_28_000_18DEC, block.timestamp);

        // when
        vm.prank(_userOne);
        _iporProtocol.iporOracle.itfUpdateIndex(
            address(_iporProtocol.asset),
            TestConstants.PERCENTAGE_3_18DEC,
            block.timestamp
        );

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
            TestConstants.PERCENTAGE_3_18DEC,
            block.timestamp + TestConstants.PERIOD_25_DAYS_IN_SECONDS
        );

        vm.prank(_userTwo);
        _iporProtocol.milton.itfOpenSwapPayFixed(
            block.timestamp + TestConstants.PERIOD_25_DAYS_IN_SECONDS,
            TestConstants.TC_TOTAL_AMOUNT_10_000_18DEC,
            9 * TestConstants.D17,
            10 * Constants.D18
        );

        vm.prank(_userOne);
        _iporProtocol.iporOracle.itfUpdateIndex(
            address(_iporProtocol.asset),
            TestConstants.PERCENTAGE_3_18DEC,
            block.timestamp + TestConstants.PERIOD_50_DAYS_IN_SECONDS
        );

        // then
        (, , int256 soap50Days) = calculateSoap(
            _userTwo,
            block.timestamp + TestConstants.PERIOD_50_DAYS_IN_SECONDS,
            _iporProtocol.milton
        );
        assertEq(soap50Days, expectedSoapBalanceAfter50Days);
    }

    function testShouldCalculateExactlyTheSameSoapWithAndWithoutUpdateIPORWithTheSameIndexValueWhenDAIPayFixed25And50DaysPeriod()
        public
    {
        // given
        _cfg.iporOracleInitialParamsTestCase = BuilderUtils.IporOracleInitialParamsTestCase.DEFAULT;
        _cfg.miltonTestCase = BuilderUtils.MiltonTestCase.CASE0;

        _iporProtocol = _iporProtocolFactory.getDaiInstance(_cfg);
        _iporProtocol.spreadModel.setCalculateQuotePayFixed(TestConstants.PERCENTAGE_4_18DEC);
        _iporProtocol.spreadModel.setCalculateQuoteReceiveFixed(TestConstants.ZERO);

        vm.prank(_liquidityProvider);
        _iporProtocol.joseph.itfProvideLiquidity(TestConstants.USD_28_000_18DEC, block.timestamp);

        // when
        vm.prank(_userOne);
        _iporProtocol.iporOracle.itfUpdateIndex(
            address(_iporProtocol.asset),
            TestConstants.PERCENTAGE_3_18DEC,
            block.timestamp
        );

        vm.prank(_userTwo);
        _iporProtocol.milton.itfOpenSwapPayFixed(
            block.timestamp,
            TestConstants.TC_TOTAL_AMOUNT_10_000_18DEC,
            9 * TestConstants.D17,
            TestConstants.LEVERAGE_18DEC
        );

        (, , int256 soapBeforeUpdateIndex) = calculateSoap(
            _userTwo,
            block.timestamp + TestConstants.PERIOD_50_DAYS_IN_SECONDS,
            _iporProtocol.milton
        );

        vm.prank(_userOne);
        _iporProtocol.iporOracle.itfUpdateIndex(
            address(_iporProtocol.asset),
            TestConstants.PERCENTAGE_3_18DEC,
            block.timestamp + TestConstants.PERIOD_25_DAYS_IN_SECONDS
        );

        (, , int256 soapAfterUpdateIndex25Days) = calculateSoap(
            _userTwo,
            block.timestamp + TestConstants.PERIOD_50_DAYS_IN_SECONDS,
            _iporProtocol.milton
        );

        vm.prank(_userOne);
        _iporProtocol.iporOracle.itfUpdateIndex(
            address(_iporProtocol.asset),
            TestConstants.PERCENTAGE_3_18DEC,
            block.timestamp + TestConstants.PERIOD_50_DAYS_IN_SECONDS
        );

        (, , int256 soapAfterUpdateIndex50Days) = calculateSoap(
            _userTwo,
            block.timestamp + TestConstants.PERIOD_50_DAYS_IN_SECONDS,
            _iporProtocol.milton
        );

        // then
        int256 expectedSoapBeforeUpdateIndex = -136534382151108133190;
        int256 expectedSoapAfterUpdateIndex25Days = -136534382151108133190;
        int256 expectedSoapBalanceAfter50Days = -136534382151108133190;

        assertEq(soapBeforeUpdateIndex, expectedSoapBeforeUpdateIndex);
        assertEq(soapAfterUpdateIndex25Days, expectedSoapAfterUpdateIndex25Days);
        assertEq(soapAfterUpdateIndex50Days, expectedSoapBalanceAfter50Days);
    }

    function testShouldCalculateNegativeSoapWhenDAIPayFixedAndWait25DaysAndUpdateIbtPriceAfterSwapOpened() public {
        // given
        _cfg.iporOracleInitialParamsTestCase = BuilderUtils.IporOracleInitialParamsTestCase.DEFAULT;
        _cfg.miltonTestCase = BuilderUtils.MiltonTestCase.CASE0;

        _iporProtocol = _iporProtocolFactory.getDaiInstance(_cfg);
        _iporProtocol.spreadModel.setCalculateQuotePayFixed(TestConstants.PERCENTAGE_4_18DEC);
        _iporProtocol.spreadModel.setCalculateQuoteReceiveFixed(TestConstants.ZERO);

        vm.prank(_liquidityProvider);
        _iporProtocol.joseph.itfProvideLiquidity(TestConstants.USD_28_000_18DEC, block.timestamp);

        vm.prank(_userOne);
        _iporProtocol.iporOracle.itfUpdateIndex(
            address(_iporProtocol.asset),
            TestConstants.PERCENTAGE_3_18DEC,
            block.timestamp
        );

        vm.prank(_userTwo);
        _iporProtocol.milton.itfOpenSwapPayFixed(
            block.timestamp + TestConstants.PERIOD_1_DAY_IN_SECONDS,
            TestConstants.TC_TOTAL_AMOUNT_10_000_18DEC,
            9 * TestConstants.D17,
            TestConstants.LEVERAGE_18DEC
        );

        int256 expectedSoap = TestConstants.ZERO_INT;

        // when
        vm.prank(_userOne);
        _iporProtocol.iporOracle.itfUpdateIndex(
            address(_iporProtocol.asset),
            TestConstants.PERCENTAGE_3_18DEC,
            block.timestamp + TestConstants.PERIOD_1_DAY_IN_SECONDS
        );
        (, , int256 soapRightAfterOpenedPayFixedSwap) = calculateSoap(
            _userTwo,
            block.timestamp + TestConstants.PERIOD_1_DAY_IN_SECONDS + 100,
            _iporProtocol.milton
        );

        // then
        assertLt(soapRightAfterOpenedPayFixedSwap, expectedSoap);
    }

    function testShouldCalculateSoapWhenDAIPayFixedAnd2xAndWait50Days() public {
        // given
        _cfg.iporOracleInitialParamsTestCase = BuilderUtils.IporOracleInitialParamsTestCase.DEFAULT;
        _cfg.miltonTestCase = BuilderUtils.MiltonTestCase.CASE0;

        _iporProtocol = _iporProtocolFactory.getDaiInstance(_cfg);
        _iporProtocol.spreadModel.setCalculateQuotePayFixed(TestConstants.PERCENTAGE_4_18DEC);
        _iporProtocol.spreadModel.setCalculateQuoteReceiveFixed(TestConstants.ZERO);

        int256 expectedSoap50Days = -205221535441070939562;

        vm.prank(_liquidityProvider);
        _iporProtocol.joseph.itfProvideLiquidity(2 * TestConstants.USD_28_000_18DEC, block.timestamp);

        // when
        vm.prank(_userOne);
        _iporProtocol.iporOracle.itfUpdateIndex(
            address(_iporProtocol.asset),
            TestConstants.PERCENTAGE_3_18DEC,
            block.timestamp
        );

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
            TestConstants.PERCENTAGE_3_18DEC,
            block.timestamp + TestConstants.PERIOD_25_DAYS_IN_SECONDS
        );

        vm.prank(_userTwo);
        _iporProtocol.milton.itfOpenSwapPayFixed(
            block.timestamp + TestConstants.PERIOD_25_DAYS_IN_SECONDS,
            TestConstants.TC_TOTAL_AMOUNT_10_000_18DEC,
            9 * TestConstants.D17,
            TestConstants.LEVERAGE_18DEC
        );

        vm.prank(_userOne);
        _iporProtocol.iporOracle.itfUpdateIndex(
            address(_iporProtocol.asset),
            TestConstants.PERCENTAGE_3_18DEC,
            block.timestamp + TestConstants.PERIOD_50_DAYS_IN_SECONDS
        );

        (, , int256 soap50Days) = calculateSoap(
            _userTwo,
            block.timestamp + TestConstants.PERIOD_50_DAYS_IN_SECONDS,
            _iporProtocol.milton
        );

        // then
        assertEq(soap50Days, expectedSoap50Days);
    }

    function testShouldCalculateSoapEqualZeroWhenDAIPayFixedAtIPOR3PercentAndIPOR5PercentAfter25DaysAndDAIPayFixedAndIPOR6PercentAfter50DaysAndCloseAllSwapsAfter75DaysComplexTotalAmounts()
        public
    {
        // given
        _cfg.iporOracleInitialParamsTestCase = BuilderUtils.IporOracleInitialParamsTestCase.DEFAULT;
        _cfg.miltonTestCase = BuilderUtils.MiltonTestCase.CASE0;

        _iporProtocol = _iporProtocolFactory.getDaiInstance(_cfg);
        _iporProtocol.spreadModel.setCalculateQuoteReceiveFixed(TestConstants.ZERO);

        int256 expectedSoap75Days = TestConstants.ZERO_INT;

        _iporProtocol.spreadModel.setCalculateQuotePayFixed(TestConstants.PERCENTAGE_6_18DEC);

        vm.prank(_liquidityProvider);
        _iporProtocol.joseph.itfProvideLiquidity(2 * TestConstants.USD_28_000_18DEC, block.timestamp);

        // when
        vm.prank(_userOne);
        _iporProtocol.iporOracle.itfUpdateIndex(
            address(_iporProtocol.asset),
            TestConstants.PERCENTAGE_3_18DEC,
            block.timestamp
        );

        vm.prank(_userTwo);
        _iporProtocol.milton.itfOpenSwapPayFixed(
            block.timestamp,
            1000348983489384893923,
            9 * TestConstants.D17,
            TestConstants.LEVERAGE_1000_18DEC
        );

        vm.prank(_userOne);
        _iporProtocol.iporOracle.itfUpdateIndex(
            address(_iporProtocol.asset),
            TestConstants.PERCENTAGE_5_18DEC,
            block.timestamp + TestConstants.PERIOD_25_DAYS_IN_SECONDS
        );

        vm.prank(_userTwo);
        _iporProtocol.milton.itfOpenSwapPayFixed(
            block.timestamp + TestConstants.PERIOD_25_DAYS_IN_SECONDS,
            1492747383748202058744,
            1500000000000000000,
            TestConstants.LEVERAGE_1000_18DEC
        );

        vm.startPrank(_userOne);
        _iporProtocol.iporOracle.itfUpdateIndex(
            address(_iporProtocol.asset),
            TestConstants.PERCENTAGE_6_18DEC,
            block.timestamp + TestConstants.PERIOD_50_DAYS_IN_SECONDS
        );
        vm.stopPrank();

        _iporProtocol.milton.itfCloseSwapPayFixed(1, TestConstants.PERIOD_75_DAYS_IN_SECONDS);
        _iporProtocol.milton.itfCloseSwapPayFixed(2, TestConstants.PERIOD_75_DAYS_IN_SECONDS);

        // then
        (, , int256 soap75Days) = calculateSoap(
            _userTwo,
            block.timestamp + TestConstants.PERIOD_75_DAYS_IN_SECONDS,
            _iporProtocol.milton
        );
        assertEq(soap75Days, expectedSoap75Days);
    }

    function testShouldCalculateSoapEqualZeroWhenDAIPayFixedAtIPOR3PercentAndIPOR5PercentAfter25DaysAndDAIPayFixedAndIPOR6PercentAfter50DaysAndCloseAllSwapsAfter75DaysSimpleTotalAmounts()
        public
    {
        // given
        _cfg.iporOracleInitialParamsTestCase = BuilderUtils.IporOracleInitialParamsTestCase.DEFAULT;
        _cfg.miltonTestCase = BuilderUtils.MiltonTestCase.CASE0;

        _iporProtocol = _iporProtocolFactory.getDaiInstance(_cfg);
        _iporProtocol.spreadModel.setCalculateQuotePayFixed(TestConstants.PERCENTAGE_4_18DEC);
        _iporProtocol.spreadModel.setCalculateQuoteReceiveFixed(TestConstants.ZERO);

        int256 expectedSoap75Days = TestConstants.ZERO_INT;

        _iporProtocol.spreadModel.setCalculateQuotePayFixed(TestConstants.PERCENTAGE_6_18DEC);

        vm.prank(_liquidityProvider);
        _iporProtocol.joseph.itfProvideLiquidity(2 * TestConstants.USD_28_000_18DEC, block.timestamp);

        // when
        vm.prank(_userOne);
        _iporProtocol.iporOracle.itfUpdateIndex(
            address(_iporProtocol.asset),
            TestConstants.PERCENTAGE_3_18DEC,
            block.timestamp
        );

        vm.prank(_userTwo);
        _iporProtocol.milton.itfOpenSwapPayFixed(
            block.timestamp,
            1040000000000000000000,
            9 * TestConstants.D17,
            TestConstants.LEVERAGE_1000_18DEC
        );

        vm.prank(_userOne);
        _iporProtocol.iporOracle.itfUpdateIndex(
            address(_iporProtocol.asset),
            TestConstants.PERCENTAGE_5_18DEC,
            block.timestamp + TestConstants.PERIOD_25_DAYS_IN_SECONDS
        );

        vm.prank(_userTwo);
        _iporProtocol.milton.itfOpenSwapPayFixed(
            block.timestamp + TestConstants.PERIOD_25_DAYS_IN_SECONDS,
            1040000000000000000000,
            1500000000000000000,
            TestConstants.LEVERAGE_1000_18DEC
        );

        vm.startPrank(_userOne);
        _iporProtocol.iporOracle.itfUpdateIndex(
            address(_iporProtocol.asset),
            TestConstants.PERCENTAGE_6_18DEC,
            block.timestamp + TestConstants.PERIOD_50_DAYS_IN_SECONDS
        );
        vm.stopPrank();

        _iporProtocol.milton.itfCloseSwapPayFixed(1, TestConstants.PERIOD_75_DAYS_IN_SECONDS);
        _iporProtocol.milton.itfCloseSwapPayFixed(2, TestConstants.PERIOD_75_DAYS_IN_SECONDS);

        // then
        (, , int256 soap75Days) = calculateSoap(
            _userTwo,
            block.timestamp + TestConstants.PERIOD_75_DAYS_IN_SECONDS,
            _iporProtocol.milton
        );

        assertEq(soap75Days, expectedSoap75Days);
    }

    function testShouldCalculateSoapEqualZeroWhenDAIPayFixedAtIPOR6PercentAndIPOR3PercentAfter25DaysAndDAIPayFixedAndIPOR3PercentAfter50DaysAndCloseAllSwapsAfter75Days()
        public
    {
        // given
        _cfg.iporOracleInitialParamsTestCase = BuilderUtils.IporOracleInitialParamsTestCase.DEFAULT;
        _cfg.miltonTestCase = BuilderUtils.MiltonTestCase.CASE0;

        _iporProtocol = _iporProtocolFactory.getDaiInstance(_cfg);
        _iporProtocol.spreadModel.setCalculateQuoteReceiveFixed(TestConstants.ZERO);

        int256 expectedSoap75Days = TestConstants.ZERO_INT;

        _iporProtocol.spreadModel.setCalculateQuotePayFixed(41683900567904584);

        vm.prank(_liquidityProvider);
        _iporProtocol.joseph.itfProvideLiquidity(2 * TestConstants.USD_28_000_18DEC, block.timestamp);

        // when
        vm.prank(_userOne);
        _iporProtocol.iporOracle.itfUpdateIndex(
            address(_iporProtocol.asset),
            TestConstants.PERCENTAGE_6_18DEC,
            block.timestamp
        );

        vm.prank(_userTwo);
        _iporProtocol.milton.itfOpenSwapPayFixed(
            block.timestamp,
            1000348983489384893923,
            9 * TestConstants.D17,
            TestConstants.LEVERAGE_1000_18DEC
        );

        vm.prank(_userOne);
        _iporProtocol.iporOracle.itfUpdateIndex(
            address(_iporProtocol.asset),
            TestConstants.PERCENTAGE_3_18DEC,
            block.timestamp + TestConstants.PERIOD_25_DAYS_IN_SECONDS
        );

        vm.prank(_userTwo);
        _iporProtocol.milton.itfOpenSwapPayFixed(
            block.timestamp + TestConstants.PERIOD_25_DAYS_IN_SECONDS,
            1492747383748202058744,
            9 * TestConstants.D17,
            TestConstants.LEVERAGE_1000_18DEC
        );

        vm.startPrank(_userOne);
        _iporProtocol.iporOracle.itfUpdateIndex(
            address(_iporProtocol.asset),
            TestConstants.PERCENTAGE_3_18DEC,
            block.timestamp + TestConstants.PERIOD_50_DAYS_IN_SECONDS
        );
        vm.stopPrank();

        _iporProtocol.milton.itfCloseSwapPayFixed(1, TestConstants.PERIOD_75_DAYS_IN_SECONDS);
        _iporProtocol.milton.itfCloseSwapPayFixed(2, TestConstants.PERIOD_75_DAYS_IN_SECONDS);

        // then
        (, , int256 soap75Days) = calculateSoap(
            _userTwo,
            block.timestamp + TestConstants.PERIOD_75_DAYS_IN_SECONDS,
            _iporProtocol.milton
        );
        assertEq(soap75Days, expectedSoap75Days);
    }

    function testShouldCalculateSoapEqualZeroWhenDAIReceiveFixedAtIPOR3PercentAndIPOR5PercentAfter25DaysAndDAIReceiveFixedAndIPOR6PercentAfter50DaysAndCloseAllSwapsAfter75Days()
        public
    {
        // given
        _cfg.iporOracleInitialParamsTestCase = BuilderUtils.IporOracleInitialParamsTestCase.DEFAULT;
        _cfg.miltonTestCase = BuilderUtils.MiltonTestCase.CASE0;

        _iporProtocol = _iporProtocolFactory.getDaiInstance(_cfg);
        _iporProtocol.spreadModel.setCalculateQuotePayFixed(TestConstants.ZERO);

        int256 expectedSoap75Days = TestConstants.ZERO_INT;

        _iporProtocol.spreadModel.setCalculateQuoteReceiveFixed(38877399621396944);

        vm.prank(_liquidityProvider);
        _iporProtocol.joseph.itfProvideLiquidity(2 * TestConstants.USD_28_000_18DEC, block.timestamp);

        // when
        vm.prank(_userOne);
        _iporProtocol.iporOracle.itfUpdateIndex(
            address(_iporProtocol.asset),
            TestConstants.PERCENTAGE_3_18DEC,
            block.timestamp
        );

        vm.prank(_userTwo);
        _iporProtocol.milton.itfOpenSwapReceiveFixed(
            block.timestamp,
            1000348983489384893923,
            TestConstants.PERCENTAGE_1_18DEC,
            TestConstants.LEVERAGE_1000_18DEC
        );

        vm.prank(_userOne);
        _iporProtocol.iporOracle.itfUpdateIndex(
            address(_iporProtocol.asset),
            TestConstants.PERCENTAGE_5_18DEC,
            block.timestamp + TestConstants.PERIOD_25_DAYS_IN_SECONDS
        );

        vm.prank(_userTwo);
        _iporProtocol.milton.itfOpenSwapReceiveFixed(
            block.timestamp + TestConstants.PERIOD_25_DAYS_IN_SECONDS,
            1492747383748202058744,
            TestConstants.PERCENTAGE_1_18DEC,
            TestConstants.LEVERAGE_1000_18DEC
        );

        vm.startPrank(_userOne);
        _iporProtocol.iporOracle.itfUpdateIndex(
            address(_iporProtocol.asset),
            TestConstants.PERCENTAGE_6_18DEC,
            block.timestamp + TestConstants.PERIOD_50_DAYS_IN_SECONDS
        );
        vm.stopPrank();

        _iporProtocol.milton.itfCloseSwapReceiveFixed(1, TestConstants.PERIOD_75_DAYS_IN_SECONDS);
        _iporProtocol.milton.itfCloseSwapReceiveFixed(2, TestConstants.PERIOD_75_DAYS_IN_SECONDS);

        // then
        (, , int256 soap75Days) = calculateSoap(
            _userTwo,
            block.timestamp + TestConstants.PERIOD_75_DAYS_IN_SECONDS,
            _iporProtocol.milton
        );

        assertEq(soap75Days, expectedSoap75Days);
    }

    function testShouldCalculateSoapEqualZeroWhenDAIReceiveFixedAtIPOR6PercentAndIPOR3PercentAfter25DaysAndDAIReceiveFixedAndIPOR3PercentAfter50DaysAndCloseAllSwapsAfter75Days()
        public
    {
        // given
        _cfg.iporOracleInitialParamsTestCase = BuilderUtils.IporOracleInitialParamsTestCase.CASE6;
        _cfg.miltonTestCase = BuilderUtils.MiltonTestCase.CASE0;

        _iporProtocol = _iporProtocolFactory.getDaiInstance(_cfg);
        _iporProtocol.spreadModel.setCalculateQuotePayFixed(TestConstants.ZERO);

        int256 expectedSoap75Days = TestConstants.ZERO_INT;

        _iporProtocol.spreadModel.setCalculateQuoteReceiveFixed(TestConstants.PERCENTAGE_2_18DEC);

        vm.prank(_liquidityProvider);
        _iporProtocol.joseph.itfProvideLiquidity(2 * TestConstants.USD_28_000_18DEC, block.timestamp);

        // when
        vm.prank(_userOne);
        _iporProtocol.iporOracle.itfUpdateIndex(
            address(_iporProtocol.asset),
            TestConstants.PERCENTAGE_6_18DEC,
            block.timestamp
        );

        vm.prank(_userTwo);
        _iporProtocol.milton.itfOpenSwapReceiveFixed(
            block.timestamp,
            1000348983489384893923,
            TestConstants.PERCENTAGE_1_18DEC,
            TestConstants.LEVERAGE_1000_18DEC
        );

        vm.prank(_userOne);
        _iporProtocol.iporOracle.itfUpdateIndex(
            address(_iporProtocol.asset),
            TestConstants.PERCENTAGE_3_18DEC,
            block.timestamp + TestConstants.PERIOD_25_DAYS_IN_SECONDS
        );

        vm.prank(_userTwo);
        _iporProtocol.milton.itfOpenSwapReceiveFixed(
            block.timestamp + TestConstants.PERIOD_25_DAYS_IN_SECONDS,
            1492747383748202058744,
            TestConstants.PERCENTAGE_1_18DEC,
            TestConstants.LEVERAGE_1000_18DEC
        );

        vm.startPrank(_userOne);
        _iporProtocol.iporOracle.itfUpdateIndex(
            address(_iporProtocol.asset),
            TestConstants.PERCENTAGE_3_18DEC,
            block.timestamp + TestConstants.PERIOD_50_DAYS_IN_SECONDS
        );
        vm.stopPrank();

        _iporProtocol.milton.itfCloseSwapReceiveFixed(1, TestConstants.PERIOD_75_DAYS_IN_SECONDS);
        _iporProtocol.milton.itfCloseSwapReceiveFixed(2, TestConstants.PERIOD_75_DAYS_IN_SECONDS);

        // then
        (, , int256 soap75Days) = calculateSoap(
            _userTwo,
            block.timestamp + TestConstants.PERIOD_75_DAYS_IN_SECONDS,
            _iporProtocol.milton
        );
        assertEq(soap75Days, expectedSoap75Days);
    }

    function testShouldCalculateSoapEqualZeroWhenUSDTPayFixedAtIPOR3PercentAndIPOR5PercentAfter25DaysAndUSDTPayFixedAndIPOR6PercentAfter50DaysAndCloseAllSwapsAfter75DaysSimpleTotalAmounts()
        public
    {
        // given
        _cfg.iporOracleInitialParamsTestCase = BuilderUtils.IporOracleInitialParamsTestCase.DEFAULT;
        _cfg.miltonTestCase = BuilderUtils.MiltonTestCase.CASE0;

        _iporProtocol = _iporProtocolFactory.getUsdtInstance(_cfg);
        _iporProtocol.spreadModel.setCalculateQuoteReceiveFixed(TestConstants.ZERO);

        int256 expectedSoap75Days = TestConstants.ZERO_INT;

        _iporProtocol.spreadModel.setCalculateQuotePayFixed(TestConstants.PERCENTAGE_6_18DEC);

        vm.prank(_liquidityProvider);

        _iporProtocol.joseph.itfProvideLiquidity(2 * TestConstants.USD_28_000_6DEC, block.timestamp);

        // when
        vm.prank(_userOne);
        _iporProtocol.iporOracle.itfUpdateIndex(
            address(_iporProtocol.asset),
            TestConstants.PERCENTAGE_3_18DEC,
            block.timestamp
        );

        vm.prank(_userTwo);
        _iporProtocol.milton.itfOpenSwapPayFixed(
            block.timestamp,
            1040000000,
            9 * TestConstants.D17,
            TestConstants.LEVERAGE_1000_18DEC
        );

        vm.prank(_userOne);
        _iporProtocol.iporOracle.itfUpdateIndex(
            address(_iporProtocol.asset),
            TestConstants.PERCENTAGE_5_18DEC,
            block.timestamp + TestConstants.PERIOD_25_DAYS_IN_SECONDS
        );

        vm.prank(_userTwo);
        _iporProtocol.milton.itfOpenSwapPayFixed(
            block.timestamp + TestConstants.PERIOD_25_DAYS_IN_SECONDS,
            1040000000,
            1500000000000000000,
            TestConstants.LEVERAGE_1000_18DEC
        );

        vm.startPrank(_userOne);
        _iporProtocol.iporOracle.itfUpdateIndex(
            address(_iporProtocol.asset),
            TestConstants.PERCENTAGE_6_18DEC,
            block.timestamp + TestConstants.PERIOD_50_DAYS_IN_SECONDS
        );
        vm.stopPrank();

        _iporProtocol.milton.itfCloseSwapPayFixed(1, TestConstants.PERIOD_75_DAYS_IN_SECONDS);
        _iporProtocol.milton.itfCloseSwapPayFixed(2, TestConstants.PERIOD_75_DAYS_IN_SECONDS);

        // then
        (, , int256 soap75Days) = calculateSoap(
            _userTwo,
            block.timestamp + TestConstants.PERIOD_75_DAYS_IN_SECONDS,
            _iporProtocol.milton
        );

        assertEq(soap75Days, expectedSoap75Days);
    }

    function testShouldCalculateSoapEqualZeroWhenUSDTPayFixedAtIPOR3PercentAndIPOR5PercentAfter25DaysAndUSDTPayFixedAndIPOR6PercentAfter50DaysAndCloseAllSwapsAfter75DaysComplexTotalAmounts()
        public
    {
        // given
        _cfg.iporOracleInitialParamsTestCase = BuilderUtils.IporOracleInitialParamsTestCase.DEFAULT;
        _cfg.miltonTestCase = BuilderUtils.MiltonTestCase.CASE0;

        _iporProtocol = _iporProtocolFactory.getUsdtInstance(_cfg);
        _iporProtocol.spreadModel.setCalculateQuoteReceiveFixed(TestConstants.ZERO);

        int256 expectedSoap75Days = TestConstants.ZERO_INT;

        _iporProtocol.spreadModel.setCalculateQuotePayFixed(TestConstants.PERCENTAGE_6_18DEC);

        vm.prank(_liquidityProvider);
        _iporProtocol.joseph.itfProvideLiquidity(2 * TestConstants.USD_28_000_6DEC, block.timestamp);

        // when
        vm.prank(_userOne);
        _iporProtocol.iporOracle.itfUpdateIndex(
            address(_iporProtocol.asset),
            TestConstants.PERCENTAGE_3_18DEC,
            block.timestamp
        );

        vm.prank(_userTwo);
        _iporProtocol.milton.itfOpenSwapPayFixed(
            block.timestamp,
            1000348983,
            9 * TestConstants.D17,
            TestConstants.LEVERAGE_1000_18DEC
        );

        vm.prank(_userOne);
        _iporProtocol.iporOracle.itfUpdateIndex(
            address(_iporProtocol.asset),
            TestConstants.PERCENTAGE_5_18DEC,
            block.timestamp + TestConstants.PERIOD_25_DAYS_IN_SECONDS
        );

        vm.prank(_userTwo);
        _iporProtocol.milton.itfOpenSwapPayFixed(
            block.timestamp + TestConstants.PERIOD_25_DAYS_IN_SECONDS,
            1492747383,
            1500000000000000000,
            TestConstants.LEVERAGE_1000_18DEC
        );

        vm.startPrank(_userOne);
        _iporProtocol.iporOracle.itfUpdateIndex(
            address(_iporProtocol.asset),
            TestConstants.PERCENTAGE_6_18DEC,
            block.timestamp + TestConstants.PERIOD_50_DAYS_IN_SECONDS
        );
        vm.stopPrank();

        _iporProtocol.milton.itfCloseSwapPayFixed(1, TestConstants.PERIOD_75_DAYS_IN_SECONDS);
        _iporProtocol.milton.itfCloseSwapPayFixed(2, TestConstants.PERIOD_75_DAYS_IN_SECONDS);

        // then
        (, , int256 soap75Days) = calculateSoap(
            _userTwo,
            block.timestamp + TestConstants.PERIOD_75_DAYS_IN_SECONDS,
            _iporProtocol.milton
        );

        assertEq(soap75Days, expectedSoap75Days);
    }

    function testShouldCalculateSoapEqualZeroWhenUSDTReceiveFixedAtIPOR3PercentAndIPOR5PercentAfter25DaysAndDAIReceiveFixedAndIPOR6PercentAfter50DaysAndCloseAllSwapsAfter75Days()
        public
    {
        // given
        _cfg.iporOracleInitialParamsTestCase = BuilderUtils.IporOracleInitialParamsTestCase.DEFAULT;
        _cfg.miltonTestCase = BuilderUtils.MiltonTestCase.CASE0;

        _iporProtocol = _iporProtocolFactory.getUsdtInstance(_cfg);
        _iporProtocol.spreadModel.setCalculateQuotePayFixed(TestConstants.ZERO);

        int256 expectedSoap75Days = TestConstants.ZERO_INT;

        _iporProtocol.spreadModel.setCalculateQuoteReceiveFixed(38877399621396944);

        vm.prank(_liquidityProvider);

        _iporProtocol.joseph.itfProvideLiquidity(2 * TestConstants.USD_28_000_6DEC, block.timestamp);

        // when
        vm.prank(_userOne);
        _iporProtocol.iporOracle.itfUpdateIndex(
            address(_iporProtocol.asset),
            TestConstants.PERCENTAGE_3_18DEC,
            block.timestamp
        );

        vm.prank(_userTwo);
        _iporProtocol.milton.itfOpenSwapReceiveFixed(
            block.timestamp,
            1000348983,
            TestConstants.PERCENTAGE_1_18DEC,
            TestConstants.LEVERAGE_1000_18DEC
        );

        vm.prank(_userOne);
        _iporProtocol.iporOracle.itfUpdateIndex(
            address(_iporProtocol.asset),
            TestConstants.PERCENTAGE_5_18DEC,
            block.timestamp + TestConstants.PERIOD_25_DAYS_IN_SECONDS
        );

        vm.prank(_userTwo);
        _iporProtocol.milton.itfOpenSwapReceiveFixed(
            block.timestamp + TestConstants.PERIOD_25_DAYS_IN_SECONDS,
            1000348983,
            TestConstants.PERCENTAGE_1_18DEC,
            TestConstants.LEVERAGE_1000_18DEC
        );

        vm.startPrank(_userOne);
        _iporProtocol.iporOracle.itfUpdateIndex(
            address(_iporProtocol.asset),
            TestConstants.PERCENTAGE_6_18DEC,
            block.timestamp + TestConstants.PERIOD_50_DAYS_IN_SECONDS
        );
        vm.stopPrank();

        _iporProtocol.milton.itfCloseSwapReceiveFixed(1, TestConstants.PERIOD_75_DAYS_IN_SECONDS);
        _iporProtocol.milton.itfCloseSwapReceiveFixed(2, TestConstants.PERIOD_75_DAYS_IN_SECONDS);

        // then
        (, , int256 soap75Days) = calculateSoap(
            _userTwo,
            block.timestamp + TestConstants.PERIOD_75_DAYS_IN_SECONDS,
            _iporProtocol.milton
        );

        assertEq(soap75Days, expectedSoap75Days);
    }
}

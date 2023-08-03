// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.20;

import "../TestCommons.sol";
import "../utils/TestConstants.sol";

contract AmmSoapTest is TestCommons {
    IporProtocolFactory.IporProtocolConfig private _cfg;
    IporProtocolFactory.AmmConfig private _ammCfg;
    BuilderUtils.IporProtocol internal _iporProtocol;

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

        _cfg.spread28DaysTestCase = BuilderUtils.Spread28DaysTestCase.CASE0;

        _ammCfg.iporOracleUpdater = _userOne;
        _ammCfg.iporRiskManagementOracleUpdater = _userOne;
    }


    function testShouldCalculateSoapWhenNoDerivativesSoapEqualZero() public {
        // given
        _iporProtocol = _iporProtocolFactory.getDaiInstance(_cfg);

        // when
        (, , int256 soap) = _iporProtocol.ammSwapsLens.getSoap(address(_iporProtocol.asset));
        // then
        assertEq(soap, TestConstants.ZERO_INT);
    }

    function testShouldCalculateSoapDAIPayFixedWhenAddPositionThenCalculate() public {
        _cfg.spread28DaysTestCase = BuilderUtils.Spread28DaysTestCase.CASE3;
        _iporProtocol = _iporProtocolFactory.getDaiInstance(_cfg);

        vm.prank(_userOne);
        _iporProtocol.iporOracle.updateIndex(address(_iporProtocol.asset), TestConstants.PERCENTAGE_5_18DEC);

        vm.prank(_liquidityProvider);
        _iporProtocol.ammPoolsService.provideLiquidityDai(_liquidityProvider, TestConstants.USD_28_000_18DEC);

        vm.prank(_userTwo);
        _iporProtocol.ammOpenSwapService.openSwapPayFixed28daysDai(
            _userTwo,
            TestConstants.TC_TOTAL_AMOUNT_10_000_18DEC,
            9 * TestConstants.D17,
            TestConstants.LEVERAGE_18DEC
        );

        // when
        (, , int256 soap) = _iporProtocol.ammSwapsLens.getSoap(address(_iporProtocol.asset));

        // then
        assertEq(soap, TestConstants.ZERO_INT);
    }

    function testShouldCalculateSoapDAIPayFixedWhenAddPositionThenCalculateAfter25Days() public {
        // given

        _cfg.iporOracleInitialParamsTestCase = BuilderUtils.IporOracleInitialParamsTestCase.DEFAULT;
        _cfg.spread28DaysTestCase = BuilderUtils.Spread28DaysTestCase.CASE1;
        _cfg.openSwapServiceTestCase = BuilderUtils.AmmOpenSwapServiceTestCase.DEFAULT;

        _iporProtocol = _iporProtocolFactory.getDaiInstance(_cfg);

        vm.warp(100);
        vm.prank(_userOne);
        _iporProtocol.iporOracle.updateIndex(address(_iporProtocol.asset), TestConstants.PERCENTAGE_3_18DEC);

        vm.prank(_liquidityProvider);
        _iporProtocol.ammPoolsService.provideLiquidityDai(_liquidityProvider, TestConstants.USD_28_000_18DEC);

        vm.prank(_userTwo);
        _iporProtocol.ammOpenSwapService.openSwapPayFixed28daysDai(
            _userTwo,
            TestConstants.TC_TOTAL_AMOUNT_10_000_18DEC,
            9 * TestConstants.D17,
            TestConstants.LEVERAGE_18DEC
        );

        int256 expectedSoapBalance = -67896394443267281384;

        vm.warp(100 + TestConstants.PERIOD_25_DAYS_IN_SECONDS);

        // when
        (, , int256 soap) = _iporProtocol.ammSwapsLens.getSoap(address(_iporProtocol.asset));

        // then
        assertEq(soap, expectedSoapBalance);
    }

    function testShouldCalculateSoapDAIReceiveFixedWhenAddPositionThenCalculate() public {
        // given
        _cfg.iporOracleInitialParamsTestCase = BuilderUtils.IporOracleInitialParamsTestCase.DEFAULT;
        _cfg.spread28DaysTestCase = BuilderUtils.Spread28DaysTestCase.CASE2;
        _iporProtocol = _iporProtocolFactory.getDaiInstance(_cfg);

        vm.prank(_userOne);
        _iporProtocol.iporOracle.updateIndex(address(_iporProtocol.asset), TestConstants.PERCENTAGE_3_18DEC);

        vm.prank(_liquidityProvider);
        _iporProtocol.ammPoolsService.provideLiquidityDai(_liquidityProvider, TestConstants.USD_28_000_18DEC);

        vm.prank(_userTwo);
        _iporProtocol.ammOpenSwapService.openSwapReceiveFixed28daysDai(
            _userTwo,
            TestConstants.TC_TOTAL_AMOUNT_10_000_18DEC,
            TestConstants.PERCENTAGE_1_18DEC,
            TestConstants.LEVERAGE_18DEC
        );

        int256 expectedSoapBalance = -TestConstants.ZERO_INT;

        // when
        (, , int256 soap) = _iporProtocol.ammSwapsLens.getSoap(address(_iporProtocol.asset));

        // then
        assertEq(soap, expectedSoapBalance);
    }

    function testShouldCalculateSoapDAIReceiveFixedWhenAddPositionThenCalculateAfter25Days() public {
        // given
        _cfg.iporOracleInitialParamsTestCase = BuilderUtils.IporOracleInitialParamsTestCase.DEFAULT;
        _cfg.spread28DaysTestCase = BuilderUtils.Spread28DaysTestCase.CASE2;
        _iporProtocol = _iporProtocolFactory.getDaiInstance(_cfg);

        int256 expectedSoapBalance = -67849905986033499667;

        vm.prank(_liquidityProvider);
        _iporProtocol.ammPoolsService.provideLiquidityDai(_liquidityProvider, TestConstants.USD_28_000_18DEC);

        uint256 currentTimestamp = block.timestamp;
        vm.warp(currentTimestamp);

        vm.prank(_userOne);
        _iporProtocol.iporOracle.updateIndex(address(_iporProtocol.asset), TestConstants.PERCENTAGE_3_18DEC);

        vm.prank(_userTwo);
        _iporProtocol.ammOpenSwapService.openSwapReceiveFixed28daysDai(
            _userTwo,
            TestConstants.TC_TOTAL_AMOUNT_10_000_18DEC,
            TestConstants.PERCENTAGE_1_18DEC,
            TestConstants.LEVERAGE_18DEC
        );

        vm.warp(currentTimestamp + TestConstants.PERIOD_25_DAYS_IN_SECONDS);

        // when
        (, , int256 soap) = _iporProtocol.ammSwapsLens.getSoap(address(_iporProtocol.asset));

        // then
        assertEq(soap, expectedSoapBalance);
    }

    function testShouldCalculateSoapDAIPayFixedWhenAddAndRemovePosition() public {
        // given
        _cfg.iporOracleInitialParamsTestCase = BuilderUtils.IporOracleInitialParamsTestCase.DEFAULT;
        _cfg.spread28DaysTestCase = BuilderUtils.Spread28DaysTestCase.CASE4;
        _iporProtocol = _iporProtocolFactory.getDaiInstance(_cfg);

        int256 expectedSoapBalance = TestConstants.ZERO_INT;

        vm.prank(_liquidityProvider);
        _iporProtocol.ammPoolsService.provideLiquidityDai(_liquidityProvider, TestConstants.USD_28_000_18DEC);

        uint256 currentTimestamp = block.timestamp;

        vm.prank(_userOne);
        _iporProtocol.iporOracle.updateIndex(address(_iporProtocol.asset), TestConstants.PERCENTAGE_3_18DEC);

        vm.prank(_userTwo);
        _iporProtocol.ammOpenSwapService.openSwapPayFixed28daysDai(
            _userTwo,
            TestConstants.TC_TOTAL_AMOUNT_10_000_18DEC,
            9 * TestConstants.D17,
            TestConstants.LEVERAGE_18DEC
        );

        vm.warp(currentTimestamp + TestConstants.PERIOD_25_DAYS_IN_SECONDS);

        uint256[] memory swapPfIds = new uint256[](1);
        swapPfIds[0] = 1;
        uint256[] memory swapRfIds = new uint256[](0);

        // when
        _iporProtocol.ammCloseSwapService.closeSwapsDai(_userTwo, swapPfIds, swapRfIds);

        (, , int256 soap) = _iporProtocol.ammSwapsLens.getSoap(address(_iporProtocol.asset));

        // then
        assertEq(soap, expectedSoapBalance);
    }

    function testShouldCalculateSoapDAIReceiveFixedWhenAddAndRemovePosition() public {
        // given
        _cfg.iporOracleInitialParamsTestCase = BuilderUtils.IporOracleInitialParamsTestCase.DEFAULT;
        _cfg.spread28DaysTestCase = BuilderUtils.Spread28DaysTestCase.CASE2;
        _iporProtocol = _iporProtocolFactory.getDaiInstance(_cfg);

        int256 expectedSoapBalance = TestConstants.ZERO_INT;

        vm.prank(_liquidityProvider);
        _iporProtocol.ammPoolsService.provideLiquidityDai(_liquidityProvider, TestConstants.USD_28_000_18DEC);

        uint256 currentTimestamp = block.timestamp;

        vm.prank(_userOne);
        _iporProtocol.iporOracle.updateIndex(address(_iporProtocol.asset), TestConstants.PERCENTAGE_3_18DEC);

        vm.prank(_userTwo);
        _iporProtocol.ammOpenSwapService.openSwapReceiveFixed28daysDai(
            _userTwo,
            TestConstants.TC_TOTAL_AMOUNT_10_000_18DEC,
            TestConstants.PERCENTAGE_1_18DEC,
            TestConstants.LEVERAGE_18DEC
        );

        vm.prank(_liquidityProvider);
        _iporProtocol.ammPoolsService.provideLiquidityDai(
            _liquidityProvider,
            TestConstants.TC_TOTAL_AMOUNT_10_000_18DEC
        );

        vm.warp(currentTimestamp + TestConstants.PERIOD_25_DAYS_IN_SECONDS);

        uint256[] memory swapPfIds = new uint256[](0);
        uint256[] memory swapRfIds = new uint256[](1);
        swapRfIds[0] = 1;

        // when
        _iporProtocol.ammCloseSwapService.closeSwapsDai(_userTwo, swapPfIds, swapRfIds);

        (, , int256 soap) = _iporProtocol.ammSwapsLens.getSoap(address(_iporProtocol.asset));

        // then
        assertEq(soap, expectedSoapBalance);
    }

    function testShouldCalculateSoapWhenDAIPayFixedAndDAIReceiveFixed18Decimals() public {
        // given
        _cfg.iporOracleInitialParamsTestCase = BuilderUtils.IporOracleInitialParamsTestCase.DEFAULT;
        _cfg.spread28DaysTestCase = BuilderUtils.Spread28DaysTestCase.CASE5;
        _iporProtocol = _iporProtocolFactory.getDaiInstance(_cfg);

        int256 expectedSoapBalance = -135746300429300781051;
        vm.prank(_liquidityProvider);
        _iporProtocol.ammPoolsService.provideLiquidityDai(_liquidityProvider, 2 * TestConstants.USD_28_000_18DEC);

        uint256 currentTimestamp = block.timestamp;

        vm.prank(_userOne);
        _iporProtocol.iporOracle.updateIndex(address(_iporProtocol.asset), TestConstants.PERCENTAGE_3_18DEC);

        // when
        vm.prank(_userTwo);
        _iporProtocol.ammOpenSwapService.openSwapPayFixed28daysDai(
            _userTwo,
            TestConstants.TC_TOTAL_AMOUNT_10_000_18DEC,
            9 * TestConstants.D17,
            TestConstants.LEVERAGE_18DEC
        );

        vm.prank(_userTwo);
        _iporProtocol.ammOpenSwapService.openSwapReceiveFixed28daysDai(
            _userTwo,
            TestConstants.TC_TOTAL_AMOUNT_10_000_18DEC,
            TestConstants.PERCENTAGE_1_18DEC,
            TestConstants.LEVERAGE_18DEC
        );

        vm.warp(currentTimestamp + TestConstants.PERIOD_25_DAYS_IN_SECONDS);
        (, , int256 soap) = _iporProtocol.ammSwapsLens.getSoap(address(_iporProtocol.asset));

        // then
        assertEq(soap, expectedSoapBalance);
    }

    function testShouldCalculateSoapWhenUSDTPayFixedAndUSDTReceiveFixed6Decimals() public {
        // given
        _cfg.iporOracleInitialParamsTestCase = BuilderUtils.IporOracleInitialParamsTestCase.DEFAULT;
        _cfg.spread28DaysTestCase = BuilderUtils.Spread28DaysTestCase.CASE5;
        _iporProtocol = _iporProtocolFactory.getUsdtInstance(_cfg);

        int256 expectedSoapBalance = -135746300429300781051;
        vm.prank(_liquidityProvider);
        _iporProtocol.ammPoolsService.provideLiquidityUsdt(_liquidityProvider, 2 * TestConstants.USD_28_000_6DEC);

        uint256 currentTimestamp = block.timestamp;

        vm.prank(_userOne);
        _iporProtocol.iporOracle.updateIndex(address(_iporProtocol.asset), TestConstants.PERCENTAGE_3_18DEC);

        vm.prank(_userTwo);
        _iporProtocol.ammOpenSwapService.openSwapPayFixed28daysUsdt(
            _userTwo,
            TestConstants.TC_TOTAL_AMOUNT_10_000_6DEC,
            9 * TestConstants.D17,
            TestConstants.LEVERAGE_18DEC
        );

        vm.prank(_userTwo);
        _iporProtocol.ammOpenSwapService.openSwapReceiveFixed28daysUsdt(
            _userTwo,
            TestConstants.TC_TOTAL_AMOUNT_10_000_6DEC,
            TestConstants.PERCENTAGE_1_18DEC,
            TestConstants.LEVERAGE_18DEC
        );

        vm.warp(currentTimestamp + TestConstants.PERIOD_25_DAYS_IN_SECONDS);

        (, , int256 soap) = _iporProtocol.ammSwapsLens.getSoap(address(_iporProtocol.asset));

        // then
        assertEq(soap, expectedSoapBalance);
    }

    function testShouldCalculateSoapWhenDAIPayFixedAndUSDTPayFixed() public {
        //given
        _ammCfg.spread28DaysTestCase = BuilderUtils.Spread28DaysTestCase.CASE1;
        IporProtocolFactory.Amm memory amm = _iporProtocolFactory.getFullInstance(_ammCfg);

        BuilderUtils.IporProtocol memory ammUsdt = amm.usdt;
        BuilderUtils.IporProtocol memory ammDai = amm.dai;

        _iporProtocolFactory.setupUsers(_cfg, ammUsdt);
        _iporProtocolFactory.setupUsers(_cfg, ammDai);

        int256 expectedSoapUsdt = -67896394443267281384;
        int256 expectedSoapDai = -67896394443267281384;
        uint256 currentTimestamp = block.timestamp;

        vm.startPrank(_liquidityProvider);
        ammUsdt.ammPoolsService.provideLiquidityUsdt(_liquidityProvider, TestConstants.USD_28_000_6DEC);
        ammDai.ammPoolsService.provideLiquidityDai(_liquidityProvider, TestConstants.USD_28_000_18DEC);
        vm.stopPrank();

        vm.startPrank(_userOne);
        amm.iporOracle.updateIndex(address(ammUsdt.asset), TestConstants.PERCENTAGE_3_18DEC);
        amm.iporOracle.updateIndex(address(ammDai.asset), TestConstants.PERCENTAGE_3_18DEC);
        vm.stopPrank();

        // when
        vm.prank(_userTwo);
        ammUsdt.ammOpenSwapService.openSwapPayFixed28daysUsdt(
            _userTwo,
            TestConstants.TC_TOTAL_AMOUNT_10_000_6DEC,
            9 * TestConstants.D17,
            10 * 1e18
        );

        vm.prank(_userTwo);
        ammDai.ammOpenSwapService.openSwapPayFixed28daysDai(
            _userTwo,
            TestConstants.TC_TOTAL_AMOUNT_10_000_18DEC,
            9 * TestConstants.D17,
            10 * 1e18
        );

        vm.warp(currentTimestamp + TestConstants.PERIOD_25_DAYS_IN_SECONDS);
        (, , int256 soapUsdt) = amm.usdt.ammSwapsLens.getSoap(address(amm.usdt.asset));
        (, , int256 soapDai) = amm.dai.ammSwapsLens.getSoap(address(amm.dai.asset));

        // then
        assertEq(soapUsdt, expectedSoapUsdt, "incorrect soapUsdt");
        assertEq(soapDai, expectedSoapDai, "incorrect soapDai");
    }

    function testShouldCalculateSoapWhenDAIPayFixedAndDAIReceiveFixedAndClosePayFixed() public {
        // given
        _cfg.iporOracleInitialParamsTestCase = BuilderUtils.IporOracleInitialParamsTestCase.DEFAULT;
        _cfg.spread28DaysTestCase = BuilderUtils.Spread28DaysTestCase.CASE5;

        _iporProtocol = _iporProtocolFactory.getDaiInstance(_cfg);

        int256 expectedSoapBalance = -67849905986033499667;

        uint256 currentTimestamp = block.timestamp;

        vm.prank(_liquidityProvider);
        _iporProtocol.ammPoolsService.provideLiquidityDai(_liquidityProvider, 2 * TestConstants.USD_28_000_18DEC);

        vm.prank(_userOne);
        _iporProtocol.iporOracle.updateIndex(address(_iporProtocol.asset), TestConstants.PERCENTAGE_3_18DEC);

        vm.prank(_userTwo);
        _iporProtocol.ammOpenSwapService.openSwapPayFixed28daysDai(
            _userTwo,
            TestConstants.TC_TOTAL_AMOUNT_10_000_18DEC,
            9 * TestConstants.D17,
            TestConstants.LEVERAGE_18DEC
        );

        vm.prank(_userTwo);
        _iporProtocol.ammOpenSwapService.openSwapReceiveFixed28daysDai(
            _userTwo,
            TestConstants.TC_TOTAL_AMOUNT_10_000_18DEC,
            TestConstants.PERCENTAGE_1_18DEC,
            TestConstants.LEVERAGE_18DEC
        );

        vm.warp(currentTimestamp + TestConstants.PERIOD_25_DAYS_IN_SECONDS);

        uint256[] memory swapPfIds = new uint256[](1);
        swapPfIds[0] = 1;
        uint256[] memory swapRfIds = new uint256[](0);

        // when
        _iporProtocol.ammCloseSwapService.closeSwapsDai(_userTwo, swapPfIds, swapRfIds);
        (, , int256 soap) = _iporProtocol.ammSwapsLens.getSoap(address(_iporProtocol.asset));

        // then
        assertEq(soap, expectedSoapBalance);
    }

    function testShouldCalculateSoapWhenDAIPayFixedAndDAIReceiveFixedAndCloseReceiveFixed() public {
        // given
        _cfg.iporOracleInitialParamsTestCase = BuilderUtils.IporOracleInitialParamsTestCase.DEFAULT;
        _cfg.spread28DaysTestCase = BuilderUtils.Spread28DaysTestCase.CASE5;

        _iporProtocol = _iporProtocolFactory.getDaiInstance(_cfg);

        int256 expectedSoapBalance = -67896394443267281384;

        uint256 currentTimestamp = block.timestamp;

        vm.prank(_liquidityProvider);
        _iporProtocol.ammPoolsService.provideLiquidityDai(_liquidityProvider, 2 * TestConstants.USD_28_000_18DEC);

        vm.prank(_userOne);
        _iporProtocol.iporOracle.updateIndex(address(_iporProtocol.asset), TestConstants.PERCENTAGE_3_18DEC);

        vm.prank(_userTwo);
        _iporProtocol.ammOpenSwapService.openSwapPayFixed28daysDai(
            _userTwo,
            TestConstants.TC_TOTAL_AMOUNT_10_000_18DEC,
            9 * TestConstants.D17,
            TestConstants.LEVERAGE_18DEC
        );

        vm.prank(_userTwo);
        _iporProtocol.ammOpenSwapService.openSwapReceiveFixed28daysDai(
            _userTwo,
            TestConstants.TC_TOTAL_AMOUNT_10_000_18DEC,
            TestConstants.PERCENTAGE_1_18DEC,
            TestConstants.LEVERAGE_18DEC
        );

        vm.warp(currentTimestamp + TestConstants.PERIOD_25_DAYS_IN_SECONDS);

        uint256[] memory swapPfIds = new uint256[](0);
        uint256[] memory swapRfIds = new uint256[](1);
        swapRfIds[0] = 2;

        // when
        _iporProtocol.ammCloseSwapService.closeSwapsDai(_userTwo, swapPfIds, swapRfIds);

        // then
        (, , int256 soap) = _iporProtocol.ammSwapsLens.getSoap(address(_iporProtocol.asset));
        assertEq(soap, expectedSoapBalance);
    }

    function testShouldCalculateSoapWhenDAIPayFixedAndUSDTReceiveFixedAndRemoveReceiveFixedPositionAfter25Days()
        public
    {
        // given
        _ammCfg.spread28DaysTestCase = BuilderUtils.Spread28DaysTestCase.CASE5;

        IporProtocolFactory.Amm memory amm = _iporProtocolFactory.getFullInstance(_ammCfg);

        BuilderUtils.IporProtocol memory ammUsdt = amm.usdt;
        BuilderUtils.IporProtocol memory ammDai = amm.dai;

        _iporProtocolFactory.setupUsers(_cfg, ammUsdt);
        _iporProtocolFactory.setupUsers(_cfg, ammDai);

        int256 expectedSoapUsdt = TestConstants.ZERO_INT;
        int256 expectedSoapDai = -67896394443267281384;

        uint256 currentTimestamp = block.timestamp;

        vm.startPrank(_liquidityProvider);
        ammUsdt.ammPoolsService.provideLiquidityUsdt(_liquidityProvider, TestConstants.USD_28_000_6DEC);
        ammDai.ammPoolsService.provideLiquidityDai(_liquidityProvider, TestConstants.USD_28_000_18DEC);
        vm.stopPrank();

        vm.startPrank(_userOne);
        amm.iporOracle.updateIndex(address(ammUsdt.asset), TestConstants.PERCENTAGE_3_18DEC);
        amm.iporOracle.updateIndex(address(ammDai.asset), TestConstants.PERCENTAGE_3_18DEC);
        vm.stopPrank();

        vm.prank(_userTwo);
        ammUsdt.ammOpenSwapService.openSwapReceiveFixed28daysUsdt(
            _userTwo,
            TestConstants.TC_TOTAL_AMOUNT_10_000_6DEC,
            TestConstants.PERCENTAGE_1_18DEC,
            TestConstants.LEVERAGE_18DEC
        );

        vm.prank(_userTwo);
        ammDai.ammOpenSwapService.openSwapPayFixed28daysDai(
            _userTwo,
            TestConstants.TC_TOTAL_AMOUNT_10_000_18DEC,
            9 * TestConstants.D17,
            TestConstants.LEVERAGE_18DEC
        );

        vm.prank(_liquidityProvider);
        ammUsdt.ammPoolsService.provideLiquidityUsdt(_liquidityProvider, TestConstants.TC_TOTAL_AMOUNT_10_000_6DEC);

        vm.warp(currentTimestamp + TestConstants.PERIOD_25_DAYS_IN_SECONDS);

        uint256[] memory swapPfIds = new uint256[](0);
        uint256[] memory swapRfIds = new uint256[](1);
        swapRfIds[0] = 1;

        // when
        ammUsdt.ammCloseSwapService.closeSwapsUsdt(_userTwo, swapPfIds, swapRfIds);

        // then
        (, , int256 soapUsdt) = ammUsdt.ammSwapsLens.getSoap(address(ammUsdt.asset));
        (, , int256 soapDai) = ammDai.ammSwapsLens.getSoap(address(ammDai.asset));

        assertEq(soapUsdt, expectedSoapUsdt, "incorrect soapUsdt");
        assertEq(soapDai, expectedSoapDai, "incorrect soapDai");
    }

    function testShouldCalculateSoapWhenDAIPayFixedAndChangeIbtPriceAndWait25DaysAndThenCalculateSoap18Decimals()
        public
    {
        // given
        _cfg.iporOracleInitialParamsTestCase = BuilderUtils.IporOracleInitialParamsTestCase.DEFAULT;
        _cfg.spread28DaysTestCase = BuilderUtils.Spread28DaysTestCase.CASE1;
        _iporProtocol = _iporProtocolFactory.getDaiInstance(_cfg);

        int256 expectedSoapBalance = 8200124444169952246361;

        uint256 currentTimestamp = block.timestamp;

        vm.prank(_liquidityProvider);
        _iporProtocol.ammPoolsService.provideLiquidityDai(_liquidityProvider, TestConstants.USD_28_000_18DEC);

        vm.prank(_userOne);
        _iporProtocol.iporOracle.updateIndex(address(_iporProtocol.asset), TestConstants.PERCENTAGE_3_18DEC);

        vm.prank(_userTwo);
        _iporProtocol.ammOpenSwapService.openSwapPayFixed28daysDai(
            _userTwo,
            TestConstants.TC_TOTAL_AMOUNT_10_000_18DEC,
            9 * TestConstants.D17,
            TestConstants.LEVERAGE_18DEC
        );

        vm.startPrank(_userOne);
        _iporProtocol.iporOracle.updateIndex(address(_iporProtocol.asset), TestConstants.PERCENTAGE_120_18DEC);

        vm.warp(currentTimestamp + TestConstants.PERIOD_25_DAYS_IN_SECONDS);

        _iporProtocol.iporOracle.updateIndex(address(_iporProtocol.asset), TestConstants.PERCENTAGE_6_18DEC);
        vm.stopPrank();

        // when
        (, , int256 soap) = _iporProtocol.ammSwapsLens.getSoap(address(_iporProtocol.asset));

        // then
        assertEq(soap, expectedSoapBalance);
    }

    function testShouldCalculateSoapWhenUSDTPayFixedAndChangeIbtPriceAndWait25DaysAndThenCalculateSoap6Decimals()
        public
    {
        // given
        _cfg.iporOracleInitialParamsTestCase = BuilderUtils.IporOracleInitialParamsTestCase.DEFAULT;
        _cfg.spread28DaysTestCase = BuilderUtils.Spread28DaysTestCase.CASE1;
        _iporProtocol = _iporProtocolFactory.getUsdtInstance(_cfg);

        int256 expectedSoapBalance = 8200124444169952246361;

        uint256 currentTimestamp = block.timestamp;

        vm.prank(_userOne);
        _iporProtocol.iporOracle.updateIndex(address(_iporProtocol.asset), TestConstants.PERCENTAGE_3_18DEC);

        vm.prank(_liquidityProvider);
        _iporProtocol.ammPoolsService.provideLiquidityUsdt(_liquidityProvider, TestConstants.USD_28_000_6DEC);

        vm.prank(_userTwo);
        _iporProtocol.ammOpenSwapService.openSwapPayFixed28daysUsdt(
            _userTwo,
            TestConstants.TC_TOTAL_AMOUNT_10_000_6DEC,
            9 * TestConstants.D17,
            TestConstants.LEVERAGE_18DEC
        );

        vm.startPrank(_userOne);
        _iporProtocol.iporOracle.updateIndex(address(_iporProtocol.asset), TestConstants.PERCENTAGE_120_18DEC);

        vm.warp(currentTimestamp + TestConstants.PERIOD_25_DAYS_IN_SECONDS);

        _iporProtocol.iporOracle.updateIndex(address(_iporProtocol.asset), TestConstants.PERCENTAGE_6_18DEC);
        vm.stopPrank();

        // when
        (, , int256 soap) = _iporProtocol.ammSwapsLens.getSoap(address(_iporProtocol.asset));

        // then
        assertEq(soap, expectedSoapBalance);
    }

    function testShouldCalculateSoapWhenDAIPayFixedAndChangeIbtPriceAndCalculateSoapAfter28DaysAndCalculateSoapAfter50DaysAndCompare()
        public
    {
        // given
        _cfg.iporOracleInitialParamsTestCase = BuilderUtils.IporOracleInitialParamsTestCase.DEFAULT;
        _cfg.spread28DaysTestCase = BuilderUtils.Spread28DaysTestCase.CASE1;

        _iporProtocol = _iporProtocolFactory.getDaiInstance(_cfg);

        int256 expectedSoapBalanceAfter28Days = 8220476754593688748141;
        int256 expectedSoapBalanceAfter50Days = 8370198235286744877373;

        uint256 currentTimestamp = block.timestamp;

        vm.prank(_liquidityProvider);
        _iporProtocol.ammPoolsService.provideLiquidityDai(_liquidityProvider, TestConstants.USD_28_000_18DEC);

        vm.prank(_userOne);
        _iporProtocol.iporOracle.updateIndex(address(_iporProtocol.asset), TestConstants.PERCENTAGE_3_18DEC);

        vm.prank(_userTwo);
        _iporProtocol.ammOpenSwapService.openSwapPayFixed28daysDai(
            _userTwo,
            TestConstants.TC_TOTAL_AMOUNT_10_000_18DEC,
            9 * TestConstants.D17,
            TestConstants.LEVERAGE_18DEC
        );

        vm.startPrank(_userOne);
        _iporProtocol.iporOracle.updateIndex(address(_iporProtocol.asset), TestConstants.PERCENTAGE_120_18DEC);

        vm.warp(currentTimestamp + TestConstants.PERIOD_25_DAYS_IN_SECONDS);

        _iporProtocol.iporOracle.updateIndex(address(_iporProtocol.asset), TestConstants.PERCENTAGE_6_18DEC);
        vm.stopPrank();

        // when

        // then
        vm.warp(currentTimestamp + TestConstants.PERIOD_28_DAYS_IN_SECONDS);
        (, , int256 soap28Days) = _iporProtocol.ammSwapsLens.getSoap(address(_iporProtocol.asset));
        assertEq(soap28Days, expectedSoapBalanceAfter28Days);

        vm.warp(currentTimestamp + TestConstants.PERIOD_50_DAYS_IN_SECONDS);
        (, , int256 soap50Days) = _iporProtocol.ammSwapsLens.getSoap(address(_iporProtocol.asset));
        assertEq(soap50Days, expectedSoapBalanceAfter50Days);
    }

    function testShouldCalculateSoapWhenDAIPayFixedAndWait25DaysAndDAIPayFixedAndWait25DaysAndThenCalculateSoap()
        public
    {
        // given
        _cfg.iporOracleInitialParamsTestCase = BuilderUtils.IporOracleInitialParamsTestCase.DEFAULT;
        _cfg.spread28DaysTestCase = BuilderUtils.Spread28DaysTestCase.CASE1;

        _iporProtocol = _iporProtocolFactory.getDaiInstance(_cfg);

        int256 expectedSoapBalanceAfter50Days = -204015112473123635898;
        vm.prank(_liquidityProvider);
        _iporProtocol.ammPoolsService.provideLiquidityDai(_liquidityProvider, 2 * TestConstants.USD_28_000_18DEC);

        uint256 currentTimestamp = block.timestamp;

        // when
        vm.prank(_userOne);
        _iporProtocol.iporOracle.updateIndex(address(_iporProtocol.asset), TestConstants.PERCENTAGE_3_18DEC);

        vm.prank(_userTwo);
        _iporProtocol.ammOpenSwapService.openSwapPayFixed28daysDai(
            _userTwo,
            TestConstants.TC_TOTAL_AMOUNT_10_000_18DEC,
            9 * TestConstants.D17,
            TestConstants.LEVERAGE_18DEC
        );

        vm.warp(currentTimestamp + TestConstants.PERIOD_25_DAYS_IN_SECONDS);

        vm.prank(_userTwo);
        _iporProtocol.ammOpenSwapService.openSwapPayFixed28daysDai(
            _userTwo,
            TestConstants.TC_TOTAL_AMOUNT_10_000_18DEC,
            9 * TestConstants.D17,
            TestConstants.LEVERAGE_18DEC
        );

        vm.warp(currentTimestamp + TestConstants.PERIOD_50_DAYS_IN_SECONDS);
        // then
        (, , int256 soap50Days) = _iporProtocol.ammSwapsLens.getSoap(address(_iporProtocol.asset));
        assertEq(soap50Days, expectedSoapBalanceAfter50Days);
    }

    function testShouldCalculateSoapWhenDAYPayFixedAndWait25DaysAndUpdateIPORAndDAIPayFixedAndWait25DaysAndUpdateIPORAndThenCalculateSoap()
        public
    {
        // given
        _cfg.iporOracleInitialParamsTestCase = BuilderUtils.IporOracleInitialParamsTestCase.DEFAULT;
        _cfg.spread28DaysTestCase = BuilderUtils.Spread28DaysTestCase.CASE1;

        _iporProtocol = _iporProtocolFactory.getDaiInstance(_cfg);

        int256 expectedSoapBalanceAfter50Days = -204015112473123635898;
        vm.prank(_liquidityProvider);
        _iporProtocol.ammPoolsService.provideLiquidityDai(_liquidityProvider, 2 * TestConstants.USD_28_000_18DEC);

        uint256 currentTimestamp = block.timestamp;

        // when
        vm.prank(_userOne);
        _iporProtocol.iporOracle.updateIndex(address(_iporProtocol.asset), TestConstants.PERCENTAGE_3_18DEC);

        vm.prank(_userTwo);
        _iporProtocol.ammOpenSwapService.openSwapPayFixed28daysDai(
            _userTwo,
            TestConstants.TC_TOTAL_AMOUNT_10_000_18DEC,
            9 * TestConstants.D17,
            TestConstants.LEVERAGE_18DEC
        );

        vm.warp(currentTimestamp + TestConstants.PERIOD_25_DAYS_IN_SECONDS);
        vm.prank(_userOne);
        _iporProtocol.iporOracle.updateIndex(address(_iporProtocol.asset), TestConstants.PERCENTAGE_3_18DEC);

        vm.prank(_userTwo);
        _iporProtocol.ammOpenSwapService.openSwapPayFixed28daysDai(
            _userTwo,
            TestConstants.TC_TOTAL_AMOUNT_10_000_18DEC,
            9 * TestConstants.D17,
            10 * 1e18
        );

        vm.warp(currentTimestamp + TestConstants.PERIOD_50_DAYS_IN_SECONDS);
        vm.prank(_userOne);
        _iporProtocol.iporOracle.updateIndex(address(_iporProtocol.asset), TestConstants.PERCENTAGE_3_18DEC);

        // then
        (, , int256 soap50Days) = _iporProtocol.ammSwapsLens.getSoap(address(_iporProtocol.asset));
        assertEq(soap50Days, expectedSoapBalanceAfter50Days);
    }

    function testShouldCalculateExactlyTheSameSoapWithAndWithoutUpdateIPORWithTheSameIndexValueWhenDAIPayFixed25And50DaysPeriod()
        public
    {
        // given
        _cfg.iporOracleInitialParamsTestCase = BuilderUtils.IporOracleInitialParamsTestCase.DEFAULT;
        _cfg.spread28DaysTestCase = BuilderUtils.Spread28DaysTestCase.CASE1;

        _iporProtocol = _iporProtocolFactory.getDaiInstance(_cfg);

        vm.prank(_liquidityProvider);
        _iporProtocol.ammPoolsService.provideLiquidityDai(_liquidityProvider, TestConstants.USD_28_000_18DEC);

        uint256 currentTimestamp = block.timestamp;

        // when
        vm.prank(_userOne);
        _iporProtocol.iporOracle.updateIndex(address(_iporProtocol.asset), TestConstants.PERCENTAGE_3_18DEC);

        vm.prank(_userTwo);
        _iporProtocol.ammOpenSwapService.openSwapPayFixed28daysDai(
            _userTwo,
            TestConstants.TC_TOTAL_AMOUNT_10_000_18DEC,
            9 * TestConstants.D17,
            TestConstants.LEVERAGE_18DEC
        );

        vm.warp(currentTimestamp + TestConstants.PERIOD_50_DAYS_IN_SECONDS);
        (, , int256 soapBeforeUpdateIndex) = _iporProtocol.ammSwapsLens.getSoap(address(_iporProtocol.asset));

        vm.warp(currentTimestamp + TestConstants.PERIOD_25_DAYS_IN_SECONDS);
        vm.prank(_userOne);
        _iporProtocol.iporOracle.updateIndex(address(_iporProtocol.asset), TestConstants.PERCENTAGE_3_18DEC);

        vm.warp(currentTimestamp + TestConstants.PERIOD_50_DAYS_IN_SECONDS);
        (, , int256 soapAfterUpdateIndex25Days) = _iporProtocol.ammSwapsLens.getSoap(address(_iporProtocol.asset));

        vm.prank(_userOne);
        _iporProtocol.iporOracle.updateIndex(address(_iporProtocol.asset), TestConstants.PERCENTAGE_3_18DEC);

        (, , int256 soapAfterUpdateIndex50Days) = _iporProtocol.ammSwapsLens.getSoap(address(_iporProtocol.asset));

        // then
        int256 expectedSoapBeforeUpdateIndex = -136118718029856335219;
        int256 expectedSoapAfterUpdateIndex25Days = -136118718029856335219;
        int256 expectedSoapBalanceAfter50Days = -136118718029856335219;
        assertEq(soapBeforeUpdateIndex, expectedSoapBeforeUpdateIndex);
        assertEq(soapAfterUpdateIndex25Days, expectedSoapAfterUpdateIndex25Days);
        assertEq(soapAfterUpdateIndex50Days, expectedSoapBalanceAfter50Days);
    }

    function testShouldCalculateNegativeSoapWhenDAIPayFixedAndWait25DaysAndUpdateIbtPriceAfterSwapOpened() public {
        // given
        _cfg.iporOracleInitialParamsTestCase = BuilderUtils.IporOracleInitialParamsTestCase.DEFAULT;
        _cfg.spread28DaysTestCase = BuilderUtils.Spread28DaysTestCase.CASE1;

        _iporProtocol = _iporProtocolFactory.getDaiInstance(_cfg);

        vm.prank(_liquidityProvider);
        _iporProtocol.ammPoolsService.provideLiquidityDai(_liquidityProvider, TestConstants.USD_28_000_18DEC);

        uint256 currentTimestamp = block.timestamp;

        vm.prank(_userOne);
        _iporProtocol.iporOracle.updateIndex(address(_iporProtocol.asset), TestConstants.PERCENTAGE_3_18DEC);

        vm.warp(currentTimestamp + TestConstants.PERIOD_1_DAY_IN_SECONDS);
        vm.prank(_userTwo);
        _iporProtocol.ammOpenSwapService.openSwapPayFixed28daysDai(
            _userTwo,
            TestConstants.TC_TOTAL_AMOUNT_10_000_18DEC,
            9 * TestConstants.D17,
            TestConstants.LEVERAGE_18DEC
        );

        int256 expectedSoap = TestConstants.ZERO_INT;

        // when
        vm.prank(_userOne);
        _iporProtocol.iporOracle.updateIndex(address(_iporProtocol.asset), TestConstants.PERCENTAGE_3_18DEC);

        vm.warp(currentTimestamp + TestConstants.PERIOD_1_DAY_IN_SECONDS + 100);

        (, , int256 soapRightAfterOpenedPayFixedSwap) = _iporProtocol.ammSwapsLens.getSoap(
            address(_iporProtocol.asset)
        );

        // then
        assertLt(soapRightAfterOpenedPayFixedSwap, expectedSoap);
    }

    function testShouldCalculateSoapWhenDAIPayFixedAnd2xAndWait50Days() public {
        // given
        _cfg.iporOracleInitialParamsTestCase = BuilderUtils.IporOracleInitialParamsTestCase.DEFAULT;
        _cfg.spread28DaysTestCase = BuilderUtils.Spread28DaysTestCase.CASE1;

        _iporProtocol = _iporProtocolFactory.getDaiInstance(_cfg);

        int256 expectedSoap50Days = -204015112473123635898;

        vm.prank(_liquidityProvider);
        _iporProtocol.ammPoolsService.provideLiquidityDai(_liquidityProvider, 2 * TestConstants.USD_28_000_18DEC);

        uint256 currentTimestamp = block.timestamp;

        // when
        vm.prank(_userOne);
        _iporProtocol.iporOracle.updateIndex(address(_iporProtocol.asset), TestConstants.PERCENTAGE_3_18DEC);

        vm.prank(_userTwo);
        _iporProtocol.ammOpenSwapService.openSwapPayFixed28daysDai(
            _userTwo,
            TestConstants.TC_TOTAL_AMOUNT_10_000_18DEC,
            9 * TestConstants.D17,
            TestConstants.LEVERAGE_18DEC
        );

        vm.warp(currentTimestamp + TestConstants.PERIOD_25_DAYS_IN_SECONDS);
        vm.prank(_userOne);
        _iporProtocol.iporOracle.updateIndex(address(_iporProtocol.asset), TestConstants.PERCENTAGE_3_18DEC);

        vm.prank(_userTwo);
        _iporProtocol.ammOpenSwapService.openSwapPayFixed28daysDai(
            _userTwo,
            TestConstants.TC_TOTAL_AMOUNT_10_000_18DEC,
            9 * TestConstants.D17,
            TestConstants.LEVERAGE_18DEC
        );

        vm.warp(currentTimestamp + TestConstants.PERIOD_50_DAYS_IN_SECONDS);
        vm.prank(_userOne);
        _iporProtocol.iporOracle.updateIndex(address(_iporProtocol.asset), TestConstants.PERCENTAGE_3_18DEC);

        (, , int256 soap50Days) = _iporProtocol.ammSwapsLens.getSoap(address(_iporProtocol.asset));

        // then
        assertEq(soap50Days, expectedSoap50Days);
    }

    function testShouldCalculateSoapEqualZeroWhenDAIPayFixedAtIPOR3PercentAndIPOR5PercentAfter25DaysAndDAIPayFixedAndIPOR6PercentAfter50DaysAndCloseAllSwapsAfter75DaysComplexTotalAmounts()
        public
    {
        // given
        _cfg.iporOracleInitialParamsTestCase = BuilderUtils.IporOracleInitialParamsTestCase.DEFAULT;
        _cfg.spread28DaysTestCase = BuilderUtils.Spread28DaysTestCase.CASE3;

        _iporProtocol = _iporProtocolFactory.getDaiInstance(_cfg);

        int256 expectedSoap75Days = TestConstants.ZERO_INT;

        vm.prank(_liquidityProvider);
        _iporProtocol.ammPoolsService.provideLiquidityDai(_liquidityProvider, 2 * TestConstants.USD_28_000_18DEC);

        uint256 currentTimestamp = block.timestamp;
        // when
        vm.prank(_userOne);
        _iporProtocol.iporOracle.updateIndex(address(_iporProtocol.asset), TestConstants.PERCENTAGE_3_18DEC);

        vm.prank(_userTwo);
        _iporProtocol.ammOpenSwapService.openSwapPayFixed28daysDai(
            _userTwo,
            1000348983489384893923,
            9 * TestConstants.D17,
            TestConstants.LEVERAGE_1000_18DEC
        );

        vm.warp(currentTimestamp + TestConstants.PERIOD_25_DAYS_IN_SECONDS);
        vm.prank(_userOne);
        _iporProtocol.iporOracle.updateIndex(address(_iporProtocol.asset), TestConstants.PERCENTAGE_5_18DEC);

        vm.prank(_userTwo);
        _iporProtocol.ammOpenSwapService.openSwapPayFixed28daysDai(
            _userTwo,
            1492747383748202058744,
            1500000000000000000,
            TestConstants.LEVERAGE_1000_18DEC
        );

        vm.warp(currentTimestamp + TestConstants.PERIOD_50_DAYS_IN_SECONDS);
        vm.startPrank(_userOne);
        _iporProtocol.iporOracle.updateIndex(address(_iporProtocol.asset), TestConstants.PERCENTAGE_6_18DEC);
        vm.stopPrank();

        vm.warp(currentTimestamp + TestConstants.PERIOD_75_DAYS_IN_SECONDS);

        uint256[] memory swapPfIds = new uint256[](2);
        swapPfIds[0] = 1;
        swapPfIds[1] = 2;
        uint256[] memory swapRfIds = new uint256[](0);

        _iporProtocol.ammCloseSwapService.closeSwapsDai(_userTwo, swapPfIds, swapRfIds);

        // then
        (, , int256 soap75Days) = _iporProtocol.ammSwapsLens.getSoap(address(_iporProtocol.asset));
        assertEq(soap75Days, expectedSoap75Days);
    }

    function testShouldCalculateSoapEqualZeroWhenDAIPayFixedAtIPOR3PercentAndIPOR5PercentAfter25DaysAndDAIPayFixedAndIPOR6PercentAfter50DaysAndCloseAllSwapsAfter75DaysSimpleTotalAmounts()
        public
    {
        // given
        _cfg.iporOracleInitialParamsTestCase = BuilderUtils.IporOracleInitialParamsTestCase.DEFAULT;
        _cfg.spread28DaysTestCase = BuilderUtils.Spread28DaysTestCase.CASE3;

        _iporProtocol = _iporProtocolFactory.getDaiInstance(_cfg);

        int256 expectedSoap75Days = TestConstants.ZERO_INT;

        vm.prank(_liquidityProvider);
        _iporProtocol.ammPoolsService.provideLiquidityDai(_liquidityProvider, 2 * TestConstants.USD_28_000_18DEC);

        // when
        vm.prank(_userOne);
        _iporProtocol.iporOracle.updateIndex(address(_iporProtocol.asset), TestConstants.PERCENTAGE_3_18DEC);

        uint256 currentTimestamp = block.timestamp;
        vm.prank(_userTwo);
        _iporProtocol.ammOpenSwapService.openSwapPayFixed28daysDai(
            _userTwo,
            1040000000000000000000,
            9 * TestConstants.D17,
            TestConstants.LEVERAGE_1000_18DEC
        );

        vm.warp(currentTimestamp + TestConstants.PERIOD_25_DAYS_IN_SECONDS);

        vm.prank(_userOne);
        _iporProtocol.iporOracle.updateIndex(address(_iporProtocol.asset), TestConstants.PERCENTAGE_5_18DEC);

        vm.prank(_userTwo);
        _iporProtocol.ammOpenSwapService.openSwapPayFixed28daysDai(
            _userTwo,
            1040000000000000000000,
            1500000000000000000,
            TestConstants.LEVERAGE_1000_18DEC
        );

        vm.warp(currentTimestamp + TestConstants.PERIOD_50_DAYS_IN_SECONDS);

        vm.startPrank(_userOne);
        _iporProtocol.iporOracle.updateIndex(address(_iporProtocol.asset), TestConstants.PERCENTAGE_6_18DEC);
        vm.stopPrank();

        vm.warp(currentTimestamp + TestConstants.PERIOD_75_DAYS_IN_SECONDS);

        uint256[] memory swapPfIds = new uint256[](2);
        swapPfIds[0] = 1;
        swapPfIds[1] = 2;
        uint256[] memory swapRfIds = new uint256[](0);

        _iporProtocol.ammCloseSwapService.closeSwapsDai(_userTwo, swapPfIds, swapRfIds);

        // then
        (, , int256 soap75Days) = _iporProtocol.ammSwapsLens.getSoap(address(_iporProtocol.asset));

        assertEq(soap75Days, expectedSoap75Days);
    }

    function testShouldCalculateSoapEqualZeroWhenDAIPayFixedAtIPOR6PercentAndIPOR3PercentAfter25DaysAndDAIPayFixedAndIPOR3PercentAfter50DaysAndCloseAllSwapsAfter75Days()
        public
    {
        // given
        _cfg.iporOracleInitialParamsTestCase = BuilderUtils.IporOracleInitialParamsTestCase.DEFAULT;
        _cfg.spread28DaysTestCase = BuilderUtils.Spread28DaysTestCase.CASE6;

        _iporProtocol = _iporProtocolFactory.getDaiInstance(_cfg);

        int256 expectedSoap75Days = TestConstants.ZERO_INT;

        vm.prank(_liquidityProvider);
        _iporProtocol.ammPoolsService.provideLiquidityDai(_liquidityProvider, 2 * TestConstants.USD_28_000_18DEC);

        uint256 currentTimestamp = block.timestamp;

        // when
        vm.prank(_userOne);
        _iporProtocol.iporOracle.updateIndex(address(_iporProtocol.asset), TestConstants.PERCENTAGE_6_18DEC);

        vm.prank(_userTwo);
        _iporProtocol.ammOpenSwapService.openSwapPayFixed28daysDai(
            _userTwo,
            1000348983489384893923,
            9 * TestConstants.D17,
            TestConstants.LEVERAGE_1000_18DEC
        );

        vm.warp(currentTimestamp + TestConstants.PERIOD_25_DAYS_IN_SECONDS);

        vm.prank(_userOne);
        _iporProtocol.iporOracle.updateIndex(address(_iporProtocol.asset), TestConstants.PERCENTAGE_3_18DEC);

        vm.prank(_userTwo);
        _iporProtocol.ammOpenSwapService.openSwapPayFixed28daysDai(
            _userTwo,
            1492747383748202058744,
            9 * TestConstants.D17,
            TestConstants.LEVERAGE_1000_18DEC
        );

        vm.warp(currentTimestamp + TestConstants.PERIOD_50_DAYS_IN_SECONDS);

        vm.startPrank(_userOne);
        _iporProtocol.iporOracle.updateIndex(address(_iporProtocol.asset), TestConstants.PERCENTAGE_3_18DEC);
        vm.stopPrank();

        vm.warp(currentTimestamp + TestConstants.PERIOD_75_DAYS_IN_SECONDS);

        uint256[] memory swapPfIds = new uint256[](2);
        swapPfIds[0] = 1;
        swapPfIds[1] = 2;
        uint256[] memory swapRfIds = new uint256[](0);

        _iporProtocol.ammCloseSwapService.closeSwapsDai(_userTwo, swapPfIds, swapRfIds);

        // then
        (, , int256 soap75Days) = _iporProtocol.ammSwapsLens.getSoap(address(_iporProtocol.asset));
        assertEq(soap75Days, expectedSoap75Days);
    }

    function testShouldCalculateSoapEqualZeroWhenDAIReceiveFixedAtIPOR3PercentAndIPOR5PercentAfter25DaysAndDAIReceiveFixedAndIPOR6PercentAfter50DaysAndCloseAllSwapsAfter75Days()
        public
    {
        // given
        _cfg.iporOracleInitialParamsTestCase = BuilderUtils.IporOracleInitialParamsTestCase.DEFAULT;
        _cfg.spread28DaysTestCase = BuilderUtils.Spread28DaysTestCase.CASE7;

        _iporProtocol = _iporProtocolFactory.getDaiInstance(_cfg);

        int256 expectedSoap75Days = TestConstants.ZERO_INT;

        vm.prank(_liquidityProvider);
        _iporProtocol.ammPoolsService.provideLiquidityDai(_liquidityProvider, 2 * TestConstants.USD_28_000_18DEC);

        uint256 currentTimestamp = block.timestamp;
        // when
        vm.prank(_userOne);
        _iporProtocol.iporOracle.updateIndex(address(_iporProtocol.asset), TestConstants.PERCENTAGE_3_18DEC);

        vm.prank(_userTwo);
        _iporProtocol.ammOpenSwapService.openSwapReceiveFixed28daysDai(
            _userTwo,
            1000348983489384893923,
            TestConstants.PERCENTAGE_1_18DEC,
            TestConstants.LEVERAGE_1000_18DEC
        );

        vm.warp(currentTimestamp + TestConstants.PERIOD_25_DAYS_IN_SECONDS);

        vm.prank(_userOne);
        _iporProtocol.iporOracle.updateIndex(address(_iporProtocol.asset), TestConstants.PERCENTAGE_5_18DEC);

        vm.prank(_userTwo);
        _iporProtocol.ammOpenSwapService.openSwapReceiveFixed28daysDai(
            _userTwo,
            1492747383748202058744,
            TestConstants.PERCENTAGE_1_18DEC,
            TestConstants.LEVERAGE_1000_18DEC
        );

        vm.warp(currentTimestamp + TestConstants.PERIOD_50_DAYS_IN_SECONDS);

        vm.startPrank(_userOne);
        _iporProtocol.iporOracle.updateIndex(address(_iporProtocol.asset), TestConstants.PERCENTAGE_6_18DEC);
        vm.stopPrank();

        vm.warp(currentTimestamp + TestConstants.PERIOD_75_DAYS_IN_SECONDS);

        uint256[] memory swapPfIds = new uint256[](0);
        uint256[] memory swapRfIds = new uint256[](2);
        swapRfIds[0] = 1;
        swapRfIds[1] = 2;

        _iporProtocol.ammCloseSwapService.closeSwapsDai(_userTwo, swapPfIds, swapRfIds);

        // then
        (, , int256 soap75Days) = _iporProtocol.ammSwapsLens.getSoap(address(_iporProtocol.asset));

        assertEq(soap75Days, expectedSoap75Days);
    }

    function testShouldCalculateSoapEqualZeroWhenDAIReceiveFixedAtIPOR6PercentAndIPOR3PercentAfter25DaysAndDAIReceiveFixedAndIPOR3PercentAfter50DaysAndCloseAllSwapsAfter75Days()
        public
    {
        // given
        _cfg.spread28DaysTestCase = BuilderUtils.Spread28DaysTestCase.CASE2;

        _iporProtocol = _iporProtocolFactory.getDaiInstance(_cfg);

        int256 expectedSoap75Days = TestConstants.ZERO_INT;

        vm.prank(_liquidityProvider);
        _iporProtocol.ammPoolsService.provideLiquidityDai(_liquidityProvider, 2 * TestConstants.USD_28_000_18DEC);

        uint256 currentTimestamp = block.timestamp;

        // when
        vm.prank(_userOne);
        _iporProtocol.iporOracle.updateIndex(address(_iporProtocol.asset), TestConstants.PERCENTAGE_6_18DEC);

        vm.prank(_userTwo);
        _iporProtocol.ammOpenSwapService.openSwapReceiveFixed28daysDai(
            _userTwo,
            1000348983489384893923,
            TestConstants.PERCENTAGE_1_18DEC,
            TestConstants.LEVERAGE_1000_18DEC
        );

        vm.warp(currentTimestamp + TestConstants.PERIOD_25_DAYS_IN_SECONDS);

        vm.prank(_userOne);
        _iporProtocol.iporOracle.updateIndex(address(_iporProtocol.asset), TestConstants.PERCENTAGE_3_18DEC);

        vm.prank(_userTwo);
        _iporProtocol.ammOpenSwapService.openSwapReceiveFixed28daysDai(
            _userTwo,
            1492747383748202058744,
            TestConstants.PERCENTAGE_1_18DEC,
            TestConstants.LEVERAGE_1000_18DEC
        );

        vm.warp(currentTimestamp + TestConstants.PERIOD_50_DAYS_IN_SECONDS);

        vm.startPrank(_userOne);
        _iporProtocol.iporOracle.updateIndex(address(_iporProtocol.asset), TestConstants.PERCENTAGE_3_18DEC);
        vm.stopPrank();

        vm.warp(currentTimestamp + TestConstants.PERIOD_75_DAYS_IN_SECONDS);

        uint256[] memory swapPfIds = new uint256[](0);
        uint256[] memory swapRfIds = new uint256[](2);
        swapRfIds[0] = 1;
        swapRfIds[1] = 2;

        _iporProtocol.ammCloseSwapService.closeSwapsDai(_userTwo, swapPfIds, swapRfIds);

        // then
        (, , int256 soap75Days) = _iporProtocol.ammSwapsLens.getSoap(address(_iporProtocol.asset));
        assertEq(soap75Days, expectedSoap75Days);
    }

    function testShouldCalculateSoapEqualZeroWhenUSDTPayFixedAtIPOR3PercentAndIPOR5PercentAfter25DaysAndUSDTPayFixedAndIPOR6PercentAfter50DaysAndCloseAllSwapsAfter75DaysSimpleTotalAmounts()
        public
    {
        // given
        _cfg.iporOracleInitialParamsTestCase = BuilderUtils.IporOracleInitialParamsTestCase.DEFAULT;
        _cfg.spread28DaysTestCase = BuilderUtils.Spread28DaysTestCase.CASE3;

        _iporProtocol = _iporProtocolFactory.getUsdtInstance(_cfg);

        int256 expectedSoap75Days = TestConstants.ZERO_INT;

        vm.prank(_liquidityProvider);

        _iporProtocol.ammPoolsService.provideLiquidityUsdt(_liquidityProvider, 2 * TestConstants.USD_28_000_6DEC);

        uint256 currentTimestamp = block.timestamp;

        // when
        vm.prank(_userOne);
        _iporProtocol.iporOracle.updateIndex(address(_iporProtocol.asset), TestConstants.PERCENTAGE_3_18DEC);

        vm.prank(_userTwo);
        _iporProtocol.ammOpenSwapService.openSwapPayFixed28daysUsdt(
            _userTwo,
            1040000000,
            9 * TestConstants.D17,
            TestConstants.LEVERAGE_1000_18DEC
        );

        vm.warp(currentTimestamp + TestConstants.PERIOD_25_DAYS_IN_SECONDS);

        vm.prank(_userOne);
        _iporProtocol.iporOracle.updateIndex(address(_iporProtocol.asset), TestConstants.PERCENTAGE_5_18DEC);

        vm.prank(_userTwo);
        _iporProtocol.ammOpenSwapService.openSwapPayFixed28daysUsdt(
            _userTwo,
            1040000000,
            1500000000000000000,
            TestConstants.LEVERAGE_1000_18DEC
        );

        vm.warp(currentTimestamp + TestConstants.PERIOD_50_DAYS_IN_SECONDS);

        vm.startPrank(_userOne);
        _iporProtocol.iporOracle.updateIndex(address(_iporProtocol.asset), TestConstants.PERCENTAGE_6_18DEC);
        vm.stopPrank();

        vm.warp(currentTimestamp + TestConstants.PERIOD_75_DAYS_IN_SECONDS);

        uint256[] memory swapPfIds = new uint256[](2);
        swapPfIds[0] = 1;
        swapPfIds[1] = 2;
        uint256[] memory swapRfIds = new uint256[](0);

        _iporProtocol.ammCloseSwapService.closeSwapsUsdt(_userTwo, swapPfIds, swapRfIds);

        // then
        (, , int256 soap75Days) = _iporProtocol.ammSwapsLens.getSoap(address(_iporProtocol.asset));

        assertEq(soap75Days, expectedSoap75Days);
    }

    function testShouldCalculateSoapEqualZeroWhenUSDTPayFixedAtIPOR3PercentAndIPOR5PercentAfter25DaysAndUSDTPayFixedAndIPOR6PercentAfter50DaysAndCloseAllSwapsAfter75DaysComplexTotalAmounts()
        public
    {
        // given
        _cfg.iporOracleInitialParamsTestCase = BuilderUtils.IporOracleInitialParamsTestCase.DEFAULT;
        _cfg.spread28DaysTestCase = BuilderUtils.Spread28DaysTestCase.CASE3;
        _iporProtocol = _iporProtocolFactory.getUsdtInstance(_cfg);

        int256 expectedSoap75Days = TestConstants.ZERO_INT;

        vm.prank(_liquidityProvider);
        _iporProtocol.ammPoolsService.provideLiquidityUsdt(_liquidityProvider, 2 * TestConstants.USD_28_000_6DEC);

        uint256 currentTimestamp = block.timestamp;

        // when
        vm.prank(_userOne);
        _iporProtocol.iporOracle.updateIndex(address(_iporProtocol.asset), TestConstants.PERCENTAGE_3_18DEC);

        vm.prank(_userTwo);
        _iporProtocol.ammOpenSwapService.openSwapPayFixed28daysUsdt(
            _userTwo,
            1000348983,
            9 * TestConstants.D17,
            TestConstants.LEVERAGE_1000_18DEC
        );

        vm.warp(currentTimestamp + TestConstants.PERIOD_25_DAYS_IN_SECONDS);

        vm.prank(_userOne);
        _iporProtocol.iporOracle.updateIndex(address(_iporProtocol.asset), TestConstants.PERCENTAGE_5_18DEC);

        vm.prank(_userTwo);
        _iporProtocol.ammOpenSwapService.openSwapPayFixed28daysUsdt(
            _userTwo,
            1492747383,
            1500000000000000000,
            TestConstants.LEVERAGE_1000_18DEC
        );

        vm.warp(currentTimestamp + TestConstants.PERIOD_50_DAYS_IN_SECONDS);

        vm.startPrank(_userOne);
        _iporProtocol.iporOracle.updateIndex(address(_iporProtocol.asset), TestConstants.PERCENTAGE_6_18DEC);
        vm.stopPrank();

        vm.warp(currentTimestamp + TestConstants.PERIOD_75_DAYS_IN_SECONDS);

        uint256[] memory swapPfIds = new uint256[](2);
        swapPfIds[0] = 1;
        swapPfIds[1] = 2;
        uint256[] memory swapRfIds = new uint256[](0);

        _iporProtocol.ammCloseSwapService.closeSwapsUsdt(_userTwo, swapPfIds, swapRfIds);

        // then
        (, , int256 soap75Days) = _iporProtocol.ammSwapsLens.getSoap(address(_iporProtocol.asset));

        assertEq(soap75Days, expectedSoap75Days);
    }

    function testShouldCalculateSoapEqualZeroWhenUSDTReceiveFixedAtIPOR3PercentAndIPOR5PercentAfter25DaysAndDAIReceiveFixedAndIPOR6PercentAfter50DaysAndCloseAllSwapsAfter75Days()
        public
    {
        // given
        _cfg.iporOracleInitialParamsTestCase = BuilderUtils.IporOracleInitialParamsTestCase.DEFAULT;
        _cfg.spread28DaysTestCase = BuilderUtils.Spread28DaysTestCase.CASE7;

        _iporProtocol = _iporProtocolFactory.getUsdtInstance(_cfg);

        int256 expectedSoap75Days = TestConstants.ZERO_INT;

        vm.prank(_liquidityProvider);

        _iporProtocol.ammPoolsService.provideLiquidityUsdt(_liquidityProvider, 2 * TestConstants.USD_28_000_6DEC);

        uint256 currentTimestamp = block.timestamp;

        // when
        vm.prank(_userOne);
        _iporProtocol.iporOracle.updateIndex(address(_iporProtocol.asset), TestConstants.PERCENTAGE_3_18DEC);

        vm.prank(_userTwo);
        _iporProtocol.ammOpenSwapService.openSwapReceiveFixed28daysUsdt(
            _userTwo,
            1000348983,
            TestConstants.PERCENTAGE_1_18DEC,
            TestConstants.LEVERAGE_1000_18DEC
        );

        vm.warp(currentTimestamp + TestConstants.PERIOD_25_DAYS_IN_SECONDS);

        vm.prank(_userOne);
        _iporProtocol.iporOracle.updateIndex(address(_iporProtocol.asset), TestConstants.PERCENTAGE_5_18DEC);

        vm.prank(_userTwo);
        _iporProtocol.ammOpenSwapService.openSwapReceiveFixed28daysUsdt(
            _userTwo,
            1000348983,
            TestConstants.PERCENTAGE_1_18DEC,
            TestConstants.LEVERAGE_1000_18DEC
        );

        vm.warp(currentTimestamp + TestConstants.PERIOD_50_DAYS_IN_SECONDS);

        vm.startPrank(_userOne);
        _iporProtocol.iporOracle.updateIndex(address(_iporProtocol.asset), TestConstants.PERCENTAGE_6_18DEC);
        vm.stopPrank();

        vm.warp(currentTimestamp + TestConstants.PERIOD_75_DAYS_IN_SECONDS);

        uint256[] memory swapPfIds = new uint256[](0);
        uint256[] memory swapRfIds = new uint256[](2);
        swapRfIds[0] = 1;
        swapRfIds[1] = 2;

        _iporProtocol.ammCloseSwapService.closeSwapsUsdt(_userTwo, swapPfIds, swapRfIds);

        // then
        (, , int256 soap75Days) = _iporProtocol.ammSwapsLens.getSoap(address(_iporProtocol.asset));

        assertEq(soap75Days, expectedSoap75Days);
    }
}

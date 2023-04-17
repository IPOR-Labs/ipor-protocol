// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.16;

import "../TestCommons.sol";
import {DataUtils} from "../utils/DataUtils.sol";
import {SwapUtils} from "../utils/SwapUtils.sol";
import "../utils/TestConstants.sol";
import "../../contracts/amm/MiltonStorage.sol";
import "../../contracts/interfaces/IMarketSafetyOracle.sol";
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
    MockSpreadModel internal _miltonSpreadModel;
    MockTestnetToken internal _usdtMockedToken;
    MockTestnetToken internal _usdcMockedToken;
    MockTestnetToken internal _daiMockedToken;
    IpToken internal _ipTokenUsdt;
    IpToken internal _ipTokenUsdc;
    IpToken internal _ipTokenDai;

    function setUp() public {
        _miltonSpreadModel = prepareMockSpreadModel(
            TestConstants.ZERO, TestConstants.ZERO, TestConstants.ZERO_INT, TestConstants.ZERO_INT
        );
        _usdtMockedToken = getTokenUsdt();
        _usdcMockedToken = getTokenUsdc();
        _daiMockedToken = getTokenDai();
        _ipTokenUsdt = getIpTokenUsdt(address(_usdtMockedToken));
        _ipTokenUsdc = getIpTokenUsdc(address(_usdcMockedToken));
        _ipTokenDai = getIpTokenDai(address(_daiMockedToken));
        _admin = address(this);
        _userOne = _getUserAddress(1);
        _userTwo = _getUserAddress(2);
        _userThree = _getUserAddress(3);
        _liquidityProvider = _getUserAddress(4);
        _users = usersToArray(_admin, _userOne, _userTwo, _userThree, _liquidityProvider);
    }

    function testShouldCalculateSoapWhenNoDerivativesSoapEqualZero() public {
        // given
        ItfIporOracle iporOracle =
            getIporOracleAsset(_userOne, address(_daiMockedToken), TestConstants.TC_5_EMA_18DEC_64UINT);
        IMarketSafetyOracle marketSafetyOracle = getMarketSafetyOracleAsset(
            _userOne,
            address(_daiMockedToken),
            TestConstants.MSO_UTILIZATION_RATE_48_PER,
            TestConstants.MSO_UTILIZATION_RATE_90_PER,
            TestConstants.MSO_NOTIONAL_1B
        );
        MockCase1Stanley mockCase1StanleyDai = getMockCase1Stanley(address(_daiMockedToken));

        MiltonStorage miltonStorageDai = getMiltonStorage();
        MockCase0MiltonDai mockCase0MiltonDai = getMockCase0MiltonDai(
            address(_daiMockedToken),
            address(iporOracle),
            address(miltonStorageDai),
            address(_miltonSpreadModel),
            address(mockCase1StanleyDai),
            address(marketSafetyOracle)
        );
        // when
        (,, int256 soap) = calculateSoap(_userTwo, block.timestamp, mockCase0MiltonDai);
        // then
        assertEq(soap, TestConstants.ZERO_INT);
    }

    function testShouldCalculateSoapDAIPayFixedWhenAddPositionThenCalculate() public {
        _miltonSpreadModel.setCalculateQuotePayFixed(TestConstants.PERCENTAGE_6_18DEC);
        ItfIporOracle iporOracle =
            getIporOracleAsset(_userOne, address(_daiMockedToken), TestConstants.TC_5_EMA_18DEC_64UINT);
        IMarketSafetyOracle marketSafetyOracle = getMarketSafetyOracleAsset(
            _userOne,
            address(_daiMockedToken),
            TestConstants.MSO_UTILIZATION_RATE_48_PER,
            TestConstants.MSO_UTILIZATION_RATE_90_PER,
            TestConstants.MSO_NOTIONAL_1B
        );
        MockCase1Stanley mockCase1StanleyDai = getMockCase1Stanley(address(_daiMockedToken));
        MiltonStorage miltonStorageDai = getMiltonStorage();
        MockCase0MiltonDai mockCase0MiltonDai = getMockCase0MiltonDai(
            address(_daiMockedToken),
            address(iporOracle),
            address(miltonStorageDai),
            address(_miltonSpreadModel),
            address(mockCase1StanleyDai),
            address(marketSafetyOracle)
        );
        MockCase0JosephDai mockCase0JosephDai = getMockCase0JosephDai(
            address(_daiMockedToken),
            address(_ipTokenDai),
            address(mockCase0MiltonDai),
            address(miltonStorageDai),
            address(mockCase1StanleyDai)
        );
        prepareApproveForUsersDai(_users, _daiMockedToken, address(mockCase0JosephDai), address(mockCase0MiltonDai));
        prepareMilton(mockCase0MiltonDai, address(mockCase0JosephDai), address(mockCase1StanleyDai));
        prepareJoseph(mockCase0JosephDai);
        prepareIpToken(_ipTokenDai, address(mockCase0JosephDai));
        vm.prank(_userOne);
        iporOracle.itfUpdateIndex(address(_daiMockedToken), TestConstants.PERCENTAGE_5_18DEC, block.timestamp);
        vm.prank(_liquidityProvider);
        mockCase0JosephDai.itfProvideLiquidity(TestConstants.USD_28_000_18DEC, block.timestamp);
        openSwapPayFixed(
            _userTwo,
            block.timestamp,
            TestConstants.TC_TOTAL_AMOUNT_10_000_18DEC,
            9 * TestConstants.D17,
            TestConstants.LEVERAGE_18DEC,
            mockCase0MiltonDai
        );
        // when
        (,, int256 soap) = calculateSoap(_userTwo, block.timestamp, mockCase0MiltonDai);
        // then
        assertEq(soap, TestConstants.ZERO_INT);
    }

    function testShouldCalculateSoapDAIPayFixedWhenAddPositionThenCalculateAfter25Days() public {
        // given
        _miltonSpreadModel.setCalculateQuotePayFixed(TestConstants.PERCENTAGE_4_18DEC);
        ItfIporOracle iporOracle =
            getIporOracleAsset(_userOne, address(_daiMockedToken), TestConstants.TC_DEFAULT_EMA_18DEC_64UINT);
        IMarketSafetyOracle marketSafetyOracle = getMarketSafetyOracleAsset(
            _userOne,
            address(_daiMockedToken),
            TestConstants.MSO_UTILIZATION_RATE_48_PER,
            TestConstants.MSO_UTILIZATION_RATE_90_PER,
            TestConstants.MSO_NOTIONAL_1B
        );
        MockCase0Stanley mockCase0StanleyDai = getMockCase0Stanley(address(_daiMockedToken));
        MiltonStorage miltonStorageDai = getMiltonStorage();
        MockCase0MiltonDai mockCase0MiltonDai = getMockCase0MiltonDai(
            address(_daiMockedToken),
            address(iporOracle),
            address(miltonStorageDai),
            address(_miltonSpreadModel),
            address(mockCase0StanleyDai),
            address(marketSafetyOracle)
        );
        MockCase0JosephDai mockCase0JosephDai = getMockCase0JosephDai(
            address(_daiMockedToken),
            address(_ipTokenDai),
            address(mockCase0MiltonDai),
            address(miltonStorageDai),
            address(mockCase0StanleyDai)
        );
        int256 expectedSoapBalance = -68267191075554066594;
        prepareApproveForUsersDai(_users, _daiMockedToken, address(mockCase0JosephDai), address(mockCase0MiltonDai));
        prepareMilton(mockCase0MiltonDai, address(mockCase0JosephDai), address(mockCase0StanleyDai));
        prepareJoseph(mockCase0JosephDai);
        prepareIpToken(_ipTokenDai, address(mockCase0JosephDai));
        vm.prank(_userOne);
        iporOracle.itfUpdateIndex(address(_daiMockedToken), TestConstants.PERCENTAGE_3_18DEC, block.timestamp);
        vm.prank(_liquidityProvider);
        mockCase0JosephDai.itfProvideLiquidity(TestConstants.USD_28_000_18DEC, block.timestamp);
        openSwapPayFixed(
            _userTwo,
            block.timestamp,
            TestConstants.TC_TOTAL_AMOUNT_10_000_18DEC,
            9 * TestConstants.D17,
            TestConstants.LEVERAGE_18DEC,
            mockCase0MiltonDai
        );
        // when
        (,, int256 soap) =
            calculateSoap(_userTwo, block.timestamp + TestConstants.PERIOD_25_DAYS_IN_SECONDS, mockCase0MiltonDai);
        // then
        assertEq(soap, expectedSoapBalance);
    }

    function testShouldCalculateSoapDAIReceiveFixedWhenAddPositionThenCalculate() public {
        // given
        _miltonSpreadModel.setCalculateQuotePayFixed(TestConstants.ZERO);
        _miltonSpreadModel.setCalculateQuoteReceiveFixed(TestConstants.PERCENTAGE_2_18DEC);
        ItfIporOracle iporOracle =
            getIporOracleAsset(_userOne, address(_daiMockedToken), TestConstants.TC_DEFAULT_EMA_18DEC_64UINT);
        IMarketSafetyOracle marketSafetyOracle = getMarketSafetyOracleAsset(
            _userOne,
            address(_daiMockedToken),
            TestConstants.MSO_UTILIZATION_RATE_48_PER,
            TestConstants.MSO_UTILIZATION_RATE_90_PER,
            TestConstants.MSO_NOTIONAL_1B
        );
        MockCase1Stanley mockCase1StanleyDai = getMockCase1Stanley(address(_daiMockedToken));
        MiltonStorage miltonStorageDai = getMiltonStorage();
        MockCase0MiltonDai mockCase0MiltonDai = getMockCase0MiltonDai(
            address(_daiMockedToken),
            address(iporOracle),
            address(miltonStorageDai),
            address(_miltonSpreadModel),
            address(mockCase1StanleyDai),
            address(marketSafetyOracle)
        );
        MockCase0JosephDai mockCase0JosephDai = getMockCase0JosephDai(
            address(_daiMockedToken),
            address(_ipTokenDai),
            address(mockCase0MiltonDai),
            address(miltonStorageDai),
            address(mockCase1StanleyDai)
        );
        int256 expectedSoapBalance = TestConstants.ZERO_INT;
        prepareApproveForUsersDai(_users, _daiMockedToken, address(mockCase0JosephDai), address(mockCase0MiltonDai));
        prepareMilton(mockCase0MiltonDai, address(mockCase0JosephDai), address(mockCase1StanleyDai));
        prepareJoseph(mockCase0JosephDai);
        prepareIpToken(_ipTokenDai, address(mockCase0JosephDai));
        vm.prank(_userOne);
        iporOracle.itfUpdateIndex(address(_daiMockedToken), TestConstants.PERCENTAGE_3_18DEC, block.timestamp);
        vm.prank(_liquidityProvider);
        mockCase0JosephDai.itfProvideLiquidity(TestConstants.USD_28_000_18DEC, block.timestamp);
        openSwapReceiveFixed(
            _userTwo,
            block.timestamp,
            TestConstants.TC_TOTAL_AMOUNT_10_000_18DEC,
            TestConstants.PERCENTAGE_1_18DEC,
            TestConstants.LEVERAGE_18DEC,
            mockCase0MiltonDai
        );
        // when
        (,, int256 soap) = calculateSoap(_userTwo, block.timestamp, mockCase0MiltonDai);
        // then
        assertEq(soap, expectedSoapBalance);
    }

    function testShouldCalculateSoapDAIReceiveFixedWhenAddPositionThenCalculateAfter25Days() public {
        // given
        _miltonSpreadModel.setCalculateQuotePayFixed(TestConstants.ZERO);
        _miltonSpreadModel.setCalculateQuoteReceiveFixed(TestConstants.PERCENTAGE_2_18DEC);
        ItfIporOracle iporOracle =
            getIporOracleAsset(_userOne, address(_daiMockedToken), TestConstants.TC_DEFAULT_EMA_18DEC_64UINT);
        IMarketSafetyOracle marketSafetyOracle = getMarketSafetyOracleAsset(
            _userOne,
            address(_daiMockedToken),
            TestConstants.MSO_UTILIZATION_RATE_48_PER,
            TestConstants.MSO_UTILIZATION_RATE_90_PER,
            TestConstants.MSO_NOTIONAL_1B
        );
        MockCase1Stanley mockCase1StanleyDai = getMockCase1Stanley(address(_daiMockedToken));
        MiltonStorage miltonStorageDai = getMiltonStorage();
        MockCase0MiltonDai mockCase0MiltonDai = getMockCase0MiltonDai(
            address(_daiMockedToken),
            address(iporOracle),
            address(miltonStorageDai),
            address(_miltonSpreadModel),
            address(mockCase1StanleyDai),
            address(marketSafetyOracle)
        );
        MockCase0JosephDai mockCase0JosephDai = getMockCase0JosephDai(
            address(_daiMockedToken),
            address(_ipTokenDai),
            address(mockCase0MiltonDai),
            address(miltonStorageDai),
            address(mockCase1StanleyDai)
        );
        int256 expectedSoapBalance = -68267191075554025634;
        prepareApproveForUsersDai(_users, _daiMockedToken, address(mockCase0JosephDai), address(mockCase0MiltonDai));
        prepareMilton(mockCase0MiltonDai, address(mockCase0JosephDai), address(mockCase1StanleyDai));
        prepareJoseph(mockCase0JosephDai);
        prepareIpToken(_ipTokenDai, address(mockCase0JosephDai));
        vm.prank(_liquidityProvider);
        mockCase0JosephDai.itfProvideLiquidity(TestConstants.USD_28_000_18DEC, block.timestamp);
        vm.prank(_userOne);
        iporOracle.itfUpdateIndex(address(_daiMockedToken), TestConstants.PERCENTAGE_3_18DEC, block.timestamp);
        openSwapReceiveFixed(
            _userTwo,
            block.timestamp,
            TestConstants.TC_TOTAL_AMOUNT_10_000_18DEC,
            TestConstants.PERCENTAGE_1_18DEC,
            TestConstants.LEVERAGE_18DEC,
            mockCase0MiltonDai
        );
        // when
        (,, int256 soap) =
            calculateSoap(_userTwo, block.timestamp + TestConstants.PERIOD_25_DAYS_IN_SECONDS, mockCase0MiltonDai);
        // then
        assertEq(soap, expectedSoapBalance);
    }

    function testShouldCalculateSoapDAIPayFixedWhenAddAndRemovePosition() public {
        // given
        _miltonSpreadModel.setCalculateQuotePayFixed(TestConstants.PERCENTAGE_2_18DEC);
        _miltonSpreadModel.setCalculateQuoteReceiveFixed(TestConstants.ZERO);
        ItfIporOracle iporOracle =
            getIporOracleAsset(_userOne, address(_daiMockedToken), TestConstants.TC_DEFAULT_EMA_18DEC_64UINT);
        IMarketSafetyOracle marketSafetyOracle = getMarketSafetyOracleAsset(
            _userOne,
            address(_daiMockedToken),
            TestConstants.MSO_UTILIZATION_RATE_48_PER,
            TestConstants.MSO_UTILIZATION_RATE_90_PER,
            TestConstants.MSO_NOTIONAL_1B
        );
        MockCase1Stanley mockCase1StanleyDai = getMockCase1Stanley(address(_daiMockedToken));
        MiltonStorage miltonStorageDai = getMiltonStorage();
        MockCase0MiltonDai mockCase0MiltonDai = getMockCase0MiltonDai(
            address(_daiMockedToken),
            address(iporOracle),
            address(miltonStorageDai),
            address(_miltonSpreadModel),
            address(mockCase1StanleyDai),
            address(marketSafetyOracle)
        );
        MockCase0JosephDai mockCase0JosephDai = getMockCase0JosephDai(
            address(_daiMockedToken),
            address(_ipTokenDai),
            address(mockCase0MiltonDai),
            address(miltonStorageDai),
            address(mockCase1StanleyDai)
        );
        int256 expectedSoapBalance = TestConstants.ZERO_INT;
        prepareApproveForUsersDai(_users, _daiMockedToken, address(mockCase0JosephDai), address(mockCase0MiltonDai));
        prepareMilton(mockCase0MiltonDai, address(mockCase0JosephDai), address(mockCase1StanleyDai));
        prepareJoseph(mockCase0JosephDai);
        prepareIpToken(_ipTokenDai, address(mockCase0JosephDai));
        vm.prank(_liquidityProvider);
        mockCase0JosephDai.itfProvideLiquidity(TestConstants.USD_28_000_18DEC, block.timestamp);
        vm.prank(_userOne);
        iporOracle.itfUpdateIndex(address(_daiMockedToken), TestConstants.PERCENTAGE_3_18DEC, block.timestamp);
        openSwapPayFixed(
            _userTwo,
            block.timestamp,
            TestConstants.TC_TOTAL_AMOUNT_10_000_18DEC,
            9 * TestConstants.D17,
            TestConstants.LEVERAGE_18DEC,
            mockCase0MiltonDai
        );
        // when
        vm.prank(_userTwo);
        mockCase0MiltonDai.itfCloseSwapPayFixed(1, block.timestamp + TestConstants.PERIOD_25_DAYS_IN_SECONDS);
        (,, int256 soap) =
            calculateSoap(_userTwo, block.timestamp + TestConstants.PERIOD_25_DAYS_IN_SECONDS, mockCase0MiltonDai);
        // then
        assertEq(soap, expectedSoapBalance);
    }

    function testShouldCalculateSoapDAIReceiveFixedWhenAddAndRemovePosition() public {
        // given
        _miltonSpreadModel.setCalculateQuotePayFixed(TestConstants.ZERO);
        _miltonSpreadModel.setCalculateQuoteReceiveFixed(TestConstants.PERCENTAGE_2_18DEC);
        ItfIporOracle iporOracle =
            getIporOracleAsset(_userOne, address(_daiMockedToken), TestConstants.TC_DEFAULT_EMA_18DEC_64UINT);
        IMarketSafetyOracle marketSafetyOracle = getMarketSafetyOracleAsset(
            _userOne,
            address(_daiMockedToken),
            TestConstants.MSO_UTILIZATION_RATE_48_PER,
            TestConstants.MSO_UTILIZATION_RATE_90_PER,
            TestConstants.MSO_NOTIONAL_1B
        );
        MockCase1Stanley mockCase1StanleyDai = getMockCase1Stanley(address(_daiMockedToken));
        MiltonStorage miltonStorageDai = getMiltonStorage();
        MockCase0MiltonDai mockCase0MiltonDai = getMockCase0MiltonDai(
            address(_daiMockedToken),
            address(iporOracle),
            address(miltonStorageDai),
            address(_miltonSpreadModel),
            address(mockCase1StanleyDai),
            address(marketSafetyOracle)
        );
        MockCase0JosephDai mockCase0JosephDai = getMockCase0JosephDai(
            address(_daiMockedToken),
            address(_ipTokenDai),
            address(mockCase0MiltonDai),
            address(miltonStorageDai),
            address(mockCase1StanleyDai)
        );
        int256 expectedSoapBalance = TestConstants.ZERO_INT;
        prepareApproveForUsersDai(_users, _daiMockedToken, address(mockCase0JosephDai), address(mockCase0MiltonDai));
        prepareMilton(mockCase0MiltonDai, address(mockCase0JosephDai), address(mockCase1StanleyDai));
        prepareJoseph(mockCase0JosephDai);
        prepareIpToken(_ipTokenDai, address(mockCase0JosephDai));
        vm.prank(_liquidityProvider);
        mockCase0JosephDai.itfProvideLiquidity(TestConstants.USD_28_000_18DEC, block.timestamp);
        vm.prank(_userOne);
        iporOracle.itfUpdateIndex(address(_daiMockedToken), TestConstants.PERCENTAGE_3_18DEC, block.timestamp);
        openSwapReceiveFixed(
            _userTwo,
            block.timestamp,
            TestConstants.TC_TOTAL_AMOUNT_10_000_18DEC,
            TestConstants.PERCENTAGE_1_18DEC,
            TestConstants.LEVERAGE_18DEC,
            mockCase0MiltonDai
        );
        // we are expecting that Milton will lose money, so we add more liquidity
        vm.prank(_liquidityProvider);
        mockCase0JosephDai.itfProvideLiquidity(TestConstants.TC_TOTAL_AMOUNT_10_000_18DEC, block.timestamp);
        // when
        vm.prank(_userTwo);
        mockCase0MiltonDai.itfCloseSwapReceiveFixed(1, block.timestamp + TestConstants.PERIOD_25_DAYS_IN_SECONDS);
        (,, int256 soap) =
            calculateSoap(_userTwo, block.timestamp + TestConstants.PERIOD_25_DAYS_IN_SECONDS, mockCase0MiltonDai);
        // then
        assertEq(soap, expectedSoapBalance);
    }

    function testShouldCalculateSoapWhenDAIPayFixedAndDAIReceiveFixed18Decimals() public {
        // given
        _miltonSpreadModel.setCalculateQuotePayFixed(TestConstants.PERCENTAGE_4_18DEC);
        _miltonSpreadModel.setCalculateQuoteReceiveFixed(TestConstants.PERCENTAGE_2_18DEC);
        ItfIporOracle iporOracle =
            getIporOracleAsset(_userOne, address(_daiMockedToken), TestConstants.TC_DEFAULT_EMA_18DEC_64UINT);
        IMarketSafetyOracle marketSafetyOracle = getMarketSafetyOracleAsset(
            _userOne,
            address(_daiMockedToken),
            TestConstants.MSO_UTILIZATION_RATE_48_PER,
            TestConstants.MSO_UTILIZATION_RATE_90_PER,
            TestConstants.MSO_NOTIONAL_1B
        );
        MockCase1Stanley mockCase1StanleyDai = getMockCase1Stanley(address(_daiMockedToken));
        MiltonStorage miltonStorageDai = getMiltonStorage();
        MockCase0MiltonDai mockCase0MiltonDai = getMockCase0MiltonDai(
            address(_daiMockedToken),
            address(iporOracle),
            address(miltonStorageDai),
            address(_miltonSpreadModel),
            address(mockCase1StanleyDai),
            address(marketSafetyOracle)
        );
        MockCase0JosephDai mockCase0JosephDai = getMockCase0JosephDai(
            address(_daiMockedToken),
            address(_ipTokenDai),
            address(mockCase0MiltonDai),
            address(miltonStorageDai),
            address(mockCase1StanleyDai)
        );
        int256 expectedSoapBalance = -136534382151108092229;
        prepareApproveForUsersDai(_users, _daiMockedToken, address(mockCase0JosephDai), address(mockCase0MiltonDai));
        prepareMilton(mockCase0MiltonDai, address(mockCase0JosephDai), address(mockCase1StanleyDai));
        prepareJoseph(mockCase0JosephDai);
        prepareIpToken(_ipTokenDai, address(mockCase0JosephDai));
        vm.prank(_liquidityProvider);
        mockCase0JosephDai.itfProvideLiquidity(2 * TestConstants.USD_28_000_18DEC, block.timestamp);
        vm.prank(_userOne);
        iporOracle.itfUpdateIndex(address(_daiMockedToken), TestConstants.PERCENTAGE_3_18DEC, block.timestamp);
        // when
        openSwapPayFixed(
            _userTwo,
            block.timestamp,
            TestConstants.TC_TOTAL_AMOUNT_10_000_18DEC,
            9 * TestConstants.D17,
            TestConstants.LEVERAGE_18DEC,
            mockCase0MiltonDai
        );
        openSwapReceiveFixed(
            _userTwo,
            block.timestamp,
            TestConstants.TC_TOTAL_AMOUNT_10_000_18DEC,
            TestConstants.PERCENTAGE_1_18DEC,
            TestConstants.LEVERAGE_18DEC,
            mockCase0MiltonDai
        );
        (,, int256 soap) =
            calculateSoap(_userTwo, block.timestamp + TestConstants.PERIOD_25_DAYS_IN_SECONDS, mockCase0MiltonDai);
        // then
        assertEq(soap, expectedSoapBalance);
    }

    function testShouldCalculateSoapWhenUSDTPayFixedAndUSDTReceiveFixed6Decimals() public {
        // given
        _miltonSpreadModel.setCalculateQuotePayFixed(TestConstants.PERCENTAGE_4_18DEC);
        _miltonSpreadModel.setCalculateQuoteReceiveFixed(TestConstants.PERCENTAGE_2_18DEC);
        ItfIporOracle iporOracle =
            getIporOracleAsset(_userOne, address(_usdtMockedToken), TestConstants.TC_DEFAULT_EMA_18DEC_64UINT);
        IMarketSafetyOracle marketSafetyOracle = getMarketSafetyOracleAsset(
            _userOne,
            address(_daiMockedToken),
            TestConstants.MSO_UTILIZATION_RATE_48_PER,
            TestConstants.MSO_UTILIZATION_RATE_90_PER,
            TestConstants.MSO_NOTIONAL_1B
        );
        IpToken ipTokenUsdt = getIpTokenUsdt(address(_usdtMockedToken));
        MockCase1Stanley mockCase1StanleyUsdt = getMockCase1Stanley(address(_usdtMockedToken));
        MiltonStorage miltonStorageUsdt = getMiltonStorage();
        MockCase0MiltonUsdt mockCase0MiltonUsdt = getMockCase0MiltonUsdt(
            address(_usdtMockedToken),
            address(iporOracle),
            address(miltonStorageUsdt),
            address(_miltonSpreadModel),
            address(mockCase1StanleyUsdt),
            address(marketSafetyOracle)
        );
        MockCase0JosephUsdt mockCase0JosephUsdt = getMockCase0JosephUsdt(
            address(_usdtMockedToken),
            address(ipTokenUsdt),
            address(mockCase0MiltonUsdt),
            address(miltonStorageUsdt),
            address(mockCase1StanleyUsdt)
        );
        int256 expectedSoapBalance = -136534382151108092229;
        prepareApproveForUsersUsd(_users, _usdtMockedToken, address(mockCase0JosephUsdt), address(mockCase0MiltonUsdt));
        prepareMilton(mockCase0MiltonUsdt, address(mockCase0JosephUsdt), address(mockCase1StanleyUsdt));
        prepareJoseph(mockCase0JosephUsdt);
        prepareIpToken(ipTokenUsdt, address(mockCase0JosephUsdt));
        vm.prank(_liquidityProvider);
        mockCase0JosephUsdt.itfProvideLiquidity(2 * TestConstants.USD_28_000_6DEC, block.timestamp);
        vm.prank(_userOne);
        iporOracle.itfUpdateIndex(address(_usdtMockedToken), TestConstants.PERCENTAGE_3_18DEC, block.timestamp);
        openSwapPayFixed(
            _userTwo,
            block.timestamp,
            TestConstants.TC_TOTAL_AMOUNT_10_000_6DEC,
            9 * TestConstants.D17,
            TestConstants.LEVERAGE_18DEC,
            mockCase0MiltonUsdt
        ); //
        openSwapReceiveFixed(
            _userTwo,
            block.timestamp,
            TestConstants.TC_TOTAL_AMOUNT_10_000_6DEC,
            TestConstants.PERCENTAGE_1_18DEC,
            TestConstants.LEVERAGE_18DEC,
            mockCase0MiltonUsdt
        );
        (,, int256 soap) =
            calculateSoap(_userTwo, block.timestamp + TestConstants.PERIOD_25_DAYS_IN_SECONDS, mockCase0MiltonUsdt);
        // then
        assertEq(soap, expectedSoapBalance);
    }

    function testShouldCalculateSoapWhenDAIPayFixedAndUSDTPayFixed() public {
        // given
        _miltonSpreadModel.setCalculateQuotePayFixed(TestConstants.PERCENTAGE_4_18DEC);
        _miltonSpreadModel.setCalculateQuoteReceiveFixed(TestConstants.ZERO);
        address[] memory tokenAddresses =
            addressesToArray(address(_usdtMockedToken), address(_usdcMockedToken), address(_daiMockedToken));
        address[] memory ipTokenAddresses =
            addressesToArray(address(_ipTokenUsdt), address(_ipTokenUsdc), address(_ipTokenDai));
        ItfIporOracle iporOracle = getIporOracleAssets(
            _userOne, tokenAddresses, uint32(block.timestamp), TestConstants.TC_DEFAULT_EMA_18DEC_64UINT, 0
        );
        IMarketSafetyOracle marketSafetyOracle = getMarketSafetyOracleAssets(
            _userOne,
            tokenAddresses,
            TestConstants.MSO_UTILIZATION_RATE_48_PER,
            TestConstants.MSO_UTILIZATION_RATE_90_PER,
            TestConstants.MSO_NOTIONAL_1B
        );
        address[] memory mockCase1StanleyAddresses = addressesToArray(
            address(getMockCase1Stanley(address(_usdtMockedToken))),
            address(getMockCase1Stanley(address(_usdcMockedToken))),
            address(getMockCase1Stanley(address(_daiMockedToken)))
        );
        MiltonStorages memory miltonStorages = getMiltonStorages();
        address[] memory miltonStorageAddresses = addressesToArray(
            address(miltonStorages.miltonStorageUsdt),
            address(miltonStorages.miltonStorageUsdc),
            address(miltonStorages.miltonStorageDai)
        );
        MockCase0Miltons memory mockCase0Miltons = getMockCase0Miltons(
            address(iporOracle),
            address(_miltonSpreadModel),
            address(_usdtMockedToken),
            address(_usdcMockedToken),
            address(_daiMockedToken),
            miltonStorageAddresses,
            mockCase1StanleyAddresses,
            address(marketSafetyOracle)
        );
        address[] memory mockCase0MiltonAddresses = addressesToArray(
            address(mockCase0Miltons.mockCase0MiltonUsdt),
            address(mockCase0Miltons.mockCase0MiltonUsdc),
            address(mockCase0Miltons.mockCase0MiltonDai)
        );
        MockCase0Josephs memory mockCase0Josephs = getMockCase0Josephs(
            tokenAddresses,
            ipTokenAddresses,
            mockCase0MiltonAddresses,
            miltonStorageAddresses,
            mockCase1StanleyAddresses
        );
        address[] memory mockCase0JosephAddresses = addressesToArray(
            address(mockCase0Josephs.mockCase0JosephUsdt),
            address(mockCase0Josephs.mockCase0JosephUsdc),
            address(mockCase0Josephs.mockCase0JosephDai)
        );
        int256 expectedSoapUsdt = -68267191075554066594;
        int256 expectedSoapDai = -68267191075554066594;
        uint256 endTimestamp = block.timestamp + TestConstants.PERIOD_25_DAYS_IN_SECONDS;
        prepareApproveForUsersUsd(
            _users,
            _usdtMockedToken,
            address(mockCase0Josephs.mockCase0JosephUsdt),
            address(mockCase0Miltons.mockCase0MiltonUsdt)
        );
        prepareApproveForUsersDai(
            _users,
            _daiMockedToken,
            address(mockCase0Josephs.mockCase0JosephDai),
            address(mockCase0Miltons.mockCase0MiltonDai)
        );

        prepareMilton(
            mockCase0Miltons.mockCase0MiltonUsdt,
            address(mockCase0Josephs.mockCase0JosephUsdt),
            mockCase1StanleyAddresses[0]
        );
        prepareMilton(
            mockCase0Miltons.mockCase0MiltonDai,
            address(mockCase0Josephs.mockCase0JosephDai),
            mockCase1StanleyAddresses[2]
        );
        prepareJoseph(mockCase0Josephs.mockCase0JosephUsdt);
        prepareJoseph(mockCase0Josephs.mockCase0JosephDai);
        prepareIpToken(_ipTokenUsdt, mockCase0JosephAddresses[0]);
        prepareIpToken(_ipTokenDai, mockCase0JosephAddresses[2]);
        vm.startPrank(_liquidityProvider);
        mockCase0Josephs.mockCase0JosephUsdt.itfProvideLiquidity(TestConstants.USD_28_000_6DEC, block.timestamp);
        mockCase0Josephs.mockCase0JosephDai.itfProvideLiquidity(TestConstants.USD_28_000_18DEC, block.timestamp);
        vm.stopPrank();
        vm.startPrank(_userOne);
        iporOracle.itfUpdateIndex(address(_usdtMockedToken), TestConstants.PERCENTAGE_3_18DEC, block.timestamp);
        iporOracle.itfUpdateIndex(address(_daiMockedToken), TestConstants.PERCENTAGE_3_18DEC, block.timestamp);
        vm.stopPrank();
        // when
        openSwapPayFixed(
            _userTwo,
            block.timestamp,
            TestConstants.TC_TOTAL_AMOUNT_10_000_6DEC,
            9 * TestConstants.D17,
            10 * Constants.D18,
            mockCase0Miltons.mockCase0MiltonUsdt
        );
        openSwapPayFixed(
            _userTwo,
            block.timestamp,
            TestConstants.TC_TOTAL_AMOUNT_10_000_18DEC,
            9 * TestConstants.D17,
            10 * Constants.D18,
            mockCase0Miltons.mockCase0MiltonDai
        );
        (,, int256 soapUsdt) = calculateSoap(_userTwo, endTimestamp, mockCase0Miltons.mockCase0MiltonUsdt);
        (,, int256 soapDai) = calculateSoap(_userTwo, endTimestamp, mockCase0Miltons.mockCase0MiltonDai);
        // then
        assertEq(soapUsdt, expectedSoapUsdt);
        assertEq(soapDai, expectedSoapDai);
    }

    function testShouldCalculateSoapWhenDAIPayFixedAndDAIReceiveFixedAndClosePayFixed() public {
        // given
        _miltonSpreadModel.setCalculateQuotePayFixed(TestConstants.PERCENTAGE_4_18DEC);
        _miltonSpreadModel.setCalculateQuoteReceiveFixed(TestConstants.PERCENTAGE_2_18DEC);
        ItfIporOracle iporOracle =
            getIporOracleAsset(_userOne, address(_daiMockedToken), TestConstants.TC_DEFAULT_EMA_18DEC_64UINT);
        IMarketSafetyOracle marketSafetyOracle = getMarketSafetyOracleAsset(
            _userOne,
            address(_daiMockedToken),
            TestConstants.MSO_UTILIZATION_RATE_48_PER,
            TestConstants.MSO_UTILIZATION_RATE_90_PER,
            TestConstants.MSO_NOTIONAL_1B
        );
        MockCase1Stanley mockCase1StanleyDai = getMockCase1Stanley(address(_daiMockedToken));
        MiltonStorage miltonStorageDai = getMiltonStorage();
        MockCase0MiltonDai mockCase0MiltonDai = getMockCase0MiltonDai(
            address(_daiMockedToken),
            address(iporOracle),
            address(miltonStorageDai),
            address(_miltonSpreadModel),
            address(mockCase1StanleyDai),
            address(marketSafetyOracle)
        );
        MockCase0JosephDai mockCase0JosephDai = getMockCase0JosephDai(
            address(_daiMockedToken),
            address(_ipTokenDai),
            address(mockCase0MiltonDai),
            address(miltonStorageDai),
            address(mockCase1StanleyDai)
        );
        int256 expectedSoapBalance = -68267191075554025634;
        uint256 endTimestamp = block.timestamp + TestConstants.PERIOD_25_DAYS_IN_SECONDS;
        prepareApproveForUsersDai(_users, _daiMockedToken, address(mockCase0JosephDai), address(mockCase0MiltonDai));
        prepareMilton(mockCase0MiltonDai, address(mockCase0JosephDai), address(mockCase1StanleyDai));
        prepareJoseph(mockCase0JosephDai);
        prepareIpToken(_ipTokenDai, address(mockCase0JosephDai));
        vm.prank(_liquidityProvider);
        mockCase0JosephDai.itfProvideLiquidity(2 * TestConstants.USD_28_000_18DEC, block.timestamp);
        vm.prank(_userOne);
        iporOracle.itfUpdateIndex(address(_daiMockedToken), TestConstants.PERCENTAGE_3_18DEC, block.timestamp);
        openSwapPayFixed(
            _userTwo,
            block.timestamp,
            TestConstants.TC_TOTAL_AMOUNT_10_000_18DEC,
            9 * TestConstants.D17,
            TestConstants.LEVERAGE_18DEC,
            mockCase0MiltonDai
        );
        openSwapReceiveFixed(
            _userTwo,
            block.timestamp,
            TestConstants.TC_TOTAL_AMOUNT_10_000_18DEC,
            TestConstants.PERCENTAGE_1_18DEC,
            TestConstants.LEVERAGE_18DEC,
            mockCase0MiltonDai
        );
        // when
        vm.prank(_userTwo);
        mockCase0MiltonDai.itfCloseSwapPayFixed(1, endTimestamp);
        (,, int256 soap) = calculateSoap(_userTwo, endTimestamp, mockCase0MiltonDai);
        // then
        assertEq(soap, expectedSoapBalance);
    }

    function testShouldCalculateSoapWhenDAIPayFixedAndDAIReceiveFixedAndCloseReceiveFixed() public {
        // given
        _miltonSpreadModel.setCalculateQuotePayFixed(TestConstants.PERCENTAGE_4_18DEC);
        _miltonSpreadModel.setCalculateQuoteReceiveFixed(TestConstants.PERCENTAGE_2_18DEC);
        ItfIporOracle iporOracle =
            getIporOracleAsset(_userOne, address(_daiMockedToken), TestConstants.TC_DEFAULT_EMA_18DEC_64UINT);
        IMarketSafetyOracle marketSafetyOracle = getMarketSafetyOracleAsset(
            _userOne,
            address(_daiMockedToken),
            TestConstants.MSO_UTILIZATION_RATE_48_PER,
            TestConstants.MSO_UTILIZATION_RATE_90_PER,
            TestConstants.MSO_NOTIONAL_1B
        );
        MockCase1Stanley mockCase1StanleyDai = getMockCase1Stanley(address(_daiMockedToken));
        MiltonStorage miltonStorageDai = getMiltonStorage();
        MockCase0MiltonDai mockCase0MiltonDai = getMockCase0MiltonDai(
            address(_daiMockedToken),
            address(iporOracle),
            address(miltonStorageDai),
            address(_miltonSpreadModel),
            address(mockCase1StanleyDai),
            address(marketSafetyOracle)
        );
        MockCase0JosephDai mockCase0JosephDai = getMockCase0JosephDai(
            address(_daiMockedToken),
            address(_ipTokenDai),
            address(mockCase0MiltonDai),
            address(miltonStorageDai),
            address(mockCase1StanleyDai)
        );
        int256 expectedSoapBalance = -68267191075554066594;
        uint256 endTimestamp = block.timestamp + TestConstants.PERIOD_25_DAYS_IN_SECONDS;
        prepareApproveForUsersDai(_users, _daiMockedToken, address(mockCase0JosephDai), address(mockCase0MiltonDai));
        prepareMilton(mockCase0MiltonDai, address(mockCase0JosephDai), address(mockCase1StanleyDai));
        prepareJoseph(mockCase0JosephDai);
        prepareIpToken(_ipTokenDai, address(mockCase0JosephDai));
        vm.prank(_liquidityProvider);
        mockCase0JosephDai.itfProvideLiquidity(2 * TestConstants.USD_28_000_18DEC, block.timestamp);
        vm.prank(_userOne);
        iporOracle.itfUpdateIndex(address(_daiMockedToken), TestConstants.PERCENTAGE_3_18DEC, block.timestamp);
        openSwapPayFixed(
            _userTwo,
            block.timestamp,
            TestConstants.TC_TOTAL_AMOUNT_10_000_18DEC,
            9 * TestConstants.D17,
            TestConstants.LEVERAGE_18DEC,
            mockCase0MiltonDai
        );
        openSwapReceiveFixed(
            _userTwo,
            block.timestamp,
            TestConstants.TC_TOTAL_AMOUNT_10_000_18DEC,
            TestConstants.PERCENTAGE_1_18DEC,
            TestConstants.LEVERAGE_18DEC,
            mockCase0MiltonDai
        );
        // when
        vm.prank(_userTwo);
        mockCase0MiltonDai.itfCloseSwapReceiveFixed(2, endTimestamp);
        (,, int256 soap) = calculateSoap(_userTwo, endTimestamp, mockCase0MiltonDai);
        // then
        assertEq(soap, expectedSoapBalance);
    }

    function testShouldCalculateSoapWhenDAIPayFixedAndUSDTReceiveFixedAndRemoveReceiveFixedPositionAfter25Days()
        public
    {
        // given
        _miltonSpreadModel.setCalculateQuotePayFixed(TestConstants.PERCENTAGE_4_18DEC);
        _miltonSpreadModel.setCalculateQuoteReceiveFixed(TestConstants.PERCENTAGE_2_18DEC);
        address[] memory tokenAddresses =
            addressesToArray(address(_usdtMockedToken), address(_usdcMockedToken), address(_daiMockedToken));
        address[] memory ipTokenAddresses =
            addressesToArray(address(_ipTokenUsdt), address(_ipTokenUsdc), address(_ipTokenDai));
        ItfIporOracle iporOracle = getIporOracleAssets(
            _userOne, tokenAddresses, uint32(block.timestamp), TestConstants.TC_DEFAULT_EMA_18DEC_64UINT, 0
        );
        IMarketSafetyOracle marketSafetyOracle = getMarketSafetyOracleAssets(
            _userOne,
            tokenAddresses,
            TestConstants.MSO_UTILIZATION_RATE_48_PER,
            TestConstants.MSO_UTILIZATION_RATE_90_PER,
            TestConstants.MSO_NOTIONAL_1B
        );
        address[] memory mockCase1StanleyAddresses = addressesToArray(
            address(getMockCase1Stanley(address(_usdtMockedToken))),
            address(getMockCase1Stanley(address(_usdcMockedToken))),
            address(getMockCase1Stanley(address(_daiMockedToken)))
        );
        MiltonStorages memory miltonStorages = getMiltonStorages();
        address[] memory miltonStorageAddresses = addressesToArray(
            address(miltonStorages.miltonStorageUsdt),
            address(miltonStorages.miltonStorageUsdc),
            address(miltonStorages.miltonStorageDai)
        );
        MockCase0Miltons memory mockCase0Miltons = getMockCase0Miltons(
            address(iporOracle),
            address(_miltonSpreadModel),
            address(_usdtMockedToken),
            address(_usdcMockedToken),
            address(_daiMockedToken),
            miltonStorageAddresses,
            mockCase1StanleyAddresses,
            address(marketSafetyOracle)
        );
        address[] memory mockCase0MiltonAddresses = addressesToArray(
            address(mockCase0Miltons.mockCase0MiltonUsdt),
            address(mockCase0Miltons.mockCase0MiltonUsdc),
            address(mockCase0Miltons.mockCase0MiltonDai)
        );
        MockCase0Josephs memory mockCase0Josephs = getMockCase0Josephs(
            tokenAddresses,
            ipTokenAddresses,
            mockCase0MiltonAddresses,
            miltonStorageAddresses,
            mockCase1StanleyAddresses
        );
        address[] memory mockCase0JosephAddresses = addressesToArray(
            address(mockCase0Josephs.mockCase0JosephUsdt),
            address(mockCase0Josephs.mockCase0JosephUsdc),
            address(mockCase0Josephs.mockCase0JosephDai)
        );
        int256 expectedSoapUsdt = TestConstants.ZERO_INT;
        int256 expectedSoapDai = -68267191075554066594;
        uint256 endTimestamp = block.timestamp + TestConstants.PERIOD_25_DAYS_IN_SECONDS;
        prepareApproveForUsersUsd(
            _users,
            _usdtMockedToken,
            address(mockCase0Josephs.mockCase0JosephUsdt),
            address(mockCase0Miltons.mockCase0MiltonUsdt)
        );
        prepareApproveForUsersDai(
            _users,
            _daiMockedToken,
            address(mockCase0Josephs.mockCase0JosephDai),
            address(mockCase0Miltons.mockCase0MiltonDai)
        );
        prepareMilton(
            mockCase0Miltons.mockCase0MiltonUsdt,
            address(mockCase0Josephs.mockCase0JosephUsdt),
            mockCase1StanleyAddresses[0]
        );
        prepareMilton(
            mockCase0Miltons.mockCase0MiltonDai,
            address(mockCase0Josephs.mockCase0JosephDai),
            mockCase1StanleyAddresses[2]
        );
        prepareJoseph(mockCase0Josephs.mockCase0JosephUsdt);
        prepareJoseph(mockCase0Josephs.mockCase0JosephDai);
        prepareIpToken(_ipTokenUsdt, mockCase0JosephAddresses[0]);
        prepareIpToken(_ipTokenDai, mockCase0JosephAddresses[2]);
        vm.startPrank(_liquidityProvider);
        mockCase0Josephs.mockCase0JosephUsdt.itfProvideLiquidity(TestConstants.USD_28_000_6DEC, block.timestamp);
        mockCase0Josephs.mockCase0JosephDai.itfProvideLiquidity(TestConstants.USD_28_000_18DEC, block.timestamp);
        vm.stopPrank();
        vm.startPrank(_userOne);
        iporOracle.itfUpdateIndex(address(_usdtMockedToken), TestConstants.PERCENTAGE_3_18DEC, block.timestamp);
        iporOracle.itfUpdateIndex(address(_daiMockedToken), TestConstants.PERCENTAGE_3_18DEC, block.timestamp);
        vm.stopPrank();
        // when
        openSwapReceiveFixed(
            _userTwo,
            block.timestamp,
            TestConstants.TC_TOTAL_AMOUNT_10_000_6DEC,
            TestConstants.PERCENTAGE_1_18DEC,
            TestConstants.LEVERAGE_18DEC,
            mockCase0Miltons.mockCase0MiltonUsdt
        );
        openSwapPayFixed(
            _userTwo,
            block.timestamp,
            TestConstants.TC_TOTAL_AMOUNT_10_000_18DEC,
            9 * TestConstants.D17,
            TestConstants.LEVERAGE_18DEC,
            mockCase0Miltons.mockCase0MiltonDai
        );
        // we are expecting that Milton will lose money on receive fixed, so we add more liquidity
        vm.prank(_liquidityProvider);
        mockCase0Josephs.mockCase0JosephUsdt.itfProvideLiquidity(
            TestConstants.TC_TOTAL_AMOUNT_10_000_6DEC, block.timestamp
        );
        // when
        vm.prank(_userTwo);
        mockCase0Miltons.mockCase0MiltonUsdt.itfCloseSwapReceiveFixed(1, endTimestamp);
        (,, int256 soapUsdt) = calculateSoap(_userTwo, endTimestamp, mockCase0Miltons.mockCase0MiltonUsdt);
        (,, int256 soapDai) = calculateSoap(_userTwo, endTimestamp, mockCase0Miltons.mockCase0MiltonDai);
        // then
        assertEq(soapUsdt, expectedSoapUsdt);
        assertEq(soapDai, expectedSoapDai);
    }

    function testShouldCalculateSoapWhenDAIPayFixedAndChangeIbtPriceAndWait25DaysAndThenCalculateSoap18Decimals()
        public
    {
        // given
        _miltonSpreadModel.setCalculateQuotePayFixed(TestConstants.PERCENTAGE_4_18DEC);
        _miltonSpreadModel.setCalculateQuoteReceiveFixed(TestConstants.ZERO);
        ItfIporOracle iporOracle =
            getIporOracleAsset(_userOne, address(_daiMockedToken), TestConstants.TC_DEFAULT_EMA_18DEC_64UINT);
        IMarketSafetyOracle marketSafetyOracle = getMarketSafetyOracleAsset(
            _userOne,
            address(_daiMockedToken),
            TestConstants.MSO_UTILIZATION_RATE_48_PER,
            TestConstants.MSO_UTILIZATION_RATE_90_PER,
            TestConstants.MSO_NOTIONAL_1B
        );
        MockCase0Stanley mockCase0StanleyDai = getMockCase0Stanley(address(_daiMockedToken));
        MiltonStorage miltonStorageDai = getMiltonStorage();
        MockCase0MiltonDai mockCase0MiltonDai = getMockCase0MiltonDai(
            address(_daiMockedToken),
            address(iporOracle),
            address(miltonStorageDai),
            address(_miltonSpreadModel),
            address(mockCase0StanleyDai),
            address(marketSafetyOracle)
        );
        MockCase0JosephDai mockCase0JosephDai = getMockCase0JosephDai(
            address(_daiMockedToken),
            address(_ipTokenDai),
            address(mockCase0MiltonDai),
            address(miltonStorageDai),
            address(mockCase0StanleyDai)
        );
        int256 expectedSoapBalance = 7918994164764269327487;
        uint256 endTimestamp = block.timestamp + TestConstants.PERIOD_25_DAYS_IN_SECONDS;
        prepareApproveForUsersDai(_users, _daiMockedToken, address(mockCase0JosephDai), address(mockCase0MiltonDai));
        prepareMilton(mockCase0MiltonDai, address(mockCase0JosephDai), address(mockCase0StanleyDai));
        prepareJoseph(mockCase0JosephDai);
        prepareIpToken(_ipTokenDai, address(mockCase0JosephDai));
        vm.prank(_liquidityProvider);
        mockCase0JosephDai.itfProvideLiquidity(TestConstants.USD_28_000_18DEC, block.timestamp);
        vm.prank(_userOne);
        iporOracle.itfUpdateIndex(address(_daiMockedToken), TestConstants.PERCENTAGE_3_18DEC, block.timestamp);
        openSwapPayFixed(
            _userTwo,
            block.timestamp,
            TestConstants.TC_TOTAL_AMOUNT_10_000_18DEC,
            9 * TestConstants.D17,
            TestConstants.LEVERAGE_18DEC,
            mockCase0MiltonDai
        );
        vm.startPrank(_userOne);
        iporOracle.itfUpdateIndex(address(_daiMockedToken), TestConstants.PERCENTAGE_120_18DEC, block.timestamp);
        iporOracle.itfUpdateIndex(address(_daiMockedToken), TestConstants.PERCENTAGE_6_18DEC, endTimestamp);
        vm.stopPrank();
        // when
        (,, int256 soap) = calculateSoap(_userTwo, endTimestamp, mockCase0MiltonDai);
        // then
        assertEq(soap, expectedSoapBalance);
    }

    function testShouldCalculateSoapWhenUSDTPayFixedAndChangeIbtPriceAndWait25DaysAndThenCalculateSoap6Decimals()
        public
    {
        // given
        _miltonSpreadModel.setCalculateQuotePayFixed(TestConstants.PERCENTAGE_4_18DEC);
        _miltonSpreadModel.setCalculateQuoteReceiveFixed(TestConstants.ZERO);
        ItfIporOracle iporOracle =
            getIporOracleAsset(_userOne, address(_usdtMockedToken), TestConstants.TC_DEFAULT_EMA_18DEC_64UINT);
        IMarketSafetyOracle marketSafetyOracle = getMarketSafetyOracleAsset(
            _userOne,
            address(_usdtMockedToken),
            TestConstants.MSO_UTILIZATION_RATE_48_PER,
            TestConstants.MSO_UTILIZATION_RATE_90_PER,
            TestConstants.MSO_NOTIONAL_1B
        );
        IpToken ipTokenUsdt = getIpTokenUsdt(address(_usdtMockedToken));
        MockCase1Stanley mockCase1StanleyUsdt = getMockCase1Stanley(address(_usdtMockedToken));
        MiltonStorage miltonStorageUsdt = getMiltonStorage();
        MockCase0MiltonUsdt mockCase0MiltonUsdt = getMockCase0MiltonUsdt(
            address(_usdtMockedToken),
            address(iporOracle),
            address(miltonStorageUsdt),
            address(_miltonSpreadModel),
            address(mockCase1StanleyUsdt),
            address(marketSafetyOracle)
        );
        MockCase0JosephUsdt mockCase0JosephUsdt = getMockCase0JosephUsdt(
            address(_usdtMockedToken),
            address(ipTokenUsdt),
            address(mockCase0MiltonUsdt),
            address(miltonStorageUsdt),
            address(mockCase1StanleyUsdt)
        );
        int256 expectedSoapBalance = 7918994164764269327487;
        uint256 endTimestamp = block.timestamp + TestConstants.PERIOD_25_DAYS_IN_SECONDS;
        prepareApproveForUsersUsd(_users, _usdtMockedToken, address(mockCase0JosephUsdt), address(mockCase0MiltonUsdt));
        prepareMilton(mockCase0MiltonUsdt, address(mockCase0JosephUsdt), address(mockCase1StanleyUsdt));
        prepareJoseph(mockCase0JosephUsdt);
        prepareIpToken(ipTokenUsdt, address(mockCase0JosephUsdt));
        vm.prank(_userOne);
        iporOracle.itfUpdateIndex(address(_usdtMockedToken), TestConstants.PERCENTAGE_3_18DEC, block.timestamp);
        vm.prank(_liquidityProvider);
        mockCase0JosephUsdt.itfProvideLiquidity(TestConstants.USD_28_000_6DEC, block.timestamp);
        openSwapPayFixed(
            _userTwo,
            block.timestamp,
            TestConstants.TC_TOTAL_AMOUNT_10_000_6DEC,
            9 * TestConstants.D17,
            TestConstants.LEVERAGE_18DEC,
            mockCase0MiltonUsdt
        );
        vm.startPrank(_userOne);
        iporOracle.itfUpdateIndex(address(_usdtMockedToken), TestConstants.PERCENTAGE_120_18DEC, block.timestamp);
        iporOracle.itfUpdateIndex(address(_usdtMockedToken), TestConstants.PERCENTAGE_6_18DEC, endTimestamp);
        vm.stopPrank();
        // when
        (,, int256 soap) = calculateSoap(_userTwo, endTimestamp, mockCase0MiltonUsdt);
        // then
        assertEq(soap, expectedSoapBalance);
    }

    function testShouldCalculateSoapWhenDAIPayFixedAndChangeIbtPriceAndCalculateSoapAfter28DaysAndCalculateSoapAfter50DaysAndCompare(
    ) public {
        // given
        _miltonSpreadModel.setCalculateQuotePayFixed(TestConstants.PERCENTAGE_4_18DEC);
        _miltonSpreadModel.setCalculateQuoteReceiveFixed(TestConstants.ZERO);
        ItfIporOracle iporOracle =
            getIporOracleAsset(_userOne, address(_daiMockedToken), TestConstants.TC_DEFAULT_EMA_18DEC_64UINT);
        IMarketSafetyOracle marketSafetyOracle = getMarketSafetyOracleAsset(
            _userOne,
            address(_daiMockedToken),
            TestConstants.MSO_UTILIZATION_RATE_48_PER,
            TestConstants.MSO_UTILIZATION_RATE_90_PER,
            TestConstants.MSO_NOTIONAL_1B
        );
        MockCase0Stanley mockCase0StanleyDai = getMockCase0Stanley(address(_daiMockedToken));
        MiltonStorage miltonStorageDai = getMiltonStorage();
        MockCase0MiltonDai mockCase0MiltonDai = getMockCase0MiltonDai(
            address(_daiMockedToken),
            address(iporOracle),
            address(miltonStorageDai),
            address(_miltonSpreadModel),
            address(mockCase0StanleyDai),
            address(marketSafetyOracle)
        );
        MockCase0JosephDai mockCase0JosephDai = getMockCase0JosephDai(
            address(_daiMockedToken),
            address(_ipTokenDai),
            address(mockCase0MiltonDai),
            address(miltonStorageDai),
            address(mockCase0StanleyDai)
        );
        int256 expectedSoapBalanceAfter28Days = 7935378290622402313573;
        int256 expectedSoapBalanceAfter50Days = 8055528546915377478426;
        prepareApproveForUsersDai(_users, _daiMockedToken, address(mockCase0JosephDai), address(mockCase0MiltonDai));
        prepareMilton(mockCase0MiltonDai, address(mockCase0JosephDai), address(mockCase0StanleyDai));
        prepareJoseph(mockCase0JosephDai);
        prepareIpToken(_ipTokenDai, address(mockCase0JosephDai));
        vm.prank(_liquidityProvider);
        mockCase0JosephDai.itfProvideLiquidity(TestConstants.USD_28_000_18DEC, block.timestamp);
        vm.prank(_userOne);
        iporOracle.itfUpdateIndex(address(_daiMockedToken), TestConstants.PERCENTAGE_3_18DEC, block.timestamp);
        openSwapPayFixed(
            _userTwo,
            block.timestamp,
            TestConstants.TC_TOTAL_AMOUNT_10_000_18DEC,
            9 * TestConstants.D17,
            TestConstants.LEVERAGE_18DEC,
            mockCase0MiltonDai
        );
        vm.startPrank(_userOne);
        iporOracle.itfUpdateIndex(address(_daiMockedToken), TestConstants.PERCENTAGE_120_18DEC, block.timestamp);
        iporOracle.itfUpdateIndex(
            address(_daiMockedToken),
            TestConstants.PERCENTAGE_6_18DEC,
            block.timestamp + TestConstants.PERIOD_25_DAYS_IN_SECONDS
        );
        vm.stopPrank();
        // when
        // then
        (,, int256 soap28Days) =
            calculateSoap(_userTwo, block.timestamp + TestConstants.PERIOD_28_DAYS_IN_SECONDS, mockCase0MiltonDai);
        assertEq(soap28Days, expectedSoapBalanceAfter28Days);
        (,, int256 soap50Days) =
            calculateSoap(_userTwo, block.timestamp + TestConstants.PERIOD_50_DAYS_IN_SECONDS, mockCase0MiltonDai);
        assertEq(soap50Days, expectedSoapBalanceAfter50Days);
    }

    function testShouldCalculateSoapWhenDAIPayFixedAndWait25DaysAndDAIPayFixedAndWait25DaysAndThenCalculateSoap()
        public
    {
        // given
        _miltonSpreadModel.setCalculateQuotePayFixed(TestConstants.PERCENTAGE_4_18DEC);
        _miltonSpreadModel.setCalculateQuoteReceiveFixed(TestConstants.ZERO);
        ItfIporOracle iporOracle =
            getIporOracleAsset(_userOne, address(_daiMockedToken), TestConstants.TC_DEFAULT_EMA_18DEC_64UINT);
        IMarketSafetyOracle marketSafetyOracle = getMarketSafetyOracleAsset(
            _userOne,
            address(_daiMockedToken),
            TestConstants.MSO_UTILIZATION_RATE_48_PER,
            TestConstants.MSO_UTILIZATION_RATE_90_PER,
            TestConstants.MSO_NOTIONAL_1B
        );
        MockCase0Stanley mockCase0StanleyDai = getMockCase0Stanley(address(_daiMockedToken));
        MiltonStorage miltonStorageDai = getMiltonStorage();
        MockCase0MiltonDai mockCase0MiltonDai = getMockCase0MiltonDai(
            address(_daiMockedToken),
            address(iporOracle),
            address(miltonStorageDai),
            address(_miltonSpreadModel),
            address(mockCase0StanleyDai),
            address(marketSafetyOracle)
        );
        MockCase0JosephDai mockCase0JosephDai = getMockCase0JosephDai(
            address(_daiMockedToken),
            address(_ipTokenDai),
            address(mockCase0MiltonDai),
            address(miltonStorageDai),
            address(mockCase0StanleyDai)
        );
        int256 expectedSoapBalanceAfter50Days = -205221535441070939561;
        prepareApproveForUsersDai(_users, _daiMockedToken, address(mockCase0JosephDai), address(mockCase0MiltonDai));
        prepareMilton(mockCase0MiltonDai, address(mockCase0JosephDai), address(mockCase0StanleyDai));
        prepareJoseph(mockCase0JosephDai);
        prepareIpToken(_ipTokenDai, address(mockCase0JosephDai));
        vm.prank(_liquidityProvider);
        mockCase0JosephDai.itfProvideLiquidity(2 * TestConstants.USD_28_000_18DEC, block.timestamp);
        // when
        vm.prank(_userOne);
        iporOracle.itfUpdateIndex(address(_daiMockedToken), TestConstants.PERCENTAGE_3_18DEC, block.timestamp);
        openSwapPayFixed(
            _userTwo,
            block.timestamp,
            TestConstants.TC_TOTAL_AMOUNT_10_000_18DEC,
            9 * TestConstants.D17,
            TestConstants.LEVERAGE_18DEC,
            mockCase0MiltonDai
        );
        openSwapPayFixed(
            _userTwo,
            block.timestamp + TestConstants.PERIOD_25_DAYS_IN_SECONDS,
            TestConstants.TC_TOTAL_AMOUNT_10_000_18DEC,
            9 * TestConstants.D17,
            TestConstants.LEVERAGE_18DEC,
            mockCase0MiltonDai
        );
        // then
        (,, int256 soap50Days) =
            calculateSoap(_userTwo, block.timestamp + TestConstants.PERIOD_50_DAYS_IN_SECONDS, mockCase0MiltonDai);
        assertEq(soap50Days, expectedSoapBalanceAfter50Days);
    }

    function testShouldCalculateSoapWhenDAYPayFixedAndWait25DaysAndUpdateIPORAndDAIPayFixedAndWait25DaysAndUpdateIPORAndThenCalculateSoap(
    ) public {
        // given
        _miltonSpreadModel.setCalculateQuotePayFixed(TestConstants.PERCENTAGE_4_18DEC);
        _miltonSpreadModel.setCalculateQuoteReceiveFixed(TestConstants.ZERO);
        ItfIporOracle iporOracle =
            getIporOracleAsset(_userOne, address(_daiMockedToken), TestConstants.TC_DEFAULT_EMA_18DEC_64UINT);
        IMarketSafetyOracle marketSafetyOracle = getMarketSafetyOracleAsset(
            _userOne,
            address(_daiMockedToken),
            TestConstants.MSO_UTILIZATION_RATE_48_PER,
            TestConstants.MSO_UTILIZATION_RATE_90_PER,
            TestConstants.MSO_NOTIONAL_1B
        );
        MockCase0Stanley mockCase0StanleyDai = getMockCase0Stanley(address(_daiMockedToken));
        MiltonStorage miltonStorageDai = getMiltonStorage();
        MockCase0MiltonDai mockCase0MiltonDai = getMockCase0MiltonDai(
            address(_daiMockedToken),
            address(iporOracle),
            address(miltonStorageDai),
            address(_miltonSpreadModel),
            address(mockCase0StanleyDai),
            address(marketSafetyOracle)
        );
        MockCase0JosephDai mockCase0JosephDai = getMockCase0JosephDai(
            address(_daiMockedToken),
            address(_ipTokenDai),
            address(mockCase0MiltonDai),
            address(miltonStorageDai),
            address(mockCase0StanleyDai)
        );
        int256 expectedSoapBalanceAfter50Days = -205221535441070939561;
        prepareApproveForUsersDai(_users, _daiMockedToken, address(mockCase0JosephDai), address(mockCase0MiltonDai));
        prepareMilton(mockCase0MiltonDai, address(mockCase0JosephDai), address(mockCase0StanleyDai));
        prepareJoseph(mockCase0JosephDai);
        prepareIpToken(_ipTokenDai, address(mockCase0JosephDai));
        vm.prank(_liquidityProvider);
        mockCase0JosephDai.itfProvideLiquidity(2 * TestConstants.USD_28_000_18DEC, block.timestamp);
        // when
        vm.prank(_userOne);
        iporOracle.itfUpdateIndex(address(_daiMockedToken), TestConstants.PERCENTAGE_3_18DEC, block.timestamp);
        openSwapPayFixed(
            _userTwo,
            block.timestamp,
            TestConstants.TC_TOTAL_AMOUNT_10_000_18DEC,
            9 * TestConstants.D17,
            TestConstants.LEVERAGE_18DEC,
            mockCase0MiltonDai
        );
        vm.prank(_userOne);
        iporOracle.itfUpdateIndex(
            address(_daiMockedToken),
            TestConstants.PERCENTAGE_3_18DEC,
            block.timestamp + TestConstants.PERIOD_25_DAYS_IN_SECONDS
        );
        openSwapPayFixed(
            _userTwo,
            block.timestamp + TestConstants.PERIOD_25_DAYS_IN_SECONDS,
            TestConstants.TC_TOTAL_AMOUNT_10_000_18DEC,
            9 * TestConstants.D17,
            10 * Constants.D18,
            mockCase0MiltonDai
        );
        vm.prank(_userOne);
        iporOracle.itfUpdateIndex(
            address(_daiMockedToken),
            TestConstants.PERCENTAGE_3_18DEC,
            block.timestamp + TestConstants.PERIOD_50_DAYS_IN_SECONDS
        );
        // then
        (,, int256 soap50Days) =
            calculateSoap(_userTwo, block.timestamp + TestConstants.PERIOD_50_DAYS_IN_SECONDS, mockCase0MiltonDai);
        assertEq(soap50Days, expectedSoapBalanceAfter50Days);
    }

    function testShouldCalculateExactlyTheSameSoapWithAndWithoutUpdateIPORWithTheSameIndexValueWhenDAIPayFixed25And50DaysPeriod(
    ) public {
        // given
        _miltonSpreadModel.setCalculateQuotePayFixed(TestConstants.PERCENTAGE_4_18DEC);
        _miltonSpreadModel.setCalculateQuoteReceiveFixed(TestConstants.ZERO);
        ItfIporOracle iporOracle =
            getIporOracleAsset(_userOne, address(_daiMockedToken), TestConstants.TC_DEFAULT_EMA_18DEC_64UINT);
        IMarketSafetyOracle marketSafetyOracle = getMarketSafetyOracleAsset(
            _userOne,
            address(_daiMockedToken),
            TestConstants.MSO_UTILIZATION_RATE_48_PER,
            TestConstants.MSO_UTILIZATION_RATE_90_PER,
            TestConstants.MSO_NOTIONAL_1B
        );
        MockCase0Stanley mockCase0StanleyDai = getMockCase0Stanley(address(_daiMockedToken));
        MiltonStorage miltonStorageDai = getMiltonStorage();
        MockCase0MiltonDai mockCase0MiltonDai = getMockCase0MiltonDai(
            address(_daiMockedToken),
            address(iporOracle),
            address(miltonStorageDai),
            address(_miltonSpreadModel),
            address(mockCase0StanleyDai),
            address(marketSafetyOracle)
        );
        MockCase0JosephDai mockCase0JosephDai = getMockCase0JosephDai(
            address(_daiMockedToken),
            address(_ipTokenDai),
            address(mockCase0MiltonDai),
            address(miltonStorageDai),
            address(mockCase0StanleyDai)
        );
        prepareApproveForUsersDai(_users, _daiMockedToken, address(mockCase0JosephDai), address(mockCase0MiltonDai));
        prepareMilton(mockCase0MiltonDai, address(mockCase0JosephDai), address(mockCase0StanleyDai));
        prepareJoseph(mockCase0JosephDai);
        prepareIpToken(_ipTokenDai, address(mockCase0JosephDai));
        vm.prank(_liquidityProvider);
        mockCase0JosephDai.itfProvideLiquidity(TestConstants.USD_28_000_18DEC, block.timestamp);
        // when
        vm.prank(_userOne);
        iporOracle.itfUpdateIndex(address(_daiMockedToken), TestConstants.PERCENTAGE_3_18DEC, block.timestamp);
        openSwapPayFixed(
            _userTwo,
            block.timestamp,
            TestConstants.TC_TOTAL_AMOUNT_10_000_18DEC,
            9 * TestConstants.D17,
            TestConstants.LEVERAGE_18DEC,
            mockCase0MiltonDai
        );
        (,, int256 soapBeforeUpdateIndex) =
            calculateSoap(_userTwo, block.timestamp + TestConstants.PERIOD_50_DAYS_IN_SECONDS, mockCase0MiltonDai);
        vm.prank(_userOne);
        iporOracle.itfUpdateIndex(
            address(_daiMockedToken),
            TestConstants.PERCENTAGE_3_18DEC,
            block.timestamp + TestConstants.PERIOD_25_DAYS_IN_SECONDS
        );
        (,, int256 soapAfterUpdateIndex25Days) =
            calculateSoap(_userTwo, block.timestamp + TestConstants.PERIOD_50_DAYS_IN_SECONDS, mockCase0MiltonDai);
        vm.prank(_userOne);
        iporOracle.itfUpdateIndex(
            address(_daiMockedToken),
            TestConstants.PERCENTAGE_3_18DEC,
            block.timestamp + TestConstants.PERIOD_50_DAYS_IN_SECONDS
        );
        (,, int256 soapAfterUpdateIndex50Days) =
            calculateSoap(_userTwo, block.timestamp + TestConstants.PERIOD_50_DAYS_IN_SECONDS, mockCase0MiltonDai);
        // then
        int256 expectedSoapBeforeUpdateIndex = -136534382151108133189;
        int256 expectedSoapAfterUpdateIndex25Days = -136534382151108133189;
        int256 expectedSoapBalanceAfter50Days = -136534382151108133189;
        assertEq(soapBeforeUpdateIndex, expectedSoapBeforeUpdateIndex);
        assertEq(soapAfterUpdateIndex25Days, expectedSoapAfterUpdateIndex25Days);
        assertEq(soapAfterUpdateIndex50Days, expectedSoapBalanceAfter50Days);
    }

    function testShouldCalculateNegativeSoapWhenDAIPayFixedAndWait25DaysAndUpdateIbtPriceAfterSwapOpened() public {
        // given
        _miltonSpreadModel.setCalculateQuotePayFixed(TestConstants.PERCENTAGE_4_18DEC);
        _miltonSpreadModel.setCalculateQuoteReceiveFixed(TestConstants.ZERO);
        ItfIporOracle iporOracle =
            getIporOracleAsset(_userOne, address(_daiMockedToken), TestConstants.TC_DEFAULT_EMA_18DEC_64UINT);
        IMarketSafetyOracle marketSafetyOracle = getMarketSafetyOracleAsset(
            _userOne,
            address(_daiMockedToken),
            TestConstants.MSO_UTILIZATION_RATE_48_PER,
            TestConstants.MSO_UTILIZATION_RATE_90_PER,
            TestConstants.MSO_NOTIONAL_1B
        );
        MockCase1Stanley mockCase1StanleyDai = getMockCase1Stanley(address(_daiMockedToken));
        MiltonStorage miltonStorageDai = getMiltonStorage();
        MockCase0MiltonDai mockCase0MiltonDai = getMockCase0MiltonDai(
            address(_daiMockedToken),
            address(iporOracle),
            address(miltonStorageDai),
            address(_miltonSpreadModel),
            address(mockCase1StanleyDai),
            address(marketSafetyOracle)
        );
        MockCase0JosephDai mockCase0JosephDai = getMockCase0JosephDai(
            address(_daiMockedToken),
            address(_ipTokenDai),
            address(mockCase0MiltonDai),
            address(miltonStorageDai),
            address(mockCase1StanleyDai)
        );
        prepareApproveForUsersDai(_users, _daiMockedToken, address(mockCase0JosephDai), address(mockCase0MiltonDai));
        prepareMilton(mockCase0MiltonDai, address(mockCase0JosephDai), address(mockCase1StanleyDai));
        prepareJoseph(mockCase0JosephDai);
        prepareIpToken(_ipTokenDai, address(mockCase0JosephDai));
        vm.prank(_liquidityProvider);
        mockCase0JosephDai.itfProvideLiquidity(TestConstants.USD_28_000_18DEC, block.timestamp);
        vm.prank(_userOne);
        iporOracle.itfUpdateIndex(address(_daiMockedToken), TestConstants.PERCENTAGE_3_18DEC, block.timestamp);
        openSwapPayFixed(
            _userTwo,
            block.timestamp + TestConstants.PERIOD_1_DAY_IN_SECONDS,
            TestConstants.TC_TOTAL_AMOUNT_10_000_18DEC,
            9 * TestConstants.D17,
            TestConstants.LEVERAGE_18DEC,
            mockCase0MiltonDai
        );
        int256 expectedSoap = TestConstants.ZERO_INT;
        // when
        vm.prank(_userOne);
        iporOracle.itfUpdateIndex(
            address(_daiMockedToken),
            TestConstants.PERCENTAGE_3_18DEC,
            block.timestamp + TestConstants.PERIOD_1_DAY_IN_SECONDS
        );
        (,, int256 soapRightAfterOpenedPayFixedSwap) =
            calculateSoap(_userTwo, block.timestamp + TestConstants.PERIOD_1_DAY_IN_SECONDS + 100, mockCase0MiltonDai);
        // then
        assertLt(soapRightAfterOpenedPayFixedSwap, expectedSoap);
    }

    function testShouldCalculateSoapWhenDAIPayFixedAnd2xAndWait50Days() public {
        // given
        _miltonSpreadModel.setCalculateQuotePayFixed(TestConstants.PERCENTAGE_4_18DEC);
        _miltonSpreadModel.setCalculateQuoteReceiveFixed(TestConstants.ZERO);
        ItfIporOracle iporOracle =
            getIporOracleAsset(_userOne, address(_daiMockedToken), TestConstants.TC_DEFAULT_EMA_18DEC_64UINT);
        IMarketSafetyOracle marketSafetyOracle = getMarketSafetyOracleAsset(
            _userOne,
            address(_daiMockedToken),
            TestConstants.MSO_UTILIZATION_RATE_48_PER,
            TestConstants.MSO_UTILIZATION_RATE_90_PER,
            TestConstants.MSO_NOTIONAL_1B
        );
        MockCase0Stanley mockCase0StanleyDai = getMockCase0Stanley(address(_daiMockedToken));
        MiltonStorage miltonStorageDai = getMiltonStorage();
        MockCase0MiltonDai mockCase0MiltonDai = getMockCase0MiltonDai(
            address(_daiMockedToken),
            address(iporOracle),
            address(miltonStorageDai),
            address(_miltonSpreadModel),
            address(mockCase0StanleyDai),
            address(marketSafetyOracle)
        );
        MockCase0JosephDai mockCase0JosephDai = getMockCase0JosephDai(
            address(_daiMockedToken),
            address(_ipTokenDai),
            address(mockCase0MiltonDai),
            address(miltonStorageDai),
            address(mockCase0StanleyDai)
        );
        int256 expectedSoap50Days = -205221535441070939561;
        prepareApproveForUsersDai(_users, _daiMockedToken, address(mockCase0JosephDai), address(mockCase0MiltonDai));
        prepareMilton(mockCase0MiltonDai, address(mockCase0JosephDai), address(mockCase0StanleyDai));
        prepareJoseph(mockCase0JosephDai);
        prepareIpToken(_ipTokenDai, address(mockCase0JosephDai));
        vm.prank(_liquidityProvider);
        mockCase0JosephDai.itfProvideLiquidity(2 * TestConstants.USD_28_000_18DEC, block.timestamp);
        // when
        vm.prank(_userOne);
        iporOracle.itfUpdateIndex(address(_daiMockedToken), TestConstants.PERCENTAGE_3_18DEC, block.timestamp);
        openSwapPayFixed(
            _userTwo,
            block.timestamp,
            TestConstants.TC_TOTAL_AMOUNT_10_000_18DEC,
            9 * TestConstants.D17,
            TestConstants.LEVERAGE_18DEC,
            mockCase0MiltonDai
        );
        vm.prank(_userOne);
        iporOracle.itfUpdateIndex(
            address(_daiMockedToken),
            TestConstants.PERCENTAGE_3_18DEC,
            block.timestamp + TestConstants.PERIOD_25_DAYS_IN_SECONDS
        );
        openSwapPayFixed(
            _userTwo,
            block.timestamp + TestConstants.PERIOD_25_DAYS_IN_SECONDS,
            TestConstants.TC_TOTAL_AMOUNT_10_000_18DEC,
            9 * TestConstants.D17,
            TestConstants.LEVERAGE_18DEC,
            mockCase0MiltonDai
        );
        vm.prank(_userOne);
        iporOracle.itfUpdateIndex(
            address(_daiMockedToken),
            TestConstants.PERCENTAGE_3_18DEC,
            block.timestamp + TestConstants.PERIOD_50_DAYS_IN_SECONDS
        );
        (,, int256 soap50Days) =
            calculateSoap(_userTwo, block.timestamp + TestConstants.PERIOD_50_DAYS_IN_SECONDS, mockCase0MiltonDai);
        // then
        assertEq(soap50Days, expectedSoap50Days);
    }

    function testShouldCalculateSoapEqualZeroWhenDAIPayFixedAtIPOR3PercentAndIPOR5PercentAfter25DaysAndDAIPayFixedAndIPOR6PercentAfter50DaysAndCloseAllSwapsAfter75DaysComplexTotalAmounts(
    ) public {
        // given
        _miltonSpreadModel.setCalculateQuoteReceiveFixed(TestConstants.ZERO);
        ItfIporOracle iporOracle =
            getIporOracleAsset(_userOne, address(_daiMockedToken), TestConstants.TC_DEFAULT_EMA_18DEC_64UINT);
        IMarketSafetyOracle marketSafetyOracle = getMarketSafetyOracleAsset(
            _userOne,
            address(_daiMockedToken),
            TestConstants.MSO_UTILIZATION_RATE_48_PER,
            TestConstants.MSO_UTILIZATION_RATE_90_PER,
            TestConstants.MSO_NOTIONAL_1B
        );
        MockCase0Stanley mockCase0StanleyDai = getMockCase0Stanley(address(_daiMockedToken));
        MiltonStorage miltonStorageDai = getMiltonStorage();
        MockCase0MiltonDai mockCase0MiltonDai = getMockCase0MiltonDai(
            address(_daiMockedToken),
            address(iporOracle),
            address(miltonStorageDai),
            address(_miltonSpreadModel),
            address(mockCase0StanleyDai),
            address(marketSafetyOracle)
        );
        MockCase0JosephDai mockCase0JosephDai = getMockCase0JosephDai(
            address(_daiMockedToken),
            address(_ipTokenDai),
            address(mockCase0MiltonDai),
            address(miltonStorageDai),
            address(mockCase0StanleyDai)
        );
        int256 expectedSoap75Days = TestConstants.ZERO_INT;
        prepareApproveForUsersDai(_users, _daiMockedToken, address(mockCase0JosephDai), address(mockCase0MiltonDai));
        prepareMilton(mockCase0MiltonDai, address(mockCase0JosephDai), address(mockCase0StanleyDai));
        prepareJoseph(mockCase0JosephDai);
        prepareIpToken(_ipTokenDai, address(mockCase0JosephDai));
        _miltonSpreadModel.setCalculateQuotePayFixed(TestConstants.PERCENTAGE_6_18DEC);
        vm.prank(_liquidityProvider);
        mockCase0JosephDai.itfProvideLiquidity(2 * TestConstants.USD_28_000_18DEC, block.timestamp);
        // when
        vm.prank(_userOne);
        iporOracle.itfUpdateIndex(address(_daiMockedToken), TestConstants.PERCENTAGE_3_18DEC, block.timestamp);
        openSwapPayFixed(
            _userTwo,
            block.timestamp,
            1000348983489384893923,
            9 * TestConstants.D17,
            TestConstants.LEVERAGE_1000_18DEC,
            mockCase0MiltonDai
        );
        vm.prank(_userOne);
        iporOracle.itfUpdateIndex(
            address(_daiMockedToken),
            TestConstants.PERCENTAGE_5_18DEC,
            block.timestamp + TestConstants.PERIOD_25_DAYS_IN_SECONDS
        );
        openSwapPayFixed(
            _userTwo,
            block.timestamp + TestConstants.PERIOD_25_DAYS_IN_SECONDS,
            1492747383748202058744,
            1500000000000000000,
            TestConstants.LEVERAGE_1000_18DEC,
            mockCase0MiltonDai
        );
        vm.startPrank(_userOne);
        iporOracle.itfUpdateIndex(
            address(_daiMockedToken),
            TestConstants.PERCENTAGE_6_18DEC,
            block.timestamp + TestConstants.PERIOD_50_DAYS_IN_SECONDS
        );
        mockCase0MiltonDai.itfCloseSwapPayFixed(1, TestConstants.PERIOD_75_DAYS_IN_SECONDS);
        mockCase0MiltonDai.itfCloseSwapPayFixed(2, TestConstants.PERIOD_75_DAYS_IN_SECONDS);
        vm.stopPrank();
        // then
        (,, int256 soap75Days) =
            calculateSoap(_userTwo, block.timestamp + TestConstants.PERIOD_75_DAYS_IN_SECONDS, mockCase0MiltonDai);
        assertEq(soap75Days, expectedSoap75Days);
    }

    function testShouldCalculateSoapEqualZeroWhenDAIPayFixedAtIPOR3PercentAndIPOR5PercentAfter25DaysAndDAIPayFixedAndIPOR6PercentAfter50DaysAndCloseAllSwapsAfter75DaysSimpleTotalAmounts(
    ) public {
        // given
        _miltonSpreadModel.setCalculateQuotePayFixed(TestConstants.PERCENTAGE_4_18DEC);
        _miltonSpreadModel.setCalculateQuoteReceiveFixed(TestConstants.ZERO);
        ItfIporOracle iporOracle =
            getIporOracleAsset(_userOne, address(_daiMockedToken), TestConstants.TC_DEFAULT_EMA_18DEC_64UINT);
        IMarketSafetyOracle marketSafetyOracle = getMarketSafetyOracleAsset(
            _userOne,
            address(_daiMockedToken),
            TestConstants.MSO_UTILIZATION_RATE_48_PER,
            TestConstants.MSO_UTILIZATION_RATE_90_PER,
            TestConstants.MSO_NOTIONAL_1B
        );
        MockCase0Stanley mockCase0StanleyDai = getMockCase0Stanley(address(_daiMockedToken));
        MiltonStorage miltonStorageDai = getMiltonStorage();
        MockCase0MiltonDai mockCase0MiltonDai = getMockCase0MiltonDai(
            address(_daiMockedToken),
            address(iporOracle),
            address(miltonStorageDai),
            address(_miltonSpreadModel),
            address(mockCase0StanleyDai),
            address(marketSafetyOracle)
        );
        MockCase0JosephDai mockCase0JosephDai = getMockCase0JosephDai(
            address(_daiMockedToken),
            address(_ipTokenDai),
            address(mockCase0MiltonDai),
            address(miltonStorageDai),
            address(mockCase0StanleyDai)
        );
        int256 expectedSoap75Days = TestConstants.ZERO_INT;
        prepareApproveForUsersDai(_users, _daiMockedToken, address(mockCase0JosephDai), address(mockCase0MiltonDai));
        prepareMilton(mockCase0MiltonDai, address(mockCase0JosephDai), address(mockCase0StanleyDai));
        prepareJoseph(mockCase0JosephDai);
        prepareIpToken(_ipTokenDai, address(mockCase0JosephDai));
        _miltonSpreadModel.setCalculateQuotePayFixed(TestConstants.PERCENTAGE_6_18DEC);
        vm.prank(_liquidityProvider);
        mockCase0JosephDai.itfProvideLiquidity(2 * TestConstants.USD_28_000_18DEC, block.timestamp);
        // when
        vm.prank(_userOne);
        iporOracle.itfUpdateIndex(address(_daiMockedToken), TestConstants.PERCENTAGE_3_18DEC, block.timestamp);
        openSwapPayFixed(
            _userTwo,
            block.timestamp,
            1040000000000000000000,
            9 * TestConstants.D17,
            TestConstants.LEVERAGE_1000_18DEC,
            mockCase0MiltonDai
        );
        vm.prank(_userOne);
        iporOracle.itfUpdateIndex(
            address(_daiMockedToken),
            TestConstants.PERCENTAGE_5_18DEC,
            block.timestamp + TestConstants.PERIOD_25_DAYS_IN_SECONDS
        );
        openSwapPayFixed(
            _userTwo,
            block.timestamp + TestConstants.PERIOD_25_DAYS_IN_SECONDS,
            1040000000000000000000,
            1500000000000000000,
            TestConstants.LEVERAGE_1000_18DEC,
            mockCase0MiltonDai
        );
        vm.startPrank(_userOne);
        iporOracle.itfUpdateIndex(
            address(_daiMockedToken),
            TestConstants.PERCENTAGE_6_18DEC,
            block.timestamp + TestConstants.PERIOD_50_DAYS_IN_SECONDS
        );
        mockCase0MiltonDai.itfCloseSwapPayFixed(1, TestConstants.PERIOD_75_DAYS_IN_SECONDS);
        mockCase0MiltonDai.itfCloseSwapPayFixed(2, TestConstants.PERIOD_75_DAYS_IN_SECONDS);
        vm.stopPrank();
        // then
        (,, int256 soap75Days) =
            calculateSoap(_userTwo, block.timestamp + TestConstants.PERIOD_75_DAYS_IN_SECONDS, mockCase0MiltonDai);
        assertEq(soap75Days, expectedSoap75Days);
    }

    function testShouldCalculateSoapEqualZeroWhenDAIPayFixedAtIPOR6PercentAndIPOR3PercentAfter25DaysAndDAIPayFixedAndIPOR3PercentAfter50DaysAndCloseAllSwapsAfter75Days(
    ) public {
        // given
        _miltonSpreadModel.setCalculateQuoteReceiveFixed(TestConstants.ZERO);
        ItfIporOracle iporOracle =
            getIporOracleAsset(_userOne, address(_daiMockedToken), TestConstants.TC_6_EMA_18DEC_64UINT);
        IMarketSafetyOracle marketSafetyOracle = getMarketSafetyOracleAsset(
            _userOne,
            address(_daiMockedToken),
            TestConstants.MSO_UTILIZATION_RATE_48_PER,
            TestConstants.MSO_UTILIZATION_RATE_90_PER,
            TestConstants.MSO_NOTIONAL_1B
        );
        MockCase0Stanley mockCase0StanleyDai = getMockCase0Stanley(address(_daiMockedToken));
        MiltonStorage miltonStorageDai = getMiltonStorage();
        MockCase0MiltonDai mockCase0MiltonDai = getMockCase0MiltonDai(
            address(_daiMockedToken),
            address(iporOracle),
            address(miltonStorageDai),
            address(_miltonSpreadModel),
            address(mockCase0StanleyDai),
            address(marketSafetyOracle)
        );
        MockCase0JosephDai mockCase0JosephDai = getMockCase0JosephDai(
            address(_daiMockedToken),
            address(_ipTokenDai),
            address(mockCase0MiltonDai),
            address(miltonStorageDai),
            address(mockCase0StanleyDai)
        );
        int256 expectedSoap75Days = TestConstants.ZERO_INT;
        prepareApproveForUsersDai(_users, _daiMockedToken, address(mockCase0JosephDai), address(mockCase0MiltonDai));
        prepareMilton(mockCase0MiltonDai, address(mockCase0JosephDai), address(mockCase0StanleyDai));
        prepareJoseph(mockCase0JosephDai);
        prepareIpToken(_ipTokenDai, address(mockCase0JosephDai));
        _miltonSpreadModel.setCalculateQuotePayFixed(41683900567904584);
        vm.prank(_liquidityProvider);
        mockCase0JosephDai.itfProvideLiquidity(2 * TestConstants.USD_28_000_18DEC, block.timestamp);
        // when
        vm.prank(_userOne);
        iporOracle.itfUpdateIndex(address(_daiMockedToken), TestConstants.PERCENTAGE_6_18DEC, block.timestamp);
        openSwapPayFixed(
            _userTwo,
            block.timestamp,
            1000348983489384893923,
            9 * TestConstants.D17,
            TestConstants.LEVERAGE_1000_18DEC,
            mockCase0MiltonDai
        );
        vm.prank(_userOne);
        iporOracle.itfUpdateIndex(
            address(_daiMockedToken),
            TestConstants.PERCENTAGE_3_18DEC,
            block.timestamp + TestConstants.PERIOD_25_DAYS_IN_SECONDS
        );
        openSwapPayFixed(
            _userTwo,
            block.timestamp + TestConstants.PERIOD_25_DAYS_IN_SECONDS,
            1492747383748202058744,
            9 * TestConstants.D17,
            TestConstants.LEVERAGE_1000_18DEC,
            mockCase0MiltonDai
        );
        vm.startPrank(_userOne);
        iporOracle.itfUpdateIndex(
            address(_daiMockedToken),
            TestConstants.PERCENTAGE_3_18DEC,
            block.timestamp + TestConstants.PERIOD_50_DAYS_IN_SECONDS
        );
        mockCase0MiltonDai.itfCloseSwapPayFixed(1, TestConstants.PERIOD_75_DAYS_IN_SECONDS);
        mockCase0MiltonDai.itfCloseSwapPayFixed(2, TestConstants.PERIOD_75_DAYS_IN_SECONDS);
        vm.stopPrank();
        // then
        (,, int256 soap75Days) =
            calculateSoap(_userTwo, block.timestamp + TestConstants.PERIOD_75_DAYS_IN_SECONDS, mockCase0MiltonDai);
        assertEq(soap75Days, expectedSoap75Days);
    }

    function testShouldCalculateSoapEqualZeroWhenDAIReceiveFixedAtIPOR3PercentAndIPOR5PercentAfter25DaysAndDAIReceiveFixedAndIPOR6PercentAfter50DaysAndCloseAllSwapsAfter75Days(
    ) public {
        // given
        _miltonSpreadModel.setCalculateQuotePayFixed(TestConstants.ZERO);
        ItfIporOracle iporOracle =
            getIporOracleAsset(_userOne, address(_daiMockedToken), TestConstants.TC_DEFAULT_EMA_18DEC_64UINT);
        IMarketSafetyOracle marketSafetyOracle = getMarketSafetyOracleAsset(
            _userOne,
            address(_daiMockedToken),
            TestConstants.MSO_UTILIZATION_RATE_48_PER,
            TestConstants.MSO_UTILIZATION_RATE_90_PER,
            TestConstants.MSO_NOTIONAL_1B
        );
        MockCase0Stanley mockCase0StanleyDai = getMockCase0Stanley(address(_daiMockedToken));
        MiltonStorage miltonStorageDai = getMiltonStorage();
        MockCase0MiltonDai mockCase0MiltonDai = getMockCase0MiltonDai(
            address(_daiMockedToken),
            address(iporOracle),
            address(miltonStorageDai),
            address(_miltonSpreadModel),
            address(mockCase0StanleyDai),
            address(marketSafetyOracle)
        );
        MockCase0JosephDai mockCase0JosephDai = getMockCase0JosephDai(
            address(_daiMockedToken),
            address(_ipTokenDai),
            address(mockCase0MiltonDai),
            address(miltonStorageDai),
            address(mockCase0StanleyDai)
        );
        int256 expectedSoap75Days = TestConstants.ZERO_INT;
        prepareApproveForUsersDai(_users, _daiMockedToken, address(mockCase0JosephDai), address(mockCase0MiltonDai));
        prepareMilton(mockCase0MiltonDai, address(mockCase0JosephDai), address(mockCase0StanleyDai));
        prepareJoseph(mockCase0JosephDai);
        prepareIpToken(_ipTokenDai, address(mockCase0JosephDai));
        _miltonSpreadModel.setCalculateQuoteReceiveFixed(38877399621396944);
        vm.prank(_liquidityProvider);
        mockCase0JosephDai.itfProvideLiquidity(2 * TestConstants.USD_28_000_18DEC, block.timestamp);
        // when
        vm.prank(_userOne);
        iporOracle.itfUpdateIndex(address(_daiMockedToken), TestConstants.PERCENTAGE_3_18DEC, block.timestamp);
        openSwapReceiveFixed(
            _userTwo,
            block.timestamp,
            1000348983489384893923,
            TestConstants.PERCENTAGE_1_18DEC,
            TestConstants.LEVERAGE_1000_18DEC,
            mockCase0MiltonDai
        );
        vm.prank(_userOne);
        iporOracle.itfUpdateIndex(
            address(_daiMockedToken),
            TestConstants.PERCENTAGE_5_18DEC,
            block.timestamp + TestConstants.PERIOD_25_DAYS_IN_SECONDS
        );
        openSwapReceiveFixed(
            _userTwo,
            block.timestamp + TestConstants.PERIOD_25_DAYS_IN_SECONDS,
            1492747383748202058744,
            TestConstants.PERCENTAGE_1_18DEC,
            TestConstants.LEVERAGE_1000_18DEC,
            mockCase0MiltonDai
        );
        vm.startPrank(_userOne);
        iporOracle.itfUpdateIndex(
            address(_daiMockedToken),
            TestConstants.PERCENTAGE_6_18DEC,
            block.timestamp + TestConstants.PERIOD_50_DAYS_IN_SECONDS
        );
        mockCase0MiltonDai.itfCloseSwapReceiveFixed(1, TestConstants.PERIOD_75_DAYS_IN_SECONDS);
        mockCase0MiltonDai.itfCloseSwapReceiveFixed(2, TestConstants.PERIOD_75_DAYS_IN_SECONDS);
        vm.stopPrank();
        // then
        (,, int256 soap75Days) =
            calculateSoap(_userTwo, block.timestamp + TestConstants.PERIOD_75_DAYS_IN_SECONDS, mockCase0MiltonDai);
        assertEq(soap75Days, expectedSoap75Days);
    }

    function testShouldCalculateSoapEqualZeroWhenDAIReceiveFixedAtIPOR6PercentAndIPOR3PercentAfter25DaysAndDAIReceiveFixedAndIPOR3PercentAfter50DaysAndCloseAllSwapsAfter75Days(
    ) public {
        // given
        _miltonSpreadModel.setCalculateQuotePayFixed(TestConstants.ZERO);
        ItfIporOracle iporOracle =
            getIporOracleAsset(_userOne, address(_daiMockedToken), TestConstants.TC_6_EMA_18DEC_64UINT);
        IMarketSafetyOracle marketSafetyOracle = getMarketSafetyOracleAsset(
            _userOne,
            address(_daiMockedToken),
            TestConstants.MSO_UTILIZATION_RATE_48_PER,
            TestConstants.MSO_UTILIZATION_RATE_90_PER,
            TestConstants.MSO_NOTIONAL_1B
        );
        MockCase0Stanley mockCase0StanleyDai = getMockCase0Stanley(address(_daiMockedToken));
        MiltonStorage miltonStorageDai = getMiltonStorage();
        MockCase0MiltonDai mockCase0MiltonDai = getMockCase0MiltonDai(
            address(_daiMockedToken),
            address(iporOracle),
            address(miltonStorageDai),
            address(_miltonSpreadModel),
            address(mockCase0StanleyDai),
            address(marketSafetyOracle)
        );
        MockCase0JosephDai mockCase0JosephDai = getMockCase0JosephDai(
            address(_daiMockedToken),
            address(_ipTokenDai),
            address(mockCase0MiltonDai),
            address(miltonStorageDai),
            address(mockCase0StanleyDai)
        );
        int256 expectedSoap75Days = TestConstants.ZERO_INT;
        prepareApproveForUsersDai(_users, _daiMockedToken, address(mockCase0JosephDai), address(mockCase0MiltonDai));
        prepareMilton(mockCase0MiltonDai, address(mockCase0JosephDai), address(mockCase0StanleyDai));
        prepareJoseph(mockCase0JosephDai);
        prepareIpToken(_ipTokenDai, address(mockCase0JosephDai));
        _miltonSpreadModel.setCalculateQuoteReceiveFixed(TestConstants.PERCENTAGE_2_18DEC);
        vm.prank(_liquidityProvider);
        mockCase0JosephDai.itfProvideLiquidity(2 * TestConstants.USD_28_000_18DEC, block.timestamp);
        // when
        vm.prank(_userOne);
        iporOracle.itfUpdateIndex(address(_daiMockedToken), TestConstants.PERCENTAGE_6_18DEC, block.timestamp);
        openSwapReceiveFixed(
            _userTwo,
            block.timestamp,
            1000348983489384893923,
            TestConstants.PERCENTAGE_1_18DEC,
            TestConstants.LEVERAGE_1000_18DEC,
            mockCase0MiltonDai
        );
        vm.prank(_userOne);
        iporOracle.itfUpdateIndex(
            address(_daiMockedToken),
            TestConstants.PERCENTAGE_3_18DEC,
            block.timestamp + TestConstants.PERIOD_25_DAYS_IN_SECONDS
        );
        openSwapReceiveFixed(
            _userTwo,
            block.timestamp + TestConstants.PERIOD_25_DAYS_IN_SECONDS,
            1492747383748202058744,
            TestConstants.PERCENTAGE_1_18DEC,
            TestConstants.LEVERAGE_1000_18DEC,
            mockCase0MiltonDai
        );
        vm.startPrank(_userOne);
        iporOracle.itfUpdateIndex(
            address(_daiMockedToken),
            TestConstants.PERCENTAGE_3_18DEC,
            block.timestamp + TestConstants.PERIOD_50_DAYS_IN_SECONDS
        );
        mockCase0MiltonDai.itfCloseSwapReceiveFixed(1, TestConstants.PERIOD_75_DAYS_IN_SECONDS);
        mockCase0MiltonDai.itfCloseSwapReceiveFixed(2, TestConstants.PERIOD_75_DAYS_IN_SECONDS);
        vm.stopPrank();
        // then
        (,, int256 soap75Days) =
            calculateSoap(_userTwo, block.timestamp + TestConstants.PERIOD_75_DAYS_IN_SECONDS, mockCase0MiltonDai);
        assertEq(soap75Days, expectedSoap75Days);
    }

    function testShouldCalculateSoapEqualZeroWhenUSDTPayFixedAtIPOR3PercentAndIPOR5PercentAfter25DaysAndUSDTPayFixedAndIPOR6PercentAfter50DaysAndCloseAllSwapsAfter75DaysSimpleTotalAmounts(
    ) public {
        // given
        _miltonSpreadModel.setCalculateQuoteReceiveFixed(TestConstants.ZERO);
        ItfIporOracle iporOracle =
            getIporOracleAsset(_userOne, address(_usdtMockedToken), TestConstants.TC_DEFAULT_EMA_18DEC_64UINT);
        IMarketSafetyOracle marketSafetyOracle = getMarketSafetyOracleAsset(
            _userOne,
            address(_usdtMockedToken),
            TestConstants.MSO_UTILIZATION_RATE_48_PER,
            TestConstants.MSO_UTILIZATION_RATE_90_PER,
            TestConstants.MSO_NOTIONAL_1B
        );
        MockCase0Stanley mockCase0StanleyUsdt = getMockCase0Stanley(address(_usdtMockedToken));
        MiltonStorage miltonStorageUsdt = getMiltonStorage();
        MockCase0MiltonUsdt mockCase0MiltonUsdt = getMockCase0MiltonUsdt(
            address(_usdtMockedToken),
            address(iporOracle),
            address(miltonStorageUsdt),
            address(_miltonSpreadModel),
            address(mockCase0StanleyUsdt),
            address(marketSafetyOracle)
        );
        MockCase0JosephUsdt mockCase0JosephUsdt = getMockCase0JosephUsdt(
            address(_usdtMockedToken),
            address(_ipTokenUsdt),
            address(mockCase0MiltonUsdt),
            address(miltonStorageUsdt),
            address(mockCase0StanleyUsdt)
        );
        int256 expectedSoap75Days = TestConstants.ZERO_INT;
        prepareApproveForUsersUsd(_users, _usdtMockedToken, address(mockCase0JosephUsdt), address(mockCase0MiltonUsdt));
        prepareMilton(mockCase0MiltonUsdt, address(mockCase0JosephUsdt), address(mockCase0StanleyUsdt));
        prepareJoseph(mockCase0JosephUsdt);
        prepareIpToken(_ipTokenUsdt, address(mockCase0JosephUsdt));
        _miltonSpreadModel.setCalculateQuotePayFixed(TestConstants.PERCENTAGE_6_18DEC);
        vm.prank(_liquidityProvider);
        mockCase0JosephUsdt.itfProvideLiquidity(2 * TestConstants.USD_28_000_6DEC, block.timestamp);
        // when
        vm.prank(_userOne);
        iporOracle.itfUpdateIndex(address(_usdtMockedToken), TestConstants.PERCENTAGE_3_18DEC, block.timestamp);
        openSwapPayFixed(
            _userTwo,
            block.timestamp,
            1040000000,
            9 * TestConstants.D17,
            TestConstants.LEVERAGE_1000_18DEC,
            mockCase0MiltonUsdt
        );
        vm.prank(_userOne);
        iporOracle.itfUpdateIndex(
            address(_usdtMockedToken),
            TestConstants.PERCENTAGE_5_18DEC,
            block.timestamp + TestConstants.PERIOD_25_DAYS_IN_SECONDS
        );
        openSwapPayFixed(
            _userTwo,
            block.timestamp + TestConstants.PERIOD_25_DAYS_IN_SECONDS,
            1040000000,
            1500000000000000000,
            TestConstants.LEVERAGE_1000_18DEC,
            mockCase0MiltonUsdt
        );
        vm.startPrank(_userOne);
        iporOracle.itfUpdateIndex(
            address(_usdtMockedToken),
            TestConstants.PERCENTAGE_6_18DEC,
            block.timestamp + TestConstants.PERIOD_50_DAYS_IN_SECONDS
        );
        mockCase0MiltonUsdt.itfCloseSwapPayFixed(1, TestConstants.PERIOD_75_DAYS_IN_SECONDS);
        mockCase0MiltonUsdt.itfCloseSwapPayFixed(2, TestConstants.PERIOD_75_DAYS_IN_SECONDS);
        vm.stopPrank();
        // then
        (,, int256 soap75Days) =
            calculateSoap(_userTwo, block.timestamp + TestConstants.PERIOD_75_DAYS_IN_SECONDS, mockCase0MiltonUsdt);
        assertEq(soap75Days, expectedSoap75Days);
    }

    function testShouldCalculateSoapEqualZeroWhenUSDTPayFixedAtIPOR3PercentAndIPOR5PercentAfter25DaysAndUSDTPayFixedAndIPOR6PercentAfter50DaysAndCloseAllSwapsAfter75DaysComplexTotalAmounts(
    ) public {
        // given
        _miltonSpreadModel.setCalculateQuoteReceiveFixed(TestConstants.ZERO);
        ItfIporOracle iporOracle =
            getIporOracleAsset(_userOne, address(_usdtMockedToken), TestConstants.TC_DEFAULT_EMA_18DEC_64UINT);
        IMarketSafetyOracle marketSafetyOracle = getMarketSafetyOracleAsset(
            _userOne,
            address(_usdtMockedToken),
            TestConstants.MSO_UTILIZATION_RATE_48_PER,
            TestConstants.MSO_UTILIZATION_RATE_90_PER,
            TestConstants.MSO_NOTIONAL_1B
        );
        MockCase0Stanley mockCase0StanleyUsdt = getMockCase0Stanley(address(_usdtMockedToken));
        MiltonStorage miltonStorageUsdt = getMiltonStorage();
        MockCase0MiltonUsdt mockCase0MiltonUsdt = getMockCase0MiltonUsdt(
            address(_usdtMockedToken),
            address(iporOracle),
            address(miltonStorageUsdt),
            address(_miltonSpreadModel),
            address(mockCase0StanleyUsdt),
            address(marketSafetyOracle)
        );
        MockCase0JosephUsdt mockCase0JosephUsdt = getMockCase0JosephUsdt(
            address(_usdtMockedToken),
            address(_ipTokenUsdt),
            address(mockCase0MiltonUsdt),
            address(miltonStorageUsdt),
            address(mockCase0StanleyUsdt)
        );
        int256 expectedSoap75Days = TestConstants.ZERO_INT;
        prepareApproveForUsersUsd(_users, _usdtMockedToken, address(mockCase0JosephUsdt), address(mockCase0MiltonUsdt));
        prepareMilton(mockCase0MiltonUsdt, address(mockCase0JosephUsdt), address(mockCase0StanleyUsdt));
        prepareJoseph(mockCase0JosephUsdt);
        prepareIpToken(_ipTokenUsdt, address(mockCase0JosephUsdt));
        _miltonSpreadModel.setCalculateQuotePayFixed(TestConstants.PERCENTAGE_6_18DEC);
        vm.prank(_liquidityProvider);
        mockCase0JosephUsdt.itfProvideLiquidity(2 * TestConstants.USD_28_000_6DEC, block.timestamp);
        // when
        vm.prank(_userOne);
        iporOracle.itfUpdateIndex(address(_usdtMockedToken), TestConstants.PERCENTAGE_3_18DEC, block.timestamp);
        openSwapPayFixed(
            _userTwo,
            block.timestamp,
            1000348983,
            9 * TestConstants.D17,
            TestConstants.LEVERAGE_1000_18DEC,
            mockCase0MiltonUsdt
        );
        vm.prank(_userOne);
        iporOracle.itfUpdateIndex(
            address(_usdtMockedToken),
            TestConstants.PERCENTAGE_5_18DEC,
            block.timestamp + TestConstants.PERIOD_25_DAYS_IN_SECONDS
        );
        openSwapPayFixed(
            _userTwo,
            block.timestamp + TestConstants.PERIOD_25_DAYS_IN_SECONDS,
            1492747383,
            1500000000000000000,
            TestConstants.LEVERAGE_1000_18DEC,
            mockCase0MiltonUsdt
        );
        vm.startPrank(_userOne);
        iporOracle.itfUpdateIndex(
            address(_usdtMockedToken),
            TestConstants.PERCENTAGE_6_18DEC,
            block.timestamp + TestConstants.PERIOD_50_DAYS_IN_SECONDS
        );
        mockCase0MiltonUsdt.itfCloseSwapPayFixed(1, TestConstants.PERIOD_75_DAYS_IN_SECONDS);
        mockCase0MiltonUsdt.itfCloseSwapPayFixed(2, TestConstants.PERIOD_75_DAYS_IN_SECONDS);
        vm.stopPrank();
        // then
        (,, int256 soap75Days) =
            calculateSoap(_userTwo, block.timestamp + TestConstants.PERIOD_75_DAYS_IN_SECONDS, mockCase0MiltonUsdt);
        assertEq(soap75Days, expectedSoap75Days);
    }

    function testShouldCalculateSoapEqualZeroWhenUSDTReceiveFixedAtIPOR3PercentAndIPOR5PercentAfter25DaysAndDAIReceiveFixedAndIPOR6PercentAfter50DaysAndCloseAllSwapsAfter75Days(
    ) public {
        // given
        _miltonSpreadModel.setCalculateQuotePayFixed(TestConstants.ZERO);
        ItfIporOracle iporOracle =
            getIporOracleAsset(_userOne, address(_usdtMockedToken), TestConstants.TC_DEFAULT_EMA_18DEC_64UINT);
        IMarketSafetyOracle marketSafetyOracle = getMarketSafetyOracleAsset(
            _userOne,
            address(_usdtMockedToken),
            TestConstants.MSO_UTILIZATION_RATE_48_PER,
            TestConstants.MSO_UTILIZATION_RATE_90_PER,
            TestConstants.MSO_NOTIONAL_1B
        );
        MockCase0Stanley mockCase0StanleyUsdt = getMockCase0Stanley(address(_usdtMockedToken));
        MiltonStorage miltonStorageUsdt = getMiltonStorage();
        MockCase0MiltonUsdt mockCase0MiltonUsdt = getMockCase0MiltonUsdt(
            address(_usdtMockedToken),
            address(iporOracle),
            address(miltonStorageUsdt),
            address(_miltonSpreadModel),
            address(mockCase0StanleyUsdt),
            address(marketSafetyOracle)
        );
        MockCase0JosephUsdt mockCase0JosephUsdt = getMockCase0JosephUsdt(
            address(_usdtMockedToken),
            address(_ipTokenUsdt),
            address(mockCase0MiltonUsdt),
            address(miltonStorageUsdt),
            address(mockCase0StanleyUsdt)
        );
        int256 expectedSoap75Days = TestConstants.ZERO_INT;
        prepareApproveForUsersUsd(_users, _usdtMockedToken, address(mockCase0JosephUsdt), address(mockCase0MiltonUsdt));
        prepareMilton(mockCase0MiltonUsdt, address(mockCase0JosephUsdt), address(mockCase0StanleyUsdt));
        prepareJoseph(mockCase0JosephUsdt);
        prepareIpToken(_ipTokenUsdt, address(mockCase0JosephUsdt));
        _miltonSpreadModel.setCalculateQuoteReceiveFixed(38877399621396944);
        vm.prank(_liquidityProvider);
        mockCase0JosephUsdt.itfProvideLiquidity(2 * TestConstants.USD_28_000_6DEC, block.timestamp);
        // when
        vm.prank(_userOne);
        iporOracle.itfUpdateIndex(address(_usdtMockedToken), TestConstants.PERCENTAGE_3_18DEC, block.timestamp);
        openSwapReceiveFixed(
            _userTwo,
            block.timestamp,
            1000348983,
            TestConstants.PERCENTAGE_1_18DEC,
            TestConstants.LEVERAGE_1000_18DEC,
            mockCase0MiltonUsdt
        );
        vm.prank(_userOne);
        iporOracle.itfUpdateIndex(
            address(_usdtMockedToken),
            TestConstants.PERCENTAGE_5_18DEC,
            block.timestamp + TestConstants.PERIOD_25_DAYS_IN_SECONDS
        );
        openSwapReceiveFixed(
            _userTwo,
            block.timestamp + TestConstants.PERIOD_25_DAYS_IN_SECONDS,
            1492747383,
            TestConstants.PERCENTAGE_1_18DEC,
            TestConstants.LEVERAGE_1000_18DEC,
            mockCase0MiltonUsdt
        );
        vm.startPrank(_userOne);
        iporOracle.itfUpdateIndex(
            address(_usdtMockedToken),
            TestConstants.PERCENTAGE_6_18DEC,
            block.timestamp + TestConstants.PERIOD_50_DAYS_IN_SECONDS
        );
        mockCase0MiltonUsdt.itfCloseSwapReceiveFixed(1, TestConstants.PERIOD_75_DAYS_IN_SECONDS);
        mockCase0MiltonUsdt.itfCloseSwapReceiveFixed(2, TestConstants.PERIOD_75_DAYS_IN_SECONDS);
        vm.stopPrank();
        // then
        (,, int256 soap75Days) =
            calculateSoap(_userTwo, block.timestamp + TestConstants.PERIOD_75_DAYS_IN_SECONDS, mockCase0MiltonUsdt);
        assertEq(soap75Days, expectedSoap75Days);
    }
}

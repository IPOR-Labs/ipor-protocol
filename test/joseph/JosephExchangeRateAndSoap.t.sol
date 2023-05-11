// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.16;

import "../TestCommons.sol";
import {DataUtils} from "../utils/DataUtils.sol";
import {SwapUtils} from "../utils/SwapUtils.sol";
import "../utils/TestConstants.sol";
import "../../contracts/mocks/spread/MockSpreadModel.sol";
import "../../contracts/mocks/tokens/MockTestnetToken.sol";
import "../../contracts/tokens/IpToken.sol";
import "../../contracts/mocks/milton/MockCase0MiltonDai.sol";
import "../../contracts/mocks/stanley/MockCase0Stanley.sol";
import "../../contracts/mocks/joseph/MockCase0JosephDai.sol";
import "../../contracts/amm/MiltonStorage.sol";
import "../../contracts/itf/ItfIporOracle.sol";
import "../../contracts/interfaces/IIporRiskManagementOracle.sol";
import "../../contracts/interfaces/types/IporTypes.sol";

contract JosephExchangeRateAndSoap is TestCommons, DataUtils, SwapUtils {
    MockSpreadModel internal _miltonSpreadModel;
    MockTestnetToken internal _usdtMockedToken;
    MockTestnetToken internal _usdcMockedToken;
    MockTestnetToken internal _daiMockedToken;
    IpToken internal _ipTokenUsdt;
    IpToken internal _ipTokenUsdc;
    IpToken internal _ipTokenDai;

    function setUp() public {
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
        _miltonSpreadModel = prepareMockSpreadModel(
            TestConstants.ZERO, TestConstants.ZERO, TestConstants.ZERO_INT, TestConstants.ZERO_INT
        );
    }

    function testShouldCalculateExchangeRatePayFixedWhenSOAPChangedAndSOAPIsLowerThanZeroAndSOAPAbsoluteValueIsLowerThanLiquidityPoolBalance(
    ) public {
        // given
        _miltonSpreadModel.setCalculateQuotePayFixed(TestConstants.PERCENTAGE_4_18DEC);
        ItfIporOracle iporOracle =
            getIporOracleAsset(_userOne, address(_daiMockedToken), TestConstants.TC_DEFAULT_EMA_18DEC_64UINT);
        IIporRiskManagementOracle iporRiskManagementOracle = getRiskManagementOracleAsset(
            _userOne,
            address(_daiMockedToken),
            TestConstants.RMO_UTILIZATION_RATE_48_PER,
            TestConstants.RMO_UTILIZATION_RATE_90_PER,
            TestConstants.RMO_NOTIONAL_1B
        );
        MockCase0Stanley stanleyDai = getMockCase0Stanley(address(_daiMockedToken));
        MiltonStorage miltonStorageDai = getMiltonStorage();
        MockCase0MiltonDai mockCase0MiltonDai = getMockCase0MiltonDai(
            address(_daiMockedToken),
            address(iporOracle),
            address(miltonStorageDai),
            address(_miltonSpreadModel),
            address(stanleyDai),
            address(iporRiskManagementOracle)
        );
        MockCase0JosephDai mockCase0JosephDai = getMockCase0JosephDai(
            address(_daiMockedToken),
            address(_ipTokenDai),
            address(mockCase0MiltonDai),
            address(miltonStorageDai),
            address(stanleyDai)
        );
        prepareApproveForUsersDai(_users, _daiMockedToken, address(mockCase0JosephDai), address(mockCase0MiltonDai));
        prepareMilton(mockCase0MiltonDai, address(mockCase0JosephDai), address(stanleyDai));
        prepareJoseph(mockCase0JosephDai);
        prepareIpToken(_ipTokenDai, address(mockCase0JosephDai));
        // required to have IBT price higher than 0
        vm.prank(_userOne);
        iporOracle.itfUpdateIndex(address(_daiMockedToken), TestConstants.PERCENTAGE_3_18DEC, block.timestamp);
        vm.prank(_liquidityProvider);
        mockCase0JosephDai.itfProvideLiquidity(TestConstants.USD_60_000_18DEC, block.timestamp);
        vm.prank(_userTwo);
        mockCase0MiltonDai.itfOpenSwapPayFixed(
            block.timestamp, 26000 * TestConstants.D18, 9 * TestConstants.D17, TestConstants.LEVERAGE_18DEC
        );
        (,, int256 soap) =
            calculateSoap(_userTwo, block.timestamp + TestConstants.PERIOD_25_DAYS_IN_SECONDS, mockCase0MiltonDai);
        IporTypes.MiltonBalancesMemory memory balance = mockCase0MiltonDai.getAccruedBalance();
        // when
        uint256 actualExchangeRate =
            mockCase0JosephDai.itfCalculateExchangeRate(block.timestamp + TestConstants.PERIOD_25_DAYS_IN_SECONDS);
        // then
        assertLt(soap, TestConstants.ZERO_INT);
        assertLt(soap * -1, int256(balance.liquidityPool));
        assertEq(actualExchangeRate, 1003063517802295728);
    }

    function testShouldCalculateExchangeRateReceiveFixedWhenSOAPChangedAndSOAPIsLowerThanZeroAndSOAPAbsoluteValueIsLowerThanLiquidityPoolBalance(
    ) public {
        // given
        _miltonSpreadModel.setCalculateQuoteReceiveFixed(TestConstants.PERCENTAGE_2_18DEC);
        ItfIporOracle iporOracle =
            getIporOracleAsset(_userOne, address(_daiMockedToken), TestConstants.TC_DEFAULT_EMA_18DEC_64UINT);
        IIporRiskManagementOracle iporRiskManagementOracle = getRiskManagementOracleAsset(
            _userOne,
            address(_daiMockedToken),
            TestConstants.RMO_UTILIZATION_RATE_48_PER,
            TestConstants.RMO_UTILIZATION_RATE_90_PER,
            TestConstants.RMO_NOTIONAL_1B
        );
        MockCase0Stanley stanleyDai = getMockCase0Stanley(address(_daiMockedToken));
        MiltonStorage miltonStorageDai = getMiltonStorage();
        MockCase0MiltonDai mockCase0MiltonDai = getMockCase0MiltonDai(
            address(_daiMockedToken),
            address(iporOracle),
            address(miltonStorageDai),
            address(_miltonSpreadModel),
            address(stanleyDai),
            address(iporRiskManagementOracle)
        );
        MockCase0JosephDai mockCase0JosephDai = getMockCase0JosephDai(
            address(_daiMockedToken),
            address(_ipTokenDai),
            address(mockCase0MiltonDai),
            address(miltonStorageDai),
            address(stanleyDai)
        );
        prepareApproveForUsersDai(_users, _daiMockedToken, address(mockCase0JosephDai), address(mockCase0MiltonDai));
        prepareMilton(mockCase0MiltonDai, address(mockCase0JosephDai), address(stanleyDai));
        prepareJoseph(mockCase0JosephDai);
        prepareIpToken(_ipTokenDai, address(mockCase0JosephDai));
        // required to have IBT price higher than 0
        vm.prank(_userOne);
        iporOracle.itfUpdateIndex(address(_daiMockedToken), TestConstants.PERCENTAGE_3_18DEC, block.timestamp);
        vm.prank(_liquidityProvider);
        mockCase0JosephDai.itfProvideLiquidity(TestConstants.USD_60_000_18DEC, block.timestamp);
        vm.prank(_userTwo);
        mockCase0MiltonDai.itfOpenSwapReceiveFixed(
            block.timestamp, 27000 * TestConstants.D18, 1 * TestConstants.D16, TestConstants.LEVERAGE_18DEC
        );
        vm.prank(_userOne);
        iporOracle.itfUpdateIndex(address(_daiMockedToken), TestConstants.PERCENTAGE_5_18DEC, block.timestamp);
        (,, int256 soap) =
            calculateSoap(_userTwo, block.timestamp + TestConstants.PERIOD_25_DAYS_IN_SECONDS, mockCase0MiltonDai);
        IporTypes.MiltonBalancesMemory memory balance = mockCase0MiltonDai.getAccruedBalance();
        // when
        uint256 actualExchangeRate =
            mockCase0JosephDai.itfCalculateExchangeRate(block.timestamp + TestConstants.PERIOD_25_DAYS_IN_SECONDS);
        // then
        assertLt(soap, TestConstants.ZERO_INT);
        assertLt(soap * -1, int256(balance.liquidityPool));
        assertEq(actualExchangeRate, 1009337599018308114);
    }

    function testShouldCalculateExchangeRatePayFixedWhenSOAPChangedAndSOAPIsGreaterThanZeroAndSOAPAbsoluteValueIsLowerThanLiquidityPoolBalance(
    ) public {
        // given
        _miltonSpreadModel.setCalculateQuotePayFixed(TestConstants.PERCENTAGE_4_18DEC);
        ItfIporOracle iporOracle =
            getIporOracleAsset(_userOne, address(_daiMockedToken), TestConstants.TC_DEFAULT_EMA_18DEC_64UINT);
        IIporRiskManagementOracle iporRiskManagementOracle = getRiskManagementOracleAsset(
            _userOne,
            address(_daiMockedToken),
            TestConstants.RMO_UTILIZATION_RATE_48_PER,
            TestConstants.RMO_UTILIZATION_RATE_90_PER,
            TestConstants.RMO_NOTIONAL_1B
        );
        MockCase0Stanley stanleyDai = getMockCase0Stanley(address(_daiMockedToken));
        MiltonStorage miltonStorageDai = getMiltonStorage();
        MockCase0MiltonDai mockCase0MiltonDai = getMockCase0MiltonDai(
            address(_daiMockedToken),
            address(iporOracle),
            address(miltonStorageDai),
            address(_miltonSpreadModel),
            address(stanleyDai),
            address(iporRiskManagementOracle)
        );
        MockCase0JosephDai mockCase0JosephDai = getMockCase0JosephDai(
            address(_daiMockedToken),
            address(_ipTokenDai),
            address(mockCase0MiltonDai),
            address(miltonStorageDai),
            address(stanleyDai)
        );
        prepareApproveForUsersDai(_users, _daiMockedToken, address(mockCase0JosephDai), address(mockCase0MiltonDai));
        prepareMilton(mockCase0MiltonDai, address(mockCase0JosephDai), address(stanleyDai));
        prepareJoseph(mockCase0JosephDai);
        prepareIpToken(_ipTokenDai, address(mockCase0JosephDai));
        // required to have IBT price higher than 0
        vm.prank(_userOne);
        iporOracle.itfUpdateIndex(address(_daiMockedToken), TestConstants.PERCENTAGE_3_18DEC, block.timestamp);
        vm.prank(_liquidityProvider);
        mockCase0JosephDai.itfProvideLiquidity(TestConstants.USD_60_000_18DEC, block.timestamp);
        vm.prank(_userTwo);
        mockCase0MiltonDai.itfOpenSwapPayFixed(
            block.timestamp, 27000 * TestConstants.D18, 9 * TestConstants.D17, TestConstants.LEVERAGE_18DEC
        );
        vm.prank(_userOne);
        iporOracle.itfUpdateIndex(address(_daiMockedToken), TestConstants.PERCENTAGE_8_18DEC, block.timestamp);
        (,, int256 soap) =
            calculateSoap(_userTwo, block.timestamp + TestConstants.PERIOD_25_DAYS_IN_SECONDS, mockCase0MiltonDai);
        IporTypes.MiltonBalancesMemory memory balance = mockCase0MiltonDai.getAccruedBalance();
        // when
        uint256 actualExchangeRate =
            mockCase0JosephDai.itfCalculateExchangeRate(block.timestamp + TestConstants.PERIOD_25_DAYS_IN_SECONDS);
        // then
        assertGt(soap, TestConstants.ZERO_INT);
        assertLt(soap, int256(balance.liquidityPool));
        assertEq(actualExchangeRate, 987791187781442077);
    }

    function testShouldCalculateExchangeRateReceiveFixedWhenSOAPChangedAndSOAPIsGreaterThanZeroAndSOAPAbsoluteValueIsLowerThanLiquidityPoolBalance(
    ) public {
        // given
        _miltonSpreadModel.setCalculateQuoteReceiveFixed(TestConstants.PERCENTAGE_7_18DEC);
        ItfIporOracle iporOracle =
            getIporOracleAsset(_userOne, address(_daiMockedToken), TestConstants.TC_8_EMA_18DEC_64UINT);
        IIporRiskManagementOracle iporRiskManagementOracle = getRiskManagementOracleAsset(
            _userOne,
            address(_daiMockedToken),
            TestConstants.RMO_UTILIZATION_RATE_48_PER,
            TestConstants.RMO_UTILIZATION_RATE_90_PER,
            TestConstants.RMO_NOTIONAL_1B
        );
        MockCase0Stanley stanleyDai = getMockCase0Stanley(address(_daiMockedToken));
        MiltonStorage miltonStorageDai = getMiltonStorage();
        MockCase0MiltonDai mockCase0MiltonDai = getMockCase0MiltonDai(
            address(_daiMockedToken),
            address(iporOracle),
            address(miltonStorageDai),
            address(_miltonSpreadModel),
            address(stanleyDai),
            address(iporRiskManagementOracle)
        );
        MockCase0JosephDai mockCase0JosephDai = getMockCase0JosephDai(
            address(_daiMockedToken),
            address(_ipTokenDai),
            address(mockCase0MiltonDai),
            address(miltonStorageDai),
            address(stanleyDai)
        );
        prepareApproveForUsersDai(_users, _daiMockedToken, address(mockCase0JosephDai), address(mockCase0MiltonDai));
        prepareMilton(mockCase0MiltonDai, address(mockCase0JosephDai), address(stanleyDai));
        prepareJoseph(mockCase0JosephDai);
        prepareIpToken(_ipTokenDai, address(mockCase0JosephDai));
        // required to have IBT price higher than 0
        vm.prank(_userOne);
        iporOracle.itfUpdateIndex(address(_daiMockedToken), TestConstants.PERCENTAGE_8_18DEC, block.timestamp);
        vm.prank(_liquidityProvider);
        mockCase0JosephDai.itfProvideLiquidity(TestConstants.USD_60_000_18DEC, block.timestamp);
        vm.prank(_userTwo);
        mockCase0MiltonDai.itfOpenSwapReceiveFixed(
            block.timestamp, 27000 * TestConstants.D18, 1 * TestConstants.D16, TestConstants.LEVERAGE_18DEC
        );
        vm.prank(_userOne);
        iporOracle.itfUpdateIndex(address(_daiMockedToken), TestConstants.PERCENTAGE_3_18DEC, block.timestamp);
        (,, int256 soap) =
            calculateSoap(_userTwo, block.timestamp + TestConstants.PERIOD_25_DAYS_IN_SECONDS, mockCase0MiltonDai);
        IporTypes.MiltonBalancesMemory memory balance = mockCase0MiltonDai.getAccruedBalance();
        // when
        uint256 actualExchangeRate =
            mockCase0JosephDai.itfCalculateExchangeRate(block.timestamp + TestConstants.PERIOD_25_DAYS_IN_SECONDS);
        // then
        assertGt(soap, TestConstants.ZERO_INT);
        assertLt(soap, int256(balance.liquidityPool));
        assertEq(actualExchangeRate, 987791187781442078);
    }

    function testShouldNotCalculateExchangeRatePayFixedWhenSOAPChangedAndSOAPIsGreaterThanZeroAndSOAPAbsoluteValueIsGreaterThanLiquidityPoolBalance(
    ) public {
        // given
        _miltonSpreadModel.setCalculateQuotePayFixed(TestConstants.PERCENTAGE_4_18DEC);
        ItfIporOracle iporOracle =
            getIporOracleAsset(_userOne, address(_daiMockedToken), TestConstants.TC_DEFAULT_EMA_18DEC_64UINT);
        IIporRiskManagementOracle iporRiskManagementOracle = getRiskManagementOracleAsset(
            _userOne,
            address(_daiMockedToken),
            TestConstants.RMO_UTILIZATION_RATE_48_PER,
            TestConstants.RMO_UTILIZATION_RATE_90_PER,
            TestConstants.RMO_NOTIONAL_1B
        );
        MockCase0Stanley stanleyDai = getMockCase0Stanley(address(_daiMockedToken));
        MiltonStorage miltonStorageDai = getMiltonStorage();
        MockCase0MiltonDai mockCase0MiltonDai = getMockCase0MiltonDai(
            address(_daiMockedToken),
            address(iporOracle),
            address(miltonStorageDai),
            address(_miltonSpreadModel),
            address(stanleyDai),
            address(iporRiskManagementOracle)
        );
        MockCase0JosephDai mockCase0JosephDai = getMockCase0JosephDai(
            address(_daiMockedToken),
            address(_ipTokenDai),
            address(mockCase0MiltonDai),
            address(miltonStorageDai),
            address(stanleyDai)
        );
        prepareApproveForUsersDai(_users, _daiMockedToken, address(mockCase0JosephDai), address(mockCase0MiltonDai));
        prepareMilton(mockCase0MiltonDai, address(mockCase0JosephDai), address(stanleyDai));
        prepareJoseph(mockCase0JosephDai);
        prepareIpToken(_ipTokenDai, address(mockCase0JosephDai));
        // required to have IBT price higher than 0
        vm.prank(_userOne);
        iporOracle.itfUpdateIndex(address(_daiMockedToken), TestConstants.PERCENTAGE_3_18DEC, block.timestamp);
        vm.prank(_liquidityProvider);
        mockCase0JosephDai.itfProvideLiquidity(TestConstants.USD_60_000_18DEC, block.timestamp);
        vm.prank(_userTwo);
        mockCase0MiltonDai.itfOpenSwapPayFixed(
            block.timestamp, 27000 * TestConstants.D18, 9 * TestConstants.D17, TestConstants.LEVERAGE_18DEC
        );
        // BEGIN HACK - subtract liquidity without  burn ipToken
        miltonStorageDai.setJoseph(_admin);
        miltonStorageDai.subtractLiquidity(55000 * TestConstants.D18);
        miltonStorageDai.setJoseph(address(mockCase0JosephDai));
        // END HACK - subtract liquidity without  burn ipToken
        vm.prank(_userOne);
        iporOracle.itfUpdateIndex(address(_daiMockedToken), TestConstants.PERCENTAGE_50_18DEC, block.timestamp);
        // Notice! |SOAP| > Liquidity Pool Balance
        (,, int256 soap) =
            calculateSoap(_userTwo, block.timestamp + TestConstants.PERIOD_25_DAYS_IN_SECONDS, mockCase0MiltonDai);
        IporTypes.MiltonBalancesMemory memory balance = mockCase0MiltonDai.getAccruedBalance();
        // when
        vm.expectRevert("IPOR_316");
        mockCase0JosephDai.itfCalculateExchangeRate(block.timestamp + TestConstants.PERIOD_25_DAYS_IN_SECONDS);
        // then
        assertGt(soap, TestConstants.ZERO_INT);
        assertGt(soap, int256(balance.liquidityPool));
        assertEq(soap, 8495442144821465629202);
        assertEq(balance.liquidityPool, 5006205366436217422150);
    }

    function testShouldNotCalculateExchangeRateReceiveFixedWhenSOAPChangedAndSOAPIsGreaterThanZeroAndSOAPAbsoluteValueIsGreaterThanLiquidityPoolBalance(
    ) public {
        // given
        _miltonSpreadModel.setCalculateQuoteReceiveFixed(49 * TestConstants.D16);
        ItfIporOracle iporOracle =
            getIporOracleAsset(_userOne, address(_daiMockedToken), TestConstants.TC_50_EMA_18DEC_64UINT);
        IIporRiskManagementOracle iporRiskManagementOracle = getRiskManagementOracleAsset(
            _userOne,
            address(_daiMockedToken),
            TestConstants.RMO_UTILIZATION_RATE_48_PER,
            TestConstants.RMO_UTILIZATION_RATE_90_PER,
            TestConstants.RMO_NOTIONAL_1B
        );
        MockCase0Stanley stanleyDai = getMockCase0Stanley(address(_daiMockedToken));
        MiltonStorage miltonStorageDai = getMiltonStorage();
        MockCase0MiltonDai mockCase0MiltonDai = getMockCase0MiltonDai(
            address(_daiMockedToken),
            address(iporOracle),
            address(miltonStorageDai),
            address(_miltonSpreadModel),
            address(stanleyDai),
            address(iporRiskManagementOracle)
        );
        MockCase0JosephDai mockCase0JosephDai = getMockCase0JosephDai(
            address(_daiMockedToken),
            address(_ipTokenDai),
            address(mockCase0MiltonDai),
            address(miltonStorageDai),
            address(stanleyDai)
        );
        prepareApproveForUsersDai(_users, _daiMockedToken, address(mockCase0JosephDai), address(mockCase0MiltonDai));
        prepareMilton(mockCase0MiltonDai, address(mockCase0JosephDai), address(stanleyDai));
        prepareJoseph(mockCase0JosephDai);
        prepareIpToken(_ipTokenDai, address(mockCase0JosephDai));
        // required to have IBT price higher than 0
        vm.prank(_userOne);
        iporOracle.itfUpdateIndex(address(_daiMockedToken), TestConstants.PERCENTAGE_50_18DEC, block.timestamp);
        vm.prank(_liquidityProvider);
        mockCase0JosephDai.itfProvideLiquidity(TestConstants.USD_60_000_18DEC, block.timestamp);
        vm.prank(_userTwo);
        mockCase0MiltonDai.itfOpenSwapReceiveFixed(
            block.timestamp, 27000 * TestConstants.D18, 1 * TestConstants.D16, TestConstants.LEVERAGE_18DEC
        );
        // BEGIN HACK - subtract liquidity without  burn ipToken
        miltonStorageDai.setJoseph(_admin);
        miltonStorageDai.subtractLiquidity(55000 * TestConstants.D18);
        miltonStorageDai.setJoseph(address(mockCase0JosephDai));
        // END HACK - subtract liquidity without  burn ipToken
        vm.prank(_userOne);
        iporOracle.itfUpdateIndex(address(_daiMockedToken), TestConstants.PERCENTAGE_3_18DEC, block.timestamp);
        // Notice! |SOAP| > Liquidity Pool Balance
        (,, int256 soap) =
            calculateSoap(_userTwo, block.timestamp + TestConstants.PERIOD_25_DAYS_IN_SECONDS, mockCase0MiltonDai);
        IporTypes.MiltonBalancesMemory memory balance = mockCase0MiltonDai.getAccruedBalance();
        // when
        vm.expectRevert("IPOR_316");
        mockCase0JosephDai.itfCalculateExchangeRate(block.timestamp + TestConstants.PERIOD_25_DAYS_IN_SECONDS);
        // then
        assertGt(soap, TestConstants.ZERO_INT);
        assertGt(soap, int256(balance.liquidityPool));
        assertEq(soap, 8495442144821465799111);
        assertEq(balance.liquidityPool, 5006205366436217422150);
    }

    function testShouldCalculateExchangeRatePayFixedWhenSOAPChangedAndSOAPIsLowerThanZeroAndSOAPAbsoluteValueIsGreaterThanLiquidityPoolBalance(
    ) public {
        // given
        _miltonSpreadModel.setCalculateQuotePayFixed(51 * TestConstants.D16);
        ItfIporOracle iporOracle =
            getIporOracleAsset(_userOne, address(_daiMockedToken), TestConstants.TC_50_EMA_18DEC_64UINT);
        IIporRiskManagementOracle iporRiskManagementOracle = getRiskManagementOracleAsset(
            _userOne,
            address(_daiMockedToken),
            TestConstants.RMO_UTILIZATION_RATE_48_PER,
            TestConstants.RMO_UTILIZATION_RATE_90_PER,
            TestConstants.RMO_NOTIONAL_1B
        );
        MockCase0Stanley stanleyDai = getMockCase0Stanley(address(_daiMockedToken));
        MiltonStorage miltonStorageDai = getMiltonStorage();
        MockCase0MiltonDai mockCase0MiltonDai = getMockCase0MiltonDai(
            address(_daiMockedToken),
            address(iporOracle),
            address(miltonStorageDai),
            address(_miltonSpreadModel),
            address(stanleyDai),
            address(iporRiskManagementOracle)
        );
        MockCase0JosephDai mockCase0JosephDai = getMockCase0JosephDai(
            address(_daiMockedToken),
            address(_ipTokenDai),
            address(mockCase0MiltonDai),
            address(miltonStorageDai),
            address(stanleyDai)
        );
        prepareApproveForUsersDai(_users, _daiMockedToken, address(mockCase0JosephDai), address(mockCase0MiltonDai));
        prepareMilton(mockCase0MiltonDai, address(mockCase0JosephDai), address(stanleyDai));
        prepareJoseph(mockCase0JosephDai);
        prepareIpToken(_ipTokenDai, address(mockCase0JosephDai));
        // required to have IBT price higher than 0
        vm.prank(_userOne);
        iporOracle.itfUpdateIndex(address(_daiMockedToken), TestConstants.PERCENTAGE_50_18DEC, block.timestamp);
        vm.prank(_liquidityProvider);
        mockCase0JosephDai.itfProvideLiquidity(TestConstants.USD_60_000_18DEC, block.timestamp);
        vm.prank(_userTwo);
        mockCase0MiltonDai.itfOpenSwapPayFixed(
            block.timestamp, 27000 * TestConstants.D18, 9 * TestConstants.D17, TestConstants.LEVERAGE_18DEC
        );
        //BEGIN HACK - subtract liquidity without  burn ipToken. Notice! This affect ipToken price!
        miltonStorageDai.setJoseph(_admin);
        miltonStorageDai.subtractLiquidity(55000 * TestConstants.D18);
        miltonStorageDai.setJoseph(address(mockCase0JosephDai));
        //END HACK - subtract liquidity without  burn ipToken. Notice! This affect ipToken price!
        vm.prank(_userOne);
        iporOracle.itfUpdateIndex(address(_daiMockedToken), TestConstants.PERCENTAGE_3_18DEC, block.timestamp);
        // Notice! |SOAP| > Liquidity Pool Balance
        (,, int256 soap) =
            calculateSoap(_userTwo, block.timestamp + TestConstants.PERIOD_25_DAYS_IN_SECONDS, mockCase0MiltonDai);
        IporTypes.MiltonBalancesMemory memory balance = mockCase0MiltonDai.getAccruedBalance();
        uint256 actualExchangeRate =
            mockCase0JosephDai.itfCalculateExchangeRate(block.timestamp + TestConstants.PERIOD_25_DAYS_IN_SECONDS);
        // then
        assertEq(actualExchangeRate, 231183576017208826);
        assertEq(soap, -8864809194596312135794);
        assertEq(balance.liquidityPool, 5006205366436217422150);
    }

    function testShouldCalculateExchangeRateReceiveFixedWhenSOAPChangedAndSOAPIsLowerThanZeroAndSOAPAbsoluteValueIsGreaterThanLiquidityPoolBalance(
    ) public {
        // given
        _miltonSpreadModel.setCalculateQuoteReceiveFixed(TestConstants.PERCENTAGE_2_18DEC);
        ItfIporOracle iporOracle =
            getIporOracleAsset(_userOne, address(_daiMockedToken), TestConstants.TC_DEFAULT_EMA_18DEC_64UINT);
        IIporRiskManagementOracle iporRiskManagementOracle = getRiskManagementOracleAsset(
            _userOne,
            address(_daiMockedToken),
            TestConstants.RMO_UTILIZATION_RATE_48_PER,
            TestConstants.RMO_UTILIZATION_RATE_90_PER,
            TestConstants.RMO_NOTIONAL_1B
        );
        MockCase0Stanley stanleyDai = getMockCase0Stanley(address(_daiMockedToken));
        MiltonStorage miltonStorageDai = getMiltonStorage();
        MockCase0MiltonDai mockCase0MiltonDai = getMockCase0MiltonDai(
            address(_daiMockedToken),
            address(iporOracle),
            address(miltonStorageDai),
            address(_miltonSpreadModel),
            address(stanleyDai),
            address(iporRiskManagementOracle)
        );
        MockCase0JosephDai mockCase0JosephDai = getMockCase0JosephDai(
            address(_daiMockedToken),
            address(_ipTokenDai),
            address(mockCase0MiltonDai),
            address(miltonStorageDai),
            address(stanleyDai)
        );
        prepareApproveForUsersDai(_users, _daiMockedToken, address(mockCase0JosephDai), address(mockCase0MiltonDai));
        prepareMilton(mockCase0MiltonDai, address(mockCase0JosephDai), address(stanleyDai));
        prepareJoseph(mockCase0JosephDai);
        prepareIpToken(_ipTokenDai, address(mockCase0JosephDai));
        // required to have IBT price higher than 0
        vm.prank(_userOne);
        iporOracle.itfUpdateIndex(address(_daiMockedToken), TestConstants.PERCENTAGE_3_18DEC, block.timestamp);
        vm.prank(_liquidityProvider);
        mockCase0JosephDai.itfProvideLiquidity(TestConstants.USD_60_000_18DEC, block.timestamp);
        vm.prank(_userTwo);
        mockCase0MiltonDai.itfOpenSwapReceiveFixed(
            block.timestamp, 27000 * TestConstants.D18, 1 * TestConstants.D16, TestConstants.LEVERAGE_18DEC
        );
        //BEGIN HACK - subtract liquidity without  burn ipToken. Notice! This affect ipToken price!
        miltonStorageDai.setJoseph(_admin);
        miltonStorageDai.subtractLiquidity(55000 * TestConstants.D18);
        miltonStorageDai.setJoseph(address(mockCase0JosephDai));
        //END HACK - subtract liquidity without  burn ipToken. Notice! This affect ipToken price!
        vm.prank(_userOne);
        iporOracle.itfUpdateIndex(address(_daiMockedToken), TestConstants.PERCENTAGE_50_18DEC, block.timestamp);
        // Notice! |SOAP| > Liquidity Pool Balance
        (,, int256 soap) =
            calculateSoap(_userTwo, block.timestamp + TestConstants.PERIOD_25_DAYS_IN_SECONDS, mockCase0MiltonDai);
        IporTypes.MiltonBalancesMemory memory balance = mockCase0MiltonDai.getAccruedBalance();
        uint256 actualExchangeRate =
            mockCase0JosephDai.itfCalculateExchangeRate(block.timestamp + TestConstants.PERIOD_25_DAYS_IN_SECONDS);
        // then
        assertEq(actualExchangeRate, 231183576017208823);
        assertEq(soap, -8864809194596311965885);
        assertEq(balance.liquidityPool, 5006205366436217422150);
    }

    function testShouldCalculateExchangeRatePositionValuesAndSoapWhenTwoPayFixedSwapsAreClosedAfter60Days() public {
        // given
        _miltonSpreadModel.setCalculateQuotePayFixed(TestConstants.PERCENTAGE_4_18DEC);
        ItfIporOracle iporOracle =
            getIporOracleAsset(_userOne, address(_daiMockedToken), TestConstants.TC_DEFAULT_EMA_18DEC_64UINT);
        IIporRiskManagementOracle iporRiskManagementOracle = getRiskManagementOracleAsset(
            _userOne,
            address(_daiMockedToken),
            TestConstants.RMO_UTILIZATION_RATE_48_PER,
            TestConstants.RMO_UTILIZATION_RATE_90_PER,
            TestConstants.RMO_NOTIONAL_1B
        );
        MockCase0Stanley stanleyDai = getMockCase0Stanley(address(_daiMockedToken));
        MiltonStorage miltonStorageDai = getMiltonStorage();
        MockCase0MiltonDai mockCase0MiltonDai = getMockCase0MiltonDai(
            address(_daiMockedToken),
            address(iporOracle),
            address(miltonStorageDai),
            address(_miltonSpreadModel),
            address(stanleyDai),
            address(iporRiskManagementOracle)
        );
        MockCase0JosephDai mockCase0JosephDai = getMockCase0JosephDai(
            address(_daiMockedToken),
            address(_ipTokenDai),
            address(mockCase0MiltonDai),
            address(miltonStorageDai),
            address(stanleyDai)
        );
        prepareApproveForUsersDai(_users, _daiMockedToken, address(mockCase0JosephDai), address(mockCase0MiltonDai));
        prepareMilton(mockCase0MiltonDai, address(mockCase0JosephDai), address(stanleyDai));
        prepareJoseph(mockCase0JosephDai);
        prepareIpToken(_ipTokenDai, address(mockCase0JosephDai));

        // required to have IBT price higher than 0
        vm.prank(_userOne);
        iporOracle.itfUpdateIndex(address(_daiMockedToken), TestConstants.PERCENTAGE_3_18DEC, block.timestamp);

        vm.prank(_liquidityProvider);
        mockCase0JosephDai.itfProvideLiquidity(TestConstants.USD_1_000_000_18DEC, block.timestamp);

        vm.startPrank(_userTwo);
        mockCase0MiltonDai.itfOpenSwapPayFixed(
            block.timestamp, TestConstants.USD_100_000_18DEC, 9 * TestConstants.D17, TestConstants.LEVERAGE_1000_18DEC
        );
        mockCase0MiltonDai.itfOpenSwapPayFixed(
            block.timestamp, TestConstants.USD_100_000_18DEC, 9 * TestConstants.D17, TestConstants.LEVERAGE_1000_18DEC
        );
        vm.stopPrank();

        // fixed interest rate on swaps is equal to 4%, so lets use 4,5% for IPOR here:
        vm.prank(_userOne);
        iporOracle.itfUpdateIndex(address(_daiMockedToken), TestConstants.PERCENTAGE_4_5_18DEC, block.timestamp);

        (,, int256 initialSoap) = calculateSoap(_userTwo, block.timestamp, mockCase0MiltonDai);
        (,, int256 soapAfter28Days) =
            calculateSoap(_userTwo, block.timestamp + TestConstants.PERIOD_28_DAYS_IN_SECONDS, mockCase0MiltonDai);
        (,, int256 soapAfter56DaysBeforeClose) =
            calculateSoap(_userTwo, block.timestamp + TestConstants.PERIOD_56_DAYS_IN_SECONDS, mockCase0MiltonDai);

        ExchangeRateAndPayoff memory exchangeRateAndPayoff;
        exchangeRateAndPayoff.initialExchangeRate = mockCase0JosephDai.itfCalculateExchangeRate(block.timestamp);
        exchangeRateAndPayoff.exchangeRateAfter28Days =
            mockCase0JosephDai.itfCalculateExchangeRate(block.timestamp + TestConstants.PERIOD_28_DAYS_IN_SECONDS);
        exchangeRateAndPayoff.exchangeRateAfter56DaysBeforeClose =
            mockCase0JosephDai.itfCalculateExchangeRate(block.timestamp + TestConstants.PERIOD_56_DAYS_IN_SECONDS);
        exchangeRateAndPayoff.payoff1After28Days = mockCase0MiltonDai.itfCalculateSwapPayFixedValue(
            block.timestamp + TestConstants.PERIOD_28_DAYS_IN_SECONDS, 1
        );
        exchangeRateAndPayoff.payoff2After28Days = mockCase0MiltonDai.itfCalculateSwapPayFixedValue(
            block.timestamp + TestConstants.PERIOD_28_DAYS_IN_SECONDS, 2
        );
        exchangeRateAndPayoff.payoff1After56Days = mockCase0MiltonDai.itfCalculateSwapPayFixedValue(
            block.timestamp + TestConstants.PERIOD_56_DAYS_IN_SECONDS, 1
        );
        exchangeRateAndPayoff.payoff2After56Days = mockCase0MiltonDai.itfCalculateSwapPayFixedValue(
            block.timestamp + TestConstants.PERIOD_56_DAYS_IN_SECONDS, 2
        );
        IporTypes.MiltonBalancesMemory memory liquidityPoolBalanceBeforeClose = miltonStorageDai.getBalance();
        int256 actualSOAPPlusLiquidityPoolBalanceBeforeClose =
            int256(liquidityPoolBalanceBeforeClose.liquidityPool) - soapAfter56DaysBeforeClose;

        // when
//        vm.startPrank(_userOne);
        mockCase0MiltonDai.itfCloseSwapPayFixed(1, block.timestamp + TestConstants.PERIOD_56_DAYS_IN_SECONDS);
        mockCase0MiltonDai.itfCloseSwapPayFixed(2, block.timestamp + TestConstants.PERIOD_56_DAYS_IN_SECONDS);
//        vm.stopPrank();

        // then
        (,, int256 soapAfter56DaysAfterClose) =
            calculateSoap(_userTwo, block.timestamp + TestConstants.PERIOD_56_DAYS_IN_SECONDS, mockCase0MiltonDai);
        IporTypes.MiltonBalancesMemory memory liquidityPoolBalanceAfterClose = miltonStorageDai.getBalance();
        uint256 exchangeRate56DaysAfterClose =
            mockCase0JosephDai.itfCalculateExchangeRate(block.timestamp + TestConstants.PERIOD_56_DAYS_IN_SECONDS);
        assertEq(initialSoap, TestConstants.ZERO_INT);
        assertEq(exchangeRateAndPayoff.initialExchangeRate, 1004497846813069095, "incorrect initial exchange rate");
        assertEq(liquidityPoolBalanceBeforeClose.liquidityPool, 1004497846813069094746924, "incorrect liquidity pool balance before close");
        assertEq(soapAfter28Days, 74964113551151590806229, "incorrect SOAP after 28 days");
        assertEq(exchangeRateAndPayoff.exchangeRateAfter28Days, 929533733261917504, "incorrect exchange rate after 28 days");
        assertEq(exchangeRateAndPayoff.payoff1After28Days, 37482056775575795403115, "incorrect payoff1After28Days");
        assertEq(exchangeRateAndPayoff.payoff2After28Days, 37482056775575795403115, "incorrect payoff2After28Days");
        assertEq(soapAfter56DaysBeforeClose, 149928227102303181612459, "incorrect SOAP after 56 days before close");
        assertEq(exchangeRateAndPayoff.exchangeRateAfter56DaysBeforeClose, 854569619710765913, "incorrect exchange rate after 56 days before close");
        assertEq(exchangeRateAndPayoff.payoff1After56Days, 74964113551151590806229, "incorrect payoff1After56Days");
        assertEq(exchangeRateAndPayoff.payoff2After56Days, 74964113551151590806229, "incorrect payoff2After56Days");
        assertEq(soapAfter56DaysAfterClose, TestConstants.ZERO_INT, "incorrect SOAP after close");
        assertEq(exchangeRate56DaysAfterClose, 854569619710765913, "incorrect exchange rate after close");
        assertEq(liquidityPoolBalanceAfterClose.liquidityPool, 854569619710765913134466, "incorrect Liquidity Pool balance after close");
        // SOAP + Liquidity Pool balance before close should be equal to Liquidity Pool balance after close swaps
        assertEq(actualSOAPPlusLiquidityPoolBalanceBeforeClose, 854569619710765913134465, "incorrect SOAP + Liquidity Pool balance before close");
    }
}

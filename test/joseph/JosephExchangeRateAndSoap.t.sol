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
            TestConstants.MSO_UTILIZATION_RATE_48_PER,
            TestConstants.MSO_UTILIZATION_RATE_90_PER,
            TestConstants.MSO_NOTIONAL_1B
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
        assertEq(actualExchangeRate, 1003093533812002519);
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
            TestConstants.MSO_UTILIZATION_RATE_48_PER,
            TestConstants.MSO_UTILIZATION_RATE_90_PER,
            TestConstants.MSO_NOTIONAL_1B
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
        assertEq(actualExchangeRate, 1009368340867602731);
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
            TestConstants.MSO_UTILIZATION_RATE_48_PER,
            TestConstants.MSO_UTILIZATION_RATE_90_PER,
            TestConstants.MSO_NOTIONAL_1B
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
        assertEq(actualExchangeRate, 987823434476506361);
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
            TestConstants.MSO_UTILIZATION_RATE_48_PER,
            TestConstants.MSO_UTILIZATION_RATE_90_PER,
            TestConstants.MSO_NOTIONAL_1B
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
        assertEq(actualExchangeRate, 987823434476506362);
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
            TestConstants.MSO_UTILIZATION_RATE_48_PER,
            TestConstants.MSO_UTILIZATION_RATE_90_PER,
            TestConstants.MSO_NOTIONAL_1B
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
        assertEq(soap, 8494848805632282803369);
        assertEq(balance.liquidityPool, 5008088573427971608517);
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
            TestConstants.MSO_UTILIZATION_RATE_48_PER,
            TestConstants.MSO_UTILIZATION_RATE_90_PER,
            TestConstants.MSO_NOTIONAL_1B
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
        assertEq(soap, 8494848805632282973266);
        assertEq(balance.liquidityPool, 5008088573427971608517);
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
            TestConstants.MSO_UTILIZATION_RATE_48_PER,
            TestConstants.MSO_UTILIZATION_RATE_90_PER,
            TestConstants.MSO_NOTIONAL_1B
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
        assertEq(actualExchangeRate, 231204643857984158);
        assertEq(soap, -8864190058051077882738);
        assertEq(balance.liquidityPool, 5008088573427971608517);
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
            TestConstants.MSO_UTILIZATION_RATE_48_PER,
            TestConstants.MSO_UTILIZATION_RATE_90_PER,
            TestConstants.MSO_NOTIONAL_1B
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
        assertEq(actualExchangeRate, 231204643857984155);
        assertEq(soap, -8864190058051077712841);
        assertEq(balance.liquidityPool, 5008088573427971608517);
    }

    function testShouldCalculateExchangeRatePositionValuesAndSoapWhenTwoPayFixedSwapsAreClosedAfter60Days() public {
        // given
        _miltonSpreadModel.setCalculateQuotePayFixed(TestConstants.PERCENTAGE_4_18DEC);
        ItfIporOracle iporOracle =
            getIporOracleAsset(_userOne, address(_daiMockedToken), TestConstants.TC_DEFAULT_EMA_18DEC_64UINT);
        IIporRiskManagementOracle iporRiskManagementOracle = getRiskManagementOracleAsset(
            _userOne,
            address(_daiMockedToken),
            TestConstants.MSO_UTILIZATION_RATE_48_PER,
            TestConstants.MSO_UTILIZATION_RATE_90_PER,
            TestConstants.MSO_NOTIONAL_1B
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
        assertEq(exchangeRateAndPayoff.initialExchangeRate, 1000059964010796761);
        assertEq(liquidityPoolBalanceBeforeClose.liquidityPool, 1000059964010796760971708);
        assertEq(soapAfter28Days, 76666315173940979346744);
        assertEq(exchangeRateAndPayoff.exchangeRateAfter28Days, 923393648836855782);
        assertEq(exchangeRateAndPayoff.payoff1After28Days, 38333157586970489673372);
        assertEq(exchangeRateAndPayoff.payoff2After28Days, 38333157586970489673372);
        assertEq(soapAfter56DaysBeforeClose, 153332630347881958693488);
        assertEq(exchangeRateAndPayoff.exchangeRateAfter56DaysBeforeClose, 846727333662914802);
        assertEq(exchangeRateAndPayoff.payoff1After56Days, 76666315173940979346744);
        assertEq(exchangeRateAndPayoff.payoff2After56Days, 76666315173940979346744);
        assertEq(soapAfter56DaysAfterClose, TestConstants.ZERO_INT);
        assertEq(exchangeRate56DaysAfterClose, 846727333662914802);
        assertEq(liquidityPoolBalanceAfterClose.liquidityPool, 846727333662914802278220);
        // SOAP + Liquidity Pool balance before close should be equal to Liquidity Pool balance after close swaps
        assertEq(actualSOAPPlusLiquidityPoolBalanceBeforeClose, 846727333662914802278220);
    }
}

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
import "../../contracts/mocks/milton/MockCase0MiltonUsdt.sol";
import "../../contracts/mocks/stanley/MockCase0Stanley.sol";
import "../../contracts/mocks/joseph/MockCase0JosephDai.sol";
import "../../contracts/mocks/joseph/MockCase0JosephUsdt.sol";
import "../../contracts/amm/MiltonStorage.sol";
import "../../contracts/itf/ItfIporOracle.sol";
import "../../contracts/interfaces/IMarketSafetyOracle.sol";
import "../../contracts/interfaces/types/IporTypes.sol";

contract JosephRedeem is TestCommons, DataUtils, SwapUtils {
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
            TestConstants.PERCENTAGE_4_18DEC,
            TestConstants.PERCENTAGE_2_18DEC,
            TestConstants.ZERO_INT,
            TestConstants.ZERO_INT
        );
    }

    function testShouldRedeemIpToken18DecimalsSimpleCase1() public {
        // given
        ItfIporOracle iporOracle =
            getIporOracleAsset(_userOne, address(_daiMockedToken), TestConstants.TC_DEFAULT_EMA_18DEC_64UINT);
        IMarketSafetyOracle marketSafetyOracle = getMarketSafetyOracleAsset(
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
            address(marketSafetyOracle)
        );
        MockCase0JosephDai mockCase0JosephDai = getMockCase0JosephDai(
            address(_daiMockedToken),
            address(_ipTokenDai),
            address(mockCase0MiltonDai),
            address(miltonStorageDai),
            address(stanleyDai)
        );
        uint256 redeemFee = 50 * TestConstants.D18;
        ExpectedJosephBalances memory expectedBalances;
        expectedBalances.expectedIpTokenBalance = 4000 * TestConstants.D18;
        expectedBalances.expectedTokenBalance = 9996000 * TestConstants.D18 - redeemFee;
        expectedBalances.expectedMiltonBalance = 4000 * TestConstants.D18 + redeemFee;
        expectedBalances.expectedLiquidityPoolBalance = 4000 * TestConstants.D18 + redeemFee;
        prepareApproveForUsersDai(_users, _daiMockedToken, address(mockCase0JosephDai), address(mockCase0MiltonDai));
        prepareMilton(mockCase0MiltonDai, address(mockCase0JosephDai), address(stanleyDai));
        prepareJoseph(mockCase0JosephDai);
        prepareIpToken(_ipTokenDai, address(mockCase0JosephDai));
        vm.startPrank(_liquidityProvider);
        mockCase0JosephDai.itfProvideLiquidity(TestConstants.USD_14_000_18DEC, block.timestamp);
        // when
        mockCase0JosephDai.itfRedeem(TestConstants.TC_TOTAL_AMOUNT_10_000_18DEC, block.timestamp);
        vm.stopPrank();
        IporTypes.MiltonBalancesMemory memory balance = mockCase0MiltonDai.getAccruedBalance();
        uint256 actualLiquidityPoolBalance = balance.liquidityPool;
        // then
        assertEq(_ipTokenDai.balanceOf(_liquidityProvider), expectedBalances.expectedIpTokenBalance);
        assertEq(_daiMockedToken.balanceOf(address(mockCase0MiltonDai)), expectedBalances.expectedMiltonBalance);
        assertEq(actualLiquidityPoolBalance, expectedBalances.expectedLiquidityPoolBalance);
        assertEq(_daiMockedToken.balanceOf(_liquidityProvider), expectedBalances.expectedTokenBalance);
    }

    function testShouldRedeemIpToken6DecimalsSimpleCase1() public {
        // given
        ItfIporOracle iporOracle =
            getIporOracleAsset(_userOne, address(_usdtMockedToken), TestConstants.TC_DEFAULT_EMA_18DEC_64UINT);
        IMarketSafetyOracle marketSafetyOracle = getMarketSafetyOracleAsset(
            _userOne,
            address(_usdtMockedToken),
            TestConstants.MSO_UTILIZATION_RATE_48_PER,
            TestConstants.MSO_UTILIZATION_RATE_90_PER,
            TestConstants.MSO_NOTIONAL_1B
        );
        MockCase0Stanley stanleyUsdt = getMockCase0Stanley(address(_usdtMockedToken));
        MiltonStorage miltonStorageUsdt = getMiltonStorage();
        MockCase0MiltonUsdt mockCase0MiltonUsdt = getMockCase0MiltonUsdt(
            address(_usdtMockedToken),
            address(iporOracle),
            address(miltonStorageUsdt),
            address(_miltonSpreadModel),
            address(stanleyUsdt),
            address(marketSafetyOracle)
        );
        MockCase0JosephUsdt mockCase0JosephUsdt = getMockCase0JosephUsdt(
            address(_usdtMockedToken),
            address(_ipTokenUsdt),
            address(mockCase0MiltonUsdt),
            address(miltonStorageUsdt),
            address(stanleyUsdt)
        );
        uint256 redeemFee18Dec = 50 * TestConstants.D18;
        uint256 redeemFee6Dec = 50 * TestConstants.N1__0_6DEC;
        ExpectedJosephBalances memory expectedBalances;
        expectedBalances.expectedIpTokenBalance = 4000 * TestConstants.D18;
        expectedBalances.expectedTokenBalance = 9996000 * TestConstants.N1__0_6DEC - redeemFee6Dec;
        expectedBalances.expectedMiltonBalance = 4000 * TestConstants.N1__0_6DEC + redeemFee6Dec;
        expectedBalances.expectedLiquidityPoolBalance = 4000 * TestConstants.D18 + redeemFee18Dec;
        prepareApproveForUsersUsd(_users, _usdtMockedToken, address(mockCase0JosephUsdt), address(mockCase0MiltonUsdt));
        prepareMilton(mockCase0MiltonUsdt, address(mockCase0JosephUsdt), address(stanleyUsdt));
        prepareJoseph(mockCase0JosephUsdt);
        prepareIpToken(_ipTokenUsdt, address(mockCase0JosephUsdt));
        vm.startPrank(_liquidityProvider);
        mockCase0JosephUsdt.itfProvideLiquidity(TestConstants.USD_14_000_6DEC, block.timestamp);
        // when
        mockCase0JosephUsdt.itfRedeem(TestConstants.TC_TOTAL_AMOUNT_10_000_18DEC, block.timestamp);
        vm.stopPrank();
        IporTypes.MiltonBalancesMemory memory balance = mockCase0MiltonUsdt.getAccruedBalance();
        uint256 actualLiquidityPoolBalance = balance.liquidityPool;
        // then
        assertEq(_ipTokenUsdt.balanceOf(_liquidityProvider), expectedBalances.expectedIpTokenBalance);
        assertEq(_usdtMockedToken.balanceOf(address(mockCase0MiltonUsdt)), expectedBalances.expectedMiltonBalance);
        assertEq(actualLiquidityPoolBalance, expectedBalances.expectedLiquidityPoolBalance);
        assertEq(_usdtMockedToken.balanceOf(_liquidityProvider), expectedBalances.expectedTokenBalance);
    }

    function testShouldRedeemIpTokensBecauseNoValidationForCoolOffPeriod() public {
        // given
        ItfIporOracle iporOracle =
            getIporOracleAsset(_userOne, address(_daiMockedToken), TestConstants.TC_DEFAULT_EMA_18DEC_64UINT);
        IMarketSafetyOracle marketSafetyOracle = getMarketSafetyOracleAsset(
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
            address(marketSafetyOracle)
        );
        MockCase0JosephDai mockCase0JosephDai = getMockCase0JosephDai(
            address(_daiMockedToken),
            address(_ipTokenDai),
            address(mockCase0MiltonDai),
            address(miltonStorageDai),
            address(stanleyDai)
        );
        uint256 redeemFee = 50 * TestConstants.D18;
        ExpectedJosephBalances memory expectedBalances;
        expectedBalances.expectedIpTokenBalance = 4000 * TestConstants.D18;
        expectedBalances.expectedTokenBalance = 9996000 * TestConstants.D18 - redeemFee;
        expectedBalances.expectedMiltonBalance = 4000 * TestConstants.D18 + redeemFee;
        expectedBalances.expectedLiquidityPoolBalance = 4000 * TestConstants.D18 + redeemFee;
        prepareApproveForUsersDai(_users, _daiMockedToken, address(mockCase0JosephDai), address(mockCase0MiltonDai));
        prepareMilton(mockCase0MiltonDai, address(mockCase0JosephDai), address(stanleyDai));
        prepareJoseph(mockCase0JosephDai);
        prepareIpToken(_ipTokenDai, address(mockCase0JosephDai));
        vm.startPrank(_liquidityProvider);
        mockCase0JosephDai.itfProvideLiquidity(TestConstants.USD_14_000_18DEC, block.timestamp);
        // when
        mockCase0JosephDai.itfRedeem(TestConstants.TC_TOTAL_AMOUNT_10_000_18DEC, block.timestamp);
        vm.stopPrank();
        IporTypes.MiltonBalancesMemory memory balance = mockCase0MiltonDai.getAccruedBalance();
        uint256 actualLiquidityPoolBalance = balance.liquidityPool;
        // then
        assertEq(_ipTokenDai.balanceOf(_liquidityProvider), expectedBalances.expectedIpTokenBalance);
        assertEq(_daiMockedToken.balanceOf(address(mockCase0MiltonDai)), expectedBalances.expectedMiltonBalance);
        assertEq(_daiMockedToken.balanceOf(_liquidityProvider), expectedBalances.expectedTokenBalance);
        assertEq(actualLiquidityPoolBalance, expectedBalances.expectedLiquidityPoolBalance);
    }

    function testShouldRedeemIpTokensWhenTwoTimesProvidedLiquidity() public {
        // given
        ItfIporOracle iporOracle =
            getIporOracleAsset(_userOne, address(_daiMockedToken), TestConstants.TC_DEFAULT_EMA_18DEC_64UINT);
        IMarketSafetyOracle marketSafetyOracle = getMarketSafetyOracleAsset(
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
            address(marketSafetyOracle)
        );
        MockCase0JosephDai mockCase0JosephDai = getMockCase0JosephDai(
            address(_daiMockedToken),
            address(_ipTokenDai),
            address(mockCase0MiltonDai),
            address(miltonStorageDai),
            address(stanleyDai)
        );
        uint256 redeemFee = 70 * TestConstants.D18;
        ExpectedJosephBalances memory expectedBalances;
        expectedBalances.expectedIpTokenBalance = 6000 * TestConstants.D18;
        expectedBalances.expectedTokenBalance = 9994000 * TestConstants.D18 - redeemFee;
        expectedBalances.expectedMiltonBalance = 6000 * TestConstants.D18 + redeemFee;
        expectedBalances.expectedLiquidityPoolBalance = 6000 * TestConstants.D18 + redeemFee;
        prepareApproveForUsersDai(_users, _daiMockedToken, address(mockCase0JosephDai), address(mockCase0MiltonDai));
        prepareMilton(mockCase0MiltonDai, address(mockCase0JosephDai), address(stanleyDai));
        prepareJoseph(mockCase0JosephDai);
        prepareIpToken(_ipTokenDai, address(mockCase0JosephDai));
        vm.startPrank(_liquidityProvider);
        mockCase0JosephDai.itfProvideLiquidity(TestConstants.TC_TOTAL_AMOUNT_10_000_18DEC, block.timestamp);
        mockCase0JosephDai.itfProvideLiquidity(TestConstants.TC_TOTAL_AMOUNT_10_000_18DEC, block.timestamp);
        // when
        mockCase0JosephDai.itfRedeem(TestConstants.USD_14_000_18DEC, block.timestamp);
        vm.stopPrank();
        IporTypes.MiltonBalancesMemory memory balance = mockCase0MiltonDai.getAccruedBalance();
        uint256 actualLiquidityPoolBalance = balance.liquidityPool;
        // then
        assertEq(_ipTokenDai.balanceOf(_liquidityProvider), expectedBalances.expectedIpTokenBalance);
        assertEq(_daiMockedToken.balanceOf(address(mockCase0MiltonDai)), expectedBalances.expectedMiltonBalance);
        assertEq(_daiMockedToken.balanceOf(_liquidityProvider), expectedBalances.expectedTokenBalance);
        assertEq(actualLiquidityPoolBalance, expectedBalances.expectedLiquidityPoolBalance);
    }

    function testShouldRedeemIpDaiAndIpUsdtWhenSimpleCase1() public {
        // given
        ItfIporOracle iporOracleDai =
            getIporOracleAsset(_userOne, address(_daiMockedToken), TestConstants.TC_DEFAULT_EMA_18DEC_64UINT);
        IMarketSafetyOracle marketSafetyOracleDai = getMarketSafetyOracleAsset(
            _userOne,
            address(_daiMockedToken),
            TestConstants.MSO_UTILIZATION_RATE_48_PER,
            TestConstants.MSO_UTILIZATION_RATE_90_PER,
            TestConstants.MSO_NOTIONAL_1B
        );
        ItfIporOracle iporOracleUsdt =
            getIporOracleAsset(_userOne, address(_usdtMockedToken), TestConstants.TC_DEFAULT_EMA_18DEC_64UINT);
        IMarketSafetyOracle marketSafetyOracleUsdt = getMarketSafetyOracleAsset(
            _userOne,
            address(_usdtMockedToken),
            TestConstants.MSO_UTILIZATION_RATE_48_PER,
            TestConstants.MSO_UTILIZATION_RATE_90_PER,
            TestConstants.MSO_NOTIONAL_1B
        );
        MockCase0Stanley stanleyDai = getMockCase0Stanley(address(_daiMockedToken));
        MockCase0Stanley stanleyUsdt = getMockCase0Stanley(address(_usdtMockedToken));
        MiltonStorage miltonStorageDai = getMiltonStorage();
        MiltonStorage miltonStorageUsdt = getMiltonStorage();
        MockCase0MiltonDai mockCase0MiltonDai = getMockCase0MiltonDai(
            address(_daiMockedToken),
            address(iporOracleDai),
            address(miltonStorageDai),
            address(_miltonSpreadModel),
            address(stanleyDai),
            address(marketSafetyOracleDai)
        );
        MockCase0MiltonUsdt mockCase0MiltonUsdt = getMockCase0MiltonUsdt(
            address(_usdtMockedToken),
            address(iporOracleUsdt),
            address(miltonStorageUsdt),
            address(_miltonSpreadModel),
            address(stanleyUsdt),
            address(marketSafetyOracleUsdt)
        );
        MockCase0JosephDai mockCase0JosephDai = getMockCase0JosephDai(
            address(_daiMockedToken),
            address(_ipTokenDai),
            address(mockCase0MiltonDai),
            address(miltonStorageDai),
            address(stanleyDai)
        );
        MockCase0JosephUsdt mockCase0JosephUsdt = getMockCase0JosephUsdt(
            address(_usdtMockedToken),
            address(_ipTokenUsdt),
            address(mockCase0MiltonUsdt),
            address(miltonStorageUsdt),
            address(stanleyUsdt)
        );
        uint256 redeemFee18Dec = 50 * TestConstants.D18;
        uint256 redeemFee6Dec = 50 * TestConstants.N1__0_6DEC;
        ExpectedJosephBalances memory expectedBalancesDai;
        expectedBalancesDai.expectedIpTokenBalance = 4000 * TestConstants.D18;
        expectedBalancesDai.expectedTokenBalance = 9996000 * TestConstants.D18 - redeemFee18Dec;
        expectedBalancesDai.expectedMiltonBalance = 4000 * TestConstants.D18 + redeemFee18Dec;
        expectedBalancesDai.expectedLiquidityPoolBalance = 4000 * TestConstants.D18 + redeemFee18Dec;
        ExpectedJosephBalances memory expectedBalancesUsdt;
        expectedBalancesUsdt.expectedIpTokenBalance = 4000 * TestConstants.D18;
        expectedBalancesUsdt.expectedTokenBalance = 9996000 * TestConstants.N1__0_6DEC - redeemFee6Dec;
        expectedBalancesUsdt.expectedMiltonBalance = 4000 * TestConstants.N1__0_6DEC + redeemFee6Dec;
        expectedBalancesUsdt.expectedLiquidityPoolBalance = 4000 * TestConstants.D18 + redeemFee18Dec;
        prepareApproveForUsersDai(_users, _daiMockedToken, address(mockCase0JosephDai), address(mockCase0MiltonDai));
        prepareApproveForUsersUsd(_users, _usdtMockedToken, address(mockCase0JosephUsdt), address(mockCase0MiltonUsdt));
        prepareMilton(mockCase0MiltonDai, address(mockCase0JosephDai), address(stanleyDai));
        prepareMilton(mockCase0MiltonUsdt, address(mockCase0JosephUsdt), address(stanleyUsdt));
        prepareJoseph(mockCase0JosephDai);
        prepareJoseph(mockCase0JosephUsdt);
        prepareIpToken(_ipTokenDai, address(mockCase0JosephDai));
        prepareIpToken(_ipTokenUsdt, address(mockCase0JosephUsdt));
        vm.startPrank(_liquidityProvider);
        mockCase0JosephDai.itfProvideLiquidity(TestConstants.USD_14_000_18DEC, block.timestamp);
        mockCase0JosephUsdt.itfProvideLiquidity(TestConstants.USD_14_000_6DEC, block.timestamp);
        // when
        mockCase0JosephDai.itfRedeem(TestConstants.TC_TOTAL_AMOUNT_10_000_18DEC, block.timestamp);
        mockCase0JosephUsdt.itfRedeem(TestConstants.TC_TOTAL_AMOUNT_10_000_18DEC, block.timestamp);
        vm.stopPrank();
        IporTypes.MiltonBalancesMemory memory balanceDai = mockCase0MiltonDai.getAccruedBalance();
        uint256 actualLiquidityPoolBalanceDai = balanceDai.liquidityPool;
        IporTypes.MiltonBalancesMemory memory balanceUsdt = mockCase0MiltonUsdt.getAccruedBalance();
        uint256 actualLiquidityPoolBalanceUsdt = balanceUsdt.liquidityPool;
        // then
        assertEq(_ipTokenDai.balanceOf(_liquidityProvider), expectedBalancesDai.expectedIpTokenBalance);
        assertEq(_daiMockedToken.balanceOf(address(mockCase0MiltonDai)), expectedBalancesDai.expectedMiltonBalance);
        assertEq(_daiMockedToken.balanceOf(_liquidityProvider), expectedBalancesDai.expectedTokenBalance);
        assertEq(actualLiquidityPoolBalanceDai, expectedBalancesDai.expectedLiquidityPoolBalance);
        assertEq(_ipTokenUsdt.balanceOf(_liquidityProvider), expectedBalancesUsdt.expectedIpTokenBalance);
        assertEq(_usdtMockedToken.balanceOf(address(mockCase0MiltonUsdt)), expectedBalancesUsdt.expectedMiltonBalance);
        assertEq(_usdtMockedToken.balanceOf(_liquidityProvider), expectedBalancesUsdt.expectedTokenBalance);
        assertEq(actualLiquidityPoolBalanceUsdt, expectedBalancesUsdt.expectedLiquidityPoolBalance);
    }

    function testShouldRedeemIpDaiAndIpUsdtWhenTwoUsersAndSimpleCase1() public {
        // given
        ItfIporOracle iporOracleDai =
            getIporOracleAsset(_userOne, address(_daiMockedToken), TestConstants.TC_DEFAULT_EMA_18DEC_64UINT);
        IMarketSafetyOracle marketSafetyOracleDai = getMarketSafetyOracleAsset(
            _userOne,
            address(_daiMockedToken),
            TestConstants.MSO_UTILIZATION_RATE_48_PER,
            TestConstants.MSO_UTILIZATION_RATE_90_PER,
            TestConstants.MSO_NOTIONAL_1B
        );
        ItfIporOracle iporOracleUsdt =
            getIporOracleAsset(_userOne, address(_usdtMockedToken), TestConstants.TC_DEFAULT_EMA_18DEC_64UINT);
        IMarketSafetyOracle marketSafetyOracle = getMarketSafetyOracleAsset(
            _userOne,
            address(_usdtMockedToken),
            TestConstants.MSO_UTILIZATION_RATE_48_PER,
            TestConstants.MSO_UTILIZATION_RATE_90_PER,
            TestConstants.MSO_NOTIONAL_1B
        );
        MockCase0Stanley stanleyDai = getMockCase0Stanley(address(_daiMockedToken));
        MockCase0Stanley stanleyUsdt = getMockCase0Stanley(address(_usdtMockedToken));
        MiltonStorage miltonStorageDai = getMiltonStorage();
        MiltonStorage miltonStorageUsdt = getMiltonStorage();
        MockCase0MiltonDai mockCase0MiltonDai = getMockCase0MiltonDai(
            address(_daiMockedToken),
            address(iporOracleDai),
            address(miltonStorageDai),
            address(_miltonSpreadModel),
            address(stanleyDai),
            address(marketSafetyOracleDai)
        );
        MockCase0MiltonUsdt mockCase0MiltonUsdt = getMockCase0MiltonUsdt(
            address(_usdtMockedToken),
            address(iporOracleUsdt),
            address(miltonStorageUsdt),
            address(_miltonSpreadModel),
            address(stanleyUsdt),
            address(marketSafetyOracle)
        );
        MockCase0JosephDai mockCase0JosephDai = getMockCase0JosephDai(
            address(_daiMockedToken),
            address(_ipTokenDai),
            address(mockCase0MiltonDai),
            address(miltonStorageDai),
            address(stanleyDai)
        );
        MockCase0JosephUsdt mockCase0JosephUsdt = getMockCase0JosephUsdt(
            address(_usdtMockedToken),
            address(_ipTokenUsdt),
            address(mockCase0MiltonUsdt),
            address(miltonStorageUsdt),
            address(stanleyUsdt)
        );
        uint256 redeemFee18Dec = 50 * TestConstants.D18;
        uint256 redeemFee6Dec = 50 * TestConstants.N1__0_6DEC;
        ExpectedJosephBalances memory expectedBalancesDai;
        expectedBalancesDai.expectedIpTokenBalance = 4000 * TestConstants.D18;
        expectedBalancesDai.expectedTokenBalance = 9996000 * TestConstants.D18 - redeemFee18Dec;
        expectedBalancesDai.expectedMiltonBalance = 4000 * TestConstants.D18 + redeemFee18Dec;
        expectedBalancesDai.expectedLiquidityPoolBalance = 4000 * TestConstants.D18 + redeemFee18Dec;
        ExpectedJosephBalances memory expectedBalancesUsdt;
        expectedBalancesUsdt.expectedIpTokenBalance = 4000 * TestConstants.D18;
        expectedBalancesUsdt.expectedTokenBalance = 9996000 * TestConstants.N1__0_6DEC - redeemFee6Dec;
        expectedBalancesUsdt.expectedMiltonBalance = 4000 * TestConstants.N1__0_6DEC + redeemFee6Dec;
        expectedBalancesUsdt.expectedLiquidityPoolBalance = 4000 * TestConstants.D18 + redeemFee18Dec;
        prepareApproveForUsersDai(_users, _daiMockedToken, address(mockCase0JosephDai), address(mockCase0MiltonDai));
        prepareApproveForUsersUsd(_users, _usdtMockedToken, address(mockCase0JosephUsdt), address(mockCase0MiltonUsdt));
        prepareMilton(mockCase0MiltonDai, address(mockCase0JosephDai), address(stanleyDai));
        prepareMilton(mockCase0MiltonUsdt, address(mockCase0JosephUsdt), address(stanleyUsdt));
        prepareJoseph(mockCase0JosephDai);
        prepareJoseph(mockCase0JosephUsdt);
        prepareIpToken(_ipTokenDai, address(mockCase0JosephDai));
        prepareIpToken(_ipTokenUsdt, address(mockCase0JosephUsdt));
        vm.prank(_userOne);
        mockCase0JosephDai.itfProvideLiquidity(TestConstants.USD_14_000_18DEC, block.timestamp);
        vm.prank(_userTwo);
        mockCase0JosephUsdt.itfProvideLiquidity(TestConstants.USD_14_000_6DEC, block.timestamp);
        // when
        vm.prank(_userOne);
        mockCase0JosephDai.itfRedeem(TestConstants.TC_TOTAL_AMOUNT_10_000_18DEC, block.timestamp);
        vm.prank(_userTwo);
        mockCase0JosephUsdt.itfRedeem(TestConstants.TC_TOTAL_AMOUNT_10_000_18DEC, block.timestamp);
        IporTypes.MiltonBalancesMemory memory balanceDai = mockCase0MiltonDai.getAccruedBalance();
        uint256 actualLiquidityPoolBalanceDai = balanceDai.liquidityPool;
        IporTypes.MiltonBalancesMemory memory balanceUsdt = mockCase0MiltonUsdt.getAccruedBalance();
        uint256 actualLiquidityPoolBalanceUsdt = balanceUsdt.liquidityPool;
        // then
        assertEq(_ipTokenDai.balanceOf(_userOne), expectedBalancesDai.expectedIpTokenBalance);
        assertEq(_daiMockedToken.balanceOf(address(mockCase0MiltonDai)), expectedBalancesDai.expectedMiltonBalance);
        assertEq(_daiMockedToken.balanceOf(_userOne), expectedBalancesDai.expectedTokenBalance);
        assertEq(balanceDai.liquidityPool, expectedBalancesDai.expectedLiquidityPoolBalance);
        assertEq(_ipTokenUsdt.balanceOf(_userTwo), expectedBalancesUsdt.expectedIpTokenBalance);
        assertEq(_usdtMockedToken.balanceOf(address(mockCase0MiltonUsdt)), expectedBalancesUsdt.expectedMiltonBalance);
        assertEq(_usdtMockedToken.balanceOf(_userTwo), expectedBalancesUsdt.expectedTokenBalance);
        assertEq(balanceUsdt.liquidityPool, expectedBalancesUsdt.expectedLiquidityPoolBalance);
    }

    function testShouldRedeemWhenLiquidityProviderCanTransferTokensToAnotherUserAndUserCanRedeemTokens() public {
        // given
        ItfIporOracle iporOracle =
            getIporOracleAsset(_userOne, address(_daiMockedToken), TestConstants.TC_DEFAULT_EMA_18DEC_64UINT);
        IMarketSafetyOracle marketSafetyOracle = getMarketSafetyOracleAsset(
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
            address(marketSafetyOracle)
        );
        MockCase0JosephDai mockCase0JosephDai = getMockCase0JosephDai(
            address(_daiMockedToken),
            address(_ipTokenDai),
            address(mockCase0MiltonDai),
            address(miltonStorageDai),
            address(stanleyDai)
        );
        uint256 redeemFee = 50 * TestConstants.D18;
        ExpectedJosephBalances memory expectedBalancesLiquidityProvider;
        expectedBalancesLiquidityProvider.expectedIpTokenBalance = 400 * TestConstants.D18;
        expectedBalancesLiquidityProvider.expectedTokenBalance = 9989600 * TestConstants.D18;
        expectedBalancesLiquidityProvider.expectedMiltonBalance = 400 * TestConstants.D18 + redeemFee;
        expectedBalancesLiquidityProvider.expectedLiquidityPoolBalance = 400 * TestConstants.D18 + redeemFee;
        ExpectedJosephBalances memory expectedBalancesUserThree;
        expectedBalancesUserThree.expectedIpTokenBalance = TestConstants.ZERO;
        expectedBalancesUserThree.expectedTokenBalance = 10010000 * TestConstants.D18 - redeemFee;
        prepareApproveForUsersDai(_users, _daiMockedToken, address(mockCase0JosephDai), address(mockCase0MiltonDai));
        prepareMilton(mockCase0MiltonDai, address(mockCase0JosephDai), address(stanleyDai));
        prepareJoseph(mockCase0JosephDai);
        prepareIpToken(_ipTokenDai, address(mockCase0JosephDai));
        vm.startPrank(_liquidityProvider);
        mockCase0JosephDai.itfProvideLiquidity(TestConstants.USD_10_400_18DEC, block.timestamp);
        _ipTokenDai.transfer(_userThree, TestConstants.TC_TOTAL_AMOUNT_10_000_18DEC);
        // when
        vm.stopPrank();
        vm.prank(_userThree);
        mockCase0JosephDai.itfRedeem(TestConstants.TC_TOTAL_AMOUNT_10_000_18DEC, block.timestamp);
        IporTypes.MiltonBalancesMemory memory balance = mockCase0MiltonDai.getAccruedBalance();
        uint256 actualLiquidityPoolBalance = balance.liquidityPool;
        // then
        assertEq(_ipTokenDai.balanceOf(_liquidityProvider), expectedBalancesLiquidityProvider.expectedIpTokenBalance);
        assertEq(
            _daiMockedToken.balanceOf(address(mockCase0MiltonDai)),
            expectedBalancesLiquidityProvider.expectedMiltonBalance
        );
        assertEq(_daiMockedToken.balanceOf(_liquidityProvider), expectedBalancesLiquidityProvider.expectedTokenBalance);
        assertEq(actualLiquidityPoolBalance, expectedBalancesLiquidityProvider.expectedLiquidityPoolBalance);
        assertEq(_ipTokenDai.balanceOf(_userThree), expectedBalancesUserThree.expectedIpTokenBalance);
        assertEq(_daiMockedToken.balanceOf(_userThree), expectedBalancesUserThree.expectedTokenBalance);
    }

    function testShouldRedeemWhenLiquidityPoolUtilizationNotExceededAndPayFixed() public {
        // given
        ItfIporOracle iporOracle =
            getIporOracleAsset(_userOne, address(_daiMockedToken), TestConstants.TC_DEFAULT_EMA_18DEC_64UINT);
        IMarketSafetyOracle marketSafetyOracle = getMarketSafetyOracleAsset(
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
            address(marketSafetyOracle)
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
        vm.prank(_userOne);
        iporOracle.itfUpdateIndex(address(_daiMockedToken), TestConstants.PERCENTAGE_3_18DEC, block.timestamp);
        vm.prank(_liquidityProvider);
        mockCase0JosephDai.itfProvideLiquidity(TestConstants.USD_100_000_18DEC, block.timestamp);
        vm.prank(_userTwo);
        mockCase0MiltonDai.itfOpenSwapPayFixed(
            block.timestamp, 27000 * TestConstants.D18, 9 * TestConstants.D17, TestConstants.LEVERAGE_18DEC
        );
        IporTypes.MiltonBalancesMemory memory balance = mockCase0MiltonDai.getAccruedBalance();
        uint256 actualCollateral = balance.totalCollateralPayFixed + balance.totalCollateralReceiveFixed;
        uint256 actualLiquidityPoolBalance = balance.liquidityPool;
        uint256 expectedIpTokenBalanceSender = 49000 * TestConstants.D18;
        // when
        vm.prank(_liquidityProvider);
        mockCase0JosephDai.itfRedeem(51000 * TestConstants.D18, block.timestamp);
        // then
        //this line is not achieved if redeem failed
        uint256 actualIpTokenBalanceSender = _ipTokenDai.balanceOf(_liquidityProvider);
        assertLe(actualCollateral, actualLiquidityPoolBalance);
        assertEq(actualIpTokenBalanceSender, expectedIpTokenBalanceSender);
    }

    function testShouldRedeemWhenLiquidityPoolUtilizationNotExceededAndReceiveFixed() public {
        // given
        ItfIporOracle iporOracle =
            getIporOracleAsset(_userOne, address(_daiMockedToken), TestConstants.TC_DEFAULT_EMA_18DEC_64UINT);
        IMarketSafetyOracle marketSafetyOracle = getMarketSafetyOracleAsset(
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
            address(marketSafetyOracle)
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
        vm.prank(_userOne);
        iporOracle.itfUpdateIndex(address(_daiMockedToken), TestConstants.PERCENTAGE_3_18DEC, block.timestamp);
        vm.prank(_liquidityProvider);
        mockCase0JosephDai.itfProvideLiquidity(TestConstants.USD_100_000_18DEC, block.timestamp);
        vm.prank(_userTwo);
        mockCase0MiltonDai.itfOpenSwapReceiveFixed(
            block.timestamp, 40000 * TestConstants.D18, TestConstants.D16, TestConstants.LEVERAGE_18DEC
        );
        IporTypes.MiltonBalancesMemory memory balance = mockCase0MiltonDai.getAccruedBalance();
        uint256 actualCollateral = balance.totalCollateralPayFixed + balance.totalCollateralReceiveFixed;
        uint256 actualLiquidityPoolBalance = balance.liquidityPool;
        uint256 expectedIpTokenBalanceSender = 49000 * TestConstants.D18;
        // when
        vm.prank(_liquidityProvider);
        mockCase0JosephDai.itfRedeem(51000 * TestConstants.D18, block.timestamp);
        // then
        //this line is not achieved if redeem failed
        uint256 actualIpTokenBalanceSender = _ipTokenDai.balanceOf(_liquidityProvider);
        assertLe(actualCollateral, actualLiquidityPoolBalance);
        assertEq(actualIpTokenBalanceSender, expectedIpTokenBalanceSender);
    }

    function testShouldRedeemWhenLiquidityPoolUtilizationNotExceededAndNotOpenPayFixedWhenMaxUtilizationExceeded()
        public
    {
        // given
        ItfIporOracle iporOracle =
            getIporOracleAsset(_userOne, address(_daiMockedToken), TestConstants.TC_DEFAULT_EMA_18DEC_64UINT);
        IMarketSafetyOracle marketSafetyOracle = getMarketSafetyOracleAsset(
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
            address(marketSafetyOracle)
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
        vm.prank(_userOne);
        iporOracle.itfUpdateIndex(address(_daiMockedToken), TestConstants.PERCENTAGE_3_18DEC, block.timestamp);
        vm.prank(_liquidityProvider);
        mockCase0JosephDai.itfProvideLiquidity(TestConstants.USD_100_000_18DEC, block.timestamp);
        // position that sets leg utilization at 48%
        vm.prank(_userTwo);
        mockCase0MiltonDai.itfOpenSwapPayFixed(
            block.timestamp, 48000 * TestConstants.D18, 9 * TestConstants.D17, TestConstants.LEVERAGE_18DEC
        );
        // first small redeem
        vm.prank(_liquidityProvider);
        mockCase0JosephDai.itfRedeem(TestConstants.USD_10_000_18DEC, block.timestamp);
        //show that currently liquidity pool utilization for opening position is achieved
        vm.expectRevert("IPOR_303");
        vm.prank(_userTwo);
        mockCase0MiltonDai.itfOpenSwapPayFixed(
            block.timestamp, 50 * TestConstants.D18, 9 * TestConstants.D17, TestConstants.LEVERAGE_18DEC
        );
        uint256 expectedIpTokenBalanceSender = 79700 * TestConstants.D18;
        // when
        vm.prank(_liquidityProvider);
        mockCase0JosephDai.itfRedeem(10300 * TestConstants.D18, block.timestamp);
        // then
        //this line is not achieved if redeem failed
        uint256 actualIpTokenBalanceSender = _ipTokenDai.balanceOf(_liquidityProvider);
        assertEq(actualIpTokenBalanceSender, expectedIpTokenBalanceSender);
    }

    function testShouldRedeemWhenLiquidityPoolUtilizationNotExceededAndNotOpenReceiveFixedWhenMaxUtilizationExceeded()
        public
    {
        // given
        ItfIporOracle iporOracle =
            getIporOracleAsset(_userOne, address(_daiMockedToken), TestConstants.TC_DEFAULT_EMA_18DEC_64UINT);
        IMarketSafetyOracle marketSafetyOracle = getMarketSafetyOracleAsset(
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
            address(marketSafetyOracle)
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
        vm.prank(_userOne);
        iporOracle.itfUpdateIndex(address(_daiMockedToken), TestConstants.PERCENTAGE_3_18DEC, block.timestamp);
        vm.prank(_liquidityProvider);
        mockCase0JosephDai.itfProvideLiquidity(TestConstants.USD_100_000_18DEC, block.timestamp);
        // position that sets leg utilization at 48%
        vm.prank(_userTwo);
        mockCase0MiltonDai.itfOpenSwapReceiveFixed(
            block.timestamp, 48000 * TestConstants.D18, TestConstants.D16, TestConstants.LEVERAGE_18DEC
        );
        // first small redeem
        vm.prank(_liquidityProvider);
        mockCase0JosephDai.itfRedeem(TestConstants.USD_10_000_18DEC, block.timestamp);
        //show that currently liquidity pool utilization for opening position is achieved
        vm.expectRevert("IPOR_303");
        vm.prank(_userTwo);
        mockCase0MiltonDai.itfOpenSwapReceiveFixed(
            block.timestamp, 50 * TestConstants.D18, 9 * TestConstants.D17, TestConstants.LEVERAGE_18DEC
        );
        uint256 expectedIpTokenBalanceSender = 79700 * TestConstants.D18;
        // when
        vm.prank(_liquidityProvider);
        mockCase0JosephDai.itfRedeem(10300 * TestConstants.D18, block.timestamp);
        // then
        //this line is not achieved if redeem failed
        uint256 actualIpTokenBalanceSender = _ipTokenDai.balanceOf(_liquidityProvider);
        assertEq(actualIpTokenBalanceSender, expectedIpTokenBalanceSender);
    }
}

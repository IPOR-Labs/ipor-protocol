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

contract JosephExchangeRateLiquidity is TestCommons, DataUtils, SwapUtils {
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
            TestConstants.PERCENTAGE_4_18DEC, TestConstants.ZERO, TestConstants.ZERO_INT, TestConstants.ZERO_INT
        );
    }

    function testShouldCalculateExchangeRateWhenLiquidityPoolBalanceAndIpTokenTotalSupplyIsZero() public {
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
        // when
        uint256 actualExchangeRate = mockCase0JosephDai.itfCalculateExchangeRate(block.timestamp);
        // then
        assertEq(actualExchangeRate, TestConstants.D18);
    }

    function testShouldCalculateExchangeRateWhenLiquidityPoolBalanceIsNotZeroAndIpTokenTotalSupplyIsNotZeroAnd18Decimals(
    ) public {
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
        vm.prank(_liquidityProvider);
        mockCase0JosephDai.itfProvideLiquidity(TestConstants.USD_14_000_18DEC, block.timestamp);
        // when
        uint256 actualExchangeRate = mockCase0JosephDai.itfCalculateExchangeRate(block.timestamp);
        // then
        assertEq(actualExchangeRate, TestConstants.D18);
    }

    function testShouldCalculateExchangeRateWhenLiquidityPoolBalanceIsNotZeroAndIpTokenTotalSupplyIsNotZeroAnd6Decimals(
    ) public {
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
        prepareApproveForUsersUsd(_users, _usdtMockedToken, address(mockCase0JosephUsdt), address(mockCase0MiltonUsdt));
        prepareMilton(mockCase0MiltonUsdt, address(mockCase0JosephUsdt), address(stanleyUsdt));
        prepareJoseph(mockCase0JosephUsdt);
        prepareIpToken(_ipTokenUsdt, address(mockCase0JosephUsdt));
        vm.prank(_liquidityProvider);
        mockCase0JosephUsdt.itfProvideLiquidity(TestConstants.USD_14_000_6DEC, block.timestamp);
        // when
        uint256 actualExchangeRate = mockCase0JosephUsdt.itfCalculateExchangeRate(block.timestamp);
        // then
        assertEq(actualExchangeRate, TestConstants.D18);
    }

    function testShouldCalculateExchangeRateWhenLiquidityPoolBalanceIsZeroAndIpTokenTotalSupplyIsNotZeroAnd18Decimals()
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
        vm.prank(_liquidityProvider);
        mockCase0JosephDai.itfProvideLiquidity(TestConstants.TC_TOTAL_AMOUNT_10_000_18DEC, block.timestamp);
        //simulation that Liquidity Pool Balance equal 0, but ipToken is not burned
        miltonStorageDai.setJoseph(_userOne);
        vm.prank(_userOne);
        miltonStorageDai.subtractLiquidity(TestConstants.TC_TOTAL_AMOUNT_10_000_18DEC);
        miltonStorageDai.setJoseph(address(mockCase0JosephDai));
        // when
        uint256 actualExchangeRate = mockCase0JosephDai.itfCalculateExchangeRate(block.timestamp);
        // then
        assertEq(actualExchangeRate, TestConstants.ZERO);
    }

    function testShouldCalculateExchangeRateWhenExchangeRateIsGreaterThan1And18Decimals() public {
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
        mockCase0JosephDai.itfProvideLiquidity(40 * TestConstants.D18, block.timestamp);
        // open position to have something in the pool
        vm.prank(_userTwo);
        mockCase0MiltonDai.itfOpenSwapPayFixed(
            block.timestamp, 40 * TestConstants.D18, 9 * TestConstants.D17, TestConstants.LEVERAGE_18DEC
        );
        // when
        uint256 actualExchangeRate = mockCase0JosephDai.itfCalculateExchangeRate(block.timestamp);
        // then
        assertEq(actualExchangeRate, 1000074977506747976);
    }

    function testShouldCalculateExchangeRateWhenLiquidityPoolBalanceIsNotZeroAndIpTokenTotalSupplyIsZeroAnd18Decimals()
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
        //BEGIN HACK - provide liquidity without mint ipToken
        miltonStorageDai.setJoseph(_admin);
        miltonStorageDai.addLiquidity(
            _liquidityProvider,
            TestConstants.USD_2_000_18DEC,
            TestConstants.USD_20_000_000_18DEC,
            TestConstants.USD_10_000_000_18DEC
        );
        _daiMockedToken.transfer(address(mockCase0MiltonDai), TestConstants.USD_2_000_18DEC);
        miltonStorageDai.setJoseph(address(mockCase0JosephDai));
        //END HACK - provide liquidity without mint ipToken
        IporTypes.MiltonBalancesMemory memory balance = mockCase0MiltonDai.getAccruedBalance();
        // when
        uint256 actualExchangeRate = mockCase0JosephDai.itfCalculateExchangeRate(block.timestamp);
        // then
        assertEq(_daiMockedToken.balanceOf(address(_ipTokenDai)), TestConstants.ZERO);
        assertGt(balance.liquidityPool, TestConstants.ZERO);
        assertEq(actualExchangeRate, TestConstants.D18);
    }

    function testShouldCalculateExchangeRateWhenExchangeRateIsGreaterThan1And6Decimals() public {
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
        prepareApproveForUsersUsd(_users, _usdtMockedToken, address(mockCase0JosephUsdt), address(mockCase0MiltonUsdt));
        prepareMilton(mockCase0MiltonUsdt, address(mockCase0JosephUsdt), address(stanleyUsdt));
        prepareJoseph(mockCase0JosephUsdt);
        prepareIpToken(_ipTokenUsdt, address(mockCase0JosephUsdt));
        vm.prank(_userOne);
        iporOracle.itfUpdateIndex(address(_usdtMockedToken), TestConstants.PERCENTAGE_3_18DEC, block.timestamp);
        vm.prank(_liquidityProvider);
        mockCase0JosephUsdt.itfProvideLiquidity(40 * TestConstants.N1__0_6DEC, block.timestamp);
        // open position to have something in the pool
        vm.prank(_userTwo);
        mockCase0MiltonUsdt.itfOpenSwapPayFixed(
            block.timestamp, 40 * TestConstants.N1__0_6DEC, 9 * TestConstants.D17, TestConstants.LEVERAGE_18DEC
        );
        // when
        uint256 actualExchangeRate = mockCase0JosephUsdt.itfCalculateExchangeRate(block.timestamp);
        // then
        assertEq(actualExchangeRate, 1000074977506747976);
    }
}

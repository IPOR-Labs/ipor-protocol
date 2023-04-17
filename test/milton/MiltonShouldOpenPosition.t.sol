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
import "../../contracts/mocks/milton/MockCase4MiltonDai.sol";
import "../../contracts/mocks/milton/MockCase5MiltonDai.sol";
import "../../contracts/mocks/milton/MockCase0MiltonUsdt.sol";
import "../../contracts/mocks/joseph/MockCase0JosephDai.sol";
import "../../contracts/mocks/joseph/MockCase0JosephUsdt.sol";
import "../../contracts/interfaces/IMarketSafetyOracle.sol";
import "../../contracts/interfaces/types/IporTypes.sol";
import "../../contracts/interfaces/types/MiltonStorageTypes.sol";

contract MiltonShouldOpenPositionTest is TestCommons, DataUtils, SwapUtils {
    MockSpreadModel internal _miltonSpreadModel;
    MockTestnetToken internal _usdtMockedToken;
    MockTestnetToken internal _usdcMockedToken;
    MockTestnetToken internal _daiMockedToken;
    IpToken internal _ipTokenUsdt;
    IpToken internal _ipTokenUsdc;
    IpToken internal _ipTokenDai;

    struct ActualBalances {
        uint256 actualIncomeFeeValue;
        uint256 actualSumOfBalances;
        uint256 actualMiltonBalance;
        int256 actualPayoff;
        int256 actualOpenerUserBalance;
        int256 actualCloserUserBalance;
    }

    function setUp() public {
        _miltonSpreadModel = prepareMockSpreadModel(
            TestConstants.PERCENTAGE_4_18DEC, TestConstants.ZERO, TestConstants.ZERO_INT, TestConstants.ZERO_INT
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

    function testShouldOpenPositionPayFixedDAIWhenOwnerSimpleCase18Decimals() public {
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
        uint256 miltonBalanceBeforePayoutWad = TestConstants.USD_28_000_18DEC;
        vm.prank(_userOne);
        iporOracle.itfUpdateIndex(address(_daiMockedToken), TestConstants.PERCENTAGE_3_18DEC, block.timestamp);
        vm.prank(_liquidityProvider);
        mockCase0JosephDai.itfProvideLiquidity(miltonBalanceBeforePayoutWad, block.timestamp);
        ExpectedMiltonBalances memory expectedBalances;
        expectedBalances.expectedMiltonBalance =
            miltonBalanceBeforePayoutWad + TestConstants.TC_TOTAL_AMOUNT_10_000_18DEC;
        expectedBalances.expectedOpenerUserBalance = 9990000 * TestConstants.D18_INT;
        expectedBalances.expectedLiquidityPoolBalance =
            miltonBalanceBeforePayoutWad + TestConstants.TC_OPENING_FEE_18DEC;
        expectedBalances.expectedSumOfBalancesBeforePayout =
            miltonBalanceBeforePayoutWad + TestConstants.USD_10_000_000_18DEC;
        uint256 expectedIporPublicationFee = TestConstants.TC_IPOR_PUBLICATION_AMOUNT_18DEC;
        uint256 expectedDerivativesTotalBalanceWad = TestConstants.TC_COLLATERAL_18DEC;
        // when
        vm.prank(_userTwo);
        mockCase0MiltonDai.itfOpenSwapPayFixed(
            block.timestamp,
            TestConstants.TC_TOTAL_AMOUNT_10_000_18DEC,
            TestConstants.PERCENTAGE_6_18DEC,
            TestConstants.LEVERAGE_18DEC
        );
        (, IporTypes.IporSwapMemory[] memory swaps) =
            miltonStorageDai.getSwapsPayFixed(_userTwo, TestConstants.ZERO, 50);
        uint256 actualOpenSwapsVolume;
        for (uint256 i = 0; i < swaps.length; i++) {
            if (swaps[i].state == 1) {
                actualOpenSwapsVolume++;
            }
        }
        MiltonStorageTypes.ExtendedBalancesMemory memory balance = miltonStorageDai.getExtendedBalance();
        uint256 actualSumOfBalances =
            _daiMockedToken.balanceOf(address(mockCase0MiltonDai)) + _daiMockedToken.balanceOf(_userTwo);
        uint256 actualDerivativesTotalBalanceWad = balance.totalCollateralPayFixed + balance.totalCollateralReceiveFixed;
        // then
        assertEq(actualOpenSwapsVolume, 1);
        assertEq(_daiMockedToken.balanceOf(address(mockCase0MiltonDai)), expectedBalances.expectedMiltonBalance);
        assertEq(int256(_daiMockedToken.balanceOf(_userTwo)), expectedBalances.expectedOpenerUserBalance);
        assertEq(actualDerivativesTotalBalanceWad, expectedDerivativesTotalBalanceWad);
        assertEq(balance.iporPublicationFee, expectedIporPublicationFee);
        assertEq(balance.liquidityPool, expectedBalances.expectedLiquidityPoolBalance);
        assertEq(balance.treasury, TestConstants.ZERO);
        assertEq(expectedBalances.expectedSumOfBalancesBeforePayout, actualSumOfBalances);
    }

    function testShouldOpenPositionPayFixedUSDTWhenOwnerSimpleCase6Decimals() public {
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
        MockCase1Stanley stanleyUsdt = getMockCase1Stanley(address(_usdtMockedToken));
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
        mockCase0JosephUsdt.itfProvideLiquidity(TestConstants.USD_28_000_6DEC, block.timestamp);
        ExpectedMiltonBalances memory expectedBalances;
        expectedBalances.expectedMiltonBalance =
            TestConstants.USD_28_000_6DEC + TestConstants.TC_TOTAL_AMOUNT_10_000_6DEC;
        expectedBalances.expectedOpenerUserBalance = 9990000000000;
        expectedBalances.expectedLiquidityPoolBalance =
            TestConstants.USD_28_000_18DEC + TestConstants.TC_OPENING_FEE_18DEC;
        expectedBalances.expectedSumOfBalancesBeforePayout =
            TestConstants.USD_28_000_6DEC + TestConstants.USD_10_000_000_6DEC;
        uint256 expectedDerivativesTotalBalanceWad = TestConstants.TC_COLLATERAL_18DEC;
        uint256 expectedIporPublicationFee = TestConstants.TC_IPOR_PUBLICATION_AMOUNT_18DEC;
        // when
        vm.prank(_userTwo);
        mockCase0MiltonUsdt.itfOpenSwapPayFixed(
            block.timestamp,
            TestConstants.TC_TOTAL_AMOUNT_10_000_6DEC,
            TestConstants.PERCENTAGE_6_18DEC,
            TestConstants.LEVERAGE_18DEC
        );
        (, IporTypes.IporSwapMemory[] memory swaps) =
            miltonStorageUsdt.getSwapsPayFixed(_userTwo, TestConstants.ZERO, 50);
        uint256 actualOpenSwapsVolume;
        for (uint256 i = 0; i < swaps.length; i++) {
            if (swaps[i].state == 1) {
                actualOpenSwapsVolume++;
            }
        }
        MiltonStorageTypes.ExtendedBalancesMemory memory balance = miltonStorageUsdt.getExtendedBalance();
        uint256 actualSumOfBalances =
            _usdtMockedToken.balanceOf(address(mockCase0MiltonUsdt)) + _usdtMockedToken.balanceOf(_userTwo);
        uint256 actualDerivativesTotalBalanceWad = balance.totalCollateralPayFixed + balance.totalCollateralReceiveFixed;
        // then
        assertEq(actualOpenSwapsVolume, 1);
        assertEq(_usdtMockedToken.balanceOf(address(mockCase0MiltonUsdt)), expectedBalances.expectedMiltonBalance);
        assertEq(int256(_usdtMockedToken.balanceOf(_userTwo)), expectedBalances.expectedOpenerUserBalance);
        assertEq(actualDerivativesTotalBalanceWad, expectedDerivativesTotalBalanceWad);
        assertEq(balance.iporPublicationFee, expectedIporPublicationFee);
        assertEq(balance.liquidityPool, expectedBalances.expectedLiquidityPoolBalance);
        assertEq(balance.treasury, TestConstants.ZERO);
        assertEq(expectedBalances.expectedSumOfBalancesBeforePayout, actualSumOfBalances);
    }

    function testShouldOpenPositionPayFixedDAIWhenCustomOpeningFeeForTreasuryIs50Percent() public {
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
        MockCase1Stanley stanleyDai = getMockCase1Stanley(address(_daiMockedToken));
        MiltonStorage miltonStorageDai = getMiltonStorage();
        MockCase4MiltonDai mockCase4MiltonDai = getMockCase4MiltonDai(
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
            address(mockCase4MiltonDai),
            address(miltonStorageDai),
            address(stanleyDai)
        );
        prepareApproveForUsersDai(_users, _daiMockedToken, address(mockCase0JosephDai), address(mockCase4MiltonDai));
        prepareMilton(mockCase4MiltonDai, address(mockCase0JosephDai), address(stanleyDai));
        prepareJoseph(mockCase0JosephDai);
        prepareIpToken(_ipTokenDai, address(mockCase0JosephDai));
        vm.prank(_userOne);
        iporOracle.itfUpdateIndex(address(_daiMockedToken), TestConstants.PERCENTAGE_3_18DEC, block.timestamp);
        vm.prank(_liquidityProvider);
        mockCase0JosephDai.itfProvideLiquidity(TestConstants.USD_28_000_18DEC, block.timestamp);
        ExpectedMiltonBalances memory expectedBalances;
        expectedBalances.expectedLiquidityPoolBalance = 28002840597820653803859;
        uint256 expectedTreasuryBalance = 149505148455463361;
        // when
        vm.prank(_userTwo);
        mockCase4MiltonDai.itfOpenSwapPayFixed(
            block.timestamp,
            TestConstants.TC_TOTAL_AMOUNT_10_000_18DEC,
            TestConstants.PERCENTAGE_6_18DEC,
            TestConstants.LEVERAGE_18DEC
        );
        MiltonStorageTypes.ExtendedBalancesMemory memory balance = miltonStorageDai.getExtendedBalance();
        // then
        assertEq(balance.liquidityPool, expectedBalances.expectedLiquidityPoolBalance);
        assertEq(balance.treasury, expectedTreasuryBalance);
    }

    function testShouldOpenPositionPayFixedDAIWhenCustomOpeningFeeForTreasuryIs25Percent() public {
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
        MockCase1Stanley stanleyDai = getMockCase1Stanley(address(_daiMockedToken));
        MiltonStorage miltonStorageDai = getMiltonStorage();
        MockCase5MiltonDai mockCase5MiltonDai = getMockCase5MiltonDai(
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
            address(mockCase5MiltonDai),
            address(miltonStorageDai),
            address(stanleyDai)
        );
        prepareApproveForUsersDai(_users, _daiMockedToken, address(mockCase0JosephDai), address(mockCase5MiltonDai));
        prepareMilton(mockCase5MiltonDai, address(mockCase0JosephDai), address(stanleyDai));
        prepareJoseph(mockCase0JosephDai);
        prepareIpToken(_ipTokenDai, address(mockCase0JosephDai));
        vm.prank(_userOne);
        iporOracle.itfUpdateIndex(address(_daiMockedToken), TestConstants.PERCENTAGE_3_18DEC, block.timestamp);
        vm.prank(_liquidityProvider);
        mockCase0JosephDai.itfProvideLiquidity(TestConstants.USD_28_000_18DEC, block.timestamp);
        ExpectedMiltonBalances memory expectedBalances;
        expectedBalances.expectedLiquidityPoolBalance = 28002915350394881535539;
        uint256 expectedTreasuryBalance = 74752574227731681;
        // when
        vm.prank(_userTwo);
        mockCase5MiltonDai.itfOpenSwapPayFixed(
            block.timestamp,
            TestConstants.TC_TOTAL_AMOUNT_10_000_18DEC,
            TestConstants.PERCENTAGE_6_18DEC,
            TestConstants.LEVERAGE_18DEC
        );
        MiltonStorageTypes.ExtendedBalancesMemory memory balance = miltonStorageDai.getExtendedBalance();
        // then
        assertEq(balance.liquidityPool, expectedBalances.expectedLiquidityPoolBalance);
        assertEq(balance.treasury, expectedTreasuryBalance);
    }

    function testShouldOpenPayFixedDAIWhenCustomLeverageSimpleCase1() public {
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
        mockCase0JosephDai.itfProvideLiquidity(TestConstants.USD_28_000_18DEC, block.timestamp);
        uint256 expectedCollateralBalance = TestConstants.TC_COLLATERAL_18DEC;
        uint256 expectedNotionalBalance = 150751024692592222333298;
        // when
        vm.prank(_userTwo);
        mockCase0MiltonDai.itfOpenSwapPayFixed(
            block.timestamp, TestConstants.TC_TOTAL_AMOUNT_10_000_18DEC, 9 * TestConstants.D17, 15125000000000000000
        );
        IporTypes.IporSwapMemory memory swapPayFixed = miltonStorageDai.getSwapPayFixed(1);
        // then
        assertEq(swapPayFixed.collateral, expectedCollateralBalance);
        assertEq(swapPayFixed.notional, expectedNotionalBalance);
    }

    function testShouldOpenPayFixedPositionWhenOpenTimestampIsLongTimeAgo() public {
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
        uint256 longAgoTimestamp = 31536000; //1971-01-01
        prepareApproveForUsersDai(_users, _daiMockedToken, address(mockCase0JosephDai), address(mockCase0MiltonDai));
        prepareMilton(mockCase0MiltonDai, address(mockCase0JosephDai), address(stanleyDai));
        prepareJoseph(mockCase0JosephDai);
        prepareIpToken(_ipTokenDai, address(mockCase0JosephDai));
        vm.prank(_liquidityProvider);
        mockCase0JosephDai.itfProvideLiquidity(TestConstants.USD_28_000_18DEC, longAgoTimestamp);
        openSwapPayFixed(
            _userTwo,
            longAgoTimestamp,
            TestConstants.TC_TOTAL_AMOUNT_10_000_18DEC,
            TestConstants.PERCENTAGE_4_18DEC,
            TestConstants.LEVERAGE_18DEC,
            mockCase0MiltonDai
        );
        vm.prank(_userOne);
        iporOracle.itfUpdateIndex(address(_daiMockedToken), TestConstants.PERCENTAGE_3_18DEC, longAgoTimestamp);
        ExpectedMiltonBalances memory expectedBalances;
        expectedBalances.expectedPayoffAbs = TestConstants.ZERO;
        expectedBalances.expectedIncomeFeeValue = TestConstants.ZERO;
        int256 openerUserLost = TestConstants.TC_OPENING_FEE_18DEC_INT
            + TestConstants.TC_IPOR_PUBLICATION_AMOUNT_18DEC_INT + TestConstants.TC_LIQUIDATION_DEPOSIT_AMOUNT_18DEC_INT
            + int256(expectedBalances.expectedPayoffAbs);
        expectedBalances.expectedMiltonBalance = TestConstants.TC_LP_BALANCE_BEFORE_CLOSE_18DEC
            + TestConstants.TC_OPENING_FEE_18DEC + TestConstants.LEVERAGE_18DEC + expectedBalances.expectedPayoffAbs;
        expectedBalances.expectedOpenerUserBalance = TestConstants.USD_10_000_000_18DEC_INT
            + TestConstants.TC_LIQUIDATION_DEPOSIT_AMOUNT_18DEC_INT - openerUserLost;
        expectedBalances.expectedLiquidityPoolBalance = TestConstants.TC_LP_BALANCE_BEFORE_CLOSE_18DEC
            + TestConstants.TC_OPENING_FEE_18DEC + expectedBalances.expectedPayoffAbs
            - expectedBalances.expectedIncomeFeeValue;
        expectedBalances.expectedSumOfBalancesBeforePayout =
            TestConstants.TC_LP_BALANCE_BEFORE_CLOSE_18DEC + TestConstants.USD_10_000_000_18DEC;
        uint256 endTimestamp = longAgoTimestamp;
        // when
        vm.prank(_userTwo);
        mockCase0MiltonDai.itfCloseSwapPayFixed(1, endTimestamp);
        // then
        ActualBalances memory actualBalances;
        actualBalances.actualPayoff = mockCase0MiltonDai.itfCalculateSwapPayFixedValue(endTimestamp, 1);
        actualBalances.actualIncomeFeeValue = mockCase0MiltonDai.itfCalculateIncomeFeeValue(actualBalances.actualPayoff);
        actualBalances.actualSumOfBalances =
            _daiMockedToken.balanceOf(address(mockCase0MiltonDai)) + _daiMockedToken.balanceOf(_userTwo);
        actualBalances.actualMiltonBalance = _daiMockedToken.balanceOf(address(mockCase0MiltonDai));
        actualBalances.actualOpenerUserBalance = int256(_daiMockedToken.balanceOf(_userTwo));
        MiltonStorageTypes.ExtendedBalancesMemory memory balance = miltonStorageDai.getExtendedBalance();
        (, IporTypes.IporSwapMemory[] memory swaps) =
            miltonStorageDai.getSwapsPayFixed(_userTwo, TestConstants.ZERO, 50);
        (,, int256 soap) = calculateSoap(_userTwo, endTimestamp, mockCase0MiltonDai);
        assertEq(TestConstants.ZERO, swaps.length);
        assertEq(actualBalances.actualPayoff, -int256(expectedBalances.expectedPayoffAbs));
        assertEq(actualBalances.actualIncomeFeeValue, expectedBalances.expectedIncomeFeeValue);
        assertEq(actualBalances.actualSumOfBalances, expectedBalances.expectedSumOfBalancesBeforePayout);
        assertEq(actualBalances.actualMiltonBalance, expectedBalances.expectedMiltonBalance);
        assertEq(actualBalances.actualOpenerUserBalance, expectedBalances.expectedOpenerUserBalance);
        assertEq(balance.totalCollateralPayFixed, TestConstants.ZERO);
        assertEq(balance.iporPublicationFee, TestConstants.TC_IPOR_PUBLICATION_AMOUNT_18DEC);
        assertEq(balance.liquidityPool, expectedBalances.expectedLiquidityPoolBalance);
        assertEq(balance.treasury, expectedBalances.expectedIncomeFeeValue);
        assertEq(soap, TestConstants.ZERO_INT);
    }

    function testShouldArraysHaveCorrectStateWhenOneUserOpensManyPositions() public {
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
        mockCase0JosephDai.itfProvideLiquidity(3 * TestConstants.USD_28_000_18DEC, block.timestamp);
        // when
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
        openSwapPayFixed(
            _userTwo,
            block.timestamp + TestConstants.PERIOD_50_DAYS_IN_SECONDS,
            TestConstants.TC_TOTAL_AMOUNT_10_000_18DEC,
            9 * TestConstants.D17,
            TestConstants.LEVERAGE_18DEC,
            mockCase0MiltonDai
        );
        // then
        (, IporTypes.IporSwapMemory[] memory swaps) =
            miltonStorageDai.getSwapsPayFixed(_userTwo, TestConstants.ZERO, 10);
        (uint256 swapsCount, uint256[] memory swapIds) =
            miltonStorageDai.getSwapPayFixedIds(_userTwo, TestConstants.ZERO, 10);
        assertEq(swaps.length, 3);
        assertEq(swapIds.length, 3);
        assertEq(swapsCount, 3);
        assertEq(swaps[0].idsIndex, 0);
        assertEq(swaps[1].idsIndex, 1);
        assertEq(swaps[2].idsIndex, 2);
    }

    function testShouldArraysHaveCorrectStateWhenTwoUsersOpenPositions() public {
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
        mockCase0JosephDai.itfProvideLiquidity(3 * TestConstants.USD_28_000_18DEC, block.timestamp);
        // when
        openSwapPayFixed(
            _userTwo,
            block.timestamp,
            TestConstants.TC_TOTAL_AMOUNT_10_000_18DEC,
            9 * TestConstants.D17,
            TestConstants.LEVERAGE_18DEC,
            mockCase0MiltonDai
        );
        openSwapPayFixed(
            _userThree,
            block.timestamp + TestConstants.PERIOD_25_DAYS_IN_SECONDS,
            TestConstants.TC_TOTAL_AMOUNT_10_000_18DEC,
            9 * TestConstants.D17,
            TestConstants.LEVERAGE_18DEC,
            mockCase0MiltonDai
        );
        openSwapPayFixed(
            _userTwo,
            block.timestamp + TestConstants.PERIOD_50_DAYS_IN_SECONDS,
            TestConstants.TC_TOTAL_AMOUNT_10_000_18DEC,
            9 * TestConstants.D17,
            TestConstants.LEVERAGE_18DEC,
            mockCase0MiltonDai
        );
        // then
        (, IporTypes.IporSwapMemory[] memory swapsUserOne) =
            miltonStorageDai.getSwapsPayFixed(_userTwo, TestConstants.ZERO, 10);
        (uint256 swapsUserOneCount, uint256[] memory swapsUserOneIds) =
            miltonStorageDai.getSwapPayFixedIds(_userTwo, TestConstants.ZERO, 10);
        assertEq(swapsUserOne.length, 2);
        assertEq(swapsUserOneIds.length, 2);
        assertEq(swapsUserOneCount, 2);
        assertEq(swapsUserOne[0].idsIndex, 0);
        assertEq(swapsUserOne[0].id, 1);
        assertEq(swapsUserOne[1].idsIndex, 1);
        assertEq(swapsUserOne[1].id, 3);
        (, IporTypes.IporSwapMemory[] memory swapsUserTwo) =
            miltonStorageDai.getSwapsPayFixed(_userThree, TestConstants.ZERO, 10);
        (uint256 swapsUserTwoCount, uint256[] memory swapsUserTwoIds) =
            miltonStorageDai.getSwapPayFixedIds(_userThree, TestConstants.ZERO, 10);
        assertEq(swapsUserTwo.length, 1);
        assertEq(swapsUserTwoIds.length, 1);
        assertEq(swapsUserTwoCount, 1);
        assertEq(swapsUserTwo[0].idsIndex, 0);
        assertEq(swapsUserTwo[0].id, 2);
    }

    function testShouldPositionArraysHaveCorrectIdsWhenTwoUsersOpenPositionsAndOnePositionIsClosed() public {
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
        mockCase0JosephDai.itfProvideLiquidity(3 * TestConstants.USD_28_000_18DEC, block.timestamp);
        openSwapPayFixed(
            _userTwo,
            block.timestamp,
            TestConstants.TC_TOTAL_AMOUNT_10_000_18DEC,
            9 * TestConstants.D17,
            TestConstants.LEVERAGE_18DEC,
            mockCase0MiltonDai
        );
        openSwapPayFixed(
            _userThree,
            block.timestamp + TestConstants.PERIOD_25_DAYS_IN_SECONDS,
            TestConstants.TC_TOTAL_AMOUNT_10_000_18DEC,
            9 * TestConstants.D17,
            TestConstants.LEVERAGE_18DEC,
            mockCase0MiltonDai
        );
        openSwapPayFixed(
            _userTwo,
            block.timestamp + TestConstants.PERIOD_50_DAYS_IN_SECONDS,
            TestConstants.TC_TOTAL_AMOUNT_10_000_18DEC,
            9 * TestConstants.D17,
            TestConstants.LEVERAGE_18DEC,
            mockCase0MiltonDai
        );
        // when
        vm.prank(_userThree);
        mockCase0MiltonDai.itfCloseSwapPayFixed(2, block.timestamp + TestConstants.PERIOD_75_DAYS_IN_SECONDS);
        // then
        (, IporTypes.IporSwapMemory[] memory swapsUserOne) =
            miltonStorageDai.getSwapsPayFixed(_userTwo, TestConstants.ZERO, 10);
        (uint256 swapsUserOneCount, uint256[] memory swapsUserOneIds) =
            miltonStorageDai.getSwapPayFixedIds(_userTwo, TestConstants.ZERO, 10);
        assertEq(swapsUserOne.length, 2);
        assertEq(swapsUserOneIds.length, 2);
        assertEq(swapsUserOneCount, 2);
        assertEq(swapsUserOne[0].idsIndex, 0);
        assertEq(swapsUserOne[0].id, 1);
        assertEq(swapsUserOne[1].idsIndex, 1);
        assertEq(swapsUserOne[1].id, 3);
        (, IporTypes.IporSwapMemory[] memory swapsUserTwo) =
            miltonStorageDai.getSwapsPayFixed(_userThree, TestConstants.ZERO, 10);
        (uint256 swapsUserTwoCount, uint256[] memory swapsUserTwoIds) =
            miltonStorageDai.getSwapPayFixedIds(_userThree, TestConstants.ZERO, 10);
        assertEq(swapsUserTwo.length, 0);
        assertEq(swapsUserTwoIds.length, 0);
        assertEq(swapsUserTwoCount, 0);
    }

    function testShouldPositionArraysHaveCorrectIdsWhenTwoUsersOpenPositionsAndAllExceptOnePositionAreClosed() public {
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
        mockCase0JosephDai.itfProvideLiquidity(3 * TestConstants.USD_28_000_18DEC, block.timestamp);
        openSwapPayFixed(
            _userTwo,
            block.timestamp,
            TestConstants.TC_TOTAL_AMOUNT_10_000_18DEC,
            9 * TestConstants.D17,
            TestConstants.LEVERAGE_18DEC,
            mockCase0MiltonDai
        );
        openSwapPayFixed(
            _userThree,
            block.timestamp + TestConstants.PERIOD_25_DAYS_IN_SECONDS,
            TestConstants.TC_TOTAL_AMOUNT_10_000_18DEC,
            9 * TestConstants.D17,
            TestConstants.LEVERAGE_18DEC,
            mockCase0MiltonDai
        );
        openSwapPayFixed(
            _userTwo,
            block.timestamp + TestConstants.PERIOD_50_DAYS_IN_SECONDS,
            TestConstants.TC_TOTAL_AMOUNT_10_000_18DEC,
            9 * TestConstants.D17,
            TestConstants.LEVERAGE_18DEC,
            mockCase0MiltonDai
        );
        // when
        vm.prank(_userThree);
        mockCase0MiltonDai.itfCloseSwapPayFixed(2, block.timestamp + TestConstants.PERIOD_75_DAYS_IN_SECONDS);
        vm.prank(_userTwo);
        mockCase0MiltonDai.itfCloseSwapPayFixed(3, block.timestamp + TestConstants.PERIOD_75_DAYS_IN_SECONDS);
        // then
        (, IporTypes.IporSwapMemory[] memory swapsUserOne) =
            miltonStorageDai.getSwapsPayFixed(_userTwo, TestConstants.ZERO, 10);
        (uint256 swapsUserOneCount, uint256[] memory swapsUserOneIds) =
            miltonStorageDai.getSwapPayFixedIds(_userTwo, TestConstants.ZERO, 10);
        assertEq(swapsUserOne.length, 1);
        assertEq(swapsUserOneIds.length, 1);
        assertEq(swapsUserOneCount, 1);
        assertEq(swapsUserOne[0].idsIndex, 0);
        assertEq(swapsUserOne[0].id, 1);
        (, IporTypes.IporSwapMemory[] memory swapsUserTwo) =
            miltonStorageDai.getSwapsPayFixed(_userThree, TestConstants.ZERO, 10);
        (uint256 swapsUserTwoCount, uint256[] memory swapsUserTwoIds) =
            miltonStorageDai.getSwapPayFixedIds(_userThree, TestConstants.ZERO, 10);
        assertEq(swapsUserTwo.length, 0);
        assertEq(swapsUserTwoIds.length, 0);
        assertEq(swapsUserTwoCount, 0);
    }

    function testShouldFixLastByteDifferenceWhenTwoPositionsAreOpenedAndClosedAndArithmeticOverflowCase1() public {
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
        mockCase0JosephDai.itfProvideLiquidity(2 * TestConstants.USD_28_000_18DEC, block.timestamp);
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
        // when
        vm.startPrank(_userThree);
        mockCase0MiltonDai.itfCloseSwapPayFixed(1, block.timestamp + TestConstants.PERIOD_50_DAYS_IN_SECONDS);
        mockCase0MiltonDai.itfCloseSwapPayFixed(2, block.timestamp + TestConstants.PERIOD_75_DAYS_IN_SECONDS);
        vm.stopPrank();
        // then
        (, IporTypes.IporSwapMemory[] memory swapsUserOne) =
            miltonStorageDai.getSwapsPayFixed(_userTwo, TestConstants.ZERO, 10);
        (uint256 swapsUserOneCount, uint256[] memory swapsUserOneIds) =
            miltonStorageDai.getSwapPayFixedIds(_userTwo, TestConstants.ZERO, 10);
        assertEq(swapsUserOne.length, 0);
        assertEq(swapsUserOneIds.length, 0);
        assertEq(swapsUserOneCount, 0);
        (, IporTypes.IporSwapMemory[] memory swapsUserTwo) =
            miltonStorageDai.getSwapsPayFixed(_userThree, TestConstants.ZERO, 10);
        (uint256 swapsUserTwoCount, uint256[] memory swapsUserTwoIds) =
            miltonStorageDai.getSwapPayFixedIds(_userThree, TestConstants.ZERO, 10);
        assertEq(swapsUserTwo.length, 0);
        assertEq(swapsUserTwoIds.length, 0);
        assertEq(swapsUserTwoCount, 0);
    }

    function testShouldFixLastByteDifferenceWhenTwoPositionsAreOpenedAndClosedAndArithmeticOverflowCase1Minus3()
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
        mockCase0JosephDai.itfProvideLiquidity(2 * TestConstants.USD_28_000_18DEC, block.timestamp);
        openSwapPayFixed(
            _userTwo,
            block.timestamp,
            TestConstants.TC_TOTAL_AMOUNT_10_000_18DEC,
            9 * TestConstants.D17,
            TestConstants.LEVERAGE_18DEC,
            mockCase0MiltonDai
        );
        uint256 threeDaysInSeconds = 259200;
        openSwapPayFixed(
            _userTwo,
            block.timestamp + TestConstants.PERIOD_25_DAYS_IN_SECONDS - threeDaysInSeconds,
            TestConstants.TC_TOTAL_AMOUNT_10_000_18DEC,
            9 * TestConstants.D17,
            TestConstants.LEVERAGE_18DEC,
            mockCase0MiltonDai
        );
        // when
        vm.startPrank(_userThree);
        mockCase0MiltonDai.itfCloseSwapPayFixed(1, block.timestamp + TestConstants.PERIOD_50_DAYS_IN_SECONDS);
        mockCase0MiltonDai.itfCloseSwapPayFixed(2, block.timestamp + TestConstants.PERIOD_75_DAYS_IN_SECONDS);
        vm.stopPrank();
        // then
        (, IporTypes.IporSwapMemory[] memory swapsUserOne) =
            miltonStorageDai.getSwapsPayFixed(_userTwo, TestConstants.ZERO, 10);
        (uint256 swapsUserOneCount, uint256[] memory swapsUserOneIds) =
            miltonStorageDai.getSwapPayFixedIds(_userTwo, TestConstants.ZERO, 10);
        assertEq(swapsUserOne.length, 0);
        assertEq(swapsUserOneIds.length, 0);
        assertEq(swapsUserOneCount, 0);
        (, IporTypes.IporSwapMemory[] memory swapsUserTwo) =
            miltonStorageDai.getSwapsPayFixed(_userThree, TestConstants.ZERO, 10);
        (uint256 swapsUserTwoCount, uint256[] memory swapsUserTwoIds) =
            miltonStorageDai.getSwapPayFixedIds(_userThree, TestConstants.ZERO, 10);
        assertEq(swapsUserTwo.length, 0);
        assertEq(swapsUserTwoIds.length, 0);
        assertEq(swapsUserTwoCount, 0);
    }

    function testShouldHaveLastByteDifferenceWhenTwoPositionsAreOpenedAndClosedAndArithmeticOverflowCase1() public {
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
        mockCase0JosephDai.itfProvideLiquidity(2 * TestConstants.USD_28_000_18DEC, block.timestamp);
        openSwapPayFixed(
            _userThree,
            block.timestamp,
            TestConstants.TC_TOTAL_AMOUNT_10_000_18DEC,
            9 * TestConstants.D17,
            TestConstants.LEVERAGE_18DEC,
            mockCase0MiltonDai
        );
        openSwapPayFixed(
            _userThree,
            block.timestamp + TestConstants.PERIOD_25_DAYS_IN_SECONDS,
            TestConstants.TC_TOTAL_AMOUNT_10_000_18DEC,
            9 * TestConstants.D17,
            TestConstants.LEVERAGE_18DEC,
            mockCase0MiltonDai
        );
        // when
        vm.startPrank(_userThree);
        mockCase0MiltonDai.itfCloseSwapPayFixed(1, block.timestamp + TestConstants.PERIOD_50_DAYS_IN_SECONDS);
        mockCase0MiltonDai.itfCloseSwapPayFixed(2, block.timestamp + TestConstants.PERIOD_75_DAYS_IN_SECONDS);
        vm.stopPrank();
        // then
        (, IporTypes.IporSwapMemory[] memory swapsUserOne) =
            miltonStorageDai.getSwapsPayFixed(_userTwo, TestConstants.ZERO, 10);
        (uint256 swapsUserOneCount, uint256[] memory swapsUserOneIds) =
            miltonStorageDai.getSwapPayFixedIds(_userTwo, TestConstants.ZERO, 10);
        assertEq(swapsUserOne.length, 0);
        assertEq(swapsUserOneIds.length, 0);
        assertEq(swapsUserOneCount, 0);
        (, IporTypes.IporSwapMemory[] memory swapsUserTwo) =
            miltonStorageDai.getSwapsPayFixed(_userThree, TestConstants.ZERO, 10);
        (uint256 swapsUserTwoCount, uint256[] memory swapsUserTwoIds) =
            miltonStorageDai.getSwapPayFixedIds(_userThree, TestConstants.ZERO, 10);
        assertEq(swapsUserTwo.length, 0);
        assertEq(swapsUserTwoIds.length, 0);
        assertEq(swapsUserTwoCount, 0);
    }
}

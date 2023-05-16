// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.16;

import "./TestCommons.sol";
import {DataUtils} from "./utils/DataUtils.sol";
import {TestConstants} from "./utils/TestConstants.sol";
import {IpToken} from "contracts/tokens/IpToken.sol";
import {MiltonStorage} from "contracts/amm/MiltonStorage.sol";
import {ItfIporOracle} from "contracts/itf/ItfIporOracle.sol";
import {MockSpreadModel} from "contracts/mocks/spread/MockSpreadModel.sol";
import {MockCaseBaseStanley} from "contracts/mocks/stanley/MockCaseBaseStanley.sol";
import {MockCase2Stanley} from "contracts/mocks/stanley/MockCase2Stanley.sol";
import {IIporRiskManagementOracle} from "contracts/interfaces/IIporRiskManagementOracle.sol";
import {IporTypes} from "contracts/interfaces/types/IporTypes.sol";

contract StanleyTest is TestCommons, DataUtils {
    MockSpreadModel internal _miltonSpreadModel;
    MockTestnetToken internal _usdtMockedToken;
    MockTestnetToken internal _usdcMockedToken;
    MockTestnetToken internal _daiMockedToken;
    IpToken internal _ipTokenUsdt;
    IpToken internal _ipTokenUsdc;
    IpToken internal _ipTokenDai;

    struct ExpectedBalances {
        uint256 expectedMiltonStableBalance;
        uint256 expectedMiltonLiquidityPoolBalance;
        uint256 expectedIporVaultStableBalance;
    }

    struct ActualBalances {
        uint256 actualMiltonStableBalance;
        uint256 actualMiltonBalance;
        uint256 actualIporVaultStableBalance;
        uint256 actualMiltonAccruedBalance;
    }

    function setUp() public {
        _miltonSpreadModel = prepareMockSpreadModel(
            TestConstants.ZERO,
            TestConstants.ZERO,
            TestConstants.ZERO_INT,
            TestConstants.ZERO_INT
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

    function testShouldRebalanceWhenAMVaultRatioIsGreaterThanOptimalAndDepositToVault() public {
        //given
        ItfIporOracle iporOracle = getIporOracleAsset(
            _userOne,
            address(_daiMockedToken),
            TestConstants.TC_DEFAULT_EMA_18DEC_64UINT
        );
        IIporRiskManagementOracle iporRiskManagementOracle = getRiskManagementOracleAsset(
            _userOne,
            address(_daiMockedToken),
            TestConstants.RMO_UTILIZATION_RATE_48_PER,
            TestConstants.RMO_UTILIZATION_RATE_90_PER,
            TestConstants.RMO_NOTIONAL_1B,
            TestConstants.RMO_SPREAD_0_1_PER
        );
        MockCaseBaseStanley stanleyDai = getMockCase1Stanley(address(_daiMockedToken));
        MiltonStorage miltonStorageDai = getMiltonStorage();
        MockMilton mockCase0MiltonDai = getMockCase0MiltonDai(
            address(_daiMockedToken),
            address(iporOracle),
            address(miltonStorageDai),
            address(_miltonSpreadModel),
            address(stanleyDai),
            address(iporRiskManagementOracle)
        );
        ItfJoseph mockCase0JosephDai = getMockCase0JosephDai(
            address(_daiMockedToken),
            address(_ipTokenDai),
            address(mockCase0MiltonDai),
            address(miltonStorageDai),
            address(stanleyDai)
        );
        ActualBalances memory actualBalances;
        ExpectedBalances memory expectedBalances;
        expectedBalances.expectedMiltonStableBalance = 17002550000000000000000;
        expectedBalances.expectedMiltonLiquidityPoolBalance = 20003000000000000000000;
        expectedBalances.expectedIporVaultStableBalance = 3000450000000000000000;
        prepareApproveForUsersDai(_users, _daiMockedToken, address(mockCase0JosephDai), address(mockCase0MiltonDai));
        prepareMilton(mockCase0MiltonDai, address(mockCase0JosephDai), address(stanleyDai));
        prepareJoseph(mockCase0JosephDai);
        prepareIpToken(_ipTokenDai, address(mockCase0JosephDai));
        mockCase0JosephDai.addAppointedToRebalance(_admin);
        vm.startPrank(_liquidityProvider);
        _daiMockedToken.approve(address(stanleyDai), TestConstants.TOTAL_SUPPLY_18_DECIMALS);
        mockCase0JosephDai.itfProvideLiquidity(TestConstants.USD_20_000_18DEC, block.timestamp);
        vm.stopPrank();
        vm.prank(_admin);
        mockCase0JosephDai.depositToStanley(TestConstants.USD_1_000_18DEC);
        //Force deposit to simulate that IporVault earn money for Milton $3
        vm.prank(_liquidityProvider);
        stanleyDai.forTestDeposit(address(mockCase0MiltonDai), TestConstants.USD_3_18DEC);
        // when
        vm.prank(_admin);
        mockCase0JosephDai.rebalance();
        // then
        actualBalances.actualMiltonStableBalance = _daiMockedToken.balanceOf(address(mockCase0MiltonDai));
        actualBalances.actualIporVaultStableBalance = stanleyDai.totalBalance(address(mockCase0MiltonDai));
        actualBalances.actualMiltonBalance = miltonStorageDai.getBalance().liquidityPool;
        actualBalances.actualMiltonAccruedBalance = mockCase0MiltonDai.getAccruedBalance().liquidityPool;
        assertEq(actualBalances.actualMiltonStableBalance, expectedBalances.expectedMiltonStableBalance);
        assertEq(actualBalances.actualIporVaultStableBalance, expectedBalances.expectedIporVaultStableBalance);
        assertEq(actualBalances.actualMiltonBalance, expectedBalances.expectedMiltonLiquidityPoolBalance);
        //Notice! In this specific case IporVault mock returns totalBalance without any interest so balance = accrued balance
        assertEq(actualBalances.actualMiltonAccruedBalance, expectedBalances.expectedMiltonLiquidityPoolBalance);
    }

    function testShouldRebalanceWhenAMVaultRatioIsLessThanOptimalAndWithdrawFromVaultPartAmountCase1() public {
        // given
        ItfIporOracle iporOracle = getIporOracleAsset(
            _userOne,
            address(_daiMockedToken),
            TestConstants.TC_DEFAULT_EMA_18DEC_64UINT
        );
        IIporRiskManagementOracle iporRiskManagementOracle = getRiskManagementOracleAsset(
            _userOne,
            address(_daiMockedToken),
            TestConstants.RMO_UTILIZATION_RATE_48_PER,
            TestConstants.RMO_UTILIZATION_RATE_90_PER,
            TestConstants.RMO_NOTIONAL_1B,
            TestConstants.RMO_SPREAD_0_1_PER
        );
        MockCaseBaseStanley stanleyDai = getMockCase1Stanley(address(_daiMockedToken));
        MiltonStorage miltonStorageDai = getMiltonStorage();
        MockMilton mockCase0MiltonDai = getMockCase0MiltonDai(
            address(_daiMockedToken),
            address(iporOracle),
            address(miltonStorageDai),
            address(_miltonSpreadModel),
            address(stanleyDai),
            address(iporRiskManagementOracle)
        );
        ItfJoseph mockCase0JosephDai = getMockCase0JosephDai(
            address(_daiMockedToken),
            address(_ipTokenDai),
            address(mockCase0MiltonDai),
            address(miltonStorageDai),
            address(stanleyDai)
        );
        ActualBalances memory actualBalances;
        ExpectedBalances memory expectedBalances;
        expectedBalances.expectedMiltonStableBalance = 17850000000000000000000;
        expectedBalances.expectedMiltonLiquidityPoolBalance = 1003000000000000000000;
        expectedBalances.expectedIporVaultStableBalance = 3150000000000000000000;
        prepareApproveForUsersDai(_users, _daiMockedToken, address(mockCase0JosephDai), address(mockCase0MiltonDai));
        prepareMilton(mockCase0MiltonDai, address(mockCase0JosephDai), address(stanleyDai));
        prepareJoseph(mockCase0JosephDai);
        prepareIpToken(_ipTokenDai, address(mockCase0JosephDai));
        mockCase0JosephDai.addAppointedToRebalance(_admin);
        vm.startPrank(_liquidityProvider);
        _daiMockedToken.approve(address(stanleyDai), TestConstants.TOTAL_SUPPLY_18_DECIMALS);
        mockCase0JosephDai.itfProvideLiquidity(TestConstants.USD_1_000_18DEC, block.timestamp);
        vm.stopPrank();
        _daiMockedToken.transfer(address(mockCase0MiltonDai), TestConstants.USD_19_997_18DEC);
        vm.prank(_admin);
        mockCase0JosephDai.depositToStanley(TestConstants.USD_19_997_18DEC);
        //Force deposit to simulate that IporVault earn money for Milton $3
        vm.prank(_liquidityProvider);
        stanleyDai.forTestDeposit(address(mockCase0MiltonDai), TestConstants.USD_3_18DEC);
        // when
        vm.prank(_admin);
        mockCase0JosephDai.rebalance();
        // then
        actualBalances.actualMiltonStableBalance = _daiMockedToken.balanceOf(address(mockCase0MiltonDai));
        actualBalances.actualIporVaultStableBalance = stanleyDai.totalBalance(address(mockCase0MiltonDai));
        actualBalances.actualMiltonBalance = miltonStorageDai.getBalance().liquidityPool;
        actualBalances.actualMiltonAccruedBalance = mockCase0MiltonDai.getAccruedBalance().liquidityPool;
        assertEq(actualBalances.actualMiltonStableBalance, expectedBalances.expectedMiltonStableBalance);
        assertEq(actualBalances.actualIporVaultStableBalance, expectedBalances.expectedIporVaultStableBalance);
        assertEq(actualBalances.actualMiltonBalance, expectedBalances.expectedMiltonLiquidityPoolBalance);
        //Notice! In this specific case IporVault mock returns totalBalance without any interest so balance = accrued balance
        assertEq(actualBalances.actualMiltonAccruedBalance, expectedBalances.expectedMiltonLiquidityPoolBalance);
    }

    function testShouldRebalanceWhenAMVaultRatioIsLessThanOptimalAndWithdrawFromVaultPartAmountCase2() public {
        // given
        ItfIporOracle iporOracle = getIporOracleAsset(
            _userOne,
            address(_daiMockedToken),
            TestConstants.TC_DEFAULT_EMA_18DEC_64UINT
        );
        IIporRiskManagementOracle iporRiskManagementOracle = getRiskManagementOracleAsset(
            _userOne,
            address(_daiMockedToken),
            TestConstants.RMO_UTILIZATION_RATE_48_PER,
            TestConstants.RMO_UTILIZATION_RATE_90_PER,
            TestConstants.RMO_NOTIONAL_1B,
            TestConstants.RMO_SPREAD_0_1_PER
        );
        MockCase2Stanley stanleyDai = getMockCase2Stanley(address(_daiMockedToken));
        MiltonStorage miltonStorageDai = getMiltonStorage();
        MockMilton mockCase0MiltonDai = getMockCase0MiltonDai(
            address(_daiMockedToken),
            address(iporOracle),
            address(miltonStorageDai),
            address(_miltonSpreadModel),
            address(stanleyDai),
            address(iporRiskManagementOracle)
        );
        ItfJoseph mockCase0JosephDai = getMockCase0JosephDai(
            address(_daiMockedToken),
            address(_ipTokenDai),
            address(mockCase0MiltonDai),
            address(miltonStorageDai),
            address(stanleyDai)
        );
        ActualBalances memory actualBalances;
        ExpectedBalances memory expectedBalances;
        expectedBalances.expectedMiltonStableBalance = 14480000000000000000000;
        expectedBalances.expectedMiltonLiquidityPoolBalance = 1003000000000000000000;
        expectedBalances.expectedIporVaultStableBalance = 6520000000000000000000;
        prepareApproveForUsersDai(_users, _daiMockedToken, address(mockCase0JosephDai), address(mockCase0MiltonDai));
        prepareMilton(mockCase0MiltonDai, address(mockCase0JosephDai), address(stanleyDai));
        prepareJoseph(mockCase0JosephDai);
        prepareIpToken(_ipTokenDai, address(mockCase0JosephDai));
        mockCase0JosephDai.addAppointedToRebalance(_admin);
        vm.startPrank(_liquidityProvider);
        _daiMockedToken.approve(address(stanleyDai), TestConstants.TOTAL_SUPPLY_18_DECIMALS);
        mockCase0JosephDai.itfProvideLiquidity(TestConstants.USD_1_000_18DEC, block.timestamp);
        vm.stopPrank();
        _daiMockedToken.transfer(address(mockCase0MiltonDai), TestConstants.USD_19_997_18DEC);
        vm.prank(_admin);
        mockCase0JosephDai.depositToStanley(TestConstants.USD_19_997_18DEC);
        //Force deposit to simulate that IporVault earn money for Milton $3
        vm.prank(_liquidityProvider);
        stanleyDai.forTestDeposit(address(mockCase0MiltonDai), TestConstants.USD_3_18DEC);
        // when
        vm.prank(_admin);
        mockCase0JosephDai.rebalance();
        // then
        actualBalances.actualMiltonStableBalance = _daiMockedToken.balanceOf(address(mockCase0MiltonDai));
        actualBalances.actualIporVaultStableBalance = stanleyDai.totalBalance(address(mockCase0MiltonDai));
        actualBalances.actualMiltonBalance = miltonStorageDai.getBalance().liquidityPool;
        actualBalances.actualMiltonAccruedBalance = mockCase0MiltonDai.getAccruedBalance().liquidityPool;
        assertEq(actualBalances.actualMiltonStableBalance, expectedBalances.expectedMiltonStableBalance);
        assertEq(actualBalances.actualIporVaultStableBalance, expectedBalances.expectedIporVaultStableBalance);
        assertEq(actualBalances.actualMiltonBalance, expectedBalances.expectedMiltonLiquidityPoolBalance);
        //Notice! In this specific case IporVault mock returns totalBalance without any interest so balance = accrued balance
        assertEq(actualBalances.actualMiltonAccruedBalance, expectedBalances.expectedMiltonLiquidityPoolBalance);
    }

    function testShouldWithdrawAllFromStanley() public {
        // given
        ItfIporOracle iporOracle = getIporOracleAsset(
            _userOne,
            address(_daiMockedToken),
            TestConstants.TC_DEFAULT_EMA_18DEC_64UINT
        );
        IIporRiskManagementOracle iporRiskManagementOracle = getRiskManagementOracleAsset(
            _userOne,
            address(_daiMockedToken),
            TestConstants.RMO_UTILIZATION_RATE_48_PER,
            TestConstants.RMO_UTILIZATION_RATE_90_PER,
            TestConstants.RMO_NOTIONAL_1B,
            TestConstants.RMO_SPREAD_0_1_PER
        );
        MockCase2Stanley stanleyDai = getMockCase2Stanley(address(_daiMockedToken));
        MiltonStorage miltonStorageDai = getMiltonStorage();
        MockMilton mockCase0MiltonDai = getMockCase0MiltonDai(
            address(_daiMockedToken),
            address(iporOracle),
            address(miltonStorageDai),
            address(_miltonSpreadModel),
            address(stanleyDai),
            address(iporRiskManagementOracle)
        );
        ItfJoseph mockCase0JosephDai = getMockCase0JosephDai(
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
        vm.startPrank(_liquidityProvider);
        _daiMockedToken.approve(address(stanleyDai), TestConstants.TOTAL_SUPPLY_18_DECIMALS);
        mockCase0JosephDai.itfProvideLiquidity(TestConstants.USD_1_000_18DEC, block.timestamp);
        vm.stopPrank();
        _daiMockedToken.transfer(address(mockCase0MiltonDai), TestConstants.USD_19_997_18DEC);
        vm.prank(_admin);
        mockCase0JosephDai.depositToStanley(TestConstants.USD_19_997_18DEC);
        //Force deposit to simulate that IporVault earn money for Milton $3
        vm.prank(_liquidityProvider);
        stanleyDai.forTestDeposit(address(mockCase0MiltonDai), TestConstants.USD_3_18DEC);
        uint256 stanleyBalanceBefore = stanleyDai.totalBalance(address(mockCase0MiltonDai));
        // when
        vm.prank(_admin);
        mockCase0JosephDai.withdrawAllFromStanley();
        // then
        uint256 stanleyBalanceAfter = stanleyDai.totalBalance(address(mockCase0MiltonDai));
        uint256 miltonLiquidityPoolBalanceAfter = mockCase0MiltonDai.getAccruedBalance().liquidityPool;
        uint256 exchangeRateAfter = mockCase0JosephDai.itfCalculateExchangeRate(block.timestamp);
        assertGt(stanleyBalanceBefore, stanleyBalanceAfter);
        assertEq(miltonLiquidityPoolBalanceAfter, 1003000000000000000000);
        assertEq(exchangeRateAfter, 1003000000000000000);
    }

    function testShouldNotSendETHToStanleyDaiUsdtUsdc() public payable {
        // given
        MockCaseBaseStanley stanleyDai = getMockCase0Stanley(address(_daiMockedToken));
        MockCaseBaseStanley stanleyUsdt = getMockCase0Stanley(address(_usdtMockedToken));
        MockCaseBaseStanley stanleyUsdc = getMockCase0Stanley(address(_usdcMockedToken));
        vm.expectRevert(
            abi.encodePacked(
                "Transaction reverted: function selector was not recognized and there's no fallback nor receive function"
            )
        );
        (bool statusDai, ) = address(stanleyDai).call{value: msg.value}("");
        assertTrue(!statusDai);
        vm.expectRevert(
            abi.encodePacked(
                "Transaction reverted: function selector was not recognized and there's no fallback nor receive function"
            )
        );
        (bool statusUsdt, ) = address(stanleyUsdt).call{value: msg.value}("");
        assertTrue(!statusUsdt);
        vm.expectRevert(
            abi.encodePacked(
                "Transaction reverted: function selector was not recognized and there's no fallback nor receive function"
            )
        );
        (bool statusUsdc, ) = address(stanleyUsdc).call{value: msg.value}("");
        assertTrue(!statusUsdc);
    }
}

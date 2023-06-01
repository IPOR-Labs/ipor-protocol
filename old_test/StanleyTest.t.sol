// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.20;

import "./TestCommons.sol";
import {DataUtils} from "./utils/DataUtils.sol";
import {TestConstants} from "./utils/TestConstants.sol";
import {IpToken} from "contracts/tokens/IpToken.sol";
import {AmmStorage} from "contracts/amm/AmmStorage.sol";
import {ItfIporOracle} from "contracts/itf/ItfIporOracle.sol";
import {MockSpreadModel} from "contracts/mocks/spread/MockSpreadModel.sol";
import {MockCaseBaseAssetManagement} from "contracts/mocks/assetManagement/MockCaseBaseAssetManagement.sol";
import {MockCase2AssetManagement} from "contracts/mocks/assetManagement/MockCase2AssetManagement.sol";
import {IIporRiskManagementOracle} from "contracts/interfaces/IIporRiskManagementOracle.sol";
import {IporTypes} from "contracts/interfaces/types/IporTypes.sol";

contract AssetManagementTest is TestCommons, DataUtils {
    MockSpreadModel internal _ammTreasurySpreadModel;
    MockTestnetToken internal _usdtMockedToken;
    MockTestnetToken internal _usdcMockedToken;
    MockTestnetToken internal _daiMockedToken;
    IpToken internal _ipTokenUsdt;
    IpToken internal _ipTokenUsdc;
    IpToken internal _ipTokenDai;

    struct ExpectedBalances {
        uint256 expectedAmmTreasuryStableBalance;
        uint256 expectedAmmTreasuryLiquidityPoolBalance;
        uint256 expectedIporVaultStableBalance;
    }

    struct ActualBalances {
        uint256 actualAmmTreasuryStableBalance;
        uint256 actualAmmTreasuryBalance;
        uint256 actualIporVaultStableBalance;
        uint256 actualAmmTreasuryAccruedBalance;
    }

    function setUp() public {
        _ammTreasurySpreadModel = prepareMockSpreadModel(
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
            address(_daiMockedToken)
        );
        IIporRiskManagementOracle iporRiskManagementOracle = getRiskManagementOracleAsset(
            _userOne,
            address(_daiMockedToken),
            TestConstants.RMO_UTILIZATION_RATE_48_PER,
            TestConstants.RMO_UTILIZATION_RATE_90_PER,
            TestConstants.RMO_NOTIONAL_1B,
            TestConstants.RMO_SPREAD_0_1_PER
        );
        MockCaseBaseAssetManagement assetManagementDai = getMockCase1AssetManagement(address(_daiMockedToken));
        AmmStorage ammStorageDai = getAmmStorage();
        MockAmmTreasury mockCase0AmmTreasuryDai = getMockCase0AmmTreasuryDai(
            address(_daiMockedToken),
            address(iporOracle),
            address(ammStorageDai),
            address(_ammTreasurySpreadModel),
            address(assetManagementDai),
            address(iporRiskManagementOracle)
        );
        ItfJoseph mockCase0JosephDai = getMockCase0JosephDai(
            address(_daiMockedToken),
            address(_ipTokenDai),
            address(mockCase0AmmTreasuryDai),
            address(ammStorageDai),
            address(assetManagementDai)
        );
        ActualBalances memory actualBalances;
        ExpectedBalances memory expectedBalances;
        expectedBalances.expectedAmmTreasuryStableBalance = 17002550000000000000000;
        expectedBalances.expectedAmmTreasuryLiquidityPoolBalance = 20003000000000000000000;
        expectedBalances.expectedIporVaultStableBalance = 3000450000000000000000;
        prepareApproveForUsersDai(_users, _daiMockedToken, address(mockCase0JosephDai), address(mockCase0AmmTreasuryDai));
        prepareAmmTreasury(mockCase0AmmTreasuryDai, address(mockCase0JosephDai), address(assetManagementDai));
        prepareJoseph(mockCase0JosephDai);
        prepareIpToken(_ipTokenDai, address(mockCase0JosephDai));
        mockCase0JosephDai.addAppointedToRebalance(_admin);
        vm.startPrank(_liquidityProvider);
        _daiMockedToken.approve(address(assetManagementDai), TestConstants.TOTAL_SUPPLY_18_DECIMALS);
        mockCase0JosephDai.provideLiquidity(TestConstants.USD_20_000_18DEC);
        vm.stopPrank();
        vm.prank(_admin);
        mockCase0JosephDai.depositToAssetManagement(TestConstants.USD_1_000_18DEC);
        //Force deposit to simulate that IporVault earn money for AmmTreasury $3
        vm.prank(_liquidityProvider);
        assetManagementDai.forTestDeposit(address(mockCase0AmmTreasuryDai), TestConstants.USD_3_18DEC);
        // when
        vm.prank(_admin);
        mockCase0JosephDai.rebalance();
        // then
        actualBalances.actualAmmTreasuryStableBalance = _daiMockedToken.balanceOf(address(mockCase0AmmTreasuryDai));
        actualBalances.actualIporVaultStableBalance = assetManagementDai.totalBalance(address(mockCase0AmmTreasuryDai));
        actualBalances.actualAmmTreasuryBalance = ammStorageDai.getBalance().liquidityPool;
        actualBalances.actualAmmTreasuryAccruedBalance = mockCase0AmmTreasuryDai.getAccruedBalance().liquidityPool;
        assertEq(actualBalances.actualAmmTreasuryStableBalance, expectedBalances.expectedAmmTreasuryStableBalance);
        assertEq(actualBalances.actualIporVaultStableBalance, expectedBalances.expectedIporVaultStableBalance);
        assertEq(actualBalances.actualAmmTreasuryBalance, expectedBalances.expectedAmmTreasuryLiquidityPoolBalance);
        //Notice! In this specific case IporVault mock returns totalBalance without any interest so balance = accrued balance
        assertEq(actualBalances.actualAmmTreasuryAccruedBalance, expectedBalances.expectedAmmTreasuryLiquidityPoolBalance);
    }

    function testShouldRebalanceWhenAMVaultRatioIsLessThanOptimalAndWithdrawFromVaultPartAmountCase1() public {
        // given
        ItfIporOracle iporOracle = getIporOracleAsset(
            _userOne,
            address(_daiMockedToken)
        );
        IIporRiskManagementOracle iporRiskManagementOracle = getRiskManagementOracleAsset(
            _userOne,
            address(_daiMockedToken),
            TestConstants.RMO_UTILIZATION_RATE_48_PER,
            TestConstants.RMO_UTILIZATION_RATE_90_PER,
            TestConstants.RMO_NOTIONAL_1B,
            TestConstants.RMO_SPREAD_0_1_PER
        );
        MockCaseBaseAssetManagement assetManagementDai = getMockCase1AssetManagement(address(_daiMockedToken));
        AmmStorage ammStorageDai = getAmmStorage();
        MockAmmTreasury mockCase0AmmTreasuryDai = getMockCase0AmmTreasuryDai(
            address(_daiMockedToken),
            address(iporOracle),
            address(ammStorageDai),
            address(_ammTreasurySpreadModel),
            address(assetManagementDai),
            address(iporRiskManagementOracle)
        );
        ItfJoseph mockCase0JosephDai = getMockCase0JosephDai(
            address(_daiMockedToken),
            address(_ipTokenDai),
            address(mockCase0AmmTreasuryDai),
            address(ammStorageDai),
            address(assetManagementDai)
        );
        ActualBalances memory actualBalances;
        ExpectedBalances memory expectedBalances;
        expectedBalances.expectedAmmTreasuryStableBalance = 17850000000000000000000;
        expectedBalances.expectedAmmTreasuryLiquidityPoolBalance = 1003000000000000000000;
        expectedBalances.expectedIporVaultStableBalance = 3150000000000000000000;
        prepareApproveForUsersDai(_users, _daiMockedToken, address(mockCase0JosephDai), address(mockCase0AmmTreasuryDai));
        prepareAmmTreasury(mockCase0AmmTreasuryDai, address(mockCase0JosephDai), address(assetManagementDai));
        prepareJoseph(mockCase0JosephDai);
        prepareIpToken(_ipTokenDai, address(mockCase0JosephDai));
        mockCase0JosephDai.addAppointedToRebalance(_admin);
        vm.startPrank(_liquidityProvider);
        _daiMockedToken.approve(address(assetManagementDai), TestConstants.TOTAL_SUPPLY_18_DECIMALS);
        mockCase0JosephDai.provideLiquidity(TestConstants.USD_1_000_18DEC);
        vm.stopPrank();
        _daiMockedToken.transfer(address(mockCase0AmmTreasuryDai), TestConstants.USD_19_997_18DEC);
        vm.prank(_admin);
        mockCase0JosephDai.depositToAssetManagement(TestConstants.USD_19_997_18DEC);
        //Force deposit to simulate that IporVault earn money for AmmTreasury $3
        vm.prank(_liquidityProvider);
        assetManagementDai.forTestDeposit(address(mockCase0AmmTreasuryDai), TestConstants.USD_3_18DEC);
        // when
        vm.prank(_admin);
        mockCase0JosephDai.rebalance();
        // then
        actualBalances.actualAmmTreasuryStableBalance = _daiMockedToken.balanceOf(address(mockCase0AmmTreasuryDai));
        actualBalances.actualIporVaultStableBalance = assetManagementDai.totalBalance(address(mockCase0AmmTreasuryDai));
        actualBalances.actualAmmTreasuryBalance = ammStorageDai.getBalance().liquidityPool;
        actualBalances.actualAmmTreasuryAccruedBalance = mockCase0AmmTreasuryDai.getAccruedBalance().liquidityPool;
        assertEq(actualBalances.actualAmmTreasuryStableBalance, expectedBalances.expectedAmmTreasuryStableBalance);
        assertEq(actualBalances.actualIporVaultStableBalance, expectedBalances.expectedIporVaultStableBalance);
        assertEq(actualBalances.actualAmmTreasuryBalance, expectedBalances.expectedAmmTreasuryLiquidityPoolBalance);
        //Notice! In this specific case IporVault mock returns totalBalance without any interest so balance = accrued balance
        assertEq(actualBalances.actualAmmTreasuryAccruedBalance, expectedBalances.expectedAmmTreasuryLiquidityPoolBalance);
    }

    function testShouldRebalanceWhenAMVaultRatioIsLessThanOptimalAndWithdrawFromVaultPartAmountCase2() public {
        // given
        ItfIporOracle iporOracle = getIporOracleAsset(
            _userOne,
            address(_daiMockedToken)
        );
        IIporRiskManagementOracle iporRiskManagementOracle = getRiskManagementOracleAsset(
            _userOne,
            address(_daiMockedToken),
            TestConstants.RMO_UTILIZATION_RATE_48_PER,
            TestConstants.RMO_UTILIZATION_RATE_90_PER,
            TestConstants.RMO_NOTIONAL_1B,
            TestConstants.RMO_SPREAD_0_1_PER
        );
        MockCase2AssetManagement assetManagementDai = getMockCase2AssetManagement(address(_daiMockedToken));
        AmmStorage ammStorageDai = getAmmStorage();
        MockAmmTreasury mockCase0AmmTreasuryDai = getMockCase0AmmTreasuryDai(
            address(_daiMockedToken),
            address(iporOracle),
            address(ammStorageDai),
            address(_ammTreasurySpreadModel),
            address(assetManagementDai),
            address(iporRiskManagementOracle)
        );
        ItfJoseph mockCase0JosephDai = getMockCase0JosephDai(
            address(_daiMockedToken),
            address(_ipTokenDai),
            address(mockCase0AmmTreasuryDai),
            address(ammStorageDai),
            address(assetManagementDai)
        );
        ActualBalances memory actualBalances;
        ExpectedBalances memory expectedBalances;
        expectedBalances.expectedAmmTreasuryStableBalance = 14480000000000000000000;
        expectedBalances.expectedAmmTreasuryLiquidityPoolBalance = 1003000000000000000000;
        expectedBalances.expectedIporVaultStableBalance = 6520000000000000000000;
        prepareApproveForUsersDai(_users, _daiMockedToken, address(mockCase0JosephDai), address(mockCase0AmmTreasuryDai));
        prepareAmmTreasury(mockCase0AmmTreasuryDai, address(mockCase0JosephDai), address(assetManagementDai));
        prepareJoseph(mockCase0JosephDai);
        prepareIpToken(_ipTokenDai, address(mockCase0JosephDai));
        mockCase0JosephDai.addAppointedToRebalance(_admin);
        vm.startPrank(_liquidityProvider);
        _daiMockedToken.approve(address(assetManagementDai), TestConstants.TOTAL_SUPPLY_18_DECIMALS);
        mockCase0JosephDai.provideLiquidity(TestConstants.USD_1_000_18DEC);
        vm.stopPrank();
        _daiMockedToken.transfer(address(mockCase0AmmTreasuryDai), TestConstants.USD_19_997_18DEC);
        vm.prank(_admin);
        mockCase0JosephDai.depositToAssetManagement(TestConstants.USD_19_997_18DEC);
        //Force deposit to simulate that IporVault earn money for AmmTreasury $3
        vm.prank(_liquidityProvider);
        assetManagementDai.forTestDeposit(address(mockCase0AmmTreasuryDai), TestConstants.USD_3_18DEC);
        // when
        vm.prank(_admin);
        mockCase0JosephDai.rebalance();
        // then
        actualBalances.actualAmmTreasuryStableBalance = _daiMockedToken.balanceOf(address(mockCase0AmmTreasuryDai));
        actualBalances.actualIporVaultStableBalance = assetManagementDai.totalBalance(address(mockCase0AmmTreasuryDai));
        actualBalances.actualAmmTreasuryBalance = ammStorageDai.getBalance().liquidityPool;
        actualBalances.actualAmmTreasuryAccruedBalance = mockCase0AmmTreasuryDai.getAccruedBalance().liquidityPool;
        assertEq(actualBalances.actualAmmTreasuryStableBalance, expectedBalances.expectedAmmTreasuryStableBalance);
        assertEq(actualBalances.actualIporVaultStableBalance, expectedBalances.expectedIporVaultStableBalance);
        assertEq(actualBalances.actualAmmTreasuryBalance, expectedBalances.expectedAmmTreasuryLiquidityPoolBalance);
        //Notice! In this specific case IporVault mock returns totalBalance without any interest so balance = accrued balance
        assertEq(actualBalances.actualAmmTreasuryAccruedBalance, expectedBalances.expectedAmmTreasuryLiquidityPoolBalance);
    }

    function testShouldWithdrawAllFromAssetManagement() public {
        // given
        ItfIporOracle iporOracle = getIporOracleAsset(
            _userOne,
            address(_daiMockedToken)
        );
        IIporRiskManagementOracle iporRiskManagementOracle = getRiskManagementOracleAsset(
            _userOne,
            address(_daiMockedToken),
            TestConstants.RMO_UTILIZATION_RATE_48_PER,
            TestConstants.RMO_UTILIZATION_RATE_90_PER,
            TestConstants.RMO_NOTIONAL_1B,
            TestConstants.RMO_SPREAD_0_1_PER
        );
        MockCase2AssetManagement assetManagementDai = getMockCase2AssetManagement(address(_daiMockedToken));
        AmmStorage ammStorageDai = getAmmStorage();
        MockAmmTreasury mockCase0AmmTreasuryDai = getMockCase0AmmTreasuryDai(
            address(_daiMockedToken),
            address(iporOracle),
            address(ammStorageDai),
            address(_ammTreasurySpreadModel),
            address(assetManagementDai),
            address(iporRiskManagementOracle)
        );
        ItfJoseph mockCase0JosephDai = getMockCase0JosephDai(
            address(_daiMockedToken),
            address(_ipTokenDai),
            address(mockCase0AmmTreasuryDai),
            address(ammStorageDai),
            address(assetManagementDai)
        );
        prepareApproveForUsersDai(_users, _daiMockedToken, address(mockCase0JosephDai), address(mockCase0AmmTreasuryDai));
        prepareAmmTreasury(mockCase0AmmTreasuryDai, address(mockCase0JosephDai), address(assetManagementDai));
        prepareJoseph(mockCase0JosephDai);
        prepareIpToken(_ipTokenDai, address(mockCase0JosephDai));
        vm.startPrank(_liquidityProvider);
        _daiMockedToken.approve(address(assetManagementDai), TestConstants.TOTAL_SUPPLY_18_DECIMALS);
        mockCase0JosephDai.provideLiquidity(TestConstants.USD_1_000_18DEC);
        vm.stopPrank();
        _daiMockedToken.transfer(address(mockCase0AmmTreasuryDai), TestConstants.USD_19_997_18DEC);
        vm.prank(_admin);
        mockCase0JosephDai.depositToAssetManagement(TestConstants.USD_19_997_18DEC);
        //Force deposit to simulate that IporVault earn money for AmmTreasury $3
        vm.prank(_liquidityProvider);
        assetManagementDai.forTestDeposit(address(mockCase0AmmTreasuryDai), TestConstants.USD_3_18DEC);
        uint256 assetManagementBalanceBefore = assetManagementDai.totalBalance(address(mockCase0AmmTreasuryDai));
        // when
        vm.prank(_admin);
        mockCase0JosephDai.withdrawAllFromAssetManagement();
        // then
        uint256 assetManagementBalanceAfter = assetManagementDai.totalBalance(address(mockCase0AmmTreasuryDai));
        uint256 ammTreasuryLiquidityPoolBalanceAfter = mockCase0AmmTreasuryDai.getAccruedBalance().liquidityPool;
        uint256 exchangeRateAfter = mockCase0JosephDai.itfCalculateExchangeRate(block.timestamp);
        assertGt(assetManagementBalanceBefore, assetManagementBalanceAfter);
        assertEq(ammTreasuryLiquidityPoolBalanceAfter, 1003000000000000000000);
        assertEq(exchangeRateAfter, 1003000000000000000);
    }

    function testShouldNotSendETHToAssetManagementDaiUsdtUsdc() public payable {
        // given
        MockCaseBaseAssetManagement assetManagementDai = getMockCase0AssetManagement(address(_daiMockedToken));
        MockCaseBaseAssetManagement assetManagementUsdt = getMockCase0AssetManagement(address(_usdtMockedToken));
        MockCaseBaseAssetManagement assetManagementUsdc = getMockCase0AssetManagement(address(_usdcMockedToken));
        vm.expectRevert(
            abi.encodePacked(
                "Transaction reverted: function selector was not recognized and there's no fallback nor receive function"
            )
        );
        (bool statusDai, ) = address(assetManagementDai).call{value: msg.value}("");
        assertTrue(!statusDai);
        vm.expectRevert(
            abi.encodePacked(
                "Transaction reverted: function selector was not recognized and there's no fallback nor receive function"
            )
        );
        (bool statusUsdt, ) = address(assetManagementUsdt).call{value: msg.value}("");
        assertTrue(!statusUsdt);
        vm.expectRevert(
            abi.encodePacked(
                "Transaction reverted: function selector was not recognized and there's no fallback nor receive function"
            )
        );
        (bool statusUsdc, ) = address(assetManagementUsdc).call{value: msg.value}("");
        assertTrue(!statusUsdc);
    }
}

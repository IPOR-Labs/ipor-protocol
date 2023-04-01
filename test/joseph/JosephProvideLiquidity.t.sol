// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.16;

import "forge-std/console2.sol";
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
import "../../contracts/mocks/stanley/MockCase1Stanley.sol";
import "../../contracts/mocks/joseph/MockCase0JosephDai.sol";
import "../../contracts/mocks/joseph/MockCase0JosephUsdt.sol";
import "../../contracts/amm/MiltonStorage.sol";
import "../../contracts/itf/ItfIporOracle.sol";
import "../../contracts/interfaces/types/IporTypes.sol";
import "../../contracts/mocks/stanley/MockTestnetStrategy.sol";
import "../../contracts/libraries/Constants.sol";

contract JosephProvideLiquidity is TestCommons, DataUtils, SwapUtils {
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
            TestConstants.ZERO,
            TestConstants.ZERO,
            TestConstants.ZERO_INT,
            TestConstants.ZERO_INT
        );
    }

    //
    //    function testAttack() public {
    //        // given
    //        IporProtocol memory iporProtocol = setupIporProtocolForDai();
    //
    //        uint256 userOnePosition = 1_000*1e18;
    //        uint256 userTwoPosition = 1_000_000*1e18;
    //
    //        uint256 liquidityProviderPosition = 2000*1e18;
    //
    //        iporProtocol.joseph.setAutoRebalanceThreshold(1);
    //
    //        console2.log("Auto-rebalance treshold: 10000");
    //
    //        console2.log("Attacker money for provide liquidity: ", userOnePosition);
    //        console2.log("Attacker aTokens for transfer to Stanley: ", aTokenValue);
    //
    //        console2.log("User money for provide liquidity: ", userTwoPosition);
    //
    //        // this is first initial provide liquidity
    //        deal(address(iporProtocol.asset), address(_liquidityProvider), liquidityProviderPosition);
    //
    //        deal(address(iporProtocol.asset), address(_userOne), userOnePosition);
    //        console2.log("attacker erc20 balance before attack:", iporProtocol.asset.balanceOf(address(_userOne)));
    //        deal(address(iporProtocol.asset), address(_userTwo), userTwoPosition);
    //        console2.log("user erc20 balance before attack:", iporProtocol.asset.balanceOf(address(_userTwo)));
    //
    //        vm.prank(address(_liquidityProvider));
    //        iporProtocol.asset.approve(address(iporProtocol.joseph), liquidityProviderPosition);
    ////
    ////        console2.log("NOW! INITIAL PROVIDE LIQUIDITY WHICH PROTECT POOL FROM ATTACK...");
    ////        vm.prank(address(_liquidityProvider));
    ////        iporProtocol.joseph.provideLiquidity(10*1e18);
    //
    //        vm.prank(address(_userOne));
    //        iporProtocol.asset.approve(address(iporProtocol.joseph), userOnePosition);
    //
    //        vm.prank(address(_userTwo));
    //        iporProtocol.asset.approve(address(iporProtocol.joseph), userTwoPosition);
    //
    //        console2.log("attacker provide liquidity and force Stanley rebalance:",userOnePosition);
    //        vm.prank(address(_userOne));
    //        iporProtocol.joseph.provideLiquidity(userOnePosition);
    //
    //        uint256 userOneIpToken = iporProtocol.ipToken.balanceOf(address(_userOne));
    //        console2.log("attacker has ipTokens: ",userOneIpToken);
    //
    //        console2.log("attacker redeem to achieve 1 wei token...");
    //        vm.prank(address(_userOne));
    //        iporProtocol.joseph.redeem(userOnePosition-1);
    //        console2.log("attacker ipToken balance after redeem: ",iporProtocol.ipToken.balanceOf(address(_userOne)));
    //        console2.log("attacker erc20 balance after redeem: ", iporProtocol.asset.balanceOf(address(_userOne)));
    //
    //        console2.log("ipToken TotalSupply:", iporProtocol.ipToken.totalSupply());
    //
    //        (address maxApyStrategy,,) = iporProtocol.stanley.getMaxApyStrategy();
    //        uint256 deposit = MockTestnetStrategy(maxApyStrategy).getDepositsBalance();
    //
    //        console2.log("exchangeRate before attack: ", iporProtocol.joseph.calculateExchangeRate());
    //        console2.log("attacker transfer aTokens to AAVE directly for Stanley address...");
    //
    //        MockTestnetStrategy(maxApyStrategy).setStanley(_admin);
    //        iporProtocol.asset.approve(maxApyStrategy, aTokenValue);
    //        MockTestnetStrategy(maxApyStrategy).deposit(aTokenValue);
    //        MockTestnetStrategy(maxApyStrategy).setStanley(address(iporProtocol.stanley));
    //
    //        console2.log("exchangeRate after attack:", iporProtocol.joseph.calculateExchangeRate());
    //
    //        console2.log("user provide liquidity: ",userTwoPosition);
    //        vm.prank(address(_userTwo));
    //        iporProtocol.joseph.provideLiquidity(userTwoPosition);
    //
    //        console2.log("liquidity provider provide liquidity: ",liquidityProviderPosition);
    //        vm.prank(address(_liquidityProvider));
    //        iporProtocol.joseph.provideLiquidity(liquidityProviderPosition);
    //
    //        uint256 lpIpToken = iporProtocol.ipToken.balanceOf(address(_liquidityProvider));
    //
    //        console2.log("provideLiquidity ip token balance: ", lpIpToken);
    //
    //        console2.log("liquidity provider redeem...");
    //        vm.prank(address(_liquidityProvider));
    //        iporProtocol.joseph.redeem(lpIpToken);
    //
    //        uint256 userTwoIpToken = iporProtocol.ipToken.balanceOf(address(_userTwo));
    //        console2.log("user has ipTokens: ",userTwoIpToken);
    //
    //        uint256 userOneIpToken_2 = iporProtocol.ipToken.balanceOf(address(_userOne));
    //        console2.log("attacker has ipTokens: ", userOneIpToken_2);
    //
    //        console2.log("user redeem...");
    //        vm.prank(address(_userTwo));
    //        iporProtocol.joseph.redeem(userTwoIpToken);
    //        console2.log("user erc20 balance after redeem: ", iporProtocol.asset.balanceOf(address(_userTwo)));
    //
    //        console2.log("NOW ATTACKER HAVE TO BE RIGHT AFTER USER REDEEM");
    //
    //        console2.log("attacker redeem...");
    //        vm.prank(address(_userOne));
    //        iporProtocol.joseph.redeem(userOneIpToken_2);
    //        console2.log("attacker erc20 balance after redeem: ", iporProtocol.asset.balanceOf(address(_userOne)));
    //
    //        console2.log("----------------------------------------SUMMARY----------------------------------------");
    //
    //        console2.log("user lost:");
    //        int256 userLost = int256(iporProtocol.asset.balanceOf(address(_userTwo))) - int256(userTwoPosition);
    //        console.logInt(userLost);
    //        console.logInt(IporMath.divisionInt(userLost, Constants.D18_INT));
    //
    //        console2.log("liquidity provider lost:");
    //        int256 liquidityProviderLost = int256(iporProtocol.asset.balanceOf(address(_liquidityProvider))) - int256(liquidityProviderPosition);
    //        console.logInt(liquidityProviderLost);
    //        console.logInt(IporMath.divisionInt(liquidityProviderLost, Constants.D18_INT));
    //
    //        console2.log("attacker gained:");
    //        int256 attackerGained = int256(iporProtocol.asset.balanceOf(address(_userOne))) - int256(userOnePosition+aTokenValue);
    //        console.logInt(attackerGained);
    //        console.logInt(IporMath.divisionInt(attackerGained, Constants.D18_INT));
    //
    //        console2.log("accrued liquidity pool balance:", iporProtocol.milton.getAccruedBalance().liquidityPool);
    //        console2.log("accrued liquidity pool balance:",
    //            IporMath.division(iporProtocol.milton.getAccruedBalance().liquidityPool, Constants.D18));
    //
    //    }
    //
    //    function testAttack2() public {
    //        // given
    //        IporProtocol memory iporProtocol = setupIporProtocolForDai();
    //
    //        uint256 user1 = 1_000*1e18;
    //        uint256 user2 = 1_000*1e18;
    //        uint256 user3 = 1_000*1e18;
    //
    //        iporProtocol.joseph.setAutoRebalanceThreshold(0);
    //        deal(address(iporProtocol.asset), address(_userOne), user1);
    //        deal(address(iporProtocol.asset), address(_userTwo), user2);
    //        deal(address(iporProtocol.asset), address(_userThree), user3);
    //
    //        vm.prank(address(_userOne));
    //        iporProtocol.asset.approve(address(iporProtocol.joseph), user1);
    //        vm.prank(address(_userTwo));
    //        iporProtocol.asset.approve(address(iporProtocol.joseph), user2);
    //        vm.prank(address(_userThree));
    //        iporProtocol.asset.approve(address(iporProtocol.joseph), user3);
    //
    //
    //        vm.prank(address(_userOne));
    //        iporProtocol.joseph.provideLiquidity(user1);
    //
    //        console2.log("exchangeRate - 1 - after provide user one: ", iporProtocol.joseph.calculateExchangeRate());
    //
    //        vm.prank(address(_userTwo));
    //        iporProtocol.joseph.provideLiquidity(user2);
    //
    //        console2.log("exchangeRate - 1 - after provide user two: ", iporProtocol.joseph.calculateExchangeRate());
    //        vm.prank(address(_userThree));
    //        iporProtocol.joseph.provideLiquidity(user3);
    //
    //        console2.log("exchangeRate - 1 - after provide user three: ", iporProtocol.joseph.calculateExchangeRate());
    //
    //        uint256 user2IpToken = iporProtocol.ipToken.balanceOf(address(_userTwo));
    //        vm.prank(address(_userTwo));
    //        iporProtocol.joseph.redeem(user2IpToken);
    //
    //        console2.log("exchangeRate - 2 - after redeem user two: ", iporProtocol.joseph.calculateExchangeRate());
    //
    //        uint256 user3IpToken = iporProtocol.ipToken.balanceOf(address(_userThree));
    //        vm.prank(address(_userThree));
    //        iporProtocol.joseph.redeem(user3IpToken);
    //
    //        console2.log("exchangeRate - 3 - after redeem user three: ", iporProtocol.joseph.calculateExchangeRate());
    //
    //
    //        console2.log("----------------------------------------SUMMARY----------------------------------------");
    //
    //        console2.log("user one:");
    //        int256 userOneAmount = int256(iporProtocol.asset.balanceOf(address(_userOne))) - int256(user1);
    //        console.logInt(userOneAmount);
    //        console.logInt(IporMath.divisionInt(userOneAmount, Constants.D18_INT));
    //
    //        console2.log("user two:");
    //        int256 userTwoAmount = int256(iporProtocol.asset.balanceOf(address(_userTwo))) - int256(user2);
    //        console.logInt(userTwoAmount);
    //        console.logInt(IporMath.divisionInt(userTwoAmount, Constants.D18_INT));
    //
    //        console2.log("user three:");
    //        int256 userThreeAmount = int256(iporProtocol.asset.balanceOf(address(_userThree))) - int256(user3);
    //        console.logInt(userThreeAmount);
    //        console.logInt(IporMath.divisionInt(userThreeAmount, Constants.D18_INT));
    //
    //
    //        console2.log("accrued liquidity pool balance:", iporProtocol.milton.getAccruedBalance().liquidityPool);
    //        console2.log("accrued liquidity pool balance:",
    //            IporMath.division(iporProtocol.milton.getAccruedBalance().liquidityPool, Constants.D18));
    //        console2.log("exchangeRate - 4:", iporProtocol.joseph.calculateExchangeRate());
    //
    //    }

    function testShouldSetupInitValueForRedeemLPMaxUtilizationPercentage() public {
        // given
        address[] memory tokenAddresses = addressesToArray(
            address(_usdtMockedToken),
            address(_usdcMockedToken),
            address(_daiMockedToken)
        );
        address[] memory ipTokenAddresses = addressesToArray(
            address(_ipTokenUsdt),
            address(_ipTokenUsdc),
            address(_ipTokenDai)
        );
        ItfIporOracle iporOracle = getIporOracleAssets(
            _userOne,
            tokenAddresses,
            uint32(block.timestamp),
            TestConstants.TC_DEFAULT_EMA_18DEC_64UINT,
            0
        );
        address[] memory mockCase1StanleyAddresses = addressesToArray(
            address(_usdtMockedToken),
            address(_usdcMockedToken),
            address(_daiMockedToken)
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
            mockCase1StanleyAddresses
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
        // when
        uint256 actualValueUsdt = mockCase0Josephs
            .mockCase0JosephUsdt
            .getRedeemLpMaxUtilizationRate();
        uint256 actualValueUsdc = mockCase0Josephs
            .mockCase0JosephUsdc
            .getRedeemLpMaxUtilizationRate();
        uint256 actualValueDai = mockCase0Josephs
            .mockCase0JosephDai
            .getRedeemLpMaxUtilizationRate();
        // then
        assertEq(actualValueUsdt, TestConstants.D18);
        assertEq(actualValueUsdc, TestConstants.D18);
		
        assertEq(actualValueDai, TestConstants.D18);
    }

    function testShouldProvideLiquidityAndTakeIpTokenWhemSimpleCase1And18Decimals() public {
        // given

        ItfIporOracle iporOracle = getIporOracleAsset(
            _userOne,
            address(_daiMockedToken),
            TestConstants.TC_DEFAULT_EMA_18DEC_64UINT
        );
        MockCase0Stanley stanleyDai = getMockCase0Stanley(address(_daiMockedToken));
        MiltonStorage miltonStorageDai = getMiltonStorage();
        MockCase0MiltonDai mockCase0MiltonDai = getMockCase0MiltonDai(
            address(_daiMockedToken),
            address(iporOracle),
            address(miltonStorageDai),
            address(_miltonSpreadModel),
            address(stanleyDai)
        );
        MockCase0JosephDai mockCase0JosephDai = getMockCase0JosephDai(
            address(_daiMockedToken),
            address(_ipTokenDai),
            address(mockCase0MiltonDai),
            address(miltonStorageDai),
            address(stanleyDai)
        );
        prepareApproveForUsersDai(
            _users,
            _daiMockedToken,
            address(mockCase0JosephDai),
            address(mockCase0MiltonDai)
        );
        prepareMilton(mockCase0MiltonDai, address(mockCase0JosephDai), address(stanleyDai));
        prepareJoseph(mockCase0JosephDai);
        prepareIpToken(_ipTokenDai, address(mockCase0JosephDai));
        // when
        vm.prank(_liquidityProvider);
        mockCase0JosephDai.itfProvideLiquidity(TestConstants.USD_14_000_18DEC, block.timestamp);
        IporTypes.MiltonBalancesMemory memory balance = mockCase0MiltonDai.getAccruedBalance();
        // then
        assertEq(TestConstants.USD_14_000_18DEC, _ipTokenDai.balanceOf(_liquidityProvider));
        assertEq(
            TestConstants.USD_14_000_18DEC,
            _daiMockedToken.balanceOf(address(mockCase0MiltonDai))
        );
        assertEq(TestConstants.USD_14_000_18DEC, balance.liquidityPool);
        assertEq(9986000 * TestConstants.D18, _daiMockedToken.balanceOf(_liquidityProvider));
    }

    function testShouldProvideLiquidityAndTakeIpTokenWhemSimpleCase1And6Decimals() public {
        // given
        ItfIporOracle iporOracle = getIporOracleAsset(
            _userOne,
            address(_usdtMockedToken),
            TestConstants.TC_DEFAULT_EMA_18DEC_64UINT
        );
        MockCase0Stanley stanleyUsdt = getMockCase0Stanley(address(_usdtMockedToken));
        MiltonStorage miltonStorageUsdt = getMiltonStorage();
        MockCase0MiltonUsdt mockCase0MiltonUsdt = getMockCase0MiltonUsdt(
            address(_usdtMockedToken),
            address(iporOracle),
            address(miltonStorageUsdt),
            address(_miltonSpreadModel),
            address(stanleyUsdt)
        );
        MockCase0JosephUsdt mockCase0JosephUsdt = getMockCase0JosephUsdt(
            address(_usdtMockedToken),
            address(_ipTokenUsdt),
            address(mockCase0MiltonUsdt),
            address(miltonStorageUsdt),
            address(stanleyUsdt)
        );
        prepareApproveForUsersUsd(
            _users,
            _usdtMockedToken,
            address(mockCase0JosephUsdt),
            address(mockCase0MiltonUsdt)
        );
        prepareMilton(mockCase0MiltonUsdt, address(mockCase0JosephUsdt), address(stanleyUsdt));
        prepareJoseph(mockCase0JosephUsdt);
        prepareIpToken(_ipTokenUsdt, address(mockCase0JosephUsdt));
        // when
        vm.prank(_liquidityProvider);
        mockCase0JosephUsdt.itfProvideLiquidity(TestConstants.USD_14_000_6DEC, block.timestamp);
        IporTypes.MiltonBalancesMemory memory balance = mockCase0MiltonUsdt.getAccruedBalance();
        // then
        assertEq(TestConstants.USD_14_000_18DEC, _ipTokenUsdt.balanceOf(_liquidityProvider));
        assertEq(
            TestConstants.USD_14_000_6DEC,
            _usdtMockedToken.balanceOf(address(mockCase0MiltonUsdt))
        );
        assertEq(TestConstants.USD_14_000_18DEC, balance.liquidityPool);
        assertEq(9986000000000, _usdtMockedToken.balanceOf(_liquidityProvider));
    }

    function testShouldNotProvideLiquidityWhenLiquidyPoolIsEmpty() public {
        // given
        ItfIporOracle iporOracle = getIporOracleAsset(
            _userOne,
            address(_daiMockedToken),
            TestConstants.TC_DEFAULT_EMA_18DEC_64UINT
        );
        MockCase0Stanley stanleyDai = getMockCase0Stanley(address(_daiMockedToken));
        MiltonStorage miltonStorageDai = getMiltonStorage();
        MockCase0MiltonDai mockCase0MiltonDai = getMockCase0MiltonDai(
            address(_daiMockedToken),
            address(iporOracle),
            address(miltonStorageDai),
            address(_miltonSpreadModel),
            address(stanleyDai)
        );
        MockCase0JosephDai mockCase0JosephDai = getMockCase0JosephDai(
            address(_daiMockedToken),
            address(_ipTokenDai),
            address(mockCase0MiltonDai),
            address(miltonStorageDai),
            address(stanleyDai)
        );
        prepareApproveForUsersDai(
            _users,
            _daiMockedToken,
            address(mockCase0JosephDai),
            address(mockCase0MiltonDai)
        );
        prepareMilton(mockCase0MiltonDai, address(mockCase0JosephDai), address(stanleyDai));
        prepareJoseph(mockCase0JosephDai);
        prepareIpToken(_ipTokenDai, address(mockCase0JosephDai));
        mockCase0JosephDai.itfProvideLiquidity(TestConstants.USD_10_000_18DEC, block.timestamp);
        //simulation that Liquidity Pool Balance equal 0, but ipToken is not burned
        miltonStorageDai.setJoseph(_userOne);
        vm.prank(_userOne);
        miltonStorageDai.subtractLiquidity(TestConstants.USD_10_000_18DEC);
        miltonStorageDai.setJoseph(address(mockCase0JosephDai));
        // when
        vm.prank(_liquidityProvider);
        vm.expectRevert("IPOR_300");
        mockCase0JosephDai.itfProvideLiquidity(TestConstants.USD_10_000_18DEC, block.timestamp);
    }

    function testShouldNotProvideLiquidityWhenMaxLiquidityPoolBalanceExceeded() public {
        // given
        ItfIporOracle iporOracle = getIporOracleAsset(
            _userOne,
            address(_daiMockedToken),
            TestConstants.TC_DEFAULT_EMA_18DEC_64UINT
        );
        MockCase0Stanley stanleyDai = getMockCase0Stanley(address(_daiMockedToken));
        MiltonStorage miltonStorageDai = getMiltonStorage();
        MockCase0MiltonDai mockCase0MiltonDai = getMockCase0MiltonDai(
            address(_daiMockedToken),
            address(iporOracle),
            address(miltonStorageDai),
            address(_miltonSpreadModel),
            address(stanleyDai)
        );
        MockCase0JosephDai mockCase0JosephDai = getMockCase0JosephDai(
            address(_daiMockedToken),
            address(_ipTokenDai),
            address(mockCase0MiltonDai),
            address(miltonStorageDai),
            address(stanleyDai)
        );
        prepareApproveForUsersDai(
            _users,
            _daiMockedToken,
            address(mockCase0JosephDai),
            address(mockCase0MiltonDai)
        );
        prepareMilton(mockCase0MiltonDai, address(mockCase0JosephDai), address(stanleyDai));
        prepareJoseph(mockCase0JosephDai);
        prepareIpToken(_ipTokenDai, address(mockCase0JosephDai));
        mockCase0JosephDai.setMaxLiquidityPoolBalance(20000);
        mockCase0JosephDai.setMaxLpAccountContribution(15000);
        vm.prank(_liquidityProvider);
        mockCase0JosephDai.itfProvideLiquidity(TestConstants.USD_15_000_18DEC, block.timestamp);
        // when other user provides liquidity
        vm.prank(_userOne);
        vm.expectRevert("IPOR_304");
        mockCase0JosephDai.itfProvideLiquidity(TestConstants.USD_15_000_18DEC, block.timestamp);
    }

    function testShouldNotProvideLiquidityWhenMaxLiquidityPoolAccountContributionExceededCase1()
        public
    {
        // given
        ItfIporOracle iporOracle = getIporOracleAsset(
            _userOne,
            address(_daiMockedToken),
            TestConstants.TC_DEFAULT_EMA_18DEC_64UINT
        );
        MockCase0Stanley stanleyDai = getMockCase0Stanley(address(_daiMockedToken));
        MiltonStorage miltonStorageDai = getMiltonStorage();
        MockCase0MiltonDai mockCase0MiltonDai = getMockCase0MiltonDai(
            address(_daiMockedToken),
            address(iporOracle),
            address(miltonStorageDai),
            address(_miltonSpreadModel),
            address(stanleyDai)
        );
        MockCase0JosephDai mockCase0JosephDai = getMockCase0JosephDai(
            address(_daiMockedToken),
            address(_ipTokenDai),
            address(mockCase0MiltonDai),
            address(miltonStorageDai),
            address(stanleyDai)
        );
        prepareApproveForUsersDai(
            _users,
            _daiMockedToken,
            address(mockCase0JosephDai),
            address(mockCase0MiltonDai)
        );
        prepareMilton(mockCase0MiltonDai, address(mockCase0JosephDai), address(stanleyDai));
        prepareJoseph(mockCase0JosephDai);
        prepareIpToken(_ipTokenDai, address(mockCase0JosephDai));
        mockCase0JosephDai.setMaxLiquidityPoolBalance(2000000);
        mockCase0JosephDai.setMaxLpAccountContribution(50000);
        vm.startPrank(_liquidityProvider);
        mockCase0JosephDai.itfProvideLiquidity(TestConstants.USD_10_000_18DEC, block.timestamp);
        // when
        vm.expectRevert("IPOR_305");
        mockCase0JosephDai.itfProvideLiquidity(51000 * TestConstants.D18, block.timestamp);
        vm.stopPrank();
    }

    function testShouldNotProvideLiquidityWhenMaxLiquidityPoolAccountContributionExceededCase2()
        public
    {
        // given
        ItfIporOracle iporOracle = getIporOracleAsset(
            _userOne,
            address(_daiMockedToken),
            TestConstants.TC_DEFAULT_EMA_18DEC_64UINT
        );
        MockCase0Stanley stanleyDai = getMockCase0Stanley(address(_daiMockedToken));
        MiltonStorage miltonStorageDai = getMiltonStorage();
        MockCase0MiltonDai mockCase0MiltonDai = getMockCase0MiltonDai(
            address(_daiMockedToken),
            address(iporOracle),
            address(miltonStorageDai),
            address(_miltonSpreadModel),
            address(stanleyDai)
        );
        MockCase0JosephDai mockCase0JosephDai = getMockCase0JosephDai(
            address(_daiMockedToken),
            address(_ipTokenDai),
            address(mockCase0MiltonDai),
            address(miltonStorageDai),
            address(stanleyDai)
        );
        prepareApproveForUsersDai(
            _users,
            _daiMockedToken,
            address(mockCase0JosephDai),
            address(mockCase0MiltonDai)
        );
        prepareMilton(mockCase0MiltonDai, address(mockCase0JosephDai), address(stanleyDai));
        prepareJoseph(mockCase0JosephDai);
        prepareIpToken(_ipTokenDai, address(mockCase0JosephDai));
        mockCase0JosephDai.setMaxLiquidityPoolBalance(2000000);
        mockCase0JosephDai.setMaxLpAccountContribution(50000);
        vm.startPrank(_liquidityProvider);
        mockCase0JosephDai.itfProvideLiquidity(TestConstants.USD_50_000_18DEC, block.timestamp);
        // when
        vm.expectRevert("IPOR_305");
        mockCase0JosephDai.itfProvideLiquidity(TestConstants.USD_50_000_18DEC, block.timestamp);
        vm.stopPrank();
    }

    function testShouldNotProvideLiquidityWhenMaxLiquidityPoolAccountContributionExceededCase3()
        public
    {
        // given
        ItfIporOracle iporOracle = getIporOracleAsset(
            _userOne,
            address(_daiMockedToken),
            TestConstants.TC_DEFAULT_EMA_18DEC_64UINT
        );
        MockCase0Stanley stanleyDai = getMockCase0Stanley(address(_daiMockedToken));
        MiltonStorage miltonStorageDai = getMiltonStorage();
        MockCase0MiltonDai mockCase0MiltonDai = getMockCase0MiltonDai(
            address(_daiMockedToken),
            address(iporOracle),
            address(miltonStorageDai),
            address(_miltonSpreadModel),
            address(stanleyDai)
        );
        MockCase0JosephDai mockCase0JosephDai = getMockCase0JosephDai(
            address(_daiMockedToken),
            address(_ipTokenDai),
            address(mockCase0MiltonDai),
            address(miltonStorageDai),
            address(stanleyDai)
        );
        prepareApproveForUsersDai(
            _users,
            _daiMockedToken,
            address(mockCase0JosephDai),
            address(mockCase0MiltonDai)
        );
        prepareMilton(mockCase0MiltonDai, address(mockCase0JosephDai), address(stanleyDai));
        prepareJoseph(mockCase0JosephDai);
        prepareIpToken(_ipTokenDai, address(mockCase0JosephDai));
        mockCase0JosephDai.setMaxLiquidityPoolBalance(2000000);
        mockCase0JosephDai.setMaxLpAccountContribution(50000);
        vm.startPrank(_liquidityProvider);
        mockCase0JosephDai.itfProvideLiquidity(TestConstants.USD_50_000_18DEC, block.timestamp);
        mockCase0JosephDai.itfRedeem(TestConstants.USD_50_000_18DEC, block.timestamp);
        // when
        vm.expectRevert("IPOR_305");
        mockCase0JosephDai.itfProvideLiquidity(TestConstants.USD_50_000_18DEC, block.timestamp);
        vm.stopPrank();
    }

    function testShouldNotProvideLiquidityWhenMaxLiquidityPoolAccountContributionExceededCase4()
        public
    {
        // given
        ItfIporOracle iporOracle = getIporOracleAsset(
            _userOne,
            address(_daiMockedToken),
            TestConstants.TC_DEFAULT_EMA_18DEC_64UINT
        );
        MockCase0Stanley stanleyDai = getMockCase0Stanley(address(_daiMockedToken));
        MiltonStorage miltonStorageDai = getMiltonStorage();
        MockCase0MiltonDai mockCase0MiltonDai = getMockCase0MiltonDai(
            address(_daiMockedToken),
            address(iporOracle),
            address(miltonStorageDai),
            address(_miltonSpreadModel),
            address(stanleyDai)
        );
        MockCase0JosephDai mockCase0JosephDai = getMockCase0JosephDai(
            address(_daiMockedToken),
            address(_ipTokenDai),
            address(mockCase0MiltonDai),
            address(miltonStorageDai),
            address(stanleyDai)
        );
        prepareApproveForUsersDai(
            _users,
            _daiMockedToken,
            address(mockCase0JosephDai),
            address(mockCase0MiltonDai)
        );
        prepareMilton(mockCase0MiltonDai, address(mockCase0JosephDai), address(stanleyDai));
        prepareJoseph(mockCase0JosephDai);
        prepareIpToken(_ipTokenDai, address(mockCase0JosephDai));
        mockCase0JosephDai.setMaxLiquidityPoolBalance(2000000);
        mockCase0JosephDai.setMaxLpAccountContribution(50000);
        vm.startPrank(_liquidityProvider);
        mockCase0JosephDai.itfProvideLiquidity(TestConstants.USD_50_000_18DEC, block.timestamp);
        _ipTokenDai.transfer(_userThree, TestConstants.USD_50_000_18DEC);
        uint256 ipTokenLiquidityProviderBalance = _ipTokenDai.balanceOf(_liquidityProvider);
        assertEq(ipTokenLiquidityProviderBalance, TestConstants.ZERO);
        // when
        vm.expectRevert("IPOR_305");
        mockCase0JosephDai.itfProvideLiquidity(TestConstants.USD_50_000_18DEC, block.timestamp);
        vm.stopPrank();
    }
}

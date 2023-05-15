// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.16;

import "../TestCommons.sol";
import {DataUtils} from "../utils/DataUtils.sol";
import {SwapUtils} from "../utils/SwapUtils.sol";
import "../utils/TestConstants.sol";
import "../../contracts/mocks/spread/MockSpreadModel.sol";
import "../../contracts/mocks/tokens/MockTestnetToken.sol";
import "../../contracts/tokens/IpToken.sol";
import "../../contracts/itf/ItfIporOracle.sol";
import "../../contracts/interfaces/types/IporTypes.sol";

contract JosephRedeem is TestCommons, DataUtils, SwapUtils {
    IporProtocolFactory.IporProtocolConfig private _cfg;
    IporProtocolFactory.AmmConfig private _ammCfg;
    IporProtocolBuilder.IporProtocol internal _iporProtocol;

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

        _cfg.spreadImplementation = address(
            new MockSpreadModel(
                TestConstants.PERCENTAGE_4_18DEC,
                TestConstants.PERCENTAGE_2_18DEC,
                TestConstants.ZERO_INT,
                TestConstants.ZERO_INT
            )
        );

        _ammCfg.iporOracleUpdater = _userOne;
        _ammCfg.iporRiskManagementOracleUpdater = _userOne;
    }

    function testShouldRedeemIpToken18DecimalsSimpleCase1() public {
        // given
        _cfg.miltonTestCase = BuilderUtils.MiltonTestCase.CASE0;
        _iporProtocol = _iporProtocolFactory.getDaiInstance(_cfg);

        uint256 redeemFee = 50 * TestConstants.D18;
        ExpectedJosephBalances memory expectedBalances;
        expectedBalances.expectedIpTokenBalance = 4000 * TestConstants.D18;
        expectedBalances.expectedTokenBalance = 9996000 * TestConstants.D18 - redeemFee;
        expectedBalances.expectedMiltonBalance = 4000 * TestConstants.D18 + redeemFee;
        expectedBalances.expectedLiquidityPoolBalance = 4000 * TestConstants.D18 + redeemFee;

        vm.startPrank(_liquidityProvider);
        _iporProtocol.joseph.itfProvideLiquidity(TestConstants.USD_14_000_18DEC, block.timestamp);

        // when
        _iporProtocol.joseph.itfRedeem(TestConstants.TC_TOTAL_AMOUNT_10_000_18DEC, block.timestamp);
        vm.stopPrank();

        // then
        IporTypes.MiltonBalancesMemory memory balance = _iporProtocol.milton.getAccruedBalance();
        uint256 actualLiquidityPoolBalance = balance.liquidityPool;

        assertEq(_iporProtocol.ipToken.balanceOf(_liquidityProvider), expectedBalances.expectedIpTokenBalance);
        assertEq(_iporProtocol.asset.balanceOf(address(_iporProtocol.milton)), expectedBalances.expectedMiltonBalance);
        assertEq(actualLiquidityPoolBalance, expectedBalances.expectedLiquidityPoolBalance);
        assertEq(_iporProtocol.asset.balanceOf(_liquidityProvider), expectedBalances.expectedTokenBalance);
    }

    function testShouldRedeemIpToken6DecimalsSimpleCase1() public {
        // given
        _cfg.miltonTestCase = BuilderUtils.MiltonTestCase.CASE0;
        _iporProtocol = _iporProtocolFactory.getUsdtInstance(_cfg);

        uint256 redeemFee18Dec = 50 * TestConstants.D18;
        uint256 redeemFee6Dec = 50 * TestConstants.N1__0_6DEC;

        ExpectedJosephBalances memory expectedBalances;
        expectedBalances.expectedIpTokenBalance = 4000 * TestConstants.D18;
        expectedBalances.expectedTokenBalance = 9996000 * TestConstants.N1__0_6DEC - redeemFee6Dec;
        expectedBalances.expectedMiltonBalance = 4000 * TestConstants.N1__0_6DEC + redeemFee6Dec;
        expectedBalances.expectedLiquidityPoolBalance = 4000 * TestConstants.D18 + redeemFee18Dec;

        vm.startPrank(_liquidityProvider);
        _iporProtocol.joseph.itfProvideLiquidity(TestConstants.USD_14_000_6DEC, block.timestamp);

        // when
        _iporProtocol.joseph.itfRedeem(TestConstants.TC_TOTAL_AMOUNT_10_000_18DEC, block.timestamp);
        vm.stopPrank();

        // then
        IporTypes.MiltonBalancesMemory memory balance = _iporProtocol.milton.getAccruedBalance();
        uint256 actualLiquidityPoolBalance = balance.liquidityPool;

        assertEq(_iporProtocol.ipToken.balanceOf(_liquidityProvider), expectedBalances.expectedIpTokenBalance);
        assertEq(_iporProtocol.asset.balanceOf(address(_iporProtocol.milton)), expectedBalances.expectedMiltonBalance);
        assertEq(actualLiquidityPoolBalance, expectedBalances.expectedLiquidityPoolBalance);
        assertEq(_iporProtocol.asset.balanceOf(_liquidityProvider), expectedBalances.expectedTokenBalance);
    }

    function testShouldRedeemIpTokensBecauseNoValidationForCoolOffPeriod() public {
        // given
        _cfg.miltonTestCase = BuilderUtils.MiltonTestCase.CASE0;
        _iporProtocol = _iporProtocolFactory.getDaiInstance(_cfg);

        uint256 redeemFee = 50 * TestConstants.D18;

        ExpectedJosephBalances memory expectedBalances;
        expectedBalances.expectedIpTokenBalance = 4000 * TestConstants.D18;
        expectedBalances.expectedTokenBalance = 9996000 * TestConstants.D18 - redeemFee;
        expectedBalances.expectedMiltonBalance = 4000 * TestConstants.D18 + redeemFee;
        expectedBalances.expectedLiquidityPoolBalance = 4000 * TestConstants.D18 + redeemFee;

        vm.startPrank(_liquidityProvider);
        _iporProtocol.joseph.itfProvideLiquidity(TestConstants.USD_14_000_18DEC, block.timestamp);

        // when
        _iporProtocol.joseph.itfRedeem(TestConstants.TC_TOTAL_AMOUNT_10_000_18DEC, block.timestamp);
        vm.stopPrank();

        // then
        IporTypes.MiltonBalancesMemory memory balance = _iporProtocol.milton.getAccruedBalance();
        uint256 actualLiquidityPoolBalance = balance.liquidityPool;

        assertEq(_iporProtocol.ipToken.balanceOf(_liquidityProvider), expectedBalances.expectedIpTokenBalance);
        assertEq(_iporProtocol.asset.balanceOf(address(_iporProtocol.milton)), expectedBalances.expectedMiltonBalance);
        assertEq(_iporProtocol.asset.balanceOf(_liquidityProvider), expectedBalances.expectedTokenBalance);
        assertEq(actualLiquidityPoolBalance, expectedBalances.expectedLiquidityPoolBalance);
    }

    function testShouldRedeemIpTokensWhenTwoTimesProvidedLiquidity() public {
        // given
        _cfg.miltonTestCase = BuilderUtils.MiltonTestCase.CASE0;
        _iporProtocol = _iporProtocolFactory.getDaiInstance(_cfg);

        uint256 redeemFee = 70 * TestConstants.D18;

        ExpectedJosephBalances memory expectedBalances;
        expectedBalances.expectedIpTokenBalance = 6000 * TestConstants.D18;
        expectedBalances.expectedTokenBalance = 9994000 * TestConstants.D18 - redeemFee;
        expectedBalances.expectedMiltonBalance = 6000 * TestConstants.D18 + redeemFee;
        expectedBalances.expectedLiquidityPoolBalance = 6000 * TestConstants.D18 + redeemFee;

        vm.startPrank(_liquidityProvider);
        _iporProtocol.joseph.itfProvideLiquidity(TestConstants.TC_TOTAL_AMOUNT_10_000_18DEC, block.timestamp);
        _iporProtocol.joseph.itfProvideLiquidity(TestConstants.TC_TOTAL_AMOUNT_10_000_18DEC, block.timestamp);

        // when
        _iporProtocol.joseph.itfRedeem(TestConstants.USD_14_000_18DEC, block.timestamp);
        vm.stopPrank();

        // then
        IporTypes.MiltonBalancesMemory memory balance = _iporProtocol.milton.getAccruedBalance();
        uint256 actualLiquidityPoolBalance = balance.liquidityPool;

        assertEq(_iporProtocol.ipToken.balanceOf(_liquidityProvider), expectedBalances.expectedIpTokenBalance);
        assertEq(_iporProtocol.asset.balanceOf(address(_iporProtocol.milton)), expectedBalances.expectedMiltonBalance);
        assertEq(_iporProtocol.asset.balanceOf(_liquidityProvider), expectedBalances.expectedTokenBalance);
        assertEq(actualLiquidityPoolBalance, expectedBalances.expectedLiquidityPoolBalance);
    }

    function testShouldRedeemIpDaiAndIpUsdtWhenSimpleCase1() public {
        // given
        address owner = address(this);
        IporProtocolBuilder iporProtocolBuilder = new IporProtocolBuilder(owner);

        AssetBuilder assetBuilder = new AssetBuilder(owner, iporProtocolBuilder);
        assetBuilder.withUSDT();
        MockTestnetToken usdt = assetBuilder.build();

        assetBuilder.withDAI();
        MockTestnetToken dai = assetBuilder.build();

        IporOracleFactory iporOracleFactory = new IporOracleFactory(owner);
        address[] memory assets = new address[](2);
        assets[0] = address(dai);
        assets[1] = address(usdt);

        BuilderUtils.IporOracleInitialParamsTestCase initialParamsTestCase;
        ItfIporOracle iporOracle = iporOracleFactory.getInstance(assets, owner, initialParamsTestCase);

        BuilderUtils.IporRiskManagementOracleInitialParamsTestCase iporRiskManagementOracleInitialParamsTestCase;
        IporRiskManagementOracle iporRiskManagementOracle = _iporRiskManagementOracleFactory.getInstance(
            assets,
            owner,
            iporRiskManagementOracleInitialParamsTestCase
        );

        IporProtocolBuilder.IporProtocol memory ammUsdt = iporProtocolBuilder
            .usdtBuilder()
            .withAsset(address(usdt))
            .ipToken()
            .withName("IP USDT")
            .withSymbol("ipUSDT")
            .and()
            .ivToken()
            .withName("IV USDT")
            .withSymbol("ivUSDT")
            .and()
            .withIporOracle(address(iporOracle))
            .withIporRiskManagementOracle(address(iporRiskManagementOracle))
            .build();

        IporProtocolBuilder.IporProtocol memory ammDai = iporProtocolBuilder
            .daiBuilder()
            .withAsset(address(dai))
            .ipToken()
            .withName("IP DAI")
            .withSymbol("ipDAI")
            .and()
            .ivToken()
            .withName("IV DAI")
            .withSymbol("ivDAI")
            .and()
            .withIporOracle(address(iporOracle))
            .withIporRiskManagementOracle(address(iporRiskManagementOracle))
            .build();

        _iporProtocolFactory.setupUsers(_cfg, ammUsdt);
        _iporProtocolFactory.setupUsers(_cfg, ammDai);

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

        vm.startPrank(_liquidityProvider);
        ammDai.joseph.itfProvideLiquidity(TestConstants.USD_14_000_18DEC, block.timestamp);
        ammUsdt.joseph.itfProvideLiquidity(TestConstants.USD_14_000_6DEC, block.timestamp);

        // when
        ammDai.joseph.itfRedeem(TestConstants.TC_TOTAL_AMOUNT_10_000_18DEC, block.timestamp);
        ammUsdt.joseph.itfRedeem(TestConstants.TC_TOTAL_AMOUNT_10_000_18DEC, block.timestamp);
        vm.stopPrank();

        // then
        IporTypes.MiltonBalancesMemory memory balanceDai = ammDai.milton.getAccruedBalance();
        IporTypes.MiltonBalancesMemory memory balanceUsdt = ammUsdt.milton.getAccruedBalance();

        uint256 actualLiquidityPoolBalanceDai = balanceDai.liquidityPool;
        uint256 actualLiquidityPoolBalanceUsdt = balanceUsdt.liquidityPool;

        assertEq(
            ammDai.ipToken.balanceOf(_liquidityProvider),
            expectedBalancesDai.expectedIpTokenBalance,
            "incorrect ip token balance for DAI"
        );
        assertEq(
            ammDai.asset.balanceOf(address(ammDai.milton)),
            expectedBalancesDai.expectedMiltonBalance,
            "incorrect milton balance for DAI"
        );
        assertEq(
            ammDai.asset.balanceOf(_liquidityProvider),
            expectedBalancesDai.expectedTokenBalance,
            "incorrect token balance for DAI"
        );
        assertEq(actualLiquidityPoolBalanceDai, expectedBalancesDai.expectedLiquidityPoolBalance);

        assertEq(
            ammUsdt.ipToken.balanceOf(_liquidityProvider),
            expectedBalancesUsdt.expectedIpTokenBalance,
            "incorrect ip token balance for USDT"
        );
        assertEq(
            ammUsdt.asset.balanceOf(address(ammUsdt.milton)),
            expectedBalancesUsdt.expectedMiltonBalance,
            "incorrect milton balance for USDT"
        );
        assertEq(
            ammUsdt.asset.balanceOf(_liquidityProvider),
            expectedBalancesUsdt.expectedTokenBalance,
            "incorrect token balance for USDT"
        );
        assertEq(
            actualLiquidityPoolBalanceUsdt,
            expectedBalancesUsdt.expectedLiquidityPoolBalance,
            "incorrect liquidity pool balance for USDT"
        );
    }

    function testShouldRedeemIpDaiAndIpUsdtWhenTwoUsersAndSimpleCase1() public {
        // given
        IporProtocolFactory.Amm memory amm = _iporProtocolFactory.getFullInstance(_ammCfg);

        IporProtocolBuilder.IporProtocol memory ammUsdt = amm.usdt;
        IporProtocolBuilder.IporProtocol memory ammDai = amm.dai;

        _iporProtocolFactory.setupUsers(_cfg, ammUsdt);
        _iporProtocolFactory.setupUsers(_cfg, ammDai);

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

        vm.prank(_userOne);
        ammDai.joseph.itfProvideLiquidity(TestConstants.USD_14_000_18DEC, block.timestamp);

        vm.prank(_userTwo);
        ammUsdt.joseph.itfProvideLiquidity(TestConstants.USD_14_000_6DEC, block.timestamp);

        // when
        vm.prank(_userOne);
        ammDai.joseph.itfRedeem(TestConstants.TC_TOTAL_AMOUNT_10_000_18DEC, block.timestamp);

        vm.prank(_userTwo);
        ammUsdt.joseph.itfRedeem(TestConstants.TC_TOTAL_AMOUNT_10_000_18DEC, block.timestamp);

        // then
        IporTypes.MiltonBalancesMemory memory balanceDai = ammDai.milton.getAccruedBalance();
        IporTypes.MiltonBalancesMemory memory balanceUsdt = ammUsdt.milton.getAccruedBalance();

        uint256 actualLiquidityPoolBalanceDai = balanceDai.liquidityPool;
        uint256 actualLiquidityPoolBalanceUsdt = balanceUsdt.liquidityPool;

        assertEq(
            ammDai.ipToken.balanceOf(_userOne),
            expectedBalancesDai.expectedIpTokenBalance,
            "incorrect ip token balance for DAI"
        );
        assertEq(
            ammDai.asset.balanceOf(address(ammDai.milton)),
            expectedBalancesDai.expectedMiltonBalance,
            "incorrect milton balance for DAI"
        );
        assertEq(
            ammDai.asset.balanceOf(_userOne),
            expectedBalancesDai.expectedTokenBalance,
            "incorrect token balance for DAI"
        );
        assertEq(
            balanceDai.liquidityPool,
            expectedBalancesDai.expectedLiquidityPoolBalance,
            "incorrect liquidity pool balance for DAI"
        );

        assertEq(
            ammUsdt.ipToken.balanceOf(_userTwo),
            expectedBalancesUsdt.expectedIpTokenBalance,
            "incorrect ip token balance for USDT"
        );
        assertEq(
            ammUsdt.asset.balanceOf(address(ammUsdt.milton)),
            expectedBalancesUsdt.expectedMiltonBalance,
            "incorrect milton balance for USDT"
        );
        assertEq(
            ammUsdt.asset.balanceOf(_userTwo),
            expectedBalancesUsdt.expectedTokenBalance,
            "incorrect token balance for USDT"
        );
        assertEq(
            balanceUsdt.liquidityPool,
            expectedBalancesUsdt.expectedLiquidityPoolBalance,
            "incorrect liquidity pool balance for USDT"
        );
    }

    function testShouldRedeemWhenLiquidityProviderCanTransferTokensToAnotherUserAndUserCanRedeemTokens() public {
        // given
        _cfg.miltonTestCase = BuilderUtils.MiltonTestCase.CASE0;
        _iporProtocol = _iporProtocolFactory.getDaiInstance(_cfg);

        uint256 redeemFee = 50 * TestConstants.D18;

        ExpectedJosephBalances memory expectedBalancesLiquidityProvider;
        expectedBalancesLiquidityProvider.expectedIpTokenBalance = 400 * TestConstants.D18;
        expectedBalancesLiquidityProvider.expectedTokenBalance = 9989600 * TestConstants.D18;
        expectedBalancesLiquidityProvider.expectedMiltonBalance = 400 * TestConstants.D18 + redeemFee;
        expectedBalancesLiquidityProvider.expectedLiquidityPoolBalance = 400 * TestConstants.D18 + redeemFee;

        ExpectedJosephBalances memory expectedBalancesUserThree;
        expectedBalancesUserThree.expectedIpTokenBalance = TestConstants.ZERO;
        expectedBalancesUserThree.expectedTokenBalance = 10010000 * TestConstants.D18 - redeemFee;

        vm.startPrank(_liquidityProvider);
        _iporProtocol.joseph.itfProvideLiquidity(TestConstants.USD_10_400_18DEC, block.timestamp);
        _iporProtocol.ipToken.transfer(_userThree, TestConstants.TC_TOTAL_AMOUNT_10_000_18DEC);

        // when
        vm.stopPrank();
        vm.prank(_userThree);
        _iporProtocol.joseph.itfRedeem(TestConstants.TC_TOTAL_AMOUNT_10_000_18DEC, block.timestamp);

        // then
        IporTypes.MiltonBalancesMemory memory balance = _iporProtocol.milton.getAccruedBalance();
        uint256 actualLiquidityPoolBalance = balance.liquidityPool;

        assertEq(
            _iporProtocol.ipToken.balanceOf(_liquidityProvider),
            expectedBalancesLiquidityProvider.expectedIpTokenBalance
        );
        assertEq(
            _iporProtocol.asset.balanceOf(address(_iporProtocol.milton)),
            expectedBalancesLiquidityProvider.expectedMiltonBalance
        );
        assertEq(
            _iporProtocol.asset.balanceOf(_liquidityProvider),
            expectedBalancesLiquidityProvider.expectedTokenBalance
        );
        assertEq(actualLiquidityPoolBalance, expectedBalancesLiquidityProvider.expectedLiquidityPoolBalance);
        assertEq(_iporProtocol.ipToken.balanceOf(_userThree), expectedBalancesUserThree.expectedIpTokenBalance);
        assertEq(_iporProtocol.asset.balanceOf(_userThree), expectedBalancesUserThree.expectedTokenBalance);
    }

    function testShouldRedeemWhenLiquidityPoolUtilizationNotExceededAndPayFixed() public {
        // given
        _cfg.miltonTestCase = BuilderUtils.MiltonTestCase.CASE0;
        _iporProtocol = _iporProtocolFactory.getDaiInstance(_cfg);

        vm.prank(_userOne);
        _iporProtocol.iporOracle.itfUpdateIndex(
            address(_iporProtocol.asset),
            TestConstants.PERCENTAGE_3_18DEC,
            block.timestamp
        );

        vm.prank(_liquidityProvider);
        _iporProtocol.joseph.itfProvideLiquidity(TestConstants.USD_100_000_18DEC, block.timestamp);

        vm.prank(_userTwo);
        _iporProtocol.milton.itfOpenSwapPayFixed(
            block.timestamp,
            27000 * TestConstants.D18,
            9 * TestConstants.D17,
            TestConstants.LEVERAGE_18DEC
        );

        IporTypes.MiltonBalancesMemory memory balance = _iporProtocol.milton.getAccruedBalance();

        uint256 actualCollateral = balance.totalCollateralPayFixed + balance.totalCollateralReceiveFixed;
        uint256 actualLiquidityPoolBalance = balance.liquidityPool;
        uint256 expectedIpTokenBalanceSender = 49000 * TestConstants.D18;

        // when
        vm.prank(_liquidityProvider);
        _iporProtocol.joseph.itfRedeem(51000 * TestConstants.D18, block.timestamp);

        // then

        uint256 actualIpTokenBalanceSender = _iporProtocol.ipToken.balanceOf(_liquidityProvider);
        assertLe(actualCollateral, actualLiquidityPoolBalance);
        assertEq(actualIpTokenBalanceSender, expectedIpTokenBalanceSender);
    }

    function testShouldRedeemWhenLiquidityPoolUtilizationNotExceededAndReceiveFixed() public {
        // given
        _cfg.miltonTestCase = BuilderUtils.MiltonTestCase.CASE0;
        _iporProtocol = _iporProtocolFactory.getDaiInstance(_cfg);

        vm.prank(_userOne);
        _iporProtocol.iporOracle.itfUpdateIndex(
            address(_iporProtocol.asset),
            TestConstants.PERCENTAGE_3_18DEC,
            block.timestamp
        );
        vm.prank(_liquidityProvider);
        _iporProtocol.joseph.itfProvideLiquidity(TestConstants.USD_100_000_18DEC, block.timestamp);
        vm.prank(_userTwo);
        _iporProtocol.milton.itfOpenSwapReceiveFixed(
            block.timestamp,
            40000 * TestConstants.D18,
            TestConstants.D16,
            TestConstants.LEVERAGE_18DEC
        );
        IporTypes.MiltonBalancesMemory memory balance = _iporProtocol.milton.getAccruedBalance();
        uint256 actualCollateral = balance.totalCollateralPayFixed + balance.totalCollateralReceiveFixed;
        uint256 actualLiquidityPoolBalance = balance.liquidityPool;
        uint256 expectedIpTokenBalanceSender = 49000 * TestConstants.D18;
        // when
        vm.prank(_liquidityProvider);
        _iporProtocol.joseph.itfRedeem(51000 * TestConstants.D18, block.timestamp);
        // then
        //this line is not achieved if redeem failed
        uint256 actualIpTokenBalanceSender = _iporProtocol.ipToken.balanceOf(_liquidityProvider);
        assertLe(actualCollateral, actualLiquidityPoolBalance);
        assertEq(actualIpTokenBalanceSender, expectedIpTokenBalanceSender);
    }

    function testShouldRedeemWhenLiquidityPoolUtilizationNotExceededAndNotOpenPayFixedWhenMaxUtilizationExceeded()
        public
    {
        // given
        _cfg.miltonTestCase = BuilderUtils.MiltonTestCase.CASE0;
        _iporProtocol = _iporProtocolFactory.getDaiInstance(_cfg);

        vm.prank(_userOne);
        _iporProtocol.iporOracle.itfUpdateIndex(
            address(_iporProtocol.asset),
            TestConstants.PERCENTAGE_3_18DEC,
            block.timestamp
        );

        vm.prank(_liquidityProvider);
        _iporProtocol.joseph.itfProvideLiquidity(TestConstants.USD_100_000_18DEC, block.timestamp);

        vm.prank(_userTwo);
        _iporProtocol.milton.itfOpenSwapPayFixed(
            block.timestamp,
            48000 * TestConstants.D18,
            9 * TestConstants.D17,
            TestConstants.LEVERAGE_18DEC
        );

        vm.prank(_liquidityProvider);
        _iporProtocol.joseph.itfRedeem(TestConstants.USD_10_000_18DEC, block.timestamp);
        //show that currently liquidity pool utilization for opening position is achieved
        vm.expectRevert("IPOR_303");
        vm.prank(_userTwo);
        _iporProtocol.milton.itfOpenSwapPayFixed(
            block.timestamp,
            50 * TestConstants.D18,
            9 * TestConstants.D17,
            TestConstants.LEVERAGE_18DEC
        );

        uint256 expectedIpTokenBalanceSender = 79700 * TestConstants.D18;

        // when
        vm.prank(_liquidityProvider);
        _iporProtocol.joseph.itfRedeem(10300 * TestConstants.D18, block.timestamp);

        // then
        //this line is not achieved if redeem failed
        uint256 actualIpTokenBalanceSender = _iporProtocol.ipToken.balanceOf(_liquidityProvider);
        assertEq(actualIpTokenBalanceSender, expectedIpTokenBalanceSender);
    }

    function testShouldRedeemWhenLiquidityPoolUtilizationNotExceededAndNotOpenReceiveFixedWhenMaxUtilizationExceeded()
        public
    {
        // given
        _cfg.miltonTestCase = BuilderUtils.MiltonTestCase.CASE0;
        _iporProtocol = _iporProtocolFactory.getDaiInstance(_cfg);

        vm.prank(_userOne);
        _iporProtocol.iporOracle.itfUpdateIndex(
            address(_iporProtocol.asset),
            TestConstants.PERCENTAGE_3_18DEC,
            block.timestamp
        );

        vm.prank(_liquidityProvider);
        _iporProtocol.joseph.itfProvideLiquidity(TestConstants.USD_100_000_18DEC, block.timestamp);

        vm.prank(_userTwo);
        _iporProtocol.milton.itfOpenSwapReceiveFixed(
            block.timestamp,
            48000 * TestConstants.D18,
            TestConstants.D16,
            TestConstants.LEVERAGE_18DEC
        );

        vm.prank(_liquidityProvider);
        _iporProtocol.joseph.itfRedeem(TestConstants.USD_10_000_18DEC, block.timestamp);

        //show that currently liquidity pool utilization for opening position is achieved
        vm.expectRevert("IPOR_303");
        vm.prank(_userTwo);
        _iporProtocol.milton.itfOpenSwapReceiveFixed(
            block.timestamp,
            50 * TestConstants.D18,
            9 * TestConstants.D17,
            TestConstants.LEVERAGE_18DEC
        );

        uint256 expectedIpTokenBalanceSender = 79700 * TestConstants.D18;

        // when
        vm.prank(_liquidityProvider);
        _iporProtocol.joseph.itfRedeem(10300 * TestConstants.D18, block.timestamp);

        // then
        //this line is not achieved if redeem failed
        uint256 actualIpTokenBalanceSender = _iporProtocol.ipToken.balanceOf(_liquidityProvider);
        assertEq(actualIpTokenBalanceSender, expectedIpTokenBalanceSender);
    }
}

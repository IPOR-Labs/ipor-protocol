// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.20;

import "test/TestCommons.sol";
import "../utils/TestConstants.sol";
import "test/mocks/tokens/MockTestnetToken.sol";
import "contracts/tokens/IpToken.sol";
import "contracts/interfaces/types/IporTypes.sol";

contract AmmPoolsServiceRedeemTest is TestCommons {
    IporProtocolFactory.IporProtocolConfig private _cfg;
    IporProtocolFactory.AmmConfig private _ammCfg;
    BuilderUtils.IporProtocol internal _iporProtocol;

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
        _cfg.spread28DaysTestCase = BuilderUtils.Spread28DaysTestCase.CASE5;

        _ammCfg.iporOracleUpdater = _userOne;
        _ammCfg.iporRiskManagementOracleUpdater = _userOne;
    }

    function testShouldRedeemIpToken18DecimalsSimpleCase1() public {
        // given
        _iporProtocol = _iporProtocolFactory.getDaiInstance(_cfg);

        uint256 redeemFee = 50 * TestConstants.D18;

        uint256 expectedIpTokenBalance = 4000 * TestConstants.D18;
        uint256 expectedTokenBalance = 9996000 * TestConstants.D18 - redeemFee;
        uint256 expectedAmmTreasuryBalance = 4000 * TestConstants.D18 + redeemFee;
        uint256 expectedLiquidityPoolBalance = 4000 * TestConstants.D18 + redeemFee;

        vm.startPrank(_liquidityProvider);
        _iporProtocol.ammPoolsService.provideLiquidityDai(_liquidityProvider, TestConstants.USD_14_000_18DEC);

        // when
        _iporProtocol.ammPoolsService.redeemFromAmmPoolDai(
            _liquidityProvider,
            TestConstants.TC_TOTAL_AMOUNT_10_000_18DEC
        );
        vm.stopPrank();

        // then
        IporTypes.AmmBalancesMemory memory balance = _iporProtocol.ammPoolsLens.getAmmBalance(
            address(_iporProtocol.asset)
        );
        uint256 actualLiquidityPoolBalance = balance.liquidityPool;

        assertEq(_iporProtocol.ipToken.balanceOf(_liquidityProvider), expectedIpTokenBalance);
        assertEq(_iporProtocol.asset.balanceOf(address(_iporProtocol.ammTreasury)), expectedAmmTreasuryBalance);
        assertEq(actualLiquidityPoolBalance, expectedLiquidityPoolBalance);
        assertEq(_iporProtocol.asset.balanceOf(_liquidityProvider), expectedTokenBalance);
    }

    function testShouldRedeemIpToken6DecimalsSimpleCase1() public {
        // given
        _iporProtocol = _iporProtocolFactory.getUsdtInstance(_cfg);

        uint256 redeemFee18Dec = 50 * TestConstants.D18;
        uint256 redeemFee6Dec = 50 * TestConstants.N1__0_6DEC;

        uint256 expectedIpTokenBalance = 4000 * TestConstants.D18;
        uint256 expectedTokenBalance = 9996000 * TestConstants.N1__0_6DEC - redeemFee6Dec;
        uint256 expectedAmmTreasuryBalance = 4000 * TestConstants.N1__0_6DEC + redeemFee6Dec;
        uint256 expectedLiquidityPoolBalance = 4000 * TestConstants.D18 + redeemFee18Dec;

        vm.startPrank(_liquidityProvider);
        _iporProtocol.ammPoolsService.provideLiquidityUsdt(_liquidityProvider, TestConstants.USD_14_000_6DEC);

        // when
        _iporProtocol.ammPoolsService.redeemFromAmmPoolUsdt(
            _liquidityProvider,
            TestConstants.TC_TOTAL_AMOUNT_10_000_18DEC
        );
        vm.stopPrank();

        // then
        IporTypes.AmmBalancesMemory memory balance = _iporProtocol.ammPoolsLens.getAmmBalance(
            address(_iporProtocol.asset)
        );
        uint256 actualLiquidityPoolBalance = balance.liquidityPool;

        assertEq(_iporProtocol.ipToken.balanceOf(_liquidityProvider), expectedIpTokenBalance);
        assertEq(_iporProtocol.asset.balanceOf(address(_iporProtocol.ammTreasury)), expectedAmmTreasuryBalance);
        assertEq(actualLiquidityPoolBalance, expectedLiquidityPoolBalance);
        assertEq(_iporProtocol.asset.balanceOf(_liquidityProvider), expectedTokenBalance);
    }

    function testShouldRedeemIpTokensWhenTwoTimesProvidedLiquidity() public {
        // given
        _iporProtocol = _iporProtocolFactory.getDaiInstance(_cfg);

        uint256 redeemFee = 70 * TestConstants.D18;

        uint256 expectedIpTokenBalance = 6000 * TestConstants.D18;
        uint256 expectedTokenBalance = 9994000 * TestConstants.D18 - redeemFee;
        uint256 expectedAmmTreasuryBalance = 6000 * TestConstants.D18 + redeemFee;
        uint256 expectedLiquidityPoolBalance = 6000 * TestConstants.D18 + redeemFee;

        vm.startPrank(_liquidityProvider);
        _iporProtocol.ammPoolsService.provideLiquidityDai(
            _liquidityProvider,
            TestConstants.TC_TOTAL_AMOUNT_10_000_18DEC
        );
        _iporProtocol.ammPoolsService.provideLiquidityDai(
            _liquidityProvider,
            TestConstants.TC_TOTAL_AMOUNT_10_000_18DEC
        );

        // when
        _iporProtocol.ammPoolsService.redeemFromAmmPoolDai(_liquidityProvider, TestConstants.USD_14_000_18DEC);
        vm.stopPrank();

        // then
        IporTypes.AmmBalancesMemory memory balance = _iporProtocol.ammPoolsLens.getAmmBalance(
            address(_iporProtocol.asset)
        );
        uint256 actualLiquidityPoolBalance = balance.liquidityPool;

        assertEq(_iporProtocol.ipToken.balanceOf(_liquidityProvider), expectedIpTokenBalance);
        assertEq(_iporProtocol.asset.balanceOf(address(_iporProtocol.ammTreasury)), expectedAmmTreasuryBalance);
        assertEq(_iporProtocol.asset.balanceOf(_liquidityProvider), expectedTokenBalance);
        assertEq(actualLiquidityPoolBalance, expectedLiquidityPoolBalance);
    }

    function testShouldRedeemIpDaiAndIpUsdtWhenSimpleCase1() public {
        // given
        IporProtocolFactory.Amm memory amm = _iporProtocolFactory.getFullInstance(_ammCfg);

        _iporProtocolFactory.setupUsers(_cfg, amm.usdt);
        _iporProtocolFactory.setupUsers(_cfg, amm.dai);

        uint256 redeemFee18Dec = 50 * TestConstants.D18;
        uint256 redeemFee6Dec = 50 * TestConstants.N1__0_6DEC;

        uint256 expectedIpTokenBalance = 4000 * TestConstants.D18;
        uint256 expectedTokenBalanceDai = 9996000 * TestConstants.D18 - redeemFee18Dec;
        uint256 expectedAmmTreasuryBalanceDai = 4000 * TestConstants.D18 + redeemFee18Dec;
        uint256 expectedLiquidityPoolBalance = 4000 * TestConstants.D18 + redeemFee18Dec;

        uint256 expectedTokenBalanceUsdt = 9996000 * TestConstants.N1__0_6DEC - redeemFee6Dec;
        uint256 expectedAmmTreasuryBalanceUsdt = 4000 * TestConstants.N1__0_6DEC + redeemFee6Dec;

        vm.startPrank(_liquidityProvider);
        amm.dai.ammPoolsService.provideLiquidityDai(_liquidityProvider, TestConstants.USD_14_000_18DEC);
        amm.usdt.ammPoolsService.provideLiquidityUsdt(_liquidityProvider, TestConstants.USD_14_000_6DEC);

        // when
        amm.dai.ammPoolsService.redeemFromAmmPoolDai(_liquidityProvider, TestConstants.TC_TOTAL_AMOUNT_10_000_18DEC);
        amm.usdt.ammPoolsService.redeemFromAmmPoolUsdt(_liquidityProvider, TestConstants.TC_TOTAL_AMOUNT_10_000_18DEC);
        vm.stopPrank();

        // then
        IporTypes.AmmBalancesMemory memory balanceDai = amm.dai.ammPoolsLens.getAmmBalance(address(amm.dai.asset));
        IporTypes.AmmBalancesMemory memory balanceUsdt = amm.usdt.ammPoolsLens.getAmmBalance(address(amm.usdt.asset));

        uint256 actualLiquidityPoolBalanceDai = balanceDai.liquidityPool;
        uint256 actualLiquidityPoolBalanceUsdt = balanceUsdt.liquidityPool;

        assertEq(
            amm.dai.ipToken.balanceOf(_liquidityProvider),
            expectedIpTokenBalance,
            "incorrect ip token balance for DAI"
        );
        assertEq(
            amm.dai.asset.balanceOf(address(amm.dai.ammTreasury)),
            expectedAmmTreasuryBalanceDai,
            "incorrect ammTreasury balance for DAI"
        );
        assertEq(
            amm.dai.asset.balanceOf(_liquidityProvider),
            expectedTokenBalanceDai,
            "incorrect token balance for DAI"
        );
        assertEq(actualLiquidityPoolBalanceDai, expectedLiquidityPoolBalance);

        assertEq(
            amm.usdt.ipToken.balanceOf(_liquidityProvider),
            expectedIpTokenBalance,
            "incorrect ip token balance for USDT"
        );
        assertEq(
            amm.usdt.asset.balanceOf(address(amm.usdt.ammTreasury)),
            expectedAmmTreasuryBalanceUsdt,
            "incorrect ammTreasury balance for USDT"
        );
        assertEq(
            amm.usdt.asset.balanceOf(_liquidityProvider),
            expectedTokenBalanceUsdt,
            "incorrect token balance for USDT"
        );
        assertEq(
            actualLiquidityPoolBalanceUsdt,
            expectedLiquidityPoolBalance,
            "incorrect liquidity pool balance for USDT"
        );
    }

    function testShouldRedeemIpDaiAndIpUsdtWhenTwoUsersAndSimpleCase1() public {
        // given
        IporProtocolFactory.Amm memory amm = _iporProtocolFactory.getFullInstance(_ammCfg);

        BuilderUtils.IporProtocol memory ammUsdt = amm.usdt;
        BuilderUtils.IporProtocol memory ammDai = amm.dai;

        _iporProtocolFactory.setupUsers(_cfg, ammUsdt);
        _iporProtocolFactory.setupUsers(_cfg, ammDai);

        uint256 redeemFee18Dec = 50 * TestConstants.D18;
        uint256 redeemFee6Dec = 50 * TestConstants.N1__0_6DEC;

        uint256 expectedIpTokenBalance = 4000 * TestConstants.D18;
        uint256 expectedTokenBalanceDai = 9996000 * TestConstants.D18 - redeemFee18Dec;
        uint256 expectedAmmTreasuryBalanceDai = 4000 * TestConstants.D18 + redeemFee18Dec;
        uint256 expectedLiquidityPoolBalance = 4000 * TestConstants.D18 + redeemFee18Dec;

        uint256 expectedTokenBalanceUsdt = 9996000 * TestConstants.N1__0_6DEC - redeemFee6Dec;
        uint256 expectedAmmTreasuryBalanceUsdt = 4000 * TestConstants.N1__0_6DEC + redeemFee6Dec;

        vm.prank(_userOne);
        ammDai.ammPoolsService.provideLiquidityDai(_userOne, TestConstants.USD_14_000_18DEC);

        vm.prank(_userTwo);
        ammUsdt.ammPoolsService.provideLiquidityUsdt(_userTwo, TestConstants.USD_14_000_6DEC);

        // when
        vm.prank(_userOne);
        ammDai.ammPoolsService.redeemFromAmmPoolDai(_userOne, TestConstants.TC_TOTAL_AMOUNT_10_000_18DEC);

        vm.prank(_userTwo);
        ammUsdt.ammPoolsService.redeemFromAmmPoolUsdt(_userTwo, TestConstants.TC_TOTAL_AMOUNT_10_000_18DEC);

        // then
        IporTypes.AmmBalancesMemory memory balanceDai = ammDai.ammPoolsLens.getAmmBalance(address(amm.dai.asset));
        IporTypes.AmmBalancesMemory memory balanceUsdt = ammUsdt.ammPoolsLens.getAmmBalance(address(amm.usdt.asset));

        assertEq(ammDai.ipToken.balanceOf(_userOne), expectedIpTokenBalance, "incorrect ip token balance for DAI");
        assertEq(
            ammDai.asset.balanceOf(address(ammDai.ammTreasury)),
            expectedAmmTreasuryBalanceDai,
            "incorrect ammTreasury balance for DAI"
        );
        assertEq(ammDai.asset.balanceOf(_userOne), expectedTokenBalanceDai, "incorrect token balance for DAI");
        assertEq(balanceDai.liquidityPool, expectedLiquidityPoolBalance, "incorrect liquidity pool balance for DAI");

        assertEq(ammUsdt.ipToken.balanceOf(_userTwo), expectedIpTokenBalance, "incorrect ip token balance for USDT");
        assertEq(
            ammUsdt.asset.balanceOf(address(ammUsdt.ammTreasury)),
            expectedAmmTreasuryBalanceUsdt,
            "incorrect ammTreasury balance for USDT"
        );
        assertEq(ammUsdt.asset.balanceOf(_userTwo), expectedTokenBalanceUsdt, "incorrect token balance for USDT");
        assertEq(balanceUsdt.liquidityPool, expectedLiquidityPoolBalance, "incorrect liquidity pool balance for USDT");
    }

    function testShouldRedeemWhenLiquidityProviderCanTransferTokensToAnotherUserAndUserCanRedeemTokens() public {
        // given
        _iporProtocol = _iporProtocolFactory.getDaiInstance(_cfg);

        uint256 redeemFee = 50 * TestConstants.D18;

        uint256 expectedIpTokenBalance = 400 * TestConstants.D18;
        uint256 expectedTokenBalance = 9989600 * TestConstants.D18;
        uint256 expectedAmmTreasuryBalance = 400 * TestConstants.D18 + redeemFee;
        uint256 expectedLiquidityPoolBalance = 400 * TestConstants.D18 + redeemFee;

        uint256 expectedIpTokenBalanceUserThree = TestConstants.ZERO;
        uint256 expectedTokenBalanceUserThree = 10010000 * TestConstants.D18 - redeemFee;

        vm.startPrank(_liquidityProvider);
        _iporProtocol.ammPoolsService.provideLiquidityDai(_liquidityProvider, TestConstants.USD_10_400_18DEC);
        _iporProtocol.ipToken.transfer(_userThree, TestConstants.TC_TOTAL_AMOUNT_10_000_18DEC);
        vm.stopPrank();

        // when
        vm.prank(_userThree);
        _iporProtocol.ammPoolsService.redeemFromAmmPoolDai(_userThree, TestConstants.TC_TOTAL_AMOUNT_10_000_18DEC);

        // then
        IporTypes.AmmBalancesMemory memory balance = _iporProtocol.ammPoolsLens.getAmmBalance(
            address(_iporProtocol.asset)
        );
        uint256 actualLiquidityPoolBalance = balance.liquidityPool;

        assertEq(_iporProtocol.ipToken.balanceOf(_liquidityProvider), expectedIpTokenBalance);
        assertEq(_iporProtocol.asset.balanceOf(address(_iporProtocol.ammTreasury)), expectedAmmTreasuryBalance);
        assertEq(_iporProtocol.asset.balanceOf(_liquidityProvider), expectedTokenBalance);
        assertEq(actualLiquidityPoolBalance, expectedLiquidityPoolBalance);
        assertEq(_iporProtocol.ipToken.balanceOf(_userThree), expectedIpTokenBalanceUserThree);
        assertEq(_iporProtocol.asset.balanceOf(_userThree), expectedTokenBalanceUserThree);
    }

    function testShouldRedeemWhenLiquidityPoolCollateralRatioNotExceededAndPayFixed() public {
        // given
        _iporProtocol = _iporProtocolFactory.getDaiInstance(_cfg);

        vm.prank(_userOne);
        _iporProtocol.iporOracle.updateIndex(address(_iporProtocol.asset), TestConstants.PERCENTAGE_3_18DEC);

        vm.prank(_liquidityProvider);
        _iporProtocol.ammPoolsService.provideLiquidityDai(_liquidityProvider, TestConstants.USD_100_000_18DEC);

        vm.prank(_userTwo);
        _iporProtocol.ammOpenSwapService.openSwapPayFixed28daysDai(
            _userTwo,
            27000 * TestConstants.D18,
            9 * TestConstants.D17,
            TestConstants.LEVERAGE_18DEC
        );

        IporTypes.AmmBalancesMemory memory balance = _iporProtocol.ammPoolsLens.getAmmBalance(
            address(_iporProtocol.asset)
        );

        uint256 actualCollateral = balance.totalCollateralPayFixed + balance.totalCollateralReceiveFixed;
        uint256 actualLiquidityPoolBalance = balance.liquidityPool;
        uint256 expectedIpTokenBalanceSender = 49000 * TestConstants.D18;

        // when
        vm.prank(_liquidityProvider);
        _iporProtocol.ammPoolsService.redeemFromAmmPoolDai(_liquidityProvider, 51000 * TestConstants.D18);

        // then

        uint256 actualIpTokenBalanceSender = _iporProtocol.ipToken.balanceOf(_liquidityProvider);
        assertLe(actualCollateral, actualLiquidityPoolBalance);
        assertEq(actualIpTokenBalanceSender, expectedIpTokenBalanceSender);
    }

    function testShouldRedeemWhenLiquidityPoolCollateralRatioNotExceededAndReceiveFixed() public {
        // given
        _iporProtocol = _iporProtocolFactory.getDaiInstance(_cfg);

        vm.prank(_userOne);
        _iporProtocol.iporOracle.updateIndex(address(_iporProtocol.asset), TestConstants.PERCENTAGE_3_18DEC);

        vm.prank(_liquidityProvider);
        _iporProtocol.ammPoolsService.provideLiquidityDai(_liquidityProvider, TestConstants.USD_100_000_18DEC);

        vm.prank(_userTwo);
        _iporProtocol.ammOpenSwapService.openSwapReceiveFixed28daysDai(
            _userTwo,
            40000 * TestConstants.D18,
            TestConstants.D16,
            TestConstants.LEVERAGE_18DEC
        );

        IporTypes.AmmBalancesMemory memory balance = _iporProtocol.ammPoolsLens.getAmmBalance(
            address(_iporProtocol.asset)
        );
        uint256 actualCollateral = balance.totalCollateralPayFixed + balance.totalCollateralReceiveFixed;
        uint256 actualLiquidityPoolBalance = balance.liquidityPool;
        uint256 expectedIpTokenBalanceSender = 49000 * TestConstants.D18;

        // when
        vm.prank(_liquidityProvider);
        _iporProtocol.ammPoolsService.redeemFromAmmPoolDai(_liquidityProvider, 51000 * TestConstants.D18);

        // then
        //this line is not achieved if redeem failed
        uint256 actualIpTokenBalanceSender = _iporProtocol.ipToken.balanceOf(_liquidityProvider);
        assertLe(actualCollateral, actualLiquidityPoolBalance);
        assertEq(actualIpTokenBalanceSender, expectedIpTokenBalanceSender);
    }

    function testShouldRedeemWhenLiquidityPoolCollateralRatioNotExceededAndNotOpenPayFixedWhenMaxCollateralRatioExceeded()
        public
    {
        // given
        _iporProtocol = _iporProtocolFactory.getDaiInstance(_cfg);

        vm.prank(_userOne);
        _iporProtocol.iporOracle.updateIndex(address(_iporProtocol.asset), TestConstants.PERCENTAGE_3_18DEC);

        vm.prank(_liquidityProvider);
        _iporProtocol.ammPoolsService.provideLiquidityDai(_liquidityProvider, TestConstants.USD_100_000_18DEC);

        vm.prank(_userTwo);
        _iporProtocol.ammOpenSwapService.openSwapPayFixed28daysDai(
            _userTwo,
            48000 * TestConstants.D18,
            9 * TestConstants.D17,
            TestConstants.LEVERAGE_18DEC
        );

        vm.prank(_liquidityProvider);
        _iporProtocol.ammPoolsService.redeemFromAmmPoolDai(_liquidityProvider, TestConstants.USD_10_000_18DEC);

        //show that currently liquidity pool collateral ratio for opening position is achieved
        vm.expectRevert("IPOR_303");
        vm.prank(_userTwo);
        _iporProtocol.ammOpenSwapService.openSwapPayFixed28daysDai(
            _userTwo,
            50 * TestConstants.D18,
            9 * TestConstants.D17,
            TestConstants.LEVERAGE_18DEC
        );

        uint256 expectedIpTokenBalanceSender = 79700 * TestConstants.D18;

        // when
        vm.prank(_liquidityProvider);
        _iporProtocol.ammPoolsService.redeemFromAmmPoolDai(_liquidityProvider, 10300 * TestConstants.D18);

        // then
        //this line is not achieved if redeem failed
        uint256 actualIpTokenBalanceSender = _iporProtocol.ipToken.balanceOf(_liquidityProvider);
        assertEq(actualIpTokenBalanceSender, expectedIpTokenBalanceSender);
    }

    function testShouldRedeemWhenLiquidityPoolCollateralRatioNotExceededAndNotOpenReceiveFixedWhenMaxCollateralRatioExceeded()
        public
    {
        // given
        _iporProtocol = _iporProtocolFactory.getDaiInstance(_cfg);

        vm.prank(_userOne);
        _iporProtocol.iporOracle.updateIndex(address(_iporProtocol.asset), TestConstants.PERCENTAGE_3_18DEC);

        vm.prank(_liquidityProvider);
        _iporProtocol.ammPoolsService.provideLiquidityDai(_liquidityProvider, TestConstants.USD_100_000_18DEC);

        vm.prank(_userTwo);
        _iporProtocol.ammOpenSwapService.openSwapReceiveFixed28daysDai(
            _userTwo,
            48000 * TestConstants.D18,
            TestConstants.D16,
            TestConstants.LEVERAGE_18DEC
        );

        vm.prank(_liquidityProvider);
        _iporProtocol.ammPoolsService.redeemFromAmmPoolDai(_liquidityProvider, TestConstants.USD_10_000_18DEC);

        //show that currently liquidity pool collateral ratio for opening position is achieved
        vm.expectRevert("IPOR_303");
        vm.prank(_userTwo);
        _iporProtocol.ammOpenSwapService.openSwapReceiveFixed28daysDai(
            _userTwo,
            50 * TestConstants.D18,
            9 * TestConstants.D17,
            TestConstants.LEVERAGE_18DEC
        );

        uint256 expectedIpTokenBalanceSender = 79700 * TestConstants.D18;

        // when
        vm.prank(_liquidityProvider);
        _iporProtocol.ammPoolsService.redeemFromAmmPoolDai(_liquidityProvider, 10300 * TestConstants.D18);

        // then
        //this line is not achieved if redeem failed
        uint256 actualIpTokenBalanceSender = _iporProtocol.ipToken.balanceOf(_liquidityProvider);
        assertEq(actualIpTokenBalanceSender, expectedIpTokenBalanceSender);
    }
}

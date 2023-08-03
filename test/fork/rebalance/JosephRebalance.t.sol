// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.16;

import "forge-std/Test.sol";
import "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import "../../TestCommons.sol";
import "../DaiAmm.sol";
import "../UsdcAmm.sol";
import "../UsdtAmm.sol";


contract JosephRebalance is Test, TestCommons {
    event Burn(address indexed account, uint256 amount);

    function testRebalanceAndDepositDaiIntoVaultAAVE() public {
        // given
        address user = _getUserAddress(1);
        uint256 depositAmount = 50_000e18;
        DaiAmm daiAmm = new DaiAmm(address(this));
        Joseph joseph = daiAmm.joseph();

        joseph.setAutoRebalanceThreshold(0);
        deal(daiAmm.dai(), user, 500_000e18);
        daiAmm.approveMiltonJoseph(user);

        vm.prank(user);
        joseph.provideLiquidity(depositAmount);
        daiAmm.overrideCompoundStrategyWithZeroApr(address(this));
        uint256 balanceMiltonDaiBefore = IIpToken(daiAmm.dai()).balanceOf(address(daiAmm.milton()));
        uint256 balanceMiltonIvDaiBefore = ERC20(daiAmm.ivDai()).balanceOf(
            address(daiAmm.milton())
        );
        uint256 balanceAaveStrategyBefore = daiAmm.strategyAave().balanceOf();

        // when
        joseph.rebalance();

        //then
        uint256 balanceMiltonDaiAfter = IIpToken(daiAmm.dai()).balanceOf(address(daiAmm.milton()));
        uint256 balanceMiltonIvDaiAfter = ERC20(daiAmm.ivDai()).balanceOf(address(daiAmm.milton()));
        uint256 balanceAaveStrategyAfter = daiAmm.strategyAave().balanceOf();

        assertTrue(balanceMiltonDaiBefore > balanceMiltonDaiAfter);
        assertTrue(balanceMiltonIvDaiBefore < balanceMiltonIvDaiAfter);
        assertTrue(balanceAaveStrategyBefore < balanceAaveStrategyAfter);
    }

    function testShouldSetNewAaveStrategyAndRebalanceAndDepositDaiIntoVaultAave() public {
        // given
        address user = _getUserAddress(1);
        uint256 depositAmount = 10_000e18;
        DaiAmm daiAmm = new DaiAmm(address(this));
        Joseph joseph = daiAmm.joseph();
        Stanley stanley = daiAmm.stanley();

        joseph.setAutoRebalanceThreshold(0);
        deal(daiAmm.dai(), user, 500_000e18);
        daiAmm.approveMiltonJoseph(user);

        vm.prank(user);
        joseph.provideLiquidity(depositAmount);
        daiAmm.overrideCompoundStrategyWithZeroApr(address(this));
        uint256 balanceMiltonDaiBefore = IIpToken(daiAmm.dai()).balanceOf(address(daiAmm.milton()));
        joseph.rebalance();
        StrategyAave newStrategyAave = daiAmm.createAaveStrategy();

        uint256 balanceOldAaveStrategyBefore = daiAmm.strategyAave().balanceOf();
        uint256 balanceNewAaveStrategyBefore = newStrategyAave.balanceOf();
        uint256 balanceMiltonIvDaiBefore = ERC20(daiAmm.ivDai()).balanceOf(
            address(daiAmm.milton())
        );

        // when
        stanley.setStrategyAave(address(newStrategyAave));
        uint256 balanceOldAaveStrategyAfterSwitch = daiAmm.strategyAave().balanceOf();
        uint256 balanceNewAaveStrategyAfterSwitch = newStrategyAave.balanceOf();

        vm.prank(user);
        joseph.provideLiquidity(depositAmount);

        joseph.rebalance();

        // then

        uint256 balanceMiltonIvDaiAfterRebalance = ERC20(daiAmm.ivDai()).balanceOf(
            address(daiAmm.milton())
        );
        uint256 balanceMiltonDaiAfterRebalance = IIpToken(daiAmm.dai()).balanceOf(
            address(daiAmm.milton())
        );
        uint256 balanceOldAaveStrategyAfterRebalance = daiAmm.strategyAave().balanceOf();
        uint256 balanceNewAaveStrategyAfterRebalance = newStrategyAave.balanceOf();

        assertTrue(balanceOldAaveStrategyBefore > 0);
        assertEq(balanceNewAaveStrategyBefore, 0);
        assertEq(balanceOldAaveStrategyAfterSwitch, 0);
        assertEq(balanceOldAaveStrategyBefore, balanceNewAaveStrategyAfterSwitch);
        assertEq(balanceOldAaveStrategyAfterRebalance, 0);
        assertTrue(balanceNewAaveStrategyAfterRebalance > 0);
        assertTrue(balanceMiltonIvDaiBefore < balanceMiltonIvDaiAfterRebalance);
    }

    function testShouldRebalanceAndWithdrawDaiFromStanleyAndAave() public {
        // given
        address user = _getUserAddress(1);
        uint256 depositAmount = 50_000e18;
        DaiAmm daiAmm = new DaiAmm(address(this));
        Joseph joseph = daiAmm.joseph();

        joseph.setAutoRebalanceThreshold(0);
        deal(daiAmm.dai(), user, 500_000e18);
        daiAmm.approveMiltonJoseph(user);

        vm.prank(user);
        joseph.provideLiquidity(depositAmount);
        daiAmm.overrideCompoundStrategyWithZeroApr(address(this));
        joseph.rebalance();
        vm.prank(user);
        joseph.redeem(15_000e18);
        uint256 balanceMiltonDaiBefore = IIpToken(daiAmm.dai()).balanceOf(address(daiAmm.milton()));
        uint256 balanceMiltonIvDaiBefore = ERC20(daiAmm.ivDai()).balanceOf(
            address(daiAmm.milton())
        );
        uint256 balanceAaveStrategyBefore = daiAmm.strategyAave().balanceOf();

        // when

        vm.warp(block.timestamp + 60);
        joseph.rebalance();

        // then
        uint256 balanceMiltonDaiAfter = IIpToken(daiAmm.dai()).balanceOf(address(daiAmm.milton()));
        uint256 balanceMiltonIvDaiAfter = ERC20(daiAmm.ivDai()).balanceOf(address(daiAmm.milton()));
        uint256 balanceAaveStrategyAfter = daiAmm.strategyAave().balanceOf();

        assertTrue(
            balanceMiltonDaiBefore < balanceMiltonDaiAfter,
            "balanceMiltonDaiBefore < balanceMiltonDaiAfter"
        );
        assertTrue(
            balanceMiltonIvDaiBefore > balanceMiltonIvDaiAfter,
            "balanceMiltonIvDaiBefore > balanceMiltonIvDaiAfter"
        );
        assertTrue(
            balanceAaveStrategyBefore > balanceAaveStrategyAfter,
            "balanceAaveStrategyBefore > balanceAaveStrategyAfter"
        );
    }

    function testShouldRebalanceAndDepositUsdcIntoVaultAAVE() public {
        // given
        address user = _getUserAddress(1);
        uint256 depositAmount = 50_000e6;
        UsdcAmm usdcAmm = new UsdcAmm(address(this));
        Joseph joseph = usdcAmm.joseph();

        joseph.setAutoRebalanceThreshold(0);
        deal(usdcAmm.usdc(), user, 500_000e6);
        usdcAmm.approveMiltonJoseph(user);

        vm.prank(user);
        joseph.provideLiquidity(depositAmount);
        usdcAmm.overrideCompoundStrategyWithZeroApr(address(this));
        uint256 balanceMiltonBefore = IIpToken(usdcAmm.usdc()).balanceOf(address(usdcAmm.milton()));
        uint256 balanceMiltonIvBefore = ERC20(usdcAmm.ivUsdc()).balanceOf(
            address(usdcAmm.milton())
        );
        uint256 balanceAaveStrategyBefore = usdcAmm.strategyAave().balanceOf();

        // when
        joseph.rebalance();

        //then
        uint256 balanceMiltonAfter = IIpToken(usdcAmm.usdc()).balanceOf(address(usdcAmm.milton()));
        uint256 balanceMiltonIvAfter = ERC20(usdcAmm.ivUsdc()).balanceOf(address(usdcAmm.milton()));
        uint256 balanceAaveStrategyAfter = usdcAmm.strategyAave().balanceOf();

        assertTrue(balanceMiltonBefore > balanceMiltonAfter);
        assertTrue(balanceMiltonIvBefore < balanceMiltonIvAfter);
        assertTrue(balanceAaveStrategyBefore < balanceAaveStrategyAfter);
    }

	//TODO: temporary skipped
    function skipTestShouldNotChangeJosephExchangeRateWhenWithdrawAllFromStanley() public {
        // given
        address user = _getUserAddress(1);
        uint256 depositAmount = 50_000e6;
        UsdcAmm usdcAmm = new UsdcAmm(address(this));
        Joseph joseph = usdcAmm.joseph();

        joseph.setAutoRebalanceThreshold(0);
        deal(usdcAmm.usdc(), user, 500_000e6);
        usdcAmm.approveMiltonJoseph(user);

        vm.prank(user);
        joseph.provideLiquidity(depositAmount);
        usdcAmm.overrideCompoundStrategyWithZeroApr(address(this));
        joseph.rebalance();

        uint256 balanceMiltonBefore = IIpToken(usdcAmm.usdc()).balanceOf(address(usdcAmm.milton()));
        uint256 balanceMiltonIvBefore = ERC20(usdcAmm.ivUsdc()).balanceOf(
            address(usdcAmm.milton())
        );
        uint256 balanceAaveStrategyBefore = usdcAmm.strategyAave().balanceOf();
        uint256 exchangeRateJosephBefore = joseph.calculateExchangeRate();

        // when
        joseph.withdrawAllFromStanley();

        //then
        uint256 exchangeRateJosephAfter = joseph.calculateExchangeRate();
        uint256 balanceMiltonAfter = IIpToken(usdcAmm.usdc()).balanceOf(address(usdcAmm.milton()));
        uint256 balanceMiltonIvAfter = ERC20(usdcAmm.ivUsdc()).balanceOf(address(usdcAmm.milton()));
        uint256 balanceAaveStrategyAfter = usdcAmm.strategyAave().balanceOf();

        assertEq(exchangeRateJosephBefore, exchangeRateJosephAfter);
        assertTrue(balanceMiltonBefore < balanceMiltonAfter);
        assertTrue(balanceMiltonIvBefore > balanceMiltonIvAfter);
        assertTrue(balanceAaveStrategyBefore > balanceAaveStrategyAfter);
    }

	//TODO: temporary skipped
    function skipTestShouldNotChangeJosephExchangeRateWhenWithdrawFromStanley() public {
        // given
        address user = _getUserAddress(1);
        uint256 depositAmount = 50_000e6;
        UsdcAmm usdcAmm = new UsdcAmm(address(this));
        Joseph joseph = usdcAmm.joseph();

        joseph.setAutoRebalanceThreshold(0);
        deal(usdcAmm.usdc(), user, 500_000e6);
        usdcAmm.approveMiltonJoseph(user);

        vm.prank(user);
        joseph.provideLiquidity(depositAmount);
        usdcAmm.overrideCompoundStrategyWithZeroApr(address(this));
        joseph.rebalance();

        uint256 balanceMiltonBefore = IIpToken(usdcAmm.usdc()).balanceOf(address(usdcAmm.milton()));
        uint256 balanceMiltonIvBefore = ERC20(usdcAmm.ivUsdc()).balanceOf(
            address(usdcAmm.milton())
        );
        uint256 balanceAaveStrategyBefore = usdcAmm.strategyAave().balanceOf();
        uint256 exchangeRateJosephBefore = joseph.calculateExchangeRate();

        // when
        joseph.withdrawFromStanley(74e20);

        //then
        uint256 exchangeRateJosephAfter = joseph.calculateExchangeRate();
        uint256 balanceMiltonAfter = IIpToken(usdcAmm.usdc()).balanceOf(address(usdcAmm.milton()));
        uint256 balanceMiltonIvAfter = ERC20(usdcAmm.ivUsdc()).balanceOf(address(usdcAmm.milton()));
        uint256 balanceAaveStrategyAfter = usdcAmm.strategyAave().balanceOf();

        assertEq(exchangeRateJosephBefore, exchangeRateJosephAfter);
        assertTrue(balanceMiltonBefore < balanceMiltonAfter);
        assertTrue(balanceMiltonIvBefore > balanceMiltonIvAfter);
        assertTrue(balanceAaveStrategyBefore > balanceAaveStrategyAfter);
    }

    function testShouldSetNewAaveStrategyAndRebalanceAndDepositUsdcIntoVaultAave() public {
        // given
        address user = _getUserAddress(1);
        uint256 depositAmount = 10_000e6;
        UsdcAmm usdcAmm = new UsdcAmm(address(this));
        Joseph joseph = usdcAmm.joseph();
        Stanley stanley = usdcAmm.stanley();

        joseph.setAutoRebalanceThreshold(0);
        deal(usdcAmm.usdc(), user, 500_000e6);
        usdcAmm.approveMiltonJoseph(user);

        vm.prank(user);
        joseph.provideLiquidity(depositAmount);
        usdcAmm.overrideCompoundStrategyWithZeroApr(address(this));
        uint256 balanceMiltonBefore = IIpToken(usdcAmm.usdc()).balanceOf(address(usdcAmm.milton()));
        joseph.rebalance();
        StrategyAave newStrategyAave = usdcAmm.createAaveStrategy();

        uint256 balanceOldAaveStrategyBefore = usdcAmm.strategyAave().balanceOf();
        uint256 balanceNewAaveStrategyBefore = newStrategyAave.balanceOf();
        uint256 balanceMiltonIvBefore = ERC20(usdcAmm.ivUsdc()).balanceOf(
            address(usdcAmm.milton())
        );

        // when
        stanley.setStrategyAave(address(newStrategyAave));
        uint256 balanceOldAaveStrategyAfterSwitch = usdcAmm.strategyAave().balanceOf();
        uint256 balanceNewAaveStrategyAfterSwitch = newStrategyAave.balanceOf();

        vm.prank(user);
        joseph.provideLiquidity(depositAmount);

        vm.warp(block.timestamp + 1 days);
        joseph.rebalance();

        // then

        uint256 balanceMiltonIvAfterRebalance = ERC20(usdcAmm.ivUsdc()).balanceOf(
            address(usdcAmm.milton())
        );
        uint256 balanceMiltonAfterRebalance = IIpToken(usdcAmm.usdc()).balanceOf(
            address(usdcAmm.milton())
        );
        uint256 balanceOldAaveStrategyAfterRebalance = usdcAmm.strategyAave().balanceOf();
        uint256 balanceNewAaveStrategyAfterRebalance = newStrategyAave.balanceOf();

        assertTrue(balanceOldAaveStrategyBefore > 0);
        assertEq(balanceNewAaveStrategyBefore, 0);
        assertEq(balanceOldAaveStrategyAfterSwitch, 0);
        assertEq(balanceOldAaveStrategyBefore, balanceNewAaveStrategyAfterSwitch);
        assertEq(balanceOldAaveStrategyAfterRebalance, 0);
        assertTrue(balanceNewAaveStrategyAfterRebalance > 0);
        assertTrue(balanceMiltonIvBefore < balanceMiltonIvAfterRebalance);
    }

    function testShouldRebalanceAndWithdrawUsdcFromStanleyAndAave() public {
        // given
        address user = _getUserAddress(1);
        uint256 depositAmount = 50_000e6;
        UsdcAmm usdcAmm = new UsdcAmm(address(this));
        Joseph joseph = usdcAmm.joseph();

        joseph.setAutoRebalanceThreshold(0);
        deal(usdcAmm.usdc(), user, 500_000e6);
        usdcAmm.approveMiltonJoseph(user);

        vm.prank(user);
        joseph.provideLiquidity(depositAmount);
        usdcAmm.overrideCompoundStrategyWithZeroApr(address(this));
        joseph.rebalance();
        vm.prank(user);
        joseph.redeem(17_000e18);
        uint256 balanceMiltonBefore = IIpToken(usdcAmm.usdc()).balanceOf(address(usdcAmm.milton()));
        uint256 balanceMiltonIvBefore = ERC20(usdcAmm.ivUsdc()).balanceOf(
            address(usdcAmm.milton())
        );
        uint256 balanceAaveStrategyBefore = usdcAmm.strategyAave().balanceOf();

        // when

        vm.warp(block.timestamp + 60);
        joseph.rebalance();

        // then
        uint256 balanceMiltonAfter = IIpToken(usdcAmm.usdc()).balanceOf(address(usdcAmm.milton()));
        uint256 balanceMiltonIvAfter = ERC20(usdcAmm.ivUsdc()).balanceOf(address(usdcAmm.milton()));
        uint256 balanceAaveStrategyAfter = usdcAmm.strategyAave().balanceOf();

        assertTrue(
            balanceMiltonBefore < balanceMiltonAfter,
            "balanceMiltonBefore < balanceMiltonAfter"
        );
        assertTrue(
            balanceMiltonIvBefore > balanceMiltonIvAfter,
            "balanceMiltonIvBefore > balanceMiltonIvAfter"
        );
        assertTrue(
            balanceAaveStrategyBefore > balanceAaveStrategyAfter,
            "balanceAaveStrategyBefore > balanceAaveStrategyAfter"
        );
    }

    function testRebalanceAndDepositUsdtIntoVaultCompound() public {
        // given
        address user = _getUserAddress(1);
        uint256 depositAmount = 50_000e6;
        UsdtAmm usdtAmm = new UsdtAmm(address(this));
        Joseph joseph = usdtAmm.joseph();

        joseph.setAutoRebalanceThreshold(0);
        deal(usdtAmm.usdt(), user, 500_000e6);
        usdtAmm.approveMiltonJoseph(user);

        vm.prank(user);
        joseph.provideLiquidity(depositAmount);
        usdtAmm.overrideAaveStrategyWithZeroApr(address(this));
        uint256 balanceMiltonBefore = IIpToken(usdtAmm.usdt()).balanceOf(address(usdtAmm.milton()));
        uint256 balanceMiltonIvBefore = ERC20(usdtAmm.ivUsdt()).balanceOf(
            address(usdtAmm.milton())
        );
        uint256 balanceCompoundStrategyBefore = usdtAmm.strategyCompound().balanceOf();

        // when
        joseph.rebalance();

        //then
        uint256 balanceMiltonAfter = IIpToken(usdtAmm.usdt()).balanceOf(address(usdtAmm.milton()));
        uint256 balanceMiltonIvAfter = ERC20(usdtAmm.ivUsdt()).balanceOf(address(usdtAmm.milton()));
        uint256 balanceCompoundStrategyAfter = usdtAmm.strategyCompound().balanceOf();

        assertTrue(balanceMiltonBefore > balanceMiltonAfter);
        assertTrue(balanceMiltonIvBefore < balanceMiltonIvAfter);
        assertTrue(balanceCompoundStrategyBefore < balanceCompoundStrategyAfter);
    }

    function testShouldSetNewCompoundStrategyAndTransferAsset() public {
        // given
        address user = _getUserAddress(1);
        uint256 depositAmount = 10_000e6;
        UsdtAmm usdtAmm = new UsdtAmm(address(this));
        Joseph joseph = usdtAmm.joseph();
        Stanley stanley = usdtAmm.stanley();

        joseph.setAutoRebalanceThreshold(0);
        deal(usdtAmm.usdt(), user, 500_000e6);
        usdtAmm.approveMiltonJoseph(user);

        vm.prank(user);
        joseph.provideLiquidity(depositAmount);
        usdtAmm.overrideAaveStrategyWithZeroApr(address(this));
        uint256 balanceMiltonBefore = IIpToken(usdtAmm.usdt()).balanceOf(address(usdtAmm.milton()));
        joseph.rebalance();
        vm.warp(block.timestamp + 10000);
        StrategyCompound newStrategyCompound = usdtAmm.createCompoundStrategy();

        uint256 balanceOldCompoundStrategyBefore = usdtAmm.strategyCompound().balanceOf();
        uint256 balanceNewCompoundStrategyBefore = newStrategyCompound.balanceOf();
        uint256 balanceMiltonIvBefore = ERC20(usdtAmm.ivUsdt()).balanceOf(
            address(usdtAmm.milton())
        );

        // when
        stanley.setStrategyCompound(address(newStrategyCompound));

        uint256 balanceOldCompoundStrategyAfterSwitch = usdtAmm.strategyCompound().balanceOf();
        uint256 balanceNewCompoundStrategyAfterSwitch = newStrategyCompound.balanceOf();


        // then
        uint256 balanceMiltonIvAfter = ERC20(usdtAmm.ivUsdt()).balanceOf(
            address(usdtAmm.milton())
        );
        uint256 balanceMiltonAfterRebalance = IIpToken(usdtAmm.usdt()).balanceOf(
            address(usdtAmm.milton())
        );
        uint256 balanceOldCompoundStrategyAfterRebalance = usdtAmm.strategyCompound().balanceOf();
        uint256 balanceNewCompoundStrategyAfterRebalance = newStrategyCompound.balanceOf();

        assertTrue(balanceOldCompoundStrategyBefore > 0);
        assertEq(balanceNewCompoundStrategyBefore, 0);
        assertTrue(balanceOldCompoundStrategyAfterSwitch < balanceOldCompoundStrategyBefore);
        assertEq(balanceMiltonIvBefore, balanceMiltonIvAfter);
    }

    function skipTestShouldClosePositionWhenMiltonDoesntHaveCashButStanleyHas() public {
        //given
        address user = _getUserAddress(1);
        uint256 depositAmount = 50_000e18;
        uint256 totalAmount = 750e18;

        DaiAmm daiAmm = new DaiAmm(address(this));
        Joseph joseph = daiAmm.joseph();
        Milton milton = daiAmm.milton();

        joseph.setAutoRebalanceThreshold(0);
        joseph.setMiltonStanleyBalanceRatio(1e16);
        deal(daiAmm.dai(), user, 500_000e18);
        daiAmm.approveMiltonJoseph(user);

        vm.prank(user);
        joseph.provideLiquidity(depositAmount);

        vm.prank(user);
        milton.openSwapPayFixed(totalAmount, 9e16, 100e18);

        joseph.rebalance();

        uint256 balanceMiltonAfterRebalance = IIpToken(daiAmm.dai()).balanceOf(
            address(milton)
        );

        vm.roll(block.number + 10);

        uint256 userBalanceBeforeClose = IIpToken(daiAmm.dai()).balanceOf(user);


        //then
        vm.expectEmit(true, true, false, false);
        emit Burn(address(milton), 1234);

        //when
        milton.closeSwapPayFixed(1);

        uint256 userBalanceAfterClose = IIpToken(daiAmm.dai()).balanceOf(user);

        //then
        assertTrue(balanceMiltonAfterRebalance < totalAmount, "balanceMiltonAfterRebalance < totalAmount not achieved");
        assertTrue(userBalanceAfterClose > userBalanceBeforeClose, "userBalanceAfterClose > userBalanceBeforeClose not achieved");

        uint256 balanceMiltonAfterClose = IIpToken(daiAmm.dai()).balanceOf(
            address(milton)
        );
    }
}


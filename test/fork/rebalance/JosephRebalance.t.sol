// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.16;

import "forge-std/Test.sol";
import "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import "../../TestCommons.sol";
import "../DaiAmm.sol";

contract AmmDaiForkOpenCloseSwaps is Test, TestCommons {
    function test1() public {
        assertTrue(true);
    }

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
        joseth.redeem(15_000e18);
        uint256 balanceMiltonDaiBefore = IIpToken(daiAmm.dai()).balanceOf(address(daiAmm.milton()));
        uint256 balanceMiltonIvDaiBefore = ERC20(daiAmm.ivDai()).balanceOf(
            address(daiAmm.milton())
        );
        uint256 balanceAaveStrategyBefore = daiAmm.strategyAave().balanceOf();

        // when
        vm.warp(block.timestamp + 60);
    }
}

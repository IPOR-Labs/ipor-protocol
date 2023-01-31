// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.16;

import "forge-std/Test.sol";
import "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import "../../TestCommons.sol";
import "../DaiAmm.sol";

contract AmmDaiForkOpenCloseSwaps is Test, TestCommons {

    function testShouldProvideLiquidityFor50000DaiWhenNoAutoRebalanceThreshold() public {
        // given
        address user = _getUserAddress(1);
        uint256 depositAmount = 50_000e18;
        DaiAmm daiAmm = new DaiAmm(address(this));
        daiAmm.joseph().setAutoRebalanceThreshold(0);
        deal(daiAmm.dai(), user, 500_000e18);
        daiAmm.approveMiltonJoseph(user);

        uint256 balanceIpDaiBefore = IIpToken(daiAmm.ipDai()).balanceOf(user);
        uint256 balanceDaiBefore = IIpToken(daiAmm.dai()).balanceOf(user);

        // when
        Joseph joseph = daiAmm.joseph();
        vm.prank(user);
        joseph.provideLiquidity(depositAmount);

        //then
        uint256 balanceIpDaiAfter = IIpToken(daiAmm.ipDai()).balanceOf(user);
        uint256 balanceDaiAfter = IIpToken(daiAmm.dai()).balanceOf(user);

        assertEq(balanceDaiAfter, balanceDaiBefore - depositAmount);
        assertEq(balanceIpDaiAfter, balanceIpDaiBefore + depositAmount);
    }

    function testShouldProvideLiquidityFor50000DaiWhenBelowAutoRebalanceThreshold() public {
        // given
        address user = _getUserAddress(1);
        uint256 depositAmount = 50_000e18;
        DaiAmm daiAmm = new DaiAmm(address(this));
        daiAmm.joseph().setAutoRebalanceThreshold(70);
        deal(daiAmm.dai(), user, 500_000e18);
        daiAmm.approveMiltonJoseph(user);

        uint256 balanceIpDaiBefore = IIpToken(daiAmm.ipDai()).balanceOf(user);
        uint256 balanceDaiBefore = IIpToken(daiAmm.dai()).balanceOf(user);
        uint256 balanceStanleyBefore = daiAmm.stanley().totalBalance(address(daiAmm.milton()));

        // when
        Joseph joseph = daiAmm.joseph();
        vm.prank(user);
        joseph.provideLiquidity(depositAmount);

        //then
        uint256 balanceIpDaiAfter = IIpToken(daiAmm.ipDai()).balanceOf(user);
        uint256 balanceDaiAfter = IIpToken(daiAmm.dai()).balanceOf(user);
        uint256 balanceStanleyAfter = daiAmm.stanley().totalBalance(address(daiAmm.milton()));

        assertEq(balanceStanleyBefore, 0);
        assertEq(balanceStanleyAfter, 0);
        assertEq(balanceDaiAfter, balanceDaiBefore - depositAmount);
        assertEq(balanceIpDaiAfter, balanceIpDaiBefore + depositAmount);
    }

    function testShouldProvideLiquidityFor50000DaiWhenAboveAutoRebalanceThreshold() public {
        // given
        address user = _getUserAddress(1);
        uint256 depositAmount = 50_000e18;
        DaiAmm daiAmm = new DaiAmm(address(this));
        Joseph joseph = daiAmm.joseph();
        joseph.setAutoRebalanceThreshold(40);
        deal(daiAmm.dai(), user, 500_000e18);
        daiAmm.approveMiltonJoseph(user);

        uint256 balanceUserIpDaiBefore = IIpToken(daiAmm.ipDai()).balanceOf(user);
        uint256 balanceUserDaiBefore = IIpToken(daiAmm.dai()).balanceOf(user);
        uint256 balanceStanleyBefore = daiAmm.stanley().totalBalance(address(daiAmm.milton()));
        uint256 balanceMiltonDaiBefore = IIpToken(daiAmm.dai()).balanceOf(address(daiAmm.milton()));

        // when
        vm.prank(user);
        joseph.provideLiquidity(depositAmount);

        //then
        uint256 balanceUserIpDaiAfter = IIpToken(daiAmm.ipDai()).balanceOf(user);
        uint256 balanceUserDaiAfter = IIpToken(daiAmm.dai()).balanceOf(user);
        uint256 balanceStanleyAfter = daiAmm.stanley().totalBalance(address(daiAmm.milton()));
        uint256 balanceMiltonDaiAfter = IIpToken(daiAmm.dai()).balanceOf(address(daiAmm.milton()));

        assertEq(balanceStanleyBefore, 0);
        assertTrue(balanceStanleyAfter > 0);
        assertEq(balanceMiltonDaiBefore, 0);
        assertEq(balanceMiltonDaiAfter, depositAmount - 7500e18);
        assertEq(balanceUserDaiAfter, balanceUserDaiBefore - depositAmount);
        assertEq(balanceUserIpDaiAfter, balanceUserIpDaiBefore + depositAmount);
    }

    function testShouldOpenSwapPayFixed() public {
        // given
        address user = _getUserAddress(1);
        address usertwo = _getUserAddress(2);
        uint256 depositAmount = 50_000e18;
        DaiAmm daiAmm = new DaiAmm(address(this));

        deal(daiAmm.dai(), user, 500_000e18);
        deal(daiAmm.dai(), usertwo, 500_000e18);

        daiAmm.approveMiltonJoseph(user);
        daiAmm.approveMiltonJoseph(usertwo);

        Joseph joseph = daiAmm.joseph();
        vm.prank(usertwo);
        joseph.provideLiquidity(depositAmount);

        Milton milton = daiAmm.milton();

        // when
        vm.prank(user);
        uint256 swapId = milton.openSwapPayFixed(100e18, 9e16, 10e18);

        // then
        MiltonStorage miltonStorage = daiAmm.miltonStorage();
        IporTypes.IporSwapMemory memory swap = miltonStorage.getSwapPayFixed(1);

        assertEq(swap.id, 1);
        assertEq(swap.buyer, user);
        assertEq(swap.collateral, 64356435643564356436);
        assertEq(swap.notional, 643564356435643564360);
        assertEq(swapId, 1);
    }

    function testShouldOpenSwapReceiveFixed() public {
        // given
        address user = _getUserAddress(1);
        address usertwo = _getUserAddress(2);
        uint256 depositAmount = 50_000e18;
        DaiAmm daiAmm = new DaiAmm(address(this));

        deal(daiAmm.dai(), user, 500_000e18);
        deal(daiAmm.dai(), usertwo, 500_000e18);

        daiAmm.approveMiltonJoseph(user);
        daiAmm.approveMiltonJoseph(usertwo);

        Joseph joseph = daiAmm.joseph();
        vm.prank(usertwo);
        joseph.provideLiquidity(depositAmount);

        Milton milton = daiAmm.milton();

        // when
        vm.prank(user);
        uint256 swapId = milton.openSwapReceiveFixed(100e18, 1e16, 10e18);

        // then
        MiltonStorage miltonStorage = daiAmm.miltonStorage();
        IporTypes.IporSwapMemory memory swap = miltonStorage.getSwapReceiveFixed(1);

        console2.log("swap.collateral", swap.collateral);
        console2.log("swap.notional", swap.notional);

        assertEq(swap.id, 1);
        assertEq(swap.buyer, user);
        assertEq(swap.collateral, 64356435643564356436);
        assertEq(swap.notional, 643564356435643564360);
        assertEq(swapId, 1);
    }

    function testShouldCloseSwapPayFixed() public {
        // given
        address user = _getUserAddress(1);
        address userTwo = _getUserAddress(2);
        uint256 depositAmount = 50_000e18;
        DaiAmm daiAmm = new DaiAmm(address(this));
        MiltonStorage miltonStorage = daiAmm.miltonStorage();
        Joseph joseph = daiAmm.joseph();
        Milton milton = daiAmm.milton();

        deal(daiAmm.dai(), user, 500_000e18);
        deal(daiAmm.dai(), userTwo, 500_000e18);

        daiAmm.approveMiltonJoseph(user);
        daiAmm.approveMiltonJoseph(userTwo);

        vm.prank(userTwo);
        joseph.provideLiquidity(depositAmount);

        vm.prank(userTwo);
        uint256 swapId = milton.openSwapPayFixed(100e18, 9e16, 10e18);
        IporTypes.IporSwapMemory memory swapBefore = miltonStorage.getSwapPayFixed(1);

        // when
        vm.prank(userTwo);
        milton.closeSwapPayFixed(swapId);

        // then
        IporTypes.IporSwapMemory memory swapAfter = miltonStorage.getSwapPayFixed(1);

        assertEq(swapBefore.id, swapAfter.id);
        assertEq(swapBefore.buyer, swapAfter.buyer);
        assertEq(swapBefore.collateral, swapAfter.collateral);
        assertEq(swapBefore.notional, swapAfter.notional);
        assertEq(swapBefore.openTimestamp, swapAfter.openTimestamp);
        assertEq(swapBefore.endTimestamp, swapAfter.endTimestamp);
        assertEq(swapBefore.idsIndex, swapAfter.idsIndex);
        assertEq(swapBefore.ibtQuantity, swapAfter.ibtQuantity);
        assertEq(swapBefore.fixedInterestRate, swapAfter.fixedInterestRate);
        assertEq(swapBefore.liquidationDepositAmount, swapAfter.liquidationDepositAmount);
        assertEq(swapBefore.state, 1);
        assertEq(swapAfter.state, 0);
    }
    function testShouldCloseSwapReceiveFixed() public {
        // given
        address user = _getUserAddress(1);
        address userTwo = _getUserAddress(2);
        uint256 depositAmount = 50_000e18;
        DaiAmm daiAmm = new DaiAmm(address(this));
        MiltonStorage miltonStorage = daiAmm.miltonStorage();
        Joseph joseph = daiAmm.joseph();
        Milton milton = daiAmm.milton();

        deal(daiAmm.dai(), user, 500_000e18);
        deal(daiAmm.dai(), userTwo, 500_000e18);

        daiAmm.approveMiltonJoseph(user);
        daiAmm.approveMiltonJoseph(userTwo);

        vm.prank(userTwo);
        joseph.provideLiquidity(depositAmount);

        vm.prank(userTwo);
        uint256 swapId = milton.openSwapReceiveFixed(100e18, 1e16, 10e18);
        IporTypes.IporSwapMemory memory swapBefore = miltonStorage.getSwapReceiveFixed(1);

        // when
        vm.prank(userTwo);
        milton.closeSwapReceiveFixed(swapId);

        // then
        IporTypes.IporSwapMemory memory swapAfter = miltonStorage.getSwapReceiveFixed(1);

        assertEq(swapBefore.id, swapAfter.id);
        assertEq(swapBefore.buyer, swapAfter.buyer);
        assertEq(swapBefore.collateral, swapAfter.collateral);
        assertEq(swapBefore.notional, swapAfter.notional);
        assertEq(swapBefore.openTimestamp, swapAfter.openTimestamp);
        assertEq(swapBefore.endTimestamp, swapAfter.endTimestamp);
        assertEq(swapBefore.idsIndex, swapAfter.idsIndex);
        assertEq(swapBefore.ibtQuantity, swapAfter.ibtQuantity);
        assertEq(swapBefore.fixedInterestRate, swapAfter.fixedInterestRate);
        assertEq(swapBefore.liquidationDepositAmount, swapAfter.liquidationDepositAmount);
        assertEq(swapBefore.state, 1);
        assertEq(swapAfter.state, 0);
    }
}

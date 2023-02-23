// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.16;

import "forge-std/Test.sol";
import "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import "../../TestCommons.sol";
import "../UsdtAmm.sol";
import "../IAsset.sol";

contract AmmUsdtForkOpenCloseSwaps is Test, TestCommons {
    function testShouldProvideLiquidityFor50000WhenNoAutoRebalanceThreshold() public {
        // given
        address user = _getUserAddress(1);
        uint256 depositAmount = 50_000e6;
        UsdtAmm usdtAmm = new UsdtAmm(address(this));
        Joseph joseph = usdtAmm.joseph();

        joseph.setAutoRebalanceThreshold(0);
        deal(usdtAmm.usdt(), user, 500_000e6);
        usdtAmm.approveMiltonJoseph(user);

        uint256 balanceIpUsdtBefore = IIpToken(usdtAmm.ipUsdt()).balanceOf(user);
        uint256 balanceUsdtBefore = IAsset(usdtAmm.usdt()).balanceOf(user);

        // when
        vm.prank(user);
        joseph.provideLiquidity(depositAmount);

        //then
        uint256 balanceIpUsdtAfter = IIpToken(usdtAmm.ipUsdt()).balanceOf(user);
        uint256 balanceUsdtAfter = IAsset(usdtAmm.usdt()).balanceOf(user);

        assertEq(balanceUsdtAfter, balanceUsdtBefore - depositAmount);
        assertEq(balanceIpUsdtAfter, balanceIpUsdtBefore + depositAmount * 1e12);
    }

    function testShouldProvideLiquidityFor50000WhenBelowAutoRebalanceThreshold() public {
        // given
        address user = _getUserAddress(1);
        uint256 depositAmount = 50_000e6;
        UsdtAmm usdtAmm = new UsdtAmm(address(this));
        Joseph joseph = usdtAmm.joseph();

        joseph.setAutoRebalanceThreshold(70);
        deal(usdtAmm.usdt(), user, 500_000e6);
        usdtAmm.approveMiltonJoseph(user);

        uint256 balanceIpUsdtBefore = IIpToken(usdtAmm.ipUsdt()).balanceOf(user);
        uint256 balanceUsdtBefore = IAsset(usdtAmm.usdt()).balanceOf(user);
        uint256 balanceStanleyBefore = usdtAmm.stanley().totalBalance(address(usdtAmm.milton()));

        // when
        vm.prank(user);
        joseph.provideLiquidity(depositAmount);

        //then
        uint256 balanceIpUsdtAfter = IIpToken(usdtAmm.ipUsdt()).balanceOf(user);
        uint256 balanceUsdtAfter = IAsset(usdtAmm.usdt()).balanceOf(user);
        uint256 balanceStanleyAfter = usdtAmm.stanley().totalBalance(address(usdtAmm.milton()));

        assertEq(balanceStanleyBefore, 0);
        assertEq(balanceStanleyAfter, 0);
        assertEq(balanceUsdtAfter, balanceUsdtBefore - depositAmount);
        assertEq(balanceIpUsdtAfter, balanceIpUsdtBefore + depositAmount * 1e12);
    }

    //
    function testShouldProvideLiquidityFor50000WhenAboveAutoRebalanceThreshold() public {
        // given
        address user = _getUserAddress(1);
        uint256 depositAmount = 50_000e6;
        UsdtAmm usdtAmm = new UsdtAmm(address(this));
        Joseph joseph = usdtAmm.joseph();

        joseph.setAutoRebalanceThreshold(40);
        deal(usdtAmm.usdt(), user, 500_000e6);
        usdtAmm.approveMiltonJoseph(user);

        uint256 balanceUserIpUsdtBefore = IIpToken(usdtAmm.ipUsdt()).balanceOf(user);
        uint256 balanceUserUsdtBefore = IAsset(usdtAmm.usdt()).balanceOf(user);
        uint256 balanceStanleyBefore = usdtAmm.stanley().totalBalance(address(usdtAmm.milton()));
        uint256 balanceMiltonUsdtBefore = IAsset(usdtAmm.usdt()).balanceOf(
            address(usdtAmm.milton())
        );

        // when
        vm.prank(user);
        joseph.provideLiquidity(depositAmount);

        //then
        uint256 balanceUserIpUsdtAfter = IIpToken(usdtAmm.ipUsdt()).balanceOf(user);
        uint256 balanceUserUsdtAfter = IIpToken(usdtAmm.usdt()).balanceOf(user);
        uint256 balanceStanleyAfter = usdtAmm.stanley().totalBalance(address(usdtAmm.milton()));
        uint256 balanceMiltonUsdtAfter = IIpToken(usdtAmm.usdt()).balanceOf(
            address(usdtAmm.milton())
        );

        assertEq(balanceStanleyBefore, 0);
        assertTrue(balanceStanleyAfter > 0);
        assertEq(balanceMiltonUsdtBefore, 0);
        assertEq(balanceMiltonUsdtAfter, depositAmount - 7500e6);
        assertEq(balanceUserUsdtAfter, balanceUserUsdtBefore - depositAmount);
        assertEq(balanceUserIpUsdtAfter, balanceUserIpUsdtBefore + depositAmount * 1e12);
    }

    function testShouldOpenSwapPayFixed() public {
        // given
        address user = _getUserAddress(1);
        address userTwo = _getUserAddress(2);
        uint256 depositAmount = 50_000e6;
        UsdtAmm usdtAmm = new UsdtAmm(address(this));
        Joseph joseph = usdtAmm.joseph();
        Milton milton = usdtAmm.milton();

        deal(usdtAmm.usdt(), user, 500_000e6);
        deal(usdtAmm.usdt(), userTwo, 500_000e6);

        usdtAmm.approveMiltonJoseph(user);
        usdtAmm.approveMiltonJoseph(userTwo);

        vm.prank(userTwo);
        joseph.provideLiquidity(depositAmount);

        // when
        vm.prank(user);
        uint256 swapId = milton.openSwapPayFixed(100e6, 9e16, 10e18);

        // then
        MiltonStorage miltonStorage = usdtAmm.miltonStorage();
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
        address userTwo = _getUserAddress(2);
        uint256 depositAmount = 50_000e6;
        UsdtAmm usdtAmm = new UsdtAmm(address(this));
        Joseph joseph = usdtAmm.joseph();
        Milton milton = usdtAmm.milton();

        deal(usdtAmm.usdt(), user, 500_000e6);
        deal(usdtAmm.usdt(), userTwo, 500_000e6);

        usdtAmm.approveMiltonJoseph(user);
        usdtAmm.approveMiltonJoseph(userTwo);

        vm.prank(userTwo);
        joseph.provideLiquidity(depositAmount);

        // when
        vm.prank(user);
        uint256 swapId = milton.openSwapReceiveFixed(100e6, 1e16, 10e18);

        // then
        MiltonStorage miltonStorage = usdtAmm.miltonStorage();
        IporTypes.IporSwapMemory memory swap = miltonStorage.getSwapReceiveFixed(1);

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
        uint256 depositAmount = 50_000e6;
        UsdtAmm usdtAmm = new UsdtAmm(address(this));
        MiltonStorage miltonStorage = usdtAmm.miltonStorage();
        Joseph joseph = usdtAmm.joseph();
        Milton milton = usdtAmm.milton();

        deal(usdtAmm.usdt(), user, 500_000e6);
        deal(usdtAmm.usdt(), userTwo, 500_000e6);

        usdtAmm.approveMiltonJoseph(user);
        usdtAmm.approveMiltonJoseph(userTwo);

        vm.prank(userTwo);
        joseph.provideLiquidity(depositAmount);

        vm.prank(userTwo);
        uint256 swapId = milton.openSwapPayFixed(100e6, 9e16, 10e18);
        IporTypes.IporSwapMemory memory swapBefore = miltonStorage.getSwapPayFixed(1);

        // when
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
        uint256 depositAmount = 50_000e6;
        UsdtAmm usdtAmm = new UsdtAmm(address(this));
        MiltonStorage miltonStorage = usdtAmm.miltonStorage();
        Joseph joseph = usdtAmm.joseph();
        Milton milton = usdtAmm.milton();

        deal(usdtAmm.usdt(), user, 500_000e6);
        deal(usdtAmm.usdt(), userTwo, 500_000e6);

        usdtAmm.approveMiltonJoseph(user);
        usdtAmm.approveMiltonJoseph(userTwo);

        vm.prank(userTwo);
        joseph.provideLiquidity(depositAmount);

        vm.prank(userTwo);
        uint256 swapId = milton.openSwapReceiveFixed(100e6, 1e16, 10e18);
        IporTypes.IporSwapMemory memory swapBefore = miltonStorage.getSwapReceiveFixed(1);

        // when
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

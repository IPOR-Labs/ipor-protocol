// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.16;

import "forge-std/Test.sol";
import "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import "../../TestCommons.sol";
import "../UsdcAmm.sol";
import "../IAsset.sol";

contract AmmUsdcForkOpenCloseSwaps is Test, TestCommons {

    function testShouldProvideLiquidityFor50000WhenNoAutoRebalanceThreshold() public {
        // given
        address user = _getUserAddress(1);
        uint256 depositAmount = 50_000e6;
        UsdcAmm usdcAmm = new UsdcAmm(address(this));
        Joseph joseph = usdcAmm.joseph();

        joseph.setAutoRebalanceThreshold(0);
        deal(usdcAmm.usdc(), user, 500_000e6);
        usdcAmm.approveMiltonJoseph(user);

        uint256 balanceIpUsdcBefore = IIpToken(usdcAmm.ipUsdc()).balanceOf(user);
        uint256 balanceUsdcBefore = IAsset(usdcAmm.usdc()).balanceOf(user);

        // when
        vm.prank(user);
        joseph.provideLiquidity(depositAmount);

        //then
        uint256 balanceIpUsdcAfter = IIpToken(usdcAmm.ipUsdc()).balanceOf(user);
        uint256 balanceUsdcAfter = IAsset(usdcAmm.usdc()).balanceOf(user);


        assertEq(balanceUsdcAfter, balanceUsdcBefore - depositAmount);
        assertEq(balanceIpUsdcAfter, balanceIpUsdcBefore + depositAmount * 1e12);
    }

    function testShouldProvideLiquidityFor50000WhenBelowAutoRebalanceThreshold() public {
        // given
        address user = _getUserAddress(1);
        uint256 depositAmount = 50_000e6;
        UsdcAmm usdcAmm = new UsdcAmm(address(this));
        Joseph joseph = usdcAmm.joseph();

        joseph.setAutoRebalanceThreshold(70);
        deal(usdcAmm.usdc(), user, 500_000e6);
        usdcAmm.approveMiltonJoseph(user);

        uint256 balanceIpUsdcBefore = IIpToken(usdcAmm.ipUsdc()).balanceOf(user);
        uint256 balanceUsdcBefore = IAsset(usdcAmm.usdc()).balanceOf(user);
        uint256 balanceStanleyBefore = usdcAmm.stanley().totalBalance(address(usdcAmm.milton()));

        // when
        vm.prank(user);
        joseph.provideLiquidity(depositAmount);

        //then
        uint256 balanceIpUsdcAfter = IIpToken(usdcAmm.ipUsdc()).balanceOf(user);
        uint256 balanceUsdcAfter = IAsset(usdcAmm.usdc()).balanceOf(user);
        uint256 balanceStanleyAfter = usdcAmm.stanley().totalBalance(address(usdcAmm.milton()));

        assertEq(balanceStanleyBefore, 0);
        assertEq(balanceStanleyAfter, 0);
        assertEq(balanceUsdcAfter, balanceUsdcBefore - depositAmount);
        assertEq(balanceIpUsdcAfter, balanceIpUsdcBefore + depositAmount * 1e12);
    }
    //
    function testShouldProvideLiquidityFor50000WhenAboveAutoRebalanceThreshold() public {
        // given
        address user = _getUserAddress(1);
        uint256 depositAmount = 50_000e6;
        UsdcAmm usdcAmm = new UsdcAmm(address(this));
        Joseph joseph = usdcAmm.joseph();

        joseph.setAutoRebalanceThreshold(40);
        deal(usdcAmm.usdc(), user, 500_000e6);
        usdcAmm.approveMiltonJoseph(user);

        uint256 balanceUserIpUsdcBefore = IIpToken(usdcAmm.ipUsdc()).balanceOf(user);
        uint256 balanceUserUsdcBefore = IAsset(usdcAmm.usdc()).balanceOf(user);
        uint256 balanceStanleyBefore = usdcAmm.stanley().totalBalance(address(usdcAmm.milton()));
        uint256 balanceMiltonUsdcBefore = IAsset(usdcAmm.usdc()).balanceOf(address(usdcAmm.milton()));

        // when
        vm.prank(user);
        joseph.provideLiquidity(depositAmount);

        //then
        uint256 balanceUserIpUsdcAfter = IIpToken(usdcAmm.ipUsdc()).balanceOf(user);
        uint256 balanceUserUsdcAfter = IIpToken(usdcAmm.usdc()).balanceOf(user);
        uint256 balanceStanleyAfter = usdcAmm.stanley().totalBalance(address(usdcAmm.milton()));
        uint256 balanceMiltonUsdcAfter = IIpToken(usdcAmm.usdc()).balanceOf(address(usdcAmm.milton()));

        assertEq(balanceStanleyBefore, 0);
        assertTrue(balanceStanleyAfter > 0);
        assertEq(balanceMiltonUsdcBefore, 0);
        assertEq(balanceMiltonUsdcAfter, depositAmount - 7500e6);
        assertEq(balanceUserUsdcAfter, balanceUserUsdcBefore - depositAmount);
        assertEq(balanceUserIpUsdcAfter, balanceUserIpUsdcBefore + depositAmount * 1e12);
    }

    function testShouldOpenSwapPayFixed() public {
        // given
        address user = _getUserAddress(1);
        address userTwo = _getUserAddress(2);
        uint256 depositAmount = 50_000e6;
        UsdcAmm usdcAmm = new UsdcAmm(address(this));
        Joseph joseph = usdcAmm.joseph();
        Milton milton = usdcAmm.milton();

        deal(usdcAmm.usdc(), user, 500_000e6);
        deal(usdcAmm.usdc(), userTwo, 500_000e6);

        usdcAmm.approveMiltonJoseph(user);
        usdcAmm.approveMiltonJoseph(userTwo);

        vm.prank(userTwo);
        joseph.provideLiquidity(depositAmount);

        // when
        vm.prank(user);
        uint256 swapId = milton.openSwapPayFixed(100e6, 9e16, 10e18);

        // then
        MiltonStorage miltonStorage = usdcAmm.miltonStorage();
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
        UsdcAmm usdcAmm = new UsdcAmm(address(this));
        Joseph joseph = usdcAmm.joseph();
        Milton milton = usdcAmm.milton();

        deal(usdcAmm.usdc(), user, 500_000e6);
        deal(usdcAmm.usdc(), userTwo, 500_000e6);

        usdcAmm.approveMiltonJoseph(user);
        usdcAmm.approveMiltonJoseph(userTwo);

        vm.prank(userTwo);
        joseph.provideLiquidity(depositAmount);


        // when
        vm.prank(user);
        uint256 swapId = milton.openSwapReceiveFixed(100e6, 1e16, 10e18);

        // then
        MiltonStorage miltonStorage = usdcAmm.miltonStorage();
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
            UsdcAmm usdcAmm = new UsdcAmm(address(this));
            MiltonStorage miltonStorage = usdcAmm.miltonStorage();
            Joseph joseph = usdcAmm.joseph();
            Milton milton = usdcAmm.milton();

            deal(usdcAmm.usdc(), user, 500_000e6);
            deal(usdcAmm.usdc(), userTwo, 500_000e6);

            usdcAmm.approveMiltonJoseph(user);
            usdcAmm.approveMiltonJoseph(userTwo);

            vm.prank(userTwo);
            joseph.provideLiquidity(depositAmount);

            vm.prank(userTwo);
            uint256 swapId = milton.openSwapPayFixed(100e6, 9e16, 10e18);
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
            uint256 depositAmount = 50_000e6;
            UsdcAmm usdcAmm = new UsdcAmm(address(this));
            MiltonStorage miltonStorage = usdcAmm.miltonStorage();
            Joseph joseph = usdcAmm.joseph();
            Milton milton = usdcAmm.milton();

            deal(usdcAmm.usdc(), user, 500_000e6);
            deal(usdcAmm.usdc(), userTwo, 500_000e6);

            usdcAmm.approveMiltonJoseph(user);
            usdcAmm.approveMiltonJoseph(userTwo);

            vm.prank(userTwo);
            joseph.provideLiquidity(depositAmount);

            vm.prank(userTwo);
            uint256 swapId = milton.openSwapReceiveFixed(100e6, 1e16, 10e18);
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

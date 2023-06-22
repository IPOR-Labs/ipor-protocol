// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.20;

import "forge-std/Test.sol";
import "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import "@ipor-protocol/test/TestCommons.sol";
import "../DaiAmm.sol";

contract AmmDaiForkOpenCloseSwaps is Test, TestCommons {
    function testShouldProvideLiquidityFor50000DaiWhenNoAutoRebalanceThreshold() public {
        // given
        address user = _getUserAddress(1);
        uint256 depositAmount = 50_000e18;
        DaiAmm daiAmm = new DaiAmm(address(this));
        daiAmm.joseph().setAutoRebalanceThreshold(0);
        deal(daiAmm.dai(), user, 500_000e18);
        daiAmm.approveAmmTreasuryJoseph(user);

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
        daiAmm.approveAmmTreasuryJoseph(user);

        uint256 balanceIpDaiBefore = IIpToken(daiAmm.ipDai()).balanceOf(user);
        uint256 balanceDaiBefore = IIpToken(daiAmm.dai()).balanceOf(user);
        uint256 balanceAssetManagementBefore = daiAmm.assetManagement().totalBalance(address(daiAmm.ammTreasury()));

        // when
        Joseph joseph = daiAmm.joseph();
        vm.prank(user);
        joseph.provideLiquidity(depositAmount);

        //then
        uint256 balanceIpDaiAfter = IIpToken(daiAmm.ipDai()).balanceOf(user);
        uint256 balanceDaiAfter = IIpToken(daiAmm.dai()).balanceOf(user);
        uint256 balanceAssetManagementAfter = daiAmm.assetManagement().totalBalance(address(daiAmm.ammTreasury()));

        assertEq(balanceAssetManagementBefore, 0);
        assertEq(balanceAssetManagementAfter, 0);
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
        daiAmm.approveAmmTreasuryJoseph(user);

        uint256 balanceUserIpDaiBefore = IIpToken(daiAmm.ipDai()).balanceOf(user);
        uint256 balanceUserDaiBefore = IIpToken(daiAmm.dai()).balanceOf(user);
        uint256 balanceAssetManagementBefore = daiAmm.assetManagement().totalBalance(address(daiAmm.ammTreasury()));
        uint256 balanceAmmTreasuryDaiBefore = IIpToken(daiAmm.dai()).balanceOf(address(daiAmm.ammTreasury()));

        // when
        vm.prank(user);
        joseph.provideLiquidity(depositAmount);

        //then
        uint256 balanceUserIpDaiAfter = IIpToken(daiAmm.ipDai()).balanceOf(user);
        uint256 balanceUserDaiAfter = IIpToken(daiAmm.dai()).balanceOf(user);
        uint256 balanceAssetManagementAfter = daiAmm.assetManagement().totalBalance(address(daiAmm.ammTreasury()));
        uint256 balanceAmmTreasuryDaiAfter = IIpToken(daiAmm.dai()).balanceOf(address(daiAmm.ammTreasury()));

        assertEq(balanceAssetManagementBefore, 0);
        assertTrue(balanceAssetManagementAfter > 0);
        assertEq(balanceAmmTreasuryDaiBefore, 0);
        assertEq(balanceAmmTreasuryDaiAfter, depositAmount - 7500e18);
        assertEq(balanceUserDaiAfter, balanceUserDaiBefore - depositAmount);
        assertEq(balanceUserIpDaiAfter, balanceUserIpDaiBefore + depositAmount);
    }

    function testShouldOpenSwapPayFixed() public {
        // given
        address user = _getUserAddress(1);
        address userTwo = _getUserAddress(2);
        uint256 depositAmount = 50_000e18;
        DaiAmm daiAmm = new DaiAmm(address(this));

        deal(daiAmm.dai(), user, 500_000e18);
        deal(daiAmm.dai(), userTwo, 500_000e18);

        daiAmm.approveAmmTreasuryJoseph(user);
        daiAmm.approveAmmTreasuryJoseph(userTwo);

        Joseph joseph = daiAmm.joseph();
        vm.prank(userTwo);
        joseph.provideLiquidity(depositAmount);

        AmmTreasury ammTreasury = daiAmm.ammTreasury();

        // when
        vm.prank(user);
        uint256 swapId = ammTreasury.openSwapPayFixed(100e18, 9e16, 10e18);

        // then
        AmmStorage ammStorage = daiAmm.ammStorage();
        AmmTypes.Swap memory swap = ammStorage.getSwapPayFixed(1);

        assertEq(swap.id, 1);
        assertEq(swap.buyer, user);
        assertEq(swap.collateral, 64975078052253930028);
        assertEq(swap.notional, 649750780522539300280);
        assertEq(swapId, 1);
    }

    // TODO: IL-2888 Turn on tests after the first index publication
    function skipTestShouldOpenSwapReceiveFixed() public {
        // given
        address user = _getUserAddress(1);
        address userTwo = _getUserAddress(2);
        uint256 depositAmount = 50_000e18;
        DaiAmm daiAmm = new DaiAmm(address(this));

        deal(daiAmm.dai(), user, 500_000e18);
        deal(daiAmm.dai(), userTwo, 500_000e18);

        daiAmm.approveAmmTreasuryJoseph(user);
        daiAmm.approveAmmTreasuryJoseph(userTwo);

        Joseph joseph = daiAmm.joseph();
        vm.prank(userTwo);
        joseph.provideLiquidity(depositAmount);

        AmmTreasury ammTreasury = daiAmm.ammTreasury();

        // when
        vm.prank(user);
        uint256 swapId = ammTreasury.openSwapReceiveFixed(100e18, 1e16, 10e18);

        // then
        AmmStorage ammStorage = daiAmm.ammStorage();
        AmmTypes.Swap memory swap = ammStorage.getSwapReceiveFixed(1);

        assertEq(swap.id, 1);
        assertEq(swap.buyer, user);
        assertEq(swap.collateral, 64975078052253930028);
        assertEq(swap.notional, 649750780522539300280);
        assertEq(swapId, 1);
    }

    function testShouldCloseSwapPayFixed() public {
        // given
        address user = _getUserAddress(1);
        address userTwo = _getUserAddress(2);
        uint256 depositAmount = 50_000e18;
        DaiAmm daiAmm = new DaiAmm(address(this));
        AmmStorage ammStorage = daiAmm.ammStorage();
        Joseph joseph = daiAmm.joseph();
        AmmTreasury ammTreasury = daiAmm.ammTreasury();

        deal(daiAmm.dai(), user, 500_000e18);
        deal(daiAmm.dai(), userTwo, 500_000e18);

        daiAmm.approveAmmTreasuryJoseph(user);
        daiAmm.approveAmmTreasuryJoseph(userTwo);

        vm.prank(userTwo);
        joseph.provideLiquidity(depositAmount);

        vm.prank(userTwo);
        uint256 swapId = ammTreasury.openSwapPayFixed(100e18, 9e16, 10e18);
        AmmTypes.Swap memory swapBefore = ammStorage.getSwapPayFixed(1);

        // when
        ammTreasury.closeSwapPayFixed(swapId);

        // then
        AmmTypes.Swap memory swapAfter = ammStorage.getSwapPayFixed(1);

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

    // TODO: IL-2888 Turn on tests after the first index publication
    function skipTestShouldCloseSwapReceiveFixed() public {
        // given
        address user = _getUserAddress(1);
        address userTwo = _getUserAddress(2);
        uint256 depositAmount = 50_000e18;
        DaiAmm daiAmm = new DaiAmm(address(this));
        AmmStorage ammStorage = daiAmm.ammStorage();
        Joseph joseph = daiAmm.joseph();
        AmmTreasury ammTreasury = daiAmm.ammTreasury();

        deal(daiAmm.dai(), user, 500_000e18);
        deal(daiAmm.dai(), userTwo, 500_000e18);

        daiAmm.approveAmmTreasuryJoseph(user);
        daiAmm.approveAmmTreasuryJoseph(userTwo);

        vm.prank(userTwo);
        joseph.provideLiquidity(depositAmount);

        vm.prank(userTwo);
        uint256 swapId = ammTreasury.openSwapReceiveFixed(100e18, 1e16, 10e18);
        AmmTypes.Swap memory swapBefore = ammStorage.getSwapReceiveFixed(1);

        // when
        ammTreasury.closeSwapReceiveFixed(swapId);

        // then
        AmmTypes.Swap memory swapAfter = ammStorage.getSwapReceiveFixed(1);

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

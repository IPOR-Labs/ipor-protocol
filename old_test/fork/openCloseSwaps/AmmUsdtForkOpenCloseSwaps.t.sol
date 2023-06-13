// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.20;

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
        usdtAmm.approveAmmTreasuryJoseph(user);

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
        usdtAmm.approveAmmTreasuryJoseph(user);

        uint256 balanceIpUsdtBefore = IIpToken(usdtAmm.ipUsdt()).balanceOf(user);
        uint256 balanceUsdtBefore = IAsset(usdtAmm.usdt()).balanceOf(user);
        uint256 balanceAssetManagementBefore = usdtAmm.assetManagement().totalBalance(address(usdtAmm.ammTreasury()));

        // when
        vm.prank(user);
        joseph.provideLiquidity(depositAmount);

        //then
        uint256 balanceIpUsdtAfter = IIpToken(usdtAmm.ipUsdt()).balanceOf(user);
        uint256 balanceUsdtAfter = IAsset(usdtAmm.usdt()).balanceOf(user);
        uint256 balanceAssetManagementAfter = usdtAmm.assetManagement().totalBalance(address(usdtAmm.ammTreasury()));

        assertEq(balanceAssetManagementBefore, 0);
        assertEq(balanceAssetManagementAfter, 0);
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
        usdtAmm.approveAmmTreasuryJoseph(user);

        uint256 balanceUserIpUsdtBefore = IIpToken(usdtAmm.ipUsdt()).balanceOf(user);
        uint256 balanceUserUsdtBefore = IAsset(usdtAmm.usdt()).balanceOf(user);
        uint256 balanceAssetManagementBefore = usdtAmm.assetManagement().totalBalance(address(usdtAmm.ammTreasury()));
        uint256 balanceAmmTreasuryUsdtBefore = IAsset(usdtAmm.usdt()).balanceOf(
            address(usdtAmm.ammTreasury())
        );

        // when
        vm.prank(user);
        joseph.provideLiquidity(depositAmount);

        //then
        uint256 balanceUserIpUsdtAfter = IIpToken(usdtAmm.ipUsdt()).balanceOf(user);
        uint256 balanceUserUsdtAfter = IIpToken(usdtAmm.usdt()).balanceOf(user);
        uint256 balanceAssetManagementAfter = usdtAmm.assetManagement().totalBalance(address(usdtAmm.ammTreasury()));
        uint256 balanceAmmTreasuryUsdtAfter = IIpToken(usdtAmm.usdt()).balanceOf(
            address(usdtAmm.ammTreasury())
        );

        assertEq(balanceAssetManagementBefore, 0);
        assertTrue(balanceAssetManagementAfter > 0);
        assertEq(balanceAmmTreasuryUsdtBefore, 0);
        assertEq(balanceAmmTreasuryUsdtAfter, depositAmount - 7500e6);
        assertEq(balanceUserUsdtAfter, balanceUserUsdtBefore - depositAmount);
        assertEq(balanceUserIpUsdtAfter, balanceUserIpUsdtBefore + depositAmount * 1e12);
    }

	//TODO: temporary skipped
    function skipTestShouldOpenSwapPayFixed() public {
        // given
        address user = _getUserAddress(1);
        address userTwo = _getUserAddress(2);
        uint256 depositAmount = 50_000e6;
        UsdtAmm usdtAmm = new UsdtAmm(address(this));
        Joseph joseph = usdtAmm.joseph();
        AmmTreasury ammTreasury = usdtAmm.ammTreasury();

        deal(usdtAmm.usdt(), user, 500_000e6);
        deal(usdtAmm.usdt(), userTwo, 500_000e6);

        usdtAmm.approveAmmTreasuryJoseph(user);
        usdtAmm.approveAmmTreasuryJoseph(userTwo);

        vm.prank(userTwo);
        joseph.provideLiquidity(depositAmount);

        // when
        vm.prank(user);
        uint256 swapId = ammTreasury.openSwapPayFixed(100e6, 9e16, 10e18);

        // then
        AmmStorage ammStorage = usdtAmm.ammStorage();
        AmmTypes.Swap memory swap = ammStorage.getSwapPayFixed(1);

        assertEq(swap.id, 1);
        assertEq(swap.buyer, user);
        assertEq(swap.collateral, 64356435643564356436);
        assertEq(swap.notional, 643564356435643564360);
        assertEq(swapId, 1);
    }

    function skipTestShouldOpenSwapReceiveFixed() public {
        // given
        address user = _getUserAddress(1);
        address userTwo = _getUserAddress(2);
        uint256 depositAmount = 50_000e6;
        UsdtAmm usdtAmm = new UsdtAmm(address(this));
        Joseph joseph = usdtAmm.joseph();
        AmmTreasury ammTreasury = usdtAmm.ammTreasury();

        deal(usdtAmm.usdt(), user, 500_000e6);
        deal(usdtAmm.usdt(), userTwo, 500_000e6);

        usdtAmm.approveAmmTreasuryJoseph(user);
        usdtAmm.approveAmmTreasuryJoseph(userTwo);

        vm.prank(userTwo);
        joseph.provideLiquidity(depositAmount);

        // when
        vm.prank(user);
        uint256 swapId = ammTreasury.openSwapReceiveFixed(100e6, 1e16, 10e18);

        // then
        AmmStorage ammStorage = usdtAmm.ammStorage();
        AmmTypes.Swap memory swap = ammStorage.getSwapReceiveFixed(1);

        assertEq(swap.id, 1);
        assertEq(swap.buyer, user);
        assertEq(swap.collateral, 64356435643564356436);
        assertEq(swap.notional, 643564356435643564360);
        assertEq(swapId, 1);
    }

	//TODO: temporary skipped
    function skipTestShouldCloseSwapPayFixed() public {
        // given
        address user = _getUserAddress(1);
        address userTwo = _getUserAddress(2);
        uint256 depositAmount = 50_000e6;
        UsdtAmm usdtAmm = new UsdtAmm(address(this));
        AmmStorage ammStorage = usdtAmm.ammStorage();
        Joseph joseph = usdtAmm.joseph();
        AmmTreasury ammTreasury = usdtAmm.ammTreasury();

        deal(usdtAmm.usdt(), user, 500_000e6);
        deal(usdtAmm.usdt(), userTwo, 500_000e6);

        usdtAmm.approveAmmTreasuryJoseph(user);
        usdtAmm.approveAmmTreasuryJoseph(userTwo);

        vm.prank(userTwo);
        joseph.provideLiquidity(depositAmount);

        vm.prank(userTwo);
        uint256 swapId = ammTreasury.openSwapPayFixed(100e6, 9e16, 10e18);
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

    function skipTestShouldCloseSwapReceiveFixed() public {
        // given
        address user = _getUserAddress(1);
        address userTwo = _getUserAddress(2);
        uint256 depositAmount = 50_000e6;
        UsdtAmm usdtAmm = new UsdtAmm(address(this));
        AmmStorage ammStorage = usdtAmm.ammStorage();
        Joseph joseph = usdtAmm.joseph();
        AmmTreasury ammTreasury = usdtAmm.ammTreasury();

        deal(usdtAmm.usdt(), user, 500_000e6);
        deal(usdtAmm.usdt(), userTwo, 500_000e6);

        usdtAmm.approveAmmTreasuryJoseph(user);
        usdtAmm.approveAmmTreasuryJoseph(userTwo);

        vm.prank(userTwo);
        joseph.provideLiquidity(depositAmount);

        vm.prank(userTwo);
        uint256 swapId = ammTreasury.openSwapReceiveFixed(100e6, 1e16, 10e18);
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

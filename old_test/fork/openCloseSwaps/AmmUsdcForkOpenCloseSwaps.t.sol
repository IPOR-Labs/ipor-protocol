// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.20;

import "forge-std/Test.sol";
import "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import "@ipor-protocol/test/TestCommons.sol";
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
        usdcAmm.approveAmmTreasuryJoseph(user);

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
        usdcAmm.approveAmmTreasuryJoseph(user);

        uint256 balanceIpUsdcBefore = IIpToken(usdcAmm.ipUsdc()).balanceOf(user);
        uint256 balanceUsdcBefore = IAsset(usdcAmm.usdc()).balanceOf(user);
        uint256 balanceAssetManagementBefore = usdcAmm.assetManagement().totalBalance(address(usdcAmm.ammTreasury()));

        // when
        vm.prank(user);
        joseph.provideLiquidity(depositAmount);

        //then
        uint256 balanceIpUsdcAfter = IIpToken(usdcAmm.ipUsdc()).balanceOf(user);
        uint256 balanceUsdcAfter = IAsset(usdcAmm.usdc()).balanceOf(user);
        uint256 balanceAssetManagementAfter = usdcAmm.assetManagement().totalBalance(address(usdcAmm.ammTreasury()));

        assertEq(balanceAssetManagementBefore, 0);
        assertEq(balanceAssetManagementAfter, 0);
        assertEq(balanceUsdcAfter, balanceUsdcBefore - depositAmount);
        assertEq(balanceIpUsdcAfter, balanceIpUsdcBefore + depositAmount * 1e12);
    }

    //TODO: temporary disabled
    function skipTestShouldProvideLiquidityFor50000WhenAboveAutoRebalanceThreshold() public {
        // given
        address user = _getUserAddress(1);
        uint256 depositAmount = 50_000e6;
        UsdcAmm usdcAmm = new UsdcAmm(address(this));
        Joseph joseph = usdcAmm.joseph();

        joseph.setAutoRebalanceThreshold(40);
        deal(usdcAmm.usdc(), user, 500_000e6);
        usdcAmm.approveAmmTreasuryJoseph(user);

        uint256 balanceUserIpUsdcBefore = IIpToken(usdcAmm.ipUsdc()).balanceOf(user);
        uint256 balanceUserUsdcBefore = IAsset(usdcAmm.usdc()).balanceOf(user);
        uint256 balanceAssetManagementBefore = usdcAmm.assetManagement().totalBalance(address(usdcAmm.ammTreasury()));
        uint256 balanceAmmTreasuryUsdcBefore = IAsset(usdcAmm.usdc()).balanceOf(
            address(usdcAmm.ammTreasury())
        );

        // when
        vm.prank(user);
        joseph.provideLiquidity(depositAmount);

        //then
        uint256 balanceUserIpUsdcAfter = IIpToken(usdcAmm.ipUsdc()).balanceOf(user);
        uint256 balanceUserUsdcAfter = IIpToken(usdcAmm.usdc()).balanceOf(user);
        uint256 balanceAssetManagementAfter = usdcAmm.assetManagement().totalBalance(address(usdcAmm.ammTreasury()));
        uint256 balanceAmmTreasuryUsdcAfter = IIpToken(usdcAmm.usdc()).balanceOf(
            address(usdcAmm.ammTreasury())
        );

        assertEq(balanceAssetManagementBefore, 0);
        assertTrue(balanceAssetManagementAfter > 0);
        assertEq(balanceAmmTreasuryUsdcBefore, 0);
        assertEq(balanceAmmTreasuryUsdcAfter, depositAmount - 7500e6);
        assertEq(balanceUserUsdcAfter, balanceUserUsdcBefore - depositAmount);
        assertEq(balanceUserIpUsdcAfter, balanceUserIpUsdcBefore + depositAmount * 1e12);
    }

    //TODO: temporary disabled
    function skipTestShouldOpenSwapPayFixed() public {
        // given
        address user = _getUserAddress(1);
        address userTwo = _getUserAddress(2);
        uint256 depositAmount = 50_000e6;
        UsdcAmm usdcAmm = new UsdcAmm(address(this));
        Joseph joseph = usdcAmm.joseph();
        AmmTreasury ammTreasury = usdcAmm.ammTreasury();

        deal(usdcAmm.usdc(), user, 500_000e6);
        deal(usdcAmm.usdc(), userTwo, 500_000e6);

        usdcAmm.approveAmmTreasuryJoseph(user);
        usdcAmm.approveAmmTreasuryJoseph(userTwo);

        vm.prank(userTwo);
        joseph.provideLiquidity(depositAmount);

        // when
        vm.prank(user);
        uint256 swapId = ammTreasury.openSwapPayFixed(100e6, 9e16, 10e18);

        // then
        AmmStorage ammStorage = usdcAmm.ammStorage();
        AmmTypes.Swap memory swap = ammStorage.getSwapPayFixed(1);

        assertEq(swap.id, 1);
        assertEq(swap.buyer, user);
        assertEq(swap.collateral, 64356435643564356436);
        assertEq(swap.notional, 643564356435643564360);
        assertEq(swapId, 1);
    }

    //TODO: temporary disabled
    function skipTestShouldOpenSwapReceiveFixed() public {
        // given
        address user = _getUserAddress(1);
        address userTwo = _getUserAddress(2);
        uint256 depositAmount = 50_000e6;
        UsdcAmm usdcAmm = new UsdcAmm(address(this));
        Joseph joseph = usdcAmm.joseph();
        AmmTreasury ammTreasury = usdcAmm.ammTreasury();

        deal(usdcAmm.usdc(), user, 500_000e6);
        deal(usdcAmm.usdc(), userTwo, 500_000e6);

        usdcAmm.approveAmmTreasuryJoseph(user);
        usdcAmm.approveAmmTreasuryJoseph(userTwo);

        vm.prank(userTwo);
        joseph.provideLiquidity(depositAmount);

        // when
        vm.prank(user);
        uint256 swapId = ammTreasury.openSwapReceiveFixed(100e6, 1e16, 10e18);

        // then
        AmmStorage ammStorage = usdcAmm.ammStorage();
        AmmTypes.Swap memory swap = ammStorage.getSwapReceiveFixed(1);

        assertEq(swap.id, 1);
        assertEq(swap.buyer, user);
        assertEq(swap.collateral, 64356435643564356436);
        assertEq(swap.notional, 643564356435643564360);
        assertEq(swapId, 1);
    }

    //TODO: temporary skip
    function skipTestShouldCloseSwapPayFixed() public {
        // given
        address user = _getUserAddress(1);
        address userTwo = _getUserAddress(2);
        uint256 depositAmount = 50_000e6;
        UsdcAmm usdcAmm = new UsdcAmm(address(this));
        AmmStorage ammStorage = usdcAmm.ammStorage();
        Joseph joseph = usdcAmm.joseph();
        AmmTreasury ammTreasury = usdcAmm.ammTreasury();

        deal(usdcAmm.usdc(), user, 500_000e6);
        deal(usdcAmm.usdc(), userTwo, 500_000e6);

        usdcAmm.approveAmmTreasuryJoseph(user);
        usdcAmm.approveAmmTreasuryJoseph(userTwo);

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

    //TODO: temporary skip
    function skipTestShouldCloseSwapReceiveFixed() public {
        // given
        address user = _getUserAddress(1);
        address userTwo = _getUserAddress(2);
        uint256 depositAmount = 50_000e6;
        UsdcAmm usdcAmm = new UsdcAmm(address(this));
        AmmStorage ammStorage = usdcAmm.ammStorage();
        Joseph joseph = usdcAmm.joseph();
        AmmTreasury ammTreasury = usdcAmm.ammTreasury();

        deal(usdcAmm.usdc(), user, 500_000e6);
        deal(usdcAmm.usdc(), userTwo, 500_000e6);

        usdcAmm.approveAmmTreasuryJoseph(user);
        usdcAmm.approveAmmTreasuryJoseph(userTwo);

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

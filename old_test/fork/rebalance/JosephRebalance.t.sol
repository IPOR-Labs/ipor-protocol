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
        daiAmm.approveAmmTreasuryJoseph(user);

        vm.prank(user);
        joseph.provideLiquidity(depositAmount);
        daiAmm.overrideCompoundStrategyWithZeroApr(address(this));
        uint256 balanceAmmTreasuryDaiBefore = IIpToken(daiAmm.dai()).balanceOf(address(daiAmm.ammTreasury()));
        uint256 balanceAmmTreasuryIvDaiBefore = ERC20(daiAmm.ivDai()).balanceOf(address(daiAmm.ammTreasury()));
        uint256 balanceAaveStrategyBefore = daiAmm.strategyAave().balanceOf();

        // when
        joseph.rebalance();

        //then
        uint256 balanceAmmTreasuryDaiAfter = IIpToken(daiAmm.dai()).balanceOf(address(daiAmm.ammTreasury()));
        uint256 balanceAmmTreasuryIvDaiAfter = ERC20(daiAmm.ivDai()).balanceOf(address(daiAmm.ammTreasury()));
        uint256 balanceAaveStrategyAfter = daiAmm.strategyAave().balanceOf();

        assertTrue(balanceAmmTreasuryDaiBefore > balanceAmmTreasuryDaiAfter);
        assertTrue(balanceAmmTreasuryIvDaiBefore < balanceAmmTreasuryIvDaiAfter);
        assertTrue(balanceAaveStrategyBefore < balanceAaveStrategyAfter);
    }

    function testShouldSetNewAaveStrategyAndRebalanceAndDepositDaiIntoVaultAave() public {
        // given
        address user = _getUserAddress(1);
        uint256 depositAmount = 10_000e18;
        DaiAmm daiAmm = new DaiAmm(address(this));
        Joseph joseph = daiAmm.joseph();
        AssetManagement assetManagement = daiAmm.assetManagement();

        joseph.setAutoRebalanceThreshold(0);
        deal(daiAmm.dai(), user, 500_000e18);
        daiAmm.approveAmmTreasuryJoseph(user);

        vm.prank(user);
        joseph.provideLiquidity(depositAmount);
        daiAmm.overrideCompoundStrategyWithZeroApr(address(this));
        joseph.rebalance();
        StrategyAave newStrategyAave = daiAmm.createAaveStrategy();

        uint256 balanceOldAaveStrategyBefore = daiAmm.strategyAave().balanceOf();
        uint256 balanceNewAaveStrategyBefore = newStrategyAave.balanceOf();
        uint256 balanceAmmTreasuryIvDaiBefore = ERC20(daiAmm.ivDai()).balanceOf(address(daiAmm.ammTreasury()));

        // when
        assetManagement.setStrategyAave(address(newStrategyAave));
        uint256 balanceOldAaveStrategyAfterSwitch = daiAmm.strategyAave().balanceOf();
        uint256 balanceNewAaveStrategyAfterSwitch = newStrategyAave.balanceOf();

        vm.prank(user);
        joseph.provideLiquidity(depositAmount);

        joseph.rebalance();

        // then

        uint256 balanceAmmTreasuryIvDaiAfterRebalance = ERC20(daiAmm.ivDai()).balanceOf(address(daiAmm.ammTreasury()));
        uint256 balanceOldAaveStrategyAfterRebalance = daiAmm.strategyAave().balanceOf();
        uint256 balanceNewAaveStrategyAfterRebalance = newStrategyAave.balanceOf();

        assertTrue(balanceOldAaveStrategyBefore > 0);
        assertEq(balanceNewAaveStrategyBefore, 0);
        assertEq(balanceOldAaveStrategyAfterSwitch, 0);
        assertEq(balanceOldAaveStrategyBefore, balanceNewAaveStrategyAfterSwitch);
        assertEq(balanceOldAaveStrategyAfterRebalance, 0);
        assertTrue(balanceNewAaveStrategyAfterRebalance > 0);
        assertTrue(balanceAmmTreasuryIvDaiBefore < balanceAmmTreasuryIvDaiAfterRebalance);
    }

    function testShouldRebalanceAndWithdrawDaiFromAssetManagementAndAave() public {
        // given
        address user = _getUserAddress(1);
        uint256 depositAmount = 50_000e18;
        DaiAmm daiAmm = new DaiAmm(address(this));
        Joseph joseph = daiAmm.joseph();

        joseph.setAutoRebalanceThreshold(0);
        deal(daiAmm.dai(), user, 500_000e18);
        daiAmm.approveAmmTreasuryJoseph(user);

        vm.prank(user);
        joseph.provideLiquidity(depositAmount);
        daiAmm.overrideCompoundStrategyWithZeroApr(address(this));
        joseph.rebalance();
        vm.prank(user);
        joseph.redeem(15_000e18);
        uint256 balanceAmmTreasuryDaiBefore = IIpToken(daiAmm.dai()).balanceOf(address(daiAmm.ammTreasury()));
        uint256 balanceAmmTreasuryIvDaiBefore = ERC20(daiAmm.ivDai()).balanceOf(address(daiAmm.ammTreasury()));
        uint256 balanceAaveStrategyBefore = daiAmm.strategyAave().balanceOf();

        // when

        vm.warp(block.timestamp + 60);
        joseph.rebalance();

        // then
        uint256 balanceAmmTreasuryDaiAfter = IIpToken(daiAmm.dai()).balanceOf(address(daiAmm.ammTreasury()));
        uint256 balanceAmmTreasuryIvDaiAfter = ERC20(daiAmm.ivDai()).balanceOf(address(daiAmm.ammTreasury()));
        uint256 balanceAaveStrategyAfter = daiAmm.strategyAave().balanceOf();

        assertTrue(balanceAmmTreasuryDaiBefore < balanceAmmTreasuryDaiAfter, "balanceAmmTreasuryDaiBefore < balanceAmmTreasuryDaiAfter");
        assertTrue(
            balanceAmmTreasuryIvDaiBefore > balanceAmmTreasuryIvDaiAfter,
            "balanceAmmTreasuryIvDaiBefore > balanceAmmTreasuryIvDaiAfter"
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
        usdcAmm.approveAmmTreasuryJoseph(user);

        vm.prank(user);
        joseph.provideLiquidity(depositAmount);
        usdcAmm.overrideCompoundStrategyWithZeroApr(address(this));
        uint256 balanceAmmTreasuryBefore = IIpToken(usdcAmm.usdc()).balanceOf(address(usdcAmm.ammTreasury()));
        uint256 balanceAmmTreasuryIvBefore = ERC20(usdcAmm.ivUsdc()).balanceOf(address(usdcAmm.ammTreasury()));
        uint256 balanceAaveStrategyBefore = usdcAmm.strategyAave().balanceOf();

        // when
        joseph.rebalance();

        //then
        uint256 balanceAmmTreasuryAfter = IIpToken(usdcAmm.usdc()).balanceOf(address(usdcAmm.ammTreasury()));
        uint256 balanceAmmTreasuryIvAfter = ERC20(usdcAmm.ivUsdc()).balanceOf(address(usdcAmm.ammTreasury()));
        uint256 balanceAaveStrategyAfter = usdcAmm.strategyAave().balanceOf();

        assertTrue(balanceAmmTreasuryBefore > balanceAmmTreasuryAfter);
        assertTrue(balanceAmmTreasuryIvBefore < balanceAmmTreasuryIvAfter);
        assertTrue(balanceAaveStrategyBefore < balanceAaveStrategyAfter);
    }

    //TODO: temporary skipped
    function skipTestShouldNotChangeJosephExchangeRateWhenWithdrawAllFromAssetManagement() public {
        // given
        address user = _getUserAddress(1);
        uint256 depositAmount = 50_000e6;
        UsdcAmm usdcAmm = new UsdcAmm(address(this));
        Joseph joseph = usdcAmm.joseph();

        joseph.setAutoRebalanceThreshold(0);
        deal(usdcAmm.usdc(), user, 500_000e6);
        usdcAmm.approveAmmTreasuryJoseph(user);

        vm.prank(user);
        joseph.provideLiquidity(depositAmount);
        usdcAmm.overrideCompoundStrategyWithZeroApr(address(this));
        joseph.rebalance();

        uint256 balanceAmmTreasuryBefore = IIpToken(usdcAmm.usdc()).balanceOf(address(usdcAmm.ammTreasury()));
        uint256 balanceAmmTreasuryIvBefore = ERC20(usdcAmm.ivUsdc()).balanceOf(address(usdcAmm.ammTreasury()));
        uint256 balanceAaveStrategyBefore = usdcAmm.strategyAave().balanceOf();
        uint256 exchangeRateJosephBefore = joseph.calculateExchangeRate();

        // when
        joseph.withdrawAllFromAssetManagement();

        //then
        uint256 exchangeRateJosephAfter = joseph.calculateExchangeRate();
        uint256 balanceAmmTreasuryAfter = IIpToken(usdcAmm.usdc()).balanceOf(address(usdcAmm.ammTreasury()));
        uint256 balanceAmmTreasuryIvAfter = ERC20(usdcAmm.ivUsdc()).balanceOf(address(usdcAmm.ammTreasury()));
        uint256 balanceAaveStrategyAfter = usdcAmm.strategyAave().balanceOf();

        assertEq(exchangeRateJosephBefore, exchangeRateJosephAfter);
        assertTrue(balanceAmmTreasuryBefore < balanceAmmTreasuryAfter);
        assertTrue(balanceAmmTreasuryIvBefore > balanceAmmTreasuryIvAfter);
        assertTrue(balanceAaveStrategyBefore > balanceAaveStrategyAfter);
    }

    //TODO: temporary skipped
    function skipTestShouldNotChangeJosephExchangeRateWhenWithdrawFromAssetManagement() public {
        // given
        address user = _getUserAddress(1);
        uint256 depositAmount = 50_000e6;
        UsdcAmm usdcAmm = new UsdcAmm(address(this));
        Joseph joseph = usdcAmm.joseph();

        joseph.setAutoRebalanceThreshold(0);
        deal(usdcAmm.usdc(), user, 500_000e6);
        usdcAmm.approveAmmTreasuryJoseph(user);

        vm.prank(user);
        joseph.provideLiquidity(depositAmount);
        usdcAmm.overrideCompoundStrategyWithZeroApr(address(this));
        joseph.rebalance();

        uint256 balanceAmmTreasuryBefore = IIpToken(usdcAmm.usdc()).balanceOf(address(usdcAmm.ammTreasury()));
        uint256 balanceAmmTreasuryIvBefore = ERC20(usdcAmm.ivUsdc()).balanceOf(address(usdcAmm.ammTreasury()));
        uint256 balanceAaveStrategyBefore = usdcAmm.strategyAave().balanceOf();
        uint256 exchangeRateJosephBefore = joseph.calculateExchangeRate();

        // when
        joseph.withdrawFromAssetManagement(74e20);

        //then
        uint256 exchangeRateJosephAfter = joseph.calculateExchangeRate();
        uint256 balanceAmmTreasuryAfter = IIpToken(usdcAmm.usdc()).balanceOf(address(usdcAmm.ammTreasury()));
        uint256 balanceAmmTreasuryIvAfter = ERC20(usdcAmm.ivUsdc()).balanceOf(address(usdcAmm.ammTreasury()));
        uint256 balanceAaveStrategyAfter = usdcAmm.strategyAave().balanceOf();

        assertEq(exchangeRateJosephBefore, exchangeRateJosephAfter);
        assertTrue(balanceAmmTreasuryBefore < balanceAmmTreasuryAfter);
        assertTrue(balanceAmmTreasuryIvBefore > balanceAmmTreasuryIvAfter);
        assertTrue(balanceAaveStrategyBefore > balanceAaveStrategyAfter);
    }

    function testShouldSetNewAaveStrategyAndRebalanceAndDepositUsdcIntoVaultAave() public {
        // given
        address user = _getUserAddress(1);
        uint256 depositAmount = 10_000e6;
        UsdcAmm usdcAmm = new UsdcAmm(address(this));
        Joseph joseph = usdcAmm.joseph();
        AssetManagement assetManagement = usdcAmm.assetManagement();

        joseph.setAutoRebalanceThreshold(0);
        deal(usdcAmm.usdc(), user, 500_000e6);
        usdcAmm.approveAmmTreasuryJoseph(user);

        vm.prank(user);
        joseph.provideLiquidity(depositAmount);
        usdcAmm.overrideCompoundStrategyWithZeroApr(address(this));
        joseph.rebalance();
        StrategyAave newStrategyAave = usdcAmm.createAaveStrategy();

        uint256 balanceOldAaveStrategyBefore = usdcAmm.strategyAave().balanceOf();
        uint256 balanceNewAaveStrategyBefore = newStrategyAave.balanceOf();
        uint256 balanceAmmTreasuryIvBefore = ERC20(usdcAmm.ivUsdc()).balanceOf(address(usdcAmm.ammTreasury()));

        // when
        assetManagement.setStrategyAave(address(newStrategyAave));
        uint256 balanceOldAaveStrategyAfterSwitch = usdcAmm.strategyAave().balanceOf();
        uint256 balanceNewAaveStrategyAfterSwitch = newStrategyAave.balanceOf();

        vm.prank(user);
        joseph.provideLiquidity(depositAmount);

        joseph.rebalance();

        // then

        uint256 balanceAmmTreasuryIvAfterRebalance = ERC20(usdcAmm.ivUsdc()).balanceOf(address(usdcAmm.ammTreasury()));
        uint256 balanceOldAaveStrategyAfterRebalance = usdcAmm.strategyAave().balanceOf();
        uint256 balanceNewAaveStrategyAfterRebalance = newStrategyAave.balanceOf();

        assertTrue(balanceOldAaveStrategyBefore > 0);
        assertEq(balanceNewAaveStrategyBefore, 0);
        assertEq(balanceOldAaveStrategyAfterSwitch, 0);
        assertEq(balanceOldAaveStrategyBefore, balanceNewAaveStrategyAfterSwitch);
        assertEq(balanceOldAaveStrategyAfterRebalance, 0);
        assertTrue(balanceNewAaveStrategyAfterRebalance > 0);
        assertTrue(balanceAmmTreasuryIvBefore < balanceAmmTreasuryIvAfterRebalance);
    }

    function testShouldRebalanceAndWithdrawUsdcFromAssetManagementAndAave() public {
        // given
        address user = _getUserAddress(1);
        uint256 depositAmount = 50_000e6;
        UsdcAmm usdcAmm = new UsdcAmm(address(this));
        Joseph joseph = usdcAmm.joseph();

        joseph.setAutoRebalanceThreshold(0);
        deal(usdcAmm.usdc(), user, 500_000e6);
        usdcAmm.approveAmmTreasuryJoseph(user);

        vm.prank(user);
        joseph.provideLiquidity(depositAmount);
        usdcAmm.overrideCompoundStrategyWithZeroApr(address(this));
        joseph.rebalance();
        vm.prank(user);
        joseph.redeem(17_000e18);
        uint256 balanceAmmTreasuryBefore = IIpToken(usdcAmm.usdc()).balanceOf(address(usdcAmm.ammTreasury()));
        uint256 balanceAmmTreasuryIvBefore = ERC20(usdcAmm.ivUsdc()).balanceOf(address(usdcAmm.ammTreasury()));
        uint256 balanceAaveStrategyBefore = usdcAmm.strategyAave().balanceOf();

        // when

        vm.warp(block.timestamp + 60);
        joseph.rebalance();

        // then
        uint256 balanceAmmTreasuryAfter = IIpToken(usdcAmm.usdc()).balanceOf(address(usdcAmm.ammTreasury()));
        uint256 balanceAmmTreasuryIvAfter = ERC20(usdcAmm.ivUsdc()).balanceOf(address(usdcAmm.ammTreasury()));
        uint256 balanceAaveStrategyAfter = usdcAmm.strategyAave().balanceOf();

        assertTrue(balanceAmmTreasuryBefore < balanceAmmTreasuryAfter, "balanceAmmTreasuryBefore < balanceAmmTreasuryAfter");
        assertTrue(balanceAmmTreasuryIvBefore > balanceAmmTreasuryIvAfter, "balanceAmmTreasuryIvBefore > balanceAmmTreasuryIvAfter");
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
        usdtAmm.approveAmmTreasuryJoseph(user);

        vm.prank(user);
        joseph.provideLiquidity(depositAmount);
        usdtAmm.overrideAaveStrategyWithZeroApr(address(this));
        uint256 balanceAmmTreasuryBefore = IIpToken(usdtAmm.usdt()).balanceOf(address(usdtAmm.ammTreasury()));
        uint256 balanceAmmTreasuryIvBefore = ERC20(usdtAmm.ivUsdt()).balanceOf(address(usdtAmm.ammTreasury()));
        uint256 balanceCompoundStrategyBefore = usdtAmm.strategyCompound().balanceOf();

        // when
        joseph.rebalance();

        //then
        uint256 balanceAmmTreasuryAfter = IIpToken(usdtAmm.usdt()).balanceOf(address(usdtAmm.ammTreasury()));
        uint256 balanceAmmTreasuryIvAfter = ERC20(usdtAmm.ivUsdt()).balanceOf(address(usdtAmm.ammTreasury()));
        uint256 balanceCompoundStrategyAfter = usdtAmm.strategyCompound().balanceOf();

        assertTrue(balanceAmmTreasuryBefore > balanceAmmTreasuryAfter);
        assertTrue(balanceAmmTreasuryIvBefore < balanceAmmTreasuryIvAfter);
        assertTrue(balanceCompoundStrategyBefore < balanceCompoundStrategyAfter);
    }

    function testShouldSetNewCompoundStrategyAndTransferAsset() public {
        // given
        address user = _getUserAddress(1);
        uint256 depositAmount = 10_000e6;
        UsdtAmm usdtAmm = new UsdtAmm(address(this));
        Joseph joseph = usdtAmm.joseph();
        AssetManagement assetManagement = usdtAmm.assetManagement();

        joseph.setAutoRebalanceThreshold(0);
        deal(usdtAmm.usdt(), user, 500_000e6);
        usdtAmm.approveAmmTreasuryJoseph(user);

        vm.prank(user);
        joseph.provideLiquidity(depositAmount);
        usdtAmm.overrideAaveStrategyWithZeroApr(address(this));
        joseph.rebalance();
        vm.warp(block.timestamp + 10000);
        StrategyCompound newStrategyCompound = usdtAmm.createCompoundStrategy();

        uint256 balanceOldCompoundStrategyBefore = usdtAmm.strategyCompound().balanceOf();
        uint256 balanceNewCompoundStrategyBefore = newStrategyCompound.balanceOf();
        uint256 balanceAmmTreasuryIvBefore = ERC20(usdtAmm.ivUsdt()).balanceOf(address(usdtAmm.ammTreasury()));

        // when
        assetManagement.setStrategyCompound(address(newStrategyCompound));

        uint256 balanceOldCompoundStrategyAfterSwitch = usdtAmm.strategyCompound().balanceOf();

        // then
        uint256 balanceAmmTreasuryIvAfter = ERC20(usdtAmm.ivUsdt()).balanceOf(address(usdtAmm.ammTreasury()));

        assertTrue(balanceOldCompoundStrategyBefore > 0);
        assertEq(balanceNewCompoundStrategyBefore, 0);
        assertTrue(balanceOldCompoundStrategyAfterSwitch < balanceOldCompoundStrategyBefore);
        assertEq(balanceAmmTreasuryIvBefore, balanceAmmTreasuryIvAfter);
    }

    function testShouldClosePositionWhenAmmTreasuryDoesntHaveCashButAssetManagementHas() public {
        //given
        address user = _getUserAddress(1);
        uint256 depositAmount = 50_000e18;
        uint256 totalAmount = 750e18;

        DaiAmm daiAmm = new DaiAmm(address(this));
        Joseph joseph = daiAmm.joseph();
        AmmTreasury ammTreasury = daiAmm.ammTreasury();

        joseph.setAutoRebalanceThreshold(0);
        joseph.setAmmTreasuryAssetManagementBalanceRatio(1e16);
        deal(daiAmm.dai(), user, 500_000e18);
        daiAmm.approveAmmTreasuryJoseph(user);

        vm.prank(user);
        joseph.provideLiquidity(depositAmount);

        vm.prank(user);
        ammTreasury.openSwapPayFixed(totalAmount, 9e16, 100e18);

        joseph.rebalance();

        uint256 balanceAmmTreasuryAfterRebalance = IIpToken(daiAmm.dai()).balanceOf(address(ammTreasury));

        vm.roll(block.number + 10);

        uint256 userBalanceBeforeClose = IIpToken(daiAmm.dai()).balanceOf(user);

        //then
        vm.expectEmit(true, true, false, false);
        emit Burn(address(ammTreasury), 1234);

        //when
        ammTreasury.closeSwapPayFixed(1);

        uint256 userBalanceAfterClose = IIpToken(daiAmm.dai()).balanceOf(user);

        //then
        assertTrue(balanceAmmTreasuryAfterRebalance < totalAmount, "balanceAmmTreasuryAfterRebalance < totalAmount not achieved");
        assertTrue(
            userBalanceAfterClose > userBalanceBeforeClose,
            "userBalanceAfterClose > userBalanceBeforeClose not achieved"
        );
    }
}

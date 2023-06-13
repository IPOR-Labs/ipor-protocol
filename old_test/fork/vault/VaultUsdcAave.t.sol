// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.20;

import "forge-std/Test.sol";
import "../UsdcAmm.sol";

contract VaultUsdcAaveTest is Test {
    address internal _admin;
    address internal _user;

    function setUp() public {
        _admin = vm.rememberKey(1);
        _user = vm.rememberKey(2);
    }

    function testShouldDepositToAssetManagementUsdc() public {
        // given
        uint256 amount = 1_000 * 1e6;
        UsdcAmm amm = new UsdcAmm(_admin);
        amm.overrideCompoundStrategyWithZeroApr(_admin);
        deal(amm.usdc(), address(amm.ammTreasury()), amount);

        uint256 ammTreasuryTotalBalanceOnAssetManagementBefore = amm.assetManagement().totalBalance(address(amm.ammTreasury()));

        // when
        vm.startPrank(_admin);
        amm.joseph().depositToAssetManagement(amount * 1e12);
        vm.stopPrank();

        // then
        uint256 ammTreasuryTotalBalanceAssetManagementAfter = amm.assetManagement().totalBalance(address(amm.ammTreasury()));
        assertGt(
            ammTreasuryTotalBalanceAssetManagementAfter,
            ammTreasuryTotalBalanceOnAssetManagementBefore,
            "ammTreasuryTotalBalanceAssetManagementAfter > ammTreasuryTotalBalanceOnAssetManagementBefore"
        );
    }

    function testShouldBeAbleToWithdrawFromAssetManagementUsdc() public {
        // given
        uint256 amount = 1_000 * 1e6;
        UsdcAmm amm = new UsdcAmm(_admin);
        amm.overrideCompoundStrategyWithZeroApr(_admin);
        deal(amm.usdc(), address(amm.ammTreasury()), amount);
        vm.startPrank(_admin);
        amm.joseph().depositToAssetManagement(amount * 1e12);

        uint256 ammTreasuryTotalBalanceOnAssetManagementBefore = amm.assetManagement().totalBalance(address(amm.ammTreasury()));
        vm.roll(block.number + (30 * 24 * 60 * 60) / 12);
        vm.warp(block.timestamp + 30 days);

        // when
        amm.joseph().withdrawFromAssetManagement(amount * 1e12);

        // then
        uint256 ammTreasuryTotalBalanceAssetManagementAfter = amm.assetManagement().totalBalance(address(amm.ammTreasury()));
        assertLt(
            ammTreasuryTotalBalanceAssetManagementAfter,
            ammTreasuryTotalBalanceOnAssetManagementBefore,
            "ammTreasuryTotalBalanceAssetManagementAfter < ammTreasuryTotalBalanceOnAssetManagementBefore"
        );
    }

    function testShouldBeAbleToWithdrawTwiceFromAssetManagementUsdc() public {
        // given
        uint256 amount = 20_000 * 1e6;
        UsdcAmm amm = new UsdcAmm(_admin);
        Joseph joseph = amm.joseph();
        amm.overrideCompoundStrategyWithZeroApr(_admin);
        deal(amm.usdc(), address(amm.ammTreasury()), amount);
        vm.startPrank(_admin);
        amm.joseph().depositToAssetManagement(10_000 * 1e18);
        vm.roll(block.number + (30 * 24 * 60 * 60) / 12);
        vm.warp(block.timestamp + 30 days);
        amm.joseph().withdrawFromAssetManagement(10_000 * 1e18);

        vm.roll(block.number + (30 * 24 * 60 * 60) / 12);
        vm.warp(block.timestamp + 30 days);
        uint256 ammTreasuryTotalBalanceOnAssetManagementBefore = amm.assetManagement().totalBalance(address(amm.ammTreasury()));

        // when
        joseph.withdrawFromAssetManagement(ammTreasuryTotalBalanceOnAssetManagementBefore);

        // then
        uint256 ammTreasuryTotalBalanceAssetManagementAfter = amm.assetManagement().totalBalance(address(amm.ammTreasury()));
        assertLt(ammTreasuryTotalBalanceAssetManagementAfter, 1e16, "ammTreasuryTotalBalanceAssetManagementAfter < 1e16");
    }

    function testShouldNotBeAbleDepositWhenStrategiesArePausedUsdc() public {
        // given
        uint256 amount = 1_000 * 1e6;
        UsdcAmm amm = new UsdcAmm(_admin);
        Joseph joseph = amm.joseph();
        amm.overrideCompoundStrategyWithZeroApr(_admin);
        vm.startPrank(_admin);
        amm.strategyAave().addPauseGuardian(_admin);
        amm.strategyCompound().addPauseGuardian(_admin);
        amm.strategyAave().pause();
        amm.strategyCompound().pause();

        deal(amm.usdc(), address(amm.ammTreasury()), amount);

        uint256 ammTreasuryTotalBalanceOnAssetManagementBefore = amm.assetManagement().totalBalance(address(amm.ammTreasury()));

        // when
        vm.expectRevert(abi.encodePacked("Pausable: paused"));
        joseph.depositToAssetManagement(amount * 1e12);

        // then
        uint256 ammTreasuryTotalBalanceAssetManagementAfter = amm.assetManagement().totalBalance(address(amm.ammTreasury()));
        assertLt(
            ammTreasuryTotalBalanceAssetManagementAfter,
            ammTreasuryTotalBalanceOnAssetManagementBefore + amount * 1e12,
            "ammTreasuryTotalBalanceAssetManagementAfter, ammTreasuryTotalBalanceOnAssetManagementBefore + amount * 1e12"
        );
    }

    function testShouldNotBeAbleWithdrawWhenStrategiesArePausedUsdc() public {
        // given
        uint256 amount = 1_000 * 1e6;
        UsdcAmm amm = new UsdcAmm(_admin);
        Joseph joseph = amm.joseph();
        amm.overrideCompoundStrategyWithZeroApr(_admin);
        deal(amm.usdc(), address(amm.ammTreasury()), amount);
        vm.startPrank(_admin);
        amm.joseph().depositToAssetManagement(amount * 1e12);
        vm.roll(block.number + 1000);
        amm.strategyAave().addPauseGuardian(_admin);
        amm.strategyCompound().addPauseGuardian(_admin);
        amm.strategyAave().pause();
        amm.strategyCompound().pause();

        uint256 ammTreasuryTotalBalanceOnAssetManagementBefore = amm.assetManagement().totalBalance(address(amm.ammTreasury()));

        // when
        vm.expectRevert(abi.encodePacked("Pausable: paused"));
        joseph.withdrawFromAssetManagement(amount * 1e12);

        // then
        uint256 ammTreasuryTotalBalanceAssetManagementAfter = amm.assetManagement().totalBalance(address(amm.ammTreasury()));
        assertEq(
            ammTreasuryTotalBalanceAssetManagementAfter,
            ammTreasuryTotalBalanceOnAssetManagementBefore,
            "ammTreasuryTotalBalanceAssetManagementAfter == ammTreasuryTotalBalanceOnAssetManagementBefore"
        );
    }

    function testShouldNotBeAbleDepositWhenAssetManagementIsPausedUsdc() public {
        // given
        uint256 amount = 1_000 * 1e6;
        UsdcAmm amm = new UsdcAmm(_admin);
        Joseph joseph = amm.joseph();
        amm.overrideCompoundStrategyWithZeroApr(_admin);
        vm.startPrank(_admin);
        amm.assetManagement().addPauseGuardian(_admin);
        amm.assetManagement().pause();

        deal(amm.usdc(), address(amm.ammTreasury()), amount);

        uint256 ammTreasuryTotalBalanceOnAssetManagementBefore = amm.assetManagement().totalBalance(address(amm.ammTreasury()));

        // when
        vm.expectRevert(abi.encodePacked("Pausable: paused"));
        joseph.depositToAssetManagement(amount * 1e12);

        // then
        uint256 ammTreasuryTotalBalanceAssetManagementAfter = amm.assetManagement().totalBalance(address(amm.ammTreasury()));
        assertLt(
            ammTreasuryTotalBalanceAssetManagementAfter,
            ammTreasuryTotalBalanceOnAssetManagementBefore + amount * 1e12,
            "ammTreasuryTotalBalanceAssetManagementAfter, ammTreasuryTotalBalanceOnAssetManagementBefore + amount * 1e12"
        );
    }

    function testShouldNotBeAbleWithdrawWhenAssetManagementIsPausedUsdc() public {
        // given
        uint256 amount = 1_000 * 1e6;
        UsdcAmm amm = new UsdcAmm(_admin);
        Joseph joseph = amm.joseph();
        amm.overrideCompoundStrategyWithZeroApr(_admin);
        deal(amm.usdc(), address(amm.ammTreasury()), amount);
        vm.startPrank(_admin);
        amm.joseph().depositToAssetManagement(amount * 1e12);
        vm.roll(block.number + 1000);
        amm.assetManagement().addPauseGuardian(_admin);
        amm.assetManagement().pause();

        uint256 ammTreasuryTotalBalanceOnAssetManagementBefore = amm.assetManagement().totalBalance(address(amm.ammTreasury()));

        // when
        vm.expectRevert(abi.encodePacked("Pausable: paused"));
        joseph.withdrawFromAssetManagement(amount * 1e12);

        // then
        uint256 ammTreasuryTotalBalanceAssetManagementAfter = amm.assetManagement().totalBalance(address(amm.ammTreasury()));
        assertEq(
            ammTreasuryTotalBalanceAssetManagementAfter,
            ammTreasuryTotalBalanceOnAssetManagementBefore,
            "ammTreasuryTotalBalanceAssetManagementAfter == ammTreasuryTotalBalanceOnAssetManagementBefore"
        );
    }
}

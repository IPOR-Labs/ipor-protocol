// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.20;

import "forge-std/Test.sol";
import "../DaiAmm.sol";

contract VaultDaiCompoundTest is Test {
    address internal _admin;
    address internal _user;

    function setUp() public {
        _admin = vm.rememberKey(1);
        _user = vm.rememberKey(2);
    }

    function testShouldDepositToAssetManagementDai() public {
        // given
        uint256 amount = 1_000 * 1e18;
        DaiAmm amm = new DaiAmm(_admin);
        amm.overrideAaveStrategyWithZeroApy(_admin);
        deal(amm.dai(), address(amm.ammTreasury()), amount);

        uint256 ammTreasuryTotalBalanceOnAssetManagementBefore = amm.assetManagement().totalBalance(address(amm.ammTreasury()));

        // when
        vm.startPrank(_admin);
        amm.joseph().depositToAssetManagement(amount);
        vm.stopPrank();

        // then
        uint256 ammTreasuryTotalBalanceAssetManagementAfter = amm.assetManagement().totalBalance(address(amm.ammTreasury()));
        assertGt(
            ammTreasuryTotalBalanceAssetManagementAfter,
            ammTreasuryTotalBalanceOnAssetManagementBefore,
            "ammTreasuryTotalBalanceAssetManagementAfter > ammTreasuryTotalBalanceOnAssetManagementBefore"
        );
    }

    function testShouldBeAbleToWithdrawFromAssetManagementDai() public {
        // given
        uint256 amount = 1_000 * 1e18;
        DaiAmm amm = new DaiAmm(_admin);
        amm.overrideAaveStrategyWithZeroApy(_admin);
        deal(amm.dai(), address(amm.ammTreasury()), amount);
        vm.startPrank(_admin);
        amm.joseph().depositToAssetManagement(amount);

        uint256 ammTreasuryTotalBalanceOnAssetManagementBefore = amm.assetManagement().totalBalance(address(amm.ammTreasury()));

        // when
        vm.roll(block.number + 1);
        amm.joseph().withdrawFromAssetManagement(amount);

        // then
        uint256 ammTreasuryTotalBalanceAssetManagementAfter = amm.assetManagement().totalBalance(address(amm.ammTreasury()));
        assertLt(
            ammTreasuryTotalBalanceAssetManagementAfter,
            ammTreasuryTotalBalanceOnAssetManagementBefore,
            "ammTreasuryTotalBalanceAssetManagementAfter < ammTreasuryTotalBalanceOnAssetManagementBefore"
        );
    }

    function testShouldNotBeAbleDepositWhenStrategiesArePausedDai() public {
        // given
        uint256 amount = 1_000 * 1e18;
        DaiAmm amm = new DaiAmm(_admin);
        Joseph joseph = amm.joseph();
        amm.overrideAaveStrategyWithZeroApy(_admin);
        vm.startPrank(_admin);
        amm.strategyAave().addPauseGuardian(_admin);
        amm.strategyCompound().addPauseGuardian(_admin);
        amm.strategyAave().pause();
        amm.strategyCompound().pause();

        deal(amm.dai(), address(amm.ammTreasury()), amount);

        uint256 ammTreasuryTotalBalanceOnAssetManagementBefore = amm.assetManagement().totalBalance(address(amm.ammTreasury()));

        // when
        vm.expectRevert(abi.encodePacked("Pausable: paused"));
        joseph.depositToAssetManagement(amount);

        // then
        uint256 ammTreasuryTotalBalanceAssetManagementAfter = amm.assetManagement().totalBalance(address(amm.ammTreasury()));
        assertLt(
            ammTreasuryTotalBalanceAssetManagementAfter,
            ammTreasuryTotalBalanceOnAssetManagementBefore + amount,
            "ammTreasuryTotalBalanceAssetManagementAfter < ammTreasuryTotalBalanceOnAssetManagementBefore + amount"
        );
    }

    function testShouldNotBeAbleWithdrawWhenStrategiesArePausedDai() public {
        // given
        uint256 amount = 1_000 * 1e18;
        DaiAmm amm = new DaiAmm(_admin);
        Joseph joseph = amm.joseph();
        amm.overrideAaveStrategyWithZeroApy(_admin);
        deal(amm.dai(), address(amm.ammTreasury()), amount);
        vm.startPrank(_admin);
        amm.joseph().depositToAssetManagement(amount);
        vm.roll(block.number + 1);
        amm.strategyAave().addPauseGuardian(_admin);
        amm.strategyCompound().addPauseGuardian(_admin);
        amm.strategyAave().pause();
        amm.strategyCompound().pause();

        uint256 ammTreasuryTotalBalanceOnAssetManagementBefore = amm.assetManagement().totalBalance(address(amm.ammTreasury()));

        // when
        vm.expectRevert(abi.encodePacked("Pausable: paused"));
        joseph.withdrawFromAssetManagement(amount);

        // then
        uint256 ammTreasuryTotalBalanceAssetManagementAfter = amm.assetManagement().totalBalance(address(amm.ammTreasury()));
        assertEq(
            ammTreasuryTotalBalanceAssetManagementAfter,
            ammTreasuryTotalBalanceOnAssetManagementBefore,
            "ammTreasuryTotalBalanceAssetManagementAfter == ammTreasuryTotalBalanceOnAssetManagementBefore"
        );
    }

    function testShouldNotBeAbleDepositWhenAssetManagementIsPausedDai() public {
        // given
        uint256 amount = 1_000 * 1e18;
        DaiAmm amm = new DaiAmm(_admin);
        Joseph joseph = amm.joseph();
        amm.overrideAaveStrategyWithZeroApy(_admin);
        vm.startPrank(_admin);
        amm.assetManagement().addPauseGuardian(_admin);
        amm.assetManagement().pause();

        deal(amm.dai(), address(amm.ammTreasury()), amount);

        uint256 ammTreasuryTotalBalanceOnAssetManagementBefore = amm.assetManagement().totalBalance(address(amm.ammTreasury()));

        // when
        vm.expectRevert(abi.encodePacked("Pausable: paused"));
        joseph.depositToAssetManagement(amount);

        // then
        uint256 ammTreasuryTotalBalanceAssetManagementAfter = amm.assetManagement().totalBalance(address(amm.ammTreasury()));
        assertLt(
            ammTreasuryTotalBalanceAssetManagementAfter,
            ammTreasuryTotalBalanceOnAssetManagementBefore + amount,
            "ammTreasuryTotalBalanceAssetManagementAfter, ammTreasuryTotalBalanceOnAssetManagementBefore + amount"
        );
    }

    function testShouldNotBeAbleWithdrawWhenAssetManagementIsPausedDai() public {
        // given
        uint256 amount = 1_000 * 1e18;
        DaiAmm amm = new DaiAmm(_admin);
        Joseph joseph = amm.joseph();
        amm.overrideAaveStrategyWithZeroApy(_admin);
        deal(amm.dai(), address(amm.ammTreasury()), amount);
        vm.startPrank(_admin);
        amm.joseph().depositToAssetManagement(amount);
        vm.roll(block.number + 1);
        amm.assetManagement().addPauseGuardian(_admin);
        amm.assetManagement().pause();

        uint256 ammTreasuryTotalBalanceOnAssetManagementBefore = amm.assetManagement().totalBalance(address(amm.ammTreasury()));

        // when
        vm.expectRevert(abi.encodePacked("Pausable: paused"));
        joseph.withdrawFromAssetManagement(amount);

        // then
        uint256 ammTreasuryTotalBalanceAssetManagementAfter = amm.assetManagement().totalBalance(address(amm.ammTreasury()));
        assertEq(
            ammTreasuryTotalBalanceAssetManagementAfter,
            ammTreasuryTotalBalanceOnAssetManagementBefore,
            "ammTreasuryTotalBalanceAssetManagementAfter == ammTreasuryTotalBalanceOnAssetManagementBefore"
        );
    }
}

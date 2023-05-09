// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.16;

import "forge-std/Test.sol";
import "../DaiAmm.sol";

contract VaultDaiAaveTest is Test {
    address internal _admin;
    address internal _user;

    function setUp() public {
        _admin = vm.rememberKey(1);
        _user = vm.rememberKey(2);
    }

    function testShouldDepositToStanleyDai() public {
        // given
        uint256 amount = 1_000 * 1e18;
        DaiAmm amm = new DaiAmm(_admin);
        amm.overrideCompoundStrategyWithZeroApr(_admin);
        deal(amm.dai(), address(amm.milton()), amount);

        uint256 miltonTotalBalanceOnStanleyBefore = amm.stanley().totalBalance(address(amm.milton()));

        // when
        vm.startPrank(_admin);
        amm.joseph().depositToStanley(amount);
        vm.stopPrank();

        // then
        uint256 miltonTotalBalanceStanleyAfter = amm.stanley().totalBalance(address(amm.milton()));
        assertGt(
            miltonTotalBalanceStanleyAfter,
            miltonTotalBalanceOnStanleyBefore,
            "miltonTotalBalanceStanleyAfter > miltonTotalBalanceOnStanleyBefore"
        );
    }

    function testShouldBeAbleToWithdrawFromStanleyDai() public {
        // given
        uint256 amount = 1_000 * 1e18;
        DaiAmm amm = new DaiAmm(_admin);
        amm.overrideCompoundStrategyWithZeroApr(_admin);
        deal(amm.dai(), address(amm.milton()), amount);
        vm.startPrank(_admin);
        amm.joseph().depositToStanley(amount);

        uint256 miltonTotalBalanceOnStanleyBefore = amm.stanley().totalBalance(address(amm.milton()));
        vm.roll(block.number + (30 * 24 * 60 * 60) / 12);
        vm.warp(block.timestamp + 30 days);

        // when
        amm.joseph().withdrawFromStanley(amount);

        // then
        uint256 miltonTotalBalanceStanleyAfter = amm.stanley().totalBalance(address(amm.milton()));
        assertLt(
            miltonTotalBalanceStanleyAfter,
            miltonTotalBalanceOnStanleyBefore,
            "miltonTotalBalanceStanleyAfter < miltonTotalBalanceOnStanleyBefore"
        );
    }

    function testShouldBeAbleToWithdrawTwiceFromStanleyDai() public {
        // given
        uint256 amount = 20_000 * 1e18;
        DaiAmm amm = new DaiAmm(_admin);
        Joseph joseph = amm.joseph();
        amm.overrideCompoundStrategyWithZeroApr(_admin);
        deal(amm.dai(), address(amm.milton()), amount);
        vm.startPrank(_admin);
        amm.joseph().depositToStanley(10_000 * 1e18);
        vm.roll(block.number + (30 * 24 * 60 * 60) / 12);
        vm.warp(block.timestamp + 30 days);
        amm.joseph().withdrawFromStanley(10_000 * 1e18);

        vm.roll(block.number + (30 * 24 * 60 * 60) / 12);
        vm.warp(block.timestamp + 30 days);
        uint256 miltonTotalBalanceOnStanleyBefore = amm.stanley().totalBalance(address(amm.milton()));

        // when
        joseph.withdrawFromStanley(miltonTotalBalanceOnStanleyBefore);

        // then
        uint256 miltonTotalBalanceStanleyAfter = amm.stanley().totalBalance(address(amm.milton()));
        assertLt(miltonTotalBalanceStanleyAfter, 1e16, "miltonTotalBalanceStanleyAfter < 1e16");
    }

    function testShouldNotBeAbleDepositWhenStrategiesArePausedDai() public {
        // given
        uint256 amount = 1_000 * 1e18;
        DaiAmm amm = new DaiAmm(_admin);
        Joseph joseph = amm.joseph();
        amm.overrideCompoundStrategyWithZeroApr(_admin);
        vm.startPrank(_admin);
        amm.strategyAave().pause();
        amm.strategyCompound().pause();

        deal(amm.dai(), address(amm.milton()), amount);

        uint256 miltonTotalBalanceOnStanleyBefore = amm.stanley().totalBalance(address(amm.milton()));

        // when
        vm.expectRevert(abi.encodePacked("Pausable: paused"));
        joseph.depositToStanley(amount);

        // then
        uint256 miltonTotalBalanceStanleyAfter = amm.stanley().totalBalance(address(amm.milton()));
        assertLt(
            miltonTotalBalanceStanleyAfter,
            miltonTotalBalanceOnStanleyBefore + amount,
            "miltonTotalBalanceStanleyAfter < miltonTotalBalanceOnStanleyBefore + amount"
        );
    }

    function testShouldNotBeAbleWithdrawWhenStrategiesArePausedDai() public {
        // given
        uint256 amount = 1_000 * 1e18;
        DaiAmm amm = new DaiAmm(_admin);
        Joseph joseph = amm.joseph();
        amm.overrideCompoundStrategyWithZeroApr(_admin);
        deal(amm.dai(), address(amm.milton()), amount);
        vm.startPrank(_admin);
        amm.joseph().depositToStanley(amount);
        vm.roll(block.number + 1);
        amm.strategyAave().pause();
        amm.strategyCompound().pause();

        uint256 miltonTotalBalanceOnStanleyBefore = amm.stanley().totalBalance(address(amm.milton()));

        // when
        vm.expectRevert(abi.encodePacked("Pausable: paused"));
        joseph.withdrawFromStanley(amount);

        // then
        uint256 miltonTotalBalanceStanleyAfter = amm.stanley().totalBalance(address(amm.milton()));
        assertEq(
            miltonTotalBalanceStanleyAfter,
            miltonTotalBalanceOnStanleyBefore,
            "miltonTotalBalanceStanleyAfter == miltonTotalBalanceOnStanleyBefore"
        );
    }

    function testShouldNotBeAbleDepositWhenStanleyIsPausedDai() public {
        // given
        uint256 amount = 1_000 * 1e18;
        DaiAmm amm = new DaiAmm(_admin);
        Joseph joseph = amm.joseph();
        amm.overrideCompoundStrategyWithZeroApr(_admin);
        vm.startPrank(_admin);
        amm.stanley().addPauseGuardian(_admin);
        amm.stanley().pause();

        deal(amm.dai(), address(amm.milton()), amount);

        uint256 miltonTotalBalanceOnStanleyBefore = amm.stanley().totalBalance(address(amm.milton()));

        // when
        vm.expectRevert(abi.encodePacked("Pausable: paused"));
        joseph.depositToStanley(amount);

        // then
        uint256 miltonTotalBalanceStanleyAfter = amm.stanley().totalBalance(address(amm.milton()));
        assertLt(
            miltonTotalBalanceStanleyAfter,
            miltonTotalBalanceOnStanleyBefore + amount,
            "miltonTotalBalanceStanleyAfter, miltonTotalBalanceOnStanleyBefore + amount"
        );
    }

    function testShouldNotBeAbleWithdrawWhenStanleyIsPausedDai() public {
        // given
        uint256 amount = 1_000 * 1e18;
        DaiAmm amm = new DaiAmm(_admin);
        Joseph joseph = amm.joseph();
        amm.overrideCompoundStrategyWithZeroApr(_admin);
        deal(amm.dai(), address(amm.milton()), amount);
        vm.startPrank(_admin);
        amm.joseph().depositToStanley(amount);
        vm.roll(block.number + 1);
        amm.stanley().addPauseGuardian(_admin);
        amm.stanley().pause();

        uint256 miltonTotalBalanceOnStanleyBefore = amm.stanley().totalBalance(address(amm.milton()));

        // when
        vm.expectRevert(abi.encodePacked("Pausable: paused"));
        joseph.withdrawFromStanley(amount);

        // then
        uint256 miltonTotalBalanceStanleyAfter = amm.stanley().totalBalance(address(amm.milton()));
        assertEq(
            miltonTotalBalanceStanleyAfter,
            miltonTotalBalanceOnStanleyBefore,
            "miltonTotalBalanceStanleyAfter == miltonTotalBalanceOnStanleyBefore"
        );
    }
}

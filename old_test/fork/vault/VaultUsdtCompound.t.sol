// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.16;

import "forge-std/Test.sol";
import "../UsdtAmm.sol";

contract VaultUsdtCompoundTest is Test {
    address internal _admin;
    address internal _user;

    function setUp() public {
        _admin = vm.rememberKey(1);
        _user = vm.rememberKey(2);
    }

    function testShouldDepositToStanleyUsdt() public {
        // given
        uint256 amount = 1_000 * 1e6;
        UsdtAmm amm = new UsdtAmm(_admin);
        amm.overrideAaveStrategyWithZeroApr(_admin);
        deal(amm.usdt(), address(amm.milton()), amount);

        uint256 miltonTotalBalanceOnStanleyBefore = amm.stanley().totalBalance(address(amm.milton()));

        // when
        vm.startPrank(_admin);
        amm.joseph().depositToStanley(amount * 1e12);
        vm.stopPrank();

        // then
        uint256 miltonTotalBalanceStanleyAfter = amm.stanley().totalBalance(address(amm.milton()));
        assertGt(
            miltonTotalBalanceStanleyAfter,
            miltonTotalBalanceOnStanleyBefore,
            "miltonTotalBalanceStanleyAfter > miltonTotalBalanceOnStanleyBefore"
        );
    }

    function testShouldBeAbleToWithdrawFromStanleyUsdt() public {
        // given
        uint256 amount = 1_000 * 1e6;
        UsdtAmm amm = new UsdtAmm(_admin);
        amm.overrideAaveStrategyWithZeroApr(_admin);
        deal(amm.usdt(), address(amm.milton()), amount);
        vm.startPrank(_admin);
        amm.joseph().depositToStanley(amount * 1e12);

        uint256 miltonTotalBalanceOnStanleyBefore = amm.stanley().totalBalance(address(amm.milton()));

        // when
        vm.roll(block.number + 1);
        amm.joseph().withdrawFromStanley(amount * 1e12);

        // then
        uint256 miltonTotalBalanceStanleyAfter = amm.stanley().totalBalance(address(amm.milton()));
        assertLt(
            miltonTotalBalanceStanleyAfter,
            miltonTotalBalanceOnStanleyBefore,
            "miltonTotalBalanceStanleyAfter < miltonTotalBalanceOnStanleyBefore"
        );
    }

    function testShouldNotBeAbleToWithdrawFromStanleyUsdt() public {
        // given
        uint256 amount = 20_000 * 1e6;
        UsdtAmm amm = new UsdtAmm(_admin);
        Joseph joseph = amm.joseph();
        amm.overrideAaveStrategyWithZeroApr(_admin);
        deal(amm.usdt(), address(amm.milton()), amount);
        vm.startPrank(_admin);
        amm.joseph().depositToStanley(10_000 * 1e18);
        vm.roll(block.number + 1);
        amm.joseph().withdrawFromStanley(9999999995 * 1e12);

        uint256 miltonTotalBalanceOnStanleyBefore = amm.stanley().totalBalance(address(amm.milton()));

        // when
        vm.expectRevert(abi.encodePacked(MiltonErrors.INTEREST_FROM_STRATEGY_BELOW_ZERO));
        joseph.withdrawFromStanley(10_000 * 1e18);

        // then
        uint256 miltonTotalBalanceStanleyAfter = amm.stanley().totalBalance(address(amm.milton()));
        assertEq(
            miltonTotalBalanceStanleyAfter,
            miltonTotalBalanceOnStanleyBefore,
            "miltonTotalBalanceStanleyAfter == miltonTotalBalanceOnStanleyBefore"
        );
    }

    function testShouldNotBeAbleDepositWhenStrategiesArePausedUsdt() public {
        // given
        uint256 amount = 1_000 * 1e6;
        UsdtAmm amm = new UsdtAmm(_admin);
        Joseph joseph = amm.joseph();
        amm.overrideAaveStrategyWithZeroApr(_admin);
        vm.startPrank(_admin);
        amm.strategyAave().addPauseGuardian(_admin);
        amm.strategyCompound().addPauseGuardian(_admin);
        amm.strategyAave().pause();
        amm.strategyCompound().pause();

        deal(amm.usdt(), address(amm.milton()), amount);

        uint256 miltonTotalBalanceOnStanleyBefore = amm.stanley().totalBalance(address(amm.milton()));

        // when
        vm.expectRevert(abi.encodePacked("Pausable: paused"));
        joseph.depositToStanley(amount * 1e12);

        // then
        uint256 miltonTotalBalanceStanleyAfter = amm.stanley().totalBalance(address(amm.milton()));
        assertLt(
            miltonTotalBalanceStanleyAfter,
            miltonTotalBalanceOnStanleyBefore + amount * 1e12,
            "miltonTotalBalanceStanleyAfter < miltonTotalBalanceOnStanleyBefore + amount * 1e12"
        );
    }

    function testShouldNotBeAbleWithdrawWhenStrategiesArePausedUsdt() public {
        // given
        uint256 amount = 1_000 * 1e6;
        UsdtAmm amm = new UsdtAmm(_admin);
        Joseph joseph = amm.joseph();
        amm.overrideAaveStrategyWithZeroApr(_admin);
        deal(amm.usdt(), address(amm.milton()), amount);
        vm.startPrank(_admin);
        amm.joseph().depositToStanley(amount * 1e12);
        vm.roll(block.number + 1);
        amm.strategyAave().addPauseGuardian(_admin);
        amm.strategyCompound().addPauseGuardian(_admin);
        amm.strategyAave().pause();
        amm.strategyCompound().pause();

        uint256 miltonTotalBalanceOnStanleyBefore = amm.stanley().totalBalance(address(amm.milton()));

        // when
        vm.expectRevert(abi.encodePacked("Pausable: paused"));
        joseph.withdrawFromStanley(amount * 1e12);

        // then
        uint256 miltonTotalBalanceStanleyAfter = amm.stanley().totalBalance(address(amm.milton()));
        assertEq(
            miltonTotalBalanceStanleyAfter,
            miltonTotalBalanceOnStanleyBefore,
            "miltonTotalBalanceStanleyAfter == miltonTotalBalanceOnStanleyBefore"
        );
    }

    function testShouldNotBeAbleDepositWhenStanleyIsPausedUsdt() public {
        // given
        uint256 amount = 1_000 * 1e6;
        UsdtAmm amm = new UsdtAmm(_admin);
        Joseph joseph = amm.joseph();
        amm.overrideAaveStrategyWithZeroApr(_admin);
        vm.startPrank(_admin);
        amm.stanley().addPauseGuardian(_admin);
        amm.stanley().pause();

        deal(amm.usdt(), address(amm.milton()), amount);

        uint256 miltonTotalBalanceOnStanleyBefore = amm.stanley().totalBalance(address(amm.milton()));

        // when
        vm.expectRevert(abi.encodePacked("Pausable: paused"));
        joseph.depositToStanley(amount * 1e12);

        // then
        uint256 miltonTotalBalanceStanleyAfter = amm.stanley().totalBalance(address(amm.milton()));
        assertLt(
            miltonTotalBalanceStanleyAfter,
            miltonTotalBalanceOnStanleyBefore + amount * 1e12,
            "miltonTotalBalanceStanleyAfter, miltonTotalBalanceOnStanleyBefore + amount * 1e12"
        );
    }

    function testShouldNotBeAbleWithdrawWhenStanleyIsPausedUsdt() public {
        // given
        uint256 amount = 1_000 * 1e6;
        UsdtAmm amm = new UsdtAmm(_admin);
        Joseph joseph = amm.joseph();
        amm.overrideAaveStrategyWithZeroApr(_admin);
        deal(amm.usdt(), address(amm.milton()), amount);
        vm.startPrank(_admin);
        amm.joseph().depositToStanley(amount * 1e12);
        vm.roll(block.number + 1);
        amm.stanley().addPauseGuardian(_admin);
        amm.stanley().pause();

        uint256 miltonTotalBalanceOnStanleyBefore = amm.stanley().totalBalance(address(amm.milton()));

        // when
        vm.expectRevert(abi.encodePacked("Pausable: paused"));
        joseph.withdrawFromStanley(amount * 1e12);

        // then
        uint256 miltonTotalBalanceStanleyAfter = amm.stanley().totalBalance(address(amm.milton()));
        assertEq(
            miltonTotalBalanceStanleyAfter,
            miltonTotalBalanceOnStanleyBefore,
            "miltonTotalBalanceStanleyAfter == miltonTotalBalanceOnStanleyBefore"
        );
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.16;

import "forge-std/Test.sol";
import "../UsdcAmm.sol";

contract VaultUsdcCompoundTest is Test {
    address internal _admin;
    address internal _user;

    function setUp() public {
        _admin = vm.rememberKey(1);
        _user = vm.rememberKey(2);
    }

    function testShouldDepositToStanleyUsdc() public {
        // given
        uint256 amount = 1_000 * 1e6;
        UsdcAmm amm = new UsdcAmm(_admin);
        amm.overrideAaveStrategyWithZeroApr(_admin);
        deal(amm.usdc(), address(amm.milton()), amount);

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

    function testShouldBeAbleToWithdrawFromStanleyUsdc() public {
        // given
        uint256 amount = 1_000 * 1e6;
        UsdcAmm amm = new UsdcAmm(_admin);
        amm.overrideAaveStrategyWithZeroApr(_admin);
        deal(amm.usdc(), address(amm.milton()), amount);
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

    function testShouldNotBeAbleToWithdrawFromStanleyUsdc() public {
        // given
        uint256 amount = 20_000 * 1e6;
        UsdcAmm amm = new UsdcAmm(_admin);
        Joseph joseph = amm.joseph();
        amm.overrideAaveStrategyWithZeroApr(_admin);
        deal(amm.usdc(), address(amm.milton()), amount);
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

    function testShouldNotBeAbleDepositWhenStrategiesArePausedUsdc() public {
        // given
        uint256 amount = 1_000 * 1e6;
        UsdcAmm amm = new UsdcAmm(_admin);
        Joseph joseph = amm.joseph();
        amm.overrideAaveStrategyWithZeroApr(_admin);
        vm.startPrank(_admin);
        amm.strategyAave().pause();
        amm.strategyCompound().pause();

        deal(amm.usdc(), address(amm.milton()), amount);

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

    function testShouldNotBeAbleWithdrawWhenStrategiesArePausedUsdc() public {
        // given
        uint256 amount = 1_000 * 1e6;
        UsdcAmm amm = new UsdcAmm(_admin);
        Joseph joseph = amm.joseph();
        amm.overrideAaveStrategyWithZeroApr(_admin);
        deal(amm.usdc(), address(amm.milton()), amount);
        vm.startPrank(_admin);
        amm.joseph().depositToStanley(amount * 1e12);
        vm.roll(block.number + 1);
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

    function testShouldNotBeAbleDepositWhenStanleyIsPausedUsdc() public {
        // given
        uint256 amount = 1_000 * 1e6;
        UsdcAmm amm = new UsdcAmm(_admin);
        Joseph joseph = amm.joseph();
        amm.overrideAaveStrategyWithZeroApr(_admin);
        vm.startPrank(_admin);
        amm.stanley().pause();

        deal(amm.usdc(), address(amm.milton()), amount);

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

    function testShouldNotBeAbleWithdrawWhenStanleyIsPausedUsdc() public {
        // given
        uint256 amount = 1_000 * 1e6;
        UsdcAmm amm = new UsdcAmm(_admin);
        Joseph joseph = amm.joseph();
        amm.overrideAaveStrategyWithZeroApr(_admin);
        deal(amm.usdc(), address(amm.milton()), amount);
        vm.startPrank(_admin);
        amm.joseph().depositToStanley(amount * 1e12);
        vm.roll(block.number + 1);
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

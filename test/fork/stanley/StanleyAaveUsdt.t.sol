// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.16;

import "forge-std/Test.sol";
import "../../../contracts/vault/StanleyUsdt.sol";
import "../../../contracts/tokens/IvToken.sol";
import "../UsdtAmm.sol";

contract StanleyAaveUsdtTest is Test {
    address internal _admin;

    function setUp() public {
        _admin = vm.rememberKey(1);
    }

    function testShouldAaveAprBeZeroAfterOverride() public {
        // given
        UsdtAmm amm = new UsdtAmm(_admin);

        // when
        amm.overrideAaveStrategyWithZeroApr(_admin);

        // then
        assertEq(IStrategy(amm.stanley().getStrategyAave()).getApr(), 0, "strategyCompoundApr == 0");
    }

    function testShouldAaveAprGreaterThanCompoundApr() public {
        // given
        UsdtAmm amm = new UsdtAmm(_admin);
        amm.overrideCompoundStrategyWithZeroApr(_admin);

        // when
        uint256 compoundApr = IStrategy(amm.stanley().getStrategyCompound()).getApr();
        uint256 aaveApr = IStrategy(amm.stanley().getStrategyAave()).getApr();

        // then
        assertGt(aaveApr, compoundApr, "aaveApr > compoundApr");
    }

    function testShouldAcceptDepositAndTransferTokensIntoAAVE() public {
        // given
        uint256 depositAmount = 10 * 1e6;
        UsdtAmm amm = new UsdtAmm(_admin);
        deal(amm.usdt(), address(amm.milton()), depositAmount);
        amm.overrideCompoundStrategyWithZeroApr(_admin);

        uint256 miltonIvTokenBefore = IvToken(amm.stanley().getIvToken()).balanceOf(address(amm.milton()));
        uint256 strategyBalanceBefore = IStrategy(amm.stanley().getStrategyAave()).balanceOf();
        uint256 miltonBalanceBefore = IERC20(amm.usdt()).balanceOf(address(amm.milton()));
        uint256 strategyATokenContractBefore = IERC20(amm.aUsdt()).balanceOf(amm.stanley().getStrategyAave());

        // when
        vm.startPrank(address(amm.milton()));
        amm.stanley().deposit(depositAmount * 1e12);

        // then
        uint256 miltonIvTokenAfter = IvToken(amm.stanley().getIvToken()).balanceOf(address(amm.milton()));
        uint256 strategyBalanceAfter = IStrategy(amm.stanley().getStrategyAave()).balanceOf();
        uint256 miltonBalanceAfter = IERC20(amm.usdt()).balanceOf(address(amm.milton()));
        uint256 strategyATokenContractAfter = IERC20(amm.aUsdt()).balanceOf(amm.stanley().getStrategyAave());

        assertEq(miltonIvTokenBefore, 0, "miltonIvTokenBefore == 0");
        assertEq(strategyBalanceBefore, 0, "strategyBalanceBefore == 0");
        assertGe(miltonIvTokenAfter, miltonIvTokenBefore, "miltonIvTokenAfter >= miltonIvTokenAfter");
        assertGe(
            strategyBalanceAfter,
            strategyBalanceBefore,
            "strategyBalanceAfter >= strategyBalanceAfter"
        );
        assertLe(miltonBalanceAfter, miltonBalanceBefore, "miltonBalanceAfter <= miltonBalanceAfter");
        assertGe(
            strategyATokenContractAfter,
            strategyATokenContractBefore,
            "strategyATokenContractAfter >= strategyATokenContractAfter"
        );
    }

    function testShouldAcceptDepositTwiceAndTransferTokensIntoAAVE() public {
        // given
        uint256 depositAmount = 10 * 1e6;
        UsdtAmm amm = new UsdtAmm(_admin);
        deal(amm.usdt(), address(amm.milton()), 2 * depositAmount);
        amm.overrideCompoundStrategyWithZeroApr(_admin);

        uint256 miltonIvTokenBefore = IvToken(amm.stanley().getIvToken()).balanceOf(address(amm.milton()));
        uint256 strategyBalanceBefore = IStrategy(amm.stanley().getStrategyAave()).balanceOf();
        uint256 miltonBalanceBefore = IERC20(amm.usdt()).balanceOf(address(amm.milton()));
        uint256 strategyATokenContractBefore = IERC20(amm.aUsdt()).balanceOf(amm.stanley().getStrategyAave());

        // when
        vm.startPrank(address(amm.milton()));
        amm.stanley().deposit(depositAmount * 1e12);
        amm.stanley().deposit(depositAmount * 1e12);

        // then
        uint256 miltonIvTokenAfter = IvToken(amm.stanley().getIvToken()).balanceOf(address(amm.milton()));
        uint256 strategyATokenContractAfter = IERC20(amm.aUsdt()).balanceOf(amm.stanley().getStrategyAave());
        uint256 miltonBalanceAfter = IERC20(amm.usdt()).balanceOf(address(amm.milton()));
        uint256 strategyBalanceAfter = IStrategy(amm.stanley().getStrategyAave()).balanceOf();

        assertGe(miltonIvTokenAfter, miltonIvTokenBefore, "miltonIvTokenAfter >= miltonIvTokenBefore");
        assertGt(
            strategyBalanceAfter,
            strategyBalanceBefore,
            "strategyBalanceAfter > strategyBalanceBefore"
        );
        assertLt(miltonBalanceAfter, miltonBalanceBefore, "miltonBalanceAfter < miltonBalanceBefore");
        assertGe(
            strategyATokenContractAfter,
            strategyATokenContractBefore,
            "strategyATokenContractAfter >= strategyATokenContractBefore"
        );
    }

    function testShouldWithdraw10FromAAVE() public {
        //given
        uint256 withdrawAmount = 10 * 1e6;
        UsdtAmm amm = new UsdtAmm(_admin);
        amm.overrideCompoundStrategyWithZeroApr(_admin);

        vm.startPrank(address(amm.milton()));
        deal(amm.usdt(), address(amm.milton()), withdrawAmount);
        amm.stanley().deposit(withdrawAmount * 1e12);

        uint256 miltonIvTokenBefore = IvToken(amm.stanley().getIvToken()).balanceOf(address(amm.milton()));
        uint256 strategyBalanceBefore = IStrategy(amm.stanley().getStrategyAave()).balanceOf();
        uint256 miltonBalanceBefore = IERC20(amm.usdt()).balanceOf(address(amm.milton()));
        uint256 strategyATokenContractBefore = IERC20(amm.aUsdt()).balanceOf(amm.stanley().getStrategyAave());

        // when
        amm.stanley().withdraw(withdrawAmount * 1e12);

        // then
        uint256 strategyBalanceAfter = IStrategy(amm.stanley().getStrategyAave()).balanceOf();
        uint256 miltonIvTokenAfter = IvToken(amm.stanley().getIvToken()).balanceOf(address(amm.milton()));
        uint256 miltonBalanceAfter = IERC20(amm.usdt()).balanceOf(address(amm.milton()));
        uint256 strategyATokenContractAfter = IERC20(amm.aUsdt()).balanceOf(amm.stanley().getStrategyAave());

        assertLt(miltonIvTokenAfter, miltonIvTokenBefore, "miltonIvTokenAfter < miltonIvTokenBefore");
        assertLt(
            strategyBalanceAfter,
            strategyBalanceBefore,
            "strategyBalanceAfter < strategyBalanceBefore"
        );
        assertGt(miltonBalanceAfter, miltonBalanceBefore, "miltonBalanceAfter > miltonBalanceBefore");
        assertLt(
            strategyATokenContractAfter,
            strategyATokenContractBefore,
            "strategyATokenContractAfter < strategyATokenContractBefore"
        );
    }

    function testShouldWithdrawAllStanleyBalanceFromAAVEWithdrawMethod() public {
        // given
        uint256 withdrawAmount = 10 * 1e6;
        UsdtAmm amm = new UsdtAmm(_admin);
        amm.overrideCompoundStrategyWithZeroApr(_admin);

        vm.startPrank(address(amm.milton()));
        deal(amm.usdt(), address(amm.milton()), withdrawAmount);
        amm.stanley().deposit(withdrawAmount * 1e12);

        uint256 miltonIvTokenBefore = IvToken(amm.stanley().getIvToken()).balanceOf(address(amm.milton()));
        uint256 strategyBalanceBefore = IStrategy(amm.stanley().getStrategyAave()).balanceOf();
        uint256 miltonBalanceBefore = IERC20(amm.usdt()).balanceOf(address(amm.milton()));
        uint256 strategyATokenContractBefore = IERC20(amm.aUsdt()).balanceOf(amm.stanley().getStrategyAave());

        // when
        amm.stanley().withdraw(strategyBalanceBefore);

        // then
        uint256 miltonIvTokenAfter = IvToken(amm.stanley().getIvToken()).balanceOf(address(amm.milton()));
        uint256 strategyBalanceAfter = IStrategy(amm.stanley().getStrategyAave()).balanceOf();
        uint256 miltonBalanceAfter = IERC20(amm.usdt()).balanceOf(address(amm.milton()));
        uint256 strategyATokenContractAfter = IERC20(amm.aUsdt()).balanceOf(amm.stanley().getStrategyAave());

        assertLt(miltonIvTokenAfter, miltonIvTokenBefore, "miltonIvTokenAfter < miltonIvTokenBefore");
        assertLt(
            strategyBalanceAfter,
            strategyBalanceBefore,
            "strategyBalanceAfter < strategyBalanceBefore"
        );

        // Important check!
        assertLt(strategyBalanceAfter, 5e17, "strategyBalanceAfter < 0.5");
        assertGt(miltonBalanceAfter, miltonBalanceBefore, "miltonBalanceAfter > miltonBalanceBefore");
        assertLt(
            strategyATokenContractAfter,
            strategyATokenContractBefore,
            "strategyATokenContractAfter < strategyATokenContractBefore"
        );
    }

    function testShouldWithdrawAllStanleyBalanceFromAAVEWithdrawAllMethod() public {
        // given
        uint256 withdrawAmount = 10 * 1e6;
        UsdtAmm amm = new UsdtAmm(_admin);
        amm.overrideCompoundStrategyWithZeroApr(_admin);

        vm.startPrank(address(amm.milton()));
        deal(amm.usdt(), address(amm.milton()), withdrawAmount);
        amm.stanley().deposit(withdrawAmount * 1e12);

        uint256 miltonIvTokenBefore = IvToken(amm.stanley().getIvToken()).balanceOf(address(amm.milton()));
        uint256 strategyBalanceBefore = IStrategy(amm.stanley().getStrategyAave()).balanceOf();
        uint256 miltonBalanceBefore = IERC20(amm.usdt()).balanceOf(address(amm.milton()));
        uint256 strategyATokenContractBefore = IERC20(amm.aUsdt()).balanceOf(amm.stanley().getStrategyAave());

        // when
        amm.stanley().withdrawAll();

        // then
        uint256 miltonIvTokenAfter = IvToken(amm.stanley().getIvToken()).balanceOf(address(amm.milton()));
        uint256 strategyBalanceAfter = IStrategy(amm.stanley().getStrategyAave()).balanceOf();
        uint256 miltonBalanceAfter = IERC20(amm.usdt()).balanceOf(address(amm.milton()));
        uint256 strategyATokenContractAfter = IERC20(amm.aUsdt()).balanceOf(amm.stanley().getStrategyAave());

        assertLt(miltonIvTokenAfter, miltonIvTokenBefore, "miltonIvTokenAfter < miltonIvTokenBefore");
        assertLt(
            strategyBalanceAfter,
            strategyBalanceBefore,
            "strategyBalanceAfter < strategyBalanceBefore"
        );
        // Important check!
        assertLt(strategyBalanceAfter, 1e17, "strategyBalanceAfter < 1e17");
        assertGt(miltonBalanceAfter, miltonBalanceBefore, "miltonBalanceAfter > miltonBalanceBefore");
        assertLt(
            strategyATokenContractAfter,
            strategyATokenContractBefore,
            "strategyATokenContractAfter < strategyATokenContractBefore"
        );
    }

    function testShouldUnclaimedRewardsFromAAVEEqualsZero() public {
        //given
        uint256 ONE_WEEK_IN_SECONDS = 60 * 60 * 24 * 7;
        uint256 amount = 100_000 * 1e6;
        UsdtAmm amm = new UsdtAmm(_admin);
        amm.overrideCompoundStrategyWithZeroApr(_admin);
        deal(amm.usdt(), address(amm.milton()), 2 * amount);
        vm.startPrank(address(amm.milton()));

        // when
        amm.stanley().deposit(amount * 1e12);
        vm.warp(block.timestamp + ONE_WEEK_IN_SECONDS);
        amm.stanley().deposit(amount * 1e12);

        // then
        uint256 claimable = amm.aaveIncentivesController().getUserUnclaimedRewards(amm.stanley().getStrategyAave());
        assertEq(claimable, 0);
    }

    function testShouldSetNewAAVEStrategy() public {
        // given
        uint256 depositAmount = 1000 * 1e6;
        UsdtAmm amm = new UsdtAmm(_admin);
        amm.overrideCompoundStrategyWithZeroApr(_admin);

        vm.startPrank(address(amm.milton()));
        deal(amm.usdt(), address(amm.milton()), depositAmount);
        amm.stanley().deposit(depositAmount * 1e12);
        vm.stopPrank();

        address strategyV1 = amm.stanley().getStrategyAave();

        uint256 strategyBalanceBefore = IStrategy(strategyV1).balanceOf();
        uint256 strategyAaveV2BalanceBefore = amm.strategyAaveV2().balanceOf();
        uint256 miltonAssetBalanceBefore = IERC20(amm.usdt()).balanceOf(address(amm.milton()));

        // when
        vm.startPrank(_admin);
        amm.stanley().setStrategyAave(address(amm.strategyAaveV2()));

        // then
        uint256 strategyBalanceAfter = IStrategy(strategyV1).balanceOf();
        uint256 strategyAaveV2BalanceAfter = amm.strategyAaveV2().balanceOf();
        uint256 miltonAssetBalanceAfter = IERC20(amm.usdt()).balanceOf(address(amm.milton()));

        assertEq(strategyAaveV2BalanceBefore, 0, "strategyAaveV2BalanceBefore == 0");
        assertEq(strategyBalanceAfter, 0, "strategyBalanceAfter == 0");
        // Great Than Equal because with accrued interest
        assertGe(
            strategyAaveV2BalanceAfter,
            strategyBalanceBefore,
            "strategyAaveV2BalanceAfter >= strategyBalanceBefore"
        );
        assertLt(
            strategyAaveV2BalanceAfter,
            strategyBalanceBefore + 1e12,
            "strategyAaveV2BalanceAfter < strategyBalanceBefore + 1e12"
        );
        assertEq(
            miltonAssetBalanceBefore,
            miltonAssetBalanceAfter,
            "miltonAssetBalanceBefore == miltonAssetBalanceAfter"
        );
    }

    function testShouldMigrateAssetToStrategyWithMaxAPR() public {
        // given
        uint256 depositAmount = 1000 * 1e6;
        UsdtAmm amm = new UsdtAmm(_admin);
        amm.overrideAaveStrategyWithZeroApr(_admin);
        deal(amm.usdt(), address(amm.milton()), depositAmount);
        vm.startPrank(address(amm.milton()));
        amm.stanley().deposit(depositAmount * 1e12);
        vm.stopPrank();
        amm.restoreStrategies(_admin);
        amm.overrideCompoundStrategyWithZeroApr(_admin);

        uint256 miltonIvTokenBefore = IvToken(amm.stanley().getIvToken()).balanceOf(address(amm.milton()));
        uint256 strategyAaveBalanceBefore = IStrategy(amm.stanley().getStrategyAave()).balanceOf();
        uint256 strategyCompoundBalanceBefore = IStrategy(amm.stanley().getStrategyCompound()).balanceOf();
        uint256 miltonAssetBalanceBefore = IERC20(amm.usdt()).balanceOf(address(amm.milton()));
        uint256 miltonTotalBalanceBefore = amm.stanley().totalBalance(address(amm.milton()));

        //when
        vm.startPrank(_admin);
        amm.stanley().migrateAssetToStrategyWithMaxApr();

        //then
        uint256 miltonIvTokenAfter = IvToken(amm.stanley().getIvToken()).balanceOf(address(amm.milton()));
        uint256 strategyAaveBalanceAfter = IStrategy(amm.stanley().getStrategyAave()).balanceOf();
        uint256 strategyCompoundBalanceAfter = IStrategy(amm.stanley().getStrategyCompound()).balanceOf();
        uint256 miltonAssetBalanceAfter = IERC20(amm.usdt()).balanceOf(address(amm.milton()));
        uint256 miltonTotalBalanceAfter = amm.stanley().totalBalance(address(amm.milton()));

        assertEq(miltonIvTokenAfter, miltonIvTokenBefore, "miltonIvTokenAfter == miltonIvTokenBefore");
        assertLt(
            strategyAaveBalanceBefore,
            strategyAaveBalanceAfter,
            "strategyAaveBalanceBefore < strategyAaveBalanceAfter"
        );
        assertGt(
            strategyCompoundBalanceBefore,
            strategyCompoundBalanceAfter,
            "strategyCompoundBalanceBefore > strategyCompoundBalanceAfter"
        );
        assertGe(strategyCompoundBalanceAfter, 0, "strategyCompoundBalanceAfter >= 0");
        assertLe(strategyCompoundBalanceAfter, 1e12, "strategyCompoundBalanceAfter <= 1");
        assertEq(
            miltonAssetBalanceAfter,
            miltonAssetBalanceBefore,
            "miltonAssetBalanceAfter == miltonAssetBalanceBefore"
        );
        assertLe(
            miltonTotalBalanceBefore,
            miltonTotalBalanceAfter + 1e12,
            "miltonTotalBalanceBefore <= miltonTotalBalanceAfter + 1e12"
        );
        assertLe(
            miltonTotalBalanceAfter,
            miltonTotalBalanceBefore + 1e12,
            "miltonTotalBalanceAfter <= miltonTotalBalanceBefore + 1e12"
        );
    }
}

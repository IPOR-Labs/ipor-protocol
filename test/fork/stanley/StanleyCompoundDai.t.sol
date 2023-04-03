// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.16;

import "forge-std/Test.sol";
import "../../../contracts/vault/StanleyDai.sol";
import "../../../contracts/tokens/IvToken.sol";
import "../DaiAmm.sol";

contract StanleyCompoundDaiTest is Test {
    address internal _admin;

    function setUp() public {
        _admin = vm.rememberKey(1);
    }

    function testShouldCompoundAprBeZeroAfterOverride() public {
        // given
        DaiAmm amm = new DaiAmm(_admin);

        // when
        amm.overrideCompoundStrategyWithZeroApr(_admin);

        // then
        assertEq(IStrategy(amm.stanley().getStrategyCompound()).getApr(), 0, "strategyCompoundApr == 0");
    }

    function testShouldCompoundAprGreaterThanAaveApr() public {
        // given
        DaiAmm amm = new DaiAmm(_admin);
        amm.overrideAaveStrategyWithZeroApr(_admin);

        // when
        uint256 compoundApr = IStrategy(amm.stanley().getStrategyCompound()).getApr();
        uint256 aaveApr = IStrategy(amm.stanley().getStrategyAave()).getApr();

        // then
        assertGt(compoundApr, aaveApr, "compoundApr > aaveApr");
    }

    function testShouldAcceptDepositAndTransferTokensIntoCompound() public {
        // given
        uint256 depositAmount = 10 * 1e18;
        DaiAmm amm = new DaiAmm(_admin);
        deal(amm.dai(), address(amm.milton()), depositAmount);
        amm.overrideAaveStrategyWithZeroApr(_admin);

        uint256 miltonIvTokenBefore = IvToken(amm.stanley().getIvToken()).balanceOf(address(amm.milton()));
        uint256 strategyCompoundBalanceBefore = IStrategy(amm.stanley().getStrategyCompound()).balanceOf();
        uint256 miltonDaiBalanceBefore = IERC20(amm.dai()).balanceOf(address(amm.milton()));
        uint256 strategyCTokenContractBefore = IERC20(amm.cDai()).balanceOf(amm.stanley().getStrategyCompound());

        // when
        vm.startPrank(address(amm.milton()));
        amm.stanley().deposit(depositAmount);

        // then
        uint256 miltonIvTokenAfter = IvToken(amm.stanley().getIvToken()).balanceOf(address(amm.milton()));
        uint256 strategyCompoundBalanceAfter = IStrategy(amm.stanley().getStrategyCompound()).balanceOf();
        uint256 miltonDaiBalanceAfter = IERC20(amm.dai()).balanceOf(address(amm.milton()));
        uint256 strategyCTokenContractAfter = IERC20(amm.cDai()).balanceOf(amm.stanley().getStrategyCompound());

        assertEq(miltonIvTokenBefore, 0, "miltonIvTokenBefore == 0");
        assertEq(strategyCompoundBalanceBefore, 0, "strategyCompoundBalanceBefore == 0");
        assertEq(miltonIvTokenAfter, depositAmount, "miltonIvTokenAfter == depositAmount");
        assertGt(
            strategyCompoundBalanceAfter,
            strategyCTokenContractBefore,
            "strategyCompoundBalanceAfter > strategyCTokenContractBefore"
        );
        assertLt(miltonDaiBalanceAfter, miltonDaiBalanceBefore, "miltonDaiBalanceAfter < miltonDaiBalanceBefore");
        assertGt(
            strategyCTokenContractAfter,
            strategyCTokenContractBefore,
            "strategyCTokenContractAfter > strategyCTokenContractBefore"
        );
    }

    function testShouldAcceptDepositTwiceAndTransferTokensIntoCompound() public {
        // given
        uint256 depositAmount = 10 * 1e18;
        DaiAmm amm = new DaiAmm(_admin);
        deal(amm.dai(), address(amm.milton()), 2 * depositAmount);
        amm.overrideAaveStrategyWithZeroApr(_admin);

        uint256 miltonIvTokenBefore = IvToken(amm.stanley().getIvToken()).balanceOf(address(amm.milton()));
        uint256 strategyCompoundBalanceBefore = IStrategy(amm.stanley().getStrategyCompound()).balanceOf();
        uint256 miltonDaiBalanceBefore = IERC20(amm.dai()).balanceOf(address(amm.milton()));
        uint256 strategyCTokenContractBefore = IERC20(amm.cDai()).balanceOf(amm.stanley().getStrategyCompound());

        // when
        vm.startPrank(address(amm.milton()));
        amm.stanley().deposit(depositAmount);
        amm.stanley().deposit(depositAmount);

        // then
        uint256 miltonIvTokenAfter = IvToken(amm.stanley().getIvToken()).balanceOf(address(amm.milton()));
        uint256 strategyCTokenContractAfter = IERC20(amm.cDai()).balanceOf(amm.stanley().getStrategyCompound());
        uint256 miltonDaiBalanceAfter = IERC20(amm.dai()).balanceOf(address(amm.milton()));
        uint256 strategyCompoundBalanceAfter = IStrategy(amm.stanley().getStrategyCompound()).balanceOf();

        assertGt(miltonIvTokenAfter, miltonIvTokenBefore, "miltonIvTokenAfter > miltonIvTokenBefore");
        assertGt(
            strategyCompoundBalanceAfter,
            strategyCompoundBalanceBefore,
            "strategyCompoundBalanceAfter > strategyCompoundBalanceBefore"
        );
        assertLt(miltonDaiBalanceAfter, miltonDaiBalanceBefore, "miltonDaiBalanceAfter < miltonDaiBalanceBefore");
        assertGe(
            strategyCTokenContractAfter,
            strategyCTokenContractBefore,
            "strategyCTokenContractAfter >= strategyCTokenContractBefore"
        );
    }

    function testShouldWithdraw10FromCompound() public {
        //given
        uint256 withdrawAmount = 10 * 1e18;
        DaiAmm amm = new DaiAmm(_admin);
        amm.overrideAaveStrategyWithZeroApr(_admin);

        vm.startPrank(address(amm.milton()));
        deal(amm.dai(), address(amm.milton()), withdrawAmount);
        amm.stanley().deposit(withdrawAmount);

        uint256 miltonIvTokenBefore = IvToken(amm.stanley().getIvToken()).balanceOf(address(amm.milton()));
        uint256 strategyCompoundBalanceBefore = IStrategy(amm.stanley().getStrategyCompound()).balanceOf();
        uint256 miltonDaiBalanceBefore = IERC20(amm.dai()).balanceOf(address(amm.milton()));
        uint256 strategyCTokenContractBefore = IERC20(amm.cDai()).balanceOf(amm.stanley().getStrategyCompound());

        // when
        amm.stanley().withdraw(withdrawAmount);

        // then
        uint256 strategyCompoundBalanceAfter = IStrategy(amm.stanley().getStrategyCompound()).balanceOf();
        uint256 miltonIvTokenAfter = IvToken(amm.stanley().getIvToken()).balanceOf(address(amm.milton()));
        uint256 miltonDaiBalanceAfter = IERC20(amm.dai()).balanceOf(address(amm.milton()));
        uint256 strategyCTokenContractAfter = IERC20(amm.cDai()).balanceOf(amm.stanley().getStrategyCompound());

        assertLt(miltonIvTokenAfter, miltonIvTokenBefore, "miltonIvTokenAfter < miltonIvTokenBefore");
        assertLt(
            strategyCompoundBalanceAfter,
            strategyCompoundBalanceBefore,
            "strategyCompoundBalanceAfter < strategyCompoundBalanceBefore"
        );
        assertGt(miltonDaiBalanceAfter, miltonDaiBalanceBefore, "miltonDaiBalanceAfter > miltonDaiBalanceBefore");
        assertLt(
            strategyCTokenContractAfter,
            strategyCTokenContractBefore,
            "strategyCTokenContractAfter < strategyCTokenContractBefore"
        );
    }

    function testShouldWithdrawAllStanleyBalanceFromCompoundWithdrawMethod() public {
        // given
        uint256 withdrawAmount = 10 * 1e18;
        DaiAmm amm = new DaiAmm(_admin);
        amm.overrideAaveStrategyWithZeroApr(_admin);

        vm.startPrank(address(amm.milton()));
        deal(amm.dai(), address(amm.milton()), withdrawAmount);
        amm.stanley().deposit(withdrawAmount);

        uint256 miltonIvTokenBefore = IvToken(amm.stanley().getIvToken()).balanceOf(address(amm.milton()));
        uint256 strategyCompoundBalanceBefore = IStrategy(amm.stanley().getStrategyCompound()).balanceOf();
        uint256 miltonDaiBalanceBefore = IERC20(amm.dai()).balanceOf(address(amm.milton()));

        // when
        amm.stanley().withdraw(strategyCompoundBalanceBefore);

        // then
        uint256 miltonIvTokenAfter = IvToken(amm.stanley().getIvToken()).balanceOf(address(amm.milton()));
        uint256 strategyCompoundBalanceAfter = IStrategy(amm.stanley().getStrategyCompound()).balanceOf();
        uint256 miltonDaiBalanceAfter = IERC20(amm.dai()).balanceOf(address(amm.milton()));
        uint256 strategyCTokenContractAfter = IERC20(amm.cDai()).balanceOf(amm.stanley().getStrategyCompound());

        assertLt(miltonIvTokenAfter, miltonIvTokenBefore, "miltonIvTokenAfter < miltonIvTokenBefore");
        assertLt(
            strategyCompoundBalanceAfter,
            strategyCompoundBalanceBefore,
            "strategyCompoundBalanceAfter < strategyCompoundBalanceBefore"
        );

        // Important check!
        assertLt(strategyCompoundBalanceAfter, 5e17, "strategyCompoundBalanceAfter < 5e17");
        assertGt(miltonDaiBalanceAfter, miltonDaiBalanceBefore, "miltonDaiBalanceAfter > miltonDaiBalanceBefore");
        assertEq(strategyCTokenContractAfter, 0, "strategyCTokenContractAfter == 0");
    }

    function testShouldWithdrawAllStanleyBalanceFromCompoundWithdrawAllMethod() public {
        // given
        uint256 withdrawAmount = 10 * 1e18;
        DaiAmm amm = new DaiAmm(_admin);
        amm.overrideAaveStrategyWithZeroApr(_admin);

        vm.startPrank(address(amm.milton()));
        deal(amm.dai(), address(amm.milton()), withdrawAmount);
        amm.stanley().deposit(withdrawAmount);

        uint256 miltonIvTokenBefore = IvToken(amm.stanley().getIvToken()).balanceOf(address(amm.milton()));
        uint256 strategyCompoundBalanceBefore = IStrategy(amm.stanley().getStrategyCompound()).balanceOf();
        uint256 miltonDaiBalanceBefore = IERC20(amm.dai()).balanceOf(address(amm.milton()));

        // when
        amm.stanley().withdrawAll();

        // then
        uint256 miltonIvTokenAfter = IvToken(amm.stanley().getIvToken()).balanceOf(address(amm.milton()));
        uint256 strategyCompoundBalanceAfter = IStrategy(amm.stanley().getStrategyCompound()).balanceOf();
        uint256 miltonDaiBalanceAfter = IERC20(amm.dai()).balanceOf(address(amm.milton()));
        uint256 strategyCTokenContractAfter = IERC20(amm.cDai()).balanceOf(amm.stanley().getStrategyCompound());

        assertLt(miltonIvTokenAfter, miltonIvTokenBefore, "miltonIvTokenAfter < miltonIvTokenBefore");
        assertLt(
            strategyCompoundBalanceAfter,
            strategyCompoundBalanceBefore,
            "strategyCompoundBalanceAfter < strategyCompoundBalanceBefore"
        );
        // Important check!
        assertLt(strategyCompoundBalanceAfter, 5e17, "strategyCompoundBalanceAfter < 5e17");
        assertGt(miltonDaiBalanceAfter, miltonDaiBalanceBefore, "miltonDaiBalanceAfter > miltonDaiBalanceBefore");
        assertEq(strategyCTokenContractAfter, 0, "strategyCTokenContractAfter == 0");
    }

    function testShouldSetNewCompoundStrategyForDAI() public {
        // given
        uint256 deposit_loss = 0.000000001 * 1e18;
        uint256 depositAmount = 100_000 * 1e18;
        DaiAmm amm = new DaiAmm(_admin);
        amm.overrideAaveStrategyWithZeroApr(_admin);

        vm.startPrank(address(amm.milton()));
        deal(amm.dai(), address(amm.milton()), depositAmount);
        amm.stanley().deposit(depositAmount);
        vm.stopPrank();

        uint256 strategyCompoundBalanceBefore = amm.strategyCompound().balanceOf();
        uint256 strategyCompoundV2BalanceBefore = amm.strategyCompoundV2().balanceOf();
        uint256 miltonAssetBalanceBefore = IERC20(amm.dai()).balanceOf(address(amm.milton()));

        // when
        vm.startPrank(_admin);
        amm.stanley().setStrategyCompound(address(amm.strategyCompoundV2()));

        // then
        uint256 strategyCompoundBalanceAfter = amm.strategyCompound().balanceOf();
        uint256 strategyCompoundV2BalanceAfter = amm.strategyCompoundV2().balanceOf();
        uint256 miltonAssetBalanceAfter = IERC20(amm.dai()).balanceOf(address(amm.milton()));

        assertGe(
            strategyCompoundBalanceBefore,
            depositAmount - deposit_loss,
            "strategyCompoundBalanceBefore >= depositAmount - deposit_loss"
        );
        assertLe(
            strategyCompoundBalanceBefore,
            depositAmount + 1e18,
            "strategyCompoundBalanceBefore <= depositAmount + 1e18"
        );

        assertEq(strategyCompoundV2BalanceBefore, 0, "strategyCompoundV2BalanceBefore == 0");
        assertEq(strategyCompoundBalanceAfter, 0, "strategyCompoundBalanceAfter == 0");
        // Great Than Equal because with accrued interest
        assertGe(
            strategyCompoundV2BalanceAfter,
            depositAmount - deposit_loss,
            "strategyCompoundV2BalanceAfter >= depositAmount - deposit_loss"
        );
        assertEq(
            miltonAssetBalanceBefore,
            miltonAssetBalanceAfter,
            "miltonAssetBalanceBefore == miltonAssetBalanceAfter"
        );
    }

    function testShouldMigrateAssetToStrategyWithMaxAPR() public {
        // given
        uint256 deposit_loss = 0.000000001 * 1e18;
        uint256 depositAmount = 10 * 1e18;
        DaiAmm amm = new DaiAmm(_admin);
        amm.overrideCompoundStrategyWithZeroApr(_admin);
        deal(amm.dai(), address(amm.milton()), depositAmount);
        vm.startPrank(address(amm.milton()));
        amm.stanley().deposit(depositAmount);
        vm.stopPrank();
        amm.restoreStrategies(_admin);
        amm.overrideAaveStrategyWithZeroApr(_admin);

        uint256 miltonIvTokenBefore = IvToken(amm.stanley().getIvToken()).balanceOf(address(amm.milton()));
        uint256 strategyAaveBalanceBefore = IStrategy(amm.stanley().getStrategyAave()).balanceOf();
        uint256 strategyCompoundBalanceBefore = IStrategy(amm.stanley().getStrategyCompound()).balanceOf();
        uint256 miltonAssetBalanceBefore = IERC20(amm.dai()).balanceOf(address(amm.milton()));
        uint256 miltonTotalBalanceBefore = amm.stanley().totalBalance(address(amm.milton()));

        //when
        vm.startPrank(_admin);
        amm.stanley().migrateAssetToStrategyWithMaxApr();

        //then
        uint256 miltonIvTokenAfter = IvToken(amm.stanley().getIvToken()).balanceOf(address(amm.milton()));
        uint256 strategyAaveBalanceAfter = IStrategy(amm.stanley().getStrategyAave()).balanceOf();
        uint256 strategyCompoundBalanceAfter = IStrategy(amm.stanley().getStrategyCompound()).balanceOf();
        uint256 miltonAssetBalanceAfter = IERC20(amm.dai()).balanceOf(address(amm.milton()));
        uint256 miltonTotalBalanceAfter = amm.stanley().totalBalance(address(amm.milton()));

        assertEq(miltonIvTokenAfter, miltonIvTokenBefore, "miltonIvTokenAfter == miltonIvTokenBefore");
        assertGt(
            strategyAaveBalanceBefore,
            strategyAaveBalanceAfter,
            "strategyAaveBalanceBefore > strategyAaveBalanceAfter"
        );
        assertLt(
            strategyCompoundBalanceBefore,
            strategyCompoundBalanceAfter,
            "strategyCompoundBalanceBefore < strategyCompoundBalanceAfter"
        );
        assertEq(strategyAaveBalanceAfter, 0, "strategyCompoundBalanceAfter >= 0");
        assertEq(
            miltonAssetBalanceAfter,
            miltonAssetBalanceBefore,
            "miltonAssetBalanceAfter == miltonAssetBalanceBefore"
        );
        assertLe(
            miltonTotalBalanceBefore,
            miltonTotalBalanceAfter + deposit_loss,
            "miltonTotalBalanceBefore <= miltonTotalBalanceAfter + deposit_loss"
        );
        assertLe(
            miltonTotalBalanceAfter,
            miltonTotalBalanceBefore + deposit_loss,
            "miltonTotalBalanceAfter <= miltonTotalBalanceBefore + deposit_loss"
        );
    }
}

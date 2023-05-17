// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.16;

import "forge-std/Test.sol";
import "contracts/vault/StanleyUsdc.sol";
import "contracts/tokens/IvToken.sol";
import "../UsdcAmm.sol";

contract StanleyCompoundUsdcTest is Test {
    address internal _admin;

    function setUp() public {
        _admin = vm.rememberKey(1);
    }

    function testShouldCompoundAprBeZeroAfterOverride() public {
        // given
        UsdcAmm amm = new UsdcAmm(_admin);

        // when
        amm.overrideCompoundStrategyWithZeroApr(_admin);

        // then
        assertEq(IStrategy(amm.stanley().getStrategyCompound()).getApr(), 0, "strategyCompoundApr == 0");
    }

    function testShouldCompoundAprGreaterThanAaveApr() public {
        // given
        UsdcAmm amm = new UsdcAmm(_admin);
        amm.overrideAaveStrategyWithZeroApr(_admin);

        // when
        uint256 compoundApr = IStrategy(amm.stanley().getStrategyCompound()).getApr();
        uint256 aaveApr = IStrategy(amm.stanley().getStrategyAave()).getApr();

        // then
        assertGt(compoundApr, aaveApr, "compoundApr > aaveApr");
    }

    function testShouldAcceptDepositAndTransferTokensIntoCompound() public {
        // given
        uint256 depositAmount = 10 * 1e6;
        UsdcAmm amm = new UsdcAmm(_admin);
        deal(amm.usdc(), address(amm.milton()), depositAmount);
        amm.overrideAaveStrategyWithZeroApr(_admin);

        uint256 miltonIvTokenBefore = IvToken(amm.stanley().getIvToken()).balanceOf(address(amm.milton()));
        uint256 strategyBalanceBefore = IStrategy(amm.stanley().getStrategyCompound()).balanceOf();
        uint256 miltonBalanceBefore = IERC20(amm.usdc()).balanceOf(address(amm.milton()));
        uint256 strategyCTokenContractBefore = IERC20(amm.cUsdc()).balanceOf(amm.stanley().getStrategyCompound());

        // when
        vm.startPrank(address(amm.milton()));
        amm.stanley().deposit(depositAmount * 1e12);

        // then
        uint256 miltonIvTokenAfter = IvToken(amm.stanley().getIvToken()).balanceOf(address(amm.milton()));
        uint256 strategyBalanceAfter = IStrategy(amm.stanley().getStrategyCompound()).balanceOf();
        uint256 miltonBalanceAfter = IERC20(amm.usdc()).balanceOf(address(amm.milton()));
        uint256 strategyCTokenContractAfter = IERC20(amm.cUsdc()).balanceOf(amm.stanley().getStrategyCompound());

        assertEq(miltonIvTokenBefore, 0, "miltonIvTokenBefore == 0");
        assertEq(strategyBalanceBefore, 0, "strategyBalanceBefore == 0");
        assertEq(miltonIvTokenAfter, depositAmount * 1e12, "miltonIvTokenAfter == depositAmount");
        assertGt(
            strategyBalanceAfter,
            strategyCTokenContractBefore,
            "strategyBalanceAfter > strategyCTokenContractBefore"
        );
        assertLt(miltonBalanceAfter, miltonBalanceBefore, "miltonBalanceAfter < miltonBalanceBefore");
        assertGt(
            strategyCTokenContractAfter,
            strategyCTokenContractBefore,
            "strategyCTokenContractAfter > strategyCTokenContractBefore"
        );
    }

    function testShouldAcceptDepositTwiceAndTransferTokensIntoCompound() public {
        // given
        uint256 depositAmount = 10 * 1e6;
        UsdcAmm amm = new UsdcAmm(_admin);
        deal(amm.usdc(), address(amm.milton()), 2 * depositAmount);
        amm.overrideAaveStrategyWithZeroApr(_admin);

        uint256 miltonIvTokenBefore = IvToken(amm.stanley().getIvToken()).balanceOf(address(amm.milton()));
        uint256 strategyBalanceBefore = IStrategy(amm.stanley().getStrategyCompound()).balanceOf();
        uint256 miltonBalanceBefore = IERC20(amm.usdc()).balanceOf(address(amm.milton()));
        uint256 strategyCTokenContractBefore = IERC20(amm.cUsdc()).balanceOf(amm.stanley().getStrategyCompound());

        // when
        vm.startPrank(address(amm.milton()));
        amm.stanley().deposit(depositAmount * 1e12);
        amm.stanley().deposit(depositAmount * 1e12);

        // then
        uint256 miltonIvTokenAfter = IvToken(amm.stanley().getIvToken()).balanceOf(address(amm.milton()));
        uint256 strategyCTokenContractAfter = IERC20(amm.cUsdc()).balanceOf(amm.stanley().getStrategyCompound());
        uint256 miltonBalanceAfter = IERC20(amm.usdc()).balanceOf(address(amm.milton()));
        uint256 strategyBalanceAfter = IStrategy(amm.stanley().getStrategyCompound()).balanceOf();

        assertGt(miltonIvTokenAfter, miltonIvTokenBefore, "miltonIvTokenAfter > miltonIvTokenBefore");
        assertGt(
            strategyBalanceAfter,
            strategyBalanceBefore,
            "strategyBalanceAfter > strategyBalanceBefore"
        );
        assertLt(miltonBalanceAfter, miltonBalanceBefore, "miltonBalanceAfter < miltonBalanceBefore");
        assertGe(
            strategyCTokenContractAfter,
            strategyCTokenContractBefore,
            "strategyCTokenContractAfter >= strategyCTokenContractBefore"
        );
    }

    function testShouldWithdraw10FromCompound() public {
        //given
        uint256 withdrawAmount = 10 * 1e6;
        UsdcAmm amm = new UsdcAmm(_admin);
        amm.overrideAaveStrategyWithZeroApr(_admin);

        vm.startPrank(address(amm.milton()));
        deal(amm.usdc(), address(amm.milton()), withdrawAmount);
        amm.stanley().deposit(withdrawAmount * 1e12);

        uint256 miltonIvTokenBefore = IvToken(amm.stanley().getIvToken()).balanceOf(address(amm.milton()));
        uint256 strategyBalanceBefore = IStrategy(amm.stanley().getStrategyCompound()).balanceOf();
        uint256 miltonBalanceBefore = IERC20(amm.usdc()).balanceOf(address(amm.milton()));
        uint256 strategyCTokenContractBefore = IERC20(amm.cUsdc()).balanceOf(amm.stanley().getStrategyCompound());

        // when
        amm.stanley().withdraw(withdrawAmount * 1e12);

        // then
        uint256 strategyBalanceAfter = IStrategy(amm.stanley().getStrategyCompound()).balanceOf();
        uint256 miltonIvTokenAfter = IvToken(amm.stanley().getIvToken()).balanceOf(address(amm.milton()));
        uint256 miltonBalanceAfter = IERC20(amm.usdc()).balanceOf(address(amm.milton()));
        uint256 strategyCTokenContractAfter = IERC20(amm.cUsdc()).balanceOf(amm.stanley().getStrategyCompound());

        assertLt(miltonIvTokenAfter, miltonIvTokenBefore, "miltonIvTokenAfter < miltonIvTokenBefore");
        assertLt(
            strategyBalanceAfter,
            strategyBalanceBefore,
            "strategyBalanceAfter < strategyBalanceBefore"
        );
        assertGt(miltonBalanceAfter, miltonBalanceBefore, "miltonBalanceAfter > miltonBalanceBefore");
        assertLt(
            strategyCTokenContractAfter,
            strategyCTokenContractBefore,
            "strategyCTokenContractAfter < strategyCTokenContractBefore"
        );
    }

    function testShouldWithdrawAllStanleyBalanceFromCompoundWithdrawMethod() public {
        // given
        uint256 withdrawAmount = 100 * 1e6;
        UsdcAmm amm = new UsdcAmm(_admin);
        amm.overrideAaveStrategyWithZeroApr(_admin);

        vm.startPrank(address(amm.milton()));
        deal(amm.usdc(), address(amm.milton()), withdrawAmount);
        amm.stanley().deposit(withdrawAmount * 1e12);

        uint256 miltonIvTokenBefore = IvToken(amm.stanley().getIvToken()).balanceOf(address(amm.milton()));
        uint256 strategyBalanceBefore = IStrategy(amm.stanley().getStrategyCompound()).balanceOf();
        uint256 miltonBalanceBefore = IERC20(amm.usdc()).balanceOf(address(amm.milton()));

        // when
        amm.stanley().withdraw(strategyBalanceBefore);

        // then
        uint256 miltonIvTokenAfter = IvToken(amm.stanley().getIvToken()).balanceOf(address(amm.milton()));
        uint256 strategyBalanceAfter = IStrategy(amm.stanley().getStrategyCompound()).balanceOf();
        uint256 miltonBalanceAfter = IERC20(amm.usdc()).balanceOf(address(amm.milton()));
        uint256 strategyATokenContractAfter = IERC20(amm.aUsdc()).balanceOf(amm.stanley().getStrategyCompound());

        assertLt(miltonIvTokenAfter, miltonIvTokenBefore, "miltonIvTokenAfter < miltonIvTokenBefore");
        assertLt(
            strategyBalanceAfter,
            strategyBalanceBefore,
            "strategyBalanceAfter < strategyBalanceBefore"
        );

        // Important check!
        assertLt(strategyBalanceAfter, 5e17, "strategyBalanceAfter < 5e17");
        assertGt(miltonBalanceAfter, miltonBalanceBefore, "miltonBalanceAfter > miltonBalanceBefore");
        assertEq(strategyATokenContractAfter, 0, "strategyATokenContractAfter == 0");
    }

    function testShouldWithdrawAllStanleyBalanceFromCompoundWithdrawAllMethod() public {
        // given
        uint256 withdrawAmount = 10 * 1e6;
        UsdcAmm amm = new UsdcAmm(_admin);
        amm.overrideAaveStrategyWithZeroApr(_admin);

        vm.startPrank(address(amm.milton()));
        deal(amm.usdc(), address(amm.milton()), withdrawAmount);
        amm.stanley().deposit(withdrawAmount * 1e12);

        uint256 miltonIvTokenBefore = IvToken(amm.stanley().getIvToken()).balanceOf(address(amm.milton()));
        uint256 strategyBalanceBefore = IStrategy(amm.stanley().getStrategyCompound()).balanceOf();
        uint256 miltonBalanceBefore = IERC20(amm.usdc()).balanceOf(address(amm.milton()));

        // when
        amm.stanley().withdrawAll();

        // then
        uint256 miltonIvTokenAfter = IvToken(amm.stanley().getIvToken()).balanceOf(address(amm.milton()));
        uint256 strategyBalanceAfter = IStrategy(amm.stanley().getStrategyCompound()).balanceOf();
        uint256 miltonBalanceAfter = IERC20(amm.usdc()).balanceOf(address(amm.milton()));
        uint256 strategyATokenContractAfter = IERC20(amm.aUsdc()).balanceOf(amm.stanley().getStrategyCompound());

        assertLt(miltonIvTokenAfter, miltonIvTokenBefore, "miltonIvTokenAfter < miltonIvTokenBefore");
        assertLt(
            strategyBalanceAfter,
            strategyBalanceBefore,
            "strategyBalanceAfter < strategyBalanceBefore"
        );
        // Important check!
        assertLt(strategyBalanceAfter, 5e17, "strategyBalanceAfter < 5e17");
        assertGt(miltonBalanceAfter, miltonBalanceBefore, "miltonBalanceAfter > miltonBalanceBefore");
        assertEq(strategyATokenContractAfter, 0, "strategyATokenContractAfter == 0");
    }

    function testShouldSetNewCompoundStrategyForUSDC() public {
        // given
        uint256 deposit_loss = 3e12;
        uint256 depositAmount = 100_000 * 1e6;
        UsdcAmm amm = new UsdcAmm(_admin);
        amm.overrideAaveStrategyWithZeroApr(_admin);

        vm.startPrank(address(amm.milton()));
        deal(amm.usdc(), address(amm.milton()), depositAmount);
        amm.stanley().deposit(depositAmount * 1e12);
        vm.stopPrank();

        address strategyV1 = amm.stanley().getStrategyCompound();

        uint256 strategyBalanceBefore = IStrategy(strategyV1).balanceOf();
        uint256 strategyCompoundV2BalanceBefore = amm.strategyCompoundV2().balanceOf();
        uint256 miltonAssetBalanceBefore = IERC20(amm.usdc()).balanceOf(address(amm.milton()));

        // when
        vm.startPrank(_admin);
        amm.stanley().setStrategyCompound(address(amm.strategyCompoundV2()));

        // then
        uint256 strategyBalanceAfter = IStrategy(strategyV1).balanceOf();
        uint256 strategyCompoundV2BalanceAfter = amm.strategyCompoundV2().balanceOf();
        uint256 miltonAssetBalanceAfter = IERC20(amm.usdc()).balanceOf(address(amm.milton()));

        assertGe(
            strategyBalanceBefore + deposit_loss,
            depositAmount * 1e12 - deposit_loss,
            "strategyBalanceBefore >= depositAmount * 1e12 - deposit_loss"
        );
        assertLe(
            strategyBalanceBefore,
            depositAmount * 1e12,
            "strategyBalanceBefore <= depositAmount * 1e12"
        );

        assertEq(strategyCompoundV2BalanceBefore, 0, "strategyCompoundV2BalanceBefore == 0");
        assertLe(strategyBalanceAfter, deposit_loss, "strategyBalanceAfter <= deposit_loss");
        // Great Than Equal because with accrued interest
        assertGe(
            strategyCompoundV2BalanceAfter,
            depositAmount * 1e12 - deposit_loss,
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
        uint256 deposit_loss = 1e12;
        uint256 depositAmount = 10 * 1e6;
        UsdcAmm amm = new UsdcAmm(_admin);
        amm.overrideCompoundStrategyWithZeroApr(_admin);
        deal(amm.usdc(), address(amm.milton()), depositAmount);
        vm.startPrank(address(amm.milton()));
        amm.stanley().deposit(depositAmount * 1e12);
        vm.stopPrank();
        amm.restoreStrategies(_admin);
        amm.overrideAaveStrategyWithZeroApr(_admin);

        uint256 miltonIvTokenBefore = IvToken(amm.stanley().getIvToken()).balanceOf(address(amm.milton()));
        uint256 strategyAaveBalanceBefore = IStrategy(amm.stanley().getStrategyAave()).balanceOf();
        uint256 strategyCompoundBalanceBefore = IStrategy(amm.stanley().getStrategyCompound()).balanceOf();
        uint256 miltonAssetBalanceBefore = IERC20(amm.usdc()).balanceOf(address(amm.milton()));
        uint256 miltonTotalBalanceBefore = amm.stanley().totalBalance(address(amm.milton()));

        //when
        vm.startPrank(_admin);
        amm.stanley().migrateAssetToStrategyWithMaxApr();

        //then
        uint256 miltonIvTokenAfter = IvToken(amm.stanley().getIvToken()).balanceOf(address(amm.milton()));
        uint256 strategyAaveBalanceAfter = IStrategy(amm.stanley().getStrategyAave()).balanceOf();
        uint256 strategyCompoundBalanceAfter = IStrategy(amm.stanley().getStrategyCompound()).balanceOf();
        uint256 miltonAssetBalanceAfter = IERC20(amm.usdc()).balanceOf(address(amm.milton()));
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
        assertEq(strategyAaveBalanceAfter, 0, "strategyCompoundBalanceAfter == 0");
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
            miltonTotalBalanceBefore,
            "miltonTotalBalanceAfter <= miltonTotalBalanceBefore"
        );
    }
}

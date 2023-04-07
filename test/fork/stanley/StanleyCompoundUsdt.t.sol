// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.16;

import "forge-std/Test.sol";
import "../../../contracts/vault/StanleyUsdt.sol";
import "../../../contracts/tokens/IvToken.sol";
import "../UsdtAmm.sol";

contract StanleyCompoundUsdtTest is Test {
    address internal _admin;

    function setUp() public {
        _admin = vm.rememberKey(1);
    }

    function testShouldCompoundAprBeZeroAfterOverride() public {
        // given
        UsdtAmm amm = new UsdtAmm(_admin);

        // when
        amm.overrideCompoundStrategyWithZeroApr(_admin);

        // then
        assertEq(IStrategy(amm.stanley().getStrategyCompound()).getApr(), 0, "strategyCompoundApr == 0");
    }

    function testShouldCompoundAprGreaterThanAaveApr() public {
        // given
        UsdtAmm amm = new UsdtAmm(_admin);
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
        UsdtAmm amm = new UsdtAmm(_admin);
        deal(amm.usdt(), address(amm.milton()), depositAmount);
        amm.overrideAaveStrategyWithZeroApr(_admin);

        uint256 miltonIvTokenBefore = IvToken(amm.stanley().getIvToken()).balanceOf(address(amm.milton()));
        uint256 strategyCompoundBalanceBefore = IStrategy(amm.stanley().getStrategyCompound()).balanceOf();
        uint256 miltonUsdtBalanceBefore = IERC20(amm.usdt()).balanceOf(address(amm.milton()));
        uint256 strategyCTokenContractBefore = IERC20(amm.cUsdt()).balanceOf(amm.stanley().getStrategyCompound());

        // when
        vm.startPrank(address(amm.milton()));
        amm.stanley().deposit(depositAmount * 1e12);

        // then
        uint256 miltonIvTokenAfter = IvToken(amm.stanley().getIvToken()).balanceOf(address(amm.milton()));
        uint256 strategyCompoundBalanceAfter = IStrategy(amm.stanley().getStrategyCompound()).balanceOf();
        uint256 miltonUsdtBalanceAfter = IERC20(amm.usdt()).balanceOf(address(amm.milton()));
        uint256 strategyCTokenContractAfter = IERC20(amm.cUsdt()).balanceOf(amm.stanley().getStrategyCompound());

        assertEq(miltonIvTokenBefore, 0, "miltonIvTokenBefore == 0");
        assertEq(strategyCompoundBalanceBefore, 0, "strategyCompoundBalanceBefore == 0");
        assertEq(miltonIvTokenAfter, depositAmount * 1e12, "miltonIvTokenAfter == depositAmount");
        assertGt(
            strategyCompoundBalanceAfter,
            strategyCTokenContractBefore,
            "strategyCompoundBalanceAfter > strategyCTokenContractBefore"
        );
        assertLt(miltonUsdtBalanceAfter, miltonUsdtBalanceBefore, "miltonUsdtBalanceAfter < miltonUsdtBalanceBefore");
        assertGt(
            strategyCTokenContractAfter,
            strategyCTokenContractBefore,
            "strategyCTokenContractAfter > strategyCTokenContractBefore"
        );
    }

    function testShouldAcceptDepositTwiceAndTransferTokensIntoCompound() public {
        // given
        uint256 depositAmount = 10 * 1e6;
        UsdtAmm amm = new UsdtAmm(_admin);
        deal(amm.usdt(), address(amm.milton()), 2 * depositAmount);
        amm.overrideAaveStrategyWithZeroApr(_admin);

        uint256 miltonIvTokenBefore = IvToken(amm.stanley().getIvToken()).balanceOf(address(amm.milton()));
        uint256 strategyCompoundBalanceBefore = IStrategy(amm.stanley().getStrategyCompound()).balanceOf();
        uint256 miltonUsdtBalanceBefore = IERC20(amm.usdt()).balanceOf(address(amm.milton()));
        uint256 strategyCTokenContractBefore = IERC20(amm.cUsdt()).balanceOf(amm.stanley().getStrategyCompound());

        // when
        vm.startPrank(address(amm.milton()));
        amm.stanley().deposit(depositAmount * 1e12);
        amm.stanley().deposit(depositAmount * 1e12);

        // then
        uint256 miltonIvTokenAfter = IvToken(amm.stanley().getIvToken()).balanceOf(address(amm.milton()));
        uint256 strategyCTokenContractAfter = IERC20(amm.cUsdt()).balanceOf(amm.stanley().getStrategyCompound());
        uint256 miltonUsdtBalanceAfter = IERC20(amm.usdt()).balanceOf(address(amm.milton()));
        uint256 strategyCompoundBalanceAfter = IStrategy(amm.stanley().getStrategyCompound()).balanceOf();

        assertGt(miltonIvTokenAfter, miltonIvTokenBefore, "miltonIvTokenAfter > miltonIvTokenBefore");
        assertGt(
            strategyCompoundBalanceAfter,
            strategyCompoundBalanceBefore,
            "strategyCompoundBalanceAfter > strategyCompoundBalanceBefore"
        );
        assertLt(miltonUsdtBalanceAfter, miltonUsdtBalanceBefore, "miltonUsdtBalanceAfter < miltonUsdtBalanceBefore");
        assertGe(
            strategyCTokenContractAfter,
            strategyCTokenContractBefore,
            "strategyCTokenContractAfter >= strategyCTokenContractBefore"
        );
    }

    function testShouldWithdraw10FromCompound() public {
        //given
        uint256 withdrawAmount = 10 * 1e6;
        UsdtAmm amm = new UsdtAmm(_admin);
        amm.overrideAaveStrategyWithZeroApr(_admin);

        vm.startPrank(address(amm.milton()));
        deal(amm.usdt(), address(amm.milton()), withdrawAmount);
        amm.stanley().deposit(withdrawAmount * 1e12);

        uint256 miltonIvTokenBefore = IvToken(amm.stanley().getIvToken()).balanceOf(address(amm.milton()));
        uint256 strategyCompoundBalanceBefore = IStrategy(amm.stanley().getStrategyCompound()).balanceOf();
        uint256 miltonUsdtBalanceBefore = IERC20(amm.usdt()).balanceOf(address(amm.milton()));
        uint256 strategyCTokenContractBefore = IERC20(amm.cUsdt()).balanceOf(amm.stanley().getStrategyCompound());

        // when
        amm.stanley().withdraw(withdrawAmount * 1e12);

        // then
        uint256 strategyCompoundBalanceAfter = IStrategy(amm.stanley().getStrategyCompound()).balanceOf();
        uint256 miltonIvTokenAfter = IvToken(amm.stanley().getIvToken()).balanceOf(address(amm.milton()));
        uint256 miltonUsdtBalanceAfter = IERC20(amm.usdt()).balanceOf(address(amm.milton()));
        uint256 strategyCTokenContractAfter = IERC20(amm.cUsdt()).balanceOf(amm.stanley().getStrategyCompound());

        assertLt(miltonIvTokenAfter, miltonIvTokenBefore, "miltonIvTokenAfter < miltonIvTokenBefore");
        assertLt(
            strategyCompoundBalanceAfter,
            strategyCompoundBalanceBefore,
            "strategyCompoundBalanceAfter < strategyCompoundBalanceBefore"
        );
        assertGt(miltonUsdtBalanceAfter, miltonUsdtBalanceBefore, "miltonUsdtBalanceAfter > miltonUsdtBalanceBefore");
        assertLt(
            strategyCTokenContractAfter,
            strategyCTokenContractBefore,
            "strategyCTokenContractAfter < strategyCTokenContractBefore"
        );
    }

    function testShouldWithdrawAllStanleyBalanceFromCompoundWithdrawMethod() public {
        // given
        uint256 withdrawAmount = 100 * 1e6;
        UsdtAmm amm = new UsdtAmm(_admin);
        amm.overrideAaveStrategyWithZeroApr(_admin);

        vm.startPrank(address(amm.milton()));
        deal(amm.usdt(), address(amm.milton()), withdrawAmount);
        amm.stanley().deposit(withdrawAmount * 1e12);

        uint256 miltonIvTokenBefore = IvToken(amm.stanley().getIvToken()).balanceOf(address(amm.milton()));
        uint256 strategyCompoundBalanceBefore = IStrategy(amm.stanley().getStrategyCompound()).balanceOf();
        uint256 miltonUsdtBalanceBefore = IERC20(amm.usdt()).balanceOf(address(amm.milton()));

        // when
        amm.stanley().withdraw(strategyCompoundBalanceBefore);

        // then
        uint256 miltonIvTokenAfter = IvToken(amm.stanley().getIvToken()).balanceOf(address(amm.milton()));
        uint256 strategyCompoundBalanceAfter = IStrategy(amm.stanley().getStrategyCompound()).balanceOf();
        uint256 miltonUsdtBalanceAfter = IERC20(amm.usdt()).balanceOf(address(amm.milton()));
        uint256 strategyATokenContractAfter = IERC20(amm.aUsdt()).balanceOf(amm.stanley().getStrategyCompound());

        assertLt(miltonIvTokenAfter, miltonIvTokenBefore, "miltonIvTokenAfter < miltonIvTokenBefore");
        assertLt(
            strategyCompoundBalanceAfter,
            strategyCompoundBalanceBefore,
            "strategyCompoundBalanceAfter < strategyCompoundBalanceBefore"
        );

        // Important check!
        assertLt(strategyCompoundBalanceAfter, 5e17, "strategyCompoundBalanceAfter < 5e17");
        assertGt(miltonUsdtBalanceAfter, miltonUsdtBalanceBefore, "miltonUsdtBalanceAfter > miltonUsdtBalanceBefore");
        assertEq(strategyATokenContractAfter, 0, "strategyATokenContractAfter == 0");
    }

    function testShouldWithdrawAllStanleyBalanceFromCompoundWithdrawAllMethod() public {
        // given
        uint256 withdrawAmount = 10 * 1e6;
        UsdtAmm amm = new UsdtAmm(_admin);
        amm.overrideAaveStrategyWithZeroApr(_admin);

        vm.startPrank(address(amm.milton()));
        deal(amm.usdt(), address(amm.milton()), withdrawAmount);
        amm.stanley().deposit(withdrawAmount * 1e12);

        uint256 miltonIvTokenBefore = IvToken(amm.stanley().getIvToken()).balanceOf(address(amm.milton()));
        uint256 strategyCompoundBalanceBefore = IStrategy(amm.stanley().getStrategyCompound()).balanceOf();
        uint256 miltonUsdtBalanceBefore = IERC20(amm.usdt()).balanceOf(address(amm.milton()));

        // when
        amm.stanley().withdrawAll();

        // then
        uint256 miltonIvTokenAfter = IvToken(amm.stanley().getIvToken()).balanceOf(address(amm.milton()));
        uint256 strategyCompoundBalanceAfter = IStrategy(amm.stanley().getStrategyCompound()).balanceOf();
        uint256 miltonUsdtBalanceAfter = IERC20(amm.usdt()).balanceOf(address(amm.milton()));
        uint256 strategyATokenContractAfter = IERC20(amm.aUsdt()).balanceOf(amm.stanley().getStrategyCompound());

        assertLt(miltonIvTokenAfter, miltonIvTokenBefore, "miltonIvTokenAfter < miltonIvTokenBefore");
        assertLt(
            strategyCompoundBalanceAfter,
            strategyCompoundBalanceBefore,
            "strategyCompoundBalanceAfter < strategyCompoundBalanceBefore"
        );
        // Important check!
        assertLt(strategyCompoundBalanceAfter, 5e17, "strategyCompoundBalanceAfter < 5e17");
        assertGt(miltonUsdtBalanceAfter, miltonUsdtBalanceBefore, "miltonUsdtBalanceAfter > miltonUsdtBalanceBefore");
        assertEq(strategyATokenContractAfter, 0, "strategyATokenContractAfter == 0");
    }

    function testShouldSetNewCompoundStrategyForUSDT() public {
        // given
        uint256 deposit_loss = 3e12;
        uint256 depositAmount = 100_000 * 1e6;
        UsdtAmm amm = new UsdtAmm(_admin);
        amm.overrideAaveStrategyWithZeroApr(_admin);

        vm.startPrank(address(amm.milton()));
        deal(amm.usdt(), address(amm.milton()), depositAmount);
        amm.stanley().deposit(depositAmount * 1e12);
        vm.stopPrank();

        uint256 strategyCompoundBalanceBefore = amm.strategyCompound().balanceOf();
        uint256 strategyCompoundV2BalanceBefore = amm.strategyCompoundV2().balanceOf();
        uint256 miltonAssetBalanceBefore = IERC20(amm.usdt()).balanceOf(address(amm.milton()));

        // when
        vm.startPrank(_admin);
        amm.stanley().setStrategyCompound(address(amm.strategyCompoundV2()));

        // then
        uint256 strategyCompoundBalanceAfter = amm.strategyCompound().balanceOf();
        uint256 strategyCompoundV2BalanceAfter = amm.strategyCompoundV2().balanceOf();
        uint256 miltonAssetBalanceAfter = IERC20(amm.usdt()).balanceOf(address(amm.milton()));

        assertGe(
            strategyCompoundBalanceBefore + deposit_loss,
            depositAmount * 1e12 - deposit_loss,
            "strategyCompoundBalanceBefore >= depositAmount * 1e12 - deposit_loss"
        );
        assertLe(
            strategyCompoundBalanceBefore,
            depositAmount * 1e12,
            "strategyCompoundBalanceBefore <= depositAmount * 1e12"
        );

        assertEq(strategyCompoundV2BalanceBefore, 0, "strategyCompoundV2BalanceBefore == 0");
        assertLe(strategyCompoundBalanceAfter, deposit_loss, "strategyCompoundBalanceAfter <= deposit_loss");
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
        UsdtAmm amm = new UsdtAmm(_admin);
        amm.overrideCompoundStrategyWithZeroApr(_admin);
        deal(amm.usdt(), address(amm.milton()), depositAmount);
        vm.startPrank(address(amm.milton()));
        amm.stanley().deposit(depositAmount * 1e12);
        vm.stopPrank();
        amm.restoreStrategies(_admin);
        amm.overrideAaveStrategyWithZeroApr(_admin);

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

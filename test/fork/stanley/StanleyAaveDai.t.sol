// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.16;

import "forge-std/Test.sol";
import "../../../contracts/vault/StanleyDai.sol";
import "../../../contracts/tokens/IvToken.sol";
import "../DaiAmm.sol";

contract StanleyAaveDaiTest is Test {
    address internal _admin;

    function setUp() public {
        _admin = vm.rememberKey(1);
    }

    function testShouldAcceptDepositAndTransferTokensIntoAAVE() public {
        // given
        uint256 depositAmount = 10 * 1e18;
        DaiAmm amm = new DaiAmm(_admin);
        deal(amm.dai(), address(amm.milton()), depositAmount);
        amm.overrideCompoundStrategyWithZeroApr(_admin); // force Compound to have 0% APR to deposit to AAVE

        uint256 miltonIvTokenBefore = IvToken(amm.stanley().getIvToken()).balanceOf(address(amm.milton()));
        uint256 strategyAaveBalanceBefore = amm.strategyAave().balanceOf();
        uint256 miltonDaiBalanceBefore = IERC20(amm.dai()).balanceOf(address(amm.milton()));
        uint256 strategyATokenContractBefore = IERC20(amm.aDai()).balanceOf(address(amm.strategyAave()));

        // when
        vm.startPrank(address(amm.milton()));
        amm.stanley().deposit(depositAmount);

        // then
        uint256 miltonIvTokenAfter = IvToken(amm.stanley().getIvToken()).balanceOf(address(amm.milton()));
        uint256 strategyAaveBalanceAfter = amm.strategyAave().balanceOf();
        uint256 miltonDaiBalanceAfter = IERC20(amm.dai()).balanceOf(address(amm.milton()));
        uint256 strategyATokenContractAfter = IERC20(amm.aDai()).balanceOf(address(amm.strategyAave()));

        assertEq(miltonIvTokenBefore, 0, "miltonIvTokenBefore == 0");
        assertEq(strategyAaveBalanceBefore, 0, "strategyAaveBalanceBefore == 0");
        assertGe(miltonIvTokenAfter, 9999999999999999999, "miltonIvTokenAfter >= 9999999999999999999");
        assertGe(strategyAaveBalanceAfter, 9999999999999999999, "strategyAaveBalanceAfter >= 9999999999999999999");
        assertEq(
            miltonDaiBalanceAfter,
            miltonDaiBalanceBefore - depositAmount,
            "miltonDaiBalanceAfter == miltonDaiBalanceBefore - depositAmount"
        );
        assertGe(
            strategyATokenContractAfter - strategyATokenContractBefore,
            depositAmount,
            "strategyATokenContractAfter - strategyATokenContractBefore >= depositAmount"
        );
    }

    function testShouldAcceptDepositTwiceAndTransferTokensIntoAAVE() public {
        // given
        uint256 depositAmount = 10 * 1e18;
        DaiAmm amm = new DaiAmm(_admin);
        deal(amm.dai(), address(amm.milton()), 2 * depositAmount);
        amm.overrideCompoundStrategyWithZeroApr(_admin); // force Compound to have 0% APR to deposit to AAVE

        uint256 miltonIvTokenBefore = IvToken(amm.stanley().getIvToken()).balanceOf(address(amm.milton()));
        uint256 strategyAaveBalanceBefore = amm.strategyAave().balanceOf();
        uint256 miltonDaiBalanceBefore = IERC20(amm.dai()).balanceOf(address(amm.milton()));
        uint256 strategyATokenContractBefore = IERC20(amm.aDai()).balanceOf(address(amm.strategyAave()));

        // when
        vm.startPrank(address(amm.milton()));
        amm.stanley().deposit(depositAmount);
        amm.stanley().deposit(depositAmount);

        // then
        uint256 miltonIvTokenAfter = IvToken(amm.stanley().getIvToken()).balanceOf(address(amm.milton()));
        uint256 strategyATokenContractAfter = IERC20(amm.aDai()).balanceOf(address(amm.strategyAave()));
        uint256 miltonDaiBalanceAfter = IERC20(amm.dai()).balanceOf(address(amm.milton()));
        uint256 strategyAaveBalanceAfter = amm.strategyAave().balanceOf();

        assertGe(miltonIvTokenAfter, miltonIvTokenBefore, "miltonIvTokenAfter >= miltonIvTokenBefore");
        assertGt(
            strategyAaveBalanceAfter,
            strategyAaveBalanceBefore,
            "strategyAaveBalanceAfter > strategyAaveBalanceBefore"
        );
        assertLt(miltonDaiBalanceAfter, miltonDaiBalanceBefore, "miltonDaiBalanceAfter < miltonDaiBalanceBefore");
        assertGt(
            strategyATokenContractAfter,
            strategyATokenContractBefore,
            "strategyATokenContractAfter > strategyATokenContractBefore"
        );
    }

    function testShouldWithdraw10FromAAVE() public {
        //given
        uint256 withdrawAmount = 10 * 1e18;
        DaiAmm amm = new DaiAmm(_admin);
        amm.overrideCompoundStrategyWithZeroApr(_admin); // force Compound to have 0% APR to deposit to AAVE

        vm.startPrank(address(amm.milton()));
        deal(amm.dai(), address(amm.milton()), withdrawAmount);
        amm.stanley().deposit(withdrawAmount);

        uint256 miltonIvTokenBefore = IvToken(amm.stanley().getIvToken()).balanceOf(address(amm.milton()));
        uint256 strategyAaveBalanceBefore = amm.strategyAave().balanceOf();
        uint256 miltonDaiBalanceBefore = IERC20(amm.dai()).balanceOf(address(amm.milton()));
        uint256 strategyATokenContractBefore = IERC20(amm.aDai()).balanceOf(address(amm.strategyAave()));

        // when
        amm.stanley().withdraw(withdrawAmount);

        // then
        uint256 strategyAaveBalanceAfter = amm.strategyAave().balanceOf();
        uint256 miltonIvTokenAfter = IvToken(amm.stanley().getIvToken()).balanceOf(address(amm.milton()));
        uint256 miltonDaiBalanceAfter = IERC20(amm.dai()).balanceOf(address(amm.milton()));
        uint256 strategyATokenContractAfter = IERC20(amm.aDai()).balanceOf(address(amm.strategyAave()));

        assertLt(miltonIvTokenAfter, miltonIvTokenBefore, "miltonIvTokenAfter < miltonIvTokenBefore");
        assertLt(
            strategyAaveBalanceAfter,
            strategyAaveBalanceBefore,
            "strategyAaveBalanceAfter < strategyAaveBalanceBefore"
        );
        assertGe(miltonDaiBalanceAfter, miltonDaiBalanceBefore, "miltonDaiBalanceAfter >= miltonDaiBalanceBefore");
        assertLt(
            strategyATokenContractAfter,
            strategyATokenContractBefore,
            "strategyATokenContractAfter < strategyATokenContractBefore"
        );
    }

    function testShouldWithdrawAllStanleyBalanceFromAAVEWithdrawMethod() public {
        // given
        uint256 withdrawAmount = 10 * 1e18;
        DaiAmm amm = new DaiAmm(_admin);
        amm.overrideCompoundStrategyWithZeroApr(_admin); // force Compound to have 0% APR to deposit to AAVE

        vm.startPrank(address(amm.milton()));
        deal(amm.dai(), address(amm.milton()), withdrawAmount);
        amm.stanley().deposit(withdrawAmount);

        uint256 miltonIvTokenBefore = IvToken(amm.stanley().getIvToken()).balanceOf(address(amm.milton()));
        uint256 strategyAaveBalanceBefore = amm.strategyAave().balanceOf();
        uint256 miltonDaiBalanceBefore = IERC20(amm.dai()).balanceOf(address(amm.milton()));
        uint256 strategyATokenContractBefore = IERC20(amm.aDai()).balanceOf(address(amm.strategyAave()));

        // when
        amm.stanley().withdraw(strategyAaveBalanceBefore);

        // then
        uint256 miltonIvTokenAfter = IvToken(amm.stanley().getIvToken()).balanceOf(address(amm.milton()));
        uint256 strategyAaveBalanceAfter = amm.strategyAave().balanceOf();
        uint256 miltonDaiBalanceAfter = IERC20(amm.dai()).balanceOf(address(amm.milton()));
        uint256 strategyATokenContractAfter = IERC20(amm.aDai()).balanceOf(address(amm.strategyAave()));

        assertLt(miltonIvTokenAfter, miltonIvTokenBefore, "miltonIvTokenAfter < miltonIvTokenBefore");
        assertLt(
            strategyAaveBalanceAfter,
            strategyAaveBalanceBefore,
            "strategyAaveBalanceAfter < strategyAaveBalanceBefore"
        );

        // Important check!
        assertLt(strategyAaveBalanceAfter, 1e12, "strategyAaveBalanceAfter < 1e12");
        assertGt(miltonDaiBalanceAfter, miltonDaiBalanceBefore, "miltonDaiBalanceAfter > miltonDaiBalanceBefore");
        assertLt(
            strategyATokenContractAfter,
            strategyATokenContractBefore,
            "strategyATokenContractAfter < strategyATokenContractBefore"
        );
    }

    function testShouldWithdrawAllStanleyBalanceFromAAVEWithdrawAllMethod() public {
        // given
        uint256 withdrawAmount = 10 * 1e18;
        DaiAmm amm = new DaiAmm(_admin);
        amm.overrideCompoundStrategyWithZeroApr(_admin); // force Compound to have 0% APR to deposit to AAVE

        vm.startPrank(address(amm.milton()));
        deal(amm.dai(), address(amm.milton()), withdrawAmount);
        amm.stanley().deposit(withdrawAmount);

        uint256 miltonIvTokenBefore = IvToken(amm.stanley().getIvToken()).balanceOf(address(amm.milton()));
        uint256 strategyAaveBalanceBefore = amm.strategyAave().balanceOf();
        uint256 miltonDaiBalanceBefore = IERC20(amm.dai()).balanceOf(address(amm.milton()));
        uint256 strategyATokenContractBefore = IERC20(amm.aDai()).balanceOf(address(amm.strategyAave()));

        // when
        amm.stanley().withdrawAll();

        // then
        uint256 miltonIvTokenAfter = IvToken(amm.stanley().getIvToken()).balanceOf(address(amm.milton()));
        uint256 strategyAaveBalanceAfter = amm.strategyAave().balanceOf();
        uint256 miltonDaiBalanceAfter = IERC20(amm.dai()).balanceOf(address(amm.milton()));
        uint256 strategyATokenContractAfter = IERC20(amm.aDai()).balanceOf(address(amm.strategyAave()));

        assertLt(miltonIvTokenAfter, miltonIvTokenBefore, "miltonIvTokenAfter < miltonIvTokenBefore");
        assertLt(
            strategyAaveBalanceAfter,
            strategyAaveBalanceBefore,
            "strategyAaveBalanceAfter < strategyAaveBalanceBefore"
        );
        // Important check!
        assertEq(strategyAaveBalanceAfter, 0, "strategyAaveBalanceAfter = 0");
        assertGt(miltonDaiBalanceAfter, miltonDaiBalanceBefore, "miltonDaiBalanceAfter > miltonDaiBalanceBefore");
        assertLt(
            strategyATokenContractAfter,
            strategyATokenContractBefore,
            "strategyATokenContractAfter < strategyATokenContractBefore"
        );
    }

    function testShouldSetNewAAVEStrategyForDAI() public {
        // given
        uint256 depositAmount = 10 * 1e18;
        DaiAmm amm = new DaiAmm(_admin);
        amm.overrideCompoundStrategyWithZeroApr(_admin); // force Compound to have 0% APR to deposit to AAVE

        vm.startPrank(address(amm.milton()));
        deal(amm.dai(), address(amm.milton()), depositAmount);
        amm.stanley().deposit(depositAmount);
        vm.stopPrank();

        uint256 strategyAaveBalanceBefore = amm.strategyAave().balanceOf();
        uint256 strategyAaveV2BalanceBefore = amm.strategyAaveV2().balanceOf();
        uint256 miltonAssetBalanceBefore = IERC20(amm.dai()).balanceOf(address(amm.milton()));

        // when
        vm.startPrank(_admin);
        amm.stanley().setStrategyAave(address(amm.strategyAaveV2()));

        // then
        uint256 strategyAaveBalanceAfter = amm.strategyAave().balanceOf();
        uint256 strategyAaveV2BalanceAfter = amm.strategyAaveV2().balanceOf();
        uint256 miltonAssetBalanceAfter = IERC20(amm.dai()).balanceOf(address(amm.milton()));

        assertEq(strategyAaveV2BalanceBefore, 0, "strategyAaveV2BalanceBefore == 0");
        assertEq(strategyAaveBalanceAfter, 0, "strategyAaveBalanceAfter == 0");
        // Great Than Equal because with accrued interest
        assertGe(
            strategyAaveV2BalanceAfter,
            strategyAaveBalanceBefore,
            "strategyAaveV2BalanceAfter >= strategyAaveBalanceBefore"
        );
        assertLt(
            strategyAaveV2BalanceAfter,
            strategyAaveBalanceBefore + 1e18,
            "strategyAaveV2BalanceAfter < strategyAaveBalanceBefore + 1e18"
        );
        assertEq(
            miltonAssetBalanceBefore,
            miltonAssetBalanceAfter,
            "miltonAssetBalanceBefore == miltonAssetBalanceAfter"
        );
    }

    function testShouldMigrateAssetToStrategyWithMaxAPR() public {
        // given
        uint256 depositAmount = 10 * 1e18;
        DaiAmm amm = new DaiAmm(_admin);
        amm.overrideCompoundStrategyWithZeroApr(_admin); // force Compound to have 0% APR to deposit to AAVE
        IStrategy(amm.stanley().getStrategyCompound()).deposit(depositAmount); // deposit to Compound
        // after withdrawing Stanley should have enough DAI to deposit to AAVE - Compound mock under the hood is dumb
        deal(amm.dai(), address(amm.stanley()), depositAmount);

        uint256 miltonIvTokenBefore = IvToken(amm.stanley().getIvToken()).balanceOf(address(amm.milton()));
        uint256 strategyAaveBalanceBefore = amm.strategyAave().balanceOf();
        uint256 strategyCompoundBalanceBefore = IStrategy(amm.stanley().getStrategyCompound()).balanceOf();
        uint256 miltonAssetBalanceBefore = IERC20(amm.dai()).balanceOf(address(amm.milton()));
        uint256 miltonTotalBalanceBefore = amm.stanley().totalBalance(address(amm.milton()));

        //when
        vm.startPrank(_admin);
        amm.stanley().migrateAssetToStrategyWithMaxApr();

        //then
        uint256 miltonIvTokenAfter = IvToken(amm.stanley().getIvToken()).balanceOf(address(amm.milton()));
        uint256 strategyAaveBalanceAfter = amm.strategyAave().balanceOf();
        uint256 strategyCompoundBalanceAfter = IStrategy(amm.stanley().getStrategyCompound()).balanceOf();
        uint256 miltonAssetBalanceAfter = IERC20(amm.dai()).balanceOf(address(amm.milton()));
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
        assertLe(strategyCompoundBalanceAfter, 5e17, "strategyCompoundBalanceAfter <= 0.5");
        assertEq(
            miltonAssetBalanceAfter,
            miltonAssetBalanceBefore,
            "miltonAssetBalanceAfter == miltonAssetBalanceBefore"
        );
        assertLe(
            miltonTotalBalanceBefore,
            miltonTotalBalanceAfter,
            "miltonTotalBalanceAfter <= miltonTotalBalanceBefore"
        );
        assertLe(
            miltonTotalBalanceAfter,
            miltonTotalBalanceBefore + 1e18,
            "miltonTotalBalanceAfter <= miltonTotalBalanceBefore + 1e18"
        );
    }
}

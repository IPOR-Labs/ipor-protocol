// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.16;

import "forge-std/Test.sol";
import "../../../contracts/vault/StanleyUsdt.sol";
import "../../../contracts/tokens/IvToken.sol";
import "../UsdtAmm.sol";

contract StanleyAaveUsdtTest is Test {
    address internal _admin;
    address internal _user;

    function setUp() public {
        _admin = vm.rememberKey(1);
        _user = vm.rememberKey(2);
    }

    function testShouldAcceptDepositAndTransferTokensIntoAAVE() public {
        // given
        uint256 depositAmount = 10 * 1e6;
        UsdtAmm amm = new UsdtAmm(_admin);
        deal(amm.usdt(), address(amm.milton()), depositAmount);
        amm.overrideCompoundStrategyWithZeroApr(_admin); // force Compound to have 0% APR to deposit to AAVE

        uint256 miltonIvTokenBefore = IvToken(amm.stanley().getIvToken()).balanceOf(address(amm.milton()));
        uint256 strategyAaveBalanceBefore = amm.strategyAave().balanceOf();
        uint256 miltonUsdtBalanceBefore = IERC20(amm.usdt()).balanceOf(address(amm.milton()));
        uint256 strategyATokenContractBefore = IERC20(amm.aUsdt()).balanceOf(address(amm.strategyAave()));

        // when
        vm.startPrank(address(amm.milton()));
        amm.stanley().deposit(depositAmount * 1e12);

        // then
        uint256 miltonIvTokenAfter = IvToken(amm.stanley().getIvToken()).balanceOf(address(amm.milton()));
        uint256 strategyAaveBalanceAfter = amm.strategyAave().balanceOf();
        uint256 miltonUsdtBalanceAfter = IERC20(amm.usdt()).balanceOf(address(amm.milton()));
        uint256 strategyATokenContractAfter = IERC20(amm.aUsdt()).balanceOf(address(amm.strategyAave()));

        assertEq(miltonIvTokenBefore, 0, "miltonIvTokenBefore == 0");
        assertEq(strategyAaveBalanceBefore, 0, "strategyAaveBalanceBefore == 0");
        assertGe(miltonIvTokenAfter, miltonIvTokenBefore, "miltonIvTokenAfter >= miltonIvTokenAfter");
        assertGe(
            strategyAaveBalanceAfter,
            strategyAaveBalanceBefore,
            "strategyAaveBalanceAfter >= strategyAaveBalanceAfter"
        );
        assertLe(miltonUsdtBalanceAfter, miltonUsdtBalanceBefore, "miltonUsdtBalanceAfter <= miltonUsdtBalanceAfter");
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
        amm.overrideCompoundStrategyWithZeroApr(_admin); // force Compound to have 0% APR to deposit to AAVE

        uint256 miltonIvTokenBefore = IvToken(amm.stanley().getIvToken()).balanceOf(address(amm.milton()));
        uint256 strategyAaveBalanceBefore = amm.strategyAave().balanceOf();
        uint256 miltonUsdtBalanceBefore = IERC20(amm.usdt()).balanceOf(address(amm.milton()));
        uint256 strategyATokenContractBefore = IERC20(amm.aUsdt()).balanceOf(address(amm.strategyAave()));

        // when
        vm.startPrank(address(amm.milton()));
        amm.stanley().deposit(depositAmount * 1e12);
        amm.stanley().deposit(depositAmount * 1e12);

        // then
        uint256 miltonIvTokenAfter = IvToken(amm.stanley().getIvToken()).balanceOf(address(amm.milton()));
        uint256 strategyATokenContractAfter = IERC20(amm.aUsdt()).balanceOf(address(amm.strategyAave()));
        uint256 miltonUsdtBalanceAfter = IERC20(amm.usdt()).balanceOf(address(amm.milton()));
        uint256 strategyAaveBalanceAfter = amm.strategyAave().balanceOf();

        assertGe(miltonIvTokenAfter, miltonIvTokenBefore, "miltonIvTokenAfter >= miltonIvTokenBefore");
        assertGt(
            strategyAaveBalanceAfter,
            strategyAaveBalanceBefore,
            "strategyAaveBalanceAfter > strategyAaveBalanceBefore"
        );
        assertLt(miltonUsdtBalanceAfter, miltonUsdtBalanceBefore, "miltonUsdtBalanceAfter < miltonUsdtBalanceBefore");
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
        amm.overrideCompoundStrategyWithZeroApr(_admin); // force Compound to have 0% APR to deposit to AAVE

        vm.startPrank(address(amm.milton()));
        deal(amm.usdt(), address(amm.milton()), withdrawAmount);
        amm.stanley().deposit(withdrawAmount * 1e12);

        uint256 miltonIvTokenBefore = IvToken(amm.stanley().getIvToken()).balanceOf(address(amm.milton()));
        uint256 strategyAaveBalanceBefore = amm.strategyAave().balanceOf();
        uint256 miltonUsdtBalanceBefore = IERC20(amm.usdt()).balanceOf(address(amm.milton()));
        uint256 strategyATokenContractBefore = IERC20(amm.aUsdt()).balanceOf(address(amm.strategyAave()));

        // when
        amm.stanley().withdraw(withdrawAmount * 1e12);

        // then
        uint256 strategyAaveBalanceAfter = amm.strategyAave().balanceOf();
        uint256 miltonIvTokenAfter = IvToken(amm.stanley().getIvToken()).balanceOf(address(amm.milton()));
        uint256 miltonUsdtBalanceAfter = IERC20(amm.usdt()).balanceOf(address(amm.milton()));
        uint256 strategyATokenContractAfter = IERC20(amm.aUsdt()).balanceOf(address(amm.strategyAave()));

        assertLt(miltonIvTokenAfter, miltonIvTokenBefore, "miltonIvTokenAfter < miltonIvTokenBefore");
        assertLt(
            strategyAaveBalanceAfter,
            strategyAaveBalanceBefore,
            "strategyAaveBalanceAfter < strategyAaveBalanceBefore"
        );
        assertGt(miltonUsdtBalanceAfter, miltonUsdtBalanceBefore, "miltonUsdtBalanceAfter > miltonUsdtBalanceBefore");
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
        amm.overrideCompoundStrategyWithZeroApr(_admin); // force Compound to have 0% APR to deposit to AAVE

        vm.startPrank(address(amm.milton()));
        deal(amm.usdt(), address(amm.milton()), withdrawAmount);
        amm.stanley().deposit(withdrawAmount * 1e12);

        uint256 miltonIvTokenBefore = IvToken(amm.stanley().getIvToken()).balanceOf(address(amm.milton()));
        uint256 strategyAaveBalanceBefore = amm.strategyAave().balanceOf();
        uint256 miltonUsdtBalanceBefore = IERC20(amm.usdt()).balanceOf(address(amm.milton()));
        uint256 strategyATokenContractBefore = IERC20(amm.aUsdt()).balanceOf(address(amm.strategyAave()));

        // when
        amm.stanley().withdraw(strategyAaveBalanceBefore);

        // then
        uint256 miltonIvTokenAfter = IvToken(amm.stanley().getIvToken()).balanceOf(address(amm.milton()));
        uint256 strategyAaveBalanceAfter = amm.strategyAave().balanceOf();
        uint256 miltonUsdtBalanceAfter = IERC20(amm.usdt()).balanceOf(address(amm.milton()));
        uint256 strategyATokenContractAfter = IERC20(amm.aUsdt()).balanceOf(address(amm.strategyAave()));

        assertLt(miltonIvTokenAfter, miltonIvTokenBefore, "miltonIvTokenAfter < miltonIvTokenBefore");
        assertLt(
            strategyAaveBalanceAfter,
            strategyAaveBalanceBefore,
            "strategyAaveBalanceAfter < strategyAaveBalanceBefore"
        );

        // Important check!
        assertLt(strategyAaveBalanceAfter, 5e17, "strategyAaveBalanceAfter < 0.5");
        assertGt(miltonUsdtBalanceAfter, miltonUsdtBalanceBefore, "miltonUsdtBalanceAfter > miltonUsdtBalanceBefore");
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
        amm.overrideCompoundStrategyWithZeroApr(_admin); // force Compound to have 0% APR to deposit to AAVE

        vm.startPrank(address(amm.milton()));
        deal(amm.usdt(), address(amm.milton()), withdrawAmount);
        amm.stanley().deposit(withdrawAmount * 1e12);

        uint256 miltonIvTokenBefore = IvToken(amm.stanley().getIvToken()).balanceOf(address(amm.milton()));
        uint256 strategyAaveBalanceBefore = amm.strategyAave().balanceOf();
        uint256 miltonUsdtBalanceBefore = IERC20(amm.usdt()).balanceOf(address(amm.milton()));
        uint256 strategyATokenContractBefore = IERC20(amm.aUsdt()).balanceOf(address(amm.strategyAave()));

        // when
        amm.stanley().withdrawAll();

        // then
        uint256 miltonIvTokenAfter = IvToken(amm.stanley().getIvToken()).balanceOf(address(amm.milton()));
        uint256 strategyAaveBalanceAfter = amm.strategyAave().balanceOf();
        uint256 miltonUsdtBalanceAfter = IERC20(amm.usdt()).balanceOf(address(amm.milton()));
        uint256 strategyATokenContractAfter = IERC20(amm.aUsdt()).balanceOf(address(amm.strategyAave()));

        assertLt(miltonIvTokenAfter, miltonIvTokenBefore, "miltonIvTokenAfter < miltonIvTokenBefore");
        assertLt(
            strategyAaveBalanceAfter,
            strategyAaveBalanceBefore,
            "strategyAaveBalanceAfter < strategyAaveBalanceBefore"
        );
        // Important check!
        assertLt(strategyAaveBalanceAfter, 1e17, "strategyAaveBalanceAfter < 1e17");
        assertGt(miltonUsdtBalanceAfter, miltonUsdtBalanceBefore, "miltonUsdtBalanceAfter > miltonUsdtBalanceBefore");
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
        uint256 claimable = amm.aaveIncentivesController().getUserUnclaimedRewards(address(amm.strategyAave()));
        assertEq(claimable, 0);
    }

    function testShouldSetNewAAVEStrategyForUsdt() public {
        // given
        uint256 depositAmount = 1000 * 1e6;
        UsdtAmm amm = new UsdtAmm(_admin);
        amm.overrideCompoundStrategyWithZeroApr(_admin); // force Compound to have 0% APR to deposit to AAVE

        vm.startPrank(address(amm.milton()));
        deal(amm.usdt(), address(amm.milton()), depositAmount);
        amm.stanley().deposit(depositAmount * 1e12);
        vm.stopPrank();

        uint256 strategyAaveBalanceBefore = amm.strategyAave().balanceOf();
        uint256 strategyAaveV2BalanceBefore = amm.strategyAaveV2().balanceOf();
        uint256 miltonAssetBalanceBefore = IERC20(amm.usdt()).balanceOf(address(amm.milton()));

        // when
        vm.startPrank(_admin);
        amm.stanley().setStrategyAave(address(amm.strategyAaveV2()));

        // then
        uint256 strategyAaveBalanceAfter = amm.strategyAave().balanceOf();
        uint256 strategyAaveV2BalanceAfter = amm.strategyAaveV2().balanceOf();
        uint256 miltonAssetBalanceAfter = IERC20(amm.usdt()).balanceOf(address(amm.milton()));

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
            strategyAaveBalanceBefore + 1e6,
            "strategyAaveV2BalanceAfter < strategyAaveBalanceBefore + 1e6"
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
        uint256 strategyAaveBalanceBefore = amm.strategyAave().balanceOf();
        uint256 strategyCompoundBalanceBefore = IStrategy(amm.stanley().getStrategyCompound()).balanceOf();
        uint256 miltonAssetBalanceBefore = IERC20(amm.usdt()).balanceOf(address(amm.milton()));
        uint256 miltonTotalBalanceBefore = amm.stanley().totalBalance(address(amm.milton()));

        //when
        vm.startPrank(_admin);
        amm.stanley().migrateAssetToStrategyWithMaxApr();

        //then
        uint256 miltonIvTokenAfter = IvToken(amm.stanley().getIvToken()).balanceOf(address(amm.milton()));
        uint256 strategyAaveBalanceAfter = amm.strategyAave().balanceOf();
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
        assertLe(strategyCompoundBalanceAfter, 1e6, "strategyCompoundBalanceAfter <= 1");
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
            miltonTotalBalanceBefore + 1e6,
            "miltonTotalBalanceAfter <= miltonTotalBalanceBefore + 1e6"
        );
    }
}

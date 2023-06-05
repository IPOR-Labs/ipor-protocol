// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.20;

import "forge-std/Test.sol";
import "contracts/vault/AssetManagementUsdt.sol";
import "contracts/tokens/IvToken.sol";
import "../UsdtAmm.sol";

contract AssetManagementAaveUsdtTest is Test {
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
        assertEq(IStrategy(amm.assetManagement().getStrategyAave()).getApr(), 0, "strategyCompoundApr == 0");
    }

    function testShouldAaveAprGreaterThanCompoundApr() public {
        // given
        UsdtAmm amm = new UsdtAmm(_admin);
        amm.overrideCompoundStrategyWithZeroApr(_admin);

        // when
        uint256 compoundApr = IStrategy(amm.assetManagement().getStrategyCompound()).getApr();
        uint256 aaveApr = IStrategy(amm.assetManagement().getStrategyAave()).getApr();

        // then
        assertGt(aaveApr, compoundApr, "aaveApr > compoundApr");
    }

    function testShouldAcceptDepositAndTransferTokensIntoAAVE() public {
        // given
        uint256 depositAmount = 10 * 1e6;
        UsdtAmm amm = new UsdtAmm(_admin);
        deal(amm.usdt(), address(amm.ammTreasury()), depositAmount);
        amm.overrideCompoundStrategyWithZeroApr(_admin);

        uint256 ammTreasuryIvTokenBefore = IvToken(amm.assetManagement().getIvToken()).balanceOf(address(amm.ammTreasury()));
        uint256 strategyBalanceBefore = IStrategy(amm.assetManagement().getStrategyAave()).balanceOf();
        uint256 ammTreasuryBalanceBefore = IERC20(amm.usdt()).balanceOf(address(amm.ammTreasury()));
        uint256 strategyATokenContractBefore = IERC20(amm.aUsdt()).balanceOf(amm.assetManagement().getStrategyAave());

        // when
        vm.startPrank(address(amm.ammTreasury()));
        amm.assetManagement().deposit(depositAmount * 1e12);

        // then
        uint256 ammTreasuryIvTokenAfter = IvToken(amm.assetManagement().getIvToken()).balanceOf(address(amm.ammTreasury()));
        uint256 strategyBalanceAfter = IStrategy(amm.assetManagement().getStrategyAave()).balanceOf();
        uint256 ammTreasuryBalanceAfter = IERC20(amm.usdt()).balanceOf(address(amm.ammTreasury()));
        uint256 strategyATokenContractAfter = IERC20(amm.aUsdt()).balanceOf(amm.assetManagement().getStrategyAave());

        assertEq(ammTreasuryIvTokenBefore, 0, "ammTreasuryIvTokenBefore == 0");
        assertEq(strategyBalanceBefore, 0, "strategyBalanceBefore == 0");
        assertGe(ammTreasuryIvTokenAfter, ammTreasuryIvTokenBefore, "ammTreasuryIvTokenAfter >= ammTreasuryIvTokenAfter");
        assertGe(
            strategyBalanceAfter,
            strategyBalanceBefore,
            "strategyBalanceAfter >= strategyBalanceAfter"
        );
        assertLe(ammTreasuryBalanceAfter, ammTreasuryBalanceBefore, "ammTreasuryBalanceAfter <= ammTreasuryBalanceAfter");
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
        deal(amm.usdt(), address(amm.ammTreasury()), 2 * depositAmount);
        amm.overrideCompoundStrategyWithZeroApr(_admin);

        uint256 ammTreasuryIvTokenBefore = IvToken(amm.assetManagement().getIvToken()).balanceOf(address(amm.ammTreasury()));
        uint256 strategyBalanceBefore = IStrategy(amm.assetManagement().getStrategyAave()).balanceOf();
        uint256 ammTreasuryBalanceBefore = IERC20(amm.usdt()).balanceOf(address(amm.ammTreasury()));
        uint256 strategyATokenContractBefore = IERC20(amm.aUsdt()).balanceOf(amm.assetManagement().getStrategyAave());

        // when
        vm.startPrank(address(amm.ammTreasury()));
        amm.assetManagement().deposit(depositAmount * 1e12);
        amm.assetManagement().deposit(depositAmount * 1e12);

        // then
        uint256 ammTreasuryIvTokenAfter = IvToken(amm.assetManagement().getIvToken()).balanceOf(address(amm.ammTreasury()));
        uint256 strategyATokenContractAfter = IERC20(amm.aUsdt()).balanceOf(amm.assetManagement().getStrategyAave());
        uint256 ammTreasuryBalanceAfter = IERC20(amm.usdt()).balanceOf(address(amm.ammTreasury()));
        uint256 strategyBalanceAfter = IStrategy(amm.assetManagement().getStrategyAave()).balanceOf();

        assertGe(ammTreasuryIvTokenAfter, ammTreasuryIvTokenBefore, "ammTreasuryIvTokenAfter >= ammTreasuryIvTokenBefore");
        assertGt(
            strategyBalanceAfter,
            strategyBalanceBefore,
            "strategyBalanceAfter > strategyBalanceBefore"
        );
        assertLt(ammTreasuryBalanceAfter, ammTreasuryBalanceBefore, "ammTreasuryBalanceAfter < ammTreasuryBalanceBefore");
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

        vm.startPrank(address(amm.ammTreasury()));
        deal(amm.usdt(), address(amm.ammTreasury()), withdrawAmount);
        amm.assetManagement().deposit(withdrawAmount * 1e12);

        uint256 ammTreasuryIvTokenBefore = IvToken(amm.assetManagement().getIvToken()).balanceOf(address(amm.ammTreasury()));
        uint256 strategyBalanceBefore = IStrategy(amm.assetManagement().getStrategyAave()).balanceOf();
        uint256 ammTreasuryBalanceBefore = IERC20(amm.usdt()).balanceOf(address(amm.ammTreasury()));
        uint256 strategyATokenContractBefore = IERC20(amm.aUsdt()).balanceOf(amm.assetManagement().getStrategyAave());

        // when
        amm.assetManagement().withdraw(withdrawAmount * 1e12);

        // then
        uint256 strategyBalanceAfter = IStrategy(amm.assetManagement().getStrategyAave()).balanceOf();
        uint256 ammTreasuryIvTokenAfter = IvToken(amm.assetManagement().getIvToken()).balanceOf(address(amm.ammTreasury()));
        uint256 ammTreasuryBalanceAfter = IERC20(amm.usdt()).balanceOf(address(amm.ammTreasury()));
        uint256 strategyATokenContractAfter = IERC20(amm.aUsdt()).balanceOf(amm.assetManagement().getStrategyAave());

        assertLt(ammTreasuryIvTokenAfter, ammTreasuryIvTokenBefore, "ammTreasuryIvTokenAfter < ammTreasuryIvTokenBefore");
        assertLt(
            strategyBalanceAfter,
            strategyBalanceBefore,
            "strategyBalanceAfter < strategyBalanceBefore"
        );
        assertGt(ammTreasuryBalanceAfter, ammTreasuryBalanceBefore, "ammTreasuryBalanceAfter > ammTreasuryBalanceBefore");
        assertLt(
            strategyATokenContractAfter,
            strategyATokenContractBefore,
            "strategyATokenContractAfter < strategyATokenContractBefore"
        );
    }

    function testShouldWithdrawAllAssetManagementBalanceFromAAVEWithdrawMethod() public {
        // given
        uint256 withdrawAmount = 10 * 1e6;
        UsdtAmm amm = new UsdtAmm(_admin);
        amm.overrideCompoundStrategyWithZeroApr(_admin);

        vm.startPrank(address(amm.ammTreasury()));
        deal(amm.usdt(), address(amm.ammTreasury()), withdrawAmount);
        amm.assetManagement().deposit(withdrawAmount * 1e12);

        uint256 ammTreasuryIvTokenBefore = IvToken(amm.assetManagement().getIvToken()).balanceOf(address(amm.ammTreasury()));
        uint256 strategyBalanceBefore = IStrategy(amm.assetManagement().getStrategyAave()).balanceOf();
        uint256 ammTreasuryBalanceBefore = IERC20(amm.usdt()).balanceOf(address(amm.ammTreasury()));
        uint256 strategyATokenContractBefore = IERC20(amm.aUsdt()).balanceOf(amm.assetManagement().getStrategyAave());

        // when
        amm.assetManagement().withdraw(strategyBalanceBefore);

        // then
        uint256 ammTreasuryIvTokenAfter = IvToken(amm.assetManagement().getIvToken()).balanceOf(address(amm.ammTreasury()));
        uint256 strategyBalanceAfter = IStrategy(amm.assetManagement().getStrategyAave()).balanceOf();
        uint256 ammTreasuryBalanceAfter = IERC20(amm.usdt()).balanceOf(address(amm.ammTreasury()));
        uint256 strategyATokenContractAfter = IERC20(amm.aUsdt()).balanceOf(amm.assetManagement().getStrategyAave());

        assertLt(ammTreasuryIvTokenAfter, ammTreasuryIvTokenBefore, "ammTreasuryIvTokenAfter < ammTreasuryIvTokenBefore");
        assertLt(
            strategyBalanceAfter,
            strategyBalanceBefore,
            "strategyBalanceAfter < strategyBalanceBefore"
        );

        // Important check!
        assertLt(strategyBalanceAfter, 5e17, "strategyBalanceAfter < 0.5");
        assertGt(ammTreasuryBalanceAfter, ammTreasuryBalanceBefore, "ammTreasuryBalanceAfter > ammTreasuryBalanceBefore");
        assertLt(
            strategyATokenContractAfter,
            strategyATokenContractBefore,
            "strategyATokenContractAfter < strategyATokenContractBefore"
        );
    }

    function testShouldWithdrawAllAssetManagementBalanceFromAAVEWithdrawAllMethod() public {
        // given
        uint256 withdrawAmount = 10 * 1e6;
        UsdtAmm amm = new UsdtAmm(_admin);
        amm.overrideCompoundStrategyWithZeroApr(_admin);

        vm.startPrank(address(amm.ammTreasury()));
        deal(amm.usdt(), address(amm.ammTreasury()), withdrawAmount);
        amm.assetManagement().deposit(withdrawAmount * 1e12);

        uint256 ammTreasuryIvTokenBefore = IvToken(amm.assetManagement().getIvToken()).balanceOf(address(amm.ammTreasury()));
        uint256 strategyBalanceBefore = IStrategy(amm.assetManagement().getStrategyAave()).balanceOf();
        uint256 ammTreasuryBalanceBefore = IERC20(amm.usdt()).balanceOf(address(amm.ammTreasury()));
        uint256 strategyATokenContractBefore = IERC20(amm.aUsdt()).balanceOf(amm.assetManagement().getStrategyAave());

        // when
        amm.assetManagement().withdrawAll();

        // then
        uint256 ammTreasuryIvTokenAfter = IvToken(amm.assetManagement().getIvToken()).balanceOf(address(amm.ammTreasury()));
        uint256 strategyBalanceAfter = IStrategy(amm.assetManagement().getStrategyAave()).balanceOf();
        uint256 ammTreasuryBalanceAfter = IERC20(amm.usdt()).balanceOf(address(amm.ammTreasury()));
        uint256 strategyATokenContractAfter = IERC20(amm.aUsdt()).balanceOf(amm.assetManagement().getStrategyAave());

        assertLt(ammTreasuryIvTokenAfter, ammTreasuryIvTokenBefore, "ammTreasuryIvTokenAfter < ammTreasuryIvTokenBefore");
        assertLt(
            strategyBalanceAfter,
            strategyBalanceBefore,
            "strategyBalanceAfter < strategyBalanceBefore"
        );
        // Important check!
        assertLt(strategyBalanceAfter, 1e17, "strategyBalanceAfter < 1e17");
        assertGt(ammTreasuryBalanceAfter, ammTreasuryBalanceBefore, "ammTreasuryBalanceAfter > ammTreasuryBalanceBefore");
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
        deal(amm.usdt(), address(amm.ammTreasury()), 2 * amount);
        vm.startPrank(address(amm.ammTreasury()));

        // when
        amm.assetManagement().deposit(amount * 1e12);
        vm.warp(block.timestamp + ONE_WEEK_IN_SECONDS);
        amm.assetManagement().deposit(amount * 1e12);

        // then
        uint256 claimable = amm.aaveIncentivesController().getUserUnclaimedRewards(amm.assetManagement().getStrategyAave());
        assertEq(claimable, 0);
    }

    function testShouldSetNewAAVEStrategy() public {
        // given
        uint256 depositAmount = 1000 * 1e6;
        UsdtAmm amm = new UsdtAmm(_admin);
        amm.overrideCompoundStrategyWithZeroApr(_admin);

        vm.startPrank(address(amm.ammTreasury()));
        deal(amm.usdt(), address(amm.ammTreasury()), depositAmount);
        amm.assetManagement().deposit(depositAmount * 1e12);
        vm.stopPrank();

        address strategyV1 = amm.assetManagement().getStrategyAave();

        uint256 strategyBalanceBefore = IStrategy(strategyV1).balanceOf();
        uint256 strategyAaveV2BalanceBefore = amm.strategyAaveV2().balanceOf();
        uint256 ammTreasuryAssetBalanceBefore = IERC20(amm.usdt()).balanceOf(address(amm.ammTreasury()));

        // when
        vm.startPrank(_admin);
        amm.assetManagement().setStrategyAave(address(amm.strategyAaveV2()));

        // then
        uint256 strategyBalanceAfter = IStrategy(strategyV1).balanceOf();
        uint256 strategyAaveV2BalanceAfter = amm.strategyAaveV2().balanceOf();
        uint256 ammTreasuryAssetBalanceAfter = IERC20(amm.usdt()).balanceOf(address(amm.ammTreasury()));

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
            ammTreasuryAssetBalanceBefore,
            ammTreasuryAssetBalanceAfter,
            "ammTreasuryAssetBalanceBefore == ammTreasuryAssetBalanceAfter"
        );
    }

    function testShouldMigrateAssetToStrategyWithMaxAPR() public {
        // given
        uint256 depositAmount = 1000 * 1e6;
        UsdtAmm amm = new UsdtAmm(_admin);
        amm.overrideAaveStrategyWithZeroApr(_admin);
        deal(amm.usdt(), address(amm.ammTreasury()), depositAmount);
        vm.startPrank(address(amm.ammTreasury()));
        amm.assetManagement().deposit(depositAmount * 1e12);
        vm.stopPrank();
        amm.restoreStrategies(_admin);
        amm.overrideCompoundStrategyWithZeroApr(_admin);

        uint256 ammTreasuryIvTokenBefore = IvToken(amm.assetManagement().getIvToken()).balanceOf(address(amm.ammTreasury()));
        uint256 strategyAaveBalanceBefore = IStrategy(amm.assetManagement().getStrategyAave()).balanceOf();
        uint256 strategyCompoundBalanceBefore = IStrategy(amm.assetManagement().getStrategyCompound()).balanceOf();
        uint256 ammTreasuryAssetBalanceBefore = IERC20(amm.usdt()).balanceOf(address(amm.ammTreasury()));
        uint256 ammTreasuryTotalBalanceBefore = amm.assetManagement().totalBalance(address(amm.ammTreasury()));

        //when
        vm.startPrank(_admin);
        amm.assetManagement().migrateAssetToStrategyWithMaxApr();

        //then
        uint256 ammTreasuryIvTokenAfter = IvToken(amm.assetManagement().getIvToken()).balanceOf(address(amm.ammTreasury()));
        uint256 strategyAaveBalanceAfter = IStrategy(amm.assetManagement().getStrategyAave()).balanceOf();
        uint256 strategyCompoundBalanceAfter = IStrategy(amm.assetManagement().getStrategyCompound()).balanceOf();
        uint256 ammTreasuryAssetBalanceAfter = IERC20(amm.usdt()).balanceOf(address(amm.ammTreasury()));
        uint256 ammTreasuryTotalBalanceAfter = amm.assetManagement().totalBalance(address(amm.ammTreasury()));

        assertEq(ammTreasuryIvTokenAfter, ammTreasuryIvTokenBefore, "ammTreasuryIvTokenAfter == ammTreasuryIvTokenBefore");
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
            ammTreasuryAssetBalanceAfter,
            ammTreasuryAssetBalanceBefore,
            "ammTreasuryAssetBalanceAfter == ammTreasuryAssetBalanceBefore"
        );
        assertLe(
            ammTreasuryTotalBalanceBefore,
            ammTreasuryTotalBalanceAfter + 1e12,
            "ammTreasuryTotalBalanceBefore <= ammTreasuryTotalBalanceAfter + 1e12"
        );
        assertLe(
            ammTreasuryTotalBalanceAfter,
            ammTreasuryTotalBalanceBefore + 1e12,
            "ammTreasuryTotalBalanceAfter <= ammTreasuryTotalBalanceBefore + 1e12"
        );
    }
}

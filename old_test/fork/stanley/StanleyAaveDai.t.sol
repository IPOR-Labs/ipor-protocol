// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.20;

import "forge-std/Test.sol";
import "@ipor-protocol/contracts/vault/AssetManagementDai.sol";
import "@ipor-protocol/contracts/tokens/IvToken.sol";
import "../DaiAmm.sol";

contract AssetManagementAaveDaiTest is Test {
    address internal _admin;

    function setUp() public {
        _admin = vm.rememberKey(1);
    }

    function testShouldAaveApyBeZeroAfterOverride() public {
        // given
        DaiAmm amm = new DaiAmm(_admin);

        // when
        amm.overrideAaveStrategyWithZeroApy(_admin);

        // then
        assertEq(IStrategy(amm.assetManagement().getStrategyAave()).getApy(), 0, "strategyCompoundApy == 0");
    }

    function testShouldAaveApyGreaterThanCompoundApy() public {
        // given
        DaiAmm amm = new DaiAmm(_admin);
        amm.overrideCompoundStrategyWithZeroApy(_admin);

        // when
        uint256 compoundApy = IStrategy(amm.assetManagement().getStrategyCompound()).getApy();
        uint256 aaveApy = IStrategy(amm.assetManagement().getStrategyAave()).getApy();

        // then
        assertGt(aaveApy, compoundApy, "aaveApy > compoundApy");
    }

    function testShouldAcceptDepositAndTransferTokensIntoAAVE() public {
        // given
        uint256 depositAmount = 10 * 1e18;
        DaiAmm amm = new DaiAmm(_admin);
        deal(amm.dai(), address(amm.ammTreasury()), depositAmount);
        amm.overrideCompoundStrategyWithZeroApy(_admin);

        uint256 ammTreasuryIvTokenBefore = IvToken(amm.assetManagement().getIvToken()).balanceOf(address(amm.ammTreasury()));
        uint256 strategyBalanceBefore = IStrategy(amm.assetManagement().getStrategyAave()).balanceOf();
        uint256 ammTreasuryBalanceBefore = IERC20(amm.dai()).balanceOf(address(amm.ammTreasury()));
        uint256 strategyATokenContractBefore = IERC20(amm.aDai()).balanceOf(amm.assetManagement().getStrategyAave());

        // when
        vm.startPrank(address(amm.ammTreasury()));
        amm.assetManagement().deposit(depositAmount);

        // then
        uint256 ammTreasuryIvTokenAfter = IvToken(amm.assetManagement().getIvToken()).balanceOf(address(amm.ammTreasury()));
        uint256 strategyBalanceAfter = IStrategy(amm.assetManagement().getStrategyAave()).balanceOf();
        uint256 ammTreasuryBalanceAfter = IERC20(amm.dai()).balanceOf(address(amm.ammTreasury()));
        uint256 strategyATokenContractAfter = IERC20(amm.aDai()).balanceOf(amm.assetManagement().getStrategyAave());

        assertEq(ammTreasuryIvTokenBefore, 0, "ammTreasuryIvTokenBefore == 0");
        assertEq(strategyBalanceBefore, 0, "strategyBalanceBefore == 0");
        assertGe(ammTreasuryIvTokenAfter, 9999999999999999999, "ammTreasuryIvTokenAfter >= 9999999999999999999");
        assertGe(strategyBalanceAfter, 9999999999999999999, "strategyBalanceAfter >= 9999999999999999999");
        assertEq(
            ammTreasuryBalanceAfter,
            ammTreasuryBalanceBefore - depositAmount,
            "ammTreasuryBalanceAfter == ammTreasuryBalanceBefore - depositAmount"
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
        deal(amm.dai(), address(amm.ammTreasury()), 2 * depositAmount);
        amm.overrideCompoundStrategyWithZeroApy(_admin);

        uint256 ammTreasuryIvTokenBefore = IvToken(amm.assetManagement().getIvToken()).balanceOf(address(amm.ammTreasury()));
        uint256 strategyBalanceBefore = IStrategy(amm.assetManagement().getStrategyAave()).balanceOf();
        uint256 ammTreasuryBalanceBefore = IERC20(amm.dai()).balanceOf(address(amm.ammTreasury()));
        uint256 strategyATokenContractBefore = IERC20(amm.aDai()).balanceOf(amm.assetManagement().getStrategyAave());

        // when
        vm.startPrank(address(amm.ammTreasury()));
        amm.assetManagement().deposit(depositAmount);
        amm.assetManagement().deposit(depositAmount);

        // then
        uint256 ammTreasuryIvTokenAfter = IvToken(amm.assetManagement().getIvToken()).balanceOf(address(amm.ammTreasury()));
        uint256 strategyATokenContractAfter = IERC20(amm.aDai()).balanceOf(amm.assetManagement().getStrategyAave());
        uint256 ammTreasuryBalanceAfter = IERC20(amm.dai()).balanceOf(address(amm.ammTreasury()));
        uint256 strategyBalanceAfter = IStrategy(amm.assetManagement().getStrategyAave()).balanceOf();

        assertGe(ammTreasuryIvTokenAfter, ammTreasuryIvTokenBefore, "ammTreasuryIvTokenAfter >= ammTreasuryIvTokenBefore");
        assertGt(
            strategyBalanceAfter,
            strategyBalanceBefore,
            "strategyBalanceAfter > strategyBalanceBefore"
        );
        assertLt(ammTreasuryBalanceAfter, ammTreasuryBalanceBefore, "ammTreasuryBalanceAfter < ammTreasuryBalanceBefore");
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
        amm.overrideCompoundStrategyWithZeroApy(_admin);

        vm.startPrank(address(amm.ammTreasury()));
        deal(amm.dai(), address(amm.ammTreasury()), withdrawAmount);
        amm.assetManagement().deposit(withdrawAmount);

        uint256 ammTreasuryIvTokenBefore = IvToken(amm.assetManagement().getIvToken()).balanceOf(address(amm.ammTreasury()));
        uint256 strategyBalanceBefore = IStrategy(amm.assetManagement().getStrategyAave()).balanceOf();
        uint256 ammTreasuryBalanceBefore = IERC20(amm.dai()).balanceOf(address(amm.ammTreasury()));
        uint256 strategyATokenContractBefore = IERC20(amm.aDai()).balanceOf(amm.assetManagement().getStrategyAave());

        // when
        amm.assetManagement().withdraw(withdrawAmount);

        // then
        uint256 strategyBalanceAfter = IStrategy(amm.assetManagement().getStrategyAave()).balanceOf();
        uint256 ammTreasuryIvTokenAfter = IvToken(amm.assetManagement().getIvToken()).balanceOf(address(amm.ammTreasury()));
        uint256 ammTreasuryBalanceAfter = IERC20(amm.dai()).balanceOf(address(amm.ammTreasury()));
        uint256 strategyATokenContractAfter = IERC20(amm.aDai()).balanceOf(amm.assetManagement().getStrategyAave());

        assertLt(ammTreasuryIvTokenAfter, ammTreasuryIvTokenBefore, "ammTreasuryIvTokenAfter < ammTreasuryIvTokenBefore");
        assertLt(
            strategyBalanceAfter,
            strategyBalanceBefore,
            "strategyBalanceAfter < strategyBalanceBefore"
        );
        assertGe(ammTreasuryBalanceAfter, ammTreasuryBalanceBefore, "ammTreasuryBalanceAfter >= ammTreasuryBalanceBefore");
        assertLt(
            strategyATokenContractAfter,
            strategyATokenContractBefore,
            "strategyATokenContractAfter < strategyATokenContractBefore"
        );
    }

    function testShouldWithdrawAllAssetManagementBalanceFromAAVEWithdrawMethod() public {
        // given
        uint256 withdrawAmount = 10 * 1e18;
        DaiAmm amm = new DaiAmm(_admin);
        amm.overrideCompoundStrategyWithZeroApy(_admin);

        vm.startPrank(address(amm.ammTreasury()));
        deal(amm.dai(), address(amm.ammTreasury()), withdrawAmount);
        amm.assetManagement().deposit(withdrawAmount);

        uint256 ammTreasuryIvTokenBefore = IvToken(amm.assetManagement().getIvToken()).balanceOf(address(amm.ammTreasury()));
        uint256 strategyBalanceBefore = IStrategy(amm.assetManagement().getStrategyAave()).balanceOf();
        uint256 ammTreasuryBalanceBefore = IERC20(amm.dai()).balanceOf(address(amm.ammTreasury()));
        uint256 strategyATokenContractBefore = IERC20(amm.aDai()).balanceOf(amm.assetManagement().getStrategyAave());

        // when
        amm.assetManagement().withdraw(strategyBalanceBefore);

        // then
        uint256 ammTreasuryIvTokenAfter = IvToken(amm.assetManagement().getIvToken()).balanceOf(address(amm.ammTreasury()));
        uint256 strategyBalanceAfter = IStrategy(amm.assetManagement().getStrategyAave()).balanceOf();
        uint256 ammTreasuryBalanceAfter = IERC20(amm.dai()).balanceOf(address(amm.ammTreasury()));
        uint256 strategyATokenContractAfter = IERC20(amm.aDai()).balanceOf(amm.assetManagement().getStrategyAave());

        assertLt(ammTreasuryIvTokenAfter, ammTreasuryIvTokenBefore, "ammTreasuryIvTokenAfter < ammTreasuryIvTokenBefore");
        assertLt(
            strategyBalanceAfter,
            strategyBalanceBefore,
            "strategyBalanceAfter < strategyBalanceBefore"
        );

        // Important check!
        assertLt(strategyBalanceAfter, 1e12, "strategyBalanceAfter < 1e12");
        assertGt(ammTreasuryBalanceAfter, ammTreasuryBalanceBefore, "ammTreasuryBalanceAfter > ammTreasuryBalanceBefore");
        assertLt(
            strategyATokenContractAfter,
            strategyATokenContractBefore,
            "strategyATokenContractAfter < strategyATokenContractBefore"
        );
    }

    function testShouldWithdrawAllAssetManagementBalanceFromAAVEWithdrawAllMethod() public {
        // given
        uint256 withdrawAmount = 10 * 1e18;
        DaiAmm amm = new DaiAmm(_admin);
        amm.overrideCompoundStrategyWithZeroApy(_admin);

        vm.startPrank(address(amm.ammTreasury()));
        deal(amm.dai(), address(amm.ammTreasury()), withdrawAmount);
        amm.assetManagement().deposit(withdrawAmount);

        uint256 ammTreasuryIvTokenBefore = IvToken(amm.assetManagement().getIvToken()).balanceOf(address(amm.ammTreasury()));
        uint256 strategyBalanceBefore = IStrategy(amm.assetManagement().getStrategyAave()).balanceOf();
        uint256 ammTreasuryBalanceBefore = IERC20(amm.dai()).balanceOf(address(amm.ammTreasury()));
        uint256 strategyATokenContractBefore = IERC20(amm.aDai()).balanceOf(amm.assetManagement().getStrategyAave());

        // when
        amm.assetManagement().withdrawAll();

        // then
        uint256 ammTreasuryIvTokenAfter = IvToken(amm.assetManagement().getIvToken()).balanceOf(address(amm.ammTreasury()));
        uint256 strategyBalanceAfter = IStrategy(amm.assetManagement().getStrategyAave()).balanceOf();
        uint256 ammTreasuryBalanceAfter = IERC20(amm.dai()).balanceOf(address(amm.ammTreasury()));
        uint256 strategyATokenContractAfter = IERC20(amm.aDai()).balanceOf(amm.assetManagement().getStrategyAave());

        assertLt(ammTreasuryIvTokenAfter, ammTreasuryIvTokenBefore, "ammTreasuryIvTokenAfter < ammTreasuryIvTokenBefore");
        assertLt(
            strategyBalanceAfter,
            strategyBalanceBefore,
            "strategyBalanceAfter < strategyBalanceBefore"
        );
        // Important check!
        assertEq(strategyBalanceAfter, 0, "strategyBalanceAfter = 0");
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
        uint256 amount = 100_000 * 1e18;
        DaiAmm amm = new DaiAmm(_admin);
        amm.overrideCompoundStrategyWithZeroApy(_admin);
        deal(amm.dai(), address(amm.ammTreasury()), 2 * amount);
        vm.startPrank(address(amm.ammTreasury()));

        // when
        amm.assetManagement().deposit(amount);
        vm.warp(block.timestamp + ONE_WEEK_IN_SECONDS);
        amm.assetManagement().deposit(amount);

        // then
        uint256 claimable = amm.aaveIncentivesController().getUserUnclaimedRewards(amm.assetManagement().getStrategyAave());
        assertEq(claimable, 0);
    }

    function testShouldSetNewAAVEStrategy() public {
        // given
        uint256 depositAmount = 10 * 1e18;
        DaiAmm amm = new DaiAmm(_admin);
        amm.overrideCompoundStrategyWithZeroApy(_admin);

        vm.startPrank(address(amm.ammTreasury()));
        deal(amm.dai(), address(amm.ammTreasury()), depositAmount);
        amm.assetManagement().deposit(depositAmount);
        vm.stopPrank();

        address strategyV1 = amm.assetManagement().getStrategyAave();

        uint256 strategyBalanceBefore = IStrategy(strategyV1).balanceOf();
        uint256 strategyAaveV2BalanceBefore = amm.strategyAaveV2().balanceOf();
        uint256 ammTreasuryAssetBalanceBefore = IERC20(amm.dai()).balanceOf(address(amm.ammTreasury()));

        // when
        vm.startPrank(_admin);
        amm.assetManagement().setStrategyAave(address(amm.strategyAaveV2()));

        // then
        uint256 strategyBalanceAfter = IStrategy(strategyV1).balanceOf();
        uint256 strategyAaveV2BalanceAfter = amm.strategyAaveV2().balanceOf();
        uint256 ammTreasuryAssetBalanceAfter = IERC20(amm.dai()).balanceOf(address(amm.ammTreasury()));

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
            strategyBalanceBefore + 1e18,
            "strategyAaveV2BalanceAfter < strategyBalanceBefore + 1e18"
        );
        assertEq(
            ammTreasuryAssetBalanceBefore,
            ammTreasuryAssetBalanceAfter,
            "ammTreasuryAssetBalanceBefore == ammTreasuryAssetBalanceAfter"
        );
    }

    function testShouldMigrateAssetToStrategyWithMaxAPY() public {
        // given
        uint256 depositAmount = 10 * 1e18;
        DaiAmm amm = new DaiAmm(_admin);
        amm.overrideAaveStrategyWithZeroApy(_admin);
        deal(amm.dai(), address(amm.ammTreasury()), depositAmount);
        vm.startPrank(address(amm.ammTreasury()));
        amm.assetManagement().deposit(depositAmount);
        vm.stopPrank();
        amm.restoreStrategies(_admin);
        amm.overrideCompoundStrategyWithZeroApy(_admin);

        uint256 ammTreasuryIvTokenBefore = IvToken(amm.assetManagement().getIvToken()).balanceOf(address(amm.ammTreasury()));
        uint256 strategyAaveBalanceBefore = IStrategy(amm.assetManagement().getStrategyAave()).balanceOf();
        uint256 strategyCompoundBalanceBefore = IStrategy(amm.assetManagement().getStrategyCompound()).balanceOf();
        uint256 ammTreasuryAssetBalanceBefore = IERC20(amm.dai()).balanceOf(address(amm.ammTreasury()));
        uint256 ammTreasuryTotalBalanceBefore = amm.assetManagement().totalBalance(address(amm.ammTreasury()));

        //when
        vm.startPrank(_admin);
        amm.assetManagement().migrateAssetToStrategyWithMaxApy();

        //then
        uint256 ammTreasuryIvTokenAfter = IvToken(amm.assetManagement().getIvToken()).balanceOf(address(amm.ammTreasury()));
        uint256 strategyAaveBalanceAfter = IStrategy(amm.assetManagement().getStrategyAave()).balanceOf();
        uint256 strategyCompoundBalanceAfter = IStrategy(amm.assetManagement().getStrategyCompound()).balanceOf();
        uint256 ammTreasuryAssetBalanceAfter = IERC20(amm.dai()).balanceOf(address(amm.ammTreasury()));
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
        assertLe(strategyCompoundBalanceAfter, 5e17, "strategyCompoundBalanceAfter <= 0.5");
        assertEq(
            ammTreasuryAssetBalanceAfter,
            ammTreasuryAssetBalanceBefore,
            "ammTreasuryAssetBalanceAfter == ammTreasuryAssetBalanceBefore"
        );
        assertLe(
            ammTreasuryTotalBalanceBefore,
            ammTreasuryTotalBalanceAfter,
            "ammTreasuryTotalBalanceAfter <= ammTreasuryTotalBalanceBefore"
        );
        assertLe(
            ammTreasuryTotalBalanceAfter,
            ammTreasuryTotalBalanceBefore + 1e18,
            "ammTreasuryTotalBalanceAfter <= ammTreasuryTotalBalanceBefore + 1e18"
        );
    }
}

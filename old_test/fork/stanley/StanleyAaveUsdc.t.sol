// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.20;

import "forge-std/Test.sol";
import "contracts/vault/AssetManagementUsdc.sol";
import "contracts/tokens/IvToken.sol";
import "../UsdcAmm.sol";

contract AssetManagementAaveUsdcTest is Test {
    address internal _admin;

    function setUp() public {
        _admin = vm.rememberKey(1);
    }

    function testShouldAaveApyBeZeroAfterOverride() public {
        // given
        UsdcAmm amm = new UsdcAmm(_admin);

        // when
        amm.overrideAaveStrategyWithZeroApy(_admin);

        // then
        assertEq(IStrategy(amm.assetManagement().getStrategyAave()).getApy(), 0, "strategyCompoundApy == 0");
    }

    function testShouldAaveApyGreaterThanCompoundApy() public {
        // given
        UsdcAmm amm = new UsdcAmm(_admin);
        amm.overrideCompoundStrategyWithZeroApy(_admin);

        // when
        uint256 compoundApy = IStrategy(amm.assetManagement().getStrategyCompound()).getApy();
        uint256 aaveApy = IStrategy(amm.assetManagement().getStrategyAave()).getApy();

        // then
        assertGt(aaveApy, compoundApy, "aaveApy > compoundApy");
    }

    function testShouldAcceptDepositAndTransferTokensIntoAAVE() public {
        // given
        uint256 depositAmount = 10 * 1e6;
        UsdcAmm amm = new UsdcAmm(_admin);
        deal(amm.usdc(), address(amm.ammTreasury()), depositAmount);
        amm.overrideCompoundStrategyWithZeroApy(_admin);

        uint256 ammTreasuryIvTokenBefore = IvToken(amm.assetManagement().getIvToken()).balanceOf(address(amm.ammTreasury()));
        uint256 strategyBalanceBefore = IStrategy(amm.assetManagement().getStrategyAave()).balanceOf();
        uint256 ammTreasuryBalanceBefore = IERC20(amm.usdc()).balanceOf(address(amm.ammTreasury()));
        uint256 strategyATokenContractBefore = IERC20(amm.aUsdc()).balanceOf(amm.assetManagement().getStrategyAave());

        // when
        vm.startPrank(address(amm.ammTreasury()));
        amm.assetManagement().deposit(depositAmount * 1e12);

        // then
        uint256 ammTreasuryIvTokenAfter = IvToken(amm.assetManagement().getIvToken()).balanceOf(address(amm.ammTreasury()));
        uint256 strategyBalanceAfter = IStrategy(amm.assetManagement().getStrategyAave()).balanceOf();
        uint256 ammTreasuryBalanceAfter = IERC20(amm.usdc()).balanceOf(address(amm.ammTreasury()));
        uint256 strategyATokenContractAfter = IERC20(amm.aUsdc()).balanceOf(amm.assetManagement().getStrategyAave());

        assertEq(ammTreasuryIvTokenBefore, 0, "ammTreasuryIvTokenBefore == 0");
        assertEq(strategyBalanceBefore, 0, "strategyBalanceBefore == 0");
        assertGt(ammTreasuryIvTokenAfter, ammTreasuryIvTokenBefore, "ammTreasuryIvTokenAfter > ammTreasuryIvTokenAfter");
        assertGt(
            strategyBalanceAfter,
            strategyBalanceBefore,
            "strategyBalanceAfter > strategyBalanceAfter"
        );
        assertLt(ammTreasuryBalanceAfter, ammTreasuryBalanceBefore, "ammTreasuryBalanceAfter < ammTreasuryBalanceAfter");
        assertGt(
            strategyATokenContractAfter,
            strategyATokenContractBefore,
            "strategyATokenContractAfter > strategyATokenContractAfter"
        );
    }

    function testShouldAcceptDepositTwiceAndTransferTokensIntoAAVE() public {
        // given
        uint256 depositAmount = 10 * 1e6;
        UsdcAmm amm = new UsdcAmm(_admin);
        deal(amm.usdc(), address(amm.ammTreasury()), 2 * depositAmount);
        amm.overrideCompoundStrategyWithZeroApy(_admin);

        uint256 ammTreasuryIvTokenBefore = IvToken(amm.assetManagement().getIvToken()).balanceOf(address(amm.ammTreasury()));
        uint256 strategyBalanceBefore = IStrategy(amm.assetManagement().getStrategyAave()).balanceOf();
        uint256 ammTreasuryBalanceBefore = IERC20(amm.usdc()).balanceOf(address(amm.ammTreasury()));
        uint256 strategyATokenContractBefore = IERC20(amm.aUsdc()).balanceOf(amm.assetManagement().getStrategyAave());

        // when
        vm.startPrank(address(amm.ammTreasury()));
        amm.assetManagement().deposit(depositAmount * 1e12);
        amm.assetManagement().deposit(depositAmount * 1e12);

        // then
        uint256 ammTreasuryIvTokenAfter = IvToken(amm.assetManagement().getIvToken()).balanceOf(address(amm.ammTreasury()));
        uint256 strategyATokenContractAfter = IERC20(amm.aUsdc()).balanceOf(amm.assetManagement().getStrategyAave());
        uint256 ammTreasuryBalanceAfter = IERC20(amm.usdc()).balanceOf(address(amm.ammTreasury()));
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
        UsdcAmm amm = new UsdcAmm(_admin);
        amm.overrideCompoundStrategyWithZeroApy(_admin);

        vm.startPrank(address(amm.ammTreasury()));
        deal(amm.usdc(), address(amm.ammTreasury()), withdrawAmount);
        amm.assetManagement().deposit(withdrawAmount * 1e12);

        uint256 ammTreasuryIvTokenBefore = IvToken(amm.assetManagement().getIvToken()).balanceOf(address(amm.ammTreasury()));
        uint256 strategyBalanceBefore = IStrategy(amm.assetManagement().getStrategyAave()).balanceOf();
        uint256 ammTreasuryBalanceBefore = IERC20(amm.usdc()).balanceOf(address(amm.ammTreasury()));
        uint256 strategyATokenContractBefore = IERC20(amm.aUsdc()).balanceOf(amm.assetManagement().getStrategyAave());

        // when
        amm.assetManagement().withdraw(withdrawAmount * 1e12);

        // then
        uint256 strategyBalanceAfter = IStrategy(amm.assetManagement().getStrategyAave()).balanceOf();
        uint256 ammTreasuryIvTokenAfter = IvToken(amm.assetManagement().getIvToken()).balanceOf(address(amm.ammTreasury()));
        uint256 ammTreasuryBalanceAfter = IERC20(amm.usdc()).balanceOf(address(amm.ammTreasury()));
        uint256 strategyATokenContractAfter = IERC20(amm.aUsdc()).balanceOf(amm.assetManagement().getStrategyAave());

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
        UsdcAmm amm = new UsdcAmm(_admin);
        amm.overrideCompoundStrategyWithZeroApy(_admin);

        vm.startPrank(address(amm.ammTreasury()));
        deal(amm.usdc(), address(amm.ammTreasury()), withdrawAmount);
        amm.assetManagement().deposit(withdrawAmount * 1e12);

        uint256 ammTreasuryIvTokenBefore = IvToken(amm.assetManagement().getIvToken()).balanceOf(address(amm.ammTreasury()));
        uint256 strategyBalanceBefore = IStrategy(amm.assetManagement().getStrategyAave()).balanceOf();
        uint256 ammTreasuryBalanceBefore = IERC20(amm.usdc()).balanceOf(address(amm.ammTreasury()));
        uint256 strategyATokenContractBefore = IERC20(amm.aUsdc()).balanceOf(amm.assetManagement().getStrategyAave());

        // when
        amm.assetManagement().withdraw(strategyBalanceBefore);

        // then
        uint256 ammTreasuryIvTokenAfter = IvToken(amm.assetManagement().getIvToken()).balanceOf(address(amm.ammTreasury()));
        uint256 strategyBalanceAfter = IStrategy(amm.assetManagement().getStrategyAave()).balanceOf();
        uint256 ammTreasuryBalanceAfter = IERC20(amm.usdc()).balanceOf(address(amm.ammTreasury()));
        uint256 strategyATokenContractAfter = IERC20(amm.aUsdc()).balanceOf(amm.assetManagement().getStrategyAave());

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
        UsdcAmm amm = new UsdcAmm(_admin);
        amm.overrideCompoundStrategyWithZeroApy(_admin);

        vm.startPrank(address(amm.ammTreasury()));
        deal(amm.usdc(), address(amm.ammTreasury()), withdrawAmount);
        amm.assetManagement().deposit(withdrawAmount * 1e12);

        uint256 ammTreasuryIvTokenBefore = IvToken(amm.assetManagement().getIvToken()).balanceOf(address(amm.ammTreasury()));
        uint256 strategyBalanceBefore = IStrategy(amm.assetManagement().getStrategyAave()).balanceOf();
        uint256 ammTreasuryBalanceBefore = IERC20(amm.usdc()).balanceOf(address(amm.ammTreasury()));
        uint256 strategyATokenContractBefore = IERC20(amm.aUsdc()).balanceOf(amm.assetManagement().getStrategyAave());

        // when
        amm.assetManagement().withdrawAll();

        // then
        uint256 ammTreasuryIvTokenAfter = IvToken(amm.assetManagement().getIvToken()).balanceOf(address(amm.ammTreasury()));
        uint256 strategyBalanceAfter = IStrategy(amm.assetManagement().getStrategyAave()).balanceOf();
        uint256 ammTreasuryBalanceAfter = IERC20(amm.usdc()).balanceOf(address(amm.ammTreasury()));
        uint256 strategyATokenContractAfter = IERC20(amm.aUsdc()).balanceOf(amm.assetManagement().getStrategyAave());

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
        UsdcAmm amm = new UsdcAmm(_admin);
        amm.overrideCompoundStrategyWithZeroApy(_admin);
        deal(amm.usdc(), address(amm.ammTreasury()), 2 * amount);
        vm.startPrank(address(amm.ammTreasury()));

        // when
        amm.assetManagement().deposit(amount * 1e12);
        vm.warp(block.timestamp + ONE_WEEK_IN_SECONDS);
        amm.assetManagement().deposit(amount * 1e12);

        // then
        uint256 claimable = amm.aaveIncentivesController().getUserUnclaimedRewards(amm.assetManagement().getStrategyAave());
        assertEq(claimable, 0);
    }

}

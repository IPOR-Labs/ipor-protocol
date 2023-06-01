// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.20;

import "forge-std/Test.sol";
import "contracts/vault/AssetManagementUsdt.sol";
import "contracts/tokens/IvToken.sol";
import "../UsdtAmm.sol";

contract AssetManagementCompoundUsdtTest is Test {
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
        assertEq(IStrategy(amm.assetManagement().getStrategyCompound()).getApr(), 0, "strategyCompoundApr == 0");
    }

    function testShouldCompoundAprGreaterThanAaveApr() public {
        // given
        UsdtAmm amm = new UsdtAmm(_admin);
        amm.overrideAaveStrategyWithZeroApr(_admin);

        // when
        uint256 compoundApr = IStrategy(amm.assetManagement().getStrategyCompound()).getApr();
        uint256 aaveApr = IStrategy(amm.assetManagement().getStrategyAave()).getApr();

        // then
        assertGt(compoundApr, aaveApr, "compoundApr > aaveApr");
    }

    function testShouldAcceptDepositAndTransferTokensIntoCompound() public {
        // given
        uint256 depositAmount = 10 * 1e6;
        UsdtAmm amm = new UsdtAmm(_admin);
        deal(amm.usdt(), address(amm.ammTreasury()), depositAmount);
        amm.overrideAaveStrategyWithZeroApr(_admin);

        uint256 ammTreasuryIvTokenBefore = IvToken(amm.assetManagement().getIvToken()).balanceOf(address(amm.ammTreasury()));
        uint256 strategyBalanceBefore = IStrategy(amm.assetManagement().getStrategyCompound()).balanceOf();
        uint256 ammTreasuryBalanceBefore = IERC20(amm.usdt()).balanceOf(address(amm.ammTreasury()));
        uint256 strategyCTokenContractBefore = IERC20(amm.cUsdt()).balanceOf(amm.assetManagement().getStrategyCompound());

        // when
        vm.startPrank(address(amm.ammTreasury()));
        amm.assetManagement().deposit(depositAmount * 1e12);

        // then
        uint256 ammTreasuryIvTokenAfter = IvToken(amm.assetManagement().getIvToken()).balanceOf(address(amm.ammTreasury()));
        uint256 strategyBalanceAfter = IStrategy(amm.assetManagement().getStrategyCompound()).balanceOf();
        uint256 ammTreasuryBalanceAfter = IERC20(amm.usdt()).balanceOf(address(amm.ammTreasury()));
        uint256 strategyCTokenContractAfter = IERC20(amm.cUsdt()).balanceOf(amm.assetManagement().getStrategyCompound());

        assertEq(ammTreasuryIvTokenBefore, 0, "ammTreasuryIvTokenBefore == 0");
        assertEq(strategyBalanceBefore, 0, "strategyBalanceBefore == 0");
        assertEq(ammTreasuryIvTokenAfter, depositAmount * 1e12, "ammTreasuryIvTokenAfter == depositAmount");
        assertGt(
            strategyBalanceAfter,
            strategyCTokenContractBefore,
            "strategyBalanceAfter > strategyCTokenContractBefore"
        );
        assertLt(ammTreasuryBalanceAfter, ammTreasuryBalanceBefore, "ammTreasuryBalanceAfter < ammTreasuryBalanceBefore");
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
        deal(amm.usdt(), address(amm.ammTreasury()), 2 * depositAmount);
        amm.overrideAaveStrategyWithZeroApr(_admin);

        uint256 ammTreasuryIvTokenBefore = IvToken(amm.assetManagement().getIvToken()).balanceOf(address(amm.ammTreasury()));
        uint256 strategyBalanceBefore = IStrategy(amm.assetManagement().getStrategyCompound()).balanceOf();
        uint256 ammTreasuryBalanceBefore = IERC20(amm.usdt()).balanceOf(address(amm.ammTreasury()));
        uint256 strategyCTokenContractBefore = IERC20(amm.cUsdt()).balanceOf(amm.assetManagement().getStrategyCompound());

        // when
        vm.startPrank(address(amm.ammTreasury()));
        amm.assetManagement().deposit(depositAmount * 1e12);
        amm.assetManagement().deposit(depositAmount * 1e12);

        // then
        uint256 ammTreasuryIvTokenAfter = IvToken(amm.assetManagement().getIvToken()).balanceOf(address(amm.ammTreasury()));
        uint256 strategyCTokenContractAfter = IERC20(amm.cUsdt()).balanceOf(amm.assetManagement().getStrategyCompound());
        uint256 ammTreasuryBalanceAfter = IERC20(amm.usdt()).balanceOf(address(amm.ammTreasury()));
        uint256 strategyBalanceAfter = IStrategy(amm.assetManagement().getStrategyCompound()).balanceOf();

        assertGt(ammTreasuryIvTokenAfter, ammTreasuryIvTokenBefore, "ammTreasuryIvTokenAfter > ammTreasuryIvTokenBefore");
        assertGt(strategyBalanceAfter, strategyBalanceBefore, "strategyBalanceAfter > strategyBalanceBefore");
        assertLt(ammTreasuryBalanceAfter, ammTreasuryBalanceBefore, "ammTreasuryBalanceAfter < ammTreasuryBalanceBefore");
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

        vm.startPrank(address(amm.ammTreasury()));
        deal(amm.usdt(), address(amm.ammTreasury()), withdrawAmount);
        amm.assetManagement().deposit(withdrawAmount * 1e12);

        uint256 ammTreasuryIvTokenBefore = IvToken(amm.assetManagement().getIvToken()).balanceOf(address(amm.ammTreasury()));
        uint256 strategyBalanceBefore = IStrategy(amm.assetManagement().getStrategyCompound()).balanceOf();
        uint256 ammTreasuryBalanceBefore = IERC20(amm.usdt()).balanceOf(address(amm.ammTreasury()));
        uint256 strategyCTokenContractBefore = IERC20(amm.cUsdt()).balanceOf(amm.assetManagement().getStrategyCompound());

        // when
        amm.assetManagement().withdraw(withdrawAmount * 1e12);

        // then
        uint256 strategyBalanceAfter = IStrategy(amm.assetManagement().getStrategyCompound()).balanceOf();
        uint256 ammTreasuryIvTokenAfter = IvToken(amm.assetManagement().getIvToken()).balanceOf(address(amm.ammTreasury()));
        uint256 ammTreasuryBalanceAfter = IERC20(amm.usdt()).balanceOf(address(amm.ammTreasury()));
        uint256 strategyCTokenContractAfter = IERC20(amm.cUsdt()).balanceOf(amm.assetManagement().getStrategyCompound());

        assertLt(ammTreasuryIvTokenAfter, ammTreasuryIvTokenBefore, "ammTreasuryIvTokenAfter < ammTreasuryIvTokenBefore");
        assertLt(strategyBalanceAfter, strategyBalanceBefore, "strategyBalanceAfter < strategyBalanceBefore");
        assertGt(ammTreasuryBalanceAfter, ammTreasuryBalanceBefore, "ammTreasuryBalanceAfter > ammTreasuryBalanceBefore");
        assertLt(
            strategyCTokenContractAfter,
            strategyCTokenContractBefore,
            "strategyCTokenContractAfter < strategyCTokenContractBefore"
        );
    }

    function testShouldWithdrawAllAssetManagementBalanceFromCompoundWithdrawMethod() public {
        // given
        uint256 withdrawAmount = 100 * 1e6;
        UsdtAmm amm = new UsdtAmm(_admin);
        amm.overrideAaveStrategyWithZeroApr(_admin);

        vm.startPrank(address(amm.ammTreasury()));
        deal(amm.usdt(), address(amm.ammTreasury()), withdrawAmount);
        amm.assetManagement().deposit(withdrawAmount * 1e12);

        uint256 ammTreasuryIvTokenBefore = IvToken(amm.assetManagement().getIvToken()).balanceOf(address(amm.ammTreasury()));
        uint256 strategyBalanceBefore = IStrategy(amm.assetManagement().getStrategyCompound()).balanceOf();
        uint256 ammTreasuryBalanceBefore = IERC20(amm.usdt()).balanceOf(address(amm.ammTreasury()));

        // when
        amm.assetManagement().withdraw(strategyBalanceBefore);

        // then
        uint256 ammTreasuryIvTokenAfter = IvToken(amm.assetManagement().getIvToken()).balanceOf(address(amm.ammTreasury()));
        uint256 strategyBalanceAfter = IStrategy(amm.assetManagement().getStrategyCompound()).balanceOf();
        uint256 ammTreasuryBalanceAfter = IERC20(amm.usdt()).balanceOf(address(amm.ammTreasury()));
        uint256 strategyATokenContractAfter = IERC20(amm.aUsdt()).balanceOf(amm.assetManagement().getStrategyCompound());

        assertLt(ammTreasuryIvTokenAfter, ammTreasuryIvTokenBefore, "ammTreasuryIvTokenAfter < ammTreasuryIvTokenBefore");
        assertLt(strategyBalanceAfter, strategyBalanceBefore, "strategyBalanceAfter < strategyBalanceBefore");

        // Important check!
        assertLt(strategyBalanceAfter, 5e17, "strategyBalanceAfter < 5e17");
        assertGt(ammTreasuryBalanceAfter, ammTreasuryBalanceBefore, "ammTreasuryBalanceAfter > ammTreasuryBalanceBefore");
        assertEq(strategyATokenContractAfter, 0, "strategyATokenContractAfter == 0");
    }

    function testShouldWithdrawAllAssetManagementBalanceFromCompoundWithdrawAllMethod() public {
        // given
        uint256 withdrawAmount = 10 * 1e6;
        UsdtAmm amm = new UsdtAmm(_admin);
        amm.overrideAaveStrategyWithZeroApr(_admin);

        vm.startPrank(address(amm.ammTreasury()));
        deal(amm.usdt(), address(amm.ammTreasury()), withdrawAmount);
        amm.assetManagement().deposit(withdrawAmount * 1e12);

        uint256 ammTreasuryIvTokenBefore = IvToken(amm.assetManagement().getIvToken()).balanceOf(address(amm.ammTreasury()));
        uint256 strategyBalanceBefore = IStrategy(amm.assetManagement().getStrategyCompound()).balanceOf();
        uint256 ammTreasuryBalanceBefore = IERC20(amm.usdt()).balanceOf(address(amm.ammTreasury()));

        // when
        amm.assetManagement().withdrawAll();

        // then
        uint256 ammTreasuryIvTokenAfter = IvToken(amm.assetManagement().getIvToken()).balanceOf(address(amm.ammTreasury()));
        uint256 strategyBalanceAfter = IStrategy(amm.assetManagement().getStrategyCompound()).balanceOf();
        uint256 ammTreasuryBalanceAfter = IERC20(amm.usdt()).balanceOf(address(amm.ammTreasury()));
        uint256 strategyATokenContractAfter = IERC20(amm.aUsdt()).balanceOf(amm.assetManagement().getStrategyCompound());

        assertLt(ammTreasuryIvTokenAfter, ammTreasuryIvTokenBefore, "ammTreasuryIvTokenAfter < ammTreasuryIvTokenBefore");
        assertLt(strategyBalanceAfter, strategyBalanceBefore, "strategyBalanceAfter < strategyBalanceBefore");
        // Important check!
        assertLt(strategyBalanceAfter, 5e17, "strategyBalanceAfter < 5e17");
        assertGt(ammTreasuryBalanceAfter, ammTreasuryBalanceBefore, "ammTreasuryBalanceAfter > ammTreasuryBalanceBefore");
        assertEq(strategyATokenContractAfter, 0, "strategyATokenContractAfter == 0");
    }

    function testShouldSetNewCompoundStrategyForUSDT() public {
        // given
        uint256 deposit_loss = 3e12;
        uint256 depositAmount = 100_000 * 1e6;
        UsdtAmm amm = new UsdtAmm(_admin);
        amm.overrideAaveStrategyWithZeroApr(_admin);

        vm.startPrank(address(amm.ammTreasury()));
        deal(amm.usdt(), address(amm.ammTreasury()), depositAmount);
        amm.assetManagement().deposit(depositAmount * 1e12);
        vm.stopPrank();

        address strategyV1 = amm.assetManagement().getStrategyCompound();

        uint256 strategyBalanceBefore = IStrategy(strategyV1).balanceOf();
        uint256 strategyCompoundV2BalanceBefore = amm.strategyCompoundV2().balanceOf();
        uint256 ammTreasuryAssetBalanceBefore = IERC20(amm.usdt()).balanceOf(address(amm.ammTreasury()));

        // when
        vm.startPrank(_admin);
        amm.assetManagement().setStrategyCompound(address(amm.strategyCompoundV2()));

        // then
        uint256 strategyBalanceAfter = IStrategy(strategyV1).balanceOf();
        uint256 strategyCompoundV2BalanceAfter = amm.strategyCompoundV2().balanceOf();
        uint256 ammTreasuryAssetBalanceAfter = IERC20(amm.usdt()).balanceOf(address(amm.ammTreasury()));

        assertGe(
            strategyBalanceBefore + deposit_loss,
            depositAmount * 1e12 - deposit_loss,
            "strategyBalanceBefore >= depositAmount * 1e12 - deposit_loss"
        );
        assertLe(strategyBalanceBefore, depositAmount * 1e12, "strategyBalanceBefore <= depositAmount * 1e12");

        assertEq(strategyCompoundV2BalanceBefore, 0, "strategyCompoundV2BalanceBefore == 0");
        assertLe(strategyBalanceAfter, deposit_loss, "strategyBalanceAfter <= deposit_loss");
        // Great Than Equal because with accrued interest
        assertGe(
            strategyCompoundV2BalanceAfter,
            depositAmount * 1e12 - deposit_loss,
            "strategyCompoundV2BalanceAfter >= depositAmount - deposit_loss"
        );
        assertEq(
            ammTreasuryAssetBalanceBefore,
            ammTreasuryAssetBalanceAfter,
            "ammTreasuryAssetBalanceBefore == ammTreasuryAssetBalanceAfter"
        );
    }

    function testShouldMigrateAssetToStrategyWithMaxAPR() public {
        // given
        uint256 deposit_loss = 1e12;
        uint256 depositAmount = 10 * 1e6;
        UsdtAmm amm = new UsdtAmm(_admin);
        amm.overrideCompoundStrategyWithZeroApr(_admin);
        deal(amm.usdt(), address(amm.ammTreasury()), depositAmount);
        vm.startPrank(address(amm.ammTreasury()));
        amm.assetManagement().deposit(depositAmount * 1e12);
        vm.stopPrank();
        amm.restoreStrategies(_admin);
        amm.overrideAaveStrategyWithZeroApr(_admin);

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
            ammTreasuryAssetBalanceAfter,
            ammTreasuryAssetBalanceBefore,
            "ammTreasuryAssetBalanceAfter == ammTreasuryAssetBalanceBefore"
        );
        assertLe(
            ammTreasuryTotalBalanceBefore,
            ammTreasuryTotalBalanceAfter + deposit_loss,
            "ammTreasuryTotalBalanceBefore <= ammTreasuryTotalBalanceAfter + deposit_loss"
        );
        assertLe(
            ammTreasuryTotalBalanceAfter,
            ammTreasuryTotalBalanceBefore,
            "ammTreasuryTotalBalanceAfter <= ammTreasuryTotalBalanceBefore"
        );
    }
}

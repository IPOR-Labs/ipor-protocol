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

    function testShouldCompoundApyBeZeroAfterOverride() public {
        // given
        UsdtAmm amm = new UsdtAmm(_admin);

        // when
        amm.overrideCompoundStrategyWithZeroApy(_admin);

        // then
        assertEq(IStrategy(amm.assetManagement().getStrategyCompound()).getApy(), 0, "strategyCompoundApy == 0");
    }

    function testShouldCompoundApyGreaterThanAaveApy() public {
        // given
        UsdtAmm amm = new UsdtAmm(_admin);
        amm.overrideAaveStrategyWithZeroApy(_admin);

        // when
        uint256 compoundApy = IStrategy(amm.assetManagement().getStrategyCompound()).getApy();
        uint256 aaveApy = IStrategy(amm.assetManagement().getStrategyAave()).getApy();

        // then
        assertGt(compoundApy, aaveApy, "compoundApy > aaveApy");
    }

    function testShouldAcceptDepositAndTransferTokensIntoCompound() public {
        // given
        uint256 depositAmount = 10 * 1e6;
        UsdtAmm amm = new UsdtAmm(_admin);
        deal(amm.usdt(), address(amm.ammTreasury()), depositAmount);
        amm.overrideAaveStrategyWithZeroApy(_admin);

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
        amm.overrideAaveStrategyWithZeroApy(_admin);

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
        amm.overrideAaveStrategyWithZeroApy(_admin);

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
        amm.overrideAaveStrategyWithZeroApy(_admin);

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
        amm.overrideAaveStrategyWithZeroApy(_admin);

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


}

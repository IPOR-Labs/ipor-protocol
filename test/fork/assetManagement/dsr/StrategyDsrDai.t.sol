// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.16;

import "forge-std/Test.sol";
import "forge-std/console2.sol";
import "../../../TestCommons.sol";
import "../../DaiAmm.sol";
import "../../../../contracts/vault/interfaces/dsr/ISavingsDai.sol";
import "../../../../contracts/vault/interfaces/dsr/IDsrManager.sol";

contract StanleyDsrDaiTest is Test, TestCommons {
    using SafeERC20Upgradeable for IERC20Upgradeable;
    address internal _admin;
    address internal _user;

    function setUp() public {
        _admin = vm.rememberKey(1);
        _user = vm.rememberKey(2);
    }

    function testShouldGetApr() public {
        // given
        DaiAmm amm = new DaiAmm(_admin);
        StrategyDsrDai strategy = amm.strategyDsr();

        // when
        uint256 apr = strategy.getApr();

        //then
        assertLe(apr, 1e18);
        assertGt(apr, 0);
    }

    function testShouldDepositSimpleCase() public {
        // given
        uint256 amount = 1000 * 1e18;
        DaiAmm amm = new DaiAmm(_admin);
        StrategyDsrDai strategy = amm.strategyDsr();

        deal(amm.dai(), address(amm.stanley()), 1000_000 * 1e18);

        IERC20Upgradeable asset = IERC20Upgradeable(amm.dai());

        vm.startPrank(address(amm.stanley()));
        asset.safeApprove(address(strategy), type(uint256).max);
        vm.stopPrank();

        uint256 stanleyErc20BalanceBefore = asset.balanceOf(address(amm.stanley()));
        uint256 strategyBalanceBeforeDeposit = strategy.balanceOf();
        //when
        vm.prank(address(amm.stanley()));
        strategy.deposit(amount);

        vm.warp(block.timestamp + 1 days);
        uint256 strategyBalanceAfterDeposit = strategy.balanceOf();

        // then
        uint256 stanleyErc20BalanceAfter = asset.balanceOf(address(amm.stanley()));
        assertEq(stanleyErc20BalanceAfter, stanleyErc20BalanceBefore - amount);
        assertGt(strategyBalanceAfterDeposit - amount, strategyBalanceBeforeDeposit);
    }

    function testShouldDepositOneDay() public {
        // given
        uint256 amount = 1000 * 1e18;
        DaiAmm amm = new DaiAmm(_admin);
        StrategyDsrDai strategy = amm.strategyDsr();

        deal(amm.dai(), address(amm.stanley()), 1000_000 * 1e18);

        IERC20Upgradeable asset = IERC20Upgradeable(amm.dai());

        vm.startPrank(address(amm.stanley()));
        asset.safeApprove(address(strategy), type(uint256).max);
        vm.stopPrank();

        //when
        vm.prank(address(amm.stanley()));
        strategy.deposit(amount);
        uint256 strategyBalanceAfterDeposit = strategy.balanceOf();

        vm.warp(block.timestamp + 1 days);

        // then
        uint256 balanceAfterOneDay = strategy.balanceOf();

        assertGt(balanceAfterOneDay, strategyBalanceAfterDeposit);
    }

    function testShouldDepositOneYearCheckApr2DecimalPlaces() public {
        // given
        uint256 amount = 1000 * 1e18;
        DaiAmm amm = new DaiAmm(_admin);
        StrategyDsrDai strategy = amm.strategyDsr();

        deal(amm.dai(), address(amm.stanley()), 1000_000 * 1e18);

        IERC20Upgradeable asset = IERC20Upgradeable(amm.dai());

        vm.startPrank(address(amm.stanley()));
        asset.safeApprove(address(strategy), type(uint256).max);
        vm.stopPrank();

        uint256 apy = strategy.getApr();

        vm.prank(address(amm.stanley()));
        strategy.deposit(amount);

        // when
        vm.warp(block.timestamp + 365 days);
        uint256 balanceAfterOneYear2DecimalPlaces = IporMath.division(strategy.balanceOf(), 1e16);

        //then
        uint256 amountAccrued2DecimalPlaces = IporMath.division(
            amount + IporMath.division(amount * apy, 1e18),
            1e16
        );
        assertEq(
            balanceAfterOneYear2DecimalPlaces,
            amountAccrued2DecimalPlaces,
            "balanceAfterOneYear2DecimalPlaces should be equal to amountAccrued2DecimalPlaces"
        );
    }

    function testShouldCompareDsrManagerWithSDai() public {
        // given
        address sDai = 0x83F20F44975D03b1b09e64809B757c47f942BEeA;
        address dsrManager = 0x373238337Bfe1146fb49989fc222523f83081dDb;
        uint256 amount = 1000 * 1e18;
        DaiAmm amm = new DaiAmm(_admin);
        StrategyDsrDai strategy = amm.strategyDsr();

        deal(amm.dai(), address(amm.stanley()), 1000_000 * 1e18);

        IERC20Upgradeable asset = IERC20Upgradeable(amm.dai());

        vm.startPrank(address(amm.stanley()));
        asset.safeApprove(dsrManager, type(uint256).max);
        asset.safeApprove(sDai, type(uint256).max);
        vm.stopPrank();

        //when
        /// @dev deposit amount using dsrManager
        vm.startPrank(address(amm.stanley()));
        IDsrManager(dsrManager).join(address(strategy), amount);
        vm.stopPrank();

        /// @dev deposit amount using Savings DAI
        vm.prank(address(amm.stanley()));
        ISavingsDai(sDai).deposit(amount, address(strategy));

        //then
        vm.warp(block.timestamp + 365 days);

        uint256 sDaiShares = ISavingsDai(sDai).balanceOf(address(strategy));
        uint256 accruedAmountSDai = ISavingsDai(sDai).convertToAssets(sDaiShares);
        uint256 accruedAmountDsrManager = IDsrManager(dsrManager).daiBalance(address(strategy));

        assertEq(accruedAmountSDai, accruedAmountDsrManager);
    }

    function testShouldWithdrawSimpleCase() public {
        // given
        uint256 amount = 1000 * 1e18;
        DaiAmm amm = new DaiAmm(_admin);
        StrategyDsrDai strategy = amm.strategyDsr();

        deal(amm.dai(), address(amm.stanley()), 1000_000 * 1e18);

        IERC20Upgradeable asset = IERC20Upgradeable(amm.dai());

        vm.startPrank(address(amm.stanley()));
        asset.safeApprove(address(strategy), type(uint256).max);
        vm.stopPrank();

        uint256 stanleyErc20BalanceBefore = asset.balanceOf(address(amm.stanley()));

        vm.prank(address(amm.stanley()));
        strategy.deposit(amount);

        vm.warp(block.timestamp + 365 days);

        uint256 strategyBalanceBeforeDepositAfter365days = strategy.balanceOf();

        //when
        vm.prank(address(amm.stanley()));
        strategy.withdraw(strategyBalanceBeforeDepositAfter365days);

        // then
        uint256 strategyBalanceAfterDeposit = strategy.balanceOf();
        uint256 stanleyErc20BalanceAfter = asset.balanceOf(address(amm.stanley()));

        assertEq(strategyBalanceAfterDeposit, 0);
        assertEq(
            stanleyErc20BalanceAfter,
            stanleyErc20BalanceBefore + strategyBalanceBeforeDepositAfter365days - amount
        );
    }

    function testShouldWihtdrawOneDay() public {
        // given
        uint256 amount = 1000 * 1e18;
        DaiAmm amm = new DaiAmm(_admin);
        StrategyDsrDai strategy = amm.strategyDsr();

        deal(amm.dai(), address(amm.stanley()), 1000_000 * 1e18);

        IERC20Upgradeable asset = IERC20Upgradeable(amm.dai());

        vm.startPrank(address(amm.stanley()));
        asset.safeApprove(address(strategy), type(uint256).max);
        vm.stopPrank();

        uint256 stanleyErc20BalanceBefore = asset.balanceOf(address(amm.stanley()));

        vm.prank(address(amm.stanley()));
        strategy.deposit(amount);

        vm.warp(block.timestamp + 1 days);

        uint256 strategyBalanceBeforeDepositAfter365days = strategy.balanceOf();

        //when
        vm.prank(address(amm.stanley()));
        strategy.withdraw(strategyBalanceBeforeDepositAfter365days);

        // then
        uint256 strategyBalanceAfterDeposit = strategy.balanceOf();
        uint256 stanleyErc20BalanceAfter = asset.balanceOf(address(amm.stanley()));

        assertEq(strategyBalanceAfterDeposit, 0);
        assertEq(
            stanleyErc20BalanceAfter,
            stanleyErc20BalanceBefore + strategyBalanceBeforeDepositAfter365days - amount
        );
        assertGt(strategyBalanceBeforeDepositAfter365days, amount);
    }

    function testShouldWithdrawOneYear() public {
        // given
        uint256 amount = 1000 * 1e18;
        DaiAmm amm = new DaiAmm(_admin);
        StrategyDsrDai strategy = amm.strategyDsr();

        deal(amm.dai(), address(amm.stanley()), 1000_000 * 1e18);

        IERC20Upgradeable asset = IERC20Upgradeable(amm.dai());

        vm.startPrank(address(amm.stanley()));
        asset.safeApprove(address(strategy), type(uint256).max);
        vm.stopPrank();

        uint256 stanleyErc20BalanceBefore = asset.balanceOf(address(amm.stanley()));

        vm.prank(address(amm.stanley()));
        strategy.deposit(amount);

        vm.warp(block.timestamp + 365 days);

        uint256 strategyBalanceBeforeDepositAfter365days = strategy.balanceOf();

        //when
        vm.prank(address(amm.stanley()));
        strategy.withdraw(strategyBalanceBeforeDepositAfter365days);

        // then
        uint256 strategyBalanceAfterDeposit = strategy.balanceOf();
        uint256 stanleyErc20BalanceAfter = asset.balanceOf(address(amm.stanley()));

        assertEq(strategyBalanceAfterDeposit, 0);
        assertEq(
            stanleyErc20BalanceAfter,
            stanleyErc20BalanceBefore + strategyBalanceBeforeDepositAfter365days - amount
        );
        assertGt(strategyBalanceBeforeDepositAfter365days, amount);
    }

    function testShouldNotWithdrawMoreThanBalance() public {
        // given
        uint256 amount = 1000 * 1e18;
        DaiAmm amm = new DaiAmm(_admin);
        StrategyDsrDai strategy = amm.strategyDsr();

        deal(amm.dai(), address(amm.stanley()), 1000_000 * 1e18);

        IERC20Upgradeable asset = IERC20Upgradeable(amm.dai());

        vm.startPrank(address(amm.stanley()));
        asset.safeApprove(address(strategy), type(uint256).max);
        vm.stopPrank();

        vm.prank(address(amm.stanley()));
        strategy.deposit(amount);

        vm.warp(block.timestamp + 365 days);

        uint256 strategyBalanceBeforeDepositAfter365days = strategy.balanceOf();

        vm.prank(address(amm.stanley()));
        //then
        vm.expectRevert("SavingsDai/insufficient-balance");
        //when
        strategy.withdraw(strategyBalanceBeforeDepositAfter365days + 100);
    }

    function testShouldNotWithdrawBecauseIssufficientAllowanceSDaiInteraction() public {
        // given
        address sDai = 0x83F20F44975D03b1b09e64809B757c47f942BEeA;

        uint256 amount = 1000 * 1e18;
        DaiAmm amm = new DaiAmm(_admin);
        StrategyDsrDai strategy = amm.strategyDsr();

        deal(amm.dai(), address(amm.stanley()), 1000_000 * 1e18);

        IERC20Upgradeable asset = IERC20Upgradeable(amm.dai());

        vm.startPrank(address(amm.stanley()));
        asset.safeApprove(address(strategy), type(uint256).max);
        asset.safeApprove(sDai, type(uint256).max);
        vm.stopPrank();

        vm.startPrank(address(_user));
        asset.safeApprove(sDai, type(uint256).max);
        vm.stopPrank();

        /// @dev deposit amount using Savings DAI
        vm.prank(address(amm.stanley()));
        ISavingsDai(sDai).deposit(amount, address(strategy));

        vm.warp(block.timestamp + 365 days);

        uint256 sDaiShares = ISavingsDai(sDai).balanceOf(address(strategy));
        uint256 accruedAmountSDai = ISavingsDai(sDai).convertToAssets(sDaiShares);

        vm.startPrank(address(_user));
        //then
        /// @dev user not have allowance to strategy's assets
        vm.expectRevert("SavingsDai/insufficient-allowance");
        //when
        ISavingsDai(sDai).withdraw(accruedAmountSDai, _user, address(strategy));
        vm.stopPrank();
    }

    function testShouldWithdrawBecauseCorrectMsgSenderSDaiInteraction() public {
        // given
        address sDai = 0x83F20F44975D03b1b09e64809B757c47f942BEeA;

        uint256 amount = 1000 * 1e18;
        DaiAmm amm = new DaiAmm(_admin);
        StrategyDsrDai strategy = amm.strategyDsr();

        deal(amm.dai(), address(amm.stanley()), 1000_000 * 1e18);

        IERC20Upgradeable asset = IERC20Upgradeable(amm.dai());

        vm.startPrank(address(amm.stanley()));
        asset.safeApprove(address(strategy), type(uint256).max);
        asset.safeApprove(sDai, type(uint256).max);
        vm.stopPrank();

        vm.startPrank(address(_user));
        asset.safeApprove(sDai, type(uint256).max);
        vm.stopPrank();

        /// @dev deposit amount using Savings DAI
        vm.prank(address(amm.stanley()));
        ISavingsDai(sDai).deposit(amount, address(strategy));

        vm.warp(block.timestamp + 365 days);

        uint256 sDaiShares = ISavingsDai(sDai).balanceOf(address(strategy));
        uint256 accruedAmountSDai = ISavingsDai(sDai).convertToAssets(sDaiShares);

        //then
        //when
        vm.startPrank(address(strategy));
        uint256 withdrawnShares = ISavingsDai(sDai).withdraw(
            accruedAmountSDai,
            _user,
            address(strategy)
        );
        vm.stopPrank();

        //then
        assertEq(withdrawnShares, sDaiShares);
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.20;

import "forge-std/Test.sol";

import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "../TestForkCommons.sol";

contract ForkStrategyAaveDepositTest is TestForkCommons {
    using SafeERC20Upgradeable for IERC20Upgradeable;

    address internal _admin;
    address internal _user;

    function setUp() public {
        /// @dev state of the blockchain: after deploy DSR, before upgrade to V2
        uint256 forkId = vm.createSelectFork(vm.envString("PROVIDER_URL"), 18070400);
        _admin = vm.rememberKey(1);
        _user = vm.rememberKey(2);
    }

    // AAve is paused
//    function testShouldDepositWhenNoInitialAllowanceToAaveLendingPoolDAI() public {
//        // given
//        _init();
//        _createNewStrategyAaveDai();
//
//        deal(DAI, address(stanleyProxyDai), 1000_000 * 1e18);
//
//        StrategyAave strategy = StrategyAave(strategyAaveDaiProxy);
//
//        IERC20Upgradeable asset = IERC20Upgradeable(DAI);
//
//        vm.startPrank(address(stanleyProxyDai));
//        asset.safeApprove(address(strategy), type(uint256).max);
//        vm.stopPrank();
//
//        uint256 strategyBalanceBefore = strategy.balanceOf();
//
//        //when
//        vm.prank(address(stanleyProxyDai));
//        strategy.deposit(10_000 * 1e18);
//
//        //then
//        address lendingPool = AaveLendingPoolProviderV2(aaveLendingPoolAddressProvider).getLendingPool();
//        uint256 newStrategyAllowanceToLendingPool = IERC20Upgradeable(asset).allowance(
//            address(strategyAaveDaiProxy),
//            lendingPool
//        );
//        uint256 strategyBalanceAfter = strategy.balanceOf();
//
//        assertEq(strategyBalanceAfter, strategyBalanceBefore + 10_000 * 1e18, "strategyBalanceAfter");
//        assertEq(newStrategyAllowanceToLendingPool, 0, "newStrategyAllowanceToLendingPool");
//    }

//    function testShouldDepositWhenNoInitialAllowanceToAaveLendingPoolUSDT() public {
//        // given
//        _init();
//        _createNewStrategyAaveUsdt();
//
//        deal(USDT, address(stanleyProxyUsdt), 1000_000 * 1e6);
//
//        StrategyAave strategy = StrategyAave(strategyAaveUsdtProxy);
//
//        IERC20Upgradeable asset = IERC20Upgradeable(USDT);
//
//        vm.startPrank(address(stanleyProxyUsdt));
//        asset.safeApprove(address(strategy), type(uint256).max);
//        vm.stopPrank();
//
//        uint256 strategyBalanceBefore = strategy.balanceOf();
//
//        //when
//        vm.prank(address(stanleyProxyUsdt));
//        strategy.deposit(10_000 * 1e18);
//
//        //then
//        address lendingPool = AaveLendingPoolProviderV2(aaveLendingPoolAddressProvider).getLendingPool();
//        uint256 newStrategyAllowanceToLendingPool = IERC20Upgradeable(asset).allowance(
//            address(strategyAaveUsdtProxy),
//            lendingPool
//        );
//        uint256 strategyBalanceAfter = strategy.balanceOf();
//
//        assertEq(strategyBalanceAfter, strategyBalanceBefore + 10_000 * 1e18, "strategyBalanceAfter");
//        assertEq(newStrategyAllowanceToLendingPool, 0, "newStrategyAllowanceToLendingPool");
//    }
}

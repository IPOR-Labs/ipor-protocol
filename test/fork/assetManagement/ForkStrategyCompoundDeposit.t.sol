// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.20;

import "forge-std/Test.sol";

import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "../TestForkCommons.sol";

contract ForkStrategyCompoundDepositTest is TestForkCommons {
    using SafeERC20Upgradeable for IERC20Upgradeable;

    address internal _admin;
    address internal _user;

    function setUp() public {
        /// @dev state of the blockchain: after deploy DSR, before upgrade to V2
        uint256 forkId = vm.createSelectFork(vm.envString("ETHEREUM_PROVIDER_URL"), 18560825);
        _admin = vm.rememberKey(1);
        _user = vm.rememberKey(2);
    }

    function testShouldDepositWhenNoInitialAllowanceToCompoundShareTokenDAI() public {
        // given
        _init();
        _createNewStrategyCompoundDai();

        deal(DAI, address(stanleyProxyDai), 1000_000 * 1e18);

        StrategyCompound strategy = StrategyCompound(strategyCompoundDaiProxy);

        IERC20Upgradeable asset = IERC20Upgradeable(DAI);

        vm.startPrank(address(stanleyProxyDai));
        asset.safeApprove(address(strategy), type(uint256).max);
        vm.stopPrank();

        uint256 strategyBalanceBefore = strategy.balanceOf();

        //when
        vm.prank(address(stanleyProxyDai));
        strategy.deposit(10_000 * 1e18);

        //then
        uint256 newStrategyAllowanceToShareToken = IERC20Upgradeable(asset).allowance(
            address(strategyCompoundDaiProxy),
            cDAI
        );
        uint256 strategyBalanceAfter = strategy.balanceOf();

        assertEq(strategyBalanceAfter, strategyBalanceBefore + 9999999999999794581997, "strategyBalanceAfter");
        assertEq(newStrategyAllowanceToShareToken, 0, "newStrategyAllowanceToShareToken");
    }

    function testShouldDepositWhenNoInitialAllowanceToCompoundShareTokenUSDT() public {
        // given
        _init();
        _createNewStrategyCompoundUsdt();

        deal(USDT, address(stanleyProxyUsdt), 1000_000 * 1e6);

        StrategyCompound strategy = StrategyCompound(strategyCompoundUsdtProxy);

        IERC20Upgradeable asset = IERC20Upgradeable(USDT);

        vm.startPrank(address(stanleyProxyUsdt));
        asset.safeApprove(address(strategy), type(uint256).max);
        vm.stopPrank();

        uint256 strategyBalanceBefore = strategy.balanceOf();

        //when
        vm.prank(address(stanleyProxyUsdt));
        strategy.deposit(10_000 * 1e18);

        //then

        uint256 newStrategyAllowanceToShareToken = IERC20Upgradeable(asset).allowance(
            address(strategyCompoundUsdtProxy),
            cUSDT
        );
        uint256 strategyBalanceAfter = strategy.balanceOf();

        assertEq(strategyBalanceAfter, strategyBalanceBefore + 9999999999999967627762, "strategyBalanceAfter");
        assertEq(newStrategyAllowanceToShareToken, 0, "newStrategyAllowanceToShareToken");
    }
}

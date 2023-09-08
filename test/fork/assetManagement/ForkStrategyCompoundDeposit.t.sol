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
        uint256 forkId = vm.createSelectFork(vm.envString("PROVIDER_URL"), 18070400);
        _admin = vm.rememberKey(1);
        _user = vm.rememberKey(2);
    }

    function testShouldDepositWhenNoInitialAllowanceToCompoundShareToken() public {
        // given
        _init();
        _createNewStrategyCompoundDai();

        deal(DAI, address(stanleyProxyDai), 1000_000 * 1e18);

        StrategyCompound strategy = StrategyCompound(newStrategyCompoundDaiProxy);

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
            address(newStrategyCompoundDaiProxy),
            cDAI
        );
        uint256 strategyBalanceAfter = strategy.balanceOf();

        assertEq(strategyBalanceAfter, strategyBalanceBefore + 9999999999999883609072);
        assertEq(newStrategyAllowanceToShareToken, 0);
    }
}

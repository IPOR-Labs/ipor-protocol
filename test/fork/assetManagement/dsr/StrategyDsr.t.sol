// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.16;

import "forge-std/Test.sol";
import "forge-std/console2.sol";
import "../../../TestCommons.sol";
import "../../DaiAmm.sol";

contract StanleyAaveDaiTest is Test, TestCommons {
    using SafeERC20Upgradeable for IERC20Upgradeable;
    address internal _admin;

    function setUp() public {
        _admin = vm.rememberKey(1);
    }

    function testShould() public {
        // given
        DaiAmm amm = new DaiAmm(_admin);
        StrategyDsr strategy = amm.strategyDsr();

        // when
        uint256 apr = strategy.getApr();

        console2.log("apr=", apr);

        deal(amm.dai(), address(amm.stanley()), 1000_000 * 1e18);


        IERC20Upgradeable asset = IERC20Upgradeable(amm.dai());

        vm.startPrank(address(amm.stanley()));
        //TODO: use it in stanley
        asset.safeApprove(address(strategy), type(uint256).max);
        vm.stopPrank();

        vm.startPrank(address(amm.strategyDsr()));
        //TODO: use it in stanley
        asset.safeApprove(0x373238337Bfe1146fb49989fc222523f83081dDb, type(uint256).max);
        vm.stopPrank();

        vm.prank(address(amm.stanley()));
        strategy.deposit(1000*1e18);
        // then
    }
}

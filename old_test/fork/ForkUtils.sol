// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.20;

import "forge-std/Test.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "test/TestCommons.sol";
import "contracts/amm/pool/Joseph.sol";
import "contracts/amm/AmmTreasury.sol";
import "contracts/interfaces/types/IAsset.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract ForkUtils is Test, TestCommons {
    function basicInteractWithAmm(
        address owner,
        address asset,
        address joseph,
        address ammTreasury
    ) public {
        address userOne = _getUserAddress(1);
        uint256 assetDecimals = IERC20Metadata(asset).decimals();
        deal(asset, userOne, 1_000_000 * 10**assetDecimals);

        vm.prank(owner);
        Joseph(joseph).addAppointedToRebalance(owner);

        vm.startPrank(userOne);
        IAsset(asset).approve(joseph, 1_000_000 * 10**assetDecimals);
        IAsset(asset).approve(ammTreasury, 1_000_000 * 10**assetDecimals);
        Joseph(joseph).provideLiquidity(10_000 * 10**assetDecimals);

        uint256 swapPayFixedId = AmmTreasury(ammTreasury).openSwapPayFixed(10_000 * 10**assetDecimals, 1e18, 100e18);
        uint256 swapPayReceiveId = AmmTreasury(ammTreasury).openSwapReceiveFixed(10_000 * 10**assetDecimals, 0, 100e18);
        vm.stopPrank();

        vm.warp(block.timestamp + 60 * 60 * 24 * 7);

        vm.startPrank(owner);
        AmmTreasury(ammTreasury).closeSwapPayFixed(swapPayFixedId);
        AmmTreasury(ammTreasury).closeSwapReceiveFixed(swapPayReceiveId);
        vm.stopPrank();

        vm.prank(owner);
        Joseph(joseph).rebalance();

        vm.prank(userOne);
        Joseph(joseph).redeem(9_000e18);

        vm.warp(block.timestamp + 60 * 60 * 24 * 7);

        vm.prank(owner);
        Joseph(joseph).rebalance();
    }
}

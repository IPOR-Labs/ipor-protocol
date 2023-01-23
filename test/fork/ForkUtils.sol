// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.16;

import "forge-std/Test.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "../TestCommons.sol";
import "../../contracts/amm/pool/Joseph.sol";
import "../../contracts/amm/Milton.sol";
import "./IAsset.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";




contract ForkUtils is Test, TestCommons {
    function basicInteractWithAmm(address owner, address asset, address joseph, address milton) public {
        address userOne = _getUserAddress(1);
        uint256 assetDecimals = IERC20Metadata(asset).decimals();
        deal(asset, userOne, 1_000_000*10**assetDecimals);

        vm.prank(owner);
        Joseph(joseph).addAppointedToRebalance(owner);

        vm.startPrank(userOne);
        IAsset(asset).approve(joseph, 1_000_000*10**assetDecimals);
        IAsset(asset).approve(milton, 1_000_000*10**assetDecimals);
        Joseph(joseph).provideLiquidity(10_000*10**assetDecimals);
        uint256 swapPayFixedId = Milton(milton).openSwapPayFixed(10_000*10**assetDecimals, 1e18, 500e18);
        uint256 swapPayReceiveId = Milton(milton).openSwapReceiveFixed(10_000*10**assetDecimals, 10**(assetDecimals-3), 500e18);
        vm.stopPrank();

        vm.warp(block.timestamp + 60*60*24*7);

        vm.startPrank(userOne);
        Milton(milton).closeSwapPayFixed(swapPayFixedId);
        Milton(milton).closeSwapReceiveFixed(swapPayReceiveId);
        vm.stopPrank();

        vm.prank(owner);
        Joseph(joseph).rebalance();

        vm.prank(userOne);
        Joseph(joseph).redeem(9_000e18);

        vm.warp(block.timestamp + 60*60*24*7);

        vm.prank(owner);
        Joseph(joseph).rebalance();
    }
}
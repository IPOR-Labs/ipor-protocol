// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.20;

import "forge-std/Test.sol";
import "contracts/vault/AssetManagementDai.sol";
import "contracts/tokens/IvToken.sol";
import "../DaiAmm.sol";

contract AssetManagementAaveDaiTest is Test {
    address internal _admin;

    function setUp() public {
        _admin = vm.rememberKey(1);
    }


    function testShouldUnclaimedRewardsFromAAVEEqualsZero() public {
        //given
        uint256 ONE_WEEK_IN_SECONDS = 60 * 60 * 24 * 7;
        uint256 amount = 100_000 * 1e18;
        DaiAmm amm = new DaiAmm(_admin);
        amm.overrideCompoundStrategyWithZeroApy(_admin);
        deal(amm.dai(), address(amm.ammTreasury()), 2 * amount);
        vm.startPrank(address(amm.ammTreasury()));

        // when
        amm.assetManagement().deposit(amount);
        vm.warp(block.timestamp + ONE_WEEK_IN_SECONDS);
        amm.assetManagement().deposit(amount);

        // then
        uint256 claimable = amm.aaveIncentivesController().getUserUnclaimedRewards(amm.assetManagement().getStrategyAave());
        assertEq(claimable, 0);
    }

}

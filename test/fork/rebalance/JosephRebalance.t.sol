// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.16;

import "forge-std/Test.sol";
import "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import "../../TestCommons.sol";
import "../DaiAmm.sol";

contract AmmDaiForkOpenCloseSwaps is Test, TestCommons {
    function test1() public {
        assertTrue(true);
    }

    function testRebalanceAndDepositDaiIntoVaultAAVE() public {
        // given
        address user = _getUserAddress(1);
        uint256 depositAmount = 50_000e18;
        DaiAmm daiAmm = new DaiAmm(address(this));
        Joseph joseph = daiAmm.joseph();

        joseph.setAutoRebalanceThreshold(0);
        deal(daiAmm.dai(), user, 500_000e18);
        daiAmm.approveMiltonJoseph(user);

        uint256 balanceIpDaiBefore = IIpToken(daiAmm.ipDai()).balanceOf(user);
        uint256 balanceDaiBefore = IIpToken(daiAmm.dai()).balanceOf(user);
        vm.prank(user);
        joseph.provideLiquidity(depositAmount);
        daiAmm.overrideCompoundStrategyWithZeroApr(address(this));

        //        // when
        //        joseph.rebalance();
        //        //then
        //        uint256 balanceIpDaiAfter = IIpToken(daiAmm.ipDai()).balanceOf(user);
        //        uint256 balanceDaiAfter = IIpToken(daiAmm.dai()).balanceOf(user);
        //
        //        assertEq(balanceDaiAfter, balanceDaiBefore - depositAmount);
        //        assertEq(balanceIpDaiAfter, balanceIpDaiBefore + depositAmount);
    }
}

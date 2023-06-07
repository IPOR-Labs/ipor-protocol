// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.20;

import "./TestForkCommons.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "contracts/interfaces/IAmmGovernanceService.sol";
import "contracts/interfaces/IIpToken.sol";

contract FirstForkTest is TestForkCommons {
    function test() public {
        // given
        _init();
        address user = _getUserAddress(22);
        console2.log("user", user);

        vm.prank(user);
        ERC20(DAI).approve(iporProtocolRouterProxy, type(uint256).max);
        deal(DAI, user, 500_000e18);

        vm.prank(owner);
        IIpToken(ipDAI).setJoseph(iporProtocolRouterProxy);

        uint256 balanceIpDaiBefore = ERC20(ipDAI).balanceOf(user);
        uint256 balanceDaiBefore = ERC20(DAI).balanceOf(user);

        vm.prank(owner);
        IAmmGovernanceService(iporProtocolRouterProxy).setAmmPoolsParams(DAI, type(uint32).max, type(uint32).max, 0,5000);

        // when
        vm.prank(user);
        IAmmPoolsService(iporProtocolRouterProxy).provideLiquidityDai(user, 10_000e18);

        // then
        uint256 balanceIpDaiAfter = ERC20(ipDAI).balanceOf(user);
        uint256 balanceDaiAfter = ERC20(DAI).balanceOf(user);


        console2.log("balanceIpDaiBefore", balanceIpDaiBefore);
        console2.log("balanceDaiBefore", balanceDaiBefore);
        console2.log("balanceIpDaiAfter", balanceIpDaiAfter);
        console2.log("balanceDaiAfter", balanceDaiAfter);
    }
}

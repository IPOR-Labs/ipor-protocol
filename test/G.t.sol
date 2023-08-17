// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.20;

import "forge-std/Test.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "../contracts/interfaces/IAmmPoolsService.sol";

contract G is Test {
    address user = 0x9642f499eAd3c9e345d5B4a56B8D7b357E7c9337; // user with ipDai and ipUsdc
    address iporRouterProxy = 0xD201B7d1d5a3A95cC8484B9d285063b54E5d2054;
    address ipDai = 0xb3F75634445dD307215AB58f2Da76d3d9C4FfA10;
    address ipUsdc = 0xA4417460B2B52DD49807Dcee39A0e9104a452f18;
    address usdc = 0x0e6c016417A0108b76E35939EE7F8F922a4Ef638;

    function setUp() public {
        vm.createSelectFork("https://eth-goerli.g.alchemy.com/v2/<ADD Key>", 9535496);
    }

    function testRedeemIpDai() public {
        // read balance of ipDai
        uint balanceIpDai = IERC20(ipDai).balanceOf(user);
        console2.log("balanceIpDai", balanceIpDai);

        // redeem half of ipDai
        vm.prank(user);
        IAmmPoolsService(iporRouterProxy).redeemFromAmmPoolDai(user, balanceIpDai / 2);

        // read balance of ipDai after redeem
        uint balanceIpDaiAfterRedeem = IERC20(ipDai).balanceOf(user);
        console2.log("balanceIpDaiAfterRedeem", balanceIpDaiAfterRedeem);
    }

    function testRedeemIpUsdc() public {
        // read balance of ipUsdc
        uint balanceIpUsdc = IERC20(ipUsdc).balanceOf(user);
        console2.log("balanceIpUsdc", balanceIpUsdc);

        // redeem half of ipUsdc
        vm.prank(user);
        IAmmPoolsService(iporRouterProxy).redeemFromAmmPoolUsdc(user, balanceIpUsdc / 2);

        // read balance of ipUsdc after redeem
        uint balanceIpUsdcAfterRedeem = IERC20(ipUsdc).balanceOf(user);
        console2.log("balanceIpUsdcAfterRedeem", balanceIpUsdcAfterRedeem);
    }

    function testProvideUsdcAndRedeemUSDC() public {
        // perpetrate new address for interact with protocol
        address user2 = vm.rememberKey(2345);
        deal(usdc, user2, 1_000e6);
        vm.prank(user2);
        IERC20(usdc).approve(iporRouterProxy, 1_000e6);

        // provide liquidity
        vm.prank(user2);
        IAmmPoolsService(iporRouterProxy).provideLiquidityUsdc(user2, 200e6);

        // read balance of ipUsdc
        uint balanceIpUsdc = IERC20(ipUsdc).balanceOf(user2);
        console2.log("balanceIpUsdc", balanceIpUsdc);

        // redeem all ipUsdc
        vm.prank(user2);
        IAmmPoolsService(iporRouterProxy).redeemFromAmmPoolUsdc(user2, balanceIpUsdc);

        // read balance of ipUsdc after redeem
        uint balanceIpUsdcAfterRedeem = IERC20(ipUsdc).balanceOf(user2);
        console2.log("balanceIpUsdcAfterRedeem", balanceIpUsdcAfterRedeem);
    }

}

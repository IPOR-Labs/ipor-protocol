// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.20;

import "./TestCommons.sol";
import "../contracts/oracles/libraries/IporLogic.sol";
import "../contracts/amm-weEth/AmmPoolsServiceWeEth.sol";
import "./utils/TestConstants.sol";
import "../contracts/interfaces/types/IporOracleTypes.sol";
import "../contracts/chains/ethereum/amm-commons/AmmGovernanceService.sol";
import "../contracts/vault/strategies/StrategyCompound.sol";
import "../contracts/vault/strategies/StrategyAave.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract IporLogicTest is TestCommons {
    address constant user = 0x4a95d7087503451B9746D018b304001D12c55d2a;
    address constant weETH = 0xDB34B028E7A996e6Ae220bbe450A1FbEEf51239b;
    address constant eETH = 0x938e6273f1573ae351B0dcf78C8acbc4547A810D;
    address constant wETH = 0x4C30580Ff48CC9058135fb58bCDFc1Ad19772067;
    address constant ETH = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;
    address constant IporProtocolRouterProxy = 0x1c882583F051A049d075fc4A8d44AB15790C892A;
    address constant eEthLiquidityPoolExternal = 0x0Ed035bf452Eba6cC1C71266E642f27D45c6a9AA;

    function testtttt() external {
        assertTrue(true);
    }

//    function testTTT() public {
//        //        vm.createSelectFork("https://Vh4Hd0lnPdIL:Lw1MNuLLjKZCJaALEJYKDyu2@dev.ipor.info:34001");
//        vm.createSelectFork("http://localhost:8545");
//        uint balancewETH = IERC20(wETH).balanceOf(user);
//        uint balancewEETH = IERC20(wETH).balanceOf(IporProtocolRouterProxy);
//        console2.log("balance wETH: ", balancewETH);
//        console2.log("balance ETH: ", user.balance);
//
//        uint balancewEETHRouter = IERC20(eETH).balanceOf(IporProtocolRouterProxy);
//        console2.log("balancewEETHRouter eETH: ", balancewEETHRouter);
//
//        vm.prank(user);
//        IEEthLiquidityPool(eEthLiquidityPoolExternal).deposit{value: 10e18}(user);
//
//        uint EEthBalanceUser = IEEthLiquidityPool(eEthLiquidityPoolExternal).getTotalEtherClaimOf(user);
//        uint balancewEETHUser = IERC20(eETH).balanceOf(user);
//
//        console2.log("EEthBalanceUser: ", EEthBalanceUser);
//        console2.log("balancewEETHUser: ", balancewEETHUser);
//        vm.prank(user);
//        AmmPoolsServiceWeEth(IporProtocolRouterProxy).provideLiquidity{value: 10464951643835616}(
//            weETH,
//            ETH,
//            user,
//            10464951643835616
//        );
//        vm.prank(user);
//        AmmPoolsServiceWeEth(IporProtocolRouterProxy).provideLiquidity(weETH, wETH, user, 10464951643835616);
//        vm.prank(user);
//        IERC20(eETH).approve(IporProtocolRouterProxy, 1000e18);
//        vm.prank(user);
//        AmmPoolsServiceWeEth(IporProtocolRouterProxy).provideLiquidity(weETH, eETH, user, 1e18);
//        vm.prank(user);
//        IERC20(eETH).approve(weETH, 1000e18);
//        vm.prank(user);
//        IWeEth(weETH).wrap(1e18);
//        vm.prank(user);
//        IERC20(weETH).approve(IporProtocolRouterProxy, 1000e18);
//        vm.prank(user);
//        AmmPoolsServiceWeEth(IporProtocolRouterProxy).provideLiquidity(weETH, weETH, user, 1e18);
//    }
}

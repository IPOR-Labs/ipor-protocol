// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.26;

import "forge-std/Test.sol";
import "./TestEthMarketCommons.sol";
import "../../contracts/libraries/errors/AmmErrors.sol";
import "../../contracts/chains/ethereum/router/IporProtocolRouterEthereum.sol";
import {IAmmPoolsLensBaseV1} from "../../contracts/base/interfaces/IAmmPoolsLensBaseV1.sol";

contract ProvideBatchExecutor is TestEthMarketCommons {
    function setUp() public {
        vm.createSelectFork(vm.envString("ETHEREUM_PROVIDER_URL"), 17810000);
        _init();
    }

    function testShouldProvideLiquidityWhenBatchExecutorIsUsed() external {
        // given
        uint256 userEthBalanceBefore = userOne.balance;
        uint256 userIpstEthBalanceBefore = IERC20(ipstEth).balanceOf(userOne);
        uint256 userStEthBalanceBefore = IStETH(stEth).balanceOf(userOne);
        uint256 userWEthBalanceBefore = IERC20(wEth).balanceOf(userOne);

        uint256 exchangeRateBefore = IAmmPoolsLensBaseV1(iporProtocolRouter).getIpTokenExchangeRate(stEth);
        uint256 ammTreasuryStEthBalanceBefore = IStETH(stEth).balanceOf(ammTreasuryStEth);

        bytes[] memory requestData = new bytes[](3);
        requestData[0] = abi.encodeWithSelector(
            IAmmPoolsServiceStEth(iporProtocolRouter).provideLiquidityStEth.selector,
            userOne,
            100e18
        );
        requestData[1] = abi.encodeWithSelector(
            IAmmPoolsServiceStEth(iporProtocolRouter).provideLiquidityWEth.selector,
            userOne,
            100e18
        );

        requestData[2] = abi.encodeWithSelector(
            IAmmPoolsServiceStEth(iporProtocolRouter).provideLiquidityEth.selector,
            userOne,
            100e18
        );

        // when
        vm.prank(userOne);
        IporProtocolRouterEthereum(iporProtocolRouter).batchExecutor{value: 150e18}(requestData);

        // then
        uint256 userEthBalanceAfter = userOne.balance;
        uint256 userIpstEthBalanceAfter = IERC20(ipstEth).balanceOf(userOne);
        uint256 userStEthBalanceAfter = IStETH(stEth).balanceOf(userOne);
        uint256 userWethBalanceAfter = IERC20(wEth).balanceOf(userOne);

        uint256 exchangeRateAfter = IAmmPoolsLensBaseV1(iporProtocolRouter).getIpTokenExchangeRate(stEth);
        uint256 ammTreasuryStEthBalanceAfter = IStETH(stEth).balanceOf(ammTreasuryStEth);

        assertEq(
            userEthBalanceAfter,
            userEthBalanceBefore - 100e18,
            " balance of userOne should be decreased by 100e18"
        );
        assertEq(userIpstEthBalanceBefore, 0, " balance of userOne should be 0");
        assertEq(
            userStEthBalanceBefore,
            49999999999999999999999,
            " balance of userOne should be 49999999999999999999999"
        );
        assertEq(userWEthBalanceBefore, 50_000e18, " balance of userOne should be 50_000e18");
        assertEq(exchangeRateBefore, exchangeRateAfter, " exchange rate should not be changed");
        assertEq(ammTreasuryStEthBalanceBefore, 0, "balance of ammTreasuryStEth should be 0 before providing liquidity");

        assertEq(
            userIpstEthBalanceAfter,
            299999999999999999999,
            " balance of userOne should be increased by 299999999999999999999"
        );
        assertEq(
            userStEthBalanceAfter,
            49899999999999999999999,
            " balance of userOne should be increased by 49899999999999999999999"
        );
        assertEq(
            userWethBalanceAfter,
            49_900_000000000000000000,
            " balance of userOne should be increased by 49900000000000000000000"
        );
        assertEq(
            ammTreasuryStEthBalanceAfter,
            299999999999999999998,
            "balance of ammTreasuryStEth should be 299999999999999999998 after providing liquidity"
        );
    }
}

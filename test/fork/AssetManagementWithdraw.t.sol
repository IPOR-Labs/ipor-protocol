// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.20;

import "./TestForkCommons.sol";
import "../../contracts/tokens/IvToken.sol";

contract AssetManagementWithdrawTest is TestForkCommons {
    function setUp() public {
        vm.createSelectFork(vm.envString("PROVIDER_URL"), 17990200);
    }

    function testShouldWithdrawFromAssetManagement() public {
        // given
        _init();

        address ammStorageAddr;
        (, , ammStorageAddr, , ) = IAmmTreasury(miltonProxyUsdt).getConfiguration();

        AmmStorage ammStorage = AmmStorage(ammStorageAddr);

        uint256 erc20BalanceBefore = IERC20(USDT).balanceOf(address(miltonProxyUsdt));
        console2.log("BEFORE erc20BalanceBefore=", erc20BalanceBefore);

        //when
        vm.startPrank(owner);
        IAmmGovernanceService(iporProtocolRouterProxy).withdrawFromAssetManagement(USDT, 10e18);
        vm.stopPrank();

        uint256 erc20BalanceAfter = IERC20(USDT).balanceOf(address(miltonProxyUsdt));
        console2.log("AFTER erc20BalanceBefore=", erc20BalanceAfter);
        console2.log("DIFF=", erc20BalanceAfter - erc20BalanceBefore);

        //TODO: pause aave and dsr
        //TODO: deposit to compound
        //TODO: withdraw from compound and make below zero interest
        //then
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.20;
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

import "../../contracts/interfaces/IAmmGovernanceService.sol";
import "../../contracts/interfaces/IAmmGovernanceService.sol";
import "./WeEthTestForkCommon.sol";

contract WeEthForkAmmGovernanceServiceTest is WeEthTestForkCommon {
    function setUp() public {
        _init();
    }

    function testShouldNotWithdrawFromAssetManagementWeEth() public {
        //given
        _init();

        // when
        vm.expectRevert(bytes(IporErrors.ASSET_NOT_SUPPORTED));
        vm.prank(IporProtocolOwner);
        IAmmGovernanceService(IporProtocolRouterProxy).withdrawFromAssetManagement(weETH, 100 * 1e18);
    }

    function testShouldNotWithdrawAllFromAssetManagementWeEth() public {
        //given
        _init();

        // when
        vm.expectRevert(bytes(IporErrors.ASSET_NOT_SUPPORTED));
        vm.prank(IporProtocolOwner);
        IAmmGovernanceService(IporProtocolRouterProxy).withdrawAllFromAssetManagement(weETH);
    }
}

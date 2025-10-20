// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.26;
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

import "../../contracts/interfaces/IAmmGovernanceService.sol";
import "../../contracts/libraries/errors/IporErrors.sol";
import "./WeEthTestForkCommon.sol";

contract WeEthForkAmmGovernanceServiceTest is WeEthTestForkCommon {
    function setUp() public {
        _init();
    }

    function testShouldNotWithdrawFromAssetManagementWeEth() public {
        //given
        _init();

        // when
        // With BaseV1 architecture, the error is UNSUPPORTED_MODULE_ASSET_MANAGEMENT when ammVault is not configured
        vm.expectRevert(
            abi.encodeWithSelector(
                IporErrors.UnsupportedModule.selector,
                IporErrors.UNSUPPORTED_MODULE_ASSET_MANAGEMENT,
                weETH
            )
        );
        vm.prank(IporProtocolOwner);
        IAmmGovernanceService(IporProtocolRouterProxy).withdrawFromAssetManagement(weETH, 100 * 1e18);
    }

    function testShouldNotWithdrawAllFromAssetManagementWeEth() public {
        //given
        _init();

        // when
        // With BaseV1 architecture, the error is UNSUPPORTED_MODULE_ASSET_MANAGEMENT when ammVault is not configured
        vm.expectRevert(
            abi.encodeWithSelector(
                IporErrors.UnsupportedModule.selector,
                IporErrors.UNSUPPORTED_MODULE_ASSET_MANAGEMENT,
                weETH
            )
        );
        vm.prank(IporProtocolOwner);
        IAmmGovernanceService(IporProtocolRouterProxy).withdrawAllFromAssetManagement(weETH);
    }
}

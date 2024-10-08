// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.26;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

import "../../../contracts/interfaces/IAmmGovernanceService.sol";
import {UsdmTestForkCommonEthereum} from "./UsdmTestForkCommonEthereum.sol";
import "../../../contracts/libraries/errors/IporErrors.sol";

contract UsdmForkAmmGovernanceServiceEthereumTest is UsdmTestForkCommonEthereum {
    function setUp() public {
        _init();
    }

    function testShouldNotWithdrawFromAssetManagementUsdm() public {
        //given

        // when
        vm.expectRevert(
            abi.encodeWithSelector(
                IporErrors.UnsupportedModule.selector,
                IporErrors.UNSUPPORTED_MODULE_ASSET_MANAGEMENT,
                USDM
            ));
        vm.prank(IporProtocolOwner);
        IAmmGovernanceService(IporProtocolRouterProxy).withdrawFromAssetManagement(USDM, 100 * 1e18);
    }

    function testShouldNotWithdrawAllFromAssetManagementUsdm() public {
        //given

        // when
        vm.expectRevert(
            abi.encodeWithSelector(
                IporErrors.UnsupportedModule.selector,
                IporErrors.UNSUPPORTED_MODULE_ASSET_MANAGEMENT,
                USDM
            ));
        vm.prank(IporProtocolOwner);
        IAmmGovernanceService(IporProtocolRouterProxy).withdrawAllFromAssetManagement(USDM);
    }
}

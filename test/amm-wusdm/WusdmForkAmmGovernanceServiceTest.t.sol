// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.20;
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

import "./WusdmTestForkCommon.sol";
import "../../contracts/interfaces/IAmmGovernanceService.sol";
import "../../contracts/interfaces/IAmmGovernanceService.sol";

contract WusdmForkAmmGovernanceServiceTest is WusdmTestForkCommon {
    function setUp() public {
        _init();
    }

    function testShouldNotWithdrawFromAssetManagementUsdm() public {
        //given
        _init();

        // when
        vm.expectRevert(bytes(IporErrors.ASSET_NOT_SUPPORTED));
        vm.prank(IporProtocolOwner);
        IAmmGovernanceService(IporProtocolRouterProxy).withdrawFromAssetManagement(USDM, 100 * 1e18);
    }

    function testShouldNotWithdrawAllFromAssetManagementUsdm() public {
        //given
        _init();

        // when
        vm.expectRevert(bytes(IporErrors.ASSET_NOT_SUPPORTED));
        vm.prank(IporProtocolOwner);
        IAmmGovernanceService(IporProtocolRouterProxy).withdrawAllFromAssetManagement(USDM);
    }
}

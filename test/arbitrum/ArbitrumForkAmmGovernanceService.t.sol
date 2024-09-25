// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.26;
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

import "./ArbitrumTestForkCommons.sol";

contract ArbitrumForkAmmGovernanceServiceTest is ArbitrumTestForkCommons {
    function setUp() public {
        vm.createSelectFork(vm.envString("ARBITRUM_PROVIDER_URL"), 171764768);
    }

    function testShouldNotWithdrawFromAssetManagementWstEth() public {
        //given
        _init();

        // when
        vm.expectRevert(
            abi.encodeWithSelector(
                IporErrors.UnsupportedModule.selector,
                IporErrors.UNSUPPORTED_MODULE_ASSET_MANAGEMENT,
                wstETH
            )
        );
        IAmmGovernanceService(iporProtocolRouterProxy).withdrawFromAssetManagement(wstETH, 100 * 1e18);
    }

    function testShouldNotWithdrawAllFromAssetManagementWstEth() public {
        //given
        _init();

        // when
        vm.expectRevert(
            abi.encodeWithSelector(
                IporErrors.UnsupportedModule.selector,
                IporErrors.UNSUPPORTED_MODULE_ASSET_MANAGEMENT,
                wstETH
            )
        );
        IAmmGovernanceService(iporProtocolRouterProxy).withdrawAllFromAssetManagement(wstETH);
    }
}

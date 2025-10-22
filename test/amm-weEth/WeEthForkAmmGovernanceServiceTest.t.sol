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

    function testShouldNotWithdrawFromAssetManagementWeEthWhenVaultIsEmpty() public {
        //given
        _init();

        // when
        // With asset management enabled, trying to withdraw from empty vault should fail with ERC4626 error
        vm.expectRevert(bytes("ERC4626: withdraw more than max"));
        vm.prank(IporProtocolOwner);
        IAmmGovernanceService(IporProtocolRouterProxy).withdrawFromAssetManagement(weETH, 100 * 1e18);
    }

    function testShouldWithdrawAllFromAssetManagementWeEthWhenVaultIsEmpty() public {
        //given
        _init();

        // when
        // With asset management enabled, withdrawAll from empty vault should succeed (withdrawing 0)
        vm.prank(IporProtocolOwner);
        IAmmGovernanceService(IporProtocolRouterProxy).withdrawAllFromAssetManagement(weETH);

        // then
        // Should not revert, just withdraw 0
        assertEq(IERC20(weETH).balanceOf(plasmaVaultWeEth), 0, "vault balance should still be 0");
    }
}

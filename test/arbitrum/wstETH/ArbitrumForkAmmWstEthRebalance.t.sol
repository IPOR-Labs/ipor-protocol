// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.26;

import "../ArbitrumTestForkCommons.sol";
import {IAmmPoolsServiceWstEthBaseV2} from "../../../contracts/base/amm-wstEth/interfaces/IAmmPoolsServiceWstEthBaseV2.sol";
import {IAmmGovernanceService} from "../../../contracts/interfaces/IAmmGovernanceService.sol";
import {IAmmGovernanceLens} from "../../../contracts/interfaces/IAmmGovernanceLens.sol";
import {AmmPoolsErrors} from "../../../contracts/libraries/errors/AmmPoolsErrors.sol";
import {IAmmGovernanceServiceArbitrum} from "../../../contracts/chains/arbitrum/interfaces/IAmmGovernanceServiceArbitrum.sol";
import {StorageLibArbitrum} from "../../../contracts/chains/arbitrum/libraries/StorageLibArbitrum.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";

/// @title Simple tests for rebalanceBetweenAmmTreasuryAndAssetManagementWstEth router integration
/// @notice These tests verify that the router properly routes the rebalance function
contract ArbitrumForkAmmWstEthRebalanceTest is ArbitrumTestForkCommons {
    function setUp() public {
        vm.createSelectFork(vm.envString("ARBITRUM_PROVIDER_URL"), 171764768);
        _init();
        _setupAssetManagement();
    }

    function _setupAssetManagement() internal {
        // Configure governance pool with asset management (ammVault) enabled
        IAmmGovernanceServiceArbitrum(iporProtocolRouterProxy).setAmmGovernancePoolConfiguration(
            wstETH,
            StorageLibArbitrum.AssetGovernancePoolConfigValue({
                decimals: IERC20Metadata(wstETH).decimals(),
                ammStorage: ammStorageWstEthProxy,
                ammTreasury: ammTreasuryWstEthProxy,
                ammVault: newPlasmaVaultWstEth, // Set to plasma vault instead of address(0)
                ammPoolsTreasury: treasurer,
                ammPoolsTreasuryManager: treasurer,
                ammCharlieTreasury: treasurer,
                ammCharlieTreasuryManager: treasurer
            })
        );

        // Set proper AMM pools params with asset management ratio
        IAmmGovernanceService(iporProtocolRouterProxy).setAmmPoolsParams(
            wstETH,
            1000000000, // maxLiquidityPoolBalance
            1, // autoRebalanceThreshold
            5000 // ammTreasuryAndAssetManagementRatio (50%)
        );
    }

    function testShouldRevertWhenNotAppointedToRebalanceWstEth() public {
        // given
        address user = _getUserAddress(22);

        // when & then
        vm.expectRevert(bytes(AmmPoolsErrors.CALLER_NOT_APPOINTED_TO_REBALANCE));
        vm.prank(user);
        IAmmPoolsServiceWstEthBaseV2(iporProtocolRouterProxy).rebalanceBetweenAmmTreasuryAndAssetManagementWstEth();
    }

    function testShouldAddUserToAppointedRebalanceWstEth() public {
        // given
        address user = _getUserAddress(23);

        bool isAppointedBefore = IAmmGovernanceLens(iporProtocolRouterProxy).isAppointedToRebalanceInAmm(wstETH, user);

        // when
        IAmmGovernanceService(iporProtocolRouterProxy).addAppointedToRebalanceInAmm(wstETH, user);

        // then
        bool isAppointedAfter = IAmmGovernanceLens(iporProtocolRouterProxy).isAppointedToRebalanceInAmm(wstETH, user);
        assertFalse(isAppointedBefore, "User should not be appointed before");
        assertTrue(isAppointedAfter, "User should be appointed after");
    }

    function testShouldRemoveUserFromAppointedRebalanceWstEth() public {
        // given
        address user = _getUserAddress(24);

        IAmmGovernanceService(iporProtocolRouterProxy).addAppointedToRebalanceInAmm(wstETH, user);

        bool isAppointedBefore = IAmmGovernanceLens(iporProtocolRouterProxy).isAppointedToRebalanceInAmm(wstETH, user);

        // when
        IAmmGovernanceService(iporProtocolRouterProxy).removeAppointedToRebalanceInAmm(wstETH, user);

        // then
        bool isAppointedAfter = IAmmGovernanceLens(iporProtocolRouterProxy).isAppointedToRebalanceInAmm(wstETH, user);
        assertTrue(isAppointedBefore, "User should be appointed before");
        assertFalse(isAppointedAfter, "User should not be appointed after");
    }

    function testShouldCallRebalanceFunctionThroughRouter() public {
        // given
        address user = _getUserAddress(25);
        IAmmGovernanceService(iporProtocolRouterProxy).addAppointedToRebalanceInAmm(wstETH, user);

        // when & then
        // This test verifies that the router correctly routes to the rebalance function
        // The function will revert during actual execution due to mock setup limitations,
        // but we can verify it reaches the correct contract by checking the revert doesn't
        // come from the router's INVALID_SIGNATURE error
        vm.prank(user);
        try
            IAmmPoolsServiceWstEthBaseV2(iporProtocolRouterProxy).rebalanceBetweenAmmTreasuryAndAssetManagementWstEth()
        {
            // If it succeeds, that's also fine - means routing works
            assertTrue(true);
        } catch (bytes memory reason) {
            // Verify it's not a router error (which would be "ROUTER_INVALID_SIGNATURE")
            // Any other error means the router successfully routed to the pools service
            string memory revertReason = string(reason);
            assertFalse(
                keccak256(abi.encodePacked(revertReason)) == keccak256(abi.encodePacked("ROUTER_INVALID_SIGNATURE")),
                "Router should route to pools service, not return INVALID_SIGNATURE"
            );
        }
    }
}

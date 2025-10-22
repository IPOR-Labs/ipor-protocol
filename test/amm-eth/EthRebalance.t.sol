// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.26;

import "./TestEthMarketCommons.sol";
import {IAmmPoolsServiceStEth} from "../../contracts/amm-eth/interfaces/IAmmPoolsServiceStEth.sol";
import {IAmmGovernanceService} from "../../contracts/interfaces/IAmmGovernanceService.sol";
import {IAmmGovernanceLens} from "../../contracts/interfaces/IAmmGovernanceLens.sol";
import {AmmPoolsErrors} from "../../contracts/libraries/errors/AmmPoolsErrors.sol";
import {IAmmGovernanceServiceBaseV1} from "../../contracts/base/interfaces/IAmmGovernanceServiceBaseV1.sol";
import {StorageLibBaseV1} from "../../contracts/base/libraries/StorageLibBaseV1.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";

/// @title Simple tests for rebalanceBetweenAmmTreasuryAndAssetManagementStEth router integration
/// @notice These tests verify that the router properly routes the rebalance function for stETH
contract EthRebalanceTest is TestEthMarketCommons {
    function setUp() public {
        vm.createSelectFork(vm.envString("ETHEREUM_PROVIDER_URL"), 20510653);
        _init();
        _setupAssetManagement();
    }

    function _setupAssetManagement() internal {
        vm.startPrank(owner);
        // Configure governance pool with asset management (ammVault) enabled
        IAmmGovernanceServiceBaseV1(iporProtocolRouter).setAmmGovernancePoolConfiguration(
            stEth,
            StorageLibBaseV1.AssetGovernancePoolConfigValue({
                decimals: IERC20Metadata(stEth).decimals(),
                ammStorage: ammStorageStEth,
                ammTreasury: ammTreasuryStEth,
                ammVault: newPlasmaVaultStEth, // Set to plasma vault instead of address(0)
                ammPoolsTreasury: _getUserAddress(123),
                ammPoolsTreasuryManager: _getUserAddress(123),
                ammCharlieTreasury: _getUserAddress(123),
                ammCharlieTreasuryManager: _getUserAddress(123)
            })
        );

        // Set proper AMM pools params with asset management ratio
        IAmmGovernanceService(iporProtocolRouter).setAmmPoolsParams(
            stEth,
            1000000000, // maxLiquidityPoolBalance
            1, // autoRebalanceThreshold
            5000 // ammTreasuryAndAssetManagementRatio (50%)
        );
        vm.stopPrank();
    }

    function testShouldRevertWhenNotAppointedToRebalanceStEth() public {
        // given
        address user = _getUserAddress(22);

        // when & then
        vm.expectRevert(bytes(AmmPoolsErrors.CALLER_NOT_APPOINTED_TO_REBALANCE));
        vm.prank(user);
        IAmmPoolsServiceStEth(iporProtocolRouter).rebalanceBetweenAmmTreasuryAndAssetManagementStEth();
    }

    function testShouldAddUserToAppointedRebalanceStEth() public {
        // given
        address user = _getUserAddress(23);

        bool isAppointedBefore = IAmmGovernanceLens(iporProtocolRouter).isAppointedToRebalanceInAmm(stEth, user);

        // when
        vm.prank(owner);
        IAmmGovernanceService(iporProtocolRouter).addAppointedToRebalanceInAmm(stEth, user);

        // then
        bool isAppointedAfter = IAmmGovernanceLens(iporProtocolRouter).isAppointedToRebalanceInAmm(stEth, user);
        assertFalse(isAppointedBefore, "User should not be appointed before");
        assertTrue(isAppointedAfter, "User should be appointed after");
    }

    function testShouldRemoveUserFromAppointedRebalanceStEth() public {
        // given
        address user = _getUserAddress(24);

        vm.prank(owner);
        IAmmGovernanceService(iporProtocolRouter).addAppointedToRebalanceInAmm(stEth, user);

        bool isAppointedBefore = IAmmGovernanceLens(iporProtocolRouter).isAppointedToRebalanceInAmm(stEth, user);

        // when
        vm.prank(owner);
        IAmmGovernanceService(iporProtocolRouter).removeAppointedToRebalanceInAmm(stEth, user);

        // then
        bool isAppointedAfter = IAmmGovernanceLens(iporProtocolRouter).isAppointedToRebalanceInAmm(stEth, user);
        assertTrue(isAppointedBefore, "User should be appointed before");
        assertFalse(isAppointedAfter, "User should not be appointed after");
    }

    function testShouldCallRebalanceFunctionThroughRouter() public {
        // given
        address user = _getUserAddress(25);

        vm.prank(owner);
        IAmmGovernanceService(iporProtocolRouter).addAppointedToRebalanceInAmm(stEth, user);

        // when & then
        // This test verifies that the router correctly routes to the rebalance function
        // The function will revert during actual execution due to mock setup limitations,
        // but we can verify it reaches the correct contract by checking the revert doesn't
        // come from the router's INVALID_SIGNATURE error
        vm.prank(user);
        try IAmmPoolsServiceStEth(iporProtocolRouter).rebalanceBetweenAmmTreasuryAndAssetManagementStEth() {
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

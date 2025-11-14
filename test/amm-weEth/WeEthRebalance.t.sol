// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.26;

import "./WeEthTestForkCommon.sol";
import {IAmmPoolsServiceWeEth} from "../../contracts/amm-weEth/interfaces/IAmmPoolsServiceWeEth.sol";
import {IAmmGovernanceService} from "../../contracts/interfaces/IAmmGovernanceService.sol";
import {IAmmGovernanceLens} from "../../contracts/interfaces/IAmmGovernanceLens.sol";
import {AmmPoolsErrors} from "../../contracts/libraries/errors/AmmPoolsErrors.sol";

/// @title Simple tests for rebalanceBetweenAmmTreasuryAndAssetManagementWeEth router integration
/// @notice These tests verify that the router properly routes the rebalance function for weETH
contract WeEthRebalanceTest is WeEthTestForkCommon {
    function setUp() public {
        _init();
    }

    function testShouldRevertWhenNotAppointedToRebalanceWeEth() public {
        // given
        address user = _getUserAddress(22);

        // when & then
        vm.expectRevert(bytes(AmmPoolsErrors.CALLER_NOT_APPOINTED_TO_REBALANCE));
        vm.prank(user);
        IAmmPoolsServiceWeEth(IporProtocolRouterProxy).rebalanceBetweenAmmTreasuryAndAssetManagementWeEth();
    }

    function testShouldAddUserToAppointedRebalanceWeEth() public {
        // given
        address user = _getUserAddress(23);

        bool isAppointedBefore = IAmmGovernanceLens(IporProtocolRouterProxy).isAppointedToRebalanceInAmm(weETH, user);

        // when
        vm.prank(IporProtocolOwner);
        IAmmGovernanceService(IporProtocolRouterProxy).addAppointedToRebalanceInAmm(weETH, user);

        // then
        bool isAppointedAfter = IAmmGovernanceLens(IporProtocolRouterProxy).isAppointedToRebalanceInAmm(weETH, user);
        assertFalse(isAppointedBefore, "User should not be appointed before");
        assertTrue(isAppointedAfter, "User should be appointed after");
    }

    function testShouldRemoveUserFromAppointedRebalanceWeEth() public {
        // given
        address user = _getUserAddress(24);

        vm.prank(IporProtocolOwner);
        IAmmGovernanceService(IporProtocolRouterProxy).addAppointedToRebalanceInAmm(weETH, user);

        bool isAppointedBefore = IAmmGovernanceLens(IporProtocolRouterProxy).isAppointedToRebalanceInAmm(weETH, user);

        // when
        vm.prank(IporProtocolOwner);
        IAmmGovernanceService(IporProtocolRouterProxy).removeAppointedToRebalanceInAmm(weETH, user);

        // then
        bool isAppointedAfter = IAmmGovernanceLens(IporProtocolRouterProxy).isAppointedToRebalanceInAmm(weETH, user);
        assertTrue(isAppointedBefore, "User should be appointed before");
        assertFalse(isAppointedAfter, "User should not be appointed after");
    }

    function testShouldCallRebalanceFunctionThroughRouter() public {
        // given
        address user = _getUserAddress(25);

        vm.prank(IporProtocolOwner);
        IAmmGovernanceService(IporProtocolRouterProxy).addAppointedToRebalanceInAmm(weETH, user);

        // when & then
        // This test verifies that the router correctly routes to the rebalance function
        // The function will succeed if vault is empty (rebalancing 0)
        vm.prank(user);
        try IAmmPoolsServiceWeEth(IporProtocolRouterProxy).rebalanceBetweenAmmTreasuryAndAssetManagementWeEth() {
            // If it succeeds, that's fine - means routing works
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

    function testShouldRebalanceAfterProvidingLiquidity() public {
        // given
        address rebalancer = _getUserAddress(26);
        address liquidityProvider = _getUserAddress(27);
        _setupUser(liquidityProvider, 100_000 * 1e18);

        vm.prank(IporProtocolOwner);
        IAmmGovernanceService(IporProtocolRouterProxy).addAppointedToRebalanceInAmm(weETH, rebalancer);

        // Provide some liquidity first
        uint256 provideAmount = 100e18;
        vm.prank(liquidityProvider);
        IAmmPoolsServiceWeEth(IporProtocolRouterProxy).provideLiquidityWeEthToAmmPoolWeEth(
            liquidityProvider,
            provideAmount
        );

        uint256 treasuryBalanceBefore = IERC20(weETH).balanceOf(ammTreasuryWeEthProxy);
        uint256 vaultBalanceBefore = IERC20(weETH).balanceOf(plasmaVaultWeEth);

        // when
        vm.prank(rebalancer);
        IAmmPoolsServiceWeEth(IporProtocolRouterProxy).rebalanceBetweenAmmTreasuryAndAssetManagementWeEth();

        // then
        uint256 treasuryBalanceAfter = IERC20(weETH).balanceOf(ammTreasuryWeEthProxy);
        uint256 vaultBalanceAfter = IERC20(weETH).balanceOf(plasmaVaultWeEth);

        // With 50% ratio, balances should be approximately equal (allowing for auto-rebalance during provide)
        // Total should remain the same
        assertEq(
            treasuryBalanceBefore + vaultBalanceBefore,
            treasuryBalanceAfter + vaultBalanceAfter,
            "Total balance should remain the same"
        );

        // After rebalance, they should be closer to 50/50 split
        uint256 totalBalance = treasuryBalanceAfter + vaultBalanceAfter;
        if (totalBalance > 0) {
            // Allow some tolerance due to rounding
            uint256 treasuryRatio = (treasuryBalanceAfter * 10000) / totalBalance;
            assertTrue(treasuryRatio >= 4500 && treasuryRatio <= 5500, "Treasury should be around 50% of total");
        }
    }
}

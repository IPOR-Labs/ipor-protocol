// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.26;

import "forge-std/Test.sol";
import "../mocks/assetManagement/MockAssetManagementLogic.sol";

contract UnitAssetManagementLogic is Test {
    MockAssetManagementLogic internal _assetManagementLogic;

    function setUp() public {
        _assetManagementLogic = new MockAssetManagementLogic();
    }

    function testShouldCalculateRebalanceAmountAfterProvideLiquidityWhenRation100Percentage() public {
        uint256 wadAmmTreasuryErc20BalanceAfterDeposit = 100_000 * 1e18;
        uint256 vaultBalance = 5_000_000 * 1e18;
        uint256 wadAmmTreasuryAndAssetManagementRatio = 9999 * 1e14;

        int256 rebalanceAmount = _assetManagementLogic.calculateRebalanceAmountAfterProvideLiquidity(
            wadAmmTreasuryErc20BalanceAfterDeposit,
            vaultBalance,
            wadAmmTreasuryAndAssetManagementRatio
        );

        assertEq(rebalanceAmount, -4999490000000000000000000);
    }

    function testShouldCalculateRebalanceAmountAfterProvideLiquidityWhenRation50Percentage() public {
        uint256 wadAmmTreasuryErc20BalanceAfterDeposit = 100_000 * 1e18;
        uint256 vaultBalance = 5_000_000 * 1e18;
        uint256 wadAmmTreasuryAndAssetManagementRatio = 5000 * 1e14;

        int256 rebalanceAmount = _assetManagementLogic.calculateRebalanceAmountAfterProvideLiquidity(
            wadAmmTreasuryErc20BalanceAfterDeposit,
            vaultBalance,
            wadAmmTreasuryAndAssetManagementRatio
        );

        assertEq(rebalanceAmount, -2450000000000000000000000);
    }

    function testShouldNotCalculateRebalanceAmountAfterProvideLiquidityWhenRation0Percentage() public {
        uint256 wadAmmTreasuryErc20BalanceAfterDeposit = 100_000 * 1e18;
        uint256 vaultBalance = 5_000_000 * 1e18;
        uint256 wadAmmTreasuryAndAssetManagementRatio = 0;

        int256 rebalanceAmount = _assetManagementLogic.calculateRebalanceAmountAfterProvideLiquidity(
            wadAmmTreasuryErc20BalanceAfterDeposit,
            vaultBalance,
            wadAmmTreasuryAndAssetManagementRatio
        );

        assertEq(rebalanceAmount, 0);
    }

    function testShouldCalculateRebalanceAmountBeforeWithdrawWhenRation100Percentage() public {
        uint256 wadAmmErc20BalanceBeforeWithdraw = 100_000 * 1e18;
        uint256 vaultBalance = 5_000_000 * 1e18;
        uint256 wadOperationAmount = 10_000 * 1e18;
        uint256 wadAmmTreasuryAndAssetManagementRatioCfg = 9999 * 1e14;

        int256 rebalanceAmount = _assetManagementLogic.calculateRebalanceAmountBeforeWithdraw(
            wadAmmErc20BalanceBeforeWithdraw,
            vaultBalance,
            wadOperationAmount,
            wadAmmTreasuryAndAssetManagementRatioCfg
        );

        assertEq(rebalanceAmount, -4999491000000000000000000);
    }

    function testShouldCalculateRebalanceAmountBeforeWithdrawWhenRation50Percentage() public {
        uint256 wadAmmErc20BalanceBeforeWithdraw = 100_000 * 1e18;
        uint256 vaultBalance = 5_000_000 * 1e18;
        uint256 wadOperationAmount = 10_000 * 1e18;
        uint256 wadAmmTreasuryAndAssetManagementRatioCfg = 5000 * 1e14;

        int256 rebalanceAmount = _assetManagementLogic.calculateRebalanceAmountBeforeWithdraw(
            wadAmmErc20BalanceBeforeWithdraw,
            vaultBalance,
            wadOperationAmount,
            wadAmmTreasuryAndAssetManagementRatioCfg
        );

        assertEq(rebalanceAmount, -2455000000000000000000000);
    }

    function testShouldNotCalculateRebalanceAmountBeforeWithdrawWhenRation0Percentage() public {
        uint256 wadAmmErc20BalanceBeforeWithdraw = 100_000 * 1e18;
        uint256 vaultBalance = 5_000_000 * 1e18;
        uint256 wadOperationAmount = 10_000 * 1e18;
        uint256 wadAmmTreasuryAndAssetManagementRatioCfg = 0;

        int256 rebalanceAmount = _assetManagementLogic.calculateRebalanceAmountBeforeWithdraw(
            wadAmmErc20BalanceBeforeWithdraw,
            vaultBalance,
            wadOperationAmount,
            wadAmmTreasuryAndAssetManagementRatioCfg
        );

        assertEq(rebalanceAmount, 0);
    }
}

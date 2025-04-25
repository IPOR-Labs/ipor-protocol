// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.26;

import {IAmmPoolsServiceWstEthBaseV1} from "./IAmmPoolsServiceWstEthBaseV1.sol";

/// @title Interface of the AmmPoolsServiceWstEth contract V2.
interface IAmmPoolsServiceWstEthBaseV2 is IAmmPoolsServiceWstEthBaseV1 {
    /// @notice Rebalances wstETH assets between the AmmTreasury and the AssetManagement, based on configuration stored
    /// in the `AmmPoolsParamsValue.ammTreasuryAndAssetManagementRatio` field.
    /// @dev Emits {Deposit} or {Withdraw} event from AssetManagement depends on current asset balance on AmmTreasury and AssetManagement.
    /// @dev Emits {Transfer} from ERC20 asset.
    function rebalanceBetweenAmmTreasuryAndAssetManagementWstEth() external;
}

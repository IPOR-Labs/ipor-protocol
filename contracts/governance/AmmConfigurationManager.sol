// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.20;

import "../libraries/errors/IporErrors.sol";
import "../libraries/errors/AmmPoolsErrors.sol";
import "../libraries/StorageLib.sol";

/// @title Configuration manager for AMM
library AmmConfigurationManager {
    /// @notice Emitted when new liquidator is added to the list of SwapLiquidators.
    /// @param asset address of the asset (pool)
    /// @param liquidator address of the new liquidator
    event AmmSwapsLiquidatorChanged(address indexed asset, address indexed liquidator, bool status);

    /// @notice Emitted when new account is added to the list of AppointedToRebalance.
    /// @param asset address of the asset (pool)
    /// @param account address of account appointed to rebalance
    /// @param status true if account is appointed to rebalance, false otherwise
    event AmmAppointedToRebalanceChanged(address indexed asset, address indexed account, bool status);

    /// @notice Emitted when AMM Pools Params are changed.
    /// @param asset address of the asset (pool)
    /// @param maxLiquidityPoolBalance maximum liquidity pool balance
    /// @param autoRebalanceThresholdInThousands auto rebalance threshold in thousands
    /// @param ammTreasuryAndAssetManagementRatio AMM treasury and asset management ratio
    event AmmPoolsParamsChanged(
        address indexed asset,
        uint32 maxLiquidityPoolBalance,
        uint32 autoRebalanceThresholdInThousands,
        uint16 ammTreasuryAndAssetManagementRatio
    );

    /// @notice Adds new liquidator to the list of SwapLiquidators.
    /// @param asset address of the asset (pool)
    /// @param account address of the new liquidator
    /// @dev Allowed only for the owner of the Ipor Protocol Router
    function addSwapLiquidator(address asset, address account) internal {
        require(account != address(0), IporErrors.WRONG_ADDRESS);
        require(asset != address(0), IporErrors.WRONG_ADDRESS);

        mapping(address => mapping(address => bool)) storage swapLiquidators = StorageLib
            .getAmmSwapsLiquidatorsStorage()
            .value;
        swapLiquidators[asset][account] = true;

        emit AmmSwapsLiquidatorChanged(asset, account, true);
    }

    /// @notice Removes liquidator from the list of SwapLiquidators.
    /// @param asset address of the asset (pool)
    /// @param account address of the liquidator
    /// @dev Allowed only for the owner of the Ipor Protocol Router
    function removeSwapLiquidator(address asset, address account) internal {
        require(account != address(0), IporErrors.WRONG_ADDRESS);
        require(asset != address(0), IporErrors.WRONG_ADDRESS);

        mapping(address => mapping(address => bool)) storage swapLiquidators = StorageLib
            .getAmmSwapsLiquidatorsStorage()
            .value;
        swapLiquidators[asset][account] = false;

        emit AmmSwapsLiquidatorChanged(asset, account, false);
    }

    /// @notice Checks if account is a SwapLiquidator.
    /// @param asset address of the asset (pool)
    /// @param account address of the account
    /// @return true if account is a SwapLiquidator, false otherwise
    function isSwapLiquidator(address asset, address account) internal view returns (bool) {
        mapping(address => mapping(address => bool)) storage swapLiquidators = StorageLib
            .getAmmSwapsLiquidatorsStorage()
            .value;
        return swapLiquidators[asset][account];
    }

    /// @notice Adds new account to the list of AppointedToRebalance in AMM.
    /// @param asset address of the asset (pool)
    /// @param account address added to appointed to rebalance
    /// @dev Allowed only for the owner of the Ipor Protocol Router
    function addAppointedToRebalanceInAmm(address asset, address account) internal {
        require(asset != address(0), IporErrors.WRONG_ADDRESS);
        require(account != address(0), IporErrors.WRONG_ADDRESS);

        mapping(address => mapping(address => bool)) storage appointedToRebalance = StorageLib
            .getAmmPoolsAppointedToRebalanceStorage()
            .value;
        appointedToRebalance[asset][account] = true;

        emit AmmAppointedToRebalanceChanged(asset, account, true);
    }

    /// @notice Removes account from the list of AppointedToRebalance in AMM.
    /// @param asset address of the asset (pool)
    /// @param account address removed from appointed to rebalance
    /// @dev Allowed only for the owner of the Ipor Protocol Router
    function removeAppointedToRebalanceInAmm(address asset, address account) internal {
        require(asset != address(0), IporErrors.WRONG_ADDRESS);
        require(account != address(0), IporErrors.WRONG_ADDRESS);

        mapping(address => mapping(address => bool)) storage appointedToRebalance = StorageLib
            .getAmmPoolsAppointedToRebalanceStorage()
            .value;
        appointedToRebalance[asset][account] = false;

        emit AmmAppointedToRebalanceChanged(asset, account, false);
    }

    /// @notice Checks if account is appointed to rebalance in AMM.
    /// @param asset address of the asset (pool)
    /// @param account address of the account
    /// @return true if account is appointed to rebalance, false otherwise
    function isAppointedToRebalanceInAmm(address asset, address account) internal view returns (bool) {
        mapping(address => mapping(address => bool)) storage appointedToRebalance = StorageLib
            .getAmmPoolsAppointedToRebalanceStorage()
            .value;
        return appointedToRebalance[asset][account];
    }

    /// @notice Sets AMM Pools Params.
    /// @param asset address of the asset (pool)
    /// @param newMaxLiquidityPoolBalance maximum liquidity pool balance
    /// @param newAutoRebalanceThresholdInThousands auto rebalance threshold in thousands
    /// @param newAmmTreasuryAndAssetManagementRatio AMM treasury and asset management ratio
    /// @dev Allowed only for the owner of the Ipor Protocol Router
    function setAmmPoolsParams(
        address asset,
        uint32 newMaxLiquidityPoolBalance,
        uint32 newAutoRebalanceThresholdInThousands,
        uint16 newAmmTreasuryAndAssetManagementRatio
    ) internal {
        require(asset != address(0), IporErrors.WRONG_ADDRESS);
        /// @dev newAmmTreasuryAndAssetManagementRatio is percentage with 2 decimals, example: 65% = 6500, (see description in StorageLib.AmmPoolsParamsValue)
        /// value cannot be greater than 10000 which is 100%
        require(newAmmTreasuryAndAssetManagementRatio < 1e4, AmmPoolsErrors.AMM_TREASURY_ASSET_MANAGEMENT_RATIO);

        StorageLib.getAmmPoolsParamsStorage().value[asset] = StorageLib.AmmPoolsParamsValue({
            maxLiquidityPoolBalance: newMaxLiquidityPoolBalance,
            autoRebalanceThresholdInThousands: newAutoRebalanceThresholdInThousands,
            ammTreasuryAndAssetManagementRatio: newAmmTreasuryAndAssetManagementRatio
        });

        emit AmmPoolsParamsChanged(
            asset,
            newMaxLiquidityPoolBalance,
            newAutoRebalanceThresholdInThousands,
            newAmmTreasuryAndAssetManagementRatio
        );
    }

    /// @notice Gets AMM Pools Params.
    /// @param asset address of the asset (pool)
    /// @return AMM Pools Params struct
    function getAmmPoolsParams(address asset) internal view returns (StorageLib.AmmPoolsParamsValue memory) {
        return StorageLib.getAmmPoolsParamsStorage().value[asset];
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.16;

import "../libraries/Constants.sol";
import "../libraries/errors/IporErrors.sol";
import "../libraries/errors/AmmPoolsErrors.sol";
import "../libraries/StorageLib.sol";

library AmmConfigurationManager {
    /// @notice Emitted when new liquidator is added to the list of SwapLiquidators.
    /// @param asset address of the asset (pool)
    /// @param liquidator address of the new liquidator
    event AmmSwapsLiquidatorChanged(
        address indexed changedBy,
        address indexed asset,
        address indexed liquidator,
        bool status
    );

    /// @notice Emitted when new ratio AMM vs Asset Management is set for asset.
    /// @param changedBy account address that changed ratio
    /// @param asset address of the asset
    /// @param oldRatio old ratio, describe what percentage of asset should be managed by AMM against Asset Management.
    /// @param newRatio new ratio, describe what percentage of asset should be managed by AMM against Asset Management.
    event AmmAndAssetManagementRatioChanged(
        address indexed changedBy,
        address indexed asset,
        uint256 oldRatio,
        uint256 newRatio
    );

    /// @notice Emitted after the max liquidity pool balance has changed
    /// @param changedBy account address that changed max liquidity pool balance
    /// @param asset address of the asset
    /// @param oldMaxLiquidityPoolBalance Old max liquidity pool balance, represented in 18 decimals
    /// @param newMaxLiquidityPoolBalance New max liquidity pool balance, represented in 18 decimals
    event AmmMaxLiquidityPoolBalanceChanged(
        address indexed changedBy,
        address indexed asset,
        uint256 oldMaxLiquidityPoolBalance,
        uint256 newMaxLiquidityPoolBalance
    );

    /// @notice Emitted after the max lp account contribution has changed
    /// @param changedBy account address that changed max lp account contribution
    /// @param asset address of the asset
    /// @param oldMaxLpAccountContribution Old max lp account contribution, represented in 18 decimals
    /// @param newMaxLpAccountContribution New max lp account contribution, represented in 18 decimals
    event AmmMaxLpAccountContributionChanged(
        address indexed changedBy,
        address indexed asset,
        uint256 oldMaxLpAccountContribution,
        uint256 newMaxLpAccountContribution
    );

    event AmmAppointedToRebalanceChanged(
        address indexed changedBy,
        address indexed asset,
        address indexed account,
        bool status
    );

    event AmmAutoRebalanceThresholdChanged(
        address indexed changedBy,
        address indexed asset,
        uint256 oldAutoRebalanceThreshold,
        uint256 newAutoRebalanceThreshold
    );

    function addSwapLiquidator(address asset, address account) internal {
        require(account != address(0), IporErrors.WRONG_ADDRESS);
        require(asset != address(0), IporErrors.WRONG_ADDRESS);

        mapping(address => mapping(address => bool)) storage swapLiquidators = StorageLib
            .getAmmSwapsLiquidatorsStorage()
            .value;
        swapLiquidators[asset][account] = true;

        emit AmmSwapsLiquidatorChanged(msg.sender, asset, account, true);
    }

    function removeSwapLiquidator(address asset, address account) internal {
        require(account != address(0), IporErrors.WRONG_ADDRESS);
        require(asset != address(0), IporErrors.WRONG_ADDRESS);

        mapping(address => mapping(address => bool)) storage swapLiquidators = StorageLib
            .getAmmSwapsLiquidatorsStorage()
            .value;
        swapLiquidators[asset][account] = false;

        emit AmmSwapsLiquidatorChanged(msg.sender, asset, account, false);
    }

    function isSwapLiquidator(address asset, address account) internal view returns (bool) {
        mapping(address => mapping(address => bool)) storage swapLiquidators = StorageLib
            .getAmmSwapsLiquidatorsStorage()
            .value;
        return swapLiquidators[asset][account];
    }

    /// @dev key - asset address, value - ratio
    function setAmmAndAssetManagementRatio(address asset, uint256 newRatio) internal {
        require(asset != address(0), IporErrors.WRONG_ADDRESS);
        require(newRatio > 0, AmmPoolsErrors.AMM_TREASURY_ASSET_MANAGEMENT_RATIO);
        require(newRatio < 1e18, AmmPoolsErrors.AMM_TREASURY_ASSET_MANAGEMENT_RATIO);

        mapping(address => uint256) storage ratio = StorageLib.getAmmAndAssetManagementRatioStorage().value;
        uint256 oldRatio = ratio[asset];
        ratio[asset] = newRatio;

        emit AmmAndAssetManagementRatioChanged(msg.sender, asset, oldRatio, newRatio);
    }

    function getAmmAndAssetManagementRatio(address asset) internal view returns (uint256) {
        mapping(address => uint256) storage ratio = StorageLib.getAmmAndAssetManagementRatioStorage().value;
        return ratio[asset];
    }

    /// @param asset address of the asset
    /// @param newMaxLiquidityPoolBalance new max liquidity pool balance, represented WITHOUT 18 decimals
    function setAmmMaxLiquidityPoolBalance(address asset, uint256 newMaxLiquidityPoolBalance) internal {
        require(asset != address(0), IporErrors.WRONG_ADDRESS);

        mapping(address => uint256) storage maxLiquidityPoolBalance = StorageLib
            .getAmmMaxLiquidityPoolBalanceStorage()
            .value;
        uint256 oldMaxLiquidityPoolBalance = maxLiquidityPoolBalance[asset];
        maxLiquidityPoolBalance[asset] = newMaxLiquidityPoolBalance;

        emit AmmMaxLiquidityPoolBalanceChanged(
            msg.sender,
            asset,
            oldMaxLiquidityPoolBalance * Constants.D18,
            newMaxLiquidityPoolBalance * Constants.D18
        );
    }

    /// @param asset address of the asset
    /// @return max liquidity pool balance, represented WITHOUT 18 decimals
    function getAmmMaxLiquidityPoolBalance(address asset) internal view returns (uint256) {
        mapping(address => uint256) storage maxLiquidityPoolBalance = StorageLib
            .getAmmMaxLiquidityPoolBalanceStorage()
            .value;
        return maxLiquidityPoolBalance[asset];
    }

    /// @param asset address of the asset
    /// @param newMaxLpAccountContribution new max lp account contribution, represented WITHOUT 18 decimals
    function setAmmMaxLpAccountContribution(address asset, uint256 newMaxLpAccountContribution) internal {
        require(asset != address(0), IporErrors.WRONG_ADDRESS);

        mapping(address => uint256) storage maxLpAccountContribution = StorageLib
            .getAmmMaxLpAccountContributionStorage()
            .value;
        uint256 oldMaxLpAccountContribution = maxLpAccountContribution[asset];
        maxLpAccountContribution[asset] = newMaxLpAccountContribution;

        emit AmmMaxLpAccountContributionChanged(
            msg.sender,
            asset,
            oldMaxLpAccountContribution * Constants.D18,
            newMaxLpAccountContribution * Constants.D18
        );
    }

    /// @param asset address of the asset
    /// @return max lp account contribution, represented WITHOUT 18 decimals
    function getAmmMaxLpAccountContribution(address asset) internal view returns (uint256) {
        mapping(address => uint256) storage maxLpAccountContribution = StorageLib
            .getAmmMaxLpAccountContributionStorage()
            .value;
        return maxLpAccountContribution[asset];
    }

    function addAppointedToRebalanceInAmm(address asset, address account) internal {
        require(asset != address(0), IporErrors.WRONG_ADDRESS);
        require(account != address(0), IporErrors.WRONG_ADDRESS);

        mapping(address => mapping(address => bool)) storage appointedToRebalance = StorageLib
            .getAmmPoolsAppointedToRebalanceStorage()
            .value;
        appointedToRebalance[asset][account] = true;

        emit AmmAppointedToRebalanceChanged(msg.sender, asset, account, true);
    }

    function removeAppointedToRebalanceInAmm(address asset, address account) internal {
        require(asset != address(0), IporErrors.WRONG_ADDRESS);
        require(account != address(0), IporErrors.WRONG_ADDRESS);

        mapping(address => mapping(address => bool)) storage appointedToRebalance = StorageLib
            .getAmmPoolsAppointedToRebalanceStorage()
            .value;
        appointedToRebalance[asset][account] = false;

        emit AmmAppointedToRebalanceChanged(msg.sender, asset, account, false);
    }

    function isAppointedToRebalanceInAmm(address asset, address account) internal view returns (bool) {
        mapping(address => mapping(address => bool)) storage appointedToRebalance = StorageLib
            .getAmmPoolsAppointedToRebalanceStorage()
            .value;
        return appointedToRebalance[asset][account];
    }

    function setAmmAutoRebalanceThreshold(address asset, uint256 newAutoRebalanceThreshold) internal {
        require(asset != address(0), IporErrors.WRONG_ADDRESS);

        mapping(address => uint256) storage autoRebalanceThreshold = StorageLib
            .getAmmAutoRebalanceThresholdStorage()
            .value;
        uint256 oldAutoRebalanceThreshold = autoRebalanceThreshold[asset];
        autoRebalanceThreshold[asset] = newAutoRebalanceThreshold;

        emit AmmAutoRebalanceThresholdChanged(
            msg.sender,
            asset,
            oldAutoRebalanceThreshold * Constants.D18,
            newAutoRebalanceThreshold * Constants.D18
        );
    }

    function getAmmAutoRebalanceThreshold(address asset) internal view returns (uint256) {
        mapping(address => uint256) storage autoRebalanceThreshold = StorageLib
            .getAmmAutoRebalanceThresholdStorage()
            .value;
        return autoRebalanceThreshold[asset];
    }
}

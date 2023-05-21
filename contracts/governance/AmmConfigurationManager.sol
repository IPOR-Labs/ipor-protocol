// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.16;

import "../libraries/Constants.sol";
import "../libraries/errors/IporErrors.sol";
import "../libraries/errors/JosephErrors.sol";
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
    event AmmPoolsAndAssetManagementRatioChanged(
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
    event AmmPoolsMaxLiquidityPoolBalanceChanged(
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
    event AmmPoolsMaxLpAccountContributionChanged(
        address indexed changedBy,
        address indexed asset,
        uint256 oldMaxLpAccountContribution,
        uint256 newMaxLpAccountContribution
    );

    event AmmPoolsAppointedToRebalanceChanged(
        address indexed changedBy,
        address indexed asset,
        address indexed account,
        bool status
    );

    event AmmPoolsTreasuryChanged(
        address indexed changedBy,
        address indexed asset,
        address indexed oldTreasury,
        address newTreasury
    );

    event AmmPoolsTreasuryManagerChanged(
        address indexed changedBy,
        address indexed asset,
        address indexed oldTreasuryManager,
        address newTreasuryManager
    );

    event AmmPoolsCharlieTreasuryChanged(
        address indexed changedBy,
        address indexed asset,
        address indexed oldCharlieTreasury,
        address newCharlieTreasury
    );

    event AmmPoolsCharlieTreasuryManagerChanged(
        address indexed changedBy,
        address indexed asset,
        address indexed oldCharlieTreasuryManager,
        address newCharlieTreasuryManager
    );

    event AmmPoolsAutoRebalanceThresholdChanged(
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
    function setAmmPoolsAndAssetManagementRatio(address asset, uint256 newRatio) internal {
        require(asset != address(0), IporErrors.WRONG_ADDRESS);
        require(newRatio > 0, JosephErrors.MILTON_STANLEY_RATIO);
        require(newRatio < 1e18, JosephErrors.MILTON_STANLEY_RATIO);

        mapping(address => uint256) storage ratio = StorageLib.getAmmPoolsAndAssetManagementRatioStorage().value;
        uint256 oldRatio = ratio[asset];
        ratio[asset] = newRatio;

        emit AmmPoolsAndAssetManagementRatioChanged(msg.sender, asset, oldRatio, newRatio);
    }

    function getAmmPoolsAndAssetManagementRatio(address asset) internal view returns (uint256) {
        mapping(address => uint256) storage ratio = StorageLib.getAmmPoolsAndAssetManagementRatioStorage().value;
        return ratio[asset];
    }

    /// @param asset address of the asset
    /// @param newMaxLiquidityPoolBalance new max liquidity pool balance, represented WITHOUT 18 decimals
    function setAmmPoolsMaxLiquidityPoolBalance(address asset, uint256 newMaxLiquidityPoolBalance) internal {
        require(asset != address(0), IporErrors.WRONG_ADDRESS);

        mapping(address => uint256) storage maxLiquidityPoolBalance = StorageLib
            .getAmmPoolsMaxLiquidityPoolBalanceStorage()
            .value;
        uint256 oldMaxLiquidityPoolBalance = maxLiquidityPoolBalance[asset];
        maxLiquidityPoolBalance[asset] = newMaxLiquidityPoolBalance;

        emit AmmPoolsMaxLiquidityPoolBalanceChanged(
            msg.sender,
            asset,
            oldMaxLiquidityPoolBalance * Constants.D18,
            newMaxLiquidityPoolBalance * Constants.D18
        );
    }

    /// @param asset address of the asset
    /// @return max liquidity pool balance, represented WITHOUT 18 decimals
    function getAmmPoolsMaxLiquidityPoolBalance(address asset) internal view returns (uint256) {
        mapping(address => uint256) storage maxLiquidityPoolBalance = StorageLib
            .getAmmPoolsMaxLiquidityPoolBalanceStorage()
            .value;
        return maxLiquidityPoolBalance[asset];
    }

    /// @param asset address of the asset
    /// @param newMaxLpAccountContribution new max lp account contribution, represented WITHOUT 18 decimals
    function setAmmPoolsMaxLpAccountContribution(address asset, uint256 newMaxLpAccountContribution) internal {
        require(asset != address(0), IporErrors.WRONG_ADDRESS);

        mapping(address => uint256) storage maxLpAccountContribution = StorageLib
            .getAmmPoolsMaxLpAccountContributionStorage()
            .value;
        uint256 oldMaxLpAccountContribution = maxLpAccountContribution[asset];
        maxLpAccountContribution[asset] = newMaxLpAccountContribution;

        emit AmmPoolsMaxLpAccountContributionChanged(
            msg.sender,
            asset,
            oldMaxLpAccountContribution * Constants.D18,
            newMaxLpAccountContribution * Constants.D18
        );
    }

    /// @param asset address of the asset
    /// @return max lp account contribution, represented WITHOUT 18 decimals
    function getAmmPoolsMaxLpAccountContribution(address asset) internal view returns (uint256) {
        mapping(address => uint256) storage maxLpAccountContribution = StorageLib
            .getAmmPoolsMaxLpAccountContributionStorage()
            .value;
        return maxLpAccountContribution[asset];
    }

    function addAmmPoolsAppointedToRebalance(address asset, address account) internal {
        require(asset != address(0), IporErrors.WRONG_ADDRESS);
        require(account != address(0), IporErrors.WRONG_ADDRESS);

        mapping(address => mapping(address => bool)) storage appointedToRebalance = StorageLib
            .getAmmPoolsAppointedToRebalanceStorage()
            .value;
        appointedToRebalance[asset][account] = true;

        emit AmmPoolsAppointedToRebalanceChanged(msg.sender, asset, account, true);
    }

    function removeAmmPoolsAppointedToRebalance(address asset, address account) internal {
        require(asset != address(0), IporErrors.WRONG_ADDRESS);
        require(account != address(0), IporErrors.WRONG_ADDRESS);

        mapping(address => mapping(address => bool)) storage appointedToRebalance = StorageLib
            .getAmmPoolsAppointedToRebalanceStorage()
            .value;
        appointedToRebalance[asset][account] = false;

        emit AmmPoolsAppointedToRebalanceChanged(msg.sender, asset, account, false);
    }

    function isAmmPoolsAppointedToRebalance(address asset, address account) internal view returns (bool) {
        mapping(address => mapping(address => bool)) storage appointedToRebalance = StorageLib
            .getAmmPoolsAppointedToRebalanceStorage()
            .value;
        return appointedToRebalance[asset][account];
    }

    function setAmmPoolsTreasury(address asset, address treasuryWalletAddress) internal {
        require(asset != address(0), IporErrors.WRONG_ADDRESS);
        require(treasuryWalletAddress != address(0), IporErrors.WRONG_ADDRESS);

        mapping(address => address) storage treasury = StorageLib.getAmmPoolsTreasuryStorage().value;
        address oldTreasury = treasury[asset];
        treasury[asset] = treasuryWalletAddress;

        emit AmmPoolsTreasuryChanged(msg.sender, asset, oldTreasury, treasuryWalletAddress);
    }

    function getAmmPoolsTreasury(address asset) internal view returns (address) {
        mapping(address => address) storage treasury = StorageLib.getAmmPoolsTreasuryStorage().value;
        return treasury[asset];
    }

    function setAmmPoolsTreasuryManager(address asset, address treasuryManagerAddress) internal {
        require(asset != address(0), IporErrors.WRONG_ADDRESS);
        require(treasuryManagerAddress != address(0), IporErrors.WRONG_ADDRESS);

        mapping(address => address) storage treasuryManager = StorageLib.getAmmPoolsTreasuryManagerStorage().value;
        address oldTreasuryManager = treasuryManager[asset];
        treasuryManager[asset] = treasuryManagerAddress;

        emit AmmPoolsTreasuryManagerChanged(msg.sender, asset, oldTreasuryManager, treasuryManagerAddress);
    }

    function getAmmPoolsTreasuryManager(address asset) internal view returns (address) {
        mapping(address => address) storage treasuryManager = StorageLib.getAmmPoolsTreasuryManagerStorage().value;
        return treasuryManager[asset];
    }

    function setAmmPoolsCharlieTreasury(address asset, address charlieTreasuryAddress) internal {
        require(asset != address(0), IporErrors.WRONG_ADDRESS);
        require(charlieTreasuryAddress != address(0), IporErrors.WRONG_ADDRESS);

        mapping(address => address) storage charlieTreasury = StorageLib.getAmmPoolsCharlieTreasuryStorage().value;
        address oldCharlieTreasury = charlieTreasury[asset];
        charlieTreasury[asset] = charlieTreasuryAddress;

        emit AmmPoolsCharlieTreasuryChanged(msg.sender, asset, oldCharlieTreasury, charlieTreasuryAddress);
    }

    function getAmmPoolsCharlieTreasury(address asset) internal view returns (address) {
        mapping(address => address) storage charlieTreasury = StorageLib.getAmmPoolsCharlieTreasuryStorage().value;
        return charlieTreasury[asset];
    }

    function setAmmPoolsCharlieTreasuryManager(address asset, address charlieTreasuryManagerAddress) internal {
        require(asset != address(0), IporErrors.WRONG_ADDRESS);
        require(charlieTreasuryManagerAddress != address(0), IporErrors.WRONG_ADDRESS);

        mapping(address => address) storage charlieTreasuryManager = StorageLib
            .getAmmPoolsCharlieTreasuryManagerStorage()
            .value;
        address oldCharlieTreasuryManager = charlieTreasuryManager[asset];
        charlieTreasuryManager[asset] = charlieTreasuryManagerAddress;

        emit AmmPoolsCharlieTreasuryManagerChanged(
            msg.sender,
            asset,
            oldCharlieTreasuryManager,
            charlieTreasuryManagerAddress
        );
    }

    function getAmmPoolsCharlieTreasuryManager(address asset) internal view returns (address) {
        mapping(address => address) storage charlieTreasuryManager = StorageLib
            .getAmmPoolsCharlieTreasuryManagerStorage()
            .value;
        return charlieTreasuryManager[asset];
    }

    function setAmmPoolsAutoRebalanceThreshold(address asset, uint256 newAutoRebalanceThreshold) internal {
        require(asset != address(0), IporErrors.WRONG_ADDRESS);

        mapping(address => uint256) storage autoRebalanceThreshold = StorageLib
            .getAmmPoolsAutoRebalanceThresholdStorage()
            .value;
        uint256 oldAutoRebalanceThreshold = autoRebalanceThreshold[asset];
        autoRebalanceThreshold[asset] = newAutoRebalanceThreshold;

        emit AmmPoolsAutoRebalanceThresholdChanged(
            msg.sender,
            asset,
            oldAutoRebalanceThreshold * Constants.D18,
            newAutoRebalanceThreshold * Constants.D18
        );
    }

    function getAmmPoolsAutoRebalanceThreshold(address asset) internal view returns (uint256) {
        mapping(address => uint256) storage autoRebalanceThreshold = StorageLib
            .getAmmPoolsAutoRebalanceThresholdStorage()
            .value;
        return autoRebalanceThreshold[asset];
    }
}

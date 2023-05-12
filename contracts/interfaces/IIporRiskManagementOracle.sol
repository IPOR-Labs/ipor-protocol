// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.16;

import "./types/IporRiskManagementOracleTypes.sol";

interface IIporRiskManagementOracle {
    /// @notice Returns current version of IIporRiskManagementOracle's
    /// @dev Increase number when implementation inside source code is different that implementation deployed on Mainnet
    /// @return current IIporRiskManagementOracle version
    function getVersion() external pure returns (uint256);

    /// @notice Gets risk indicators for a given asset. Amounts and rates represented in 18 decimals.
    /// @param asset underlying / stablecoin address supported in Ipor Protocol
    /// @return maxNotionalPayFixed maximum notional value for pay fixed leg
    /// @return maxNotionalReceiveFixed maximum notional value for receive fixed leg
    /// @return maxUtilizationRatePayFixed maximum utilization rate for pay fixed leg
    /// @return maxUtilizationRateReceiveFixed maximum utilization rate for receive fixed leg
    /// @return maxUtilizationRate maximum utilization rate for both legs
    /// @return lastUpdateTimestamp Last risk indicators update done by off-chain service
    function getRiskIndicators(address asset)
        external
        view
        returns (
            uint256 maxNotionalPayFixed,
            uint256 maxNotionalReceiveFixed,
            uint256 maxUtilizationRatePayFixed,
            uint256 maxUtilizationRateReceiveFixed,
            uint256 maxUtilizationRate,
            uint256 lastUpdateTimestamp
        );

    /// @notice Gets base spreads for a given asset. Rates represented in 6 decimals. 1 = 0.0001%
    /// @param asset underlying / stablecoin address supported in Ipor Protocol
    /// @return lastUpdateTimestamp Last base spreads update done by off-chain service
    /// @return spread28dPayFixed spread for 28 days pay fixed swap
    /// @return spread28dReceiveFixed spread for 28 days receive fixed swap
    /// @return spread60dPayFixed spread for 60 days pay fixed swap
    /// @return spread60dReceiveFixed spread for 60 days receive fixed swap
    /// @return spread90dPayFixed spread for 90 days pay fixed swap
    /// @return spread90dReceiveFixed spread for 90 days receive fixed swap
    function getBaseSpreads(address asset)
        external
        view
        returns (
            uint256 lastUpdateTimestamp,
            int256 spread28dPayFixed,
            int256 spread28dReceiveFixed,
            int256 spread60dPayFixed,
            int256 spread60dReceiveFixed,
            int256 spread90dPayFixed,
            int256 spread90dReceiveFixed
        );

    /// @notice Updates risk indicators for a given asset. Values and rates are not represented in 18 decimals.
    /// @dev Emmits {RiskIndicatorsUpdated} event.
    /// @param asset underlying / stablecoin address supported by IPOR Protocol
    /// @param maxNotionalPayFixed maximum notional value for pay fixed leg, 1 = 10k
    /// @param maxNotionalReceiveFixed maximum notional value for receive fixed leg, 1 = 10k
    /// @param maxUtilizationRatePayFixed maximum utilization rate for pay fixed leg, 1 = 0.01%
    /// @param maxUtilizationRateReceiveFixed maximum utilization rate for receive fixed leg, 1 = 0.01%
    /// @param maxUtilizationRate maximum utilization rate for both legs, 1 = 0.01%
    function updateRiskIndicators(
        address asset,
        uint256 maxNotionalPayFixed,
        uint256 maxNotionalReceiveFixed,
        uint256 maxUtilizationRatePayFixed,
        uint256 maxUtilizationRateReceiveFixed,
        uint256 maxUtilizationRate
    ) external;

    /// @notice Updates risk indicators for a multiple assets. Values and rates are not represented in 18 decimals.
    /// @dev Emmits {RiskIndicatorsUpdated} event.
    /// @param asset underlying / stablecoin addresses supported by IPOR Protocol
    /// @param maxNotionalPayFixed maximum notional value for pay fixed leg, 1 = 10k
    /// @param maxNotionalReceiveFixed maximum notional value for receive fixed leg, 1 = 10k
    /// @param maxUtilizationRatePayFixed maximum utilization rate for pay fixed leg, 1 = 0.01%
    /// @param maxUtilizationRateReceiveFixed maximum utilization rate for receive fixed leg, 1 = 0.01%
    /// @param maxUtilizationRate maximum utilization rate for both legs, 1 = 0.01%
    function updateRiskIndicators(
        address[] memory asset,
        uint256[] memory maxNotionalPayFixed,
        uint256[] memory maxNotionalReceiveFixed,
        uint256[] memory maxUtilizationRatePayFixed,
        uint256[] memory maxUtilizationRateReceiveFixed,
        uint256[] memory maxUtilizationRate
    ) external;

    /// @notice Updates base spreads for a given asset. Rates are not represented in 18 decimals
    /// @dev Emmits {BaseSpreadsUpdated} event.
    /// @param asset underlying / stablecoin address supported by IPOR Protocol
    /// @param spread28dPayFixed spread for 28 days pay fixed swap
    /// @param spread28dReceiveFixed spread for 28 days receive fixed swap
    /// @param spread60dPayFixed spread for 60 days pay fixed swap
    /// @param spread60dReceiveFixed spread for 60 days receive fixed swap
    /// @param spread90dPayFixed spread for 90 days pay fixed swap
    /// @param spread90dReceiveFixed spread for 90 days receive fixed swap
    function updateBaseSpreads(
        address asset,
        int256 spread28dPayFixed,
        int256 spread28dReceiveFixed,
        int256 spread60dPayFixed,
        int256 spread60dReceiveFixed,
        int256 spread90dPayFixed,
        int256 spread90dReceiveFixed
    ) external;

    /// @notice Updates base spreads for a multiple assets.
    /// @dev Emmits {BaseSpreadsUpdated} event.
    /// @param asset underlying / stablecoin addresses supported by IPOR Protocol
    /// @param spread28dPayFixed spread for 28 days pay fixed swap
    /// @param spread28dReceiveFixed spread for 28 days receive fixed swap
    /// @param spread60dPayFixed spread for 60 days pay fixed swap
    /// @param spread60dReceiveFixed spread for 60 days receive fixed swap
    /// @param spread90dPayFixed spread for 90 days pay fixed swap
    /// @param spread90dReceiveFixed spread for 90 days receive fixed swap
    function updateBaseSpreads(
        address[] memory asset,
        int256[] memory spread28dPayFixed,
        int256[] memory spread28dReceiveFixed,
        int256[] memory spread60dPayFixed,
        int256[] memory spread60dReceiveFixed,
        int256[] memory spread90dPayFixed,
        int256[] memory spread90dReceiveFixed
    ) external;

    /// @notice Adds asset which IPOR Protocol will support. Function available only for Owner.
    /// @param asset underlying / stablecoin address which will be supported by IPOR Protocol.
    /// @param riskIndicators risk indicators
    /// @param baseSpreads base spread for each maturities and both legs
    function addAsset(
        address asset,
        IporRiskManagementOracleTypes.RiskIndicators calldata riskIndicators,
        IporRiskManagementOracleTypes.BaseSpreads calldata baseSpreads
    ) external;

    /// @notice Removes asset which IPOR Protocol will not support. Function available only for Owner.
    /// @param asset  underlying / stablecoin address which current is supported by IPOR Protocol.
    function removeAsset(address asset) external;

    /// @notice Checks if given asset is supported by IPOR Protocol.
    /// @param asset underlying / stablecoin address
    function isAssetSupported(address asset) external view returns (bool);

    /// @notice Adds new Updater. Updater has right to update indicators. Function available only for Owner.
    /// @param newUpdater new updater address
    function addUpdater(address newUpdater) external;

    /// @notice Removes Updater. Function available only for Owner.
    /// @param updater updater address
    function removeUpdater(address updater) external;

    /// @notice Checks if given account is an Updater.
    /// @param account account for checking
    /// @return 0 if account is not updater, 1 if account is updater.
    function isUpdater(address account) external view returns (uint256);

    /// @notice Pauses current smart contract, it can be executed only by the Owner
    /// @dev Emits {Paused} event from IporOracle.
    function pause() external;

    /// @notice Unpauses current smart contract, it can be executed only by the Owner
    /// @dev Emits {Unpaused} event from IporOracle.
    function unpause() external;

    /// @notice event emitted when risk indicators are updated. Values and rates are not represented in 18 decimals.
    /// @param asset underlying / stablecoin address supported by IPOR Protocol
    /// @param maxNotionalPayFixed maximum notional value for pay fixed leg, 1 = 10k
    /// @param maxNotionalReceiveFixed maximum notional value for receive fixed leg, 1 = 10k
    /// @param maxUtilizationRatePayFixed maximum utilization rate for pay fixed leg, 1 = 0.01%
    /// @param maxUtilizationRateReceiveFixed maximum utilization rate for receive fixed leg, 1 = 0.01%
    /// @param maxUtilizationRate maximum utilization rate for both legs, 1 = 0.01%
    event RiskIndicatorsUpdated(
        address indexed asset,
        uint256 maxNotionalPayFixed,
        uint256 maxNotionalReceiveFixed,
        uint256 maxUtilizationRatePayFixed,
        uint256 maxUtilizationRateReceiveFixed,
        uint256 maxUtilizationRate
    );

    /// @notice event emitted when base spreads are updated. Rates are represented in 18 decimals.
    /// @param asset underlying / stablecoin address supported by IPOR Protocol
    /// @param baseSpreads28dPayFixed spread for 28 days pay fixed swap
    /// @param baseSpreads28dReceiveFixed spread for 28 days receive fixed swap
    /// @param baseSpreads60dPayFixed spread for 60 days pay fixed swap
    /// @param baseSpreads60dReceiveFixed spread for 60 days receive fixed swap
    /// @param baseSpreads90dPayFixed spread for 90 days pay fixed swap
    /// @param baseSpreads90dReceiveFixed spread for 90 days receive fixed swap
    event BaseSpreadsUpdated(
        address indexed asset,
        int256 baseSpreads28dPayFixed,
        int256 baseSpreads28dReceiveFixed,
        int256 baseSpreads60dPayFixed,
        int256 baseSpreads60dReceiveFixed,
        int256 baseSpreads90dPayFixed,
        int256 baseSpreads90dReceiveFixed
    );

    /// @notice event emitted when new asset is added
    /// @param asset underlying / stablecoin address
    event IporRiskManagementOracleAssetAdded(address indexed asset);

    /// @notice event emitted when asset is removed
    /// @param asset underlying / stablecoin address
    event IporRiskManagementOracleAssetRemoved(address indexed asset);

    /// @notice event emitted when new updater is added
    /// @param updater address
    event IporRiskManagementOracleUpdaterAdded(address indexed updater);

    /// @notice event emitted when updater is removed
    /// @param updater address
    event IporRiskManagementOracleUpdaterRemoved(address indexed updater);
}

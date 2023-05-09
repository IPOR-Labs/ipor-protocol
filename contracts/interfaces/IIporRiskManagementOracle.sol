// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.16;

interface IIporRiskManagementOracle {
    /// @notice Returns current version of IIporRiskManagementOracle's
    /// @dev Increase number when implementation inside source code is different that implementation deployed on Mainnet
    /// @return current IIporRiskManagementOracle version
    function getVersion() external pure returns (uint256);

    /// @notice Gets risk indicators for a given asset
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

    /// @notice Updates risk indicators for a given asset
    /// @dev Emmits {RiskIndicatorsUpdated} event.
    /// @param asset underlying / stablecoin address supported by IPOR Protocol
    /// @param maxNotionalPayFixed maximum notional value for pay fixed leg
    /// @param maxNotionalReceiveFixed maximum notional value for receive fixed leg
    /// @param maxUtilizationRatePayFixed maximum utilization rate for pay fixed leg
    /// @param maxUtilizationRateReceiveFixed maximum utilization rate for receive fixed leg
    /// @param maxUtilizationRate maximum utilization rate for both legs
    function updateRiskIndicators(
        address asset,
        uint256 maxNotionalPayFixed,
        uint256 maxNotionalReceiveFixed,
        uint256 maxUtilizationRatePayFixed,
        uint256 maxUtilizationRateReceiveFixed,
        uint256 maxUtilizationRate
    ) external;

    /// @notice Updates risk indicators for a multiple assets
    /// @dev Emmits {RiskIndicatorsUpdated} event.
    /// @param asset underlying / stablecoin addresses supported by IPOR Protocol
    /// @param maxNotionalPayFixed maximum notional value for pay fixed leg
    /// @param maxNotionalReceiveFixed maximum notional value for receive fixed leg
    /// @param maxUtilizationRatePayFixed maximum utilization rate for pay fixed leg
    /// @param maxUtilizationRateReceiveFixed maximum utilization rate for receive fixed leg
    /// @param maxUtilizationRate maximum utilization rate for both legs
    function updateRiskIndicators(
        address[] memory asset,
        uint256[] memory maxNotionalPayFixed,
        uint256[] memory maxNotionalReceiveFixed,
        uint256[] memory maxUtilizationRatePayFixed,
        uint256[] memory maxUtilizationRateReceiveFixed,
        uint256[] memory maxUtilizationRate
    ) external;

    /// @notice Adds asset which IPOR Protocol will support. Function available only for Owner. Initialized with notional equals 0 and max utilization equals 0.
    /// @param asset underlying / stablecoin address which will be supported by IPOR Protocol.
    function addAsset(
        address asset,
        uint256 maxNotionalPayFixed,
        uint256 maxNotionalReceiveFixed,
        uint256 maxUtilizationRatePayFixed,
        uint256 maxUtilizationRateReceiveFixed,
        uint256 maxUtilizationRate
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

    /// @notice event emitted when risk indicators are updated
    /// @param asset underlying / stablecoin address supported by IPOR Protocol
    /// @param maxNotionalPayFixed maximum notional value for pay fixed leg
    /// @param maxNotionalReceiveFixed maximum notional value for receive fixed leg
    /// @param maxUtilizationRatePayFixed maximum utilization rate for pay fixed leg
    /// @param maxUtilizationRateReceiveFixed maximum utilization rate for receive fixed leg
    /// @param maxUtilizationRate maximum utilization rate for both legs
    event RiskIndicatorsUpdated(
        address indexed asset,
        uint256 maxNotionalPayFixed,
        uint256 maxNotionalReceiveFixed,
        uint256 maxUtilizationRatePayFixed,
        uint256 maxUtilizationRateReceiveFixed,
        uint256 maxUtilizationRate
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

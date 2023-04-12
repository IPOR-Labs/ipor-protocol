// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.16;

interface IMarketSafetyOracle {
    /// @notice Returns current version of IMarketSafetyOracle's
    /// @dev Increase number when implementation inside source code is different that implementation deployed on Mainnet
    /// @return current IMarketSafetyOracle version
    function getVersion() external pure returns (uint256);

    function getIndicators(address asset)
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

    function updateIndicators(
        address asset,
        uint256 maxNotionalPayFixed,
        uint256 maxNotionalReceiveFixed,
        uint256 maxUtilizationRatePayFixed,
        uint256 maxUtilizationRateReceiveFixed,
        uint256 maxUtilizationRate
    ) external;

    function updateIndicators(
        address[] memory asset,
        uint256[] memory maxNotionalPayFixed,
        uint256[] memory maxNotionalReceiveFixed,
        uint256[] memory maxUtilizationRatePayFixed,
        uint256[] memory maxUtilizationRateReceiveFixed,
        uint256[] memory maxUtilizationRate
    ) external;

    /// @notice Adds asset which IPOR Protocol will support. Function available only for Owner. Initialized with notional equals 0 and max utilization equals 0.
    /// @param asset underlying / stablecoin address which will be supported by IPOR Protocol.
    function addAsset(address asset) external;

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

    event MarketSafetyIndicatorsUpdate(
        address indexed asset,
        uint256 maxNotionalPayFixed,
        uint256 maxNotionalReceiveFixed,
        uint256 maxUtilizationRatePayFixed,
        uint256 maxUtilizationRateReceiveFixed,
        uint256 maxUtilizationRate
    );

    event MarketSafetyAddAsset(address indexed asset);

    event MarketSafetyRemoveAsset(address indexed asset);

    event MarketSafetyAddUpdater(address indexed updater);

    event MarketSafetyRemoveUpdater(address indexed updater);
}

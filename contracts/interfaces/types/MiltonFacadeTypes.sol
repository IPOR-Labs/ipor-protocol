// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.9;

/// @title Structs used in comunication Darcy web application with Ipor Protocol
/// @dev structs used in IMiltonFacadeDataProvider and IWarrenFacadeDataProvider interfaces
library MiltonFacadeTypes {
    /// @notice Technical struct which groups important addresses used in smart contract MiltonFacadeDataProvider,
    /// struct represent data for one specific asset which is USDT, USDC, DAI etc.
    struct AssetConfig {
        /// @notice Milton address
        address milton;
        /// @notice MiltonStorage address
        address miltonStorage;
        /// @notice Joseph address
        address joseph;
    }
}

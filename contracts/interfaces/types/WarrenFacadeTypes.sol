// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.9;

/// @title Structs used in comunication with data consumers such as off-chain applications or other smart contracts.
/// @dev structs used in IMiltonFacadeDataProvider and IWarrenFacadeDataProvider interfaces
library WarrenFacadeTypes {
    /// @notice IPOR Index data ir used for conveniance of providing certain data to various consumers, such as off-chain applications or other smart contracts. Data is compiled for each specific asset.
    struct IporFront {
        /// @notice Asset Symbol like USDT, USDC, DAI etc.
        string assetSymbol;
        /// @notice Asset address
        address asset;
        /// @notice IPOR Index Value
        /// @dev value represented in 18 decimals
        uint256 indexValue;
        /// @notice Interest Bearing Token Price taken from Warren oracle
        /// @dev value represented in 18 decimals
        uint256 ibtPrice;
        /// @notice Last update date of IPOR Index value
        uint256 lastUpdateTimestamp;
    }
}

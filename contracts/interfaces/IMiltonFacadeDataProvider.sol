// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.9;

import "../interfaces/types/MiltonFacadeTypes.sol";

/// @title Interface for reading on-chain data related with Milton Automated Market Maker.
interface IMiltonFacadeDataProvider {
    /// @notice Gets required configuration for frontend, to open, close position, provide and redeem liquidity.
    /// @return configuration structure
    function getConfiguration() external returns (MiltonFacadeTypes.AssetConfiguration[] memory);

    /// @notice Gets Milton balances for given asset.
    /// @param asset asset address (underlying / stablecoin token)
    /// @return balance structure
    function getBalance(address asset) external view returns (MiltonFacadeTypes.Balance memory);

    /// @notice Gets ipToken exchange rate for a given asset.
    /// @param asset asset address (underlying / stablecoin token)
    /// @return ipToken current exchange rate represented in 18 decimals
    function getIpTokenExchangeRate(address asset) external view returns (uint256);

    /// @notice Gets active swaps for a given asset sender address.
    /// @param asset asset address (underlying / stablecoin token)
    /// @param offset offset for paging
    /// @param chunkSize page size for paging
    /// @return totalCount total number of sender's active swaps in Milton
    /// @return swaps list of active sender's swaps
    function getMySwaps(
        address asset,
        uint256 offset,
        uint256 chunkSize
    ) external view returns (uint256 totalCount, MiltonFacadeTypes.IporSwap[] memory swaps);
}

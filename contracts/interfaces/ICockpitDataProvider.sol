// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.9;

import "./types/IporTypes.sol";
import "./types/CockpitTypes.sol";

/// @title Interface of Ipor Protocol for interaction with Cockpit web application
interface ICockpitDataProvider {
    /// @notice gets list all IPOR Indexes for all supported assets
    /// @return List of all IPOR Indexes for all supported assets in IPOR Protocol
    function getIndexes() external view returns (CockpitTypes.IporFront[] memory);

    /// @notice Gets sender assets balance
    /// @param asset asset / stablecoin address
    /// @return sender balance in decimals specific for given asset
    function getMyTotalSupply(address asset) external view returns (uint256);

    /// @notice Gets sender IP Token balance
    /// @param asset asset / stablecoin address
    /// @return sender IpToken balance represented in 18 decimals
    function getMyIpTokenBalance(address asset) external view returns (uint256);

    /// @notice Gets sender IV Token balance
    /// @param asset asset / stablecoin address
    /// @return sender IvToken balance represented in 18 decimals
    function getMyIvTokenBalance(address asset) external view returns (uint256);

    /// @notice Gets sender allowance in Milton
    /// @param asset asset / stablecoin address
    /// @return sender allowance in Milton represented in decimals specific for given asset
    function getMyAllowanceInMilton(address asset) external view returns (uint256);

    /// @notice Gets sender allowance in Joseph
    /// @param asset asset / stablecoin address
    /// @return sender allowance in Joseph represented in decimals specific for given asset
    function getMyAllowanceInJoseph(address asset) external view returns (uint256);

    /// @notice Gets list of active Pay Fixed Receive Floating Swaps in Milton for a given asset and account
    /// @param asset asset / stablecoin address
    /// @param account account address for which list of swaps is filtered
    /// @param offset offset for paging functionality purposes
    /// @param chunkSize page size for paging functionality purposes
    /// @return totalCount total amount of elements in Milton
    /// @return swaps list of active swaps for a given filter
    function getSwapsPayFixed(
        address asset,
        address account,
        uint256 offset,
        uint256 chunkSize
    ) external view returns (uint256 totalCount, IporTypes.IporSwapMemory[] memory swaps);

    /// @notice Gets list of active Receive Fixed Pay Floating Swaps in Milton for a given asset and account
    /// @param asset asset / stablecoin address
    /// @param account account address for which list of swaps is filtered
    /// @param offset offset for paging functionality purposes
    /// @param chunkSize page size for paging functionality purposes
    /// @return totalCount total amount of elements in Milton
    /// @return swaps list of active swaps for a given filter
    function getSwapsReceiveFixed(
        address asset,
        address account,
        uint256 offset,
        uint256 chunkSize
    ) external view returns (uint256 totalCount, IporTypes.IporSwapMemory[] memory swaps);

    /// @notice Gets list of active Pay Fixed Receive Floating Swaps in Milton of sender for a given asset
    /// @param asset asset / stablecoin address
    /// @param offset offset for paging functionality purposes
    /// @param chunkSize page size for paging functionality purposes
    /// @return totalCount total amount of elements in Milton
    /// @return swaps list of active swaps for a given asset
    function getMySwapsPayFixed(
        address asset,
        uint256 offset,
        uint256 chunkSize
    ) external view returns (uint256 totalCount, IporTypes.IporSwapMemory[] memory swaps);

    /// @notice Gets list of active Receive Fixed Pay Floating Swaps in Milton of sender for a given asset
    /// @param asset asset / stablecoin address
    /// @param offset offset for paging functionality purposes
    /// @param chunkSize page size for paging functionality purposes
    /// @return totalCount total amount of elements in Milton
    /// @return swaps list of active swaps for a given asset
    function getMySwapsReceiveFixed(
        address asset,
        uint256 offset,
        uint256 chunkSize
    ) external view returns (uint256 totalCount, IporTypes.IporSwapMemory[] memory swaps);

    /// @notice Calculates spread value for a given asset based on a current Milton balance,
    /// SOAP, Utilization adn IPOR Index indicators.
    /// @param asset asset / stablecoin address
    /// @return spreadPayFixedValue Spread value for Pay Fixed leg for a given asset
    /// @return spreadRecFixedValue Spread value for Receive Fixed leg for a given asset
    function calculateSpread(address asset)
        external
        view
        returns (uint256 spreadPayFixedValue, uint256 spreadRecFixedValue);
}

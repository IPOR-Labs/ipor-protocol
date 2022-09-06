// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.16;

import "./types/IporTypes.sol";
import "./types/CockpitTypes.sol";

/// @title Interface of IPOR Protocol for interaction with external diagnostics web applications
interface ICockpitDataProvider {
    /// @notice Returns current version of Cockpit Data Provider
    /// @dev Increase number when implementation inside source code is different that implementation deployed on Mainnet
    /// @return current Cockpit Data Provider version
    function getVersion() external pure returns (uint256);

    /// @notice gets list all IPOR Indexes for all supported assets
    /// @return List of all IPOR Indexes for all supported assets in IPOR Protocol
    function getIndexes() external view returns (CockpitTypes.IporFront[] memory);

    /// @notice Gets asset's sender balance
    /// @param asset asset / stablecoin address
    /// @return sender balance in decimals specific for given asset
    function getMyTotalSupply(address asset) external view returns (uint256);

    /// @notice Gets sender's ipToken balance
    /// @param asset asset / stablecoin address
    /// @return sender ipToken balance represented in 18 decimals
    function getMyIpTokenBalance(address asset) external view returns (uint256);

    /// @notice Gets sender's ivToken balance
    /// @param asset asset / stablecoin address
    /// @return sender ivToken balance represented in 18 decimals
    function getMyIvTokenBalance(address asset) external view returns (uint256);

    /// @notice Gets sender's allowance in Milton
    /// @param asset asset / stablecoin address
    /// @return sender allowance in Milton represented in decimals specific for given asset
    function getMyAllowanceInMilton(address asset) external view returns (uint256);

    /// @notice Gets sender allowance in Joseph
    /// @param asset asset / stablecoin address
    /// @return sender allowance in Joseph represented in decimals specific for given asset
    function getMyAllowanceInJoseph(address asset) external view returns (uint256);

    /// @notice Gets the list of active Pay Fixed Receive Floating swaps in Milton for a given asset and address
    /// @param asset asset / stablecoin address
    /// @param account account address for which list of swaps is scoped
    /// @param offset offset for paging
    /// @param chunkSize page size for paging
    /// @return totalCount total number of active Pay Fixed swaps in Milton
    /// @return swaps list of active swaps for a given filter
    function getSwapsPayFixed(
        address asset,
        address account,
        uint256 offset,
        uint256 chunkSize
    ) external view returns (uint256 totalCount, IporTypes.IporSwapMemory[] memory swaps);

    /// @notice Gets the list of active Receive Fixed Pay Floating Swaps in Milton for a given asset and address
    /// @param asset asset / stablecoin address
    /// @param account account address for which list of swaps is scoped
    /// @param offset offset for paging
    /// @param chunkSize page size for paging
    /// @return totalCount total number of Receive Fixed swaps in Milton
    /// @return swaps list of active swaps for a given filter
    function getSwapsReceiveFixed(
        address asset,
        address account,
        uint256 offset,
        uint256 chunkSize
    ) external view returns (uint256 totalCount, IporTypes.IporSwapMemory[] memory swaps);

    /// @notice Gets list of active Pay Fixed Receive Floating Swaps in Milton of sender for a given asset
    /// @param asset asset / stablecoin address
    /// @param offset offset for paging
    /// @param chunkSize page size for paging
    /// @return totalCount total number of Pay Fixed swaps in Milton for a current user
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
    /// @return totalCount total amount of Receive Fixed swaps in Milton for a current user
    /// @return swaps list of active swaps for a given asset
    function getMySwapsReceiveFixed(
        address asset,
        uint256 offset,
        uint256 chunkSize
    ) external view returns (uint256 totalCount, IporTypes.IporSwapMemory[] memory swaps);

    /// @notice Calculates spread value for a given asset based on a current Milton balance,
    /// SOAP, utilization and IPOR Index indicators.
    /// @param asset asset / stablecoin address
    /// @return spreadPayFixed Spread value for Pay Fixed leg for a given asset
    /// @return spreadReceiveFixed Spread value for Receive Fixed leg for a given asset
    function calculateSpread(address asset)
        external
        view
        returns (int256 spreadPayFixed, int256 spreadReceiveFixed);
}

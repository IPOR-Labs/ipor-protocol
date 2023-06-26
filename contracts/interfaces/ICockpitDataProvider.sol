// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.20;

import "contracts/interfaces/types/IporTypes.sol";
import "contracts/interfaces/types/CockpitTypes.sol";

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

    /// @notice Gets sender's allowance in AmmTreasury
    /// @param asset asset / stablecoin address
    /// @return sender allowance in AmmTreasury represented in decimals specific for given asset
    function getMyAllowanceInAmmTreasury(address asset) external view returns (uint256);

    /// @notice Calculates spread value for a given asset based on a current AmmTreasury balance,
    /// SOAP, collateral ratio and IPOR Index indicators.
    /// @param asset asset / stable coin address
    /// @return spreadPayFixed Spread value for Pay Fixed leg for a given asset
    /// @return spreadReceiveFixed Spread value for Receive Fixed leg for a given asset
    function calculateSpread(address asset) external view returns (int256 spreadPayFixed, int256 spreadReceiveFixed);
}

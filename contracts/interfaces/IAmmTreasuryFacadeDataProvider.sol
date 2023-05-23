// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.16;

import "../interfaces/types/AmmFacadeTypes.sol";

/// @title Interface for reading on-chain data related to AmmTreasury Automated Market Maker.
interface IAmmTreasuryFacadeDataProvider {
    /// @notice Returns current version of AmmTreasury Facade Data Provider
    /// @dev Increase number when implementation inside source code is different that implementation deployed on Mainnet
    /// @return current AmmTreasury Facade Data Provider version
    function getVersion() external pure returns (uint256);

    /// @notice Gets required configuration for frontend (webapp etc.), to open, close position, provide and redeem liquidity.
    /// @return configuration structure
    function getConfiguration()
        external
        view
        returns (AmmFacadeTypes.AssetConfiguration[] memory);

    /// @notice Gets AmmTreasury balances for given asset.
    /// @param asset asset address
    /// @return balance structure
    function getBalance(address asset) external view returns (AmmFacadeTypes.Balance memory);

    /// @notice Gets ipToken exchange rate for a given asset.
    /// @param asset asset address
    /// @return ipToken current exchange rate represented in 18 decimals
    function getIpTokenExchangeRate(address asset) external view returns (uint256);
}

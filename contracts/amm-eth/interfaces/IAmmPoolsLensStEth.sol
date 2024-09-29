// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.26;

/// @title Interface of the AmmPoolsLensStEth contract.
interface IAmmPoolsLensStEth {
    /// @notice Retrieves the exchange rate between stEth and ipstEth using the AmmLibEth library.
    /// @return The exchange rate calculated based on the balance of stEth in the AMM Treasury and the total supply of ipstEth.
    /// @dev This function acts as a wrapper around the `getExchangeRate` function in the AmmLibEth library.
    function getIpstEthExchangeRate() external view returns (uint256);
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.20;

/// @title Interface of the AmmPoolsLensWstEth contract.
interface IAmmPoolsLensWusdm {
    /// @notice Retrieves the exchange rate between usdm and ipUsdm using the AmmLibEth library.
    /// @return The exchange rate calculated based on the balance of usdm in the AMM Treasury and the total supply of ipUsdm.
    /// @dev This function acts as a wrapper around the `getExchangeRate` function in the AmmLibEth library.
    function getIpWusdmExchangeRate() external view returns (uint256);
}

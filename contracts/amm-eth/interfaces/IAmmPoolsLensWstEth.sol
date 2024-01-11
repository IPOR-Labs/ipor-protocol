// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.20;

/// @title Interface of the AmmPoolsLensWstEth contract.
interface IAmmPoolsLensWstEth {
    /// @notice Retrieves the exchange rate between stEth and ipwstEth using the AmmLibEth library.
    /// @return The exchange rate calculated based on the balance of stEth in the AMM Treasury and the total supply of ipwstEth.
    /// @dev This function acts as a wrapper around the `getExchangeRate` function in the AmmLibEth library.
    function getIpwstEthExchangeRate() external view returns (uint256);
}

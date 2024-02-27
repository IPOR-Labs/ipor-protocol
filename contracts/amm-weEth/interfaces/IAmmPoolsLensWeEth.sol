// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.20;

/// @title Interface of the AmmPoolsLensWstEth contract.
interface IAmmPoolsLensWeEth {
    /// @notice Retrieves the exchange rate between weEth and ipUsdm using the AmmLibEth library.
    /// @return The exchange rate calculated based on the balance of weEth in the AMM Treasury and the total supply of ipUsdm.
    /// @dev This function acts as a wrapper around the `getExchangeRate`.
    function getIpWeEthExchangeRate() external view returns (uint256);
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.20;

import "./IStrategy.sol";

/// @title Interface for interaction with AAVE.
/// @notice It standarises the calls made by the asset management to the external DeFi protocol.
interface IStrategyAave is IStrategy {
    /// @notice Extra steps executed before claiming rewards. Function can be executed by anyone.
    function beforeClaim() external;

    /// @notice Set Stk Aave token address. Function available only for Onwer.
    /// @param newStkAave new Stk Aave address
    function setStkAave(address newStkAave) external;

    /// @notice Emmited after beforeClaim function had been executed.
    /// @param executedBy account that has executed before claim action
    /// @param shareTokens list of share tokens related to this strategy
    event DoBeforeClaim(address indexed executedBy, address[] shareTokens);

    /// @notice Emmited when Stk AAVE address has changed
    /// @param newStkAave new Stk Aave address
    event StkAaveChanged(address newStkAave);
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.9;

import "./IStrategy.sol";

/// @title Interface for interaction with AAVE strategy which represent external DeFi protocol.
interface IStrategyAave is IStrategy {
    /// @notice Extra steps executed before claim rewards. Function can be executed by anyone.
    function beforeClaim() external;

    /// @notice Set Stk Aave token. Function available only for Onwer.
    /// @param newStkAave new Stk Aave address
    function setStkAave(address newStkAave) external;

    /// @notice Emmited when beforeClaim function was executed.
    /// @param executedBy account who execute before claim action
    /// @param shareTokens list of share tokens related with this strategy
    event DoBeforeClaim(address indexed executedBy, address[] shareTokens);

    /// @notice Emmited when Stk AAVE address changed
    /// @param changedBy account address who changed Stk AAVE address
    /// @param oldStkAave old Stk Aave address
    /// @param newStkAave new Stk Aave address
    event StkAaveChanged(address changedBy, address oldStkAave, address newStkAave);
}

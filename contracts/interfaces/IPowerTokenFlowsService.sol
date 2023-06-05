// SPDX-License-Identifier: BSD-3-Clause
pragma solidity 0.8.20;

interface IPowerTokenFlowsService {
    /// @notice Claims rewards for the caller by transferring them from the LiquidityMining contract to the PowerToken contract.
    /// @param lpTokens An array of LP tokens for which the rewards are to be claimed.
    /// @dev This function calls the `claim` function of the `ILiquidityMiningV2` contract to retrieve the rewards amount to transfer.
    /// It then adds the staked tokens to the `powerToken` contract and transfers the rewards from the `liquidityMining` contract to the `powerToken` contract.
    /// @dev Reverts if the `lpTokens` array is empty.
    /// @dev Reverts if there are no rewards to claim.
    function claimRewardsFromLiquidityMining(address[] calldata lpTokens) external;

    /// @notice Updates the indicators for a given account and LP tokens.
    /// @param account The account address for which the indicators are to be updated.
    /// @param lpTokens An array of LP tokens for which the indicators are to be updated.
    /// @dev This function calls the `updateIndicators` function of the `ILiquidityMiningV2` contract to update the indicators.
    /// @dev Reverts if the `lpTokens` array is empty.
    function updateIndicatorsInLiquidityMining(address account, address[] calldata lpTokens) external;

    /// @notice Delegates staked tokens by providing LP tokens and corresponding amounts.
    /// @param lpTokens An array of LP tokens to delegate.
    /// @param lpTokenAmounts An array of corresponding amounts of LP tokens to delegate.
    /// @dev This function allows the caller to delegate their staked tokens by providing the LP tokens and their corresponding amounts.
    /// @dev It requires that the length of `lpTokens` is equal to the length of `lpTokenAmounts`.
    /// @dev It reverts if either `lpTokens` or `lpTokenAmounts` arrays are empty.
    function delegatePwTokensToLiquidityMining(address[] calldata lpTokens, uint256[] calldata lpTokenAmounts) external;

    /// @notice Undelegates staked tokens by providing LP tokens and corresponding amounts.
    /// @param lpTokens An array of LP tokens to undelegate.
    /// @param lpTokenAmounts An array of corresponding amounts of LP tokens to undelegate.
    /// @dev This function allows the caller to undelegate their staked tokens by providing the LP tokens and their corresponding amounts.
    /// @dev It requires that the length of `lpTokens` is equal to the length of `lpTokenAmounts`.
    /// @dev It reverts if either `lpTokens` or `lpTokenAmounts` arrays are empty.
    /// @dev It reverts if the total staked token amount to undelegate is not greater than zero.
    function undelegatePwTokensToLiquidityMining(address[] calldata lpTokens, uint256[] calldata lpTokenAmounts) external;
}

// SPDX-License-Identifier: BSD-3-Clause
pragma solidity 0.8.16;

import "./types/LiquidityMiningTypes.sol";

/// @title The interface for interaction with the LiquidityMining.
/// LiquidityMining is responsible for the distribution of the Power Token rewards to accounts
/// staking lpTokens and / or delegating Power Tokens to LiquidityMining. LpTokens can be staked directly to the LiquidityMining,
/// Power Tokens are a staked version of the [Staked] Tokens minted by the PowerToken smart contract.
interface ILiquidityMiningV2 {
    /// @notice Contract ID. The keccak-256 hash of "io.ipor.LiquidityMining" decreased by 1
    /// @return Returns an ID of the contract
    function getContractId() external pure returns (bytes32);

    /// @notice Returns the balance of staked lpTokens
    /// @param account the account's address
    /// @param lpToken the address of lpToken
    /// @return balance of the lpTokens staked by the sender
    function balanceOf(address account, address lpToken) external view returns (uint256);

    /// @notice It returns the balance of delegated Power Tokens for a given `account` and the list of lpToken addresses.
    /// @param account address for which to fetch the information about balance of delegated Power Tokens
    /// @param lpTokens list of lpTokens addresses(lpTokens)
    /// @return balances list of {LiquidityMiningTypes.DelegatedPwTokenBalance} structure, with information how much Power Token is delegated per lpToken address.
    function balanceOfDelegatedPwToken(address account, address[] memory lpTokens)
        external
        view
        returns (LiquidityMiningTypes.DelegatedPwTokenBalance[] memory balances);

    /// @notice Calculates the accrued rewards for multiple LP tokens.
    /// @param lpTokens An array of LP token addresses.
    /// @return An array of `AccruedRewardsResult` structures, containing the LP token address and the accrued rewards amount.
    function calculateAccruedRewards(address[] calldata lpTokens)
        external
        view
        returns (LiquidityMiningTypes.AccruedRewardsResult[] memory);

    /// @notice Calculates the rewards earned by an account for multiple LP tokens.
    /// @param account The address of the account for which to calculate rewards.
    /// @param lpTokens An array of LP token addresses.
    /// @return An array of `AccountRewardResult` structures, containing the LP token address, rewards amount, and allocated Power Token balance for the account.
    function calculateAccountRewards(address account, address[] calldata lpTokens)
        external
        view
        returns (LiquidityMiningTypes.AccountRewardResult[] memory);

    /// @notice method allowing to update the indicators per asset (lpToken).
    /// @param account of which we should update the indicators
    /// @param lpTokens of the staking pools to update the indicators
    function updateIndicators(address account, address[] calldata lpTokens) external;

    /// @notice Adds LP tokens to the liquidity mining for multiple accounts.
    /// @param updateLpToken An array of `UpdateLpToken` structures, each containing the account address,
    /// LP token address, and LP token amount to be added.
    function addLpTokens(LiquidityMiningTypes.UpdateLpToken[] memory updateLpToken) external;

    /// @notice Adds Power tokens to the liquidity mining for multiple accounts.
    /// @param updatePwToken An array of `UpdatePwToken` structures, each containing the account address,
    /// LP token address, and Power token amount to be added.
    function addPwTokens(LiquidityMiningTypes.UpdatePwToken[] memory updatePwToken) external;

    /// @notice Removes LP tokens from the liquidity mining for multiple accounts.
    /// @param updateLpToken An array of `UpdateLpToken` structures, each containing the account address,
    /// LP token address, and LP token amount to be removed.
    function removeLpTokens(LiquidityMiningTypes.UpdateLpToken[] memory updateLpToken) external;

    /// @notice Removes Power Tokens from the liquidity mining for multiple accounts.
    /// @param updatePwToken An array of `UpdatePwToken` structures, each containing the account address,
    /// LP token address, and Power Token amount to be removed.
    function removePwTokens(LiquidityMiningTypes.UpdatePwToken[] memory updatePwToken) external;

    /// @notice Claims accumulated rewards for multiple LP tokens and transfers them to the specified account.
    /// @param account The account address to claim rewards for.
    /// @param lpTokens An array of LP token addresses for which rewards will be claimed.
    /// @return rewardsAmountToTransfer The total amount of rewards transferred to the account.
    function claim(address account, address[] calldata lpTokens)
        external
        returns (uint256 rewardsAmountToTransfer);

    /// @notice Retrieves the global indicators for multiple LP tokens.
    /// @param lpTokens An array of LP token addresses for which to retrieve the global indicators.
    /// @return An array of LiquidityMiningTypes.GlobalIndicatorsResult containing the global indicators for each LP token.
    function getGlobalIndicators(address[] calldata lpTokens)
        external
        view
        returns (LiquidityMiningTypes.GlobalIndicatorsResult[] memory);

    /// @notice Retrieves the account indicators for a specific account and multiple LP tokens.
    /// @param account The address of the account for which to retrieve the account indicators.
    /// @param lpTokens An array of LP token addresses for which to retrieve the account indicators.
    /// @return An array of LiquidityMiningTypes.AccountIndicatorsResult containing the account indicators for each LP token.
    function getAccountIndicators(address account, address[] calldata lpTokens)
        external
        view
        returns (LiquidityMiningTypes.AccountIndicatorsResult[] memory);

    /// @notice Emitted when the account stakes the lpTokens
    /// @param account Account's address in the context of which the activities of staking of lpTokens are performed
    /// @param lpToken address of lpToken being staked
    /// @param lpTokenAmount of lpTokens to stake, represented with 18 decimals
    event LpTokensStaked(address account, address lpToken, uint256 lpTokenAmount);

    /// @notice Emitted when the account claims the rewards
    /// @param account Account's address in the context of which activities of claiming are performed
    /// @param lpTokens The addresses of the lpTokens for which the rewards are claimed
    /// @param rewardsAmount Reward amount denominated in pwToken, represented with 18 decimals
    event Claimed(address account, address[] lpTokens, uint256 rewardsAmount);

    /// @notice Emitted when the account claims the allocated rewards
    /// @param account Account address in the context of which activities of claiming are performed
    /// @param allocatedRewards Reward amount denominated in pwToken, represented in 18 decimals
    event AllocatedTokensClaimed(address account, uint256 allocatedRewards);

    /// @notice Emitted when update was triggered for the account on the lpToken
    /// @param account Account address to which the update was triggered
    /// @param lpToken lpToken address to which the update was triggered
    event IndicatorsUpdated(address account, address lpToken);

    /// @notice Emitted when the lpToken is added to the LiquidityMining
    /// @param onBehalfOf Account address on behalf of which the lpToken is added
    /// @param lpToken lpToken address which is added
    /// @param lpTokenAmount Amount of lpTokens added, represented with 18 decimals
    event LpTokenAdded(address onBehalfOf, address lpToken, uint256 lpTokenAmount);

    /// @notice Emitted when the lpToken is removed from the LiquidityMining
    /// @param account address on behalf of which the lpToken is removed
    /// @param lpToken lpToken address which is removed
    /// @param lpTokenAmount Amount of lpTokens removed, represented with 18 decimals
    event LpTokensRemoved(address account, address lpToken, uint256 lpTokenAmount);

    /// @notice Emitted when the PwTokens is added to lpToken pool
    /// @param onBehalfOf Account address on behalf of which the PwToken is added
    /// @param lpToken lpToken address to which the PwToken is added
    /// @param pwTokenAmount Amount of PwTokens added, represented with 18 decimals
    event PwTokensAdded(address onBehalfOf, address lpToken, uint256 pwTokenAmount);

    /// @notice Emitted when the PwTokens is removed from lpToken pool
    /// @param account Account address on behalf of which the PwToken is removed
    /// @param lpToken lpToken address from which the PwToken is removed
    /// @param pwTokenAmount Amount of PwTokens removed, represented with 18 decimals
    event PwTokensRemoved(address account, address lpToken, uint256 pwTokenAmount);
}

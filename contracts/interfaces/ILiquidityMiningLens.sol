// SPDX-License-Identifier: BSD-3-Clause
pragma solidity 0.8.16;

import "./types/LiquidityMiningTypes.sol";

interface ILiquidityMiningLens {

    /// @notice Returns the balance of LP tokens staked by the specified account in the Liquidity Mining contract.
    /// @param account The address of the account for which the LP token balance is queried.
    /// @param lpToken The address of the LP token for which the balance is queried.
    /// @return The balance of LP tokens staked by the specified account.
    function balanceOfLpTokensStakedInLiquidityMining(address account, address lpToken) external view returns (uint256);

    /// @notice It returns the balance of delegated Power Tokens for a given `account` and the list of lpToken addresses.
    /// @param account address for which to fetch the information about balance of delegated Power Tokens
    /// @param lpTokens list of lpTokens addresses(lpTokens)
    /// @return balances list of {LiquidityMiningTypes.DelegatedPwTokenBalance} structure, with information how much Power Token is delegated per lpToken address.
    function balanceOfPowerTokensDelegatedToLiquidityMining(address account, address[] memory lpTokens)
        external
        view
        returns (LiquidityMiningTypes.DelegatedPwTokenBalance[] memory balances);

    /// @notice Calculates the accrued rewards for the specified LP tokens in the Liquidity Mining contract.
    /// @param lpTokens An array of LP tokens for which the accrued rewards are to be calculated.
    /// @return result An array of `AccruedRewardsResult` structs containing the accrued rewards information for each LP token.
    function getAccruedRewardsInLiquidityMining(address[] calldata lpTokens)
        external
        view
        returns (LiquidityMiningTypes.AccruedRewardsResult[] memory result);

    /// @notice Calculates the rewards for the specified account and LP tokens in the Liquidity Mining contract.
    /// @param account The address of the account for which the rewards are to be calculated.
    /// @param lpTokens An array of LP tokens for which the rewards are to be calculated.
    /// @return An array of `AccountRewardResult` structs containing the rewards information for each LP token.
    function getAccountRewardsInLiquidityMining(address account, address[] calldata lpTokens)
        external
        view
        returns (LiquidityMiningTypes.AccountRewardResult[] memory);

    /// @notice Retrieves the global indicators for the specified LP tokens in the Liquidity Mining contract.
    /// @param lpTokens An array of LP tokens for which the global indicators are to be retrieved.
    /// @return An array of `GlobalIndicatorsResult` structs containing the global indicators information for each LP token.
    function getGlobalIndicatorsFromLiquidityMining(address[] memory lpTokens)
        external
        view
        returns (LiquidityMiningTypes.GlobalIndicatorsResult[] memory);

    /// @notice Retrieves the account indicators for the specified account and LP tokens in the Liquidity Mining contract.
    /// @param account The address of the account for which the account indicators are to be retrieved.
    /// @param lpTokens An array of LP tokens for which the account indicators are to be retrieved.
    /// @return An array of `AccountIndicatorsResult` structs containing the account indicators information for each LP token.
    function getAccountIndicatorsFromLiquidityMining(address account, address[] memory lpTokens)
        external
        view
        returns (LiquidityMiningTypes.AccountIndicatorsResult[] memory);
}

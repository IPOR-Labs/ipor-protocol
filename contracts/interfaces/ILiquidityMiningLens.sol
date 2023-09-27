// SPDX-License-Identifier: BSD-3-Clause
pragma solidity 0.8.20;

/// @title LiquidityMiningLens interface responsible for reading data from LiquidityMining.
interface ILiquidityMiningLens {

    /// @title Struct pair representing delegated pwToken balance
    struct DelegatedPwTokenBalance {
        /// @notice lpToken address
        address lpToken;
        /// @notice The amount of Power Token delegated to lpToken staking pool
        /// @dev value represented in 18 decimals
        uint256 pwTokenAmount;
    }

    /// @title Global indicators used in rewards calculation.
    struct GlobalRewardsIndicators {
        /// @notice powerUp indicator aggregated
        /// @dev It can be changed many times during transaction, represented with 18 decimals
        uint256 aggregatedPowerUp;
        /// @notice composite multiplier in a block described in field blockNumber
        /// @dev It can be changed many times during transaction, represented with 27 decimals
        uint128 compositeMultiplierInTheBlock;
        /// @notice Composite multiplier updated in block {blockNumber} but calculated for PREVIOUS (!) block.
        /// @dev It can be changed once per block, represented with 27 decimals
        uint128 compositeMultiplierCumulativePrevBlock;
        /// @dev It can be changed once per block. Block number in which all other params of this structure are updated
        uint32 blockNumber;
        /// @notice value describing amount of rewards issued per block,
        /// @dev It can be changed at most once per block, represented with 8 decimals
        uint32 rewardsPerBlock;
        /// @notice amount of accrued rewards since inception
        /// @dev It can be changed at most once per block, represented with 18 decimals
        uint88 accruedRewards;
    }

    /// @title Params recorded for a given account. These params are used by the algorithm responsible for rewards distribution.
    /// @dev The structure in storage is updated when account interacts with the LiquidityMining smart contract (stake, unstake, delegate, undelegate, claim)
    struct AccountRewardsIndicators {
        /// @notice `composite multiplier cumulative` is calculated for previous block
        /// @dev represented in 27 decimals
        uint128 compositeMultiplierCumulativePrevBlock;
        /// @notice lpToken account's balance
        uint128 lpTokenBalance;
        /// @notive PowerUp is a result of logarithmic equastion,
        /// @dev  powerUp < 100 *10^18
        uint72 powerUp;
        /// @notice balance of Power Tokens delegated to LiquidityMining
        /// @dev delegatedPwTokenBalance < 10^26 < 2^87
        uint96 delegatedPwTokenBalance;
    }

    struct UpdateLpToken {
        address beneficiary;
        address lpToken;
        uint256 lpTokenAmount;
    }

    struct UpdatePwToken {
        address beneficiary;
        address lpToken;
        uint256 pwTokenAmount;
    }

    struct AccruedRewardsResult {
        address lpToken;
        uint256 rewardsAmount;
    }

    struct AccountRewardResult {
        address lpToken;
        uint256 rewardsAmount;
        uint256 allocatedPwTokens;
    }

    struct AccountIndicatorsResult {
        address lpToken;
        AccountRewardsIndicators indicators;
    }

    struct GlobalIndicatorsResult {
        address lpToken;
        GlobalRewardsIndicators indicators;
    }

    /// @notice Returns the balance of LP tokens staked by the specified account in the Liquidity Mining contract.
    /// @param account The address of the account for which the LP token balance is queried.
    /// @param lpToken The address of the LP token for which the balance is queried.
    /// @return The balance of LP tokens staked by the specified account.
    function balanceOfLpTokensStakedInLiquidityMining(address account, address lpToken) external view returns (uint256);

    /// @notice It returns the balance of delegated Power Tokens for a given `account` and the list of lpToken addresses.
    /// @param account address for which to fetch the information about balance of delegated Power Tokens
    /// @param lpTokens list of lpTokens addresses(lpTokens)
    /// @return balances list of {LiquidityMiningTypes.DelegatedPwTokenBalance} structure, with information how much Power Token is delegated per lpToken address.
    function balanceOfPowerTokensDelegatedToLiquidityMining(
        address account,
        address[] memory lpTokens
    ) external view returns (DelegatedPwTokenBalance[] memory balances);

    /// @notice Calculates the accrued rewards for the specified LP tokens in the Liquidity Mining contract.
    /// @param lpTokens An array of LP tokens for which the accrued rewards are to be calculated.
    /// @return result An array of `AccruedRewardsResult` structs containing the accrued rewards information for each LP token.
    function getAccruedRewardsInLiquidityMining(
        address[] calldata lpTokens
    ) external view returns (AccruedRewardsResult[] memory result);

    /// @notice Calculates the rewards for the specified account and LP tokens in the Liquidity Mining contract.
    /// @param account The address of the account for which the rewards are to be calculated.
    /// @param lpTokens An array of LP tokens for which the rewards are to be calculated.
    /// @return An array of `AccountRewardResult` structs containing the rewards information for each LP token.
    function getAccountRewardsInLiquidityMining(
        address account,
        address[] calldata lpTokens
    ) external view returns (AccountRewardResult[] memory);

    /// @notice Retrieves the global indicators for the specified LP tokens in the Liquidity Mining contract.
    /// @param lpTokens An array of LP tokens for which the global indicators are to be retrieved.
    /// @return An array of `GlobalIndicatorsResult` structs containing the global indicators information for each LP token.
    function getGlobalIndicatorsFromLiquidityMining(
        address[] memory lpTokens
    ) external view returns (GlobalIndicatorsResult[] memory);

    /// @notice Retrieves the account indicators for the specified account and LP tokens in the Liquidity Mining contract.
    /// @param account The address of the account for which the account indicators are to be retrieved.
    /// @param lpTokens An array of LP tokens for which the account indicators are to be retrieved.
    /// @return An array of `AccountIndicatorsResult` structs containing the account indicators information for each LP token.
    function getAccountIndicatorsFromLiquidityMining(
        address account,
        address[] memory lpTokens
    ) external view returns (AccountIndicatorsResult[] memory);
}

// SPDX-License-Identifier: BSD-3-Clause
pragma solidity 0.8.20;

/// @title Interface for interaction with PowerToken and LiquidityMining contracts.
interface IPowerTokenStakeService {
    /// @notice Stakes the specified amounts of LP tokens into the LiquidityMining contract.
    /// @dev This function allows the caller to stake their LP tokens on behalf of another address (`beneficiary`).
    /// @param beneficiary The address on behalf of which the LP tokens are being staked.
    /// @param lpTokens An array of LP token addresses to be staked.
    /// @param lpTokenAmounts An array of corresponding LP token amounts to be staked, represented with 18 decimals.
    /// @dev Both `lpTokens` and `lpTokenAmounts` arrays must have the same length.
    /// @dev The `beneficiary` address must not be the zero address.
    /// @dev The function ensures that the provided LP token addresses are valid and the amounts to be staked are greater than zero.
    /// @dev The function transfers the LP tokens from the caller's address to the LiquidityMining contract.
    /// @dev Finally, the function calls the `addLpTokens` function of the LiquidityMining contract to update the staked LP tokens.
    /// @dev Reverts if any of the requirements is not met or if the transfer of LP tokens fails.
    function stakeLpTokensToLiquidityMining(
        address beneficiary,
        address[] calldata lpTokens,
        uint256[] calldata lpTokenAmounts
    ) external;

    /// @notice Unstakes the specified amounts of LP tokens from the LiquidityMining contract and transfers them to the specified address.
    /// @param transferTo The address to which the unstaked LP tokens will be transferred.
    /// @param lpTokens An array of LP token addresses to be unstaked.
    /// @param lpTokenAmounts An array of corresponding LP token amounts to be unstaked, represented with 18 decimals.
    /// @dev Both `lpTokens` and `lpTokenAmounts` arrays must have the same length.
    /// @dev The function ensures that the provided LP token addresses are valid and the amounts to be unstaked are greater than zero.
    /// @dev The function calls the `removeLpTokens` function of the LiquidityMining contract to update the unstaked LP tokens.
    /// @dev Finally, the function transfers the unstaked LP tokens from the LiquidityMining contract to the specified address.
    /// @dev Reverts if any of the requirements is not met or if the transfer of LP tokens fails.
    function unstakeLpTokensFromLiquidityMining(
        address transferTo,
        address[] calldata lpTokens,
        uint256[] calldata lpTokenAmounts
    ) external;

    /// @notice Stakes the specified amount of IPOR tokens on behalf of the specified address.
    /// @param beneficiary The address on whose behalf the IPOR tokens will be staked.
    /// @param iporTokenAmount The amount of IPOR tokens to be staked, represented with 18 decimals.
    /// @dev The function ensures that the provided `beneficiary` address is valid and the `iporTokenAmount` is greater than zero.
    /// @dev The function calls the `addStakedToken` function of the PowerToken contract to update the staked IPOR tokens.
    /// @dev Finally, the function transfers the IPOR tokens from the sender to the PowerToken contract for staking.
    /// @dev Reverts if any of the requirements is not met or if the transfer of IPOR tokens fails.
    function stakeGovernanceTokenToPowerToken(address beneficiary, uint256 iporTokenAmount) external;

    /// @notice Stakes a specified amount of governance tokens and delegates power tokens to a specific beneficiary.
    /// @param beneficiary The address on whose behalf the governance tokens will be staked and power tokens will be delegated.
    /// @param governanceTokenAmount The amount of governance tokens to be staked, represented with 18 decimals.
    /// @param lpTokens An array of addresses representing the liquidity pool tokens.
    /// @param pwTokenAmounts An array of amounts of power tokens to be delegated corresponding to each liquidity pool token.
    /// @dev The function ensures that the `beneficiary` address is valid and the `governanceTokenAmount` is greater than zero.
    /// @dev The function also requires that the length of the `lpTokens` array is equal to the length of the `pwTokenAmounts` array.
    /// @dev For each liquidity pool token in `lpTokens`, the function creates an `UpdatePwToken` structure to be used for updating the power tokens in the Liquidity Mining contract.
    /// @dev The function checks if the total amount of power tokens to be delegated is less or equal to the amount of staked governance tokens.
    /// @dev The function calls the `addGovernanceTokenInternal` function of the PowerToken contract to update the staked governance tokens for the `beneficiary`.
    /// @dev The function transfers the governance tokens from the sender to the PowerToken contract for staking.
    /// @dev The function calls the `delegateInternal` function of the PowerToken contract to delegate power tokens to the `beneficiary`.
    /// @dev Finally, the function calls the `addPwTokensInternal` function of the Liquidity Mining contract to update the staked power tokens.
    /// @dev Reverts if any of the requirements is not met or if the transfer of governance tokens fails.
    function stakeGovernanceTokenToPowerTokenAndDelegate(
        address beneficiary,
        uint256 governanceTokenAmount,
        address[] calldata lpTokens,
        uint256[] calldata pwTokenAmounts
    ) external;

    /// @notice Unstakes the specified amount of IPOR tokens and transfers them to the specified address.
    /// @param transferTo The address to which the unstaked IPOR tokens will be transferred.
    /// @param iporTokenAmount The amount of IPOR tokens to be unstaked, represented with 18 decimals.
    /// @dev The function ensures that the `iporTokenAmount` is greater than zero.
    /// @dev The function calls the `removeStakedTokenWithFee` function of the PowerToken contract to remove the staked IPOR tokens.
    /// @dev Finally, the function transfers the corresponding staked token amount to the `transferTo` address.
    /// @dev Reverts if the `iporTokenAmount` is not greater than zero, or if the transfer of staked tokens fails.
    function unstakeGovernanceTokenFromPowerToken(address transferTo, uint256 iporTokenAmount) external;

    /// @notice Initiates a cooldown period for the specified amount of Power Tokens.
    /// @param pwTokenAmount The amount of Power Tokens to be put into cooldown, represented with 18 decimals.
    /// @dev The function ensures that the `pwTokenAmount` is greater than zero.
    /// @dev The function calls the `cooldown` function of the PowerToken contract to initiate the cooldown.
    /// @dev Reverts if the `pwTokenAmount` is not greater than zero.
    function pwTokenCooldown(uint256 pwTokenAmount) external;

    /// @notice Cancels the active cooldown for the sender.
    /// @dev The function calls the `cancelCooldown` function of the PowerToken contract to cancel the cooldown.
    function pwTokenCancelCooldown() external;

    /// @notice Redeems Power Tokens and transfers the corresponding Staked Tokens to the specified address.
    /// @dev The function calls the `redeem` function of the PowerToken contract to redeem Power Tokens.
    /// @param transferTo The address to which the Staked Tokens will be transferred.
    function redeemPwToken(address transferTo) external;
}

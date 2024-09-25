// SPDX-License-Identifier: BSD-3-Clause
pragma solidity 0.8.26;

/// @title Interface responsible for viewing data from PowerToken smart contract.
interface IPowerTokenLens {
    struct PwTokenCooldown {
        // @dev The timestamp when the account can redeem Power Tokens
        uint256 endTimestamp;
        // @dev The amount of Power Tokens which can be redeemed without fee when the cooldown reaches `endTimestamp`
        uint256 pwTokenAmount;
    }

    struct UpdateStakedToken {
        address beneficiary;
        uint256 stakedTokenAmount;
    }

    /// @notice Gets the total supply of the Power Token.
    /// @dev Value is calculated in runtime using baseTotalSupply and internal exchange rate.
    /// @return Total supply of Power tokens, represented with 18 decimals
    function totalSupplyOfPwToken() external view returns (uint256);

    /// @notice Gets the balance of Power Tokens for a given account
    /// @param account account address for which the balance of Power Tokens is fetched
    /// @return Returns the amount of the Power Tokens owned by the `account`.
    function balanceOfPwToken(address account) external view returns (uint256);

    /// @notice Gets the delegated balance of the Power Tokens for a given account.
    /// Tokens are delegated from PowerToken to LiquidityMining smart contract (reponsible for rewards distribution).
    /// @param account account address for which the balance of delegated Power Tokens is checked
    /// @return  Returns the amount of the Power Tokens owned by the `account` and delegated to the LiquidityMining contracts.
    function balanceOfPwTokenDelegatedToLiquidityMining(address account) external view returns (uint256);

    /// @notice Gets the rate of the fee from the configuration. This fee is applied when the owner of Power Tokens wants to unstake them immediately.
    /// @dev Fee value represented in as a percentage with 18 decimals
    /// @return value, a percentage represented with 18 decimal
    function getPwTokenUnstakeFee() external view returns (uint256);

    /// @notice Gets the state of the active cooldown for the sender.
    /// @dev If PowerTokenCoolDown contains only zeros it represents no active cool down.
    /// Struct containing information on when the cooldown end and what is the quantity of the Power Tokens locked.
    /// @param account account address that owns Power Tokens in the cooldown
    /// @return Object PowerTokenCoolDown represents active cool down
    function getPwTokensInCooldown(address account) external view returns (PwTokenCooldown memory);

    /// @notice Gets the power token cool down time in seconds.
    /// @return uint256 cool down time in seconds
    function getPwTokenCooldownTime() external view returns (uint256);

    /// @notice Calculates the internal exchange rate between the Staked Token and total supply of a base amount
    /// @return Current exchange rate between the Staked Token and the total supply of a base amount, represented with 18 decimals.
    function getPwTokenExchangeRate() external view returns (uint256);

    /// @notice Gets the total supply base amount
    /// @return total supply base amount, represented with 18 decimals
    function getPwTokenTotalSupplyBase() external view returns (uint256);
}

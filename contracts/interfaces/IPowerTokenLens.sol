// SPDX-License-Identifier: BSD-3-Clause
pragma solidity 0.8.16;
import "./types/PowerTokenTypes.sol";

interface IPowerTokenLens {

    /// @notice Gets the name of the Power Token
    /// @return Returns the name of the Power Token.
    function powerTokenName() external view returns (string memory);

    /// @notice Contract ID. The keccak-256 hash of "io.ipor.PowerToken" decreased by 1
    /// @return Returns the ID of the contract
    function getPowerTokenContractId() external view returns (bytes32);

    /// @notice Gets the symbol of the Power Token.
    /// @return Returns the symbol of the Power Token.
    function powerTokenSymbol() external view returns (string memory);

    /// @notice Returns the number of the decimals used by Power Token. By default it's 18 decimals.
    /// @return Returns the number of decimals: 18.
    function powerTokenDecimals() external view returns (uint8);

    /// @notice Gets the total supply of the Power Token.
    /// @dev Value is calculated in runtime using baseTotalSupply and internal exchange rate.
    /// @return Total supply of Power tokens, represented with 18 decimals
    function powerTokenTotalSupply() external view returns (uint256);

    /// @notice Gets the balance of Power Tokens for a given account
    /// @param account account address for which the balance of Power Tokens is fetched
    /// @return Returns the amount of the Power Tokens owned by the `account`.
    function powerTokenBalanceOf(address account) external view returns (uint256);

    /// @notice Gets the delegated balance of the Power Tokens for a given account.
    /// Tokens are delegated from PowerToken to LiquidityMining smart contract (reponsible for rewards distribution).
    /// @param account account address for which the balance of delegated Power Tokens is checked
    /// @return  Returns the amount of the Power Tokens owned by the `account` and delegated to the LiquidityMining contracts.
    function delegatedPowerTokensToLiquidityMiningBalanceOf(address account) external view returns (uint256);

    /// @notice Gets the rate of the fee from the configuration. This fee is applied when the owner of Power Tokens wants to unstake them immediately.
    /// @dev Fee value represented in as a percentage with 18 decimals
    /// @return value, a percentage represented with 18 decimal
    function getUnstakeWithoutCooldownFee() external view returns (uint256);

    /// @notice Gets the state of the active cooldown for the sender.
    /// @dev If PowerTokenTypes.PowerTokenCoolDown contains only zeros it represents no active cool down.
    /// Struct containing information on when the cooldown end and what is the quantity of the Power Tokens locked.
    /// @param account account address that owns Power Tokens in the cooldown
    /// @return Object PowerTokenTypes.PowerTokenCoolDown represents active cool down
    function getPowerTokenActiveCooldown(address account) external view returns (PowerTokenTypes.PwTokenCooldown memory);

    /// @notice Gets the power token cool down time in seconds.
    /// @return uint256 cool down time in seconds
    function powerTokenCoolDownTime() external view returns (uint256);

    /// @notice Calculates the internal exchange rate between the Staked Token and total supply of a base amount
    /// @return Current exchange rate between the Staked Token and the total supply of a base amount, represented with 18 decimals.
    function calculatePowerTokenExchangeRate() external view returns (uint256);

    /// @notice Gets the total supply base amount
    /// @return total supply base amount, represented with 18 decimals
    function totalPowerTokenSupplyBase() external view returns (uint256);
}

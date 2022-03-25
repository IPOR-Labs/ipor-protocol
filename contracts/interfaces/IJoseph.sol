// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.9;

/// @title Interface for interaction with Joseph - smart contract responsible
/// for managing ipTokens and ERC20 tokens in IPOR Protocol.
interface IJoseph {
    /// @notice Returns current version of Joseph's
    /// @return current Joseph version
    function getVersion() external pure returns (uint256);

    /// @notice Calculates ipToken exchange rate
    /// @dev exchange rate is a Liqudity Pool Balance and ipToken total supply ratio
    /// @return ipToken exchange rate for a specific asset
    function calculateExchangeRate() external view returns (uint256);

    /// @notice Function invoked to provide asset to Liquidity Pool in amount `assetValue`
    /// @dev Emits {ProvideLiquidity} event and transfers ERC20 tokens from sender to Milton,
    /// emits {Transfer} event from ERC20 asset, emits {Mint} event from ipToken
    /// in return transfers minted ipTokens to the sender. Volume of transferred ipTokens is based on current ipToken exchange rate
    /// @param assetValue volume of ERC20 tokens which are transferred from sender to Milton
    function provideLiquidity(uint256 assetValue) external;

    /// @notice Redeems `ipTokenVolume` IpTokens for underlying asset
    /// @dev Emits {Redeem} event, emits {Transfer} event from ERC20 asset, emits {Burn} event from ipToken,
    /// transfer asser ERC20 tokens from Milton to sender based on current exchange rate.
    /// @param ipTokenVolume redeem amount
    function redeem(uint256 ipTokenVolume) external;

    /// @notice Rebalances ERC20 balance between Milton and Stanley, based on configuration
    /// `_MILTON_STANLEY_BALANCE_PERCENTAGE` part of Milton balance is transferred to Stanley or vice versa.
    /// for more information refer to the documentation: https://ipor-labs.gitbook.io/ipor-labs/automated-market-maker/asset-management
    /// @dev Emits {Deposit} or {Withdraw} event from Stanley depends on current asset balance on Milton and Stanley. 
	/// @dev Emits {Mint} or {Burn} event from ivToken depends on current asset balance on Milton and Stanley. 
	/// @dev Emits {Transfer} from ERC20 asset.
    function rebalance() external;

    /// @notice Executes deposit underlying asset in the `amount` from Milton to Stanley
    /// @dev Emits {Deposit} event from Stanley, {Mint} event from ivToken, {Transfer} event from ERC20 asset.
    function depositToStanley(uint256 amount) external;

    /// @notice Executes withdraw underlying asset in the `amount` from Stanley to Milton
    /// @dev Emits {Withdraw} event from Stanley, {Burn} event from ivToken, {Transfer} event from ERC20 asset.
    function withdrawFromStanley(uint256 amount) external;

    /// @notice Transfers `amount` of asset from Miltons's Treasury Balance to Treasury (ie. external multisig wallet)
    /// Treasury's address is configured in `_treasury` field
    /// @dev Transfer can be requested by address defined in field `_treasuryManager`
    /// @dev Emits {Transfer} event from ERC20 asset
    /// @param amount asset amount transferred from Milton's Treasury Balance
    function transferToTreasury(uint256 amount) external;

    /// @notice Transfers amount of assetfrom Miltons's IPOR Publication Fee Balance to Charlie Treasurer account
    /// @dev Transfer can be requested by an address defined in field `_charlieTreasuryManager`,
    /// Emits {Transfer} event from ERC20 asset.
    /// @param amount asset amount transferred from Milton's IPOR Publication Fee Balance
    function transferToCharlieTreasury(uint256 amount) external;

    /// @notice Returns reserve ratio on Milton Asset Balance / (Milton Asset Balance + Stanley Asset Balance) for a given asset
    /// @return reserves ratio
    function checkVaultReservesRatio() external returns (uint256);

    /// @notice Pauses current smart contract, it can be executed only by the Owner
    /// @dev Emits {Paused} event from Joseph.
    function pause() external;

    /// @notice Unpauses current smart contract, it can be executed only by the Owner
    /// @dev Emits {Unpaused} event from Joseph.
    function unpause() external;

    /// @notice Emitted when `from` account provides liquidity to Milton Liquidity Pool
    event ProvideLiquidity(
        /// @notice moment when liquidity is provided by `from` account
        uint256 timestamp,
        /// @notice user who provide liquidity, `from` account are transferred asset tokens to `to` account
        address from,
        /// @notice Milton address where liquidity is provided, to this account asset tokens are transferred from sender `to`
        address to,
        /// @notice actual IP Token exchange rate
        /// @dev value represented in 18 decimals
        uint256 exchangeRate,
        /// @notice asset amount which was provided by user to Milton liquidity pool
        /// @dev value represented in 18 decimals
        uint256 assetValue,
        /// @notice ipToken value corresponding to `assetValue` and `excangeRate`
        /// @dev value represented in 18 decimals
        uint256 ipTokenValue
    );

    /// @notice Emitted when `to` accound executes redeem ipTokens
    event Redeem(
        /// @notice moment when IP Tokens were redeemed by `to` account
        uint256 timestamp,
        /// @notice Milton address from asset tokens are transferred to `to` account
        address from,
        /// @notice sender account where underlying asset tokens are transferred after redeem
        address to,
        /// @notice IP Token exchange rate used for calculating `assetValue`
        /// @dev value represented in 18 decimals
        uint256 exchangeRate,
        /// @notice underlying asset value calculated based on `exchangeRate` and `ipTokenValue`
        /// @dev value represented in 18 decimals
        uint256 assetValue,
        /// @notice redeemed IP Token value
        /// @dev value represented in 18 decimals
        uint256 ipTokenValue,
        /// @notice underlying asset fee taken for redeeming
        /// @dev value represented in 18 decimals
        uint256 redeemFee,
        /// @notice final asset value transferred from Milton to `to` / sender account, substraction assetValue - redeemFee
        /// @dev value represented in 18 decimals
        uint256 redeemValue
    );
}

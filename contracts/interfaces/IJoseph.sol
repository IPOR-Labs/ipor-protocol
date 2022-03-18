// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.9;

/// @title Interface to interaction with Joseph, smart contract responsible for managin IP Tokens and ERC20 tokens in IPOR Protocol.
interface IJoseph {
    /// @notice Returns current Joseph smart contract version
    /// @return current Joseph version
    function getVersion() external pure returns (uint256);

    function calculateExchangeRate() external view returns (uint256);

    /// @notice Provides `assetValue` asset tokens to Liquidity Pool
    /// @dev Emits `ProvideLiquidity` event, and transfer asset ERC20 tokens from sender to Milton,
    /// and transfer minted IpTokens to sender, volume transfered IpTokens is based on current exchange rate
    /// @param assetValue volume of asset ERC20 tokens which is transfered from sender to Milton
    function provideLiquidity(uint256 assetValue) external;

    /// @notice Redeems `ipTokenVolume` IpTokens from Milton
    /// @dev Emits `Redeem` event, transfer asser ERC20 tokens from Milton to sender based on current exchange rate.
    /// @param ipTokenVolume redeeme by sender from Milton
    function redeem(uint256 ipTokenVolume) external;

    /// @notice Rebalances asset ERC20 balance between Milton and Stanley, where based on configuration
    /// `_MILTON_STANLEY_BALANCE_PERCENTAGE` part of Milton balance is transfered to Stanley or vice versa.
    /// @dev Emits `Stanley-Deposit` event or `Stanley-Withdraw` depends on current asset balance in Milton and Stanley site.
    function rebalance() external;

    /// @notice Executes deposit underlying asset `amount` from Milton to Stanley
    /// @dev Emits `Stanley-Deposit` event
    function depositToStanley(uint256 amount) external;

    /// @notice Executes withdraw underlying asset `amount` from Stanley to Milton
    /// @dev Emits `Stanley-Withdraw` event
    function withdrawFromStanley(uint256 amount) external;

    /// @notice Transfers asset value from Miltons's Treasury Balance to Treasury Treaserer
    /// account configured in `_treasury` field
    /// @dev Transfer can be requested by account address which is defined in field `_treasuryManager`
    /// @dev Emits `ERC20-Transfer` event
    /// @param amount asset volume which will be transfered from Milton's Treasury Balance
    function transferToTreasury(uint256 amount) external;

    /// @notice Transfers asset value from Miltons's Ipor Publication Fee Balance to Charlie Treaserer account
    /// @dev Transfer can be requested by account address which is defined in field `_charlieTreasuryManager`,
    /// Emits `ERC20-Transfer` event
    /// @param amount asset volume which will be transfered from Milton's IPOR Publication Fee Balance
    function transferToCharlieTreasury(uint256 amount) external;

    /// @notice Returns reserve ratio Milton Asset Balance / (Milton Asset Balance + Stanley Asset Balance) for a given asset
    /// @return reserves ratio
    function checkVaultReservesRatio() external returns (uint256);

    /// @notice Pauses current smart contract, can be executed only by Owner
    /// @dev Emits `Paused` event.
    function pause() external;

    /// @notice Unpauses current smart contract, can be executed only by Owner
    /// @dev Emits `Unpaused` event.
    function unpause() external;

    /// @notice Emitted when `from` account provide liquidity to Milton Liquidity Pool
    event ProvideLiquidity(
        /// @notice moment when liquidity is provided by `from` account
        uint256 timestamp,
        /// @notice user who provide liquidity, `from` account are transfered asset tokens to `to` account
        address from,
        /// @notice Milton address where liquidity is provided, to this account asset tokens are transfered from sender `to`
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

    /// @notice Emitted when `to` accound execute redeem IP tokens
    event Redeem(
        /// @notice moment when IP Tokens were redeemed by `to` account
        uint256 timestamp,
        /// @notice Milton address from asset tokens are transfered to `to` account
        address from,
        /// @notice sender account where underlying asset tokens are transfered after redeem
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
        /// @notice final asset value transfered from Milton to `to` / sender account, substraction assetValue - redeemFee
        /// @dev value represented in 18 decimals
        uint256 redeemValue
    );
}

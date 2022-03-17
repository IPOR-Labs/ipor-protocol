// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.9;

/// @title Interface to interaction with Joseph, smart contract responsible for managin IP Tokens and ERC20 tokens in IPOR Protocol.
interface IJoseph {
    /// @notice Returns current Joseph smart contract version
    /// @return current Joseph version
    function getVersion() external pure returns (uint256);

    /// @notice Provides `amount` asset tokens to Liquidity Pool
    /// @dev Emits `ProvideLiquidity` event, and transfer asset ERC20 tokens from sender to Milton,
    /// and transfer minted IpTokens to sender, volume transfered IpTokens is based on current exchange rate
    /// @param amount volume of asset ERC20 tokens which is transfered from sender to Milton
    function provideLiquidity(uint256 amount) external;

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
    /// account configured in `_treasuryTreasurer` field
    function transferToTreasury(uint256 amount) external;

    //@notice Transfers asset value from Miltons's Ipor Publication Fee Balance to Charlie Treaserer account
    function transferPublicationFee(uint256 assetValue) external;

    function checkVaultReservesRatio() external returns (uint256);

    function pause() external;

    function unpause() external;

    event ProvideLiquidity(
        uint256 timestamp,
        address from,
        address to,
        uint256 exchangeRate,
        uint256 assetValue,
        uint256 ipTokenValue
    );
    event Redeem(
        uint256 timestamp,
        address from,
        address to,
        uint256 exchangeRate,
        uint256 assetValue,
        uint256 ipTokenValue,
        uint256 redeemFee,
        uint256 redeemValue
    );
}

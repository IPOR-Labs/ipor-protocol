// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.9;

/// @title Interface for interaction with Joseph. Administration part.
interface IJosephInternal {
    /// @notice Returns current version of Joseph's
    /// @return current Joseph version
    function getVersion() external pure returns (uint256);

    /// @notice Gets asset / underlying token / stablecoin which is assocciated with this Joseph instance
    /// @return asset / underlying token / stablecoin address
    function getAsset() external view returns (address);

    /// @notice Gets redeem fee percentage config param which is used in calculation redeem fee taken by Joseph when trader redeem his ipTokens
    /// @return redeem fee percentage represented in 18 decimals
    function getRedeemFeePercentage() external pure returns (uint256);

    /// @notice Gets redeem Liquidity Pool max utilization percentage config param which is used by Joseph to validate Liquidity Pool utilization rate treshold during redeeming ipTokens by trader.
    /// @return redeem Liquidity Pool max utilization percentage
    function getRedeemLpMaxUtilizationPercentage() external pure returns (uint256);

    /// @notice Gets balance ratio config param presented in percentages in 18 decimals between Milton and Stanley
    /// @return gets balance ratio config param between Milton and Stanley
    function getMiltonStanleyBalanceRatioPercentage() external pure returns (uint256);

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

    /// @notice Pauses current smart contract, it can be executed only by the Owner
    /// @dev Emits {Paused} event from Joseph.
    function pause() external;

    /// @notice Unpauses current smart contract, it can be executed only by the Owner
    /// @dev Emits {Unpaused} event from Joseph.
    function unpause() external;

    /// @notice Gets Treasury address, external multisig wallet where Milton Treasury balance is transferred.
    /// @dev Part of opening fee goes to Milton Treasury balance and from time to time is transfered to multisig wallet Treasury
    /// @return Treasury address
    function getTreasury() external view returns (address);

    /// @notice Sets Charlie Treasury address
    /// @param newCharlieTreasury new Charlie Treasury address
    function setCharlieTreasury(address newCharlieTreasury) external;

    /// @notice Sets Treasury address
    /// @param newTreasury new Treasury address
    function setTreasury(address newTreasury) external;

    /// @notice Gets Charlie Treasury Manager address, external multisig address which has permission to transfer Charlie Treasury balance from Milton to external Charlie Treausyr wallet.
    /// @return Charlie Treasury Manager address
    function getCharlieTreasuryManager() external view returns (address);

    /// @notice Sets Charlie Treasury Manager address
    /// @param newCharlieTreasuryManager new Charlie Treasury Manager address
    function setCharlieTreasuryManager(address newCharlieTreasuryManager) external;

    /// @notice Gets Charlie Treasury address, external multisig wallet where Milton IPOR publication fee balance is transferred.
    /// @return Charlie Treasury address
    function getCharlieTreasury() external view returns (address);

    /// @notice Gets Treasury Manager address, external multisig address which has permission to transfer Treasury balance from Milton to external Treausry wallet.
    /// @return Treasury Manager address
    function getTreasuryManager() external view returns (address);

    /// @notice Sets Treasury Manager address
    /// @param newTreasuryManager new Treasury Manager address
    function setTreasuryManager(address newTreasuryManager) external;

    /// @notice Emmited when Charlie Treasury address changed to new one
    /// @param changedBy account address who changed Charlie Treasury address
    /// @param oldCharlieTreasury old Charlie Treasury address
    /// @param newCharlieTreasury new Charlie Treasury address
    event CharlieTreasuryChanged(
        address indexed changedBy,
        address indexed oldCharlieTreasury,
        address indexed newCharlieTreasury
    );

    /// @notice Emmited when Charlie Treasury Manager address changed to new one.
    /// @param changedBy account address who changed Charlie Treasury Manager address
    /// @param oldCharlieTreasuryManager old Charlie Treasury Manager address
    /// @param newCharlieTreasuryManager new Charlie Treasury Manager address
    event CharlieTreasuryManagerChanged(
        address indexed changedBy,
        address indexed oldCharlieTreasuryManager,
        address indexed newCharlieTreasuryManager
    );

    /// @notice Emmited when Treasury Manager address was changed
    /// @param changedBy account address who changed Treasury Manager address
    /// @param oldTreasuryManager old Treasury Manager address
    /// @param newTreasuryManager new Treasury Manager address
    event TreasuryManagerChanged(
        address indexed changedBy,
        address indexed oldTreasuryManager,
        address indexed newTreasuryManager
    );

    /// @notice Emmited when Treasury address changed
    /// @param changedBy account address who changed Treasury address
    /// @param oldTreasury old Treasury address
    /// @param newTreasury new Treasury address
    event TreasuryChanged(
        address indexed changedBy,
        address indexed oldTreasury,
        address indexed newTreasury
    );
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.16;

/// @title Administrative interface for interaction with Joseph.
interface IJosephInternal {
    /// @notice Gets redeem Liquidity Pool max utilization rate config param which is used by Joseph to validate
    /// Liquidity Pool utilization rate threshold during redemption of ipTokens by the trader.
    /// @return redeem Liquidity Pool max utilization rate
    function getRedeemLpMaxUtilizationRate() external pure returns (uint256);


    /// @notice Rebalances ERC20 balance between Milton and Stanley, based on configuration
    /// `_MILTON_STANLEY_BALANCE_RATIO` part of Milton balance is transferred to Stanley or vice versa.
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

    /// @notice Executes withdraw underlying asset in the `amount` from Stanley to Milton
    /// @dev Emits {Withdraw} event from Stanley, {Burn} event from ivToken, {Transfer} event from ERC20 asset.
    function withdrawAllFromStanley() external;

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

    /// @notice Gets Treasury address, external multisig wallet where Milton Treasury balance is transferred.
    /// @dev Part of opening fee goes to Milton Treasury balance and from time to time is transfered to multisig wallet Treasury
    /// @return Treasury address
    function getTreasury() external view returns (address);

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

    /// @notice Sets Charlie Treasury address
    /// @param newCharlieTreasury new Charlie Treasury address
    function setCharlieTreasury(address newCharlieTreasury) external;

    /// @notice Gets Treasury Manager address, external multisig address which has permission to transfer Treasury balance from Milton to external Treausry wallet.
    /// @return Treasury Manager address
    function getTreasuryManager() external view returns (address);

    /// @notice Sets Treasury Manager address
    /// @param newTreasuryManager new Treasury Manager address
    function setTreasuryManager(address newTreasuryManager) external;

    /// @notice adds new address allowed to rebalance Milton and Stanley
    /// @param appointed new address allowed to rebalance Milton and Stanley
    function addAppointedToRebalance(address appointed) external;

    /// @notice deactivate address allowed to rebalance Milton
    /// @param appointed address to deactivate
    function removeAppointedToRebalance(address appointed) external;

    /// @notice check if address is allowed to rebalance Milton
    function isAppointedToRebalance(address appointed) external view returns (bool);

    /// @notice Gets auto rebalance threshold
    /// @dev Auto rebalance threshold is a value which is used to determine if rebalance between Milton and Stanley should be executed.
    /// @return auto rebalance threshold, represented in 18 decimals.
    function getAutoRebalanceThreshold() external view returns (uint256);

    /// @notice Sets auto rebalance threshold between Milton and Stanley.
    /// @param newAutoRebalanceThreshold new auto rebalance threshold. Notice! Value represented without decimals. The value represents multiples of 1000.
    function setAutoRebalanceThreshold(uint256 newAutoRebalanceThreshold) external;

    /// @notice Emmited after the auto rebalance threshold has changed
    /// @param changedBy account address that changed auto rebalance threshold
    /// @param oldAutoRebalanceThresholdInThousands Old auto rebalance threshold, represented in 18 decimals
    /// @param newAutoRebalanceThresholdInThousands New auto rebalance threshold, represented in 18 decimals
    event AutoRebalanceThresholdChanged(
        address indexed changedBy,
        uint256 indexed oldAutoRebalanceThresholdInThousands,
        uint256 indexed newAutoRebalanceThresholdInThousands
    );
}

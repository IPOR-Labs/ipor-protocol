// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.16;

/// @title Administrative interface for interaction with Joseph.
interface IJosephInternal {
    /// @notice Returns current version of Joseph
	/// @dev Increase number when implementation inside source code is different that implementation deployed on Mainnet
    /// @return Joseph's current version
    function getVersion() external pure returns (uint256);

    /// @notice Gets asset - underlying ERC20 token which is assocciated with this Joseph instance
    /// @return ERC20 token address
    function getAsset() external view returns (address);

    /// @notice Gets the redeem fee rate - config param used in calculation of redeem fee applied by Joseph when trader redeems his ipTokens.
    /// @return redeem fee rate represented in 18 decimals
    function getRedeemFeeRate() external pure returns (uint256);

    /// @notice Gets redeem Liquidity Pool max utilization rate config param which is used by Joseph to validate
    /// Liquidity Pool utilization rate treshold during redemption of ipTokens by the trader.
    /// @return redeem Liquidity Pool max utilization rate
    function getRedeemLpMaxUtilizationRate() external pure returns (uint256);

    /// @notice Gets balance ratio config param presented ratio in 18 decimals between Milton and Stanley
    /// @return gets balance ratio config param between Milton and Stanley
    function getMiltonStanleyBalanceRatio() external view returns (uint256);

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

    /// @notice Gets max Liquidity Pool balance
    /// @return max Liquidity Pool balance. Value represented without decimals.
    function getMaxLiquidityPoolBalance() external view returns (uint256);

    /// @notice Sets max Liquidity Pool balance
    /// @param newMaxLiquidityPoolBalance new max liquidity pool balance
    /// @dev Value represented without decimals
    function setMaxLiquidityPoolBalance(uint256 newMaxLiquidityPoolBalance) external;

    /// @notice Gets max Liquidity Pool account contribution amount
    /// @return max Liquidity Pool account contribution amount. Value represented without decimals.
    function getMaxLpAccountContribution() external view returns (uint256);

    /// @notice Sets max Liquidity Pool account contribution amount
    /// @param newMaxLpAccountContribution new max liquidity pool account contribution amount
    /// @dev Value represented without decimals.
    function setMaxLpAccountContribution(uint256 newMaxLpAccountContribution) external;

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
    /// @param oldTreasuryManager Treasury's old Manager address
    /// @param newTreasuryManager Treasury's new Manager address
    event TreasuryManagerChanged(
        address indexed changedBy,
        address indexed oldTreasuryManager,
        address indexed newTreasuryManager
    );

    /// @notice Emmited after the Treasury address has changed
    /// @param changedBy account address that changed Treasury address
    /// @param oldTreasury Treasury's old address
    /// @param newTreasury Treasury's new address
    event TreasuryChanged(
        address indexed changedBy,
        address indexed oldTreasury,
        address indexed newTreasury
    );

    /// @notice Emmited after the max liquidity pool balance has changed
    /// @param changedBy account address that changed max liquidity pool balance
    /// @param oldMaxLiquidityPoolBalance Old max liquidity pool balance, represented in 18 decimals
    /// @param newMaxLiquidityPoolBalance New max liquidity pool balance, represented in 18 decimals
    event MaxLiquidityPoolBalanceChanged(
        address indexed changedBy,
        uint256 indexed oldMaxLiquidityPoolBalance,
        uint256 indexed newMaxLiquidityPoolBalance
    );

    /// @notice Emmited after the max liquidity pool account contribution amount has changed
    /// @param changedBy account address that changed max liquidity pool account contribution amount
    /// @param oldMaxLpAccountContribution Old max liquidity pool account contribution amount, represented in 18 decimals
    /// @param newMaxLpAccountContribution New max liquidity pool account contribution amount, represented in 18 decimals
    event MaxLpAccountContributionChanged(
        address indexed changedBy,
        uint256 indexed oldMaxLpAccountContribution,
        uint256 indexed newMaxLpAccountContribution
    );
}

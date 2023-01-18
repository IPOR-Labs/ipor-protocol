// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.16;

import "./types/IporTypes.sol";
import "./types/AmmTypes.sol";
import "./types/MiltonTypes.sol";

/// @title Interface for interaction with Milton, smart contract resposnible for issuing and closing interest rate swaps also known as Automated Market Maker - administrative part.
interface IMiltonInternal {
    /// @notice Returns current version of Milton
    /// @dev Increase number when implementation inside source code is different that implementation deployed on Mainnet
    /// @return Current Milton's version
    function getVersion() external pure returns (uint256);

    /// @notice Gets asset assocciated with this Milton instance. (each Milton instance is scoped per asset)
    /// @return asset's address
    function getAsset() external view returns (address);

    /// @notice Gets address of IporOracle contract.
    /// @dev IporOracle is used to calculate the AccruedIbtPrice that is used to come up with the payoffs of the pay/receive fixed leg.
    /// @return IporOracle address
    function getIporOracle() external view returns (address);

    /// @notice Gets address of MiltonStorage
    /// @dev MiltonSttrage is used to account for Milton's balances on Stanley deposits/withdrawals and to calculate the SOAP.
    /// @return MiltonStorage address
    function getMiltonStorage() external view returns (address);

    /// @notice Gets address of Stanley used by Milton
    /// @dev Stanley is Milton's asset manager (deposits/withdrawals into/from external money markets)
    /// @return Stanley address used by Milton
    function getStanley() external view returns (address);

    /// @notice Gets max swap's collateral amount value.
    /// @dev Param used in swap validation.
    /// @return max swap's collateral amount represented in 18 decimals
    function getMaxSwapCollateralAmount() external view returns (uint256);

    /// @notice Gets max allowed liquidity pool utilization rate.
    /// @dev Param used in swap validation.
    /// @return max liquidity pool utilization rate represented in 18 decimals
    function getMaxLpUtilizationRate() external view returns (uint256);

    /// @notice Gets max liquidity pool utilization per leg.
    /// @dev Param used in swap validation.
    /// @return max Liquidity Pool Utilization Per Leg rate represented in 18 decimals
    function getMaxLpUtilizationPerLegRate() external view returns (uint256);

    /// @notice Gets income fee rate.
    /// @dev Param used when closing the swap. When trader earns then fee is deducted from accrued profit.
    /// @return income fee rate param value represented in 18 decimals
    function getIncomeFeeRate() external view returns (uint256);

    /// @notice Gets opening fee rate. When the trader opens swap position then fee is charged from the amount used to open the swap.
    /// Opening fee amount is split and transfered in part to Liquidity Pool and to Milton Treasury
    /// @dev Param is used during swap opening.
    /// @return opening fee rate represented in 18 decimals
    function getOpeningFeeRate() external view returns (uint256);

    /// @notice Gets opening fee rate used to calculate the part of the fee transferred to the Treasury. When the trader opens a position then fee is deducted from the collateral.
    /// Opening fee amount is split and transfered in part to Liquidity Pool and to Milton Treasury
    /// This param defines the proportion how the fee is divided and distributed to either liquidity pool or threasury
    /// @dev Param used in swap opening.
    /// @return opening fee for treasury rate is represented in 18 decimals
    function getOpeningFeeTreasuryPortionRate() external view returns (uint256);

    /// @notice Gets IPOR publication fee. When swap is opened then publication fee is charged. This fee is intended to subsidize the publication of IPOR.
    /// IPOR publication fee is deducted from the total amount used to open the swap.
    /// @dev Param used in swap opening.
    /// @return IPOR publication fee is represented in 18 decimals
    function getIporPublicationFee() external view returns (uint256);

    /// @notice Gets liquidation deposit. When the swap is opened then liquidation deposit is deducted from the amount used to open the swap.
    /// Deposit is refunded to whoever closes the swap: either the buyer or the liquidator.
    /// @return liquidation deposit is represented without decimals
    function getLiquidationDepositAmount() external view returns (uint256);

    /// @notice Gets liquidation deposit. When the swap is opened then liquidation deposit is deducted from the amount used to open the swap.
    /// Deposit is refunded to whoever closes the swap: either the buyer or the liquidator.
    /// @return liquidation deposit is represented in 18 decimals
    function getWadLiquidationDepositAmount() external view returns (uint256);

    /// @notice Gets max leverage value.
    /// @dev Param used in swap validation.
    /// @return max leverage value represented in 18 decimals
    function getMaxLeverage() external view returns (uint256);

    /// @notice Gets min leverage value.
    /// @dev Param used in swap validation.
    /// @return min leverage value represented in 18 decimals
    function getMinLeverage() external view returns (uint256);

    /// @notice Gets Milton's balances including balance held by Stanley in external protocols.
    /// @dev Balances including sum of all collateral for Pay-Fixed and  Receive-Fixed legs,
    /// liquidity pool balance, and vault balance held by Stanley.
    /// @return Milton Balance structure `IporTypes.MiltonBalancesMemory`.
    function getAccruedBalance() external view returns (IporTypes.MiltonBalancesMemory memory);

    /// @notice Calculates SOAP at given timestamp.
    /// @dev returned values represented in 18 decimals
    /// @param calculateTimestamp epoch timestamp at which SOAP is computed.
    /// @return soapPayFixed SOAP for Pay-Fixed leg.
    /// @return soapReceiveFixed SOAP for Receive-Fixed leg.
    /// @return soap total SOAP, sum of Pay Fixed and Receive Fixed SOAP.
    function calculateSoapAtTimestamp(uint256 calculateTimestamp)
        external
        view
        returns (
            int256 soapPayFixed,
            int256 soapReceiveFixed,
            int256 soap
        );

    /// @notice Calculats Pay-Fixed Swap payoff for a given Swap structure.
    /// @param swap `IporTypes.IporSwapMemory` structure
    /// @return Pay-Fixed Swap payoff, can be negative, represented in 18 decimals.
    /// @dev absolute value cannot be higher than the collateral
    function calculatePayoffPayFixed(IporTypes.IporSwapMemory memory swap)
        external
        view
        returns (int256);

    /// @notice Calculats Receive-Fixed swap payoff for a given Swap structure.
    /// @param swap `IporTypes.IporSwapMemory` structure
    /// @return Receive Fixed Swap payoff, can be negative, represented in 18 decimals.
    /// @dev absolute value cannot be higher than the collateral
    function calculatePayoffReceiveFixed(IporTypes.IporSwapMemory memory swap)
        external
        view
        returns (int256);

    /// @notice Transfers the assets from Milton to Stanley. Action available only to Joseph.
    /// @dev Milton balance in storage is not changing after this deposit, balance of ERC20 assets on Milton is changing as they get transfered to Stanley.
    /// @dev Emits {Deposit} event from Stanley, emits {Transfer} event from ERC20, emits {Mint} event from ivToken
    /// @param assetAmount amount of asset
    function depositToStanley(uint256 assetAmount) external;

    /// @notice Transfers the assets from Stanley to Milton. Action available only for Joseph.
    /// @dev Milton balance in storage is not changing, balance of ERC20 assets of Milton is changing.
    /// @dev Emits {Withdraw} event from Stanley, emits {Transfer} event from ERC20 asset, emits {Burn} event from ivToken
    /// @param assetAmount amount of assets
    function withdrawFromStanley(uint256 assetAmount) external;

    /// @notice Transfers assets (underlying tokens / stablecoins) from Stanley to Milton. Action available only for Joseph.
    /// @dev Milton Balance in storage is not changing after this wi, balance of ERC20 assets on Milton is changing.
    /// @dev Emits {Withdraw} event from Stanley, emits {Transfer} event from ERC20 asset, emits {Burn} event from ivToken
    function withdrawAllFromStanley() external;

    /// @notice Closes Pay-Fixed swap for a given ID in "emergency mode". Action available only to the Owner.
    /// @dev Emits {CloseSwap} event from Milton, {Transfer} event from ERC20 asset.
    /// @param swapId Pay-Fixed swap ID
    function emergencyCloseSwapPayFixed(uint256 swapId) external;

    /// @notice Closes Receive-Fixed swap for a given ID in emergency mode. Action available only to the Owner.
    /// @dev Emits {CloseSwap} event from Milton, {Transfer} event from ERC20 asset.
    /// @param swapId Receive Fixed Swap ID
    function emergencyCloseSwapReceiveFixed(uint256 swapId) external;

    /// @notice Closes Pay-Fixed swaps for a given list of IDs in emergency mode. Action available only to the Owner.
    /// @dev Emits {CloseSwap} events from Milton, {Transfer} events from ERC20 asset.
    /// @param swapIds List of Pay Fixed swaps.
    /// @return closedSwaps list of structures with information if particular swapId was closed in this execution (isClosed = true) or not (isClosed = false)
    function emergencyCloseSwapsPayFixed(uint256[] memory swapIds)
        external
        returns (MiltonTypes.IporSwapClosingResult[] memory closedSwaps);

    /// @notice Closes Receive-Fixed swaps for given list of IDs in emergency mode. Action available only to the Owner.
    /// @dev Emits {CloseSwap} events from Milton, {Transfer} events from ERC20 asset.
    /// @param swapIds List of Receive-Fixed swap IDs.
    /// @return closedSwaps list of structures with information if particular swapId was closed in this execution (isClosed = true) or not (isClosed = false)
    function emergencyCloseSwapsReceiveFixed(uint256[] memory swapIds)
        external
        returns (MiltonTypes.IporSwapClosingResult[] memory closedSwaps);

    /// @notice Pauses current smart contract, it can be executed only by the Owner
    /// @dev Emits {Paused} event from Milton.
    function pause() external;

    /// @notice Unpauses current smart contract, it can be executed only by the Owner
    /// @dev Emits {Unpaused} event from Milton.
    function unpause() external;

    /// @notice sets max allowance for a given spender. Action available only for Owner.
    /// @param spender account which will have rights to transfer ERC20 underlying assets on behalf of Milton
    function setupMaxAllowanceForAsset(address spender) external;

    /// @notice Gets Joseph's address.
    /// @return Joseph address
    function getJoseph() external view returns (address);

    /// @notice Sets Joseph address. Function available only to the Owner.
    /// @param newJoseph new Joseph address
    function setJoseph(address newJoseph) external;

    /// @notice Gets Milton Spread Model smart contract address (contract responsible for spread calculation).
    /// @return Milton Spread model smart contract address
    function getMiltonSpreadModel() external view returns (address);

    /// @notice Sets Milton Spread Model smart contract address (contract responsible for spread calculation).
    /// @param newMiltonSpreadModel new Milton Spread Model address
    function setMiltonSpreadModel(address newMiltonSpreadModel) external;

    /// @notice Sets new treshold for auto update of ipor index. Function available only to the Owner.
    /// @param newThreshold new treshold for auto update of IPOR Index. Notice! Value represented without decimals. The value represents multiples of 1000.
    function setAutoUpdateIporIndexThreshold(uint256 newThreshold) external;

    /// @notice Gets treshold for auto update of ipor index.
    /// @return treshold for auto update of IPOR Index. Represented in 18 decimals.
    function getAutoUpdateIporIndexThreshold() external view returns (uint256);

    /// @notice Emmited when Joseph's address is changed by its owner.
    /// @param changedBy account address that has changed Joseph's address
    /// @param oldJoseph Joseph's old address
    /// @param newJoseph Joseph's new address
    event JosephChanged(
        address indexed changedBy,
        address indexed oldJoseph,
        address indexed newJoseph
    );

    /// @notice Emmited when MiltonSpreadModel's address is changed by its owner.
    /// @param changedBy account address that has changed Joseph's address
    /// @param oldMiltonSpreadModel MiltonSpreadModel's old address
    /// @param newMiltonSpreadModel MiltonSpreadModel's new address
    event MiltonSpreadModelChanged(
        address indexed changedBy,
        address indexed oldMiltonSpreadModel,
        address indexed newMiltonSpreadModel
    );

    /// @notice Emmited when AutoUpdateIporIndexThreshold is changed by its owner.
    /// @param changedBy account address that has changed AutoUpdateIporIndexThreshold
    /// @param oldAutoUpdateIporIndexThreshold AutoUpdateIporIndexThreshold's old value
    /// @param newAutoUpdateIporIndexThreshold AutoUpdateIporIndexThreshold's new value
    event AutoUpdateIporIndexThresholdChanged(
        address indexed changedBy,
        uint256 indexed oldAutoUpdateIporIndexThreshold,
        uint256 indexed newAutoUpdateIporIndexThreshold
    );
}

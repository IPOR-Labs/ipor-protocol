// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.9;

import "./types/IporTypes.sol";
import "./types/AmmTypes.sol";
import "./types/MiltonTypes.sol";

/// @title Interface for interaction with Milton, smart contract resposnible for working Automated Market Maker, administration part.
interface IMiltonInternal {
    /// @notice Returns current version of Milton's.
    /// @return Current Milton version.
    function getVersion() external pure returns (uint256);

    /// @notice Gets asset / underlying token / stablecoin which is assocciated with this Joseph instance
    /// @return asset / underlying token / stablecoin address
    function getAsset() external view returns (address);

    /// @notice Gets max swap collateral amount param value.
    /// @dev Param used in validation upcoming opened swap.
    /// @return max swap collateral amount represented in 18 decimals
    function getMaxSwapCollateralAmount() external pure returns (uint256);

    /// @notice Gets max Liquidity Pool Utilization rate param value.
    /// @dev Param used in validation upcoming opened swap.
    /// @return max Liquidity Pool Utilization rate represented in 18 decimals
    function getMaxLpUtilizationRate() external pure returns (uint256);

    /// @notice Gets max Liquidity Pool Utilization Per Leg rate param value.
    /// @dev Param used in validation upcoming opened swap.
    /// @return max Liquidity Pool Utilization Per Leg rate represented in 18 decimals
    function getMaxLpUtilizationPerLegRate() external pure returns (uint256);

    /// @notice Gets Income Fee rate param value.
    /// @dev Param used in closing swap. When trader earn then Milton takes fee from interest.
    /// @return income fee rate param value represented in 18 decimals
    function getIncomeFeeRate() external pure returns (uint256);

    /// @notice Gets Opening Fee rate param value. When trader open position then Milton takes fee from collateral.
    /// Opening fee amount is divided and transfered to Liquidity Pool and to Milton Treasury
    /// @dev Param used in opening swap.
    /// @return opening fee rate param value represented in 18 decimals
    function getOpeningFeeRate() external pure returns (uint256);

    /// @notice Gets Opening Fee For Treasury rate param value. When trader open position then Milton takes fee from collateral.
    /// Opening fee amount is divided and transfered to Liquidity Pool and to Milton Treasury.
    /// Opening Fee For Treasury define ration of Opening Fee transfered to Milton Treasury.
    /// @dev Param used in opening swap.
    /// @return opening fee for treasury rate param value represented in 18 decimals
    function getOpeningFeeTreasuryPortionRate() external pure returns (uint256);

    /// @notice Gets IPOR publication fee amount param. When trader open position then Milton takes
    /// IPOR publication fee amount from total amount invested by trader.
    /// @dev Param used in opening swap.
    /// @return IPOR publication fee amount value represented in 18 decimals
    function getIporPublicationFee() external pure returns (uint256);

    /// @notice Gets liquidation deposit amount param. When trader open position then liquidation deposit amount is transfered from trader to Milton. This cash is intended to liquidator.
    /// @return liquidation deposit amount represented in 18 decimals
    function getLiquidationDepositAmount() external pure returns (uint256);

    /// @notice Gets max leverage value param.
    /// @dev Param used in validation upcoming opened swap.
    /// @return max leverage value represented in 18 decimals
    function getMaxLeverage() external pure returns (uint256);

    /// @notice Gets min leverage value param.
    /// @dev Param used in validation upcoming opened swap.
    /// @return min leverage value represented in 18 decimals
    function getMinLeverage() external pure returns (uint256);

    /// @notice Gets Milton's balances accrued with amounts which was earned by Stanley in external Protocols.
    /// @dev Balances includes total collateral for Pay Fixed leg and for Receive Fixed leg,
    /// includes Liquidity Pool Balance, and vault balance transferred to Stanley.
    /// @return Milton Balance structure `IporTypes.MiltonBalancesMemory`.
    function getAccruedBalance() external view returns (IporTypes.MiltonBalancesMemory memory);

    /// @notice Calculates SOAP in given moment.
    /// @dev return values represented in 18 decimals
    /// @param calculateTimestamp epoch timestamp for which SOAP is computed.
    /// @return soapPayFixed SOAP for Pay Fixed leg.
    /// @return soapReceiveFixed SOAP for Receive Fixed leg.
    /// @return soap total SOAP, sum of Pay Fixed and Receive Fixed SOAP.
    function calculateSoapAtTimestamp(uint256 calculateTimestamp)
        external
        view
        returns (
            int256 soapPayFixed,
            int256 soapReceiveFixed,
            int256 soap
        );

    /// @notice Calculats Pay Fixed Swap Value for a given Swap structure.
    /// @param swap `IporTypes.IporSwapMemory` structure
    /// @return Pay Fixed Swap value, can be negative, represented in 18 decimals.
    /// @dev absolute value cannot be higher than collateral for this particular swap
    function calculateSwapPayFixedValue(IporTypes.IporSwapMemory memory swap)
        external
        view
        returns (int256);

    /// @notice Calculats Receive Fixed Swap Value for a given Swap structure.
    /// @param swap `IporTypes.IporSwapMemory` structure
    /// @return Receive Fixed Swap value, can be negative, represented in 18 decimals.
    /// @dev absolute value cannot be higher than collateral for this particular swap
    function calculateSwapReceiveFixedValue(IporTypes.IporSwapMemory memory swap)
        external
        view
        returns (int256);

    /// @notice Transfers assets (underlying tokens / stablecoins) from Milton to Stanley. Action available only for Joseph.
    /// @dev Milton Balance in storage is not changing after this deposit, balance of ERC20 assets on Milton is changing.
    /// @dev Emits {Deposit} event from Stanley, emits {Transfer} event from ERC20 asset, emits {Mint} event from ivToken
    /// @param assetAmount amount of assets
    function depositToStanley(uint256 assetAmount) external;

    /// @notice Transfers assets (underlying tokens / stablecoins) from Milton to Stanley. Action available only for Joseph.
    /// @dev Milton Balance in storage is not changing after this wi, balance of ERC20 assets on Milton is changing.
    /// @dev Emits {Withdraw} event from Stanley, emits {Transfer} event from ERC20 asset, emits {Burn} event from ivToken
    /// @param assetAmount amount of assets
    function withdrawFromStanley(uint256 assetAmount) external;

    /// @notice Closes Pay Fixed Swap for given id in emergency mode. Action available only for Owner.
    /// @dev Emits {CloseSwap} event from Milton, {Transfer} event from ERC20 asset.
    /// @param swapId Pay Fixed Swap Id.
    function emergencyCloseSwapPayFixed(uint256 swapId) external;

    /// @notice Closes Receive Fixed Swap for given id in emergency mode. Action available only for Owner.
    /// @dev Emits {CloseSwap} event from Milton, {Transfer} event from ERC20 asset.
    /// @param swapId Receive Fixed Swap Id.
    function emergencyCloseSwapReceiveFixed(uint256 swapId) external;

    /// @notice Closes Pay Fixed Swaps for given list of ids in emergency mode. Action available only for Owner.
    /// @dev Emits {CloseSwap} events from Milton, {Transfer} events from ERC20 asset.
    /// @param swapIds List of Pay Fixed swaps.
    function emergencyCloseSwapsPayFixed(uint256[] memory swapIds) external;

    /// @notice Closes Receive Fixed Swaps for given list of ids in emergency mode. Action available only for Owner.
    /// @dev Emits {CloseSwap} events from Milton, {Transfer} events from ERC20 asset.
    /// @param swapIds List of Receive Fixed swaps.
    function emergencyCloseSwapsReceiveFixed(uint256[] memory swapIds) external;

    /// @notice Pauses current smart contract, it can be executed only by the Owner
    /// @dev Emits {Paused} event from Milton.
    function pause() external;

    /// @notice Unpauses current smart contract, it can be executed only by the Owner
    /// @dev Emits {Unpaused} event from Milton.
    function unpause() external;

    /// @notice sets max allowance for a given spender. Action available only for Owner.
    /// @param spender account which will have rights to spend ERC20 underlying assets on behalf of Milton
    function setupMaxAllowanceForAsset(address spender) external;

    /// @notice Gets Joseph address.
    /// @return Joseph address.
    function getJoseph() external view returns (address);

    /// @notice Sets Joseph address. Function available only for Owner.
    /// @param newJoseph new Joseph address
    function setJoseph(address newJoseph) external;

    /// @notice Gets Milton Spread Model smart contract address responsible for Spread calculation.
    /// @return Milton Spread Model smart contract address
    function getMiltonSpreadModel() external view returns (address);

    /// @notice Emmited when Joseph address is changed by its owner.
    /// @param changedBy account address that changed Joseph's address
    /// @param oldJoseph old address of Joseph
    /// @param newJoseph new address of Joseph
    event JosephChanged(
        address indexed changedBy,
        address indexed oldJoseph,
        address indexed newJoseph
    );
}

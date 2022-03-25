// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.9;

import "./types/IporTypes.sol";
import "./types/AmmTypes.sol";
import "./types/MiltonTypes.sol";

/// @title Interface for interaction with Milton, smart contract resposnible for working Automated Market Maker.
interface IMilton {
    /// @notice Returns current version of Milton's.
    /// @return Current Milton version.
    function getVersion() external pure returns (uint256);

    /// @notice Gets Milton's balances accrued with amounts which was earned by Stanley in external Protocols.
    /// @dev Balances includes total collateral for Pay Fixed leg and for Receive Fixed leg,
    /// includes Liquidity Pool Balance, and vault balance transferred to Stanley.
    /// @return Milton Balance structure `IporTypes.MiltonBalancesMemory`.
    function getAccruedBalance() external view returns (IporTypes.MiltonBalancesMemory memory);

    /// @notice Calculates Spread in current block.
    /// @return spreadPayFixed spread for Pay Fixed leg.
    /// @return spreadReceiveFixed spread for Receive Fixed leg.
    function calculateSpread()
        external
        view
        returns (uint256 spreadPayFixed, uint256 spreadReceiveFixed);

    /// @notice Calculates SOAP in current block
    /// @return soapPayFixed SOAP for Pay Fixed leg.
    /// @return soapReceiveFixed SOAP for Receive Fixed leg.
    /// @return soap total SOAP, sum of Pay Fixed and Receive Fixed SOAP.
    function calculateSoap()
        external
        view
        returns (
            int256 soapPayFixed,
            int256 soapReceiveFixed,
            int256 soap
        );

    /// @notice Calculates SOAP in given moment.
    /// @param calculateTimestamp epoch timestamp for which SOAP is computed.
    /// @return soapPayFixed SOAP for Pay Fixed leg.
    /// @return soapReceiveFixed SOAP for Receive Fixed leg.
    /// @return soap total SOAP, sum of Pay Fixed and Receive Fixed SOAP.
    function calculateSoapForTimestamp(uint256 calculateTimestamp)
        external
        view
        returns (
            int256 soapPayFixed,
            int256 soapReceiveFixed,
            int256 soap
        );

    /// @notice Calculats Pay Fixed Swap Value for a given Swap structure.
    /// @param swap `IporTypes.IporSwapMemory` structure
    /// @return Pay Fixed Swap value, can be negative,
    /// @dev absolute value cannot be higher than collateral for this particular swap
    function calculateSwapPayFixedValue(IporTypes.IporSwapMemory memory swap)
        external
        view
        returns (int256);

    /// @notice Calculats Receive Fixed Swap Value for a given Swap structure.
    /// @param swap `IporTypes.IporSwapMemory` structure
    /// @return Receive Fixed Swap value, can be negative,
    /// @dev absolute value cannot be higher than collateral for this particular swap
    function calculateSwapReceiveFixedValue(IporTypes.IporSwapMemory memory swap)
        external
        view
        returns (int256);

    /// @notice Opens Pay Fixed, Receive Floating Swap for a given parameters.
    /// @dev Emits `OpenSwap` event from Milton, {Transfer} event from ERC20 asset.
    /// @param totalAmount Total amount transferred from trader to Milton for the purpose of opening a position.
    /// @param toleratedQuoteValue Max quote value which trader accept in case of changing quote value for external interactions other traders with Milton.
    /// @param leverage Leverage of this posistion
    /// @return Swap Id in Pay Fixed Swaps
    function openSwapPayFixed(
        uint256 totalAmount,
        uint256 toleratedQuoteValue,
        uint256 leverage
    ) external returns (uint256);

    /// @notice Opens Receive Fixed, Pay Floating Swap for a given parameters.
    /// @dev Emits `OpenSwap` event from Milton, {Transfer} event from ERC20 asset.
    /// @param totalAmount Total amount transferred from trader to Milton for the purpose of opening a position.
    /// @param toleratedQuoteValue Max quote value which trader accept in case of changing quote value for external interactions other traders with Milton.
    /// @param leverage Leverage of this posisiton
    /// @return Swap Id in Pay Fixed Swaps
    function openSwapReceiveFixed(
        uint256 totalAmount,
        uint256 toleratedQuoteValue,
        uint256 leverage
    ) external returns (uint256);

    /// @notice Closes Pay Fixed Swap for given id.
    /// @dev Emits {CloseSwap} event from Milton, {Transfer} event from ERC20 asset.
    /// @param swapId Pay Fixed Swap Id.
    function closeSwapPayFixed(uint256 swapId) external;

    /// @notice Closes Receive Fixed Swap for given id.
    /// @dev Emits {CloseSwap} event from Milton, {Transfer} event from ERC20 asset.
    /// @param swapId Receive Fixed Swap Id.
    function closeSwapReceiveFixed(uint256 swapId) external;

    /// @notice Closes Pay Fixed Swaps for given list of ids.
    /// @dev Emits {CloseSwap} events from Milton, {Transfer} events from ERC20 asset.
    /// @param swapIds List of Pay Fixed swaps.
    function closeSwapsPayFixed(uint256[] memory swapIds) external;

    /// @notice Closes Receive Fixed Swaps for given list of ids.
    /// @dev Emits {CloseSwap} events from Milton, {Transfer} events from ERC20 asset.
    /// @param swapIds List of Receive Fixed swaps.
    function closeSwapsReceiveFixed(uint256[] memory swapIds) external;

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

    /// @notice sets max allowance for a given spender. Action available only for Owner.
    /// @param spender account which will have rights to spend ERC20 underlying assets on behalf of Milton
    //TODO: rename to setupMaxAllowanceForAsset
    function setupMaxAllowance(address spender) external;

    /// @notice Pauses current smart contract, it can be executed only by the Owner
    /// @dev Emits {Paused} event from Milton.
    function pause() external;

    /// @notice Unpauses current smart contract, it can be executed only by the Owner
    /// @dev Emits {Unpaused} event from Milton.
    function unpause() external;

    /// @notice Emmited when trader opens new Swap.
    event OpenSwap(
        /// @notice swap id.
        uint256 indexed swapId,
        /// @notice trader who created this swap
        address indexed buyer,
        /// @notice underlying asset / stablecoin assocciated with this swap
        address asset,
        /// @notice swap direction
        MiltonTypes.SwapDirection direction,
        /// @notice money structure related with this swap
        AmmTypes.OpenSwapMoney money,
        /// @notice moment when swap was opened
        uint256 openTimestamp,
        /// @notice moment when swap will achieve maturiry and should be closed
        uint256 endTimestamp,
        /// @notice attributes taken from IPOR Index indicators.
        MiltonTypes.IporSwapIndicator indicator
    );

    /// @notice Emmited when trader closes Swap.
    event CloseSwap(
        /// @notice swap id.
        uint256 indexed swapId,
        /// @notice underlying asset / stablecoin assocciated with this swap
        address asset,
        /// @notice moment when Swap was closed
        uint256 closeTimestamp,
        /// @notice account who liquidate this Swap
        address liquidator,
        /// @notice asset amount after closing position which is transferred from Milton to Buyer
        uint256 transferredToBuyer,
        /// @notice asset amount after closing position which is transferred from Milton to Liquidator
        uint256 transferredToLiquidator
    );
}

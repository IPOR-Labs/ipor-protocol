// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.9;

import "./types/IporTypes.sol";
import "./types/AmmTypes.sol";
import "./types/MiltonTypes.sol";

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
    /// @dev Emits `OpenSwap` event from Milton, `Transfer` event from ERC20 asset.
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
    /// @dev Emits `OpenSwap` event from Milton, `Transfer` event from ERC20 asset.
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
    /// @dev Emits `CloseSwap` event, `Transfer` event from ERC20 asset.
    /// @param swapId Pay Fixed Swap Id.
    function closeSwapPayFixed(uint256 swapId) external;

    /// @notice Closes Receive Fixed Swap for given id.
    /// @dev Emits `CloseSwap` event, `Transfer` event from ERC20 asset.
    /// @param swapId Receive Fixed Swap Id.
    function closeSwapReceiveFixed(uint256 swapId) external;

    /// @notice Closes Pay Fixed Swaps for given list of ids.
    /// @dev Emits `CloseSwap` events, `Transfer` events from ERC20 asset.
    /// @param swapIds List of Pay Fixed swaps.
    function closeSwapsPayFixed(uint256[] memory swapIds) external;

    /// @notice Closes Receive Fixed Swaps for given list of ids.
    /// @dev Emits `CloseSwap` events, `Transfer` events from ERC20 asset.
    /// @param swapIds List of Receive Fixed swaps.
    function closeSwapsReceiveFixed(uint256[] memory swapIds) external;

    /// @notice Closes Pay Fixed Swap for given id in emergency mode. Action available only for Owner.
    /// @dev Emits `CloseSwap` event, `Transfer` event from ERC20 asset.
    /// @param swapId Pay Fixed Swap Id.
    function emergencyCloseSwapPayFixed(uint256 swapId) external;

    /// @notice Closes Receive Fixed Swap for given id in emergency mode. Action available only for Owner.
    /// @dev Emits `CloseSwap` event, `Transfer` event from ERC20 asset.
    /// @param swapId Receive Fixed Swap Id.
    function emergencyCloseSwapReceiveFixed(uint256 swapId) external;

    /// @notice Closes Pay Fixed Swaps for given list of ids in emergency mode. Action available only for Owner.
    /// @dev Emits `CloseSwap` events, `Transfer` events from ERC20 asset.
    /// @param swapIds List of Pay Fixed swaps.
    function emergencyCloseSwapsPayFixed(uint256[] memory swapIds) external;

    /// @notice Closes Receive Fixed Swaps for given list of ids in emergency mode. Action available only for Owner.
    /// @dev Emits `CloseSwap` events, `Transfer` events from ERC20 asset.
    /// @param swapIds List of Receive Fixed swaps.
    function emergencyCloseSwapsReceiveFixed(uint256[] memory swapIds) external;

    /// @notice Transfers assets (underlying tokens / stablecoins) from Milton to Stanley. Action available only for Joseph.
    function depositToStanley(uint256 assetValue) external;

    function withdrawFromStanley(uint256 assetValue) external;

    function setupMaxAllowance(address spender) external;

    /// @notice Pauses current smart contract, it can be executed only by the Owner
    /// @dev Emits {Paused} event from Milton.
    function pause() external;

    /// @notice Unpauses current smart contract, it can be executed only by the Owner
    /// @dev Emits {Unpaused} event from Milton.
    function unpause() external;

    // @notice Open swap position
    event OpenSwap(
        uint256 indexed swapId,
        address indexed buyer,
        address asset,
        MiltonTypes.SwapDirection direction,
        AmmTypes.OpenSwapMoney money,
        uint256 openTimestamp,
        uint256 endTimestamp,
        MiltonTypes.IporSwapIndicator indicator
    );

    // @notice Close swap position
    event CloseSwap(
        uint256 indexed swapId,
        address asset,
        uint256 closeTimestamp,
        address liquidator,
        uint256 transferredToBuyer,
        uint256 transferredToLiquidator
    );
}

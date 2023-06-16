// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.20;

import "../interfaces/types/AmmTypes.sol";

/// @title Interface of the service allowing to close swaps.
interface IAmmCloseSwapService {
    /// @notice Emitted when the trader closes the swap.
    event CloseSwap(
        /// @notice swap ID.
        uint256 indexed swapId,
        /// @notice underlying asset
        address asset,
        /// @notice the moment when swap was closed
        uint256 closeTimestamp,
        /// @notice account that liquidated the swap
        address liquidator,
        /// @notice asset amount after closing swap that has been transferred from AmmTreasury to the Buyer. Value represented in 18 decimals.
        uint256 transferredToBuyer,
        /// @notice asset amount after closing swap that has been transferred from AmmTreasury to the Liquidator. Value represented in 18 decimals.
        uint256 transferredToLiquidator
    );

    /// @notice Emitted when the trader closes the swap before maturity or if the absolute value of the swap's payoff is less than 99% of the swap's collateral.
    event SwapUnwind(
        /// @notice swap ID.
        uint256 indexed swapId,
        /// @notice payoff to date without unwind value, represented in 18 decimals
        int256 swapPayoffToDate,
        /// @notice swap unwind amount, represented in 18 decimals
        int256 swapUnwindAmount,
        /// @notice opening fee amount, part earmarked for the liquidity pool, represented in 18 decimals
        uint256 openingFeeLPAmount,
        /// @notice opening fee amount, part earmarked for the treasury, represented in 18 decimals
        uint256 openingFeeTreasuryAmount
    );

    /// @notice Structure representing the configuration of the AmmCloseSwapService for a given pool (asset).
    struct AmmCloseSwapServicePoolConfiguration {
        /// @notice asset address
        address asset;
        /// @notice asset decimals
        uint256 decimals;
        /// @notice Amm Storage contract address
        address ammStorage;
        /// @notice Amm Treasury contract address
        address ammTreasury;
        /// @notice Asset Management contract address
        address assetManagement;
        /// @notice Opening Fee Rate for unwinding the swap, represented in 18 decimals, 1e18 = 100%
        uint256 openingFeeRateForSwapUnwind;
        /// @notice Opening Fee Rate for unwinding the swap, part earmarked for the treasury, represented in 18 decimals, 1e18 = 100%
        uint256 openingFeeTreasuryPortionRateForSwapUnwind;
        /// @notice Max number of swaps (per leg) that can be liquidated in one call, represented without decimals
        uint256 maxLengthOfLiquidatedSwapsPerLeg;
        /// @notice Time before maturity when the community is asslowed to close the swap, represented in seconds
        uint256 timeBeforeMaturityAllowedToCloseSwapByCommunity;
        /// @notice Time before maturity then the swap owner can close it, represented in seconds
        uint256 timeBeforeMaturityAllowedToCloseSwapByBuyer;
        /// @notice Min liquidation threshold allowing community to close the swap ahead of maturity, represented in 18 decimals
        uint256 minLiquidationThresholdToCloseBeforeMaturityByCommunity;
        /// @notice Min liquidation threshold allowing the owner to close the swap ahead of maturity, represented in 18 decimals
        uint256 minLiquidationThresholdToCloseBeforeMaturityByBuyer;
        /// @notice Min leverage of the virtual swap used in unwinding, represented in 18 decimals
        uint256 minLeverage;
    }

    /// @notice Returns the configuration of the AmmCloseSwapService for a given pool (asset).
    /// @param asset asset address
    /// @return AmmCloseSwapServicePoolConfiguration struct representing the configuration of the AmmCloseSwapService for a given pool (asset).
    function getAmmCloseSwapServicePoolConfiguration(
        address asset
    ) external view returns (AmmCloseSwapServicePoolConfiguration memory);

    /// @notice Closes the USDT pay-fixed swap.
    /// @param beneficiary account - receiver of liquidation deposit.
    /// @param swapId swap ID.
    /// @dev Swap payoff is always transferred to the swaps's owner.
    function closeSwapPayFixedUsdt(address beneficiary, uint256 swapId) external;

    /// @notice Closes the USDC pay-fixed swap.
    /// @param beneficiary account - receiver of liquidation deposit.
    /// @param swapId swap ID.
    /// @dev Swap payoff is always transferred to the swaps's owner.
    function closeSwapPayFixedUsdc(address beneficiary, uint256 swapId) external;

    /// @notice Closes the DAI pay-fixed swap.
    /// @param beneficiary account - receiver of liquidation deposit.
    /// @param swapId swap ID.
    /// @dev Swap payoff is always transferred to the swaps's owner.
    function closeSwapPayFixedDai(address beneficiary, uint256 swapId) external;

    /// @notice Closes the USDT receive-fixed swap.
    /// @param beneficiary account - receiver of liquidation deposit.
    /// @param swapId swap ID.
    /// @dev Swap payoff is always transferred to the swaps's owner.
    function closeSwapReceiveFixedUsdt(address beneficiary, uint256 swapId) external;

    /// @notice Closes the USDC receive-fixed swap.
    /// @param beneficiary account - receiver of liquidation deposit.
    /// @param swapId swap ID.
    /// @dev Swap payoff is always transferred to the swaps's owner.
    function closeSwapReceiveFixedUsdc(address beneficiary, uint256 swapId) external;

    /// @notice Closes the DAI receive-fixed swap.
    /// @param beneficiary account - receiver of liquidation deposit.
    /// @param swapId swap ID.
    /// @dev Swap payoff is always transferred to the swaps's owner.
    function closeSwapReceiveFixedDai(address beneficiary, uint256 swapId) external;

    /// @notice Closes batch of USDT swaps on both legs.
    /// @param beneficiary account - receiver of liquidation deposit.
    /// @param payFixedSwapIds array of pay-fixed swap IDs.
    /// @param receiveFixedSwapIds array of receive-fixed swap IDs.
    /// @dev Swap payoff is always transferred to the swaps's owner.
    /// @return closedPayFixedSwaps array of closed pay-fixed swaps.
    /// @return closedReceiveFixedSwaps array of closed receive-fixed swaps.
    function closeSwapsUsdt(
        address beneficiary,
        uint256[] memory payFixedSwapIds,
        uint256[] memory receiveFixedSwapIds
    )
        external
        returns (
            AmmTypes.IporSwapClosingResult[] memory closedPayFixedSwaps,
            AmmTypes.IporSwapClosingResult[] memory closedReceiveFixedSwaps
        );

    /// @notice Closes batch of USDC swaps on both legs.
    /// @param beneficiary account - receiver of liquidation deposit.
    /// @param payFixedSwapIds array of pay fixed swap IDs.
    /// @param receiveFixedSwapIds array of receive fixed swap IDs.
    /// @dev Swap payoff is always transferred to the swaps's owner.
    /// @return closedPayFixedSwaps array of closed pay-fixed swaps.
    /// @return closedReceiveFixedSwaps array of closed receive-fixed swaps.
    function closeSwapsUsdc(
        address beneficiary,
        uint256[] memory payFixedSwapIds,
        uint256[] memory receiveFixedSwapIds
    )
        external
        returns (
            AmmTypes.IporSwapClosingResult[] memory closedPayFixedSwaps,
            AmmTypes.IporSwapClosingResult[] memory closedReceiveFixedSwaps
        );

    /// @notice Closes batch of DAI swaps on both legs.
    /// @param beneficiary account - receiver of liquidation deposit.
    /// @param payFixedSwapIds array of pay fixed swap IDs.
    /// @param receiveFixedSwapIds array of receive fixed swap IDs.
    /// @dev Swap payoff is always transferred to the swaps's owner.
    /// @return closedPayFixedSwaps array of closed pay-fixed swaps.
    /// @return closedReceiveFixedSwaps array of closed receive-fixed swaps.
    function closeSwapsDai(
        address beneficiary,
        uint256[] memory payFixedSwapIds,
        uint256[] memory receiveFixedSwapIds
    )
        external
        returns (
            AmmTypes.IporSwapClosingResult[] memory closedPayFixedSwaps,
            AmmTypes.IporSwapClosingResult[] memory closedReceiveFixedSwaps
        );

    /// @notice Closes the USDT pay-fixed swap in emergency mode.
    /// @param swapId swap ID.
    /// @dev Swaps can be closed in emergency mode by the protocol owner even if protocol is paused.
    function emergencyCloseSwapPayFixedUsdt(uint256 swapId) external;

    /// @notice Closes the USDC pay-fixed swap in emergency mode.
    /// @param swapId swap ID.
    /// @dev Swaps can be closed in emergency mode by the protocol owner even if protocol is paused.
    function emergencyCloseSwapPayFixedUsdc(uint256 swapId) external;

    /// @notice Closes the DAI pay-fixed swap in emergency mode.
    /// @param swapId swap ID.
    /// @dev Swaps can be closed in emergency mode by the protocol owner even if protocol is paused.
    function emergencyCloseSwapPayFixedDai(uint256 swapId) external;

    /// @notice Closes the USDT receive-fixed swap in emergency mode.
    /// @param swapId swap ID.
    /// @dev Swaps can be closed in emergency mode by the protocol owner even if protocol is paused.
    function emergencyCloseSwapReceiveFixedUsdt(uint256 swapId) external;

    /// @notice Closes the USDC receive-fixed swap in emergency mode.
    /// @param swapId swap ID.
    /// @dev Swaps can be closed in emergency mode by the protocol owner even if protocol is paused.
    function emergencyCloseSwapReceiveFixedUsdc(uint256 swapId) external;

    /// @notice Closes the DAI receive-fixed swap in emergency mode.
    /// @param swapId swap ID.
    /// @dev Swaps can be closed in emergency mode by the protocol owner even if protocol is paused.
    function emergencyCloseSwapReceiveFixedDai(uint256 swapId) external;

    /// @notice Closes multiple USDT pay-fixed swap in emergency mode.
    /// @param swapIds swap IDs.
    /// @dev Swaps can be closed in emergency mode by the protocol owner even if protocol is paused.
    /// @return closedSwaps array of closed swaps.
    function emergencyCloseSwapsPayFixedUsdt(
        uint256[] memory swapIds
    ) external returns (AmmTypes.IporSwapClosingResult[] memory closedSwaps);

    /// @notice Closes multiple USDC pay-fixed swap in emergency mode.
    /// @param swapIds swap IDs.
    /// @dev Swaps can be closed in emergency mode by the protocol owner even if protocol is paused.
    /// @return closedSwaps array of closed swaps.
    function emergencyCloseSwapsPayFixedUsdc(
        uint256[] memory swapIds
    ) external returns (AmmTypes.IporSwapClosingResult[] memory closedSwaps);

    /// @notice Closes multiple DAI pay-fixed swap in emergency mode.
    /// @param swapIds swap IDs.
    /// @dev Swaps can be closed in emergency mode by the protocol owner even if protocol is paused.
    /// @return closedSwaps array of closed swaps.
    function emergencyCloseSwapsPayFixedDai(
        uint256[] memory swapIds
    ) external returns (AmmTypes.IporSwapClosingResult[] memory closedSwaps);

    /// @notice Closes multiple USDT receive-fixed swap in emergency mode.
    /// @param swapIds swap IDs.
    /// @dev Swaps can be closed in emergency mode by the protocol owner even if protocol is paused.
    /// @return closedSwaps array of closed swaps.
    function emergencyCloseSwapsReceiveFixedUsdt(
        uint256[] memory swapIds
    ) external returns (AmmTypes.IporSwapClosingResult[] memory closedSwaps);

    /// @notice Closes multiple USDC receive-fixed swap in emergency mode.
    /// @param swapIds swap IDs.
    /// @dev Swaps can be closed in emergency mode by the protocol owner even if protocol is paused.
    /// @return closedSwaps array of closed swaps.
    function emergencyCloseSwapsReceiveFixedUsdc(
        uint256[] memory swapIds
    ) external returns (AmmTypes.IporSwapClosingResult[] memory closedSwaps);

    /// @notice Closes multiple DAI receive-fixed swap in emergency mode.
    /// @param swapIds swap IDs.
    /// @dev Swaps can be closed in emergency mode by the protocol owner even if protocol is paused.
    /// @return closedSwaps array of closed swaps.
    function emergencyCloseSwapsReceiveFixedDai(
        uint256[] memory swapIds
    ) external returns (AmmTypes.IporSwapClosingResult[] memory closedSwaps);
}

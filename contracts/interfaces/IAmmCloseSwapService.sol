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

    /// @notice Emitted when the trader closes the swap earlier than maturity or absolute value of swap payoff is less than 99% of the swap collateral.
    event SwapUnwind(
        /// @notice swap ID.
        uint256 indexed swapId,
        /// @notice payoff to date without unwind value, represented in 18 decimals
        int256 swapPayoffToDate,
        /// @notice swap unwind amount, represented in 18 decimals
        int256 swapUnwindAmount,
        /// @notice opening fee amount, part dedicated for liquidity pool, represented in 18 decimals
        uint256 openingFeeLPAmount,
        /// @notice opening fee amount, part dedicated for treasury, represented in 18 decimals
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
        /// @notice Opening Fee Rate for Swap Unwind, represented in 18 decimals, 1e18 = 100%
        uint256 openingFeeRateForSwapUnwind;
        /// @notice Opening Fee Rate for Swap Unwind, part dedicated for treasury, represented in 18 decimals, 1e18 = 100%
        uint256 openingFeeTreasuryPortionRateForSwapUnwind;
        /// @notice Max length of liquidated swaps per leg, represented without decimals
        uint256 maxLengthOfLiquidatedSwapsPerLeg;
        /// @notice Time before maturity allowed to close swap by community, represented in seconds
        uint256 timeBeforeMaturityAllowedToCloseSwapByCommunity;
        /// @notice Time before maturity allowed to close swap by buyer, represented in seconds
        uint256 timeBeforeMaturityAllowedToCloseSwapByBuyer;
        /// @notice Min liquidation threshold to close before maturity by community, represented in 18 decimals
        uint256 minLiquidationThresholdToCloseBeforeMaturityByCommunity;
        /// @notice Min liquidation threshold to close before maturity by buyer, represented in 18 decimals
        uint256 minLiquidationThresholdToCloseBeforeMaturityByBuyer;
        /// @notice Min leverage to close before maturity by community, represented in 18 decimals
        uint256 minLeverage;
    }

    /// @notice Returns the configuration of the AmmCloseSwapService for a given pool (asset).
    /// @param asset asset address
    /// @return AmmCloseSwapServicePoolConfiguration struct representing the configuration of the AmmCloseSwapService for a given pool (asset).
    function getAmmCloseSwapServicePoolConfiguration(
        address asset
    ) external view returns (AmmCloseSwapServicePoolConfiguration memory);

    /// @notice Close the swap for pay fixed leg in USDT asset (pool).
    /// @param beneficiary account that will receive liquidation deposit.
    /// @param swapId swap ID.
    /// @dev Swap payoff is always transferred to the owner of the swap (buyer).
    function closeSwapPayFixedUsdt(address beneficiary, uint256 swapId) external;

    /// @notice Close the swap for pay fixed leg in USDC asset (pool).
    /// @param beneficiary account that will receive liquidation deposit.
    /// @param swapId swap ID.
    /// @dev Swap payoff is always transferred to the owner of the swap (buyer).
    function closeSwapPayFixedUsdc(address beneficiary, uint256 swapId) external;

    /// @notice Close the swap for pay fixed leg in DAI asset (pool).
    /// @param beneficiary account that will receive liquidation deposit.
    /// @param swapId swap ID.
    /// @dev Swap payoff is always transferred to the owner of the swap (buyer).
    function closeSwapPayFixedDai(address beneficiary, uint256 swapId) external;

    /// @notice Close the swap for receive fixed leg in USDT asset (pool).
    /// @param beneficiary account that will receive liquidation deposit.
    /// @param swapId swap ID.
    /// @dev Swap payoff is always transferred to the owner of the swap (buyer).
    function closeSwapReceiveFixedUsdt(address beneficiary, uint256 swapId) external;

    /// @notice Close the swap for receive fixed leg in USDC asset (pool).
    /// @param beneficiary account that will receive liquidation deposit.
    /// @param swapId swap ID.
    /// @dev Swap payoff is always transferred to the owner of the swap (buyer).
    function closeSwapReceiveFixedUsdc(address beneficiary, uint256 swapId) external;

    /// @notice Close the swap for receive fixed leg in DAI asset (pool).
    /// @param beneficiary account that will receive liquidation deposit.
    /// @param swapId swap ID.
    /// @dev Swap payoff is always transferred to the owner of the swap (buyer).
    function closeSwapReceiveFixedDai(address beneficiary, uint256 swapId) external;

    /// @notice Close the swaps for pay fixed leg in USDT asset (pool) and receive fixed leg in USDT asset (pool).
    /// @param beneficiary account that will receive liquidation deposit.
    /// @param payFixedSwapIds array of pay fixed swap IDs.
    /// @param receiveFixedSwapIds array of receive fixed swap IDs.
    /// @dev Swap payoff is always transferred to the owner of the swap (buyer).
    /// @return closedPayFixedSwaps array of closed pay fixed swaps.
    /// @return closedReceiveFixedSwaps array of closed receive fixed swaps.
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

    /// @notice Close the swaps for pay fixed leg in USDC asset (pool) and receive fixed leg in USDC asset (pool).
    /// @param beneficiary account that will receive liquidation deposit.
    /// @param payFixedSwapIds array of pay fixed swap IDs.
    /// @param receiveFixedSwapIds array of receive fixed swap IDs.
    /// @dev Swap payoff is always transferred to the owner of the swap (buyer).
    /// @return closedPayFixedSwaps array of closed pay fixed swaps.
    /// @return closedReceiveFixedSwaps array of closed receive fixed swaps.
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

    /// @notice Close the swaps for pay fixed leg in DAI asset (pool) and receive fixed leg in DAI asset (pool).
    /// @param beneficiary account that will receive liquidation deposit.
    /// @param payFixedSwapIds array of pay fixed swap IDs.
    /// @param receiveFixedSwapIds array of receive fixed swap IDs.
    /// @dev Swap payoff is always transferred to the owner of the swap (buyer).
    /// @return closedPayFixedSwaps array of closed pay fixed swaps.
    /// @return closedReceiveFixedSwaps array of closed receive fixed swaps.
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

    /// @notice Emergency close the swap for pay fixed leg in USDT asset (pool).
    /// @param swapId swap ID.
    /// @dev Any swap can be closed in any moment by IPOR Protocol Owner even if Protocol is paused.
    function emergencyCloseSwapPayFixedUsdt(uint256 swapId) external;

    /// @notice Emergency close the swap for pay fixed leg in USDC asset (pool).
    /// @param swapId swap ID.
    /// @dev Any swap can be closed in any moment by IPOR Protocol Owner even if Protocol is paused.
    function emergencyCloseSwapPayFixedUsdc(uint256 swapId) external;

    /// @notice Emergency close the swap for pay fixed leg in DAI asset (pool).
    /// @param swapId swap ID.
    /// @dev Any swap can be closed in any moment by IPOR Protocol Owner even if Protocol is paused.
    function emergencyCloseSwapPayFixedDai(uint256 swapId) external;

    /// @notice Emergency close the swap for receive fixed leg in USDT asset (pool).
    /// @param swapId swap ID.
    /// @dev Any swap can be closed in any moment by IPOR Protocol Owner even if Protocol is paused.
    function emergencyCloseSwapReceiveFixedUsdt(uint256 swapId) external;

    /// @notice Emergency close the swap for receive fixed leg in USDC asset (pool).
    /// @param swapId swap ID.
    /// @dev Any swap can be closed in any moment by IPOR Protocol Owner even if Protocol is paused.
    function emergencyCloseSwapReceiveFixedUsdc(uint256 swapId) external;

    /// @notice Emergency close the swap for receive fixed leg in DAI asset (pool).
    /// @param swapId swap ID.
    /// @dev Any swap can be closed in any moment by IPOR Protocol Owner even if Protocol is paused.
    function emergencyCloseSwapReceiveFixedDai(uint256 swapId) external;

    /// @notice Emergency close the swaps for pay fixed leg in USDT asset (pool).
    /// @param swapIds array of pay fixed swap IDs.
    /// @dev Any swap can be closed in any moment by IPOR Protocol Owner even if Protocol is paused.
    /// @return closedSwaps array of closed swaps.
    function emergencyCloseSwapsPayFixedUsdt(
        uint256[] memory swapIds
    ) external returns (AmmTypes.IporSwapClosingResult[] memory closedSwaps);

    /// @notice Emergency close the swaps for pay fixed leg in USDC asset (pool).
    /// @param swapIds array of pay fixed swap IDs.
    /// @dev Any swap can be closed in any moment by IPOR Protocol Owner even if Protocol is paused.
    /// @return closedSwaps array of closed swaps.
    function emergencyCloseSwapsPayFixedUsdc(
        uint256[] memory swapIds
    ) external returns (AmmTypes.IporSwapClosingResult[] memory closedSwaps);

    /// @notice Emergency close the swaps for pay fixed leg in DAI asset (pool).
    /// @param swapIds array of pay fixed swap IDs.
    /// @dev Any swap can be closed in any moment by IPOR Protocol Owner even if Protocol is paused.
    /// @return closedSwaps array of closed swaps.
    function emergencyCloseSwapsPayFixedDai(
        uint256[] memory swapIds
    ) external returns (AmmTypes.IporSwapClosingResult[] memory closedSwaps);

    /// @notice Emergency close the swaps for receive fixed leg in USDT asset (pool).
    /// @param swapIds array of receive fixed swap IDs.
    /// @dev Any swap can be closed in any moment by IPOR Protocol Owner even if Protocol is paused.
    /// @return closedSwaps array of closed swaps.
    function emergencyCloseSwapsReceiveFixedUsdt(
        uint256[] memory swapIds
    ) external returns (AmmTypes.IporSwapClosingResult[] memory closedSwaps);

    /// @notice Emergency close the swaps for receive fixed leg in USDC asset (pool).
    /// @param swapIds array of receive fixed swap IDs.
    /// @dev Any swap can be closed in any moment by IPOR Protocol Owner even if Protocol is paused.
    /// @return closedSwaps array of closed swaps.
    function emergencyCloseSwapsReceiveFixedUsdc(
        uint256[] memory swapIds
    ) external returns (AmmTypes.IporSwapClosingResult[] memory closedSwaps);

    /// @notice Emergency close the swaps for receive fixed leg in DAI asset (pool).
    /// @param swapIds array of receive fixed swap IDs.
    /// @dev Any swap can be closed in any moment by IPOR Protocol Owner even if Protocol is paused.
    /// @return closedSwaps array of closed swaps.
    function emergencyCloseSwapsReceiveFixedDai(
        uint256[] memory swapIds
    ) external returns (AmmTypes.IporSwapClosingResult[] memory closedSwaps);
}

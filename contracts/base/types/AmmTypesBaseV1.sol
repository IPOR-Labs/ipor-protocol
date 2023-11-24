// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.20;
import "../../interfaces/types/IporTypes.sol";
import "../../interfaces/types/AmmTypes.sol";

/// @title Types used in interfaces strictly related to AMM (Automated Market Maker).
/// @dev Used by IAmmTreasury and IAmmStorage interfaces.
library AmmTypesBaseV1 {
    /// @notice Struct representing swap item, used for listing and in internal calculations
    struct Swap {
        /// @notice Swap's unique ID
        uint256 id;
        /// @notice Swap's buyer
        address buyer;
        /// @notice Swap opening epoch timestamp
        uint256 openTimestamp;
        /// @notice Swap's tenor
        IporTypes.SwapTenor tenor;
        /// @notice Swap's direction
        AmmTypes.SwapDirection direction;
        /// @notice Index position of this Swap in an array of swaps' identification associated to swap buyer
        /// @dev Field used for gas optimization purposes, it allows for quick removal by id in the array.
        /// During removal the last item in the array is switched with the one that just has been removed.
        uint256 idsIndex;
        /// @notice Swap's collateral
        /// @dev value represented in 18 decimals
        uint256 collateral;
        /// @notice Swap's notional amount
        /// @dev value represented in 18 decimals
        uint256 notional;
        /// @notice Swap's notional amount denominated in the Interest Bearing Token (IBT)
        /// @dev value represented in 18 decimals
        uint256 ibtQuantity;
        /// @notice Fixed interest rate at which the position has been opened
        /// @dev value represented in 18 decimals
        uint256 fixedInterestRate;
        /// @notice Liquidation deposit amount
        /// @dev value represented in 18 decimals
        uint256 wadLiquidationDepositAmount;
        /// @notice State of the swap
        /// @dev 0 - INACTIVE, 1 - ACTIVE
        IporTypes.SwapState state;
    }

    /// @notice Structure representing configuration of the AmmOpenSwapServicePool for specific asset (pool).
    struct AmmOpenSwapServicePoolConfiguration {
        /// @notice address of the asset
        address asset;
        /// @notice asset decimals
        uint256 decimals;
        /// @notice address of the AMM Storage
        address ammStorage;
        /// @notice address of the AMM Treasury
        address ammTreasury;
        /// @notice spread contract address
        address spread;
        /// @notice ipor publication fee, fee used when opening swap, represented in 18 decimals.
        uint256 iporPublicationFee;
        /// @notice maximum swap collateral amount, represented in 18 decimals.
        uint256 maxSwapCollateralAmount;
        /// @notice liquidation deposit amount, represented with 6 decimals. Example 25000000 = 25 units = 25.000000.
        uint256 liquidationDepositAmount;
        /// @notice minimum leverage, represented in 18 decimals.
        uint256 minLeverage;
        /// @notice swap's opening fee rate, represented in 18 decimals. 1e18 = 100%
        uint256 openingFeeRate;
        /// @notice swap's opening fee rate, portion of the rate which is allocated to "treasury" balance
        /// @dev Value describes what percentage of opening fee amount is allocated to "treasury" balance. Value represented in 18 decimals. 1e18 = 100%
        uint256 openingFeeTreasuryPortionRate;
    }

    /// @notice Structure representing the configuration of the AmmCloseSwapService for a given pool (asset).
    struct AmmCloseSwapServicePoolConfiguration {
        address spread;
        /// @notice asset address
        address asset;
        /// @notice asset decimals
        uint256 decimals;
        /// @notice Amm Storage contract address
        address ammStorage;
        /// @notice Amm Treasury contract address
        address ammTreasury;
        /// @notice Unwinding Fee Rate for unwinding the swap, represented in 18 decimals, 1e18 = 100%
        uint256 unwindingFeeRate;
        /// @notice Unwinding Fee Rate for unwinding the swap, part earmarked for the treasury, represented in 18 decimals, 1e18 = 100%
        uint256 unwindingFeeTreasuryPortionRate;
        /// @notice Max number of swaps (per leg) that can be liquidated in one call, represented without decimals
        uint256 maxLengthOfLiquidatedSwapsPerLeg;
        /// @notice Time before maturity when the community is allowed to close the swap, represented in seconds
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

    /// @notice Technical structure with unwinding parameters.
    struct UnwindParams {
        /// @notice Risk Indicators Inputs signer
        address messageSigner;
        /// @notice Moment when the swap is closing
        uint256 closeTimestamp;
        /// @notice Swap's PnL value to moment when the swap is closing
        int256 swapPnlValueToDate;
        /// @notice Actual IPOR index value
        uint256 indexValue;
        /// @notice Swap data
        AmmTypesBaseV1.Swap swap;
        /// @notice Risk indicators for both legs pay fixed and receive fixed
        AmmTypes.CloseSwapRiskIndicatorsInput riskIndicatorsInputs;
    }

    struct BeforeOpenSwapStruct {
        /// @notice Amount of entered asset that is sent from buyer to AmmTreasury when opening swap.
        /// @dev Notice! Input Asset can be different than the asset that is used as a collateral. Value represented in decimals of input asset.
        uint256 inputAssetTotalAmount;
        /// @notice Amount of entered asset that is sent from buyer to AmmTreasury when opening swap.
        /// @dev Notice! Input Asset can be different than the asset that is used as a collateral. Value represented in 18 decimals.
        uint256 wadInputAssetTotalAmount;
        /// @notice Amount of underlying asset that is used as a collateral and other costs related to swap opening.
        /// @dev The amount is represented in decimals of the asset.
        uint256 assetTotalAmount;
        /// @notice Amount of underlying asset that is used as a collateral and other costs related to swap opening.
        /// @dev The amount is represented in 18 decimals regardless of the decimals of the asset.
        uint256 wadAssetTotalAmount;
        /// @notice Swap's collateral.
        uint256 collateral;
        /// @notice Swap's notional amount.
        uint256 notional;
        /// @notice The part of the opening fee that will be added to the liquidity pool balance.
        uint256 openingFeeLPAmount;
        /// @notice Part of the opening fee that will be added to the treasury balance.
        uint256 openingFeeTreasuryAmount;
        /// @notice Amount of asset set aside for the oracle subsidization.
        uint256 iporPublicationFeeAmount;
        /// @notice Refundable deposit blocked for the entity that will close the swap.
        /// For more information on how the liquidations work refer to the documentation.
        /// https://ipor-labs.gitbook.io/ipor-labs/automated-market-maker/liquidations
        /// @dev value represented without decimals for USDT, USDC, DAI, with 6 decimals for stETH, as an integer.
        uint256 liquidationDepositAmount;
        /// @notice The struct describing the IPOR and its params calculated for the time when it was most recently updated and the change that took place since the update.
        /// Namely, the interest that would be computed into IBT should the rebalance occur.
        IporTypes.AccruedIpor accruedIpor;
    }

    /// @notice Struct representing amounts related to Swap that is presently being opened.
    /// @dev all values represented in 18 decimals
    struct OpenSwapAmount {
        /// @notice Amount of entered asset that is sent from buyer to AmmTreasury when opening swap.
        /// @dev Notice. Input Asset can be different than the asset that is used as a collateral. Represented in 18 decimals.
        uint256 inputAssetTotalAmount;
        /// @notice Total Amount of underlying asset that is used as a collateral.
        uint256 assetTotalAmount;
        /// @notice Swap's collateral, represented in underlying asset.
        uint256 collateral;
        /// @notice Swap's notional, represented in underlying asset.
        uint256 notional;
        /// @notice Opening Fee - part allocated as a profit of the Liquidity Pool, represented in underlying asset.
        uint256 openingFeeLPAmount;
        /// @notice  Part of the fee set aside for subsidizing the oracle that publishes IPOR rate. Flat fee set by the DAO. Represented in underlying asset.
        /// @notice Opening Fee - part allocated in Treasury balance. Part of the fee set asside for subsidising the oracle that publishes IPOR rate. Flat fee set by the DAO.
        uint256 openingFeeTreasuryAmount;
        /// @notice Fee set aside for subsidizing the oracle that publishes IPOR rate. Flat fee set by the DAO. Represented in underlying asset.
        uint256 iporPublicationFee;
        /// @notice Liquidation deposit is retained when the swap is opened. Notice! Value represented in 18 decimals. Represents in underlying asset.
        uint256 liquidationDepositAmount;
    }

    struct AmmBalanceForOpenSwap {
        /// @notice Sum of all collateral put forward by the derivative buyer's on  Pay Fixed & Receive Floating leg.
        uint256 totalCollateralPayFixed;
        /// @notice Total notional amount of all swaps on  Pay Fixed leg (denominated in 18 decimals).
        uint256 totalNotionalPayFixed;
        /// @notice Sum of all collateral put forward by the derivative buyer's on  Pay Floating & Receive Fixed leg.
        uint256 totalCollateralReceiveFixed;
        /// @notice Total notional amount of all swaps on  Receive Fixed leg (denominated in 18 decimals).
        uint256 totalNotionalReceiveFixed;
    }

    struct Balance {
        /// @notice Sum of all collateral put forward by the derivative buyer's on  Pay Fixed & Receive Floating leg.
        uint256 totalCollateralPayFixed;
        /// @notice Sum of all collateral put forward by the derivative buyer's on  Pay Floating & Receive Fixed leg.
        uint256 totalCollateralReceiveFixed;
        /// @notice This balance is used to track the funds accounted for IporOracle subsidization.
        uint256 iporPublicationFee;
        /// @notice Treasury is the balance that belongs to IPOR DAO and funds up to this amount can be transferred to the DAO-appointed multi-sig wallet.
        /// this ballance is fed by part of the opening fee appointed by the DAO. For more information refer to the documentation:
        /// https://ipor-labs.gitbook.io/ipor-labs/automated-market-maker/ipor-swaps#fees
        uint256 treasury;
    }
}

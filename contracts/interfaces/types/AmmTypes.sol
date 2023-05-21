// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.16;

/// @title Types used in interfaces strictly related to AMM (Automated Market Maker).
/// @dev Used by IMilton and IMiltonStorage interfaces.
library AmmTypes {
    /// @notice enum describing Swap's duration, 28 days, 60 days or 90 days
    enum SwapDuration {
        DAYS_28,
        DAYS_60,
        DAYS_90
    }
    /// @notice enum describing Swap's state, ACTIVE - when the swap is opened, INACTIVE when it's closed
    enum SwapState {
        INACTIVE,
        ACTIVE
    }

    struct AmmPoolCoreModel {
        address asset;
        uint256 assetDecimals;
        address ipToken;
        address ammStorage;
        address ammTreasury;
        address assetManagement;
        address iporOracle;
        address iporRiskManagementOracle;
    }

    /// @notice Structure which represents Swap's data that will be saved in the storage.
    /// Refer to the documentation https://ipor-labs.gitbook.io/ipor-labs/automated-market-maker/ipor-swaps for more information.
    struct NewSwap {
        /// @notice Account / trader who opens the Swap
        address buyer;
        /// @notice Epoch timestamp of when position was opened by the trader.
        uint256 openTimestamp;
        /// @notice Swap's collateral amount.
        /// @dev value represented in 18 decimals
        uint256 collateral;
        /// @notice Swap's notional amount.
        /// @dev value represented in 18 decimals
        uint256 notional;
        /// @notice Quantity of Interest Bearing Token (IBT) at moment when position was opened.
        /// @dev value represented in 18 decimals
        uint256 ibtQuantity;
        /// @notice Fixed interest rate at which the position has been opened.
        /// @dev value represented in 18 decimals
        uint256 fixedInterestRate;
        /// @notice Liquidation deposit is retained when the swap is opened. It is then paid back to agent who closes the derivative at maturity.
        /// It can be both trader or community member. Trader receives the deposit back when he chooses to close the derivative before maturity.
        /// @dev value represented in 18 decimals
        uint256 liquidationDepositAmount;
        /// @notice Opening fee amount part which is allocated in Liquidity Pool Balance. This fee is calculated as a rate of the swap's collateral.
        /// @dev value represented in 18 decimals
        uint256 openingFeeLPAmount;
        /// @notice Opening fee amount part which is allocated in Treasury Balance. This fee is calculated as a rate of the swap's collateral.
        /// @dev value represented in 18 decimals
        uint256 openingFeeTreasuryAmount;
        /// @notice Swap's duration, 0 - 28 days, 1 - 60 days or 2 - 90 days
        AmmTypes.SwapDuration duration;
    }

    /// @notice Struct representing assets (ie. stablecoin) related to Swap that is presently being opened.
    /// @dev all values represented in 18 decimals
    struct OpenSwapMoney {
        /// @notice Total Amount of asset that is sent from buyer to Milton when opening swap.
        uint256 totalAmount;
        /// @notice Swap's collateral
        uint256 collateral;
        /// @notice Swap's notional
        uint256 notional;
        /// @notice Opening Fee - part allocated as a profit of the Liquidity Pool
        uint256 openingFeeLPAmount;
        /// @notice  Part of the fee set aside for subsidizing the oracle that publishes IPOR rate. Flat fee set by the DAO.
        /// @notice Opening Fee - part allocated in Treasury balance. Part of the fee set asside for subsidising the oracle that publishes IPOR rate. Flat fee set by the DAO.
        uint256 openingFeeTreasuryAmount;
        /// @notice Fee set aside for subsidizing the oracle that publishes IPOR rate. Flat fee set by the DAO.
        uint256 iporPublicationFee;
        /// @notice Liquidation deposit is retained when the swap is opened. Value represented in 18 decimals.
        uint256 liquidationDepositAmount;
    }

    /// @notice Structure describes one swap processed by closeSwaps method, information about swap ID and flag if this swap was closed during execution closeSwaps method.
    struct IporSwapClosingResult {
        /// @notice Swap ID
        uint256 swapId;
        /// @notice Flag describe if swap was closed during this execution
        bool closed;
    }

    struct RedeemMoney {
        uint256 wadAssetAmount;
        uint256 redeemAmount;
        uint256 wadRedeemFee;
        uint256 wadRedeemAmount;
    }
}

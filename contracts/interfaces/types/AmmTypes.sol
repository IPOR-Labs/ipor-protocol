// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.9;

/// @title Types used in interfaces strictly related to AMM (Automated Market Maker).
/// @dev Used by IMilton and IMiltonStorage interfaces.
library AmmTypes {
    /// @notice enum describing Swap's state, ACTIVE - when the swap is opened, INACTIVE when it's closed
    enum SwapState {
        INACTIVE,
        ACTIVE
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
        /// @notice Liquidation deposit is retained when the swap is opened. It is then paid back to agent who closes the derivative at maturity. 
        /// It can be both trader or community member. Trader receives the deposit back when he chooses to close the derivative before maturity. 
        /// @dev value represented in 18 decimals
        uint256 liquidationDepositAmount;
        /// @notice Swap's notional amount.
        /// @dev value represented in 18 decimals
        uint256 notionalAmount;
        /// @notice Fixed interest rate at which the position has been opened.
        /// @dev value represented in 18 decimals
        uint256 fixedInterestRate;
        /// @notice Quantity of Interest Bearing Token (IBT) at moment when position was opened.
        /// @dev value represented in 18 decimals
        uint256 ibtQuantity;
        uint256 openingFeeLPValue;
        uint256 openingFeeTreasuryValue;        /// @notice Opening fee amount. This fee is calculated as a percentage of the swap's collateral.
        /// @dev value represented in 18 decimals
        uint256 openingFeeAmount;
    }

    /// @notice Struct representing assets (ie. stablecoin) related to Swap that is presently being opened.
    /// @dev all values represented in 18 decimals
    struct OpenSwapMoney {
        /// @notice Total Amount of asset which is sent from buyer to Milton to open the swap.
        uint256 totalAmount;
        /// @notice Swap's collateral
        uint256 collateral;
        /// @notice Swap's notional
        uint256 notionalAmount;
/// @notice Opening Fee Amount 
        uint256 openingFeeLPValue;
        uint256 openingFeeTreasuryValue;
        /// @notice  Part of the fee set asside for subsidising the oracle that publishes IPOR rate. Flat fee set by the DAO.
        uint256 openingFeeAmount;
        /// @notice  Part of the fee set aside for subsidizing the oracle that publishes IPOR rate. Flat fee set by the DAO.
        uint256 iporPublicationAmount;
        /// @notice  Liquidation deposit is retained when the swap is opened.
        uint256 liquidationDepositAmount;
    }
}

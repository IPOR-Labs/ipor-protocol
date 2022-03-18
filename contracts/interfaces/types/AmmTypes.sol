// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.9;

/// @title Types used in interfaces related stricte with AMM (Automated Market Maker)
/// @dev used by IMilton and IMiltonStorage interfaces
library AmmTypes {
    /// @notice enum described Swap state, ACTIVE - when is opened, INACTIVE when is closed
    enum SwapState {
        INACTIVE,
        ACTIVE
    }

    /// @notice Structure which represents Swap data which will be saved in storage.
    struct NewSwap {
        /// @notice Account / trader who open Swap
        address buyer;
        /// @notice Moment when position was opened by trader.
        uint256 openTimestamp;
        /// @notice Swap collateral, insurance of the Swap
        /// @dev value represented in 18 decimals
        uint256 collateral;
        /// @notice Amount intended for user who liquidate this new created position in future
        /// @dev value represented in 18 decimals
        uint256 liquidationDepositAmount;
        /// @notice Notional amount of Swap
        /// @dev value represented in 18 decimals
        uint256 notionalAmount;
        /// @notice Fixed interest rate at which the position has been locked, it is quote from spread documentation
        /// @dev value represented in 18 decimals
        uint256 fixedInterestRate;
        /// @notice quantity of Interest Bearing Token at moment when position was opened
        /// @dev value represented in 18 decimals
        uint256 ibtQuantity;
        uint256 openingFeeLPValue;
        uint256 openingFeeTreasuryValue;
    }

    /// @notice Struct which represents moneys related with upcoming opened Swap.
    /// @dev all values represented in 18 decimals
    struct OpenSwapMoney {
        /// @notice Total Amount of money which is sent from buyer to Milton to open swap
        uint256 totalAmount;
        /// @notice Collateral Swap
        uint256 collateral;
        /// @notice Notional Swap
        uint256 notionalAmount;
        /// @notice Opening Fee Amount taken from trader
        uint256 openingFeeLPValue;
        uint256 openingFeeTreasuryValue;
        /// @notcie Ipor Publication Amount taken from trader, intended for request to IPOR index update by Charlie
        uint256 iporPublicationAmount;
        /// @notice  Amount intended for user who will liquidate this new created position in future
        uint256 liquidationDepositAmount;
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.20;

import "../interfaces/types/AmmTypes.sol";

/// @title Interface of the service that allows to open new swaps.
interface IAmmOpenSwapService {
    /// @notice Emitted when trader opens new swap.
    event OpenSwap(
        /// @notice swap ID.
        uint256 indexed swapId,
        /// @notice trader that opened the swap
        address indexed buyer,
        /// @notice underlying asset
        address asset,
        /// @notice swap direction
        AmmTypes.SwapDirection direction,
        /// @notice money structure related with this swap
        AmmTypes.OpenSwapMoney money,
        /// @notice the moment when swap was opened
        uint256 openTimestamp,
        /// @notice the moment when swap will achieve maturity
        uint256 endTimestamp,
        /// @notice attributes taken from IPOR Index indicators.
        AmmTypes.IporSwapIndicator indicator
    );

    struct AmmOpenSwapServicePoolConfiguration {
        address asset;
        uint256 decimals;
        address ammStorage;
        address ammTreasury;
        uint256 iporPublicationFee;
        uint256 maxSwapCollateralAmount;
        uint256 liquidationDepositAmount;
        uint256 minLeverage;
        uint256 openingFeeRate;
        uint256 openingFeeTreasuryPortionRate;
    }

    function getAmmOpenSwapServicePoolConfiguration(address asset) external view returns (AmmOpenSwapServicePoolConfiguration memory);

    /// @notice Open new swap pay fixed receive floating with maturity in 28 days for asset USDT.
    /// @param onBehalfOf address of the account on behalf of which this swap is opened.
    /// @param totalAmount total amount of the swap, represented in decimals specific to the asset.
    /// @param acceptableFixedInterestRate acceptable fixed interest rate, represented in 18 decimals.
    /// @param leverage swap leverage, represented in 18 decimals.
    /// @return swapId ID of the opened swap.
    /// @dev Owner of that swap is the user with address `onBehalfOf`. Sender pays for the swap.
    function openSwapPayFixed28daysUsdt(
        address onBehalfOf,
        uint256 totalAmount,
        uint256 acceptableFixedInterestRate,
        uint256 leverage
    ) external returns (uint256);

    /// @notice Open new swap pay fixed receive floating with maturity in 60 days for asset USDT.
    /// @param onBehalfOf address of the account on behalf of which this swap is opened.
    /// @param totalAmount total amount of the swap, represented in decimals specific to the asset.
    /// @param acceptableFixedInterestRate acceptable fixed interest rate, represented in 18 decimals.
    /// @param leverage swap leverage, represented in 18 decimals.
    /// @return swapId ID of the opened swap.
    /// @dev Owner of that swap is the user with address `onBehalfOf`. Sender pays for the swap.
    function openSwapPayFixed60daysUsdt(
        address onBehalfOf,
        uint256 totalAmount,
        uint256 acceptableFixedInterestRate,
        uint256 leverage
    ) external returns (uint256);

    /// @notice Open new swap pay fixed receive floating with maturity in 90 days for asset USDT.
    /// @param onBehalfOf address of the account on behalf of which this swap is opened.
    /// @param totalAmount total amount of the swap, represented in decimals specific to the asset.
    /// @param acceptableFixedInterestRate acceptable fixed interest rate, represented in 18 decimals.
    /// @param leverage swap leverage, represented in 18 decimals.
    /// @return swapId ID of the opened swap.
    /// @dev Owner of that swap is the user with address `onBehalfOf`. Sender pays for the swap.
    function openSwapPayFixed90daysUsdt(
        address onBehalfOf,
        uint256 totalAmount,
        uint256 acceptableFixedInterestRate,
        uint256 leverage
    ) external returns (uint256);

    /// @notice Open new swap receive fixed pay floating with maturity in 28 days for asset USDT.
    /// @param onBehalfOf address of the account on behalf of which this swap is opened.
    /// @param totalAmount total amount of the swap, represented in decimals specific to the asset.
    /// @param acceptableFixedInterestRate acceptable fixed interest rate, represented in 18 decimals.
    /// @param leverage swap leverage, represented in 18 decimals.
    /// @return swapId ID of the opened swap.
    /// @dev Owner of that swap is the user with address `onBehalfOf`. Sender pays for the swap.
    function openSwapReceiveFixed28daysUsdt(
        address onBehalfOf,
        uint256 totalAmount,
        uint256 acceptableFixedInterestRate,
        uint256 leverage
    ) external returns (uint256);

    /// @notice Open new swap receive fixed pay floating with maturity in 60 days for asset USDT.
    /// @param onBehalfOf address of the account on behalf of which this swap is opened.
    /// @param totalAmount total amount of the swap, represented in decimals specific to the asset.
    /// @param acceptableFixedInterestRate acceptable fixed interest rate, represented in 18 decimals.
    /// @param leverage swap leverage, represented in 18 decimals.
    /// @return swapId ID of the opened swap.
    /// @dev Owner of that swap is the user with address `onBehalfOf`. Sender pays for the swap.
    function openSwapReceiveFixed60daysUsdt(
        address onBehalfOf,
        uint256 totalAmount,
        uint256 acceptableFixedInterestRate,
        uint256 leverage
    ) external returns (uint256);

    /// @notice Open new swap receive fixed pay floating with maturity in 90 days for asset USDT.
    /// @param onBehalfOf address of the account on behalf of which this swap is opened.
    /// @param totalAmount total amount of the swap, represented in decimals specific to the asset.
    /// @param acceptableFixedInterestRate acceptable fixed interest rate, represented in 18 decimals.
    /// @param leverage swap leverage, represented in 18 decimals.
    /// @return swapId ID of the opened swap.
    /// @dev Owner of that swap is the user with address `onBehalfOf`. Sender pays for the swap.
    function openSwapReceiveFixed90daysUsdt(
        address onBehalfOf,
        uint256 totalAmount,
        uint256 acceptableFixedInterestRate,
        uint256 leverage
    ) external returns (uint256);

    /// @notice Open new swap pay fixed receive floating with maturity in 28 days for asset USDC.
    /// @param onBehalfOf address of the account on behalf of which this swap is opened.
    /// @param totalAmount total amount of the swap, represented in decimals specific to the asset.
    /// @param acceptableFixedInterestRate acceptable fixed interest rate, represented in 18 decimals.
    /// @param leverage swap leverage, represented in 18 decimals.
    /// @return swapId ID of the opened swap.
    /// @dev Owner of that swap is the user with address `onBehalfOf`. Sender pays for the swap.
    function openSwapPayFixed28daysUsdc(
        address onBehalfOf,
        uint256 totalAmount,
        uint256 acceptableFixedInterestRate,
        uint256 leverage
    ) external returns (uint256);

    /// @notice Open new swap pay fixed receive floating with maturity in 60 days for asset USDC.
    /// @param onBehalfOf address of the account on behalf of which this swap is opened.
    /// @param totalAmount total amount of the swap, represented in decimals specific to the asset.
    /// @param acceptableFixedInterestRate acceptable fixed interest rate, represented in 18 decimals.
    /// @param leverage swap leverage, represented in 18 decimals.
    /// @return swapId ID of the opened swap.
    /// @dev Owner of that swap is the user with address `onBehalfOf`. Sender pays for the swap.
    function openSwapPayFixed60daysUsdc(
        address onBehalfOf,
        uint256 totalAmount,
        uint256 acceptableFixedInterestRate,
        uint256 leverage
    ) external returns (uint256);

    /// @notice Open new swap pay fixed receive floating with maturity in 90 days for asset USDC.
    /// @param onBehalfOf address of the account on behalf of which this swap is opened.
    /// @param totalAmount total amount of the swap, represented in decimals specific to the asset.
    /// @param acceptableFixedInterestRate acceptable fixed interest rate, represented in 18 decimals.
    /// @param leverage swap leverage, represented in 18 decimals.
    /// @return swapId ID of the opened swap.
    /// @dev Owner of that swap is the user with address `onBehalfOf`. Sender pays for the swap.
    function openSwapPayFixed90daysUsdc(
        address onBehalfOf,
        uint256 totalAmount,
        uint256 acceptableFixedInterestRate,
        uint256 leverage
    ) external returns (uint256);

    /// @notice Open new swap receive fixed pay floating with maturity in 28 days for asset USDC.
    /// @param onBehalfOf address of the account on behalf of which this swap is opened.
    /// @param totalAmount total amount of the swap, represented in decimals specific to the asset.
    /// @param acceptableFixedInterestRate acceptable fixed interest rate, represented in 18 decimals.
    /// @param leverage swap leverage, represented in 18 decimals.
    /// @return swapId ID of the opened swap.
    /// @dev Owner of that swap is the user with address `onBehalfOf`. Sender pays for the swap.
    function openSwapReceiveFixed28daysUsdc(
        address onBehalfOf,
        uint256 totalAmount,
        uint256 acceptableFixedInterestRate,
        uint256 leverage
    ) external returns (uint256);

    /// @notice Open new swap receive fixed pay floating with maturity in 60 days for asset USDC.
    /// @param onBehalfOf address of the account on behalf of which this swap is opened.
    /// @param totalAmount total amount of the swap, represented in decimals specific to the asset.
    /// @param acceptableFixedInterestRate acceptable fixed interest rate, represented in 18 decimals.
    /// @param leverage swap leverage, represented in 18 decimals.
    /// @return swapId ID of the opened swap.
    /// @dev Owner of that swap is the user with address `onBehalfOf`. Sender pays for the swap.
    function openSwapReceiveFixed60daysUsdc(
        address onBehalfOf,
        uint256 totalAmount,
        uint256 acceptableFixedInterestRate,
        uint256 leverage
    ) external returns (uint256);

    /// @notice Open new swap receive fixed pay floating with maturity in 90 days for asset USDC.
    /// @param onBehalfOf address of the account on behalf of which this swap is opened.
    /// @param totalAmount total amount of the swap, represented in decimals specific to the asset.
    /// @param acceptableFixedInterestRate acceptable fixed interest rate, represented in 18 decimals.
    /// @param leverage swap leverage, represented in 18 decimals.
    /// @return swapId ID of the opened swap.
    /// @dev Owner of that swap is the user with address `onBehalfOf`. Sender pays for the swap.
    function openSwapReceiveFixed90daysUsdc(
        address onBehalfOf,
        uint256 totalAmount,
        uint256 acceptableFixedInterestRate,
        uint256 leverage
    ) external returns (uint256);

    /// @notice Open new swap pay fixed receive floating with maturity in 28 days for asset DAI.
    /// @param onBehalfOf address of the account on behalf of which this swap is opened.
    /// @param totalAmount total amount of the swap, represented in decimals specific to the asset.
    /// @param acceptableFixedInterestRate acceptable fixed interest rate, represented in 18 decimals.
    /// @param leverage swap leverage, represented in 18 decimals.
    /// @return swapId ID of the opened swap.
    /// @dev Owner of that swap is the user with address `onBehalfOf`. Sender pays for the swap.
    function openSwapPayFixed28daysDai(
        address onBehalfOf,
        uint256 totalAmount,
        uint256 acceptableFixedInterestRate,
        uint256 leverage
    ) external returns (uint256);

    /// @notice Open new swap pay fixed receive floating with maturity in 60 days for asset DAI.
    /// @param onBehalfOf address of the account on behalf of which this swap is opened.
    /// @param totalAmount total amount of the swap, represented in decimals specific to the asset.
    /// @param acceptableFixedInterestRate acceptable fixed interest rate, represented in 18 decimals.
    /// @param leverage swap leverage, represented in 18 decimals.
    /// @return swapId ID of the opened swap.
    /// @dev Owner of that swap is the user with address `onBehalfOf`. Sender pays for the swap.
    function openSwapPayFixed60daysDai(
        address onBehalfOf,
        uint256 totalAmount,
        uint256 acceptableFixedInterestRate,
        uint256 leverage
    ) external returns (uint256);

    /// @notice Open new swap pay fixed receive floating with maturity in 90 days for asset DAI.
    /// @param onBehalfOf address of the account on behalf of which this swap is opened.
    /// @param totalAmount total amount of the swap, represented in decimals specific to the asset.
    /// @param acceptableFixedInterestRate acceptable fixed interest rate, represented in 18 decimals.
    /// @param leverage swap leverage, represented in 18 decimals.
    /// @return swapId ID of the opened swap.
    /// @dev Owner of that swap is the user with address `onBehalfOf`. Sender pays for the swap.
    function openSwapPayFixed90daysDai(
        address onBehalfOf,
        uint256 totalAmount,
        uint256 acceptableFixedInterestRate,
        uint256 leverage
    ) external returns (uint256);

    /// @notice Open new swap receive fixed pay floating with maturity in 28 days for asset DAI.
    /// @param onBehalfOf address of the account on behalf of which this swap is opened.
    /// @param totalAmount total amount of the swap, represented in decimals specific to the asset.
    /// @param acceptableFixedInterestRate acceptable fixed interest rate, represented in 18 decimals.
    /// @param leverage swap leverage, represented in 18 decimals.
    /// @return swapId ID of the opened swap.
    /// @dev Owner of that swap is the user with address `onBehalfOf`. Sender pays for the swap.
    function openSwapReceiveFixed28daysDai(
        address onBehalfOf,
        uint256 totalAmount,
        uint256 acceptableFixedInterestRate,
        uint256 leverage
    ) external returns (uint256);

    /// @notice Open new swap receive fixed pay floating with maturity in 60 days for asset DAI.
    /// @param onBehalfOf address of the account on behalf of which this swap is opened.
    /// @param totalAmount total amount of the swap, represented in decimals specific to the asset.
    /// @param acceptableFixedInterestRate acceptable fixed interest rate, represented in 18 decimals.
    /// @param leverage swap leverage, represented in 18 decimals.
    /// @return swapId ID of the opened swap.
    /// @dev Owner of that swap is the user with address `onBehalfOf`. Sender pays for the swap.
    function openSwapReceiveFixed60daysDai(
        address onBehalfOf,
        uint256 totalAmount,
        uint256 acceptableFixedInterestRate,
        uint256 leverage
    ) external returns (uint256);

    /// @notice Open new swap receive fixed pay floating with maturity in 90 days for asset DAI.
    /// @param onBehalfOf address of the account on behalf of which this swap is opened.
    /// @param totalAmount total amount of the swap, represented in decimals specific to the asset.
    /// @param acceptableFixedInterestRate acceptable fixed interest rate, represented in 18 decimals.
    /// @param leverage swap leverage, represented in 18 decimals.
    /// @return swapId ID of the opened swap.
    /// @dev Owner of that swap is the user with address `onBehalfOf`. Sender pays for the swap.
    function openSwapReceiveFixed90daysDai(
        address onBehalfOf,
        uint256 totalAmount,
        uint256 acceptableFixedInterestRate,
        uint256 leverage
    ) external returns (uint256);
}

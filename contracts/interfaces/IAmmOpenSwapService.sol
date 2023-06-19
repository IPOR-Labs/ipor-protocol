// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.20;

import "../interfaces/types/AmmTypes.sol";

/// @title Interface of the service allowing to open new swaps.
interface IAmmOpenSwapService {
    /// @notice Emitted when the trader opens new swap.
    event OpenSwap(
        /// @notice swap ID.
        uint256 indexed swapId,
        /// @notice trader that opened the swap
        address indexed buyer,
        /// @notice underlying asset
        address asset,
        /// @notice swap direction, Pay Fixed Receive Floating (long) or Pay Floating Receive Fixed (short).
        AmmTypes.SwapDirection direction,
        /// @notice technical structure with amounts related with this swap
        AmmTypes.OpenSwapAmount amounts,
        /// @notice the moment when swap was opened
        uint256 openTimestamp,
        /// @notice the moment when swap will achieve maturity
        uint256 endTimestamp,
        /// @notice specific indicators related with this swap
        AmmTypes.IporSwapIndicator indicator
    );

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
        /// @notice ipor publication fee, fee used when opening swap, represented in 18 decimals.
        uint256 iporPublicationFee;
        /// @notice maximum swap collateral amount, represented in 18 decimals.
        uint256 maxSwapCollateralAmount;
        /// @notice liquidation deposit amount, represented WITHOUT 18 decimals. Example 25 = 25 USDT.
        uint256 liquidationDepositAmount;
        /// @notice minimum leverage, represented in 18 decimals.
        uint256 minLeverage;
        /// @notice swap's opening fee rate, represented in 18 decimals. 1e18 = 100%
        uint256 openingFeeRate;
        /// @notice swap's opening fee rate, portion of the rate which is allocated to "treasury" balance
        /// @dev Value describes what percentage of opening fee amount is allocated to "treasury" balance. Value represented in 18 decimals. 1e18 = 100%
        uint256 openingFeeTreasuryPortionRate;
    }

    /// @notice Returns configuration of the AmmOpenSwapServicePool for specific asset (pool).
    /// @param asset address of the asset
    /// @return AmmOpenSwapServicePoolConfiguration structure representing configuration of the AmmOpenSwapServicePool for specific asset (pool).
    function getAmmOpenSwapServicePoolConfiguration(
        address asset
    ) external view returns (AmmOpenSwapServicePoolConfiguration memory);

    /// @notice Open new swap pay fixed receive floating with tenor in 28 days for asset USDT.
    /// @param beneficiary address of the account on behalf of which this swap is opened.
    /// @param totalAmount total amount used by sender to open this swap, represented in decimals specific to the asset.
    /// @param acceptableFixedInterestRate acceptable fixed interest rate, represented in 18 decimals.
    /// @param leverage swap leverage, represented in 18 decimals.
    /// @return swapId ID of the opened swap.
    /// @dev Owner of that swap is the user with address `beneficiary`. Sender pays for the swap.
    function openSwapPayFixed28daysUsdt(
        address beneficiary,
        uint256 totalAmount,
        uint256 acceptableFixedInterestRate,
        uint256 leverage
    ) external returns (uint256);

    /// @notice Open new swap pay fixed receive floating with tenor in 60 days for asset USDT.
    /// @param beneficiary address of the account on behalf of which this swap is opened.
    /// @param totalAmount total amount used by sender to open this swap, represented in decimals specific to the asset.
    /// @param acceptableFixedInterestRate acceptable fixed interest rate, represented in 18 decimals.
    /// @param leverage swap leverage, represented in 18 decimals.
    /// @return swapId ID of the opened swap.
    /// @dev Owner of that swap is the user with address `beneficiary`. Sender pays for the swap.
    function openSwapPayFixed60daysUsdt(
        address beneficiary,
        uint256 totalAmount,
        uint256 acceptableFixedInterestRate,
        uint256 leverage
    ) external returns (uint256);

    /// @notice Open new swap pay fixed receive floating with tenor in 90 days for asset USDT.
    /// @param beneficiary address of the account on behalf of which this swap is opened.
    /// @param totalAmount total amount used by sender to open this swap, represented in decimals specific to the asset.
    /// @param acceptableFixedInterestRate acceptable fixed interest rate, represented in 18 decimals.
    /// @param leverage swap leverage, represented in 18 decimals.
    /// @return swapId ID of the opened swap.
    /// @dev Owner of that swap is the user with address `beneficiary`. Sender pays for the swap.
    function openSwapPayFixed90daysUsdt(
        address beneficiary,
        uint256 totalAmount,
        uint256 acceptableFixedInterestRate,
        uint256 leverage
    ) external returns (uint256);

    /// @notice Open new swap receive fixed pay floating with tenor in 28 days for asset USDT.
    /// @param beneficiary address of the account on behalf of which this swap is opened.
    /// @param totalAmount total amount used by sender to open this swap, represented in decimals specific to the asset.
    /// @param acceptableFixedInterestRate acceptable fixed interest rate, represented in 18 decimals.
    /// @param leverage swap leverage, represented in 18 decimals.
    /// @return swapId ID of the opened swap.
    /// @dev Owner of that swap is the user with address `beneficiary`. Sender pays for the swap.
    function openSwapReceiveFixed28daysUsdt(
        address beneficiary,
        uint256 totalAmount,
        uint256 acceptableFixedInterestRate,
        uint256 leverage
    ) external returns (uint256);

    /// @notice Open new swap receive fixed pay floating with tenor in 60 days for asset USDT.
    /// @param beneficiary address of the account on behalf of which this swap is opened.
    /// @param totalAmount total amount used by sender to open this swap, represented in decimals specific to the asset.
    /// @param acceptableFixedInterestRate acceptable fixed interest rate, represented in 18 decimals.
    /// @param leverage swap leverage, represented in 18 decimals.
    /// @return swapId ID of the opened swap.
    /// @dev Owner of that swap is the user with address `beneficiary`. Sender pays for the swap.
    function openSwapReceiveFixed60daysUsdt(
        address beneficiary,
        uint256 totalAmount,
        uint256 acceptableFixedInterestRate,
        uint256 leverage
    ) external returns (uint256);

    /// @notice Open new swap receive fixed pay floating with tenor in 90 days for asset USDT.
    /// @param beneficiary address of the account on behalf of which this swap is opened.
    /// @param totalAmount total amount used by sender to open this swap, represented in decimals specific to the asset.
    /// @param acceptableFixedInterestRate acceptable fixed interest rate, represented in 18 decimals.
    /// @param leverage swap leverage, represented in 18 decimals.
    /// @return swapId ID of the opened swap.
    /// @dev Owner of that swap is the user with address `beneficiary`. Sender pays for the swap.
    function openSwapReceiveFixed90daysUsdt(
        address beneficiary,
        uint256 totalAmount,
        uint256 acceptableFixedInterestRate,
        uint256 leverage
    ) external returns (uint256);

    /// @notice Open new swap pay fixed receive floating with tenor in 28 days for asset USDC.
    /// @param beneficiary address of the account on behalf of which this swap is opened.
    /// @param totalAmount total amount used by sender to open this swap, represented in decimals specific to the asset.
    /// @param acceptableFixedInterestRate acceptable fixed interest rate, represented in 18 decimals.
    /// @param leverage swap leverage, represented in 18 decimals.
    /// @return swapId ID of the opened swap.
    /// @dev Owner of that swap is the user with address `beneficiary`. Sender pays for the swap.
    function openSwapPayFixed28daysUsdc(
        address beneficiary,
        uint256 totalAmount,
        uint256 acceptableFixedInterestRate,
        uint256 leverage
    ) external returns (uint256);

    /// @notice Open new swap pay fixed receive floating with tenor in 60 days for asset USDC.
    /// @param beneficiary address of the account on behalf of which this swap is opened.
    /// @param totalAmount total amount used by sender to open this swap, represented in decimals specific to the asset.
    /// @param acceptableFixedInterestRate acceptable fixed interest rate, represented in 18 decimals.
    /// @param leverage swap leverage, represented in 18 decimals.
    /// @return swapId ID of the opened swap.
    /// @dev Owner of that swap is the user with address `beneficiary`. Sender pays for the swap.
    function openSwapPayFixed60daysUsdc(
        address beneficiary,
        uint256 totalAmount,
        uint256 acceptableFixedInterestRate,
        uint256 leverage
    ) external returns (uint256);

    /// @notice Open new swap pay fixed receive floating with tenor in 90 days for asset USDC.
    /// @param beneficiary address of the account on behalf of which this swap is opened.
    /// @param totalAmount total amount used by sender to open this swap, represented in decimals specific to the asset.
    /// @param acceptableFixedInterestRate acceptable fixed interest rate, represented in 18 decimals.
    /// @param leverage swap leverage, represented in 18 decimals.
    /// @return swapId ID of the opened swap.
    /// @dev Owner of that swap is the user with address `beneficiary`. Sender pays for the swap.
    function openSwapPayFixed90daysUsdc(
        address beneficiary,
        uint256 totalAmount,
        uint256 acceptableFixedInterestRate,
        uint256 leverage
    ) external returns (uint256);

    /// @notice Open new swap receive fixed pay floating with tenor in 28 days for asset USDC.
    /// @param beneficiary address of the account on behalf of which this swap is opened.
    /// @param totalAmount total amount used by sender to open this swap, represented in decimals specific to the asset.
    /// @param acceptableFixedInterestRate acceptable fixed interest rate, represented in 18 decimals.
    /// @param leverage swap leverage, represented in 18 decimals.
    /// @return swapId ID of the opened swap.
    /// @dev Owner of that swap is the user with address `beneficiary`. Sender pays for the swap.
    function openSwapReceiveFixed28daysUsdc(
        address beneficiary,
        uint256 totalAmount,
        uint256 acceptableFixedInterestRate,
        uint256 leverage
    ) external returns (uint256);

    /// @notice Open new swap receive fixed pay floating with tenor in 60 days for asset USDC.
    /// @param beneficiary address of the account on behalf of which this swap is opened.
    /// @param totalAmount total amount used by sender to open this swap, represented in decimals specific to the asset.
    /// @param acceptableFixedInterestRate acceptable fixed interest rate, represented in 18 decimals.
    /// @param leverage swap leverage, represented in 18 decimals.
    /// @return swapId ID of the opened swap.
    /// @dev Owner of that swap is the user with address `beneficiary`. Sender pays for the swap.
    function openSwapReceiveFixed60daysUsdc(
        address beneficiary,
        uint256 totalAmount,
        uint256 acceptableFixedInterestRate,
        uint256 leverage
    ) external returns (uint256);

    /// @notice Open new swap receive fixed pay floating with tenor in 90 days for asset USDC.
    /// @param beneficiary address of the account on behalf of which this swap is opened.
    /// @param totalAmount total amount used by sender to open this swap, represented in decimals specific to the asset.
    /// @param acceptableFixedInterestRate acceptable fixed interest rate, represented in 18 decimals.
    /// @param leverage swap leverage, represented in 18 decimals.
    /// @return swapId ID of the opened swap.
    /// @dev Owner of that swap is the user with address `beneficiary`. Sender pays for the swap.
    function openSwapReceiveFixed90daysUsdc(
        address beneficiary,
        uint256 totalAmount,
        uint256 acceptableFixedInterestRate,
        uint256 leverage
    ) external returns (uint256);

    /// @notice Open new swap pay fixed receive floating with tenor in 28 days for asset DAI.
    /// @param beneficiary address of the account on behalf of which this swap is opened.
    /// @param totalAmount total amount used by sender to open this swap, represented in decimals specific to the asset.
    /// @param acceptableFixedInterestRate acceptable fixed interest rate, represented in 18 decimals.
    /// @param leverage swap leverage, represented in 18 decimals.
    /// @return swapId ID of the opened swap.
    /// @dev Owner of that swap is the user with address `beneficiary`. Sender pays for the swap.
    function openSwapPayFixed28daysDai(
        address beneficiary,
        uint256 totalAmount,
        uint256 acceptableFixedInterestRate,
        uint256 leverage
    ) external returns (uint256);

    /// @notice Open new swap pay fixed receive floating with tenor in 60 days for asset DAI.
    /// @param beneficiary address of the account on behalf of which this swap is opened.
    /// @param totalAmount total amount used by sender to open this swap, represented in decimals specific to the asset.
    /// @param acceptableFixedInterestRate acceptable fixed interest rate, represented in 18 decimals.
    /// @param leverage swap leverage, represented in 18 decimals.
    /// @return swapId ID of the opened swap.
    /// @dev Owner of that swap is the user with address `beneficiary`. Sender pays for the swap.
    function openSwapPayFixed60daysDai(
        address beneficiary,
        uint256 totalAmount,
        uint256 acceptableFixedInterestRate,
        uint256 leverage
    ) external returns (uint256);

    /// @notice Open new swap pay fixed receive floating with tenor in 90 days for asset DAI.
    /// @param beneficiary address of the account on behalf of which this swap is opened.
    /// @param totalAmount total amount used by sender to open this swap, represented in decimals specific to the asset.
    /// @param acceptableFixedInterestRate acceptable fixed interest rate, represented in 18 decimals.
    /// @param leverage swap leverage, represented in 18 decimals.
    /// @return swapId ID of the opened swap.
    /// @dev Owner of that swap is the user with address `beneficiary`. Sender pays for the swap.
    function openSwapPayFixed90daysDai(
        address beneficiary,
        uint256 totalAmount,
        uint256 acceptableFixedInterestRate,
        uint256 leverage
    ) external returns (uint256);

    /// @notice Open new swap receive fixed pay floating with tenor in 28 days for asset DAI.
    /// @param beneficiary address of the account on behalf of which this swap is opened.
    /// @param totalAmount total amount used by sender to open this swap, represented in decimals specific to the asset.
    /// @param acceptableFixedInterestRate acceptable fixed interest rate, represented in 18 decimals.
    /// @param leverage swap leverage, represented in 18 decimals.
    /// @return swapId ID of the opened swap.
    /// @dev Owner of that swap is the user with address `beneficiary`. Sender pays for the swap.
    function openSwapReceiveFixed28daysDai(
        address beneficiary,
        uint256 totalAmount,
        uint256 acceptableFixedInterestRate,
        uint256 leverage
    ) external returns (uint256);

    /// @notice Open new swap receive fixed pay floating with tenor in 60 days for asset DAI.
    /// @param beneficiary address of the account on behalf of which this swap is opened.
    /// @param totalAmount total amount used by sender to open this swap, represented in decimals specific to the asset.
    /// @param acceptableFixedInterestRate acceptable fixed interest rate, represented in 18 decimals.
    /// @param leverage swap leverage, represented in 18 decimals.
    /// @return swapId ID of the opened swap.
    /// @dev Owner of that swap is the user with address `beneficiary`. Sender pays for the swap.
    function openSwapReceiveFixed60daysDai(
        address beneficiary,
        uint256 totalAmount,
        uint256 acceptableFixedInterestRate,
        uint256 leverage
    ) external returns (uint256);

    /// @notice Open new swap receive fixed pay floating with tenor in 90 days for asset DAI.
    /// @param beneficiary address of the account on behalf of which this swap is opened.
    /// @param totalAmount total amount used by sender to open this swap, represented in decimals specific to the asset.
    /// @param acceptableFixedInterestRate acceptable fixed interest rate, represented in 18 decimals.
    /// @param leverage swap leverage, represented in 18 decimals.
    /// @return swapId ID of the opened swap.
    /// @dev Owner of that swap is the user with address `beneficiary`. Sender pays for the swap.
    function openSwapReceiveFixed90daysDai(
        address beneficiary,
        uint256 totalAmount,
        uint256 acceptableFixedInterestRate,
        uint256 leverage
    ) external returns (uint256);
}

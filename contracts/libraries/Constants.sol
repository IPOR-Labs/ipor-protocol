// SPDX-License-Identifier: agpl-3.0
pragma solidity >=0.8.4 <0.9.0;

library Constants {

    uint256 constant LAS_VEGAS_DECIMALS_FACTOR = 1e18;

    uint256 constant YEAR_IN_SECONDS = 60 * 60 * 24 * 365;

    uint256 constant YEAR_IN_SECONDS_WITH_FACTOR = YEAR_IN_SECONDS * LAS_VEGAS_DECIMALS_FACTOR;

    //@notice By default every derivative takes 28 days, this variable show this value in seconds
    uint256 constant DERIVATIVE_DEFAULT_PERIOD_IN_SECONDS = 60 * 60 * 24 * 28;

    //@notice amount of asset taken in case of deposit liquidation
    uint256 constant LIQUIDATION_DEPOSIT_FEE_AMOUNT = 20 * 1e18;

    //@notice amount of asset taken for IPOR publication
    uint256 constant IPOR_PUBLICATION_FEE_AMOUNT = 10 * 1e18;

    //@notice percentage of deposit amount
    uint256 constant OPENING_FEE_PERCENTAGE = 1e16;

}
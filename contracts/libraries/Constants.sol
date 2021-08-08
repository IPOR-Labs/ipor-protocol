// SPDX-License-Identifier: agpl-3.0
pragma solidity >=0.8.4 <0.9.0;

library Constants {

    uint256 constant MILTON_DECIMALS_FACTOR = 1e18;

    uint256 constant YEAR_IN_SECONDS = 60 * 60 * 24 * 365;

    uint256 constant YEAR_IN_SECONDS_WITH_FACTOR = YEAR_IN_SECONDS * MILTON_DECIMALS_FACTOR;

    //@notice By default every derivative takes 28 days, this variable show this value in seconds
    uint256 constant DERIVATIVE_DEFAULT_PERIOD_IN_SECONDS = 60 * 60 * 24 * 28;

}
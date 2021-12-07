// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.9;

library Constants {
    uint256 constant MAX_VALUE =
        115792089237316195423570985008687907853269984665640564039457584007913129639935;
	uint256 constant D4 = 1e4;
    uint256 constant D6 = 1e6;
    uint256 constant D18 = 1e18;

    uint256 constant YEAR_IN_SECONDS = 60 * 60 * 24 * 365;

    //@notice By default every derivative takes 28 days, this variable show this value in seconds
    uint256 constant DERIVATIVE_DEFAULT_PERIOD_IN_SECONDS = 60 * 60 * 24 * 28;
}

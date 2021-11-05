// SPDX-License-Identifier: agpl-3.0
pragma solidity >=0.8.4 <0.9.0;

library Constants {

    uint256 constant MAX_VALUE = 115792089237316195423570985008687907853269984665640564039457584007913129639935;
    uint256 constant D6 = 1e6;
    uint256 constant D18 = 1e18;
    //@notice Milton Decimals
    uint256 constant MD = 1e18;
    uint256 constant MD_P2 = 1e36;


    uint256 constant YEAR_IN_SECONDS = 60 * 60 * 24 * 365;

    uint256 constant MD_P2_YEAR_IN_SECONDS = MD_P2 * YEAR_IN_SECONDS;
    int256 constant MD_P2_YEAR_IN_SECONDS_INT = int256(MD_P2_YEAR_IN_SECONDS);
    uint256 constant MD_YEAR_IN_SECONDS = MD * YEAR_IN_SECONDS;

    //@notice By default every derivative takes 28 days, this variable show this value in seconds
    uint256 constant DERIVATIVE_DEFAULT_PERIOD_IN_SECONDS = 60 * 60 * 24 * 28;

}

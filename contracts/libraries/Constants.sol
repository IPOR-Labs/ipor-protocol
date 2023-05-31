// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.16;

library Constants {
    uint256 public constant MAX_VALUE = 115792089237316195423570985008687907853269984665640564039457584007913129639935;

    uint256 public constant WAD_LEVERAGE_1000 = 1_000e18;
    uint256 public constant WAD_YEAR_IN_SECONDS = YEAR_IN_SECONDS * 1e18;

    uint256 public constant YEAR_IN_SECONDS = 365 days;
    uint256 public constant MAX_CHUNK_SIZE = 50;
}

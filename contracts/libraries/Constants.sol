// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.9;

library Constants {

	//@notice Euler number (2.7182818284590452353602874713526624977572470936999595749669676277240766303535475945713821785251664274) using 18 decimals
	uint256 public constant E_VALUE = 2718281828459045235;
	
	
    uint256 public constant MAX_VALUE =
        115792089237316195423570985008687907853269984665640564039457584007913129639935;
    uint256 public constant D4 = 1e4;
    uint256 public constant D6 = 1e6;
    uint256 public constant D18 = 1e18;
	uint256 public constant D16 = 1e16;
	uint256 public constant D36 = 1e36;
	uint256 public constant D54 = 1e54;

    uint256 public constant YEAR_IN_SECONDS = 365 days;
    uint256 public constant WAD_YEAR_IN_SECONDS = D18 * YEAR_IN_SECONDS;
    int256 public constant WAD_YEAR_IN_SECONDS_INT =
        int256(WAD_YEAR_IN_SECONDS);
    uint256 public constant WAD_P2_YEAR_IN_SECONDS =
        D18 * D18 * YEAR_IN_SECONDS;
    int256 public constant WAD_P2_YEAR_IN_SECONDS_INT =
        int256(WAD_P2_YEAR_IN_SECONDS);

    //@notice By default every swap takes 28 days, this variable show this value in seconds
    uint256 public constant SWAP_DEFAULT_PERIOD_IN_SECONDS =
        60 * 60 * 24 * 28;
}

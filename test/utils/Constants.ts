import { BigNumber } from "ethers";

export const ZERO = BigNumber.from("0");

// #################################################################################
//                              18 detimals
// #################################################################################

export const N1__0_18DEC = BigNumber.from("1000000000000000000");
export const N0__1_18DEC = BigNumber.from("100000000000000000");
export const N0__01_18DEC = BigNumber.from("10000000000000000");
export const N0__001_18DEC = BigNumber.from("1000000000000000");
export const N0__000_1_18DEC = BigNumber.from("100000000000000");
export const N0__000_01_18DEC = BigNumber.from("10000000000000");
export const N0__000_001_18DEC = BigNumber.from("1000000000000");

export const USD_3_18DEC = BigNumber.from("3").mul(N1__0_18DEC);
export const USD_10_18DEC = BigNumber.from("10").mul(N1__0_18DEC);
export const USD_1_000_18DEC = BigNumber.from("1000").mul(N1__0_18DEC);
export const USD_10_000_18DEC = BigNumber.from("10000").mul(N1__0_18DEC);
export const USD_14_000_18DEC = BigNumber.from("14000").mul(N1__0_18DEC);
export const USD_19_997_18DEC = BigNumber.from("19997").mul(N1__0_18DEC);
export const USD_20_000_18DEC = BigNumber.from("20000").mul(N1__0_18DEC);
export const USD_28_000_18DEC = BigNumber.from("28000").mul(N1__0_18DEC);

export const PERCENTAGE_2_5_18DEC = BigNumber.from("25").mul(N0__001_18DEC);
export const PERCENTAGE_3_18DEC = BigNumber.from("3").mul(N0__01_18DEC);
export const PERCENTAGE_8_18DEC = BigNumber.from("8").mul(N0__01_18DEC);
export const PERCENTAGE_50_18DEC = BigNumber.from("50").mul(N0__01_18DEC);

export const TC_50_000_18DEC = BigNumber.from("50000").mul(N1__0_18DEC);
export const TC_TOTAL_AMOUNT_10_000_18DEC = BigNumber.from("10000").mul(N1__0_18DEC);

export const TOTAL_SUPPLY_18_DECIMALS = BigNumber.from("10000000000000000").mul(N1__0_18DEC);
export const USER_SUPPLY_10MLN_18DEC = BigNumber.from("10000000").mul(N1__0_18DEC);

export const LEVERAGE_18DEC = BigNumber.from("10").mul(N1__0_18DEC);

// #################################################################################
//                              6 detimals
// #################################################################################

export const N1__0_6DEC = BigNumber.from("1000000");
export const N0__1_6DEC = BigNumber.from("100000");
export const N0__01_6DEC = BigNumber.from("10000");
export const N0__001_6DEC = BigNumber.from("1000");
export const N0__000_1_6DEC = BigNumber.from("100");
export const N0__000_01_6DEC = BigNumber.from("10");

export const USD_10_000_6DEC = BigNumber.from("10000").mul(N1__0_6DEC);
export const USD_14_000_6DEC = BigNumber.from("14000").mul(N1__0_6DEC);

export const TOTAL_SUPPLY_6_DECIMALS = BigNumber.from("100000000000000").mul(N1__0_6DEC);

export const USER_SUPPLY_6_DECIMALS = BigNumber.from("10000000").mul(N1__0_6DEC);

// #################################################################################
//                              Time
// #################################################################################
export const YEAR_IN_SECONDS = BigNumber.from("31536000");
export const PERIOD_25_DAYS_IN_SECONDS = BigNumber.from(60 * 60 * 24 * 25);

export const SWAP_DEFAULT_PERIOD_IN_SECONDS = "2419200"; //60 * 60 * 24 * 28

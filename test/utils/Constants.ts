import { BigNumber } from "ethers";

export const ZERO = BigNumber.from("0");
export const LEG_PAY_FIXED = BigNumber.from("0");
export const LEG_RECEIVE_FIXED = BigNumber.from("1");

// #################################################################################
//                              18 decimals
// #################################################################################

export const N1__0_18DEC = BigNumber.from("1000000000000000000");
export const N0__1_18DEC = BigNumber.from("100000000000000000");
export const N0__01_18DEC = BigNumber.from("10000000000000000");
export const N0__001_18DEC = BigNumber.from("1000000000000000");
export const N0__000_1_18DEC = BigNumber.from("100000000000000");
export const N0__000_01_18DEC = BigNumber.from("10000000000000");
export const N0__000_001_18DEC = BigNumber.from("1000000000000");

export const USD_1_18DEC = N1__0_18DEC;
export const USD_3_18DEC = BigNumber.from("3").mul(N1__0_18DEC);
export const USD_10_18DEC = BigNumber.from("10").mul(N1__0_18DEC);
export const USD_20_18DEC = BigNumber.from("20").mul(N1__0_18DEC);
export const USD_100_18DEC = BigNumber.from("100").mul(N1__0_18DEC);

export const USD_500_18DEC = BigNumber.from("500").mul(N1__0_18DEC);
export const USD_1_000_18DEC = BigNumber.from("1000").mul(N1__0_18DEC);
export const USD_2_000_18DEC = BigNumber.from("2000").mul(N1__0_18DEC);
export const USD_10_000_18DEC = BigNumber.from("10000").mul(N1__0_18DEC);
export const USD_10_400_18DEC = BigNumber.from("10400").mul(N1__0_18DEC);
export const USD_13_000_18DEC = BigNumber.from("13000").mul(N1__0_18DEC);
export const USD_14_000_18DEC = BigNumber.from("14000").mul(N1__0_18DEC);
export const USD_15_000_18DEC = BigNumber.from("15000").mul(N1__0_18DEC);
export const USD_19_997_18DEC = BigNumber.from("19997").mul(N1__0_18DEC);
export const USD_20_000_18DEC = BigNumber.from("20000").mul(N1__0_18DEC);
export const USD_28_000_18DEC = BigNumber.from("28000").mul(N1__0_18DEC);
export const USD_50_000_18DEC = BigNumber.from("50000").mul(N1__0_18DEC);
export const USD_1_000_000_18DEC = BigNumber.from("1000000").mul(N1__0_18DEC);
export const USD_10_000_000_18DEC = BigNumber.from("10000000").mul(N1__0_18DEC);

export const PERCENTAGE_2_5_18DEC = BigNumber.from("25").mul(N0__001_18DEC);
export const PERCENTAGE_3_18DEC = BigNumber.from("3").mul(N0__01_18DEC);
export const PERCENTAGE_3_5_18DEC = BigNumber.from("35").mul(N0__001_18DEC);
export const PERCENTAGE_4_18DEC = BigNumber.from("4").mul(N0__01_18DEC);
export const PERCENTAGE_4_5_18DEC = BigNumber.from("45").mul(N0__001_18DEC);
export const PERCENTAGE_5_18DEC = BigNumber.from("5").mul(N0__01_18DEC);
export const PERCENTAGE_5_2222_18DEC = BigNumber.from("52222").mul(N0__000_001_18DEC);
export const PERCENTAGE_6_18DEC = BigNumber.from("6").mul(N0__01_18DEC);
export const PERCENTAGE_7_18DEC = BigNumber.from("7").mul(N0__01_18DEC);
export const PERCENTAGE_8_18DEC = BigNumber.from("8").mul(N0__01_18DEC);
export const PERCENTAGE_50_18DEC = BigNumber.from("50").mul(N0__01_18DEC);
export const PERCENTAGE_95_18DEC = BigNumber.from("95").mul(N0__01_18DEC);
export const PERCENTAGE_119_18DEC = BigNumber.from("119").mul(N0__01_18DEC);
export const PERCENTAGE_120_18DEC = BigNumber.from("120").mul(N0__01_18DEC);
export const PERCENTAGE_121_18DEC = BigNumber.from("121").mul(N0__01_18DEC);
export const PERCENTAGE_100_18DEC = BigNumber.from("100").mul(N0__01_18DEC);
export const PERCENTAGE_149_18DEC = BigNumber.from("149").mul(N0__01_18DEC);
export const PERCENTAGE_150_18DEC = BigNumber.from("150").mul(N0__01_18DEC);
export const PERCENTAGE_151_18DEC = BigNumber.from("151").mul(N0__01_18DEC);
export const PERCENTAGE_152_18DEC = BigNumber.from("152").mul(N0__01_18DEC);
export const PERCENTAGE_155_18DEC = BigNumber.from("155").mul(N0__01_18DEC);
export const PERCENTAGE_160_18DEC = BigNumber.from("160").mul(N0__01_18DEC);
export const PERCENTAGE_161_18DEC = BigNumber.from("161").mul(N0__01_18DEC);
export const PERCENTAGE_365_18DEC = BigNumber.from("365").mul(N0__01_18DEC);
export const PERCENTAGE_366_18DEC = BigNumber.from("366").mul(N0__01_18DEC);

export const TC_TOTAL_AMOUNT_100_18DEC = BigNumber.from("100").mul(N1__0_18DEC);
export const TC_50_000_18DEC = BigNumber.from("50000").mul(N1__0_18DEC);
export const TC_TOTAL_AMOUNT_10_000_18DEC = BigNumber.from("10000").mul(N1__0_18DEC);
export const TC_IBT_PRICE_DAI_18DEC = N1__0_18DEC;
export const TC_COLLATERAL_18DEC = BigNumber.from("9967009897030890732780");
export const TC_OPENING_FEE_18DEC = BigNumber.from("2990102969109267220");
export const TC_LP_BALANCE_BEFORE_CLOSE_18DEC = BigNumber.from("28000").mul(N1__0_18DEC);
export const TC_LIQUIDATION_DEPOSIT_AMOUNT_18DEC = BigNumber.from("20").mul(N1__0_18DEC);
export const TC_IPOR_PUBLICATION_AMOUNT_18DEC = BigNumber.from("10").mul(N1__0_18DEC);
export const TC_INCOME_TAX_18DEC = BigNumber.from("996700989703089073278");

export const TOTAL_SUPPLY_18_DECIMALS = BigNumber.from("10000000000000000").mul(N1__0_18DEC);
export const USER_SUPPLY_10MLN_18DEC = BigNumber.from("10000000").mul(N1__0_18DEC);

export const LEVERAGE_18DEC = BigNumber.from("10").mul(N1__0_18DEC);
export const LEVERAGE_1000_18DEC = BigNumber.from("1000").mul(N1__0_18DEC);

export const SPECIFIC_INCOME_TAX_CASE_1 = BigNumber.from("600751281464875607313");
export const SPECIFIC_INTEREST_AMOUNT_CASE_1 = BigNumber.from("6007512814648756073133");

// #################################################################################
//                              6 decimals
// #################################################################################

export const N1__0_6DEC = BigNumber.from("1000000");
export const N0__1_6DEC = BigNumber.from("100000");
export const N0__01_6DEC = BigNumber.from("10000");
export const N0__001_6DEC = BigNumber.from("1000");
export const N0__000_1_6DEC = BigNumber.from("100");
export const N0__000_01_6DEC = BigNumber.from("10");

export const USD_10_000_000 = BigNumber.from("10000000");
export const USD_1_000_000 = BigNumber.from("1000000");
export const USD_10_000_6DEC = BigNumber.from("10000").mul(N1__0_6DEC);
export const USD_14_000_6DEC = BigNumber.from("14000").mul(N1__0_6DEC);
export const USD_28_000_6DEC = BigNumber.from("28000").mul(N1__0_6DEC);
export const USD_50_000_6DEC = BigNumber.from("50000").mul(N1__0_6DEC);
export const USD_100_000_6DEC = BigNumber.from("50000").mul(N1__0_6DEC);
export const USD_10_000_000_6DEC = BigNumber.from("10000000").mul(N1__0_6DEC);

export const PERCENTAGE_3_6DEC = BigNumber.from("3").mul(N0__01_6DEC);
export const PERCENTAGE_6_6DEC = BigNumber.from("6").mul(N0__01_6DEC);
export const PERCENTAGE_7_6DEC = BigNumber.from("7").mul(N0__01_6DEC);
export const PERCENTAGE_50_6DEC = BigNumber.from("50").mul(N0__01_6DEC);

export const TC_DEFAULT_EMA_18DEC = BigNumber.from("3").mul(N0__01_18DEC);
export const TOTAL_SUPPLY_6_DECIMALS = BigNumber.from("100000000000000").mul(N1__0_6DEC);
export const TC_IBT_PRICE_DAI_6DEC = N1__0_6DEC;
export const TC_TOTAL_AMOUNT_100_6DEC = BigNumber.from("100").mul(N1__0_6DEC);
export const TC_TOTAL_AMOUNT_10_000_6DEC = BigNumber.from("10000").mul(N1__0_6DEC);
export const TC_LP_BALANCE_BEFORE_CLOSE_6DEC = BigNumber.from("28000").mul(N1__0_6DEC);
export const TC_LIQUIDATION_DEPOSIT_AMOUNT_6DEC = BigNumber.from("20").mul(N1__0_6DEC);
export const TC_IPOR_PUBLICATION_AMOUNT_6DEC = BigNumber.from("10").mul(N1__0_6DEC);
export const TC_OPENING_FEE_6DEC = BigNumber.from("2990103");
export const TC_COLLATERAL_6DEC = BigNumber.from("9967009897");

export const USER_SUPPLY_6_DECIMALS = BigNumber.from("10000000").mul(N1__0_6DEC);

// #################################################################################
//                              Time
// #################################################################################
export const YEAR_IN_SECONDS = BigNumber.from("31536000");
export const MONTH_IN_SECONDS = BigNumber.from(60 * 60 * 24 * 30);
export const PERIOD_25_DAYS_IN_SECONDS = BigNumber.from(60 * 60 * 24 * 25);
export const PERIOD_6_HOURS_IN_SECONDS = BigNumber.from(60 * 60 * 6);
export const SWAP_DEFAULT_PERIOD_IN_SECONDS = "2419200"; //60 * 60 * 24 * 28
export const PERIOD_60_DAYS_IN_SECONDS = BigNumber.from(60 * 60 * 24 * 60);
export const PERIOD_50_DAYS_IN_SECONDS = BigNumber.from(60 * 60 * 24 * 50);
export const PERIOD_56_DAYS_IN_SECONDS = BigNumber.from(60 * 60 * 24 * 56);

export const PERIOD_27_DAYS_IN_SECONDS = BigNumber.from(60 * 60 * 24 * 27);
export const PERIOD_28_DAYS_IN_SECONDS = BigNumber.from(60 * 60 * 24 * 28);
export const PERIOD_1_DAY_IN_SECONDS = BigNumber.from(60 * 60 * 24 * 1);
export const PERIOD_27_DAYS_23_HOURS_IN_SECONDS = BigNumber.from(60 * 60 * 24 * 27 + 60 * 60 * 23);
export const PERIOD_27_DAYS_17_HOURS_IN_SECONDS = BigNumber.from(60 * 60 * 24 * 27 + 60 * 60 * 17);
export const PERIOD_14_DAYS_IN_SECONDS = BigNumber.from(60 * 60 * 24 * 14);

// #################################################################################
//                              IporRiskManagementOracle
// #################################################################################
export const MSO_NOTIONAL_1B = BigNumber.from("100000");
export const MSO_UTILIZATION_RATE_48_PER = BigNumber.from("4800");
export const MSO_UTILIZATION_RATE_90_PER = BigNumber.from("9000");

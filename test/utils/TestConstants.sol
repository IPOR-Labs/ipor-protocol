// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.16;

library TestConstants {
    uint256 public constant MAX_VALUE = 115792089237316195423570985008687907853269984665640564039457584007913129639935;

    uint256 public constant D54 = 1e54;
    uint256 public constant D36 = 1e36;
    uint256 public constant D18 = 1e18;
    uint256 public constant D17 = 1e17;
    uint256 public constant D16 = 1e16;
    uint256 public constant D15 = 1e15;
    uint256 public constant D14 = 1e14;
    uint256 public constant D13 = 1e13;
    uint256 public constant D12 = 1e12;

    uint256 public constant USD_3_18DEC = 3 * 1e18;
    uint256 public constant USD_10_18DEC = 10 * 1e18;
    uint256 public constant USD_20_18DEC = 20 * 1e18;
    uint256 public constant USD_100_18DEC = 100 * 1e18;
    uint256 public constant USD_500_18DEC = 500 * 1e18;
    uint256 public constant USD_1_000_18DEC = 1000 * 1e18;
    uint256 public constant USD_1_500_18DEC = 1500 * 1e18;
    uint256 public constant USD_2_000_18DEC = 2000 * 1e18;
    uint256 public constant USD_5_000_18DEC = 5000 * 1e18;
    uint256 public constant USD_10_000_18DEC = 10000 * 1e18;
    uint256 public constant USD_10_400_18DEC = 10400 * 1e18;
    uint256 public constant USD_13_000_18DEC = 13000 * 1e18;
    uint256 public constant USD_14_000_18DEC = 14000 * 1e18;
    uint256 public constant USD_15_000_18DEC = 15000 * 1e18;
    uint256 public constant USD_19_997_18DEC = 19997 * 1e18;
    uint256 public constant USD_20_000_18DEC = 20000 * 1e18;
    uint256 public constant USD_28_000_18DEC = 28000 * 1e18;
    uint256 public constant USD_50_000_18DEC = 50000 * 1e18;
    uint256 public constant USD_100_000_18DEC = 100000 * 1e18;
    uint256 public constant USD_1_000_000_18DEC = 1000000 * 1e18;
    uint256 public constant USD_10_000_000_18DEC = 10000000 * 1e18;
    uint256 public constant USD_1_000_000_000_18DEC = 1000000000 * 1e18;
    int256 public constant USD_10_000_000_18DEC_INT = 10000000 * 1e18;

    uint256 public constant PERCENTAGE_1_18DEC = 1 * 1e16;
    uint256 public constant PERCENTAGE_2_18DEC = 2 * 1e16;
    uint256 public constant PERCENTAGE_2_5_18DEC = 25 * 1e15;
    uint256 public constant PERCENTAGE_3_18DEC = 3 * 1e16;
    uint256 public constant PERCENTAGE_3_5_18DEC = 35 * 1e15;
    uint256 public constant PERCENTAGE_4_18DEC = 4 * 1e16;
    uint256 public constant PERCENTAGE_4_5_18DEC = 45 * 1e15;
    uint256 public constant PERCENTAGE_5_18DEC = 5 * 1e16;
    uint256 public constant PERCENTAGE_5_2222_18DEC = 522222 * 1e12;
    uint256 public constant PERCENTAGE_6_18DEC = 6 * 1e16;
    uint256 public constant PERCENTAGE_7_18DEC = 7 * 1e16;
    uint256 public constant PERCENTAGE_8_18DEC = 8 * 1e16;
    uint256 public constant PERCENTAGE_9_18DEC = 9 * 1e16;
    uint256 public constant PERCENTAGE_10_18DEC = 10 * 1e16;
    uint256 public constant PERCENTAGE_16_18DEC = 16 * 1e16;
    uint256 public constant PERCENTAGE_50_18DEC = 50 * 1e16;
    uint256 public constant PERCENTAGE_95_18DEC = 95 * 1e16;
    uint256 public constant PERCENTAGE_119_18DEC = 119 * 1e16;
    uint256 public constant PERCENTAGE_120_18DEC = 120 * 1e16;
    uint256 public constant PERCENTAGE_121_18DEC = 121 * 1e16;
    uint256 public constant PERCENTAGE_100_18DEC = 100 * 1e16;
    uint256 public constant PERCENTAGE_149_18DEC = 149 * 1e16;
    uint256 public constant PERCENTAGE_150_18DEC = 150 * 1e16;
    uint256 public constant PERCENTAGE_151_18DEC = 151 * 1e16;
    uint256 public constant PERCENTAGE_152_18DEC = 152 * 1e16;
    uint256 public constant PERCENTAGE_155_18DEC = 155 * 1e16;
    uint256 public constant PERCENTAGE_159_18DEC = 159 * 1e16;
    uint256 public constant PERCENTAGE_160_18DEC = 160 * 1e16;
    uint256 public constant PERCENTAGE_161_18DEC = 161 * 1e16;
    uint256 public constant PERCENTAGE_365_18DEC = 365 * 1e16;
    uint256 public constant PERCENTAGE_366_18DEC = 366 * 1e16;
    uint256 public constant PERCENTAGE_400_18DEC = 400 * 1e16;

    uint256 public constant TC_TOTAL_AMOUNT_100_18DEC = 100 * 1e18;
    uint256 public constant TC_50_000_18DEC = 50000 * 1e18;
    uint256 public constant TC_TOTAL_AMOUNT_10_000_18DEC = 10000 * 1e18;
    uint256 public constant TC_COLLATERAL_18DEC = 9967009897030890732780;
    int256 public constant TC_COLLATERAL_18DEC_INT = 9967009897030890732780;
    uint256 public constant TC_OPENING_FEE_18DEC = 2990102969109267220;
    int256 public constant TC_OPENING_FEE_18DEC_INT = 2990102969109267220;
    uint256 public constant TC_LP_BALANCE_BEFORE_CLOSE_18DEC = 28000 * 1e18;
    uint256 public constant TC_LIQUIDATION_DEPOSIT_AMOUNT_18DEC = 20 * 1e18;
    int256 public constant TC_LIQUIDATION_DEPOSIT_AMOUNT_18DEC_INT = 20 * 1e18;
    uint256 public constant TC_IPOR_PUBLICATION_AMOUNT_18DEC = 10 * 1e18;
    int256 public constant TC_IPOR_PUBLICATION_AMOUNT_18DEC_INT = 10 * 1e18;
    uint256 public constant TC_INCOME_TAX_18DEC = 996700989703089073278;
    int256 public constant TC_INCOME_TAX_18DEC_INT = 996700989703089073278;

    uint256 public constant TOTAL_SUPPLY_18_DECIMALS = 10000000000000000 * 1e18;
    uint256 public constant USER_SUPPLY_10MLN_18DEC = 10000000 * 1e18;
    int256 public constant USER_SUPPLY_10MLN_18DEC_INT = 10000000 * 1e18;

    uint256 public constant LEVERAGE_18DEC = 10 * 1e18;
    int256 public constant LEVERAGE_18DEC_INT = 10 * 1e18;
    uint256 public constant LEVERAGE_1000_18DEC = 1000 * 1e18;

    uint256 public constant SPECIFIC_INCOME_TAX_CASE_1 = 600751281464875607313;
    int256 public constant SPECIFIC_INCOME_TAX_CASE_1_INT = 600751281464875607313;
    uint256 public constant SPECIFIC_INTEREST_AMOUNT_CASE_1 = 6007512814648756073133;
    int256 public constant SPECIFIC_INTEREST_AMOUNT_CASE_1_INT = 6007512814648756073133;

    int256 public constant D18_INT = 1e18;
    int256 public constant D17_INT = 1e17;
    int256 public constant D16_INT = 1e16;
    int256 public constant ZERO_INT = 0;

    uint64 public constant ZERO_64UINT = 0;

    uint256 public constant ZERO = 0;
    uint256 public constant LEG_PAY_FIXED = 0;
    uint256 public constant LEG_RECEIVE_FLOATING = 1;

    uint256 public constant N1__0_6DEC = 1000000;
    uint256 public constant N0__1_6DEC = 100000;
    uint256 public constant N0__01_6DEC = 10000;
    uint256 public constant N0__001_6DEC = 1000;
    uint256 public constant N0__000_1_6DEC = 100;
    uint256 public constant N0__000_01_6DEC = 10;

    uint256 public constant USD_10_000_000 = 10000000;
    uint256 public constant USD_1_000_000 = 1000000;
    uint256 public constant USD_100_6DEC = 100000000;
    uint256 public constant USD_10_000_6DEC = 10000 * 1000000;
    uint256 public constant USD_14_000_6DEC = 14000 * 1000000;
    uint256 public constant USD_28_000_6DEC = 28000 * 1000000;
    uint256 public constant USD_50_000_6DEC = 50000 * 1000000;
    uint256 public constant USD_100_000_6DEC = 100000 * 1000000;
    uint256 public constant USD_1_000_000_6DEC = 1000000 * 1000000;
    uint256 public constant USD_10_000_000_6DEC = 10000000 * 1000000;
    int256 public constant USD_10_000_000_6DEC_INT = 10000000 * 1000000;

    uint256 public constant PERCENTAGE_3_6DEC = 3 * 10000;
    uint256 public constant PERCENTAGE_6_6DEC = 6 * 10000;
    uint256 public constant PERCENTAGE_7_6DEC = 7 * 10000;
    uint256 public constant PERCENTAGE_50_6DEC = 50 * 10000;

    uint64 public constant TC_DEFAULT_EMA_18DEC_64UINT = 3 * 1e16;
    uint64 public constant TC_5_EMA_18DEC_64UINT = 5 * 1e16;
    uint256 public constant TC_DEFAULT_EMA_18DEC = 3 * 1e16;
    uint256 public constant TC_NOTIONAL_18DEC = 99670098970308907327800;
    uint256 public constant TOTAL_SUPPLY_6_DECIMALS = 100000000000000 * 1000000;
    uint256 public constant TC_IBT_PRICE_DAI_6DEC = 1000000;
    uint256 public constant TC_TOTAL_AMOUNT_100_6DEC = 100 * 1000000;
    uint256 public constant TC_TOTAL_AMOUNT_10_000_6DEC = 10000 * 1000000;
    uint256 public constant TC_LP_BALANCE_BEFORE_CLOSE_6DEC = 28000 * 1000000;
    uint256 public constant TC_LIQUIDATION_DEPOSIT_AMOUNT_6DEC = 20 * 1000000;
    int256 public constant TC_LIQUIDATION_DEPOSIT_AMOUNT_6DEC_INT = 20 * 1000000;
    uint256 public constant TC_IPOR_PUBLICATION_AMOUNT_6DEC = 10 * 1000000;
    int256 public constant TC_IPOR_PUBLICATION_AMOUNT_6DEC_INT = 10 * 1000000;
    uint256 public constant TC_OPENING_FEE_6DEC = 2990103;
    int256 public constant TC_OPENING_FEE_6DEC_INT = 2990103;
    uint256 public constant TC_COLLATERAL_6DEC = 9967009897;

    uint256 public constant USER_SUPPLY_6_DECIMALS = 10000000 * 1000000;

    uint256 public constant YEAR_IN_SECONDS = 31536000;
    uint256 public constant MONTH_IN_SECONDS = 60 * 60 * 24 * 30;
    uint256 public constant PERIOD_25_DAYS_IN_SECONDS = 60 * 60 * 24 * 25;
    uint256 public constant PERIOD_6_HOURS_IN_SECONDS = 60 * 60 * 6;
    uint256 public constant SWAP_DEFAULT_PERIOD_IN_SECONDS = 60 * 60 * 24 * 28;
    uint256 public constant PERIOD_75_DAYS_IN_SECONDS = 60 * 60 * 24 * 75;
    uint256 public constant PERIOD_60_DAYS_IN_SECONDS = 60 * 60 * 24 * 60;
    uint256 public constant PERIOD_50_DAYS_IN_SECONDS = 60 * 60 * 24 * 50;
    uint256 public constant PERIOD_56_DAYS_IN_SECONDS = 60 * 60 * 24 * 56;
    uint256 public constant PERIOD_28_DAYS_IN_SECONDS = 60 * 60 * 24 * 28;
    uint256 public constant PERIOD_1_DAY_IN_SECONDS = 60 * 60 * 24 * 1;
    uint256 public constant PERIOD_27_DAYS_19_HOURS_IN_SECONDS = 60 * 60 * 24 * 27 + 60 * 60 * 19;
    uint256 public constant PERIOD_27_DAYS_17_HOURS_IN_SECONDS = 60 * 60 * 24 * 27 + 60 * 60 * 17;
    uint256 public constant PERIOD_14_DAYS_IN_SECONDS = 60 * 60 * 24 * 14;
    uint256 public constant MAX_CHUNK_SIZE = 50;
}
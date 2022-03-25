const { expect } = require("chai");
const { ethers } = require("hardhat");

const keccak256 = require("keccak256");

const {
    USER_SUPPLY_6_DECIMALS,
    USER_SUPPLY_10MLN_18DEC,
    LEVERAGE_18DEC,
    PERCENTAGE_3_18DEC,
    PERCENTAGE_5_18DEC,
    PERCENTAGE_6_18DEC,
    PERCENTAGE_10_18DEC,
    PERCENTAGE_50_18DEC,
    PERCENTAGE_100_18DEC,
    PERCENTAGE_120_18DEC,
    PERCENTAGE_160_18DEC,
    PERCENTAGE_365_18DEC,
    USD_10_6DEC,
    USD_10_18DEC,
    USD_20_18DEC,
    TC_TOTAL_AMOUNT_10_000_18DEC,
    USD_10_000_6DEC,
    USD_10_400_18DEC,
    USD_14_000_18DEC,
    USD_28_000_18DEC,
    USD_14_000_6DEC,
    USD_28_000_6DEC,
    TC_COLLATERAL_18DEC,
    USD_10_000_000_6DEC,

    USD_10_000_000_18DEC,
    TC_OPENING_FEE_6DEC,
    TC_OPENING_FEE_18DEC,
    TC_COLLATERAL_6DEC,
    TC_LP_BALANCE_BEFORE_CLOSE_6DEC,
    TC_LP_BALANCE_BEFORE_CLOSE_18DEC,
    TC_LIQUIDATION_DEPOSIT_AMOUNT_6DEC,
    TC_LIQUIDATION_DEPOSIT_AMOUNT_18DEC,
    TC_IPOR_PUBLICATION_AMOUNT_6DEC,
    TC_IPOR_PUBLICATION_AMOUNT_18DEC,
    ZERO,
    SPECIFIC_INTEREST_AMOUNT_CASE_1,
    SPECIFIC_INCOME_TAX_CASE_1,
    PERIOD_25_DAYS_IN_SECONDS,
    PERIOD_14_DAYS_IN_SECONDS,
    PERIOD_50_DAYS_IN_SECONDS,
} = require("./Const.js");

const {
    assertError,
    getStandardDerivativeParamsDAI,
    getStandardDerivativeParamsUSDT,
    getPayFixedDerivativeParamsDAICase1,
    getPayFixedDerivativeParamsUSDTCase1,
    prepareApproveForUsers,
    prepareData,
    prepareTestData,
    setupTokenDaiInitialValuesForUsers,
    setupTokenUsdtInitialValuesForUsers,
} = require("./Utils");

describe("MiltonConfiguration", () => {
    let admin, userOne, userTwo, userThree, liquidityProvider;

    let miltonConfiguration = null;

    before(async () => {
        [admin, userOne, userTwo, userThree, liquidityProvider] = await ethers.getSigners();
        const MiltonConfiguration = await ethers.getContractFactory("MiltonDai");
        miltonConfiguration = await MiltonConfiguration.deploy();
        await miltonConfiguration.deployed();
    });

    it("should setup init value for Max Swap Total Amount", async () => {
        //when
        let actualValue = await miltonConfiguration.getMaxSwapCollateralAmount();
        //then
        expect(actualValue).to.be.eq(BigInt("100000000000000000000000"));
    });

    it("should setup init value for Max Lp Utilization Percentage", async () => {
        //when
        let actualValue = await miltonConfiguration.getMaxLpUtilizationPercentage();
        //then
        expect(actualValue).to.be.eq(BigInt("800000000000000000"));
    });

    it("should setup init value for Max Lp Utilization Per Leg Percentage", async () => {
        //when
        let actualValue = await miltonConfiguration.getMaxLpUtilizationPerLegPercentage();
        //then
        expect(actualValue).to.be.eq(BigInt("480000000000000000"));
    });

    it("should setup init value for Income Fee Percentage", async () => {
        //when
        let actualValue = await miltonConfiguration.getIncomeFeePercentage();
        //then
        expect(actualValue).to.be.eq(BigInt("100000000000000000"));
    });

    it("should setup init value for Opening Fee Percentage", async () => {
        //when
        let actualValue = await miltonConfiguration.getOpeningFeePercentage();
        //then
        expect(actualValue).to.be.eq(BigInt("10000000000000000"));
    });
    it("should setup init value for Opening Fee Treasury Percentage", async () => {
        //when
        let actualValue = await miltonConfiguration.getOpeningFeeForTreasuryPercentage();
        //then
        expect(actualValue).to.be.eq(BigInt("0"));
    });

    it("should setup init value for IPOR Publication Fee Amount", async () => {
        //when
        let actualValue = await miltonConfiguration.getIporPublicationFeeAmount();
        //then
        expect(actualValue).to.be.eq(BigInt("10000000000000000000"));
    });
    it("should setup init value for Liquidation Deposit Amount", async () => {
        //when
        let actualValue = await miltonConfiguration.getLiquidationDepositAmount();
        //then
        expect(actualValue).to.be.eq(BigInt("20000000000000000000"));
    });
    it("should setup init value for Max Leveragey Value", async () => {
        //when
        let actualValue = await miltonConfiguration.getMaxLeverageValue();
        //then
        expect(actualValue).to.be.eq(BigInt("1000000000000000000000"));
    });

    it("should setup init value for Min Leveragey Value", async () => {
        //when
        let actualValue = await miltonConfiguration.getMinLeverageValue();
        //then
        expect(actualValue).to.be.eq(BigInt("10000000000000000000"));
    });

    it("should init value for Opening Fee Treasury Percentage lower than 100%", async () => {
        //when
        let actualValue = await miltonConfiguration.getOpeningFeeForTreasuryPercentage();
        //then
        expect(parseInt(actualValue)).to.be.lte(parseInt(PERCENTAGE_100_18DEC));
    });

    it("should init value for Income Fee Percentage lower than 100%", async () => {
        //when
        let actualValue = await miltonConfiguration.getIncomeFeePercentage();
        //then
        expect(parseInt(actualValue)).to.be.lte(parseInt(PERCENTAGE_100_18DEC));
    });
});

const { expect } = require("chai");
const { ethers } = require("hardhat");

const keccak256 = require("keccak256");

const {
    USER_SUPPLY_6_DECIMALS,
    USER_SUPPLY_10MLN_18DEC,
    COLLATERALIZATION_FACTOR_6DEC,
    COLLATERALIZATION_FACTOR_18DEC,
    PERCENTAGE_3_18DEC,
    PERCENTAGE_3_6DEC,
    PERCENTAGE_5_18DEC,
    USD_10_000_18DEC,
    USD_10_000_6DEC,
    USD_14_000_18DEC,
    USD_14_000_6DEC,
    USD_28_000_18DEC,
    USD_28_000_6DEC,
    PERIOD_25_DAYS_IN_SECONDS,
} = require("./Const.js");

const {
    getLibraries,
    setupTokenUsdtInitialValuesForUsers,
    prepareApproveForUsers,
    prepareData,
    prepareTestData,
    setupTokenDaiInitialValuesForUsers,
    setupTokenUsdcInitialValuesForUsers,
} = require("./Utils");

describe("MiltonFrontendDataProvider", () => {
    let data = null;
    let admin,
        userOne,
        userTwo,
        userThree,
        liquidityProvider,
        miltonStorageAddress;
    let libraries;

    before(async () => {
        libraries = await getLibraries();
        [
            admin,
            userOne,
            userTwo,
            userThree,
            liquidityProvider,
            miltonStorageAddress,
        ] = await ethers.getSigners();
        data = await prepareData(libraries, [
            admin,
            userOne,
            userTwo,
            userThree,
            liquidityProvider,
        ]);
    });

    it("should list correct number DAI, USDC, USDT items", async () => {
        //given
        let testData = await prepareTestData(
            [
                admin,
                userOne,
                userTwo,
                userThree,
                liquidityProvider,
                miltonStorageAddress,
            ],
            ["DAI", "USDC", "USDT"],
            data,
            0
        );

        await prepareApproveForUsers(
            [userOne, userTwo, userThree, liquidityProvider],
            "DAI",
            data,
            testData
        );
        await setupTokenDaiInitialValuesForUsers(
            [admin, userOne, userTwo, liquidityProvider],
            testData
        );

        await prepareApproveForUsers(
            [userOne, userTwo, userThree, liquidityProvider],
            "USDC",
            data,
            testData
        );
        await setupTokenUsdcInitialValuesForUsers(
            [admin, userOne, userTwo, liquidityProvider],
            testData
        );

        await prepareApproveForUsers(
            [userOne, userTwo, userThree, liquidityProvider],
            "USDT",
            data,
            testData
        );
        await setupTokenUsdtInitialValuesForUsers(
            [admin, userOne, userTwo, liquidityProvider],
            testData
        );

        const paramsDai = {
            asset: testData.tokenDai.address,
            totalAmount: USD_10_000_18DEC,
            slippageValue: 3,
            collateralizationFactor: COLLATERALIZATION_FACTOR_18DEC,
            openTimestamp: Math.floor(Date.now() / 1000),
            from: userTwo,
        };

        const paramsUsdt = {
            asset: testData.tokenUsdt.address,
            totalAmount: USD_10_000_6DEC,
            slippageValue: 3,
            collateralizationFactor: COLLATERALIZATION_FACTOR_18DEC,
            openTimestamp: Math.floor(Date.now() / 1000),
            from: userTwo,
        };

        const paramsUsdc = {
            asset: testData.tokenUsdc.address,
            totalAmount: USD_10_000_6DEC,
            slippageValue: 3,
            collateralizationFactor: COLLATERALIZATION_FACTOR_18DEC,
            openTimestamp: Math.floor(Date.now() / 1000),
            from: userTwo,
        };

        await testData.warren
            .connect(userOne)
            .itfUpdateIndex(
                paramsDai.asset,
                PERCENTAGE_5_18DEC,
                paramsDai.openTimestamp
            );

        await testData.warren
            .connect(userOne)
            .itfUpdateIndex(
                paramsUsdc.asset,
                PERCENTAGE_5_18DEC,
                paramsUsdc.openTimestamp
            );

        await testData.warren
            .connect(userOne)
            .itfUpdateIndex(
                paramsUsdt.asset,
                PERCENTAGE_5_18DEC,
                paramsUsdt.openTimestamp
            );

        await testData.josephDai
            .connect(liquidityProvider)
            .itfProvideLiquidity(USD_28_000_18DEC, paramsDai.openTimestamp);

        await testData.josephUsdc
            .connect(liquidityProvider)
            .itfProvideLiquidity(USD_28_000_6DEC, paramsUsdc.openTimestamp);

        await testData.josephUsdt
            .connect(liquidityProvider)
            .itfProvideLiquidity(USD_28_000_6DEC, paramsUsdt.openTimestamp);

        const expectedSwapsLength = 3;

        //when
        await openSwapPayFixed(testData, paramsDai);
        await openSwapPayFixed(testData, paramsUsdc);
        await openSwapPayFixed(testData, paramsUsdt);

        let itemsDai = await data.miltonFrontendDataProvider
            .connect(paramsDai.from)
            .getMySwaps(paramsDai.asset);

        let itemsUsdc = await data.miltonFrontendDataProvider
            .connect(paramsUsdc.from)
            .getMySwaps(paramsUsdc.asset);

        let itemsUsdt = await data.miltonFrontendDataProvider
            .connect(paramsUsdt.from)
            .getMySwaps(paramsUsdt.asset);

        const actualDaiSwapsLength = itemsDai.length;
        const actualUsdcSwapsLength = itemsUsdc.length;
        const actualUsdtSwapsLength = itemsUsdt.length;
        const actualSwapsLength =
            actualDaiSwapsLength +
            actualUsdcSwapsLength +
            actualUsdtSwapsLength;

        //then
        expect(expectedSwapsLength).to.be.eq(actualSwapsLength);
    });

    const openSwapPayFixed = async (testData, params) => {
        if (testData.tokenUsdt && params.asset === testData.tokenUsdt.address) {
            await testData.miltonUsdt
                .connect(params.from)
                .itfOpenSwapPayFixed(
                    params.openTimestamp,
                    params.totalAmount,
                    params.slippageValue,
                    params.collateralizationFactor
                );
        }

        if (testData.tokenUsdc && params.asset === testData.tokenUsdc.address) {
            await testData.miltonUsdc
                .connect(params.from)
                .itfOpenSwapPayFixed(
                    params.openTimestamp,
                    params.totalAmount,
                    params.slippageValue,
                    params.collateralizationFactor
                );
        }

        if (testData.tokenDai && params.asset === testData.tokenDai.address) {
            await testData.miltonDai
                .connect(params.from)
                .itfOpenSwapPayFixed(
                    params.openTimestamp,
                    params.totalAmount,
                    params.slippageValue,
                    params.collateralizationFactor
                );
        }
    };

    const openSwapReceiveFixed = async (testData, params) => {
        if (params.asset === testData.tokenUsdc.address) {
            await testData.miltonUsdc
                .connect(params.from)
                .itfOpenSwapReceiveFixed(
                    params.openTimestamp,
                    params.totalAmount,
                    params.slippageValue,
                    params.collateralizationFactor
                );
        }

        if (params.asset === testData.tokenUsdt.address) {
            await testData.miltonUsdt
                .connect(params.from)
                .itfOpenSwapReceiveFixed(
                    params.openTimestamp,
                    params.totalAmount,
                    params.slippageValue,
                    params.collateralizationFactor
                );
        }

        if (params.asset === testData.tokenDai.address) {
            await testData.miltonDai
                .connect(params.from)
                .itfOpenSwapReceiveFixed(
                    params.openTimestamp,
                    params.totalAmount,
                    params.slippageValue,
                    params.collateralizationFactor
                );
        }
    };

    const preprareSwapPayFixedStruct18DecSimpleCase1 = async (testData) => {
        let openingTimestamp = Math.floor(Date.now() / 1000);
        let closeSwapTimestamp = openingTimestamp + PERIOD_25_DAYS_IN_SECONDS;

        return {
            state: 0,
            buyer: userTwo.address,
            startingTimestamp: openingTimestamp,
            endingTimestamp: closeSwapTimestamp,
            id: 1,
            collateral: BigInt("1000000000000000000000"),
            liquidationDepositAmount: BigInt("20000000000000000000"),
            notionalAmount: BigInt("50000000000000000000000"),
            ibtQuantity: 123,
            fixedInterestRate: 234,
        };
    };
});

import hre from "hardhat";
import chai from "chai";
import { Signer, BigNumber } from "ethers";
import {
    N1__0_18DEC,
    ZERO,
    PERCENTAGE_2_5_18DEC,
    PERCENTAGE_3_18DEC,
    PERCENTAGE_5_18DEC,
    PERCENTAGE_5_2222_18DEC,
    PERCENTAGE_6_18DEC,
    PERCENTAGE_120_18DEC,
    PERCENTAGE_150_18DEC,
    PERCENTAGE_8_18DEC,
    PERCENTAGE_50_18DEC,
    PERIOD_25_DAYS_IN_SECONDS,
    PERIOD_50_DAYS_IN_SECONDS,
    PERIOD_60_DAYS_IN_SECONDS,
} from "../utils/Constants";
import {
    MockMiltonSpreadModel,
    MiltonSpreadModels,
    prepareMockMiltonSpreadModel,
} from "../utils/MiltonUtils";
import {
    prepareComplexTestDataDaiCase000,
    getStandardDerivativeParamsDAI,
} from "../utils/DataUtils";
import { assertError } from "../utils/AssertUtils";

const { expect } = chai;

describe("Joseph -  calculate Exchange Rate when SOAP changed", () => {
    let miltonSpreadModel: MockMiltonSpreadModel;
    let admin: Signer,
        userOne: Signer,
        userTwo: Signer,
        userThree: Signer,
        liquidityProvider: Signer;

    before(async () => {
        [admin, userOne, userTwo, userThree, liquidityProvider] = await hre.ethers.getSigners();
        miltonSpreadModel = await prepareMockMiltonSpreadModel(MiltonSpreadModels.CASE1);
    });

    // it("should calculate Exchange Rate when SOAP changed, SOAP < 0 and |SOAP| < Liquidity Pool Balance, Pay Fixed", async () => {
    //     //given
    //     const testData = await prepareComplexTestDataDaiCase000(
    //         [admin, userOne, userTwo, userThree, liquidityProvider],
    //         miltonSpreadModel
    //     );

    //     const { josephDai, tokenDai, miltonDai } = testData;
    //     if (josephDai === undefined || tokenDai === undefined || miltonDai === undefined) {
    //         expect(true).to.be.false;
    //         return;
    //     }

    //     const params = getStandardDerivativeParamsDAI(userTwo, tokenDai);

    //     //required to have IBT Price higher than 0
    //     await testData.iporOracle
    //         .connect(userOne)
    //         .itfUpdateIndex(params.asset, PERCENTAGE_3_18DEC, params.openTimestamp);

    //     await josephDai
    //         .connect(liquidityProvider)
    //         .itfProvideLiquidity(BigNumber.from("60000").mul(N1__0_18DEC), params.openTimestamp);

    //     await miltonDai
    //         .connect(userTwo)
    //         .itfOpenSwapPayFixed(
    //             params.openTimestamp,
    //             BigNumber.from("26000").mul(N1__0_18DEC),
    //             params.maxAcceptableFixedInterestRate,
    //             params.leverage
    //         );

    //     const calculateTimestamp = params.openTimestamp.add(PERIOD_25_DAYS_IN_SECONDS);
    //     const soap = await miltonDai.itfCalculateSoap(calculateTimestamp);
    //     const balance = await miltonDai.getAccruedBalance();

    //     const expectedExchangeRate = BigNumber.from("1003093533812002519");

    //     //when
    //     const actualExchangeRate = await josephDai.itfCalculateExchangeRate(calculateTimestamp);
    //     //then
    //     expect(soap.soap.lt(ZERO)).to.be.true;
    //     const absSoap = soap.soap.mul("-1");
    //     expect(absSoap).to.be.lte(balance.liquidityPool);
    //     expect(
    //         expectedExchangeRate,
    //         `Incorrect exchange rate for DAI, actual:  ${actualExchangeRate},
    //     expected: ${expectedExchangeRate}`
    //     ).to.be.eql(actualExchangeRate);
    // });

    // it("should calculate Exchange Rate when SOAP changed, SOAP < 0 and |SOAP| < Liquidity Pool Balance, Receive Fixed", async () => {
    //     //given
    //     const testData = await prepareComplexTestDataDaiCase000(
    //         [admin, userOne, userTwo, userThree, liquidityProvider],
    //         miltonSpreadModel
    //     );

    //     const { josephDai, tokenDai, miltonDai } = testData;
    //     if (josephDai === undefined || tokenDai === undefined || miltonDai === undefined) {
    //         expect(true).to.be.false;
    //         return;
    //     }

    //     const params = getStandardDerivativeParamsDAI(userTwo, tokenDai);

    //     //required to have IBT Price higher than 0
    //     await testData.iporOracle
    //         .connect(userOne)
    //         .itfUpdateIndex(params.asset, PERCENTAGE_3_18DEC, params.openTimestamp);

    //     await josephDai
    //         .connect(liquidityProvider)
    //         .itfProvideLiquidity(BigNumber.from("60000").mul(N1__0_18DEC), params.openTimestamp);

    //     await miltonDai
    //         .connect(userTwo)
    //         .itfOpenSwapReceiveFixed(
    //             params.openTimestamp,
    //             BigNumber.from("27000").mul(N1__0_18DEC),
    //             params.maxAcceptableFixedInterestRate,
    //             params.leverage
    //         );

    //     await testData.iporOracle
    //         .connect(userOne)
    //         .itfUpdateIndex(params.asset, PERCENTAGE_2_5_18DEC, params.openTimestamp);
    //     const calculateTimestamp = params.openTimestamp.add(PERIOD_25_DAYS_IN_SECONDS);

    //     const soap = await miltonDai.itfCalculateSoap(calculateTimestamp);
    //     const balance = await miltonDai.getAccruedBalance();

    //     const expectedExchangeRate = BigNumber.from("1001673731442211174");

    //     //when
    //     const actualExchangeRate = await josephDai.itfCalculateExchangeRate(calculateTimestamp);
    //     //then
    //     expect(soap.soap.lte(ZERO)).to.be.true;
    //     const absSoap = soap.soap.mul(BigNumber.from("-1"));
    //     expect(absSoap).to.be.lte(balance.liquidityPool);

    //     expect(
    //         expectedExchangeRate,
    //         `Incorrect exchange rate for DAI, actual:  ${actualExchangeRate},
    //     expected: ${expectedExchangeRate}`
    //     ).to.be.eql(actualExchangeRate);
    // });

    // it("should calculate Exchange Rate when SOAP changed, SOAP > 0 and |SOAP| < Liquidity Pool Balance, Pay Fixed", async () => {
    //     //given
    //     const testData = await prepareComplexTestDataDaiCase000(
    //         [admin, userOne, userTwo, userThree, liquidityProvider],
    //         miltonSpreadModel
    //     );

    //     const { josephDai, tokenDai, miltonDai, iporOracle } = testData;
    //     if (josephDai === undefined || tokenDai === undefined || miltonDai === undefined) {
    //         expect(true).to.be.false;
    //         return;
    //     }

    //     const params = getStandardDerivativeParamsDAI(userTwo, tokenDai);

    //     //required to have IBT Price higher than 0
    //     await iporOracle
    //         .connect(userOne)
    //         .itfUpdateIndex(params.asset, PERCENTAGE_3_18DEC, params.openTimestamp);

    //     await josephDai
    //         .connect(liquidityProvider)
    //         .itfProvideLiquidity(BigNumber.from("60000").mul(N1__0_18DEC), params.openTimestamp);

    //     await miltonDai
    //         .connect(userTwo)
    //         .itfOpenSwapPayFixed(
    //             params.openTimestamp,
    //             BigNumber.from("27000").mul(N1__0_18DEC),
    //             params.maxAcceptableFixedInterestRate,
    //             params.leverage
    //         );

    //     await iporOracle
    //         .connect(userOne)
    //         .itfUpdateIndex(params.asset, PERCENTAGE_8_18DEC, params.openTimestamp);

    //     const calculateTimestamp = params.openTimestamp.add(PERIOD_25_DAYS_IN_SECONDS);

    //     const soap = await miltonDai.itfCalculateSoap(calculateTimestamp);
    //     const balance = await miltonDai.getAccruedBalance();

    //     const expectedExchangeRate = BigNumber.from("987823434476506361");

    //     //when
    //     const actualExchangeRate = await josephDai.itfCalculateExchangeRate(calculateTimestamp);
    //     //then
    //     expect(soap.soap.gte(ZERO)).to.be.true;
    //     expect(soap.soap.lte(balance.liquidityPool)).to.be.true;

    //     expect(
    //         expectedExchangeRate,
    //         `Incorrect exchange rate for DAI, actual:  ${actualExchangeRate},
    //     expected: ${expectedExchangeRate}`
    //     ).to.be.eql(actualExchangeRate);
    // });

    // it("should calculate Exchange Rate when SOAP changed, SOAP > 0 and |SOAP| < Liquidity Pool Balance, Receive Fixed", async () => {
    //     //given
    //     const testData = await prepareComplexTestDataDaiCase000(
    //         [admin, userOne, userTwo, userThree, liquidityProvider],
    //         miltonSpreadModel
    //     );

    //     const { josephDai, tokenDai, miltonDai, iporOracle } = testData;
    //     if (josephDai === undefined || tokenDai === undefined || miltonDai === undefined) {
    //         expect(true).to.be.false;
    //         return;
    //     }

    //     const params = getStandardDerivativeParamsDAI(userTwo, tokenDai);

    //     //required to have IBT Price higher than 0
    //     await testData.iporOracle
    //         .connect(userOne)
    //         .itfUpdateIndex(params.asset, PERCENTAGE_8_18DEC, params.openTimestamp);

    //     await josephDai
    //         .connect(liquidityProvider)
    //         .itfProvideLiquidity(BigNumber.from("60000").mul(N1__0_18DEC), params.openTimestamp);

    //     await miltonDai
    //         .connect(userTwo)
    //         .itfOpenSwapReceiveFixed(
    //             params.openTimestamp,
    //             BigNumber.from("27000").mul(N1__0_18DEC),
    //             params.maxAcceptableFixedInterestRate,
    //             params.leverage
    //         );

    //     await testData.iporOracle
    //         .connect(userOne)
    //         .itfUpdateIndex(params.asset, PERCENTAGE_3_18DEC, params.openTimestamp);

    //     const calculateTimestamp = params.openTimestamp.add(PERIOD_25_DAYS_IN_SECONDS);
    //     const soap = await miltonDai.itfCalculateSoap(calculateTimestamp);
    //     const balance = await miltonDai.getAccruedBalance();

    //     const expectedExchangeRate = BigNumber.from("987823434476506362");

    //     //when
    //     const actualExchangeRate = await josephDai.itfCalculateExchangeRate(calculateTimestamp);
    //     //then
    //     expect(soap.soap.gte(ZERO)).to.be.true;
    //     expect(soap.soap.lte(balance.liquidityPool)).to.be.true;
    //     expect(
    //         expectedExchangeRate,
    //         `Incorrect exchange rate for DAI, actual:  ${actualExchangeRate},
    //     expected: ${expectedExchangeRate}`
    //     ).to.be.eql(actualExchangeRate);
    // });

    // it("should NOT calculate Exchange Rate when SOAP changed, SOAP > 0 and |SOAP| > Liquidity Pool Balance, Pay Fixed", async () => {
    //     //given
    //     const testData = await prepareComplexTestDataDaiCase000(
    //         [admin, userOne, userTwo, userThree, liquidityProvider],
    //         miltonSpreadModel
    //     );

    //     const { josephDai, tokenDai, miltonDai, iporOracle, miltonStorageDai } = testData;
    //     if (
    //         josephDai === undefined ||
    //         tokenDai === undefined ||
    //         miltonDai === undefined ||
    //         miltonStorageDai === undefined
    //     ) {
    //         expect(true).to.be.false;
    //         return;
    //     }

    //     const params = getStandardDerivativeParamsDAI(userTwo, tokenDai);

    //     //required to have IBT Price higher than 0
    //     await iporOracle
    //         .connect(userOne)
    //         .itfUpdateIndex(params.asset, PERCENTAGE_3_18DEC, params.openTimestamp);

    //     await josephDai
    //         .connect(liquidityProvider)
    //         .itfProvideLiquidity(BigNumber.from("60000").mul(N1__0_18DEC), params.openTimestamp);

    //     await miltonDai
    //         .connect(userTwo)
    //         .itfOpenSwapPayFixed(
    //             params.openTimestamp,
    //             BigNumber.from("27000").mul(N1__0_18DEC),
    //             params.maxAcceptableFixedInterestRate,
    //             params.leverage
    //         );

    //     //BEGIN HACK - substract liquidity without  burn ipToken
    //     await miltonStorageDai.setJoseph(await admin.getAddress());
    //     await miltonStorageDai.subtractLiquidity(BigNumber.from("55000").mul(N1__0_18DEC));
    //     await miltonStorageDai.setJoseph(josephDai.address);
    //     //END HACK - substract liquidity without  burn ipToken

    //     await testData.iporOracle
    //         .connect(userOne)
    //         .itfUpdateIndex(params.asset, PERCENTAGE_50_18DEC, params.openTimestamp);

    //     const calculateTimestamp = params.openTimestamp.add(PERIOD_25_DAYS_IN_SECONDS);

    //     // Notice! |SOAP| > Liquidity Pool Balance
    //     const expectedSoap = BigNumber.from("8494848805632282803369");
    //     const expectedLiquidityPoolBalance = BigNumber.from("5008088573427971608517");

    //     const soap = await miltonDai.itfCalculateSoap(calculateTimestamp);
    //     const balance = await miltonDai.getAccruedBalance();
    //     const actualSoap = soap.soap;
    //     const actualLiquidityPoolBalance = balance.liquidityPool;

    //     await assertError(
    //         //when
    //         josephDai.itfCalculateExchangeRate(calculateTimestamp),
    //         //then
    //         "IPOR_314"
    //     );

    //     //then
    //     expect(soap.soap.gte(ZERO)).to.be.true;
    //     expect(actualSoap.gte(balance.liquidityPool)).to.be.true;
    //     expect(actualSoap.eq(expectedSoap)).to.be.true;
    //     expect(actualLiquidityPoolBalance.eq(expectedLiquidityPoolBalance)).to.be.true;
    // });

    // it("should NOT calculate Exchange Rate when SOAP changed, SOAP > 0 and |SOAP| > Liquidity Pool Balance, Receive Fixed", async () => {
    //     //given
    //     const testData = await prepareComplexTestDataDaiCase000(
    //         [admin, userOne, userTwo, userThree, liquidityProvider],
    //         miltonSpreadModel
    //     );

    //     const { josephDai, tokenDai, miltonDai, iporOracle, miltonStorageDai } = testData;
    //     if (
    //         josephDai === undefined ||
    //         tokenDai === undefined ||
    //         miltonDai === undefined ||
    //         miltonStorageDai === undefined
    //     ) {
    //         expect(true).to.be.false;
    //         return;
    //     }

    //     const params = getStandardDerivativeParamsDAI(userTwo, tokenDai);

    //     //required to have IBT Price higher than 0
    //     await iporOracle
    //         .connect(userOne)
    //         .itfUpdateIndex(params.asset, PERCENTAGE_50_18DEC, params.openTimestamp);

    //     await josephDai
    //         .connect(liquidityProvider)
    //         .itfProvideLiquidity(BigNumber.from("60000").mul(N1__0_18DEC), params.openTimestamp);

    //     await miltonDai
    //         .connect(userTwo)
    //         .itfOpenSwapReceiveFixed(
    //             params.openTimestamp,
    //             BigNumber.from("27000").mul(N1__0_18DEC),
    //             params.maxAcceptableFixedInterestRate,
    //             params.leverage
    //         );

    //     //BEGIN HACK - substract liquidity without  burn ipToken
    //     await miltonStorageDai.setJoseph(await admin.getAddress());
    //     await miltonStorageDai.subtractLiquidity(BigNumber.from("55000").mul(N1__0_18DEC));
    //     await miltonStorageDai.setJoseph(josephDai.address);
    //     //END HACK - substract liquidity without  burn ipToken

    //     await testData.iporOracle
    //         .connect(userOne)
    //         .itfUpdateIndex(params.asset, PERCENTAGE_3_18DEC, params.openTimestamp);

    //     const calculateTimestamp = params.openTimestamp.add(PERIOD_25_DAYS_IN_SECONDS);

    //     //Notice! |SOAP| > Liquidity Pool Balance
    //     const expectedSoap = BigNumber.from("8494848805632282973266");
    //     const expectedLiquidityPoolBalance = BigNumber.from("5008088573427971608517");

    //     const soap = await miltonDai.itfCalculateSoap(calculateTimestamp);
    //     const balance = await miltonDai.getAccruedBalance();
    //     const actualSoap = soap.soap;
    //     const actualLiquidityPoolBalance = balance.liquidityPool;

    //     await assertError(
    //         //when
    //         josephDai.itfCalculateExchangeRate(calculateTimestamp),
    //         //then
    //         "IPOR_314"
    //     );

    //     //then

    //     expect(actualSoap).to.be.eql(expectedSoap);
    //     expect(actualLiquidityPoolBalance).to.be.eql(expectedLiquidityPoolBalance);
    // });

    // it("should calculate Exchange Rate when SOAP changed, SOAP < 0 and |SOAP| > Liquidity Pool Balance, Pay Fixed", async () => {
    //     //given
    //     const testData = await prepareComplexTestDataDaiCase000(
    //         [admin, userOne, userTwo, userThree, liquidityProvider],
    //         miltonSpreadModel
    //     );

    //     const { josephDai, tokenDai, miltonDai, iporOracle, miltonStorageDai } = testData;
    //     if (
    //         josephDai === undefined ||
    //         tokenDai === undefined ||
    //         miltonDai === undefined ||
    //         miltonStorageDai === undefined
    //     ) {
    //         expect(true).to.be.false;
    //         return;
    //     }

    //     const params = getStandardDerivativeParamsDAI(userTwo, tokenDai);

    //     //required to have IBT Price higher than 0
    //     await iporOracle
    //         .connect(userOne)
    //         .itfUpdateIndex(params.asset, PERCENTAGE_50_18DEC, params.openTimestamp);

    //     await josephDai
    //         .connect(liquidityProvider)
    //         .itfProvideLiquidity(BigNumber.from("60000").mul(N1__0_18DEC), params.openTimestamp);

    //     await miltonDai
    //         .connect(userTwo)
    //         .itfOpenSwapPayFixed(
    //             params.openTimestamp,
    //             BigNumber.from("27000").mul(N1__0_18DEC),
    //             params.maxAcceptableFixedInterestRate,
    //             params.leverage
    //         );

    //     //BEGIN HACK - substract liquidity without  burn ipToken. Notice! This affect ipToken price!
    //     await miltonStorageDai.setJoseph(await admin.getAddress());
    //     await miltonStorageDai.subtractLiquidity(BigNumber.from("55000").mul(N1__0_18DEC));
    //     await miltonStorageDai.setJoseph(josephDai.address);
    //     //END HACK - substract liquidity without  burn ipToken. Notice! This affect ipToken price!

    //     await iporOracle
    //         .connect(userOne)
    //         .itfUpdateIndex(params.asset, PERCENTAGE_3_18DEC, params.openTimestamp);

    //     const calculateTimestamp = params.openTimestamp.add(PERIOD_25_DAYS_IN_SECONDS);

    //     const actualExchangeRate = await josephDai.itfCalculateExchangeRate(calculateTimestamp);
    //     const expectedExchangeRate = BigNumber.from("231204643857984158");
    //     //Notice! |SOAP| > Liquidity Pool Balance
    //     const expectedSoap = BigNumber.from("-8864190058051077882737");
    //     const expectedLiquidityPoolBalance = BigNumber.from("5008088573427971608517");

    //     const soap = await miltonDai.itfCalculateSoap(calculateTimestamp);
    //     const balance = await miltonDai.getAccruedBalance();
    //     const actualSoap = soap.soap;
    //     const actualLiquidityPoolBalance = balance.liquidityPool;

    //     // then
    //     expect(
    //         expectedExchangeRate,
    //         `Incorrect exchange rate for DAI, actual:  ${actualExchangeRate},
    //     expected: ${expectedExchangeRate}`
    //     ).to.be.eql(actualExchangeRate);

    //     expect(actualSoap).to.be.eql(expectedSoap);
    //     expect(actualLiquidityPoolBalance).to.be.eql(expectedLiquidityPoolBalance);
    // });

    // it("should calculate Exchange Rate when SOAP changed, SOAP < 0 and |SOAP| > Liquidity Pool Balance, Receive Fixed", async () => {
    //     //given
    //     const testData = await prepareComplexTestDataDaiCase000(
    //         [admin, userOne, userTwo, userThree, liquidityProvider],
    //         miltonSpreadModel
    //     );

    //     const { josephDai, tokenDai, miltonDai, iporOracle, miltonStorageDai } = testData;
    //     if (
    //         josephDai === undefined ||
    //         tokenDai === undefined ||
    //         miltonDai === undefined ||
    //         miltonStorageDai === undefined
    //     ) {
    //         expect(true).to.be.false;
    //         return;
    //     }

    //     const params = getStandardDerivativeParamsDAI(userTwo, tokenDai);

    //     //required to have IBT Price higher than 0
    //     await iporOracle
    //         .connect(userOne)
    //         .itfUpdateIndex(params.asset, PERCENTAGE_3_18DEC, params.openTimestamp);

    //     await josephDai
    //         .connect(liquidityProvider)
    //         .itfProvideLiquidity(BigNumber.from("60000").mul(N1__0_18DEC), params.openTimestamp);

    //     await miltonDai
    //         .connect(userTwo)
    //         .itfOpenSwapReceiveFixed(
    //             params.openTimestamp,
    //             BigNumber.from("27000").mul(N1__0_18DEC),
    //             params.maxAcceptableFixedInterestRate,
    //             params.leverage
    //         );

    //     //BEGIN HACK - substract liquidity without  burn ipToken. Notice! This affect ipToken price!
    //     await miltonStorageDai.setJoseph(await admin.getAddress());
    //     await miltonStorageDai.subtractLiquidity(BigNumber.from("55000").mul(N1__0_18DEC));
    //     await miltonStorageDai.setJoseph(josephDai.address);
    //     //END HACK - substract liquidity without  burn ipToken. Notice! This affect ipToken price!

    //     await iporOracle
    //         .connect(userOne)
    //         .itfUpdateIndex(params.asset, PERCENTAGE_50_18DEC, params.openTimestamp);

    //     const calculateTimestamp = params.openTimestamp.add(PERIOD_25_DAYS_IN_SECONDS);

    //     let actualExchangeRate = await josephDai.itfCalculateExchangeRate(calculateTimestamp);
    //     const expectedExchangeRate = BigNumber.from("231204643857984155");

    //     //Notice! |SOAP| > Liquidity Pool Balance
    //     const expectedSoap = BigNumber.from("-8864190058051077712840");
    //     const expectedLiquidityPoolBalance = BigNumber.from("5008088573427971608517");

    //     const soap = await miltonDai.itfCalculateSoap(calculateTimestamp);
    //     const balance = await miltonDai.getAccruedBalance();
    //     const actualSoap = soap.soap;
    //     const actualLiquidityPoolBalance = balance.liquidityPool;

    //     // then
    //     expect(
    //         expectedExchangeRate,
    //         `Incorrect exchange rate for DAI, actual:  ${actualExchangeRate},
    //     expected: ${expectedExchangeRate}`
    //     ).to.be.eql(actualExchangeRate);

    //     expect(actualSoap).to.be.eql(expectedSoap);
    //     expect(actualLiquidityPoolBalance).to.be.eql(expectedLiquidityPoolBalance);
    // });

    it("should calculate Exchange Rate when 2 swaps closed after 60 days, Pay Fixed", async () => {
        //given
        const testData = await prepareComplexTestDataDaiCase000(
            [admin, userOne, userTwo, userThree, liquidityProvider],
            miltonSpreadModel
        );

        const { josephDai, tokenDai, miltonDai, iporOracle, miltonStorageDai } = testData;
        if (
            josephDai === undefined ||
            tokenDai === undefined ||
            miltonDai === undefined ||
            miltonStorageDai === undefined
        ) {
            expect(true).to.be.false;
            return;
        }

        const params = getStandardDerivativeParamsDAI(userTwo, tokenDai);

        await iporOracle
            .connect(userOne)
            .itfUpdateIndex(params.asset, PERCENTAGE_3_18DEC, params.openTimestamp);

        await josephDai
            .connect(liquidityProvider)
            .itfProvideLiquidity(BigNumber.from("1000000").mul(N1__0_18DEC), params.openTimestamp);

        await miltonDai
            .connect(userTwo)
            .itfOpenSwapPayFixed(
                params.openTimestamp,
                BigNumber.from("100000").mul(N1__0_18DEC),
                params.maxAcceptableFixedInterestRate,
                BigNumber.from("1000").mul(N1__0_18DEC)
            );

        await miltonDai
            .connect(userTwo)
            .itfOpenSwapPayFixed(
                params.openTimestamp,
                BigNumber.from("100000").mul(N1__0_18DEC),
                params.maxAcceptableFixedInterestRate,
                BigNumber.from("1000").mul(N1__0_18DEC)
            );

        await iporOracle
            .connect(userOne)
            .itfUpdateIndex(params.asset, PERCENTAGE_5_2222_18DEC, params.openTimestamp);

        const soapBefore60Days = await miltonDai.itfCalculateSoap(params.openTimestamp);
        const exchangeRateBefore60Days = await josephDai.itfCalculateExchangeRate(
            params.openTimestamp
        );

        console.log("soapBefore60Days=", soapBefore60Days.soap.toString());
        console.log("exchangeRateBefore60Days=", exchangeRateBefore60Days.toString());

        const timestamp60daysLater = params.openTimestamp.add(PERIOD_60_DAYS_IN_SECONDS);

        const soapAfter60DaysBeforeClose = await miltonDai.itfCalculateSoap(timestamp60daysLater);
        const exchangeRateAfter60DaysBeforeClose = await josephDai.itfCalculateExchangeRate(
            timestamp60daysLater
        );
        const positionValue1 = await miltonDai.itfCalculateSwapPayFixedValue(
            timestamp60daysLater,
            1
        );
        const positionValue2 = await miltonDai.itfCalculateSwapPayFixedValue(
            timestamp60daysLater,
            2
        );

        console.log("soapAfter60DaysBeforeClose=", soapAfter60DaysBeforeClose.soap.toString());
        console.log(
            "exchangeRateAfter60DaysBeforeClose=",
            exchangeRateAfter60DaysBeforeClose.toString()
        );
        console.log("positionValue1=", positionValue1.toString());
        console.log("positionValue2=", positionValue2.toString());

        await miltonDai.connect(userOne).itfCloseSwapPayFixed(1, timestamp60daysLater);
        await miltonDai.connect(userOne).itfCloseSwapPayFixed(2, timestamp60daysLater);

        const soapAfter60DaysAfterClose = await miltonDai.itfCalculateSoap(timestamp60daysLater);
        const exchangeRateAfter60DaysAfterClose = await josephDai.itfCalculateExchangeRate(
            timestamp60daysLater
        );

        console.log("soapAfter60DaysAfterClose=", soapAfter60DaysAfterClose.soap.toString());
        console.log(
            "exchangeRateAfter60DaysAfterClose=",
            exchangeRateAfter60DaysAfterClose.toString()
        );

        const expectedExchangeRate = BigNumber.from("231204643857984158");
        //Notice! |SOAP| > Liquidity Pool Balance
        const expectedSoap = BigNumber.from("-8864190058051077882737");
        const expectedLiquidityPoolBalance = BigNumber.from("5008088573427971608517");

        //      const soap = await miltonDai.itfCalculateSoap(calculateTimestamp);

        //        const actualSoap = soap.soap;

        // then
        // expect(
        //     expectedExchangeRate,
        //     `Incorrect exchange rate for DAI, actual:  ${actualExchangeRate},
        // expected: ${expectedExchangeRate}`
        // ).to.be.eql(actualExchangeRate);

        // expect(actualSoap).to.be.eql(expectedSoap);
        // expect(actualLiquidityPoolBalance).to.be.eql(expectedLiquidityPoolBalance);
    });
});

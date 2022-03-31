import hre from "hardhat";
import chai from "chai";
import { Signer, BigNumber } from "ethers";
import {
    N1__0_18DEC,
    ZERO,
    PERCENTAGE_2_5_18DEC,
    PERCENTAGE_3_18DEC,
    PERCENTAGE_8_18DEC,
    PERCENTAGE_50_18DEC,
    PERIOD_25_DAYS_IN_SECONDS,
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

    it("should calculate Exchange Rate when SOAP changed, SOAP < 0 and |SOAP| < Liquidity Pool Balance, Pay Fixed", async () => {
        //given
        const testData = await prepareComplexTestDataDaiCase000(
            [admin, userOne, userTwo, userThree, liquidityProvider],
            miltonSpreadModel
        );

        const { josephDai, tokenDai, miltonDai } = testData;
        if (josephDai === undefined || tokenDai === undefined || miltonDai === undefined) {
            expect(true).to.be.false;
            return;
        }

        const params = getStandardDerivativeParamsDAI(userTwo, tokenDai);

        //required to have IBT Price higher than 0
        await testData.warren
            .connect(userOne)
            .itfUpdateIndex(params.asset, PERCENTAGE_3_18DEC, params.openTimestamp);

        await josephDai
            .connect(liquidityProvider)
            .itfProvideLiquidity(BigNumber.from("60000").mul(N1__0_18DEC), params.openTimestamp);

        await miltonDai
            .connect(userTwo)
            .itfOpenSwapPayFixed(
                params.openTimestamp,
                BigNumber.from("26000").mul(N1__0_18DEC),
                params.toleratedQuoteValue,
                params.leverage
            );

        const calculateTimestamp = params.openTimestamp.add(PERIOD_25_DAYS_IN_SECONDS);
        const soap = await miltonDai.itfCalculateSoap(calculateTimestamp);
        const balance = await miltonDai.getAccruedBalance();

        const expectedExchangeRate = BigNumber.from("1003093533812002519");

        //when
        const actualExchangeRate = await josephDai.itfCalculateExchangeRate(calculateTimestamp);
        //then
        expect(soap.soap.lt(ZERO)).to.be.true;
        const absSoap = soap.soap.mul("-1");
        expect(absSoap).to.be.lte(balance.liquidityPool);
        expect(
            expectedExchangeRate,
            `Incorrect exchange rate for DAI, actual:  ${actualExchangeRate},
        expected: ${expectedExchangeRate}`
        ).to.be.eql(actualExchangeRate);
    });

    it("should calculate Exchange Rate when SOAP changed, SOAP < 0 and |SOAP| < Liquidity Pool Balance, Receive Fixed", async () => {
        //given
        const testData = await prepareComplexTestDataDaiCase000(
            [admin, userOne, userTwo, userThree, liquidityProvider],
            miltonSpreadModel
        );

        const { josephDai, tokenDai, miltonDai } = testData;
        if (josephDai === undefined || tokenDai === undefined || miltonDai === undefined) {
            expect(true).to.be.false;
            return;
        }

        const params = getStandardDerivativeParamsDAI(userTwo, tokenDai);

        //required to have IBT Price higher than 0
        await testData.warren
            .connect(userOne)
            .itfUpdateIndex(params.asset, PERCENTAGE_3_18DEC, params.openTimestamp);

        await josephDai
            .connect(liquidityProvider)
            .itfProvideLiquidity(BigNumber.from("60000").mul(N1__0_18DEC), params.openTimestamp);

        await miltonDai
            .connect(userTwo)
            .itfOpenSwapReceiveFixed(
                params.openTimestamp,
                BigNumber.from("27000").mul(N1__0_18DEC),
                params.toleratedQuoteValue,
                params.leverage
            );

        await testData.warren
            .connect(userOne)
            .itfUpdateIndex(params.asset, PERCENTAGE_2_5_18DEC, params.openTimestamp);
        const calculateTimestamp = params.openTimestamp.add(PERIOD_25_DAYS_IN_SECONDS);

        const soap = await miltonDai.itfCalculateSoap(calculateTimestamp);
        const balance = await miltonDai.getAccruedBalance();

        const expectedExchangeRate = BigNumber.from("1001673731442211174");

        //when
        const actualExchangeRate = await josephDai.itfCalculateExchangeRate(calculateTimestamp);
        //then
        expect(soap.soap.lte(ZERO)).to.be.true;
        const absSoap = soap.soap.mul(BigNumber.from("-1"));
        expect(absSoap).to.be.lte(balance.liquidityPool);

        expect(
            expectedExchangeRate,
            `Incorrect exchange rate for DAI, actual:  ${actualExchangeRate},
        expected: ${expectedExchangeRate}`
        ).to.be.eql(actualExchangeRate);
    });

    it("should calculate Exchange Rate when SOAP changed, SOAP > 0 and |SOAP| < Liquidity Pool Balance, Pay Fixed", async () => {
        //given
        const testData = await prepareComplexTestDataDaiCase000(
            [admin, userOne, userTwo, userThree, liquidityProvider],
            miltonSpreadModel
        );

        const { josephDai, tokenDai, miltonDai, warren } = testData;
        if (josephDai === undefined || tokenDai === undefined || miltonDai === undefined) {
            expect(true).to.be.false;
            return;
        }

        const params = getStandardDerivativeParamsDAI(userTwo, tokenDai);

        //required to have IBT Price higher than 0
        await warren
            .connect(userOne)
            .itfUpdateIndex(params.asset, PERCENTAGE_3_18DEC, params.openTimestamp);

        await josephDai
            .connect(liquidityProvider)
            .itfProvideLiquidity(BigNumber.from("60000").mul(N1__0_18DEC), params.openTimestamp);

        await miltonDai
            .connect(userTwo)
            .itfOpenSwapPayFixed(
                params.openTimestamp,
                BigNumber.from("27000").mul(N1__0_18DEC),
                params.toleratedQuoteValue,
                params.leverage
            );

        await warren
            .connect(userOne)
            .itfUpdateIndex(params.asset, PERCENTAGE_8_18DEC, params.openTimestamp);

        const calculateTimestamp = params.openTimestamp.add(PERIOD_25_DAYS_IN_SECONDS);

        const soap = await miltonDai.itfCalculateSoap(calculateTimestamp);
        const balance = await miltonDai.getAccruedBalance();

        const expectedExchangeRate = BigNumber.from("987823434476506361");

        //when
        const actualExchangeRate = await josephDai.itfCalculateExchangeRate(calculateTimestamp);
        //then
        expect(soap.soap.gte(ZERO)).to.be.true;
        expect(soap.soap.lte(balance.liquidityPool)).to.be.true;

        expect(
            expectedExchangeRate,
            `Incorrect exchange rate for DAI, actual:  ${actualExchangeRate},
        expected: ${expectedExchangeRate}`
        ).to.be.eql(actualExchangeRate);
    });

    it("should calculate Exchange Rate when SOAP changed, SOAP > 0 and |SOAP| < Liquidity Pool Balance, Receive Fixed", async () => {
        //given
        const testData = await prepareComplexTestDataDaiCase000(
            [admin, userOne, userTwo, userThree, liquidityProvider],
            miltonSpreadModel
        );

        const { josephDai, tokenDai, miltonDai, warren } = testData;
        if (josephDai === undefined || tokenDai === undefined || miltonDai === undefined) {
            expect(true).to.be.false;
            return;
        }

        const params = getStandardDerivativeParamsDAI(userTwo, tokenDai);

        //required to have IBT Price higher than 0
        await testData.warren
            .connect(userOne)
            .itfUpdateIndex(params.asset, PERCENTAGE_8_18DEC, params.openTimestamp);

        await josephDai
            .connect(liquidityProvider)
            .itfProvideLiquidity(BigNumber.from("60000").mul(N1__0_18DEC), params.openTimestamp);

        await miltonDai
            .connect(userTwo)
            .itfOpenSwapReceiveFixed(
                params.openTimestamp,
                BigNumber.from("27000").mul(N1__0_18DEC),
                params.toleratedQuoteValue,
                params.leverage
            );

        await testData.warren
            .connect(userOne)
            .itfUpdateIndex(params.asset, PERCENTAGE_3_18DEC, params.openTimestamp);

        const calculateTimestamp = params.openTimestamp.add(PERIOD_25_DAYS_IN_SECONDS);
        const soap = await miltonDai.itfCalculateSoap(calculateTimestamp);
        const balance = await miltonDai.getAccruedBalance();

        const expectedExchangeRate = BigNumber.from("987823434476506362");

        //when
        const actualExchangeRate = await josephDai.itfCalculateExchangeRate(calculateTimestamp);
        //then
        expect(soap.soap.gte(ZERO)).to.be.true;
        expect(soap.soap.lte(balance.liquidityPool)).to.be.true;
        expect(
            expectedExchangeRate,
            `Incorrect exchange rate for DAI, actual:  ${actualExchangeRate},
        expected: ${expectedExchangeRate}`
        ).to.be.eql(actualExchangeRate);
    });

    it("should NOT calculate Exchange Rate when SOAP changed, SOAP > 0 and |SOAP| > Liquidity Pool Balance, Pay Fixed", async () => {
        //given
        const testData = await prepareComplexTestDataDaiCase000(
            [admin, userOne, userTwo, userThree, liquidityProvider],
            miltonSpreadModel
        );

        const { josephDai, tokenDai, miltonDai, warren, miltonStorageDai } = testData;
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

        //required to have IBT Price higher than 0
        await warren
            .connect(userOne)
            .itfUpdateIndex(params.asset, PERCENTAGE_3_18DEC, params.openTimestamp);

        await josephDai
            .connect(liquidityProvider)
            .itfProvideLiquidity(BigNumber.from("60000").mul(N1__0_18DEC), params.openTimestamp);

        await miltonDai
            .connect(userTwo)
            .itfOpenSwapPayFixed(
                params.openTimestamp,
                BigNumber.from("27000").mul(N1__0_18DEC),
                params.toleratedQuoteValue,
                params.leverage
            );

        //BEGIN HACK - substract liquidity without  burn ipToken
        await miltonStorageDai.setJoseph(await admin.getAddress());
        await miltonStorageDai.subtractLiquidity(BigNumber.from("55000").mul(N1__0_18DEC));
        await miltonStorageDai.setJoseph(josephDai.address);
        //END HACK - substract liquidity without  burn ipToken

        await testData.warren
            .connect(userOne)
            .itfUpdateIndex(params.asset, PERCENTAGE_50_18DEC, params.openTimestamp);

        const calculateTimestamp = params.openTimestamp.add(PERIOD_25_DAYS_IN_SECONDS);

        // Notice! |SOAP| > Liquidity Pool Balance
        const expectedSoap = BigNumber.from("8494848805632282803369");
        const expectedLiquidityPoolBalance = BigNumber.from("5008088573427971608517");

        const soap = await miltonDai.itfCalculateSoap(calculateTimestamp);
        const balance = await miltonDai.getAccruedBalance();
        const actualSoap = soap.soap;
        const actualLiquidityPoolBalance = balance.liquidityPool;

        await assertError(
            //when
            josephDai.itfCalculateExchangeRate(calculateTimestamp),
            //then
            "IPOR_314"
        );

        //then
        expect(soap.soap.gte(ZERO)).to.be.true;
        expect(actualSoap.gte(balance.liquidityPool)).to.be.true;
        expect(actualSoap.eq(expectedSoap)).to.be.true;
        expect(actualLiquidityPoolBalance.eq(expectedLiquidityPoolBalance)).to.be.true;
    });

    it("should NOT calculate Exchange Rate when SOAP changed, SOAP > 0 and |SOAP| > Liquidity Pool Balance, Receive Fixed", async () => {
        //given
        const testData = await prepareComplexTestDataDaiCase000(
            [admin, userOne, userTwo, userThree, liquidityProvider],
            miltonSpreadModel
        );

        const { josephDai, tokenDai, miltonDai, warren, miltonStorageDai } = testData;
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

        //required to have IBT Price higher than 0
        await warren
            .connect(userOne)
            .itfUpdateIndex(params.asset, PERCENTAGE_50_18DEC, params.openTimestamp);

        await josephDai
            .connect(liquidityProvider)
            .itfProvideLiquidity(BigNumber.from("60000").mul(N1__0_18DEC), params.openTimestamp);

        await miltonDai
            .connect(userTwo)
            .itfOpenSwapReceiveFixed(
                params.openTimestamp,
                BigNumber.from("27000").mul(N1__0_18DEC),
                params.toleratedQuoteValue,
                params.leverage
            );

        //BEGIN HACK - substract liquidity without  burn ipToken
        await miltonStorageDai.setJoseph(await admin.getAddress());
        await miltonStorageDai.subtractLiquidity(BigNumber.from("55000").mul(N1__0_18DEC));
        await miltonStorageDai.setJoseph(josephDai.address);
        //END HACK - substract liquidity without  burn ipToken

        await testData.warren
            .connect(userOne)
            .itfUpdateIndex(params.asset, PERCENTAGE_3_18DEC, params.openTimestamp);

        const calculateTimestamp = params.openTimestamp.add(PERIOD_25_DAYS_IN_SECONDS);

        //Notice! |SOAP| > Liquidity Pool Balance
        const expectedSoap = BigNumber.from("8494848805632282973266");
        const expectedLiquidityPoolBalance = BigNumber.from("5008088573427971608517");

        const soap = await miltonDai.itfCalculateSoap(calculateTimestamp);
        const balance = await miltonDai.getAccruedBalance();
        const actualSoap = soap.soap;
        const actualLiquidityPoolBalance = balance.liquidityPool;

        await assertError(
            //when
            josephDai.itfCalculateExchangeRate(calculateTimestamp),
            //then
            "IPOR_314"
        );

        //then

        expect(actualSoap).to.be.eql(expectedSoap);
        expect(actualLiquidityPoolBalance).to.be.eql(expectedLiquidityPoolBalance);
    });

    it("should calculate Exchange Rate when SOAP changed, SOAP < 0 and |SOAP| > Liquidity Pool Balance, Pay Fixed", async () => {
        //given
        const testData = await prepareComplexTestDataDaiCase000(
            [admin, userOne, userTwo, userThree, liquidityProvider],
            miltonSpreadModel
        );

        const { josephDai, tokenDai, miltonDai, warren, miltonStorageDai } = testData;
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

        //required to have IBT Price higher than 0
        await warren
            .connect(userOne)
            .itfUpdateIndex(params.asset, PERCENTAGE_50_18DEC, params.openTimestamp);

        await josephDai
            .connect(liquidityProvider)
            .itfProvideLiquidity(BigNumber.from("60000").mul(N1__0_18DEC), params.openTimestamp);

        await miltonDai
            .connect(userTwo)
            .itfOpenSwapPayFixed(
                params.openTimestamp,
                BigNumber.from("27000").mul(N1__0_18DEC),
                params.toleratedQuoteValue,
                params.leverage
            );

        //BEGIN HACK - substract liquidity without  burn ipToken. Notice! This affect ipToken price!
        await miltonStorageDai.setJoseph(await admin.getAddress());
        await miltonStorageDai.subtractLiquidity(BigNumber.from("55000").mul(N1__0_18DEC));
        await miltonStorageDai.setJoseph(josephDai.address);
        //END HACK - substract liquidity without  burn ipToken. Notice! This affect ipToken price!

        await warren
            .connect(userOne)
            .itfUpdateIndex(params.asset, PERCENTAGE_3_18DEC, params.openTimestamp);

        const calculateTimestamp = params.openTimestamp.add(PERIOD_25_DAYS_IN_SECONDS);

        const actualExchangeRate = await josephDai.itfCalculateExchangeRate(calculateTimestamp);
        const expectedExchangeRate = BigNumber.from("231204643857984158");
        //Notice! |SOAP| > Liquidity Pool Balance
        const expectedSoap = BigNumber.from("-8864190058051077882737");
        const expectedLiquidityPoolBalance = BigNumber.from("5008088573427971608517");

        const soap = await miltonDai.itfCalculateSoap(calculateTimestamp);
        const balance = await miltonDai.getAccruedBalance();
        const actualSoap = soap.soap;
        const actualLiquidityPoolBalance = balance.liquidityPool;

        // then
        expect(
            expectedExchangeRate,
            `Incorrect exchange rate for DAI, actual:  ${actualExchangeRate},
        expected: ${expectedExchangeRate}`
        ).to.be.eql(actualExchangeRate);

        expect(actualSoap).to.be.eql(expectedSoap);
        expect(actualLiquidityPoolBalance).to.be.eql(expectedLiquidityPoolBalance);
    });

    it("should calculate Exchange Rate when SOAP changed, SOAP < 0 and |SOAP| > Liquidity Pool Balance, Receive Fixed", async () => {
        //given
        const testData = await prepareComplexTestDataDaiCase000(
            [admin, userOne, userTwo, userThree, liquidityProvider],
            miltonSpreadModel
        );

        const { josephDai, tokenDai, miltonDai, warren, miltonStorageDai } = testData;
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

        //required to have IBT Price higher than 0
        await warren
            .connect(userOne)
            .itfUpdateIndex(params.asset, PERCENTAGE_3_18DEC, params.openTimestamp);

        await josephDai
            .connect(liquidityProvider)
            .itfProvideLiquidity(BigNumber.from("60000").mul(N1__0_18DEC), params.openTimestamp);

        await miltonDai
            .connect(userTwo)
            .itfOpenSwapReceiveFixed(
                params.openTimestamp,
                BigNumber.from("27000").mul(N1__0_18DEC),
                params.toleratedQuoteValue,
                params.leverage
            );

        //BEGIN HACK - substract liquidity without  burn ipToken. Notice! This affect ipToken price!
        await miltonStorageDai.setJoseph(await admin.getAddress());
        await miltonStorageDai.subtractLiquidity(BigNumber.from("55000").mul(N1__0_18DEC));
        await miltonStorageDai.setJoseph(josephDai.address);
        //END HACK - substract liquidity without  burn ipToken. Notice! This affect ipToken price!

        await warren
            .connect(userOne)
            .itfUpdateIndex(params.asset, PERCENTAGE_50_18DEC, params.openTimestamp);

        const calculateTimestamp = params.openTimestamp.add(PERIOD_25_DAYS_IN_SECONDS);

        let actualExchangeRate = await josephDai.itfCalculateExchangeRate(calculateTimestamp);
        const expectedExchangeRate = BigNumber.from("231204643857984155");

        //Notice! |SOAP| > Liquidity Pool Balance
        const expectedSoap = BigNumber.from("-8864190058051077712840");
        const expectedLiquidityPoolBalance = BigNumber.from("5008088573427971608517");

        const soap = await miltonDai.itfCalculateSoap(calculateTimestamp);
        const balance = await miltonDai.getAccruedBalance();
        const actualSoap = soap.soap;
        const actualLiquidityPoolBalance = balance.liquidityPool;

        // then
        expect(
            expectedExchangeRate,
            `Incorrect exchange rate for DAI, actual:  ${actualExchangeRate},
        expected: ${expectedExchangeRate}`
        ).to.be.eql(actualExchangeRate);

        expect(actualSoap).to.be.eql(expectedSoap);
        expect(actualLiquidityPoolBalance).to.be.eql(expectedLiquidityPoolBalance);
    });
});

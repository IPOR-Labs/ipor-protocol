import hre from "hardhat";
import chai from "chai";
import { Signer, BigNumber } from "ethers";
import { MockSpreadModel } from "../../types";
import {
    N1__0_18DEC,
    N0__01_18DEC,
    ZERO,
    PERCENTAGE_3_18DEC,
    PERCENTAGE_4_5_18DEC,
    PERCENTAGE_5_18DEC,
    PERCENTAGE_8_18DEC,
    PERCENTAGE_50_18DEC,
    PERIOD_25_DAYS_IN_SECONDS,
    PERIOD_28_DAYS_IN_SECONDS,
    PERIOD_56_DAYS_IN_SECONDS,
} from "../utils/Constants";
import { prepareMockSpreadModel } from "../utils/MiltonUtils";
import {
    prepareComplexTestDataDaiCase000,
    getStandardDerivativeParamsDAI,
    getReceiveFixedSwapParamsDAI,
} from "../utils/DataUtils";
import { assertError } from "../utils/AssertUtils";

const { expect } = chai;

describe("Joseph -  calculate Exchange Rate when SOAP changed", () => {
    let miltonSpreadModel: MockSpreadModel;
    let admin: Signer,
        userOne: Signer,
        userTwo: Signer,
        userThree: Signer,
        liquidityProvider: Signer;

    before(async () => {
        [admin, userOne, userTwo, userThree, liquidityProvider] = await hre.ethers.getSigners();
        miltonSpreadModel = await prepareMockSpreadModel(ZERO, ZERO, ZERO, ZERO);
    });

    it("should calculate Exchange Rate when SOAP changed, SOAP < 0 and |SOAP| < Liquidity Pool Balance, Pay Fixed", async () => {
        //given
        await miltonSpreadModel.setCalculateQuotePayFixed(BigNumber.from("4").mul(N0__01_18DEC));
        const testData = await prepareComplexTestDataDaiCase000(
            BigNumber.from(Math.floor(Date.now() / 1000)),
            [admin, userOne, userTwo, userThree, liquidityProvider],
            miltonSpreadModel,
            PERCENTAGE_3_18DEC
        );

        const { josephDai, tokenDai, miltonDai } = testData;
        if (josephDai === undefined || tokenDai === undefined || miltonDai === undefined) {
            expect(true).to.be.false;
            return;
        }

        const params = getStandardDerivativeParamsDAI(userTwo, tokenDai);

        //required to have IBT Price higher than 0
        await testData.iporOracle
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
                params.acceptableFixedInterestRate,
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
        ).to.be.equal(actualExchangeRate);
    });

    it("should calculate Exchange Rate when SOAP changed, SOAP < 0 and |SOAP| < Liquidity Pool Balance, Receive Fixed", async () => {
        //given
        miltonSpreadModel.setCalculateQuoteReceiveFixed(BigNumber.from("2").mul(N0__01_18DEC));
        const testData = await prepareComplexTestDataDaiCase000(
            BigNumber.from(Math.floor(Date.now() / 1000)),
            [admin, userOne, userTwo, userThree, liquidityProvider],
            miltonSpreadModel,
            PERCENTAGE_3_18DEC
        );

        const { josephDai, tokenDai, miltonDai } = testData;
        if (josephDai === undefined || tokenDai === undefined || miltonDai === undefined) {
            expect(true).to.be.false;
            return;
        }

        const params = getReceiveFixedSwapParamsDAI(userTwo, tokenDai);

        //required to have IBT Price higher than 0
        await testData.iporOracle
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
                params.acceptableFixedInterestRate,
                params.leverage
            );

        await testData.iporOracle
            .connect(userOne)
            .itfUpdateIndex(params.asset, PERCENTAGE_5_18DEC, params.openTimestamp);

        const calculateTimestamp = params.openTimestamp.add(PERIOD_25_DAYS_IN_SECONDS);

        const soap = await miltonDai.itfCalculateSoap(calculateTimestamp);
        const balance = await miltonDai.getAccruedBalance();

        const expectedExchangeRate = BigNumber.from("1009368340867602731");

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
        ).to.be.equal(actualExchangeRate);
    });

    it("should calculate Exchange Rate when SOAP changed, SOAP > 0 and |SOAP| < Liquidity Pool Balance, Pay Fixed", async () => {
        //given
        miltonSpreadModel.setCalculateQuotePayFixed(BigNumber.from("4").mul(N0__01_18DEC));
        const testData = await prepareComplexTestDataDaiCase000(
            BigNumber.from(Math.floor(Date.now() / 1000)),
            [admin, userOne, userTwo, userThree, liquidityProvider],
            miltonSpreadModel,
            PERCENTAGE_3_18DEC
        );

        const { josephDai, tokenDai, miltonDai, iporOracle } = testData;
        if (josephDai === undefined || tokenDai === undefined || miltonDai === undefined) {
            expect(true).to.be.false;
            return;
        }

        const params = getStandardDerivativeParamsDAI(userTwo, tokenDai);

        //required to have IBT Price higher than 0
        await iporOracle
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
                params.acceptableFixedInterestRate,
                params.leverage
            );

        await iporOracle
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
        ).to.be.equal(actualExchangeRate);
    });

    it("should calculate Exchange Rate when SOAP changed, SOAP > 0 and |SOAP| < Liquidity Pool Balance, Receive Fixed", async () => {
        //given
        miltonSpreadModel.setCalculateQuoteReceiveFixed(BigNumber.from("7").mul(N0__01_18DEC));
        const testData = await prepareComplexTestDataDaiCase000(
            BigNumber.from(Math.floor(Date.now() / 1000)),
            [admin, userOne, userTwo, userThree, liquidityProvider],
            miltonSpreadModel,
            PERCENTAGE_8_18DEC
        );

        const { josephDai, tokenDai, miltonDai, iporOracle } = testData;
        if (josephDai === undefined || tokenDai === undefined || miltonDai === undefined) {
            expect(true).to.be.false;
            return;
        }

        const params = getReceiveFixedSwapParamsDAI(userTwo, tokenDai);

        //required to have IBT Price higher than 0
        await testData.iporOracle
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
                params.acceptableFixedInterestRate,
                params.leverage
            );

        await testData.iporOracle
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
        ).to.be.equal(actualExchangeRate);
    });

    it("should NOT calculate Exchange Rate when SOAP changed, SOAP > 0 and |SOAP| > Liquidity Pool Balance, Pay Fixed", async () => {
        //given
        miltonSpreadModel.setCalculateQuotePayFixed(BigNumber.from("4").mul(N0__01_18DEC));
        const testData = await prepareComplexTestDataDaiCase000(
            BigNumber.from(Math.floor(Date.now() / 1000)),
            [admin, userOne, userTwo, userThree, liquidityProvider],
            miltonSpreadModel,
            PERCENTAGE_3_18DEC
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

        //required to have IBT Price higher than 0
        await iporOracle
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
                params.acceptableFixedInterestRate,
                params.leverage
            );

        //BEGIN HACK - substract liquidity without  burn ipToken
        await miltonStorageDai.setJoseph(await admin.getAddress());
        await miltonStorageDai.subtractLiquidity(BigNumber.from("55000").mul(N1__0_18DEC));
        await miltonStorageDai.setJoseph(josephDai.address);
        //END HACK - substract liquidity without  burn ipToken

        await testData.iporOracle
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
            "IPOR_313"
        );

        //then
        expect(soap.soap.gte(ZERO)).to.be.true;
        expect(actualSoap.gte(balance.liquidityPool)).to.be.true;
        expect(actualSoap.eq(expectedSoap)).to.be.true;
        expect(actualLiquidityPoolBalance.eq(expectedLiquidityPoolBalance)).to.be.true;
    });

    it("should NOT calculate Exchange Rate when SOAP changed, SOAP > 0 and |SOAP| > Liquidity Pool Balance, Receive Fixed", async () => {
        //given
        miltonSpreadModel.setCalculateQuoteReceiveFixed(BigNumber.from("49").mul(N0__01_18DEC));
        const testData = await prepareComplexTestDataDaiCase000(
            BigNumber.from(Math.floor(Date.now() / 1000)),
            [admin, userOne, userTwo, userThree, liquidityProvider],
            miltonSpreadModel,
            PERCENTAGE_50_18DEC
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

        const params = getReceiveFixedSwapParamsDAI(userTwo, tokenDai);

        //required to have IBT Price higher than 0
        await iporOracle
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
                params.acceptableFixedInterestRate,
                params.leverage
            );

        //BEGIN HACK - substract liquidity without  burn ipToken
        await miltonStorageDai.setJoseph(await admin.getAddress());
        await miltonStorageDai.subtractLiquidity(BigNumber.from("55000").mul(N1__0_18DEC));
        await miltonStorageDai.setJoseph(josephDai.address);
        //END HACK - substract liquidity without  burn ipToken

        await testData.iporOracle
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
            "IPOR_313"
        );

        //then
        expect(actualSoap).to.be.equal(expectedSoap);
        expect(actualLiquidityPoolBalance).to.be.equal(expectedLiquidityPoolBalance);
    });

    it("should calculate Exchange Rate when SOAP changed, SOAP < 0 and |SOAP| > Liquidity Pool Balance, Pay Fixed", async () => {
        //given
        miltonSpreadModel.setCalculateQuotePayFixed(BigNumber.from("51").mul(N0__01_18DEC));
        const testData = await prepareComplexTestDataDaiCase000(
            BigNumber.from(Math.floor(Date.now() / 1000)),
            [admin, userOne, userTwo, userThree, liquidityProvider],
            miltonSpreadModel,
            PERCENTAGE_50_18DEC
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

        //required to have IBT Price higher than 0
        await iporOracle
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
                params.acceptableFixedInterestRate,
                params.leverage
            );

        //BEGIN HACK - substract liquidity without  burn ipToken. Notice! This affect ipToken price!
        await miltonStorageDai.setJoseph(await admin.getAddress());
        await miltonStorageDai.subtractLiquidity(BigNumber.from("55000").mul(N1__0_18DEC));
        await miltonStorageDai.setJoseph(josephDai.address);
        //END HACK - substract liquidity without  burn ipToken. Notice! This affect ipToken price!

        await iporOracle
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
        ).to.be.equal(actualExchangeRate);

        expect(actualSoap).to.be.equal(expectedSoap);
        expect(actualLiquidityPoolBalance).to.be.equal(expectedLiquidityPoolBalance);
    });

    it("should calculate Exchange Rate when SOAP changed, SOAP < 0 and |SOAP| > Liquidity Pool Balance, Receive Fixed", async () => {
        //given
        miltonSpreadModel.setCalculateQuoteReceiveFixed(BigNumber.from("2").mul(N0__01_18DEC));
        const testData = await prepareComplexTestDataDaiCase000(
            BigNumber.from(Math.floor(Date.now() / 1000)),
            [admin, userOne, userTwo, userThree, liquidityProvider],
            miltonSpreadModel,
            PERCENTAGE_3_18DEC
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

        const params = getReceiveFixedSwapParamsDAI(userTwo, tokenDai);

        //required to have IBT Price higher than 0
        await iporOracle
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
                params.acceptableFixedInterestRate,
                params.leverage
            );

        //BEGIN HACK - substract liquidity without  burn ipToken. Notice! This affect ipToken price!
        await miltonStorageDai.setJoseph(await admin.getAddress());
        await miltonStorageDai.subtractLiquidity(BigNumber.from("55000").mul(N1__0_18DEC));
        await miltonStorageDai.setJoseph(josephDai.address);
        //END HACK - substract liquidity without  burn ipToken. Notice! This affect ipToken price!

        await iporOracle
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
        ).to.be.equal(actualExchangeRate);
        expect(actualSoap).to.be.equal(expectedSoap);
        expect(actualLiquidityPoolBalance).to.be.equal(expectedLiquidityPoolBalance);
    });

    it("[!!!] should calculate Exchange Rate, position values and SOAP when 2 swaps closed after 60 days, Pay Fixed", async () => {
        //given
        miltonSpreadModel.setCalculateQuotePayFixed(BigNumber.from("4").mul(N0__01_18DEC));
        const testData = await prepareComplexTestDataDaiCase000(
            BigNumber.from(Math.floor(Date.now() / 1000)),
            [admin, userOne, userTwo, userThree, liquidityProvider],
            miltonSpreadModel,
            PERCENTAGE_3_18DEC
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
                params.acceptableFixedInterestRate,
                BigNumber.from("1000").mul(N1__0_18DEC)
            );

        await miltonDai
            .connect(userTwo)
            .itfOpenSwapPayFixed(
                params.openTimestamp,
                BigNumber.from("100000").mul(N1__0_18DEC),
                params.acceptableFixedInterestRate,
                BigNumber.from("1000").mul(N1__0_18DEC)
            );

        // fixed interest rate on swaps is equal to 4%, so lets use 4,5% for IPOR here:
        await iporOracle
            .connect(userOne)
            .itfUpdateIndex(params.asset, PERCENTAGE_4_5_18DEC, params.openTimestamp);

        const expectedInitialSOAP = BigNumber.from("0");
        const expectedInitialExchangeRate = BigNumber.from("1000059964010796761");
        const expectedSOAPAfter28Days = BigNumber.from("76666315173940979346744");
        const expectedExchangeRateAfter28Days = BigNumber.from("923393648836855782");

        const expectedPayoff1After28Days = BigNumber.from("38333157586970489673372");
        const expectedPayoff2After28Days = BigNumber.from("38333157586970489673372");

        const expectedSOAPAfter56DaysBeforeClose = BigNumber.from("153332630347881958693488");
        const expectedExchangeRateAfter56DaysBeforeClose = BigNumber.from("846727333662914802");

        const expectedPayoff1After56Days = BigNumber.from("76666315173940979346744");
        const expectedPayoff2After56Days = BigNumber.from("76666315173940979346744");

        const expectedSOAPAfter56DaysAfterClose = BigNumber.from("0");
        const expectedExchangeRateAfter56DaysAfterClose = BigNumber.from("846727333662914802");

        const expectedLiquidityPoolBalanceBeforeClose = BigNumber.from("1000059964010796760971708");

        const expectedMiltonLiquidityPoolBalanceAfterClose = BigNumber.from(
            "846727333662914802278220"
        );
        const expectedSOAPPlusLiquidityPoolBalanceBeforeClose = BigNumber.from(
            "846727333662914802278220"
        );

        const timestamp28DaysLater = params.openTimestamp.add(PERIOD_28_DAYS_IN_SECONDS);
        const timestamp56DaysLater = params.openTimestamp.add(PERIOD_56_DAYS_IN_SECONDS);

        const actualInitialSOAP = await miltonDai.itfCalculateSoap(params.openTimestamp);
        const actualInitialExchangeRate = await josephDai.itfCalculateExchangeRate(
            params.openTimestamp
        );
        const actualSOAPAfter28Days = await miltonDai.itfCalculateSoap(timestamp28DaysLater);
        const actualExchangeRateAfter28Days = await josephDai.itfCalculateExchangeRate(
            timestamp28DaysLater
        );
        const actualPayoff1After28days = await miltonDai.itfCalculateSwapPayFixedValue(
            timestamp28DaysLater,
            1
        );
        const actualPayoff2After28days = await miltonDai.itfCalculateSwapPayFixedValue(
            timestamp28DaysLater,
            2
        );

        const actualSOAPAfter56DaysBeforeClose = await miltonDai.itfCalculateSoap(
            timestamp56DaysLater
        );
        const actualExchangeRateAfter56DaysBeforeClose = await josephDai.itfCalculateExchangeRate(
            timestamp56DaysLater
        );
        const actualPayoff1After56days = await miltonDai.itfCalculateSwapPayFixedValue(
            timestamp56DaysLater,
            1
        );
        const actualPayoff2After56days = await miltonDai.itfCalculateSwapPayFixedValue(
            timestamp56DaysLater,
            2
        );

        const actualLiquidityPoolBalanceBeforeClose = (await miltonStorageDai.getBalance())
            .liquidityPool;

        const actualSOAPPlusLiquidityPoolBalanceBeforeClose =
            actualLiquidityPoolBalanceBeforeClose.sub(actualSOAPAfter56DaysBeforeClose.soap);

        //when
        await miltonDai.connect(userOne).itfCloseSwapPayFixed(1, timestamp56DaysLater);
        await miltonDai.connect(userOne).itfCloseSwapPayFixed(2, timestamp56DaysLater);

        //then
        const actualMiltonLiquidityPoolBalanceAfterClose = (await miltonStorageDai.getBalance())
            .liquidityPool;

        const actualSOAPAfter56DaysAfterClose = await miltonDai.itfCalculateSoap(
            timestamp56DaysLater
        );
        const actualExchangeRateAfter56DaysAfterClose = await josephDai.itfCalculateExchangeRate(
            timestamp56DaysLater
        );

        expect(expectedInitialSOAP).to.be.equal(actualInitialSOAP.soap);
        expect(expectedInitialExchangeRate).to.be.equal(actualInitialExchangeRate);
        expect(expectedSOAPAfter28Days).to.be.equal(actualSOAPAfter28Days.soap);
        expect(expectedExchangeRateAfter28Days).to.be.equal(actualExchangeRateAfter28Days);
        expect(expectedPayoff1After28Days).to.be.equal(actualPayoff1After28days);
        expect(expectedPayoff2After28Days).to.be.equal(actualPayoff2After28days);
        expect(expectedSOAPAfter56DaysBeforeClose).to.be.equal(actualSOAPAfter56DaysBeforeClose.soap);
        expect(expectedExchangeRateAfter56DaysBeforeClose).to.be.equal(
            actualExchangeRateAfter56DaysBeforeClose
        );
        expect(expectedPayoff1After56Days).to.be.equal(actualPayoff1After56days);
        expect(expectedPayoff2After56Days).to.be.equal(actualPayoff2After56days);
        expect(expectedSOAPAfter56DaysAfterClose).to.be.equal(actualSOAPAfter56DaysAfterClose.soap);
        expect(expectedExchangeRateAfter56DaysAfterClose).to.be.equal(
            actualExchangeRateAfter56DaysAfterClose
        );

        expect(expectedMiltonLiquidityPoolBalanceAfterClose).to.be.equal(
            actualMiltonLiquidityPoolBalanceAfterClose
        );

        expect(expectedLiquidityPoolBalanceBeforeClose).to.be.equal(
            actualLiquidityPoolBalanceBeforeClose
        );
        expect(expectedSOAPPlusLiquidityPoolBalanceBeforeClose).to.be.equal(
            actualSOAPPlusLiquidityPoolBalanceBeforeClose
        );

        /// SOAP + Liquidity Pool balance before close should be equal to Liquidity Pool balance after close swaps
        expect(expectedSOAPPlusLiquidityPoolBalanceBeforeClose).to.be.equal(
            actualMiltonLiquidityPoolBalanceAfterClose
        );
    });
});

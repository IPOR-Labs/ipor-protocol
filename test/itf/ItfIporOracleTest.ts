import hre from "hardhat";
import chai from "chai";
import { Signer, BigNumber } from "ethers";
import { N0__01_18DEC, ZERO } from "../utils/Constants";
import {
    prepareMockSpreadModel,
    MiltonUsdcCase,
    MiltonUsdtCase,
    MiltonDaiCase,
} from "../utils/MiltonUtils";

import { TestData, prepareTestData } from "../utils/DataUtils";
import { MockStanleyCase } from "../utils/StanleyUtils";
import { JosephUsdcMockCases, JosephUsdtMockCases, JosephDaiMockCases } from "../utils/JosephUtils";
import { MockSpreadModel, ItfIporOracle } from "../../types";

const { expect } = chai;

describe("ItfIporOracle", () => {
    let miltonSpreadModel: MockSpreadModel;
    let _iporOracle: ItfIporOracle;
    let admin: Signer,
        userOne: Signer,
        userTwo: Signer,
        userThree: Signer,
        liquidityProvider: Signer;

    beforeEach(async () => {
        [admin, userOne, userTwo, userThree, liquidityProvider] = await hre.ethers.getSigners();
        miltonSpreadModel = (await prepareMockSpreadModel(
            ZERO,
            ZERO,
            ZERO,
            ZERO
        )) as MockSpreadModel;
        const testData = (await prepareTestData(
            BigNumber.from(Math.floor(Date.now() / 1000)),
            [admin, userOne, userTwo, userThree],
            ["USDC", "USDT", "DAI"],
            [],
            miltonSpreadModel,
            MiltonUsdcCase.CASE0,
            MiltonUsdtCase.CASE0,
            MiltonDaiCase.CASE0,
            MockStanleyCase.CASE1,
            JosephUsdcMockCases.CASE0,
            JosephUsdtMockCases.CASE0,
            JosephDaiMockCases.CASE0
        )) as TestData;
        const { iporOracle } = testData;
        _iporOracle = iporOracle;
    });

    it("Should set new absolute value for decay factor", async () => {
        // given
        const timestamp = BigNumber.from("2225022130");
        const decayFactorBefore = await _iporOracle.itfGetDecayFactorValue(timestamp);
        // when
        await _iporOracle.setDecayFactor(N0__01_18DEC);
        // then
        const decayFactorAfter = await _iporOracle.itfGetDecayFactorValue(timestamp);

        expect(decayFactorAfter).to.be.equal(N0__01_18DEC);
        expect(decayFactorBefore).to.be.equal(ZERO);
    });
});

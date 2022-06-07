import hre, { ethers } from "hardhat";
import chai from "chai";
import { Signer, BigNumber } from "ethers";
import { PERCENTAGE_5_18DEC, N1__0_6DEC } from "../utils/Constants";

import { MockStanleyCase } from "../utils/StanleyUtils";
import { JosephUsdcMockCases, JosephUsdtMockCases, JosephDaiMockCases } from "../utils/JosephUtils";

import { ItfDataProvider } from "../../types";
import {
    prepareMockMiltonSpreadModel,
    MiltonUsdcCase,
    MiltonUsdtCase,
    MiltonDaiCase,
    MiltonSpreadModels,
    MockMiltonSpreadModel,
} from "../utils/MiltonUtils";

import { TestData, prepareTestData } from "../utils/DataUtils";

const { expect } = chai;

describe("ItfDataProvider - smoke tests", () => {
    let miltonSpreadModel: MockMiltonSpreadModel;
    let admin: Signer,
        userOne: Signer,
        userTwo: Signer,
        userThree: Signer,
        liquidityProvider: Signer,
        miltonStorageAddress: Signer;
    let testData: TestData;
    let itfDataProvider: ItfDataProvider;

    before(async () => {
        [admin, userOne, userTwo, userThree, liquidityProvider, miltonStorageAddress] =
            await hre.ethers.getSigners();
        miltonSpreadModel = await prepareMockMiltonSpreadModel(MiltonSpreadModels.BASE);
        testData = await prepareTestData(
            BigNumber.from(Math.floor(Date.now() / 1000)),
            [admin, userOne, userTwo, userThree, liquidityProvider, miltonStorageAddress],
            ["DAI", "USDC", "USDT"],
            [PERCENTAGE_5_18DEC, PERCENTAGE_5_18DEC, PERCENTAGE_5_18DEC],
            miltonSpreadModel,
            MiltonUsdcCase.CASE0,
            MiltonUsdtCase.CASE0,
            MiltonDaiCase.CASE0,
            MockStanleyCase.CASE1,
            JosephUsdcMockCases.CASE0,
            JosephUsdtMockCases.CASE0,
            JosephDaiMockCases.CASE0
        );
    });

    beforeEach(async () => {
        const ItfDataProvider = await ethers.getContractFactory("ItfDataProvider");
        itfDataProvider = (await ItfDataProvider.deploy()) as ItfDataProvider;
    });

    it("Should collect data from iporOracle for ITF", async () => {
        // Given
        const { miltonUsdc, tokenUsdc, iporOracle, miltonStorageUsdc, josephUsdc } = testData;

        if (
            miltonUsdc === undefined ||
            tokenUsdc === undefined ||
            iporOracle === undefined ||
            miltonStorageUsdc === undefined ||
            miltonSpreadModel === undefined ||
            josephUsdc === undefined
        ) {
            expect(true).to.be.false;
            return;
        }

        const liquidityAmount = BigNumber.from("1000000").mul(N1__0_6DEC);
        await tokenUsdc.setupInitialAmount(await admin.getAddress(), liquidityAmount);
        await tokenUsdc.approve(josephUsdc.address, liquidityAmount);
        await tokenUsdc.approve(miltonUsdc.address, liquidityAmount);
        await josephUsdc.provideLiquidity(liquidityAmount);
        await itfDataProvider.initialize(
            [tokenUsdc.address],
            [miltonUsdc.address],
            [miltonStorageUsdc.address],
            iporOracle.address,
            miltonSpreadModel.address
        );
        const calculateTimestamp = Math.floor(Date.now() / 1000);

        // when
        const iporOracleData = await itfDataProvider.collectIporOracleData(
            calculateTimestamp,
            tokenUsdc.address
        );
        const miltonData = await itfDataProvider.collectMiltonData(
            calculateTimestamp,
            tokenUsdc.address
        );
        const miltonStorageData = await itfDataProvider.collectMiltonStorageData(tokenUsdc.address);

        const miltonSpreadModelData = await itfDataProvider.collectMiltonSpreadModelData();

        const ammData = await itfDataProvider.itfAmmData(
            Math.floor(Date.now() / 1000),
            tokenUsdc.address
        );

        // then
        expect(iporOracleData.length).to.be.equal(10);
        expect(miltonData.length).to.be.equal(16);
        expect(miltonStorageData.length).to.be.equal(8);
        expect(miltonSpreadModelData.length).to.be.equal(17);
        expect(ammData.length).to.be.equal(4);
    });
});

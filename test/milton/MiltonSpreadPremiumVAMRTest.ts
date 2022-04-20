import hre from "hardhat";
import chai from "chai";
import { Signer, BigNumber } from "ethers";
import {
    MockMiltonSpreadModel,
    MiltonSpreadModels,
    prepareMockMiltonSpreadModel,
    prepareMiltonSpreadBase,
} from "../utils/MiltonUtils";

const { expect } = chai;

describe("MiltonSpreadModel - Spread Premium - Volatility And Mean Reversion", () => {
    let miltonSpreadModel: MockMiltonSpreadModel;
    let admin: Signer,
        userOne: Signer,
        userTwo: Signer,
        userThree: Signer,
        liquidityProvider: Signer,
        miltonStorageAddress: Signer;

    before(async () => {
        [admin, userOne, userTwo, userThree, liquidityProvider, miltonStorageAddress] =
            await hre.ethers.getSigners();
        miltonSpreadModel = await prepareMockMiltonSpreadModel(MiltonSpreadModels.CASE1);
    });

    it("should calculate spread - Volatility And Mean Reversion - Pay Fixed - Simple Case 1", async () => {
        //given
        const miltonSpread = await prepareMiltonSpreadBase();

        const emaVar = BigNumber.from("1065000000000000000");
        const mu = BigNumber.from("-7140000000000000000");
        const expectedResult = BigNumber.from("791318358294630906100");
        //when
        const actualResult = await miltonSpread
            .connect(liquidityProvider)
            .testCalculateVolatilityAndMeanReversionPayFixed(emaVar, mu);
        //then

        expect(expectedResult, `Incorrect Volatility and Mean Reversion, Pay Fixed leg`).to.be.eq(
            actualResult
        );
    });

    it("should calculate spread - Volatility And Mean Reversion - Receive Fixed - Simple Case 1", async () => {
        //given
        const miltonSpread = await prepareMiltonSpreadBase();

        const emaVar = BigNumber.from("1065000000000000000");
        const mu = BigNumber.from("-7140000000000000000");
        const expectedResult = BigNumber.from("-3489159569625102261");
        //when
        const actualResult = await miltonSpread
            .connect(liquidityProvider)
            .testCalculateVolatilityAndMeanReversionReceiveFixed(emaVar, mu);
        //then

        expect(
            expectedResult,
            `Incorrect Volatility and Mean Reversion, Receive Fixed leg`
        ).to.be.eq(actualResult);
    });

    it("should calculate spread - Volatility And Mean Reversion, Pay Fixed - Region One - Simple Case 1", async () => {
        //given
        const miltonSpread = await prepareMiltonSpreadBase();

        const emaVar = BigNumber.from("1065000000000000000");
        const mu = BigNumber.from("-7140000000000000000");
        const expectedResult = BigNumber.from("48882094945955889120");
        //when
        const actualResult = await miltonSpread
            .connect(liquidityProvider)
            .testVolatilityAndMeanReversionPayFixedRegionOne(emaVar, mu);
        //then

        expect(
            expectedResult,
            `Incorrect Volatility and Mean Reversion, Pay Fixed, Region One`
        ).to.be.eq(actualResult);
    });

    it("should calculate spread - Volatility And Mean Reversion, Receive Fixed - Region One - Simple Case 1", async () => {
        //given
        const miltonSpread = await prepareMiltonSpreadBase();

        const emaVar = BigNumber.from("1065000000000000000");
        const mu = BigNumber.from("-7140000000000000000");
        const expectedResult = BigNumber.from("-3489159569625102261");
        //when
        const actualResult = await miltonSpread
            .connect(liquidityProvider)
            .testVolatilityAndMeanReversionReceiveFixedRegionOne(emaVar, mu);
        //then

        expect(
            expectedResult,
            `Incorrect Volatility and Mean Reversion, Receive Fixed, Region One`
        ).to.be.eq(actualResult);
    });

    it("should calculate spread - Volatility And Mean Reversion, Pay Fixed - Region Two - Simple Case 1", async () => {
        //given
        const miltonSpread = await prepareMiltonSpreadBase();

        const emaVar = BigNumber.from("1065000000000000000");
        const mu = BigNumber.from("-7140000000000000000");
        const expectedResult = BigNumber.from("791318358294630906100");
        //when
        const actualResult = await miltonSpread
            .connect(liquidityProvider)
            .testVolatilityAndMeanReversionPayFixedRegionTwo(emaVar, mu);
        //then

        expect(
            expectedResult,
            `Incorrect Volatility and Mean Reversion, Pay Fixed, Region Two`
        ).to.be.eq(actualResult);
    });

    it("should calculate spread - Volatility And Mean Reversion, Receive Fixed - Region Two - Simple Case 1", async () => {
        //given
        const miltonSpread = await prepareMiltonSpreadBase();

        const emaVar = BigNumber.from("1065000000000000000");
        const mu = BigNumber.from("-7140000000000000000");
        const expectedResult = BigNumber.from("372475768680734065384");
        //when
        const actualResult = await miltonSpread
            .connect(liquidityProvider)
            .testVolatilityAndMeanReversionReceiveFixedRegionTwo(emaVar, mu);
        //then

        expect(
            expectedResult,
            `Incorrect Volatility and Mean Reversion, Receive Fixed, Region Two`
        ).to.be.eq(actualResult);
    });
});

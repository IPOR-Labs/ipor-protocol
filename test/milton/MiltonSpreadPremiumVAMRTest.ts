import hre from "hardhat";
import chai from "chai";
import { Signer, BigNumber } from "ethers";
import {
    N1__0_18DEC,
    TC_TOTAL_AMOUNT_10_000_18DEC,
    N0__1_18DEC,
    USD_1_000_18DEC,
    USD_2_000_18DEC,
    USD_14_000_18DEC,
    USD_20_18DEC,
    ZERO,
} from "../utils/Constants";
import {
    MockMiltonSpreadModel,
    MiltonSpreadModels,
    prepareMockMiltonSpreadModel,
    prepareMiltonSpreadBase,
    prepareMiltonSpreadCase3,
    prepareMiltonSpreadCase4,
    prepareMiltonSpreadCase5,
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
        const expectedResult = BigNumber.from("111523713219142301");
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
        const expectedResult = BigNumber.from("28177611700197706");
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

    it("should calculate spread - Volatility And Mean Reversion - Region One - Simple Case 1", async () => {
        //given
        const miltonSpread = await prepareMiltonSpreadBase();

        const emaVar = BigNumber.from("1065000000000000000");
        const mu = BigNumber.from("-7140000000000000000");
        const expectedResult = BigNumber.from("111523713219142301");
        //when
        const actualResult = await miltonSpread
            .connect(liquidityProvider)
            .testVolatilityAndMeanReversionRegionOne(emaVar, mu);
        //then

        expect(expectedResult, `Incorrect Volatility and Mean Reversion, Region One`).to.be.eq(
            actualResult
        );
    });

    it("should calculate spread - Volatility And Mean Reversion - Region Two - Simple Case 1", async () => {
        //given
        const miltonSpread = await prepareMiltonSpreadBase();

        const emaVar = BigNumber.from("1065000000000000000");
        const mu = BigNumber.from("-7140000000000000000");
        const expectedResult = BigNumber.from("28177611700197706");
        //when
        const actualResult = await miltonSpread
            .connect(liquidityProvider)
            .testVolatilityAndMeanReversionRegionTwo(emaVar, mu);
        //then

        expect(expectedResult, `Incorrect Volatility and Mean Reversion, Region Two`).to.be.eq(
            actualResult
        );
    });
});

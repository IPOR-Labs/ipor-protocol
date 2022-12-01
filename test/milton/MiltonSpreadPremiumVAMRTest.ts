import hre from "hardhat";
import chai from "chai";
import { Signer, BigNumber } from "ethers";
import { prepareMiltonSpreadBaseDai } from "../utils/MiltonUtils";

const { expect } = chai;

describe("MiltonSpreadModel - Spread Premium - Volatility And Mean Reversion", () => {
    let admin: Signer,
        userOne: Signer,
        userTwo: Signer,
        userThree: Signer,
        liquidityProvider: Signer,
        miltonStorageAddress: Signer;

    before(async () => {
        [admin, userOne, userTwo, userThree, liquidityProvider, miltonStorageAddress] =
            await hre.ethers.getSigners();
    });

    it("should calculate spread - Volatility And Mean Reversion - Pay Fixed - Simple Case 1", async () => {
        //given
        const miltonSpread = await prepareMiltonSpreadBaseDai();

        const emaVar = BigNumber.from("1065000000000000000");
        const diffIporIndexEma = BigNumber.from("-7140000000000000000");
        const expectedResult = BigNumber.from("234616050688066827447");
        //when
        const actualResult = await miltonSpread
            .connect(liquidityProvider)
            .mockTestCalculateVolatilityAndMeanReversionPayFixed(emaVar, diffIporIndexEma);
        //then

        expect(expectedResult, `Incorrect Volatility and Mean Reversion, Pay Fixed leg`).to.be.eq(
            actualResult
        );
    });

    it("should calculate spread - Volatility And Mean Reversion - Receive Fixed - Simple Case 1", async () => {
        //given
        const miltonSpread = await prepareMiltonSpreadBaseDai();

        const emaVar = BigNumber.from("1065000000000000000");
        const diffIporIndexEma = BigNumber.from("-7140000000000000000");
        const expectedResult = BigNumber.from("-95841997917942311442");
        //when
        const actualResult = await miltonSpread
            .connect(liquidityProvider)
            .mockTestCalculateVolatilityAndMeanReversionReceiveFixed(emaVar, diffIporIndexEma);
        //then

        expect(
            expectedResult,
            `Incorrect Volatility and Mean Reversion, Receive Fixed leg`
        ).to.be.eq(actualResult);
    });

    it("should calculate spread - Volatility And Mean Reversion, Pay Fixed - Region One - Simple Case 1", async () => {
        //given
        const miltonSpread = await prepareMiltonSpreadBaseDai();

        const emaVar = BigNumber.from("1065000000000000000");
        const diffIporIndexEma = BigNumber.from("-7140000000000000000");
        const expectedResult = BigNumber.from("78947314294154128210");
        //when
        const actualResult = await miltonSpread
            .connect(liquidityProvider)
            .mockTestVolatilityAndMeanReversionPayFixedRegionOne(emaVar, diffIporIndexEma);
        //then

        expect(
            expectedResult,
            `Incorrect Volatility and Mean Reversion, Pay Fixed, Region One`
        ).to.be.eq(actualResult);
    });

    it("should calculate spread - Volatility And Mean Reversion, Receive Fixed - Region One - Simple Case 1", async () => {
        //given
        const miltonSpread = await prepareMiltonSpreadBaseDai();

        const emaVar = BigNumber.from("1065000000000000000");
        const diffIporIndexEma = BigNumber.from("-7140000000000000000");
        const expectedResult = BigNumber.from("-31754644462878008830");
        //when
        const actualResult = await miltonSpread
            .connect(liquidityProvider)
            .mockTestVolatilityAndMeanReversionReceiveFixedRegionOne(emaVar, diffIporIndexEma);
        //then

        expect(
            expectedResult,
            `Incorrect Volatility and Mean Reversion, Receive Fixed, Region One`
        ).to.be.eq(actualResult);
    });

    it("should calculate spread - Volatility And Mean Reversion, Pay Fixed - Region Two - Simple Case 1", async () => {
        //given
        const miltonSpread = await prepareMiltonSpreadBaseDai();

        const emaVar = BigNumber.from("1065000000000000000");
        const diffIporIndexEma = BigNumber.from("-7140000000000000000");
        const expectedResult = BigNumber.from("234616050688066827447");
        //when
        const actualResult = await miltonSpread
            .connect(liquidityProvider)
            .mockTestVolatilityAndMeanReversionPayFixedRegionTwo(emaVar, diffIporIndexEma);
        //then

        expect(
            expectedResult,
            `Incorrect Volatility and Mean Reversion, Pay Fixed, Region Two`
        ).to.be.eq(actualResult);
    });

    it("should calculate spread - Volatility And Mean Reversion, Receive Fixed - Region Two - Simple Case 1", async () => {
        //given
        const miltonSpread = await prepareMiltonSpreadBaseDai();

        const emaVar = BigNumber.from("1065000000000000000");
        const diffIporIndexEma = BigNumber.from("-7140000000000000000");
        const expectedResult = BigNumber.from("-95841997917942311442");
        //when
        const actualResult = await miltonSpread
            .connect(liquidityProvider)
            .mockTestVolatilityAndMeanReversionReceiveFixedRegionTwo(emaVar, diffIporIndexEma);
        //then

        expect(
            expectedResult,
            `Incorrect Volatility and Mean Reversion, Receive Fixed, Region Two`
        ).to.be.eq(actualResult);
    });
});

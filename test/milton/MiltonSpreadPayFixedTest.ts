import hre from "hardhat";
import chai from "chai";
import { Signer, BigNumber } from "ethers";
import { MockSpreadModel } from "../../types";
import {
    ZERO,
    N0__001_18DEC,
    N0__1_18DEC,
    USD_20_18DEC,
    USD_100_18DEC,
    N0__01_18DEC,
    USD_13_000_18DEC,
    USD_15_000_18DEC,
    USD_10_000_000_18DEC,
    PERCENTAGE_3_18DEC,
    N1__0_18DEC,
    TC_TOTAL_AMOUNT_10_000_18DEC,
} from "../utils/Constants";
import {
    prepareMockSpreadModel,
    MiltonUsdcCase,
    MiltonUsdtCase,
    MiltonDaiCase,
    prepareMiltonSpreadBase,
    getReceiveFixedDerivativeParamsUSDTCase1,
} from "../utils/MiltonUtils";
import { assertError } from "../utils/AssertUtils";
import {
    prepareTestData,
    prepareApproveForUsers,
    setupTokenDaiInitialValuesForUsers,
    setupTokenUsdtInitialValuesForUsers,
} from "../utils/DataUtils";
import { MockStanleyCase } from "../utils/StanleyUtils";
import { JosephUsdcMockCases, JosephUsdtMockCases, JosephDaiMockCases } from "../utils/JosephUtils";

const { expect } = chai;

describe("MiltonSpreadModel - Pay Fixed", () => {
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

    it("should transfer ownership - simple case 1", async () => {
        //given
        const miltonSpread = await prepareMiltonSpreadBase();
        const expectedNewOwner = userTwo;

        //when
        await miltonSpread.connect(admin).transferOwnership(await expectedNewOwner.getAddress());

        await miltonSpread.connect(expectedNewOwner).confirmTransferOwnership();

        //then
        const actualNewOwner = await miltonSpread.connect(userOne).owner();
        expect(await expectedNewOwner.getAddress()).to.be.equal(actualNewOwner);
    });

    it("should NOT transfer ownership - sender not current owner", async () => {
        //given
        const miltonSpread = await prepareMiltonSpreadBase();
        const expectedNewOwner = userTwo;

        //when
        await assertError(
            miltonSpread.connect(userThree).transferOwnership(await expectedNewOwner.getAddress()),
            //then
            "Ownable: caller is not the owner"
        );
    });

    it("should NOT confirm transfer ownership - sender not appointed owner", async () => {
        //given
        const miltonSpread = await prepareMiltonSpreadBase();
        const expectedNewOwner = userTwo;

        //when
        await miltonSpread.connect(admin).transferOwnership(await expectedNewOwner.getAddress());

        await assertError(
            miltonSpread.connect(userThree).confirmTransferOwnership(),
            //then
            "IPOR_007"
        );
    });

    it("should NOT confirm transfer ownership twice - sender not appointed owner", async () => {
        //given
        const miltonSpread = await prepareMiltonSpreadBase();
        const expectedNewOwner = userTwo;

        //when
        await miltonSpread.connect(admin).transferOwnership(await expectedNewOwner.getAddress());

        await miltonSpread.connect(expectedNewOwner).confirmTransferOwnership();

        await assertError(
            miltonSpread.connect(expectedNewOwner).confirmTransferOwnership(),
            "IPOR_007"
        );
    });

    it("should NOT transfer ownership - sender already lost ownership", async () => {
        //given
        const miltonSpread = await prepareMiltonSpreadBase();
        const expectedNewOwner = userTwo;

        await miltonSpread.connect(admin).transferOwnership(await expectedNewOwner.getAddress());

        await miltonSpread.connect(expectedNewOwner).confirmTransferOwnership();

        //when
        await assertError(
            miltonSpread.connect(admin).transferOwnership(await expectedNewOwner.getAddress()),
            //then
            "Ownable: caller is not the owner"
        );
    });

    it("should have rights to transfer ownership - sender still have rights", async () => {
        //given
        const miltonSpread = await prepareMiltonSpreadBase();

        const expectedNewOwner = userTwo;

        await miltonSpread.connect(admin).transferOwnership(await expectedNewOwner.getAddress());

        //when
        await miltonSpread.connect(admin).transferOwnership(await expectedNewOwner.getAddress());

        //then
        const actualNewOwner = await miltonSpread.connect(userOne).owner();
        expect(await admin.getAddress()).to.be.equal(actualNewOwner);
    });

    it("should calculate Quote Value Pay Fixed Value - Spread Premium < Spread Premium Max Value, Base Case 1, Spread negative", async () => {
        //given
        miltonSpreadModel.setCalculateQuotePayFixed(BigNumber.from("130041797900449030"));
        const miltonSpread = await prepareMiltonSpreadBase();

        const liquidityPoolBalance = USD_15_000_18DEC;
        const swapCollateral = TC_TOTAL_AMOUNT_10_000_18DEC;
        const openingFee = USD_20_18DEC;

        const accruedIpor = {
            indexValue: BigNumber.from("13").mul(N0__01_18DEC), //13%
            ibtPrice: N1__0_18DEC,
            exponentialMovingAverage: BigNumber.from("1").mul(N0__01_18DEC),
            exponentialWeightedMovingVariance: BigNumber.from("15").mul(N0__001_18DEC),
        };

        const accruedBalance = {
            totalCollateralPayFixed: BigNumber.from("1000").mul(N1__0_18DEC).add(swapCollateral),
            totalCollateralReceiveFixed: USD_13_000_18DEC,
            openingFee: openingFee,
            liquidationDeposit: ZERO,
            vault: ZERO,
            iporPublicationFee: ZERO,
            liquidityPool: liquidityPoolBalance.add(openingFee),
            treasury: ZERO,
        };

        const expectedQuoteValue = BigNumber.from("129952238730246296");

        //when
        const actualQuotedValue = await miltonSpread
            .connect(userOne)
            .calculateQuotePayFixed(accruedIpor, accruedBalance);
        //then
        expect(actualQuotedValue).to.be.eq(expectedQuoteValue);
    });
    it("should calculate Quote Value Pay Fixed Value - Spread Premiums negative, Spread Premiums < IPOR Index", async () => {
        //TODO:
    });
    it("should calculate Quote Value Pay Fixed Value - Spread Premiums negative, Spread Premiums > IPOR Index", async () => {
        //TODO:
    });
    it("should calculate Quote Value Pay Fixed Value - Spread Premiums positive", async () => {
        //TODO:
    });

    // it.skip("should calculate Spread Pay Fixed - spread premiums higher than IPOR Index", async () => {
    //     //given
    //     let testData = await prepareTestData(
    //         BigNumber.from(Math.floor(Date.now() / 1000)),
    //         [admin, userOne, userTwo, userThree, liquidityProvider],
    //         ["USDT"],
    //         [PERCENTAGE_3_18DEC],
    //         miltonSpreadModel,
    //         MiltonUsdcCase.CASE0,
    //         MiltonUsdtCase.CASE0,
    //         MiltonDaiCase.CASE0,
    //         MockStanleyCase.CASE0,
    //         JosephUsdcMockCases.CASE0,
    //         JosephUsdtMockCases.CASE0,
    //         JosephDaiMockCases.CASE0
    //     );

    //     const { tokenUsdt, iporOracle, josephUsdt, miltonUsdt } = testData;

    //     if (tokenUsdt === undefined || josephUsdt === undefined || miltonUsdt === undefined) {
    //         expect(true).to.be.false;
    //         return;
    //     }

    //     const params = getReceiveFixedDerivativeParamsUSDTCase1(userTwo, tokenUsdt);

    //     await iporOracle
    //         .connect(userOne)
    //         .itfUpdateIndex(params.asset, PERCENTAGE_3_18DEC, params.openTimestamp);

    //     let balanceLiquidityPool = BigNumber.from("10000000000");

    //     await prepareApproveForUsers(
    //         [userOne, userTwo, userThree, liquidityProvider],
    //         "USDT",
    //         testData
    //     );
    //     await setupTokenUsdtInitialValuesForUsers(
    //         [admin, userOne, userTwo, userThree, liquidityProvider],
    //         tokenUsdt
    //     );

    //     await josephUsdt
    //         .connect(liquidityProvider)
    //         .itfProvideLiquidity(balanceLiquidityPool, params.openTimestamp);

    //     await miltonUsdt
    //         .connect(userTwo)
    //         .itfOpenSwapReceiveFixed(
    //             params.openTimestamp,
    //             BigNumber.from("1000000000"),
    //             params.acceptableFixedInterestRate,
    //             params.leverage
    //         );

    //     //when
    //     let actualSpreadValue = await miltonUsdt
    //         .connect(userOne)
    //         .callStatic.itfCalculateSpread(params.openTimestamp.add(BigNumber.from("1")));

    //     //then
    //     expect(actualSpreadValue.spreadPayFixed).to.be.gt(ZERO);
    // });
});

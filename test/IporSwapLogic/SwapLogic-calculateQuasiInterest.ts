import hre from "hardhat";
import chai from "chai";
import { BigNumber, Signer } from "ethers";
import { MockIporSwapLogic } from "../../types";
import {
    N1__0_18DEC,
    N0__01_18DEC,
    PERIOD_25_DAYS_IN_SECONDS,
    PERIOD_50_DAYS_IN_SECONDS,
} from "../utils/Constants";
import {
    prepareSwapPayFixedCase1,
    prepareSwapDaiCase1,
    prepareSwapUsdtCase1,
} from "../utils/SwapUtils";

const { expect } = chai;

describe("IporSwapLogic calculateQuasiInterest", () => {
    let iporSwapLogic: MockIporSwapLogic;
    let admin: Signer;

    before(async () => {
        const MockIporSwapLogic = await hre.ethers.getContractFactory("MockIporSwapLogic");
        iporSwapLogic = (await MockIporSwapLogic.deploy()) as MockIporSwapLogic;
        [admin] = await hre.ethers.getSigners();
    });

    it("Calculate Quasi Interest Case Huge Ipor 25 days Later IBT Price Changed User Loses Decimals 18", async () => {
        const iporIndex = BigNumber.from("365").mul(N0__01_18DEC);
        const spread = N0__01_18DEC;
        const fixedInterestRate = iporIndex.add(spread);

        const swap = await prepareSwapPayFixedCase1(fixedInterestRate, admin);

        const ibtPriceSecond = BigNumber.from("125").mul(N1__0_18DEC);

        //when
        const quasiInterest = await iporSwapLogic.calculateQuasiInterest(
            swap,
            swap.openTimestamp.add(PERIOD_25_DAYS_IN_SECONDS),
            ibtPriceSecond
        );

        //then
        expect(quasiInterest.quasiIFixed, "Wrong interest fixed").to.be.equal(
            "3893004244800000000000000000000000000000000000000"
        );
        expect(quasiInterest.quasiIFloating, "Wrong interest floating").to.be.equal(
            "3890872260000000000000000000000000000000000000000"
        );
    });

    it("Calculate Quasi Interest Case 100 days Later IBT Price Not Changed Decimals 18", async () => {
        //given

        const fixedInterestRate = BigNumber.from("4").mul(N0__01_18DEC);
        const swap = await prepareSwapPayFixedCase1(fixedInterestRate, admin);
        const ibtPriceSecond = BigNumber.from("120").mul(N1__0_18DEC);

        //when

        const quasiInterest = await iporSwapLogic.calculateQuasiInterest(
            swap,
            swap.openTimestamp.add(PERIOD_25_DAYS_IN_SECONDS.mul(BigNumber.from("4"))),
            ibtPriceSecond
        );

        //then
        expect(quasiInterest.quasiIFixed, "Wrong quasi interest fixed").to.be.equal(
            "3146809564800000000000000000000000000000000000000"
        );
        expect(quasiInterest.quasiIFloating, "Wrong interest floating").to.be.equal(
            "3735237369600000000000000000000000000000000000000"
        );
    });

    it("Calculate Quasi Interest Case 1", async () => {
        //given
        const fixedInterestRate = BigNumber.from("4").mul(N0__01_18DEC);
        const swap = await prepareSwapPayFixedCase1(fixedInterestRate, admin);
        //when
        const quastiInterest = await iporSwapLogic.calculateQuasiInterest(
            swap,
            swap.openTimestamp.add(BigNumber.from(60 * 60 * 24 * 28)),
            N1__0_18DEC
        );
        //then
        expect(quastiInterest.quasiIFixed, "Wrong Quasi Interest Fixed").to.be.equal(
            "3122249099904000000000000000000000000000000000000"
        );
        expect(quastiInterest.quasiIFloating, "Wrong Quasi Interest Floating").to.be.equal(
            BigNumber.from("31126978080000000000000000000000000000000000000")
        );
    });

    it("Should revert when closingTimestamp < openTimestamp", async () => {
        //given
        const fixedInterestRate = BigNumber.from("4").mul(N0__01_18DEC);
        const swap = await prepareSwapPayFixedCase1(fixedInterestRate, admin);
        //when
        await expect(
            iporSwapLogic.calculateQuasiInterest(
                swap,
                swap.openTimestamp.sub(BigNumber.from(60 * 60 * 24 * 28)),
                N1__0_18DEC
            )
        ).to.be.revertedWith("IPOR_319");
    });

    it("Calculate Quasi Interest Case 2 Same Timestamp IBT Price Increase Decimal 18 Case1", async () => {
        //given
        const fixedInterestRate = BigNumber.from("4").mul(N0__01_18DEC);
        const swap = await prepareSwapPayFixedCase1(fixedInterestRate, admin);

        const ibtPriceSecond = BigNumber.from("125").mul(N1__0_18DEC);
        //when
        const quasiInterest = await iporSwapLogic.calculateQuasiInterest(
            swap,
            swap.openTimestamp,
            ibtPriceSecond
        );

        //then
        expect(quasiInterest.quasiIFixed, "Wrong Quasi Interest Fixed").to.be.equal(
            "3112697808000000000000000000000000000000000000000"
        );
        expect(quasiInterest.quasiIFloating, "Wrong Quasi Interest Floating").to.be.equal(
            "3890872260000000000000000000000000000000000000000"
        );
    });

    it("Calculate Quasi Interest Case 25 days Later IBT Price Not Changed Decimals 18", async () => {
        //given

        const fixedInterestRate = BigNumber.from("4").mul(N0__01_18DEC);
        const swap = await prepareSwapPayFixedCase1(fixedInterestRate, admin);
        const ibtPrice = BigNumber.from("100").mul(N1__0_18DEC);

        //when

        const quasiInterest = await iporSwapLogic.calculateQuasiInterest(
            swap,
            swap.openTimestamp.add(PERIOD_25_DAYS_IN_SECONDS),
            ibtPrice
        );

        //then
        expect(quasiInterest.quasiIFixed, "Wrong Quasi Interest Fixed").to.be.equal(
            "3121225747200000000000000000000000000000000000000"
        );
        expect(quasiInterest.quasiIFloating, "Wrong Quasi Interest Floating").to.be.equal(
            "3112697808000000000000000000000000000000000000000"
        );
    });

    it("Calculate Quasi Interest Case 25 days Later IBT Price Changed Decimals 18", async () => {
        const fixedInterestRate = BigNumber.from("4").mul(N0__01_18DEC);
        const swap = await prepareSwapPayFixedCase1(fixedInterestRate, admin);
        const ibtPrice = BigNumber.from("125").mul(N1__0_18DEC);

        //when

        const quasiInterest = await iporSwapLogic.calculateQuasiInterest(
            swap,
            swap.openTimestamp.add(PERIOD_25_DAYS_IN_SECONDS),
            ibtPrice
        );

        //then
        expect(quasiInterest.quasiIFixed, "Wrong Quasi Interest Fixed").to.be.equal(
            "3121225747200000000000000000000000000000000000000"
        );
        expect(quasiInterest.quasiIFloating, "Wrong Quasi Interest Floating").to.be.equal(
            "3890872260000000000000000000000000000000000000000"
        );
    });
    it("Calculate Quasi Interest, 50 days Later IBT Price Changed Decimals 18", async () => {
        const fixedInterestRate = BigNumber.from("4").mul(N0__01_18DEC);
        const swap = await prepareSwapDaiCase1(fixedInterestRate, admin);
        const ibtPrice = BigNumber.from("125").mul(N1__0_18DEC);

        //when

        const quasiInterest = await iporSwapLogic.calculateQuasiInterest(
            swap,
            swap.openTimestamp.add(PERIOD_50_DAYS_IN_SECONDS),
            ibtPrice
        );

        //then
        expect(quasiInterest.quasiIFixed, "Wrong Quasi Interest Fixed").to.be.equal(
            "3129753686400000000000000000000000000000000000000"
        );
        expect(quasiInterest.quasiIFloating, "Wrong Quasi Interest Floating").to.be.equal(
            "3890872260000000000000000000000000000000000000000"
        );
    });
    it("Calculate Quasi Interest, 50 days Later IBT Price Changed Decimals 6", async () => {
        const fixedInterestRate = BigNumber.from("4").mul(N0__01_18DEC);
        const swap = await prepareSwapUsdtCase1(fixedInterestRate, admin);
        const ibtPrice = BigNumber.from("125").mul(N1__0_18DEC);

        //when

        const quasiInterest = await iporSwapLogic.calculateQuasiInterest(
            swap,
            swap.openTimestamp.add(PERIOD_50_DAYS_IN_SECONDS),
            ibtPrice
        );

        //then
        expect(quasiInterest.quasiIFixed, "Wrong Quasi Interest Fixed").to.be.equal(
            "3129753686400000000000000000000000000000000000000"
        );
        expect(quasiInterest.quasiIFloating, "Wrong Quasi Interest Floating").to.be.equal(
            "3890872260000000000000000000000000000000000000000"
        );
    });
});

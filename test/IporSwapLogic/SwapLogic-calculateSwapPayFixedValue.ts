import hre from "hardhat";
import chai from "chai";
import { BigNumber, Signer } from "ethers";
import { MockIporSwapLogic } from "../../types";
import { N1__0_18DEC, N0__01_18DEC, PERIOD_25_DAYS_IN_SECONDS } from "../utils/Constants";
import { prepareSwapPayFixedCase1, prepareSwapDaiCase1, prepareSwapUsdtCase1 } from "../utils/SwapUtils";

const { expect } = chai;

describe("IporSwapLogic calculateSwapPayFixedValue", () => {
    let iporSwapLogic: MockIporSwapLogic;
    let admin: Signer;

    before(async () => {
        const MockIporSwapLogic = await hre.ethers.getContractFactory("MockIporSwapLogic");
        iporSwapLogic = (await MockIporSwapLogic.deploy()) as MockIporSwapLogic;
        iporSwapLogic.deployed();
        [admin] = await hre.ethers.getSigners();
    });

    it("Calculate Interest Case 1", async () => {
        //given
        const fixedInterestRate = BigNumber.from("40000000000000000");
        const swap = await prepareSwapPayFixedCase1(fixedInterestRate, admin);
        //when
        const swapValue = await iporSwapLogic.calculateSwapPayFixedValue(
            swap,
            BigInt(Date.now() + 60 * 60 * 24 * 28),
            N1__0_18DEC
        );
        //then
        expect(swapValue, "Wrong interest difference amount").to.be.equal(
            BigInt("-50000000000000000000000")
        );
    });

    it("Calculate Interest Case 2 Same Timestamp IBT Price Increase Decimal 18 Case1", async () => {
        //given
        const fixedInterestRate = BigNumber.from("4").mul(N0__01_18DEC);
        const swap = await prepareSwapPayFixedCase1(fixedInterestRate, admin);

        const ibtPriceSecond = BigNumber.from(125).mul(N1__0_18DEC);
        //when
        const swapValue = await iporSwapLogic.calculateSwapPayFixedValue(
            swap,
            swap.openTimestamp,
            ibtPriceSecond
        );

        //then
        expect(swapValue, "Wrong interest difference amount").to.be.equal(
            "24675750000000000000000"
        );
    });

    it("Calculate Interest Case 25 days Later IBT Price Not Changed Decimal18", async () => {
        //given

        const fixedInterestRate = BigNumber.from("4").mul(N0__01_18DEC);
        const swap = await prepareSwapPayFixedCase1(fixedInterestRate, admin);
        const ibtPriceSecond = BigNumber.from(100).mul(N1__0_18DEC);

        //when

        const swapValue = await iporSwapLogic.calculateSwapPayFixedValue(
            swap,
            swap.openTimestamp.add(PERIOD_25_DAYS_IN_SECONDS),
            ibtPriceSecond
        );

        //then
        expect(swapValue, "Wrong interest difference amount").to.be.equal("-270419178082191780821");
    });

    it("Calculate Interest Case 25 days Later IBT Price Changed Decimals 18", async () => {
        const fixedInterestRate = BigNumber.from("4").mul(N0__01_18DEC);
        const swap = await prepareSwapPayFixedCase1(fixedInterestRate, admin);
        const ibtPriceSecond = BigNumber.from(125).mul(N1__0_18DEC);

        //when

        const swapValue = await iporSwapLogic.calculateSwapPayFixedValue(
            swap,
            swap.openTimestamp.add(PERIOD_25_DAYS_IN_SECONDS),
            ibtPriceSecond
        );

        //then
        expect(swapValue, "Wrong interest difference amount").to.be.equal(
            "24405330821917808219178"
        );
    });

    it("Calculate Interest Case Huge Ipor 25 days Later IBT Price Changed User Loses Decimals 18", async () => {
        const iporIndex = BigNumber.from("3650000000000000000");
        const spread = N0__01_18DEC;
        const fixedInterestRate = iporIndex.add(spread);

        const swap = await prepareSwapPayFixedCase1(fixedInterestRate, admin);

        const ibtPriceSecond = BigNumber.from(125).mul(N1__0_18DEC);

        //when
        const swapValue = await iporSwapLogic.calculateSwapPayFixedValue(
            swap,
            swap.openTimestamp.add(PERIOD_25_DAYS_IN_SECONDS),
            ibtPriceSecond
        );

        //then
        expect(swapValue, "Wrong interest difference amount").to.be.equal("-67604794520547945204");
    });

    it("Calculate Interest Case 100 days Later IBT Price Not Changed Decimals 18", async () => {
        //given

        const fixedInterestRate = BigNumber.from("4").mul(N0__01_18DEC);
        const swap = await prepareSwapPayFixedCase1(fixedInterestRate, admin);
        const ibtPriceSecond = BigNumber.from("120").mul(N1__0_18DEC);

        //when

        const swapValue = await iporSwapLogic.calculateSwapPayFixedValue(
            swap,
            swap.openTimestamp.add(PERIOD_25_DAYS_IN_SECONDS.mul(BigNumber.from("4"))),
            ibtPriceSecond
        );

        //then
        expect(swapValue, "Wrong interest difference amount").to.be.equal(
            "18658923287671232876712"
        );
    });

    it("Calculate Interest Case 100 days Later IBT Price Changed Decimals 18", async () => {
        //given

        const fixedInterestRate = BigNumber.from("4").mul(N0__01_18DEC);
        const swap = await prepareSwapDaiCase1(fixedInterestRate, admin);
        const ibtPriceSecond = BigNumber.from("120").mul(N1__0_18DEC);

        //when

        const swapValue = await iporSwapLogic.calculateSwapPayFixedValue(
            swap,
            swap.openTimestamp.add(PERIOD_25_DAYS_IN_SECONDS.mul(BigNumber.from("4"))),
            ibtPriceSecond
        );

        //then
        expect(swapValue, "Wrong interest difference amount").to.be.equal(
            "18658923287671232876712"
        );
    });

    it("Calculate Interest Case 100 days Later IBT Price Changed Decimals 6", async () => {
        //given

        const fixedInterestRate = BigNumber.from("4").mul(N0__01_18DEC);
        const swap = await prepareSwapUsdtCase1(fixedInterestRate, admin);
        const ibtPriceSecond = BigNumber.from("120").mul(N1__0_18DEC);

        //when

        const swapValue = await iporSwapLogic.calculateSwapPayFixedValue(
            swap,
            swap.openTimestamp.add(PERIOD_25_DAYS_IN_SECONDS.mul(BigNumber.from("4"))),
            ibtPriceSecond
        );

        //then
        expect(swapValue, "Wrong interest difference amount").to.be.equal(
            "18658923287671232876712"
        );
    });
});

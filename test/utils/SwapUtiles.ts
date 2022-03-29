import chai from "chai";
import {
    DaiMockedToken,
    UsdtMockedToken,
    UsdcMockedToken,
    MiltonUsdt,
    MiltonUsdc,
    MiltonDai,
} from "../../types";
import { BigNumber, Signer } from "ethers";
import { N1__0_18DEC, TC_50_000_18DEC, ZERO } from "../utils/Constants";
import { TestData } from "./DataUtils";

const { expect } = chai;

export enum SwapState {
    "INACTIVE",
    "ACTIVE",
}

export type SWAP = {
    state: SwapState;
    buyer: string;
    asset: string;
    openTimestamp: BigNumber;
    endTimestamp: BigNumber;
    id: BigNumber;
    idsIndex: BigNumber;
    collateral: BigNumber;
    liquidationDepositAmount: BigNumber;
    notionalAmount: BigNumber;
    ibtQuantity: BigNumber;
    fixedInterestRate: BigNumber;
};

export type Params = {
    asset?: UsdcMockedToken | UsdtMockedToken | DaiMockedToken;
    miltonUsdt?: MiltonUsdt;
    miltonUsdc?: MiltonUsdc;
    miltonDai?: MiltonDai;
    expectedSoap?: BigNumber;
    totalAmount?: BigNumber;
    toleratedQuoteValue?: BigNumber;
    leverage?: BigNumber;
    direction?: number;
    openTimestamp?: BigNumber;
    from: Signer;
    calculateTimestamp?: BigNumber;
};

export const prepareSwapPayFixedCase1 = async (
    fixedInterestRate: BigNumber,
    admin: Signer
): Promise<SWAP> => {
    const DaiMockedToken = await hre.ethers.getContractFactory("DaiMockedToken");
    const daiMockedToken = (await DaiMockedToken.deploy(N1__0_18DEC, 18)) as DaiMockedToken;
    const collateral = BigNumber.from("9870300000000000000000");
    const leverage = BigNumber.from("10");

    const timeStamp = Math.floor(Date.now() / 1000);
    const notionalAmount = collateral.mul(leverage);
    const swap = {
        state: SwapState.ACTIVE,
        buyer: await admin.getAddress(),
        asset: daiMockedToken.address,
        openTimestamp: BigNumber.from(timeStamp),
        endTimestamp: BigNumber.from(timeStamp + 60 * 60 * 24 * 28),
        id: BigNumber.from("0"),
        idsIndex: BigNumber.from("0"),
        collateral: TC_50_000_18DEC,
        liquidationDepositAmount: BigNumber.from("20").mul(N1__0_18DEC),
        notionalAmount,
        ibtQuantity: BigNumber.from("987030000000000000000"), //ibtQuantity
        fixedInterestRate: fixedInterestRate,
    };
    return swap;
};

export const openSwapReceiveFixed = async (testData: TestData, params: Params) => {
    if (
        testData.miltonUsdt &&
        testData.tokenUsdt &&
        params.asset &&
        params.asset.address === testData.tokenUsdt.address
    ) {
        await testData.miltonUsdt
            .connect(params.from)
            .itfOpenSwapReceiveFixed(
                params.openTimestamp || ZERO,
                params.totalAmount || ZERO,
                params.toleratedQuoteValue || ZERO,
                params.leverage || ZERO
            );
    }

    if (
        testData.miltonUsdc &&
        testData.tokenUsdc &&
        params.asset &&
        params.asset.address === testData.tokenUsdc.address
    ) {
        await testData.miltonUsdc
            .connect(params.from)
            .itfOpenSwapReceiveFixed(
                params.openTimestamp || ZERO,
                params.totalAmount || ZERO,
                params.toleratedQuoteValue || ZERO,
                params.leverage || ZERO
            );
    }

    if (
        testData.miltonDai &&
        testData.tokenDai &&
        params.asset &&
        params.asset.address === testData.tokenDai.address
    ) {
        await testData.miltonDai
            .connect(params.from)
            .itfOpenSwapReceiveFixed(
                params.openTimestamp || ZERO,
                params.totalAmount || ZERO,
                params.toleratedQuoteValue || ZERO,
                params.leverage || ZERO
            );
    }
};

export const openSwapPayFixed = async (testData: TestData, params: Params) => {
    if (
        testData.miltonUsdt &&
        testData.tokenUsdt &&
        params.asset &&
        params.asset.address === testData.tokenUsdt.address
    ) {
        await testData.miltonUsdt
            .connect(params.from)
            .itfOpenSwapPayFixed(
                params.openTimestamp || ZERO,
                params.totalAmount || ZERO,
                params.toleratedQuoteValue || ZERO,
                params.leverage || ZERO
            );
    }

    if (
        testData.miltonUsdc &&
        testData.tokenUsdc &&
        params.asset &&
        params.asset.address === testData.tokenUsdc.address
    ) {
        await testData.miltonUsdc
            .connect(params.from)
            .itfOpenSwapPayFixed(
                params.openTimestamp || ZERO,
                params.totalAmount || ZERO,
                params.toleratedQuoteValue || ZERO,
                params.leverage || ZERO
            );
    }

    if (
        testData.miltonDai &&
        testData.tokenDai &&
        params.asset &&
        params.asset.address === testData.tokenDai.address
    ) {
        await testData.miltonDai
            .connect(params.from)
            .itfOpenSwapPayFixed(
                params.openTimestamp || ZERO,
                params.totalAmount || ZERO,
                params.toleratedQuoteValue || ZERO,
                params.leverage || ZERO
            );
    }
};

export const assertSoap = async (testData: TestData, params: Params) => {
    const actualSoapStruct = await calculateSoap(testData, params);
    const actualSoap = actualSoapStruct?.soap;

    //then
    expect(
        params.expectedSoap,
        `Incorrect SOAP for asset ${params.asset} actual: ${actualSoap}, expected: ${params.expectedSoap}`
    ).to.be.eq(actualSoap);
};

export const calculateSoap = async (testData: TestData, params: Params) => {
    if (
        testData.miltonUsdt &&
        testData.tokenUsdt &&
        params.asset &&
        params.asset.address === testData.tokenUsdt.address
    ) {
        return await testData.miltonUsdt
            .connect(params.from)
            .itfCalculateSoap(params.calculateTimestamp || ZERO);
    }

    if (
        testData.miltonUsdc &&
        testData.tokenUsdc &&
        params.asset &&
        params.asset.address === testData.tokenUsdc.address
    ) {
        return await testData.miltonUsdc
            .connect(params.from)
            .itfCalculateSoap(params.calculateTimestamp || ZERO);
    }

    if (
        testData.miltonDai &&
        testData.tokenDai &&
        params.asset &&
        params.asset.address === testData.tokenDai.address
    ) {
        return await testData.miltonDai
            .connect(params.from)
            .itfCalculateSoap(params.calculateTimestamp || ZERO);
    }
};

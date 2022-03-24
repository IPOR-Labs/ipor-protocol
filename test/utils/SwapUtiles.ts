import { DaiMockedToken } from "../../types";
import { BigNumber, Signer } from "ethers";
import { ONE_18DEC, TC_50_000_18DEC } from "../utils/Constants";

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

export const prepareSwapPayFixedCase1 = async (
    fixedInterestRate: BigNumber,
    admin: Signer
): Promise<SWAP> => {
    const DaiMockedToken = await hre.ethers.getContractFactory("DaiMockedToken");
    const daiMockedToken = (await DaiMockedToken.deploy(ONE_18DEC, 18)) as DaiMockedToken;
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
        liquidationDepositAmount: BigNumber.from("20").mul(ONE_18DEC),
        notionalAmount,
        ibtQuantity: BigNumber.from("987030000000000000000"), //ibtQuantity
        fixedInterestRate: fixedInterestRate,
    };
    return swap;
};

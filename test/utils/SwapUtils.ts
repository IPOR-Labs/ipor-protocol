import chai from "chai";
import { DaiMockedToken, UsdtMockedToken, MiltonUsdt, MiltonUsdc, MiltonDai } from "../../types";
import { BigNumber, Signer } from "ethers";
import {
    N1__0_6DEC,
    N1__0_18DEC,
    N0__01_18DEC,
    TC_50_000_18DEC,
    ZERO,
    TC_TOTAL_AMOUNT_10_000_18DEC,
    USD_10_000_6DEC,
    N0__1_18DEC,
} from "./Constants";
import { TestData } from "./DataUtils";
import { assertExpectedValues } from "./AssertUtils";

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
    notional: BigNumber;
    ibtQuantity: BigNumber;
    fixedInterestRate: BigNumber;
};

export type Params = {
    asset?: string;
    miltonUsdt?: MiltonUsdt;
    miltonUsdc?: MiltonUsdc;
    miltonDai?: MiltonDai;
    expectedSoap?: BigNumber;
    totalAmount?: BigNumber;
    acceptableFixedInterestRate?: BigNumber;
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
    return prepareSwapDaiCase1(fixedInterestRate, admin);
};

export const prepareSwapDaiCase1 = async (
    fixedInterestRate: BigNumber,
    admin: Signer
): Promise<SWAP> => {
    const DaiMockedToken = await hre.ethers.getContractFactory("DaiMockedToken");
    const daiMockedToken = (await DaiMockedToken.deploy(N1__0_18DEC, 18)) as DaiMockedToken;
    const collateral = BigNumber.from("9870300000000000000000");
    const leverage = BigNumber.from("10");

    const timeStamp = Math.floor(Date.now() / 1000);
    const notional = collateral.mul(leverage);
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
        notional,
        ibtQuantity: BigNumber.from("987030000000000000000"), //ibtQuantity
        fixedInterestRate: fixedInterestRate,
    };
    return swap;
};

export const prepareSwapUsdtCase1 = async (
    fixedInterestRate: BigNumber,
    admin: Signer
): Promise<SWAP> => {
    const UsdtMockedToken = await hre.ethers.getContractFactory("UsdtMockedToken");
    const usdtMockedToken = (await UsdtMockedToken.deploy(N1__0_6DEC, 6)) as UsdtMockedToken;
    const collateral = BigNumber.from("9870300000000000000000");
    const leverage = BigNumber.from("10");

    const timeStamp = Math.floor(Date.now() / 1000);
    const notional = collateral.mul(leverage);
    const swap = {
        state: SwapState.ACTIVE,
        buyer: await admin.getAddress(),
        asset: usdtMockedToken.address,
        openTimestamp: BigNumber.from(timeStamp),
        endTimestamp: BigNumber.from(timeStamp + 60 * 60 * 24 * 28),
        id: BigNumber.from("0"),
        idsIndex: BigNumber.from("0"),
        collateral: TC_50_000_18DEC,
        liquidationDepositAmount: BigNumber.from("20").mul(N1__0_18DEC),
        notional,
        ibtQuantity: BigNumber.from("987030000000000000000"), //ibtQuantity
        fixedInterestRate: fixedInterestRate,
    };
    return swap;
};

export const openSwapReceiveFixed = async (testData: TestData, params: Params) => {
    if (testData.miltonUsdt && testData.tokenUsdt && params.asset === testData.tokenUsdt.address) {
        await testData.miltonUsdt
            .connect(params.from)
            .itfOpenSwapReceiveFixed(
                params.openTimestamp || ZERO,
                params.totalAmount || ZERO,
                params.acceptableFixedInterestRate || ZERO,
                params.leverage || ZERO
            );
    }

    if (testData.miltonUsdc && testData.tokenUsdc && params.asset === testData.tokenUsdc.address) {
        await testData.miltonUsdc
            .connect(params.from)
            .itfOpenSwapReceiveFixed(
                params.openTimestamp || ZERO,
                params.totalAmount || ZERO,
                params.acceptableFixedInterestRate || ZERO,
                params.leverage || ZERO
            );
    }

    if (testData.miltonDai && testData.tokenDai && params.asset === testData.tokenDai.address) {
        await testData.miltonDai
            .connect(params.from)
            .itfOpenSwapReceiveFixed(
                params.openTimestamp || ZERO,
                params.totalAmount || ZERO,
                params.acceptableFixedInterestRate || ZERO,
                params.leverage || ZERO
            );
    }
};

export const openSwapPayFixed = async (testData: TestData, params: Params) => {
    if (
        testData.miltonUsdt &&
        testData.tokenUsdt &&
        params.asset &&
        params.asset === testData.tokenUsdt.address
    ) {
        await testData.miltonUsdt
            .connect(params.from)
            .itfOpenSwapPayFixed(
                params.openTimestamp || ZERO,
                params.totalAmount || ZERO,
                params.acceptableFixedInterestRate || ZERO,
                params.leverage || ZERO
            );
    }

    if (
        testData.miltonUsdc &&
        testData.tokenUsdc &&
        params.asset &&
        params.asset === testData.tokenUsdc.address
    ) {
        await testData.miltonUsdc
            .connect(params.from)
            .itfOpenSwapPayFixed(
                params.openTimestamp || ZERO,
                params.totalAmount || ZERO,
                params.acceptableFixedInterestRate || ZERO,
                params.leverage || ZERO
            );
    }

    if (
        testData.miltonDai &&
        testData.tokenDai &&
        params.asset &&
        params.asset === testData.tokenDai.address
    ) {
        await testData.miltonDai
            .connect(params.from)
            .itfOpenSwapPayFixed(
                params.openTimestamp || ZERO,
                params.totalAmount || ZERO,
                params.acceptableFixedInterestRate || ZERO,
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
        params.asset === testData.tokenUsdt.address
    ) {
        return await testData.miltonUsdt
            .connect(params.from)
            .itfCalculateSoap(params.calculateTimestamp || ZERO);
    }

    if (
        testData.miltonUsdc &&
        testData.tokenUsdc &&
        params.asset &&
        params.asset === testData.tokenUsdc.address
    ) {
        return await testData.miltonUsdc
            .connect(params.from)
            .itfCalculateSoap(params.calculateTimestamp || ZERO);
    }

    if (
        testData.miltonDai &&
        testData.tokenDai &&
        params.asset &&
        params.asset === testData.tokenDai.address
    ) {
        return await testData.miltonDai
            .connect(params.from)
            .itfCalculateSoap(params.calculateTimestamp || ZERO);
    }
};

type State = {
    state: BigNumber;
};

export type Derivatives = {
    swaps: State[];
};

export const countOpenSwaps = (derivatives: Derivatives | undefined): number => {
    if (derivatives === undefined) {
        return 0;
    }
    let count = 0;
    const ONE = BigNumber.from("1");
    for (let i = 0; i < derivatives.swaps.length; i++) {
        if (derivatives.swaps[i].state.eq(ONE)) {
            count++;
        }
    }
    return count;
};

export const exetuceCloseSwapTestCase = async function (
    testData: TestData,
    asset: string,
    leverage: BigNumber,
    direction: number,
    openerUser: Signer,
    closerUser: Signer,
    iporValueBeforeOpenSwap: BigNumber,
    iporValueAfterOpenSwap: BigNumber,
    acceptableFixedInterestRate: BigNumber,
    periodOfTimeElapsedInSeconds: BigNumber,
    providedLiquidityAmount: BigNumber,
    expectedMiltonUnderlyingTokenBalance: BigNumber,
    expectedOpenerUserUnderlyingTokenBalanceAfterPayOut: BigNumber,
    expectedCloserUserUnderlyingTokenBalanceAfterPayOut: BigNumber,
    expectedLiquidityPoolTotalBalanceWad: BigNumber,
    expectedOpenedPositions: BigNumber,
    expectedDerivativesTotalBalanceWad: BigNumber,
    expectedTreasuryTotalBalanceWad: BigNumber,
    expectedSoap: BigNumber,
    openTimestamp: BigNumber,
    expectedPayoff: BigNumber,
    expectedIncomeFeeValue: BigNumber,
    userOne: Signer,
    liquidityProvider: Signer
) {
    //given
    let localOpenTimestamp = ZERO;

    if (openTimestamp != ZERO) {
        localOpenTimestamp = openTimestamp;
    } else {
        localOpenTimestamp = testData.executionTimestamp;
    }

    let totalAmount = ZERO;

    if (testData.tokenDai && asset === testData.tokenDai.address) {
        totalAmount = TC_TOTAL_AMOUNT_10_000_18DEC;
    }

    if (testData.tokenUsdt && asset === testData.tokenUsdt.address) {
        totalAmount = USD_10_000_6DEC;
    }

    const params = {
        asset: asset,
        totalAmount: totalAmount,
        acceptableFixedInterestRate: acceptableFixedInterestRate,
        leverage: leverage,
        direction: direction,
        openTimestamp: localOpenTimestamp,
        from: openerUser,
    };

    if (providedLiquidityAmount != null) {
        //in test we expect that Liquidity Pool is loosing and from its pool Milton has to paid out to closer user
        if (
            testData.josephUsdt &&
            testData.tokenUsdt &&
            params.asset === testData.tokenUsdt.address
        ) {
            await testData.josephUsdt
                .connect(liquidityProvider)
                .itfProvideLiquidity(providedLiquidityAmount, params.openTimestamp);
        }
        if (
            testData.josephUsdc &&
            testData.tokenUsdc &&
            params.asset === testData.tokenUsdc.address
        ) {
            await testData.josephUsdc
                .connect(liquidityProvider)
                .itfProvideLiquidity(providedLiquidityAmount, params.openTimestamp);
        }
        if (testData.josephDai && testData.tokenDai && params.asset === testData.tokenDai.address) {
            await testData.josephDai
                .connect(liquidityProvider)
                .itfProvideLiquidity(providedLiquidityAmount, params.openTimestamp);
        }
    }

    await testData.iporOracle
        .connect(userOne)
        .itfUpdateIndex(params.asset, iporValueBeforeOpenSwap, params.openTimestamp);
    if (params.direction == 0) {
        await openSwapPayFixed(testData, params);
    } else if (params.direction == 1) {
        await openSwapReceiveFixed(testData, params);
    }

    await testData.iporOracle
        .connect(userOne)
        .itfUpdateIndex(params.asset, iporValueAfterOpenSwap, params.openTimestamp);

    let endTimestamp = params.openTimestamp.add(periodOfTimeElapsedInSeconds);

    let actualPayoff = ZERO;
    let actualIncomeFeeValue = null;

    //when
    if (testData.miltonUsdt && testData.tokenUsdt && params.asset === testData.tokenUsdt.address) {
        if (params.direction == 0) {
            actualPayoff = await testData.miltonUsdt
                .connect(params.from)
                .itfCalculateSwapPayFixedValue(endTimestamp, 1);
            await testData.miltonUsdt.connect(closerUser).itfCloseSwapPayFixed(1, endTimestamp);
        } else if (params.direction == 1) {
            actualPayoff = await testData.miltonUsdt
                .connect(params.from)
                .itfCalculateSwapReceiveFixedValue(endTimestamp, 1);

            await testData.miltonUsdt.connect(closerUser).itfCloseSwapReceiveFixed(1, endTimestamp);
        }
        actualIncomeFeeValue = await testData.miltonUsdt
            .connect(params.from)
            .itfCalculateIncomeFeeValue(actualPayoff);
    }

    if (testData.miltonUsdc && testData.tokenUsdc && params.asset === testData.tokenUsdc.address) {
        if (params.direction == 0) {
            actualPayoff = await testData.miltonUsdc
                .connect(params.from)
                .itfCalculateSwapPayFixedValue(endTimestamp, 1);
            await testData.miltonUsdc.connect(closerUser).itfCloseSwapPayFixed(1, endTimestamp);
        } else if (params.direction == 1) {
            actualPayoff = await testData.miltonUsdc
                .connect(params.from)
                .itfCalculateSwapReceiveFixedValue(endTimestamp, 1);

            await testData.miltonUsdc.connect(closerUser).itfCloseSwapReceiveFixed(1, endTimestamp);
        }
        actualIncomeFeeValue = await testData.miltonUsdc
            .connect(params.from)
            .itfCalculateIncomeFeeValue(actualPayoff);
    }

    if (testData.miltonDai && testData.tokenDai && params.asset === testData.tokenDai.address) {
        if (params.direction == 0) {
            actualPayoff = await testData.miltonDai
                .connect(params.from)
                .itfCalculateSwapPayFixedValue(endTimestamp, 1);

            await testData.miltonDai.connect(closerUser).itfCloseSwapPayFixed(1, endTimestamp);
        } else if (params.direction == 1) {
            actualPayoff = await testData.miltonDai
                .connect(params.from)
                .itfCalculateSwapReceiveFixedValue(endTimestamp, 1);

            await testData.miltonDai.connect(closerUser).itfCloseSwapReceiveFixed(1, endTimestamp);
        }
        actualIncomeFeeValue = await testData.miltonDai
            .connect(params.from)
            .itfCalculateIncomeFeeValue(actualPayoff);
    }

    expect(actualPayoff, "Incorrect position value").to.be.eq(expectedPayoff);
    expect(actualIncomeFeeValue, "Incorrect income fee value").to.be.eq(expectedIncomeFeeValue);

    //then
    await assertExpectedValues(
        testData,
        params.asset,
        params.direction,
        openerUser,
        closerUser,
        providedLiquidityAmount,
        expectedMiltonUnderlyingTokenBalance,
        expectedOpenerUserUnderlyingTokenBalanceAfterPayOut,
        expectedCloserUserUnderlyingTokenBalanceAfterPayOut,
        expectedLiquidityPoolTotalBalanceWad,
        expectedOpenedPositions,
        expectedDerivativesTotalBalanceWad,
        expectedTreasuryTotalBalanceWad
    );

    const soapParams = {
        asset: params.asset,
        calculateTimestamp: endTimestamp,
        expectedSoap: expectedSoap,
        from: openerUser,
    };
    await assertSoap(testData, soapParams);
};

export const executeCloseSwapsTestCase = async function (
    testData: TestData,
    asset: string,
    leverage: BigNumber,
    direction: number,
    openerUser: Signer,
    closerUser: Signer,
    iporValueBeforeOpenSwap: BigNumber,
    iporValueAfterOpenSwap: BigNumber,
    periodOfTimeElapsedInSeconds: BigNumber,
    providedLiquidityAmount: BigNumber,
    swapsToCreate: BigNumber,
    closeCallback: (x: any) => {},
    openTimestamp: BigNumber,
    pauseMilton: boolean,
    admin: Signer,
    userOne: Signer,
    liquidityProvider: Signer
) {
    //given
    let localOpenTimestamp = ZERO;
    if (openTimestamp != ZERO) {
        localOpenTimestamp = openTimestamp;
    } else {
        localOpenTimestamp = testData.executionTimestamp;
    }

    let totalAmount = ZERO;

    if (testData.tokenDai && asset === testData.tokenDai.address) {
        totalAmount = TC_TOTAL_AMOUNT_10_000_18DEC;
    }

    if (testData.tokenUsdt && asset === testData.tokenUsdt.address) {
        totalAmount = USD_10_000_6DEC;
    }

    let acceptableFixedInterestRate = null;

    if (direction == 1) {
        acceptableFixedInterestRate = N0__01_18DEC;
    } else {
        acceptableFixedInterestRate = BigNumber.from("9").mul(N0__1_18DEC);
    }

    const params = {
        asset: asset,
        totalAmount: totalAmount,
        acceptableFixedInterestRate: acceptableFixedInterestRate,
        leverage: leverage,
        direction: direction || 0,
        openTimestamp: localOpenTimestamp,
        from: openerUser,
    };

    if (providedLiquidityAmount != null) {
        //in test we expect that Liquidity Pool is loosing and from its pool Milton has to paid out to closer user
        if (
            testData.josephUsdt &&
            testData.tokenUsdt &&
            params.asset === testData.tokenUsdt.address
        ) {
            await testData.josephUsdt
                .connect(liquidityProvider)
                .itfProvideLiquidity(providedLiquidityAmount, params.openTimestamp);
        }
        if (
            testData.josephUsdc &&
            testData.tokenUsdc &&
            params.asset === testData.tokenUsdc.address
        ) {
            await testData.josephUsdc
                .connect(liquidityProvider)
                .itfProvideLiquidity(providedLiquidityAmount, params.openTimestamp);
        }
        if (testData.josephDai && testData.tokenDai && params.asset === testData.tokenDai.address) {
            await testData.josephDai
                .connect(liquidityProvider)
                .itfProvideLiquidity(providedLiquidityAmount, params.openTimestamp);
        }
    }

    await testData.iporOracle
        .connect(userOne)
        .itfUpdateIndex(params.asset, iporValueBeforeOpenSwap, params.openTimestamp);

    for (let i = 0; BigNumber.from(i).lt(swapsToCreate); i++) {
        if (params.direction === 0) {
            await openSwapPayFixed(testData, params);
        } else if (params.direction === 1) {
            await openSwapReceiveFixed(testData, params);
        }
    }

    await testData.iporOracle
        .connect(userOne)
        .itfUpdateIndex(params.asset, iporValueAfterOpenSwap, params.openTimestamp);

    //when
    if (testData.miltonUsdt && testData.tokenUsdt && params.asset === testData.tokenUsdt.address) {
        if (pauseMilton) {
            await testData.miltonUsdt.connect(admin).pause();
        }
        await closeCallback(testData.miltonUsdt.connect(closerUser));
    }

    if (testData.miltonUsdc && testData.tokenUsdc && params.asset === testData.tokenUsdc.address) {
        if (pauseMilton) {
            await testData.miltonUsdc.connect(admin).pause();
        }
        await closeCallback(testData.miltonUsdc.connect(closerUser));
    }

    if (testData.miltonDai && testData.tokenDai && params.asset === testData.tokenDai.address) {
        if (pauseMilton) {
            await testData.miltonDai.connect(admin).pause();
        }
        console.log("closerUser=", await closerUser.getAddress());
        await closeCallback(testData.miltonDai.connect(closerUser));
    }
};

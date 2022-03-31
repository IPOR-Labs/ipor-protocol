import hre from "hardhat";
import { Signer, BigNumber } from "ethers";
import {
    MiltonUsdcMockCase,
    MiltonUsdtMockCase,
    MiltonDaiMockCase,
    MockMiltonSpreadModel,
    MiltonUsdcCase,
    MiltonUsdtCase,
    MiltonDaiCase,
    getMockMiltonUsdcCase,
    getMockMiltonUsdtCase,
    getMockMiltonDaiCase,
} from "./MiltonUtils";
import {
    JosephUsdcMocks,
    JosephUsdtMocks,
    JosephDaiMocks,
    JosephUsdcMockCases,
    JosephUsdtMockCases,
    JosephDaiMockCases,
    getMockJosephUsdcCase,
    getMockJosephUsdtCase,
    getMockJosephDaiCase,
} from "./JosephUtils";
import { MockStanley, MockStanleyCase, getMockStanleyCase } from "./StanleyUtils";
import { prepareWarren } from "./WarrenUtils";
import {
    DaiMockedToken,
    UsdtMockedToken,
    UsdcMockedToken,
    IpToken,
    ItfWarren,
    MiltonStorage,
} from "../../types";
import {
    USD_10_000_6DEC,
    TOTAL_SUPPLY_6_DECIMALS,
    USER_SUPPLY_6_DECIMALS,
    N0__1_18DEC,
    TOTAL_SUPPLY_18_DECIMALS,
    USD_10_000_18DEC,
    USER_SUPPLY_10MLN_18DEC,
    LEVERAGE_18DEC,
    ZERO,
    N0__01_18DEC,
} from "./Constants";

const { ethers } = hre;

// ########################################################################################################
//                                           General
// ########################################################################################################

type AssetsType = "DAI" | "USDC" | "USDT";

export type TestData = {
    tokenDai?: DaiMockedToken;
    tokenUsdt?: UsdtMockedToken;
    tokenUsdc?: UsdcMockedToken;
    ipTokenUsdt?: IpToken;
    ipTokenUsdc?: IpToken;
    ipTokenDai?: IpToken;
    miltonUsdt?: MiltonUsdtMockCase;
    miltonStorageUsdt?: MiltonStorage;
    josephUsdt?: JosephUsdtMocks;
    miltonUsdc?: MiltonUsdcMockCase;
    miltonStorageUsdc?: MiltonStorage;
    josephUsdc?: JosephUsdcMocks;
    miltonDai?: MiltonDaiMockCase;
    miltonStorageDai?: MiltonStorage;
    josephDai?: JosephDaiMocks;
    stanleyUsdt?: MockStanley;
    stanleyUsdc?: MockStanley;
    stanleyDai?: MockStanley;
    warren: ItfWarren;
};

export const prepareTestData = async (
    accounts: Signer[],
    assets: AssetsType[],
    miltonSpreadModel: MockMiltonSpreadModel, //data
    miltonUsdcCase: MiltonUsdcCase,
    miltonUsdtCase: MiltonUsdtCase,
    miltonDaiCase: MiltonDaiCase,
    stanleyCaseNumber: MockStanleyCase,
    josephCaseUsdc: JosephUsdcMockCases,
    josephCaseUsdt: JosephUsdtMockCases,
    josephCaseDai: JosephDaiMockCases
): Promise<TestData> => {
    let tokenDai: DaiMockedToken | undefined;
    let tokenUsdt: UsdtMockedToken | undefined;
    let tokenUsdc: UsdcMockedToken | undefined;
    let ipTokenUsdt: IpToken | undefined;
    let ipTokenUsdc: IpToken | undefined;
    let ipTokenDai: IpToken | undefined;
    let miltonUsdt: MiltonUsdtMockCase | undefined;
    let miltonStorageUsdt: MiltonStorage | undefined;
    let josephUsdt: JosephUsdtMocks | undefined;
    let miltonUsdc: MiltonUsdcMockCase | undefined;
    let miltonStorageUsdc: MiltonStorage | undefined;
    let josephUsdc: JosephUsdcMocks | undefined;
    let miltonDai: MiltonDaiMockCase | undefined;
    let miltonStorageDai: MiltonStorage | undefined;
    let josephDai: JosephDaiMocks | undefined;
    let stanleyUsdt: MockStanley | undefined;
    let stanleyUsdc: MockStanley | undefined;
    let stanleyDai: MockStanley | undefined;

    const IpToken = await ethers.getContractFactory("IpToken");
    const UsdtMockedToken = await ethers.getContractFactory("UsdtMockedToken");
    const UsdcMockedToken = await ethers.getContractFactory("UsdcMockedToken");
    const DaiMockedToken = await ethers.getContractFactory("DaiMockedToken");
    const MiltonStorage = await ethers.getContractFactory("MiltonStorage");

    const warren = await prepareWarren(accounts);

    for (let k = 0; k < assets.length; k++) {
        if (assets[k] === "USDT") {
            tokenUsdt = (await UsdtMockedToken.deploy(
                TOTAL_SUPPLY_6_DECIMALS,
                6
            )) as UsdtMockedToken;
            await tokenUsdt.deployed();

            stanleyUsdt = await getMockStanleyCase(stanleyCaseNumber, tokenUsdt.address);
            ipTokenUsdt = (await IpToken.deploy("IP USDT", "ipUSDT", tokenUsdt.address)) as IpToken;
            miltonStorageUsdt = (await MiltonStorage.deploy()) as MiltonStorage;
            miltonStorageUsdt.initialize();

            miltonUsdt = await getMockMiltonUsdtCase(miltonUsdtCase);
            miltonUsdt.initialize(
                tokenUsdt.address,
                warren.address,
                miltonStorageUsdt.address,
                miltonSpreadModel.address,
                stanleyUsdt.address
            );

            josephUsdt = await getMockJosephUsdtCase(josephCaseUsdt);
            await josephUsdt.initialize(
                tokenUsdt.address,
                ipTokenUsdt.address,
                miltonUsdt.address,
                miltonStorageUsdt.address,
                stanleyUsdt.address
            );
            await miltonStorageUsdt.setJoseph(josephUsdt.address);
            await miltonStorageUsdt.setMilton(miltonUsdt.address);

            await ipTokenUsdt.setJoseph(josephUsdt.address);

            await miltonUsdt.setJoseph(josephUsdt.address);
            await miltonUsdt.setupMaxAllowanceForAsset(josephUsdt.address);
            await miltonUsdt.setupMaxAllowanceForAsset(stanleyUsdt.address);
            // await stanleyUsdt.authorizeMilton(miltonUsdt.address);
            await warren.addAsset(tokenUsdt.address);
        }
        if (assets[k] === "USDC") {
            tokenUsdc = (await UsdcMockedToken.deploy(
                TOTAL_SUPPLY_6_DECIMALS,
                6
            )) as UsdcMockedToken;
            await tokenUsdc.deployed();

            stanleyUsdc = await getMockStanleyCase(stanleyCaseNumber, tokenUsdc.address);

            ipTokenUsdc = (await IpToken.deploy("IP USDC", "ipUSDC", tokenUsdc.address)) as IpToken;

            miltonStorageUsdc = (await MiltonStorage.deploy()) as MiltonStorage;
            miltonStorageUsdc.initialize();

            miltonUsdc = await getMockMiltonUsdcCase(miltonUsdcCase);
            await miltonUsdc.deployed();
            miltonUsdc.initialize(
                tokenUsdc.address,
                warren.address,
                miltonStorageUsdc.address,
                miltonSpreadModel.address,
                stanleyUsdc.address
            );

            josephUsdc = await getMockJosephUsdcCase(josephCaseUsdc);
            await josephUsdc.deployed();
            await josephUsdc.initialize(
                tokenUsdc.address,
                ipTokenUsdc.address,
                miltonUsdc.address,
                miltonStorageUsdc.address,
                stanleyUsdc.address
            );

            await miltonStorageUsdc.setJoseph(josephUsdc.address);
            await miltonStorageUsdc.setMilton(miltonUsdc.address);

            await ipTokenUsdc.setJoseph(josephUsdc.address);

            await miltonUsdc.setJoseph(josephUsdc.address);
            await miltonUsdc.setupMaxAllowanceForAsset(josephUsdc.address);
            await miltonUsdc.setupMaxAllowanceForAsset(stanleyUsdc.address);
            // await stanleyUsdc.authorizeMilton(miltonUsdc.address);
            await warren.addAsset(tokenUsdc.address);
        }
        if (assets[k] === "DAI") {
            tokenDai = (await DaiMockedToken.deploy(
                TOTAL_SUPPLY_18_DECIMALS,
                18
            )) as DaiMockedToken;
            stanleyDai = await getMockStanleyCase(stanleyCaseNumber, tokenDai.address);

            ipTokenDai = (await IpToken.deploy("IP DAI", "ipDAI", tokenDai.address)) as IpToken;

            miltonStorageDai = (await MiltonStorage.deploy()) as MiltonStorage;
            miltonStorageDai.initialize();

            miltonDai = await getMockMiltonDaiCase(miltonDaiCase);
            miltonDai.initialize(
                tokenDai.address,
                warren.address,
                miltonStorageDai.address,
                miltonSpreadModel.address,
                stanleyDai.address
            );

            josephDai = await getMockJosephDaiCase(josephCaseDai);
            await josephDai.initialize(
                tokenDai.address,
                ipTokenDai.address,
                miltonDai.address,
                miltonStorageDai.address,
                stanleyDai.address
            );

            await miltonStorageDai.setJoseph(josephDai.address);
            await miltonStorageDai.setMilton(miltonDai.address);

            await ipTokenDai.setJoseph(josephDai.address);

            await miltonDai.setJoseph(josephDai.address);
            await miltonDai.setupMaxAllowanceForAsset(josephDai.address);
            await miltonDai.setupMaxAllowanceForAsset(stanleyDai.address);
            await warren.addAsset(tokenDai.address);
        }
    }

    return {
        tokenDai,
        tokenUsdt,
        tokenUsdc,
        ipTokenUsdt,
        ipTokenUsdc,
        ipTokenDai,
        warren,
        miltonUsdt,
        miltonStorageUsdt,
        josephUsdt,
        miltonUsdc,
        miltonStorageUsdc,
        josephUsdc,
        miltonDai,
        miltonStorageDai,
        josephDai,
        stanleyUsdt,
        stanleyUsdc,
        stanleyDai,
    };
};

export const prepareApproveForUsers = async (
    users: Signer[],
    asset: AssetsType,
    testData: TestData
) => {
    for (let i = 0; i < users.length; i++) {
        if (asset === "USDT") {
            await testData?.tokenUsdt
                ?.connect(users[i])
                ?.approve(testData?.josephUsdt?.address || "", TOTAL_SUPPLY_6_DECIMALS);
            await testData?.tokenUsdt
                ?.connect(users[i])
                ?.approve(testData?.miltonUsdt?.address || "", TOTAL_SUPPLY_6_DECIMALS);
        }

        if (asset === "USDC") {
            await testData?.tokenUsdc
                ?.connect(users[i])
                ?.approve(testData?.josephUsdc?.address || "", TOTAL_SUPPLY_6_DECIMALS);
            await testData?.tokenUsdc
                ?.connect(users[i])
                ?.approve(testData?.miltonUsdc?.address || "", TOTAL_SUPPLY_6_DECIMALS);
        }

        if (asset === "DAI") {
            await testData?.tokenDai
                ?.connect(users[i])
                ?.approve(testData?.josephDai?.address || "", TOTAL_SUPPLY_18_DECIMALS);
            await testData?.tokenDai
                ?.connect(users[i])
                ?.approve(testData?.miltonDai?.address || "", TOTAL_SUPPLY_18_DECIMALS);
        }
    }
};

export const setupTokenDaiInitialValuesForUsers = async (users: Signer[], testData: TestData) => {
    for (let i = 0; i < users.length; i++) {
        await testData?.tokenDai?.setupInitialAmount(
            await users[i].getAddress(),
            USER_SUPPLY_10MLN_18DEC
        );
    }
};

export const prepareTestDataDaiCase000 = async (
    accounts: Signer[],
    miltonSpreadModel: MockMiltonSpreadModel //data
): Promise<TestData> => {
    return await prepareTestData(
        accounts,
        ["DAI"],
        miltonSpreadModel,
        MiltonUsdcCase.CASE0,
        MiltonUsdtCase.CASE0,
        MiltonDaiCase.CASE0,
        MockStanleyCase.CASE0,
        JosephUsdcMockCases.CASE0,
        JosephUsdtMockCases.CASE0,
        JosephDaiMockCases.CASE0
    );
};

export const prepareTestDataDaiCase001 = async (
    accounts: Signer[],
    miltonSpreadModel: MockMiltonSpreadModel //data
): Promise<TestData> => {
    return await prepareTestData(
        accounts,
        ["DAI"],
        miltonSpreadModel,
        MiltonUsdcCase.CASE0,
        MiltonUsdtCase.CASE0,
        MiltonDaiCase.CASE0,
        MockStanleyCase.CASE0,
        JosephUsdcMockCases.CASE1,
        JosephUsdtMockCases.CASE1,
        JosephDaiMockCases.CASE1
    );
};

export const prepareTestDataUsdtCase000 = async (
    accounts: Signer[],
    miltonSpreadModel: MockMiltonSpreadModel
) => {
    return await prepareTestData(
        accounts,
        ["USDT"],
        miltonSpreadModel,
        MiltonUsdcCase.CASE0,
        MiltonUsdtCase.CASE0,
        MiltonDaiCase.CASE0,
        MockStanleyCase.CASE0,
        JosephUsdcMockCases.CASE0,
        JosephUsdtMockCases.CASE0,
        JosephDaiMockCases.CASE0
    );
};

export const prepareComplexTestDataDaiCase000 = async (
    accounts: Signer[],
    miltonSpreadModel: MockMiltonSpreadModel
) => {
    const testData = (await prepareTestDataDaiCase000(accounts, miltonSpreadModel)) as TestData;
    await prepareApproveForUsers(accounts, "DAI", testData);
    await setupTokenDaiInitialValuesForUsers(accounts, testData);
    return testData;
};

export const prepareComplexTestDataDaiCase400 = async (
    accounts: Signer[],
    miltonSpreadModel: MockMiltonSpreadModel
) => {
    const testData = await prepareTestData(
        accounts,
        ["DAI"],
        miltonSpreadModel,
        MiltonUsdcCase.CASE4,
        MiltonUsdtCase.CASE4,
        MiltonDaiCase.CASE4,
        MockStanleyCase.CASE0,
        JosephUsdcMockCases.CASE0,
        JosephUsdtMockCases.CASE0,
        JosephDaiMockCases.CASE0
    );
    await prepareApproveForUsers(accounts, "DAI", testData);
    await setupTokenDaiInitialValuesForUsers(accounts, testData);
    return testData;
};

export const setupIpTokenInitialValues = async (
    asset: IpToken,
    liquidityProvider: Signer,
    initialAmount: BigNumber
) => {
    if (initialAmount.gt(ZERO)) {
        await asset
            .connect(liquidityProvider)
            .mint(await liquidityProvider.getAddress(), initialAmount);
    }
};

export const getStandardDerivativeParamsDAI = (user: Signer, tokenDai: DaiMockedToken) => {
    return {
        asset: tokenDai.address,
        totalAmount: USD_10_000_18DEC,
        maxAcceptableFixedInterestRate: BigNumber.from("9").mul(N0__1_18DEC),
        leverage: LEVERAGE_18DEC,
        direction: 0,
        openTimestamp: BigNumber.from(Math.floor(Date.now() / 1000)),
        from: user,
    };
};

export const getStandardDerivativeParamsUSDT = (user: Signer, tokenUsdt: UsdtMockedToken) => {
    return {
        asset: tokenUsdt.address,
        totalAmount: USD_10_000_6DEC,
        maxAcceptableFixedInterestRate: BigNumber.from("9").mul(N0__1_18DEC),
        leverage: LEVERAGE_18DEC,
        direction: 0,
        openTimestamp: Math.floor(Date.now() / 1000),
        from: user,
    };
};

export const setupTokenUsdtInitialValuesForUsers = async (
    users: Signer[],
    tokenUsdt: UsdtMockedToken
) => {
    for (let i = 0; i < users.length; i++) {
        await tokenUsdt.setupInitialAmount(await users[i].getAddress(), USER_SUPPLY_6_DECIMALS);
    }
};

export const getPayFixedDerivativeParamsDAICase1 = (user: Signer, tokenDai: DaiMockedToken) => {
    return {
        asset: tokenDai.address,
        totalAmount: USD_10_000_18DEC,
        maxAcceptableFixedInterestRate: BigNumber.from("6").mul(N0__01_18DEC),
        leverage: LEVERAGE_18DEC,
        direction: 0,
        openTimestamp: BigNumber.from(Math.floor(Date.now() / 1000)),
        from: user,
    };
};

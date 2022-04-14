import hre from "hardhat";
import chai from "chai";
import { Signer, BigNumber } from "ethers";
import {
    ZERO,
    N0__001_18DEC,
    N0__1_18DEC,
    USD_100_18DEC,
    N0__01_18DEC,
    USD_10_000_000_18DEC,
    PERCENTAGE_3_18DEC,
    N1__0_18DEC,
} from "../utils/Constants";
import {
    MockMiltonSpreadModel,
    MiltonSpreadModels,
    prepareMockMiltonSpreadModel,
    MiltonUsdcCase,
    MiltonUsdtCase,
    MiltonDaiCase,
    prepareMiltonSpreadCase6,
    prepareMiltonSpreadCase7,
    prepareMiltonSpreadCase8,
    prepareMiltonSpreadCase9,
    prepareMiltonSpreadCase10,
    getPayFixedDerivativeParamsUSDTCase1,
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
    let miltonSpreadModel: MockMiltonSpreadModel;
    let admin: Signer,
        userOne: Signer,
        userTwo: Signer,
        userThree: Signer,
        liquidityProvider: Signer;

    before(async () => {
        [admin, userOne, userTwo, userThree, liquidityProvider] = await hre.ethers.getSigners();
        miltonSpreadModel = await prepareMockMiltonSpreadModel(MiltonSpreadModels.BASE);
    });

    it("should transfer ownership - simple case 1", async () => {
        //given
        const MockCase1MiltonSpreadModel = await hre.ethers.getContractFactory(
            "MockCase1MiltonSpreadModel"
        );
        const miltonSpread = await MockCase1MiltonSpreadModel.deploy();
        await miltonSpread.deployed();
        const expectedNewOwner = userTwo;

        //when
        await miltonSpread.connect(admin).transferOwnership(await expectedNewOwner.getAddress());

        await miltonSpread.connect(expectedNewOwner).confirmTransferOwnership();

        //then
        const actualNewOwner = await miltonSpread.connect(userOne).owner();
        expect(await expectedNewOwner.getAddress()).to.be.eql(actualNewOwner);
    });

    it("should NOT transfer ownership - sender not current owner", async () => {
        //given
        const MockCase1MiltonSpreadModel = await hre.ethers.getContractFactory(
            "MockCase1MiltonSpreadModel"
        );
        const miltonSpread = await MockCase1MiltonSpreadModel.deploy();
        await miltonSpread.deployed();
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
        const MockCase1MiltonSpreadModel = await hre.ethers.getContractFactory(
            "MockCase1MiltonSpreadModel"
        );
        const miltonSpread = await MockCase1MiltonSpreadModel.deploy();
        await miltonSpread.deployed();
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
        const MockCase1MiltonSpreadModel = await hre.ethers.getContractFactory(
            "MockCase1MiltonSpreadModel"
        );
        const miltonSpread = await MockCase1MiltonSpreadModel.deploy();
        await miltonSpread.deployed();
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
        const MockCase1MiltonSpreadModel = await hre.ethers.getContractFactory(
            "MockCase1MiltonSpreadModel"
        );
        const miltonSpread = await MockCase1MiltonSpreadModel.deploy();
        await miltonSpread.deployed();
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
        const MockCase1MiltonSpreadModel = await hre.ethers.getContractFactory(
            "MockCase1MiltonSpreadModel"
        );
        const miltonSpread = await MockCase1MiltonSpreadModel.deploy();
        await miltonSpread.deployed();

        const expectedNewOwner = userTwo;

        await miltonSpread.connect(admin).transferOwnership(await expectedNewOwner.getAddress());

        //when
        await miltonSpread.connect(admin).transferOwnership(await expectedNewOwner.getAddress());

        //then
        const actualNewOwner = await miltonSpread.connect(userOne).owner();
        expect(await admin.getAddress()).to.be.eql(actualNewOwner);
    });

    it.skip("should calculate Quote Value Pay Fixed Value - Spread Premium < Spread Premium Max Value, Ref Leg Case 1", async () => {
        //given
        const miltonSpread = await prepareMiltonSpreadCase10();

        const soap = BigNumber.from("500000000000000000000"); //.mul(N1__0_18DEC);
        const swapCollateral = BigNumber.from("10000000000000000000000"); //.mul(N1__0_18DEC);
        const openingFee = BigNumber.from("20000000000000000000");
        const accruedIpor = {
            indexValue: BigNumber.from("30000000000000000"), //.mul(N0__01_18DEC),
            ibtPrice: ZERO,
            exponentialMovingAverage: BigNumber.from("40000000000000000"), //.mul(N0__01_18DEC),
            exponentialWeightedMovingVariance: BigNumber.from("35000000000000000"), //.mul(N0__000_18DEC),
        };
        const accruedBalance = {
            totalCollateralPayFixed: BigNumber.from("1000000000000000000000").add(swapCollateral),
            totalCollateralReceiveFixed: BigNumber.from("13000000000000000000000"),
            openingFee: openingFee,
            liquidationDeposit: ZERO,
            vault: ZERO,
            iporPublicationFee: ZERO,
            liquidityPool: BigNumber.from("15000000000000000000000").add(openingFee),
            treasury: ZERO,
        };

        const expectedQuoteValue = BigNumber.from("121375710450611396");

        //when
        const actualQuotedValue = await miltonSpread
            .connect(userOne)
            .calculateQuotePayFixed(soap, accruedIpor, accruedBalance);
        //then
        expect(actualQuotedValue).to.be.eq(expectedQuoteValue);
    });

    it.skip("should calculate Quote Value Pay Fixed Value - Spread Premium < Spread Premium Max Value, Ref Leg Case 2", async () => {
        //given
        const miltonSpread = await prepareMiltonSpreadCase10();

        const soap = BigNumber.from("500000000000000000000"); //.mul(N1__0_18DEC);
        const swapCollateral = BigNumber.from("10000000000000000000000"); //.mul(N1__0_18DEC);
        const openingFee = BigNumber.from("20000000000000000000");
        const accruedIpor = {
            indexValue: BigNumber.from("55000000000000000"),
            ibtPrice: ZERO,
            exponentialMovingAverage: BigNumber.from("4").mul(N0__01_18DEC),
            exponentialWeightedMovingVariance: BigNumber.from("35").mul(N0__001_18DEC),
        };
        const accruedBalance = {
            totalCollateralPayFixed: BigNumber.from("1000").mul(N1__0_18DEC).add(swapCollateral),
            totalCollateralReceiveFixed: BigNumber.from("13000").mul(N1__0_18DEC),
            openingFee: openingFee,
            liquidationDeposit: ZERO,
            vault: ZERO,
            iporPublicationFee: ZERO,
            liquidityPool: BigNumber.from("15000").mul(N1__0_18DEC).add(openingFee),
            treasury: ZERO,
        };

        const expectedQuoteValue = BigNumber.from("122234296309197255");

        //when
        let actualQuotedValue = await miltonSpread
            .connect(userOne)
            .calculateQuotePayFixed(soap, accruedIpor, accruedBalance);
        //then
        expect(actualQuotedValue).to.be.eq(expectedQuoteValue);
    });

    it.skip("should calculate Spread Premiums Pay Fixed Value - Kf part + KOmega part + KVol part + KHist < Spread Max Value", async () => {
        //given
        const miltonSpread = await prepareMiltonSpreadCase10();

        const liquidityPoolBalance = BigNumber.from("15000").mul(N1__0_18DEC);
        const swapCollateral = BigNumber.from("10000").mul(N1__0_18DEC);
        const swapOpeningFee = BigNumber.from("20").mul(N1__0_18DEC);

        const totalCollateralPayFixedBalance = BigNumber.from("1000").mul(N1__0_18DEC);
        const totalCollateralReceiveFixedBalance = BigNumber.from("13000").mul(N1__0_18DEC);

        const soap = BigNumber.from("500").mul(N1__0_18DEC);

        const accruedIpor = {
            indexValue: BigNumber.from("3").mul(N0__01_18DEC),
            ibtPrice: N1__0_18DEC,
            exponentialMovingAverage: BigNumber.from("4").mul(N0__01_18DEC),
            exponentialWeightedMovingVariance: BigNumber.from("35").mul(N0__001_18DEC),
        };

        const expectedSpreadValue = BigNumber.from("81375710450611396");

        //when
        let actualSpreadValue = BigNumber.from(
            await miltonSpread
                .connect(userOne)
                .testCalculateSpreadPremiumsPayFixed(
                    soap,
                    accruedIpor,
                    liquidityPoolBalance.add(swapOpeningFee),
                    totalCollateralPayFixedBalance.add(swapCollateral),
                    totalCollateralReceiveFixedBalance
                )
        );

        //then
        expect(
            actualSpreadValue,
            `Incorrect Pay Fixed Spread Value, actual: ${actualSpreadValue}, expected: ${expectedSpreadValue}`
        ).to.be.eq(expectedSpreadValue);
    });

    it.skip("should calculate Spread Premiums Pay Fixed = Spread Max Value - Kf denominator != 0, Komega denominator != 0, KVol denominator != 0, KHist denominator != 0", async () => {
        //given
        const miltonSpread = await prepareMiltonSpreadCase7();

        const spreadPremiumsMaxValue = BigNumber.from("3").mul(N0__1_18DEC);

        const liquidityPoolBalance = BigNumber.from("15000").mul(N1__0_18DEC);
        const swapCollateral = BigNumber.from("10000").mul(N1__0_18DEC);
        const swapOpeningFee = BigNumber.from("20").mul(N1__0_18DEC);

        const totalCollateralPayFixedBalance = BigNumber.from("1000").mul(N1__0_18DEC);
        const totalCollateralReceiveFixedBalance = BigNumber.from("13000").mul(N1__0_18DEC);

        const soap = BigNumber.from("500").mul(N1__0_18DEC);

        const accruedIpor = {
            indexValue: BigNumber.from("3").mul(N0__01_18DEC),
            ibtPrice: N1__0_18DEC,
            exponentialMovingAverage: BigNumber.from("4").mul(N0__01_18DEC),
            exponentialWeightedMovingVariance: BigNumber.from("35").mul(N0__001_18DEC),
        };

        const expectedSpreadValue = spreadPremiumsMaxValue;

        //when
        let actualSpreadValue = BigNumber.from(
            await miltonSpread
                .connect(userOne)
                .testCalculateSpreadPremiumsPayFixed(
                    soap,
                    accruedIpor,
                    liquidityPoolBalance.add(swapOpeningFee),
                    totalCollateralPayFixedBalance.add(swapCollateral),
                    totalCollateralReceiveFixedBalance
                )
        );

        //then
        expect(
            actualSpreadValue,
            `Incorrect Pay Fixed Spread Value, actual: ${actualSpreadValue}, expected: ${expectedSpreadValue}`
        ).to.be.eq(expectedSpreadValue);
    });

    it.skip("should calculate Spread Premiums Pay Fixed = Spread Max Value - Kf denominator = 0, Komega denominator != 0, KVol denominator != 0, KHist denominator != 0", async () => {
        //given
        const miltonSpread = await prepareMiltonSpreadCase7();

        const spreadPremiumsMaxValue = BigNumber.from("3").mul(N0__1_18DEC);

        const liquidityPoolBalance = BigNumber.from("15000").mul(N1__0_18DEC);
        const swapCollateral = BigNumber.from("10000").mul(N1__0_18DEC);
        const swapOpeningFee = BigNumber.from("20").mul(N1__0_18DEC);

        const totalCollateralPayFixedBalance = BigNumber.from("1000").mul(N1__0_18DEC);
        const totalCollateralReceiveFixedBalance = BigNumber.from("13000").mul(N1__0_18DEC);

        const soap = BigNumber.from("500").mul(N1__0_18DEC);

        const accruedIpor = {
            indexValue: BigNumber.from("3").mul(N0__01_18DEC),
            ibtPrice: N1__0_18DEC,
            exponentialMovingAverage: BigNumber.from("4").mul(N0__01_18DEC),
            exponentialWeightedMovingVariance: BigNumber.from("35").mul(N0__001_18DEC),
        };

        const expectedSpreadValue = spreadPremiumsMaxValue;

        //when
        let actualSpreadValue = BigNumber.from(
            await miltonSpread
                .connect(userOne)
                .testCalculateSpreadPremiumsPayFixed(
                    soap,
                    accruedIpor,
                    liquidityPoolBalance.add(swapOpeningFee),
                    totalCollateralPayFixedBalance.add(swapCollateral),
                    totalCollateralReceiveFixedBalance
                )
        );

        //then
        expect(
            actualSpreadValue,
            `Incorrect Pay Fixed Spread Value, actual: ${actualSpreadValue}, expected: ${expectedSpreadValue}`
        ).to.be.eq(expectedSpreadValue);
    });

    it.skip("should calculate Spread Premiums Pay Fixed = Spread Max Value - Kf denominator = 0, Komega denominator = 0, KVol denominator != 0, KHist denominator != 0", async () => {
        //given
        const miltonSpread = await prepareMiltonSpreadCase8();

        const spreadPremiumsMaxValue = BigNumber.from("3").mul(N0__1_18DEC);

        const liquidityPoolBalance = BigNumber.from("15000").mul(N1__0_18DEC);
        const swapCollateral = BigNumber.from("10000").mul(N1__0_18DEC);
        const swapOpeningFee = BigNumber.from("20").mul(N1__0_18DEC);

        const totalCollateralPayFixedBalance = BigNumber.from("1000").mul(N1__0_18DEC);
        const totalCollateralReceiveFixedBalance = BigNumber.from("13000").mul(N1__0_18DEC);

        const soap = totalCollateralPayFixedBalance;

        const accruedIpor = {
            indexValue: BigNumber.from("3").mul(N0__01_18DEC),
            ibtPrice: N1__0_18DEC,
            exponentialMovingAverage: BigNumber.from("4").mul(N0__01_18DEC),
            exponentialWeightedMovingVariance: BigNumber.from("35").mul(N0__001_18DEC),
        };

        const expectedSpreadValue = spreadPremiumsMaxValue;

        //when
        let actualSpreadValue = BigNumber.from(
            await miltonSpread
                .connect(userOne)
                .testCalculateSpreadPremiumsPayFixed(
                    soap,
                    accruedIpor,
                    liquidityPoolBalance.add(swapOpeningFee),
                    totalCollateralPayFixedBalance.add(swapCollateral),
                    totalCollateralReceiveFixedBalance
                )
        );

        //then
        expect(
            actualSpreadValue,
            `Incorrect Pay Fixed Spread Value, actual: ${actualSpreadValue}, expected: ${expectedSpreadValue}`
        ).to.be.eq(expectedSpreadValue);
    });

    it.skip("should calculate Spread Premiums Pay Fixed = Spread Max Value - Kf denominator = 0, Komega denominator = 0, KVol denominator = 0, KHist denominator != 0", async () => {
        //given
        const miltonSpread = await prepareMiltonSpreadCase8();

        const spreadPremiumsMaxValue = BigNumber.from("3").mul(N0__1_18DEC);

        const liquidityPoolBalance = BigNumber.from("15000").mul(N1__0_18DEC);
        const swapCollateral = BigNumber.from("10000").mul(N1__0_18DEC);
        const swapOpeningFee = BigNumber.from("20").mul(N1__0_18DEC);

        const totalCollateralPayFixedBalance = BigNumber.from("1000").mul(N1__0_18DEC);
        const totalCollateralReceiveFixedBalance = BigNumber.from("13000").mul(N1__0_18DEC);

        const soap = totalCollateralPayFixedBalance;

        const accruedIpor = {
            indexValue: BigNumber.from("3").mul(N0__01_18DEC),
            ibtPrice: N1__0_18DEC,
            exponentialMovingAverage: BigNumber.from("4").mul(N0__01_18DEC),
            exponentialWeightedMovingVariance: N1__0_18DEC,
        };

        const expectedSpreadValue = spreadPremiumsMaxValue;

        //when
        let actualSpreadValue = BigNumber.from(
            await miltonSpread
                .connect(userOne)
                .testCalculateSpreadPremiumsPayFixed(
                    soap,
                    accruedIpor,
                    liquidityPoolBalance.add(swapOpeningFee),
                    totalCollateralPayFixedBalance.add(swapCollateral),
                    totalCollateralReceiveFixedBalance
                )
        );

        //then
        expect(
            actualSpreadValue,
            `Incorrect Pay Fixed Spread Value, actual: ${actualSpreadValue}, expected: ${expectedSpreadValue}`
        ).to.be.eq(expectedSpreadValue);
    });

    it.skip("should calculate Spread Premiums Pay Fixed = Spread Max Value - Kf denominator = 0, Komega denominator = 0, KVol denominator = 0, KHist denominator = 0", async () => {
        //given
        const miltonSpread = await prepareMiltonSpreadCase8();

        const spreadPremiumsMaxValue = BigNumber.from("3").mul(N0__1_18DEC);

        const liquidityPoolBalance = BigNumber.from("15000").mul(N1__0_18DEC);
        const swapCollateral = BigNumber.from("10000").mul(N1__0_18DEC);
        const swapOpeningFee = BigNumber.from("20").mul(N1__0_18DEC);

        const totalCollateralPayFixedBalance = BigNumber.from("1000").mul(N1__0_18DEC);
        const totalCollateralReceiveFixedBalance = BigNumber.from("13000").mul(N1__0_18DEC);

        const soap = totalCollateralPayFixedBalance;

        const iporIndexValue = BigNumber.from("3").mul(N0__01_18DEC);

        const accruedIpor = {
            indexValue: iporIndexValue,
            ibtPrice: N1__0_18DEC,
            exponentialMovingAverage: N1__0_18DEC.add(iporIndexValue),
            exponentialWeightedMovingVariance: N1__0_18DEC,
        };

        const expectedSpreadValue = spreadPremiumsMaxValue;

        //when
        let actualSpreadValue = BigNumber.from(
            await miltonSpread
                .connect(userOne)
                .testCalculateSpreadPremiumsPayFixed(
                    soap,
                    accruedIpor,
                    liquidityPoolBalance.add(swapOpeningFee),
                    totalCollateralPayFixedBalance.add(swapCollateral),
                    totalCollateralReceiveFixedBalance
                )
        );

        //then
        expect(
            actualSpreadValue,
            `Incorrect Pay Fixed Spread Value, actual: ${actualSpreadValue}, expected: ${expectedSpreadValue}`
        ).to.be.eq(expectedSpreadValue);
    });

    it.skip("should calculate Spread Premiums Pay Fixed = Spread Max Value - Kf denominator != 0, Komega denominator = 0, KVol denominator = 0, KHist denominator = 0", async () => {
        //given
        const miltonSpread = await prepareMiltonSpreadCase7();
        const spreadPremiumsMaxValue = BigNumber.from("3").mul(N0__1_18DEC);

        const liquidityPoolBalance = BigNumber.from("15000").mul(N1__0_18DEC);
        const swapCollateral = BigNumber.from("10000").mul(N1__0_18DEC);
        const swapOpeningFee = BigNumber.from("20").mul(N1__0_18DEC);

        const totalCollateralPayFixedBalance = BigNumber.from("1000").mul(N1__0_18DEC);
        const totalCollateralReceiveFixedBalance = BigNumber.from("13000").mul(N1__0_18DEC);

        const soap = totalCollateralPayFixedBalance;

        const iporIndexValue = BigNumber.from("3").mul(N0__01_18DEC);

        const accruedIpor = {
            indexValue: iporIndexValue,
            ibtPrice: N1__0_18DEC,
            exponentialMovingAverage: N1__0_18DEC.add(iporIndexValue),
            exponentialWeightedMovingVariance: N1__0_18DEC,
        };

        const expectedSpreadValue = spreadPremiumsMaxValue;

        //when
        let actualSpreadValue = BigNumber.from(
            await miltonSpread
                .connect(userOne)
                .testCalculateSpreadPremiumsPayFixed(
                    soap,
                    accruedIpor,
                    liquidityPoolBalance.add(swapOpeningFee),
                    totalCollateralPayFixedBalance.add(swapCollateral),
                    totalCollateralReceiveFixedBalance
                )
        );

        //then
        expect(
            actualSpreadValue,
            `Incorrect Pay Fixed Spread Value, actual: ${actualSpreadValue}, expected: ${expectedSpreadValue}`
        ).to.be.eq(expectedSpreadValue);
    });

    it.skip("should calculate Spread Premiums Pay Fixed = Spread Max Value - Kf denominator != 0, Komega denominator != 0, KVol denominator = 0, KHist denominator = 0", async () => {
        //given
        const miltonSpread = await prepareMiltonSpreadCase6();
        const spreadPremiumsMaxValue = BigNumber.from("3").mul(N0__1_18DEC);

        const liquidityPoolBalance = BigNumber.from("15000").mul(N1__0_18DEC);
        const swapCollateral = BigNumber.from("10000").mul(N1__0_18DEC);
        const swapOpeningFee = BigNumber.from("20").mul(N1__0_18DEC);

        const totalCollateralPayFixedBalance = BigNumber.from("1000").mul(N1__0_18DEC);
        const totalCollateralReceiveFixedBalance = BigNumber.from("13000").mul(N1__0_18DEC);

        const soap = BigNumber.from("500").mul(N1__0_18DEC);

        const iporIndexValue = BigNumber.from("3").mul(N0__01_18DEC);

        const accruedIpor = {
            indexValue: iporIndexValue,
            ibtPrice: N1__0_18DEC,
            exponentialMovingAverage: N1__0_18DEC.add(iporIndexValue),
            exponentialWeightedMovingVariance: N1__0_18DEC,
        };

        const expectedSpreadValue = spreadPremiumsMaxValue;

        //when
        let actualSpreadValue = BigNumber.from(
            await miltonSpread
                .connect(userOne)
                .testCalculateSpreadPremiumsPayFixed(
                    soap,
                    accruedIpor,
                    liquidityPoolBalance.add(swapOpeningFee),
                    totalCollateralPayFixedBalance.add(swapCollateral),
                    totalCollateralReceiveFixedBalance
                )
        );

        //then
        expect(
            actualSpreadValue,
            `Incorrect Pay Fixed Spread Value, actual: ${actualSpreadValue}, expected: ${expectedSpreadValue}`
        ).to.be.eq(expectedSpreadValue);
    });

    it.skip("should calculate Spread Premiums Pay Fixed = Spread Max Value - Kf denominator != 0, Komega denominator != 0, KVol denominator != 0, KHist denominator = 0", async () => {
        //given
        const miltonSpread = await prepareMiltonSpreadCase6();

        const spreadPremiumsMaxValue = BigNumber.from("3").mul(N0__1_18DEC);
        const liquidityPoolBalance = BigNumber.from("15000").mul(N1__0_18DEC);
        const swapCollateral = BigNumber.from("10000").mul(N1__0_18DEC);
        const swapOpeningFee = BigNumber.from("20").mul(N1__0_18DEC);

        const totalCollateralPayFixedBalance = BigNumber.from("1000").mul(N1__0_18DEC);
        const totalCollateralReceiveFixedBalance = BigNumber.from("13000").mul(N1__0_18DEC);

        const soap = BigNumber.from("500").mul(N1__0_18DEC);

        const iporIndexValue = BigNumber.from("3").mul(N0__01_18DEC);

        const accruedIpor = {
            indexValue: iporIndexValue,
            ibtPrice: N1__0_18DEC,
            exponentialMovingAverage: N1__0_18DEC.add(iporIndexValue),
            exponentialWeightedMovingVariance: BigNumber.from("35").mul(N0__001_18DEC),
        };

        const expectedSpreadValue = spreadPremiumsMaxValue;

        //when
        let actualSpreadValue = BigNumber.from(
            await miltonSpread
                .connect(userOne)
                .testCalculateSpreadPremiumsPayFixed(
                    soap,
                    accruedIpor,
                    liquidityPoolBalance.add(swapOpeningFee),
                    totalCollateralPayFixedBalance.add(swapCollateral),
                    totalCollateralReceiveFixedBalance
                )
        );

        //then
        expect(
            actualSpreadValue,
            `Incorrect Pay Fixed Spread Value, actual: ${actualSpreadValue}, expected: ${expectedSpreadValue}`
        ).to.be.eq(expectedSpreadValue);
    });

    it.skip("should calculate Spread Premiums Pay Fixed = Spread Max Value - Kf part very high, Komega part normal, KVol part normal, KHist part normal", async () => {
        //given

        const miltonSpread = await prepareMiltonSpreadCase9();

        const spreadPremiumsMaxValue = BigNumber.from("3").mul(N0__1_18DEC);

        const liquidityPoolBalance = BigNumber.from("100").mul(N1__0_18DEC);
        const swapCollateral = BigNumber.from("1").mul(N0__001_18DEC);
        const swapOpeningFee = ZERO;

        const totalCollateralPayFixedBalance = BigNumber.from("99990000000000000000");
        const totalCollateralReceiveFixedBalance = BigNumber.from("13000").mul(N1__0_18DEC);

        const soap = BigNumber.from("100");

        const accruedIpor = {
            indexValue: BigNumber.from("3").mul(N0__01_18DEC),
            ibtPrice: N1__0_18DEC,
            exponentialMovingAverage: BigNumber.from("4").mul(N0__01_18DEC),
            exponentialWeightedMovingVariance: BigNumber.from("35").mul(N0__001_18DEC),
        };

        const expectedSpreadValue = spreadPremiumsMaxValue;

        //when
        let actualSpreadValue = BigNumber.from(
            await miltonSpread
                .connect(userOne)
                .testCalculateSpreadPremiumsPayFixed(
                    soap,
                    accruedIpor,
                    liquidityPoolBalance.add(swapOpeningFee),
                    totalCollateralPayFixedBalance.add(swapCollateral),
                    totalCollateralReceiveFixedBalance
                )
        );

        //then
        expect(
            actualSpreadValue,
            `Incorrect Pay Fixed Spread Value, actual: ${actualSpreadValue}, expected: ${expectedSpreadValue}`
        ).to.be.eq(expectedSpreadValue);
    });

    it.skip("should calculate Spread Premiums Pay Fixed = Spread Max Value - Kf part normal, KOmega part very high, KVol part normal, KHist part normal", async () => {
        //given
        const miltonSpread = await prepareMiltonSpreadCase6();

        const spreadPremiumsMaxValue = BigNumber.from("3").mul(N0__1_18DEC);
        const liquidityPoolBalance = BigNumber.from("15000").mul(N1__0_18DEC);
        const swapCollateral = USD_100_18DEC;
        const swapOpeningFee = BigNumber.from("20").mul(N1__0_18DEC);

        const totalCollateralPayFixedBalance = BigNumber.from("1000").mul(N1__0_18DEC);
        const totalCollateralReceiveFixedBalance = BigNumber.from("13000").mul(N1__0_18DEC);

        const soap = BigNumber.from("999999999999999990000");

        const accruedIpor = {
            indexValue: BigNumber.from("3").mul(N0__01_18DEC),
            ibtPrice: N1__0_18DEC,
            exponentialMovingAverage: BigNumber.from("4").mul(N0__01_18DEC),
            exponentialWeightedMovingVariance: BigNumber.from("35").mul(N0__001_18DEC),
        };

        const expectedSpreadValue = spreadPremiumsMaxValue;

        //when
        let actualSpreadValue = BigNumber.from(
            await miltonSpread
                .connect(userOne)
                .testCalculateSpreadPremiumsPayFixed(
                    soap,
                    accruedIpor,
                    liquidityPoolBalance.add(swapOpeningFee),
                    totalCollateralPayFixedBalance.add(swapCollateral),
                    totalCollateralReceiveFixedBalance
                )
        );

        //then
        expect(
            actualSpreadValue,
            `Incorrect Pay Fixed Spread Value, actual: ${actualSpreadValue}, expected: ${expectedSpreadValue}`
        ).to.be.eq(expectedSpreadValue);
    });

    it.skip("should calculate Spread Premiums Pay Fixed = Spread Max Value - Kf part normal, KOmega part normal, KVol part very high, KHist part normal", async () => {
        //given
        const miltonSpread = await prepareMiltonSpreadCase6();
        const spreadPremiumsMaxValue = BigNumber.from("3").mul(N0__1_18DEC);

        const liquidityPoolBalance = BigNumber.from("15000").mul(N1__0_18DEC);
        const swapCollateral = BigNumber.from("10000").mul(N1__0_18DEC);
        const swapOpeningFee = BigNumber.from("20").mul(N1__0_18DEC);

        const totalCollateralPayFixedBalance = BigNumber.from("1000").mul(N1__0_18DEC);
        const totalCollateralReceiveFixedBalance = BigNumber.from("13000").mul(N1__0_18DEC);

        const soap = BigNumber.from("500").mul(N1__0_18DEC);

        const accruedIpor = {
            indexValue: BigNumber.from("3").mul(N0__01_18DEC),
            ibtPrice: N1__0_18DEC,
            exponentialMovingAverage: BigNumber.from("4").mul(N0__01_18DEC),
            exponentialWeightedMovingVariance: BigNumber.from("999999999999999899"),
        };

        const expectedSpreadValue = spreadPremiumsMaxValue;

        //when
        let actualSpreadValue = BigNumber.from(
            await miltonSpread
                .connect(userOne)
                .testCalculateSpreadPremiumsPayFixed(
                    soap,
                    accruedIpor,
                    liquidityPoolBalance.add(swapOpeningFee),
                    totalCollateralPayFixedBalance.add(swapCollateral),
                    totalCollateralReceiveFixedBalance
                )
        );

        //then
        expect(
            actualSpreadValue,
            `Incorrect Pay Fixed Spread Value, actual: ${actualSpreadValue}, expected: ${expectedSpreadValue}`
        ).to.be.eq(expectedSpreadValue);
    });

    it.skip("should calculate Spread Premiums Pay Fixed = Spread Max Value - Kf part normal, KOmega part normal, KVol part normal, KHist very high", async () => {
        //given
        const miltonSpread = await prepareMiltonSpreadCase6();
        const spreadPremiumsMaxValue = BigNumber.from("3").mul(N0__1_18DEC);

        const liquidityPoolBalance = BigNumber.from("15000").mul(N1__0_18DEC);
        const swapCollateral = BigNumber.from("10000").mul(N1__0_18DEC);
        const swapOpeningFee = BigNumber.from("20").mul(N1__0_18DEC);

        const totalCollateralPayFixedBalance = BigNumber.from("1000").mul(N1__0_18DEC);
        const totalCollateralReceiveFixedBalance = BigNumber.from("13000").mul(N1__0_18DEC);

        const soap = BigNumber.from("500").mul(N1__0_18DEC);

        const accruedIpor = {
            indexValue: BigNumber.from("2000000000000000010"),
            ibtPrice: N1__0_18DEC,
            exponentialMovingAverage: BigNumber.from("3").mul(N1__0_18DEC),
            exponentialWeightedMovingVariance: BigNumber.from("35").mul(N0__001_18DEC),
        };

        const expectedSpreadValue = spreadPremiumsMaxValue;

        //when
        let actualSpreadValue = BigNumber.from(
            await miltonSpread
                .connect(userOne)
                .testCalculateSpreadPremiumsPayFixed(
                    soap,
                    accruedIpor,
                    liquidityPoolBalance.add(swapOpeningFee),
                    totalCollateralPayFixedBalance.add(swapCollateral),
                    totalCollateralReceiveFixedBalance
                )
        );

        //then
        expect(
            actualSpreadValue,
            `Incorrect Pay Fixed Spread Value, actual: ${actualSpreadValue}, expected: ${expectedSpreadValue}`
        ).to.be.eq(expectedSpreadValue);
    });

    it.skip("should calculate Spread Premiums Pay Fixed Value = Spread Max Value - Kf part + KOmega part + KVol part + KHist > Spread Max Value", async () => {
        //given
        const miltonSpread = await prepareMiltonSpreadCase7();
        const spreadPremiumsMaxValue = BigNumber.from("3").mul(N0__1_18DEC);

        const liquidityPoolBalance = BigNumber.from("15000").mul(N1__0_18DEC);
        const swapCollateral = BigNumber.from("10000").mul(N1__0_18DEC);
        const swapOpeningFee = BigNumber.from("20").mul(N1__0_18DEC);

        const totalCollateralPayFixedBalance = BigNumber.from("1000").mul(N1__0_18DEC);
        const totalCollateralReceiveFixedBalance = BigNumber.from("13000").mul(N1__0_18DEC);

        const soap = BigNumber.from("500").mul(N1__0_18DEC);

        const accruedIpor = {
            indexValue: BigNumber.from("3").mul(N0__01_18DEC),
            ibtPrice: N1__0_18DEC,
            exponentialMovingAverage: BigNumber.from("4").mul(N0__01_18DEC),
            exponentialWeightedMovingVariance: BigNumber.from("35").mul(N0__001_18DEC),
        };

        const expectedSpreadValue = spreadPremiumsMaxValue;

        //when
        let actualSpreadValue = BigNumber.from(
            await miltonSpread
                .connect(userOne)
                .testCalculateSpreadPremiumsPayFixed(
                    soap,
                    accruedIpor,
                    liquidityPoolBalance.add(swapOpeningFee),
                    totalCollateralPayFixedBalance.add(swapCollateral),
                    totalCollateralReceiveFixedBalance
                )
        );

        //then
        expect(
            actualSpreadValue,
            `Incorrect Pay Fixed Spread Value, actual: ${actualSpreadValue}, expected: ${expectedSpreadValue}`
        ).to.be.eq(expectedSpreadValue);
    });

    it.skip("should NOT calculate Spread Premiums Pay Fixed - Liquidity Pool + Opening Fee = 0", async () => {
        //given
        const miltonSpread = await prepareMiltonSpreadCase6();

        const liquidityPoolBalance = ZERO;
        const swapCollateral = BigNumber.from("10000").mul(N1__0_18DEC);
        const swapOpeningFee = ZERO;

        const totalCollateralPayFixedBalance = BigNumber.from("1000").mul(N1__0_18DEC);
        const totalCollateralReceiveFixedBalance = BigNumber.from("13000").mul(N1__0_18DEC);

        const soap = BigNumber.from("500").mul(N1__0_18DEC);

        const accruedIpor = {
            indexValue: BigNumber.from("3").mul(N0__01_18DEC),
            ibtPrice: N1__0_18DEC,
            exponentialMovingAverage: BigNumber.from("4").mul(N0__01_18DEC),
            exponentialWeightedMovingVariance: BigNumber.from("35").mul(N0__001_18DEC),
        };

        await assertError(
            //when
            miltonSpread
                .connect(userOne)
                .testCalculateSpreadPremiumsPayFixed(
                    soap,
                    accruedIpor,
                    liquidityPoolBalance.add(swapOpeningFee),
                    totalCollateralPayFixedBalance.add(swapCollateral),
                    totalCollateralReceiveFixedBalance
                ),
            //then
            "IPOR_322"
        );
    });

    it.skip("should calculate Spread Pay Fixed - initial state with Liquidity Pool", async () => {
        //given
        let testData = await prepareTestData(
            [admin, userOne, userTwo, userThree, liquidityProvider],
            ["DAI"],
            miltonSpreadModel,
            MiltonUsdcCase.CASE0,
            MiltonUsdtCase.CASE0,
            MiltonDaiCase.CASE0,
            MockStanleyCase.CASE1,
            JosephUsdcMockCases.CASE0,
            JosephUsdtMockCases.CASE0,
            JosephDaiMockCases.CASE0
        );
        const calculateTimestamp = Math.floor(Date.now() / 1000);
        const expectedSpreadPayFixed = BigNumber.from("360000000000000");
        const timestamp = Math.floor(Date.now() / 1000);

        await prepareApproveForUsers([liquidityProvider], "DAI", testData);

        const { josephDai, miltonDai } = testData;
        if (josephDai === undefined || miltonDai === undefined) {
            expect(true).to.be.false;
            return;
        }

        await setupTokenDaiInitialValuesForUsers([liquidityProvider], testData);
        await josephDai
            .connect(liquidityProvider)
            .itfProvideLiquidity(USD_10_000_000_18DEC, timestamp);

        //when
        let actualSpreadValue = await miltonDai
            .connect(userOne)
            .callStatic.itfCalculateSpread(calculateTimestamp);

        //then
        expect(actualSpreadValue.spreadPayFixed).to.be.eq(expectedSpreadPayFixed);
    });

    it.skip("should calculate Spread Pay Fixed - spread premiums higher than IPOR Index", async () => {
        //given
        let testData = await prepareTestData(
            [admin, userOne, userTwo, userThree, liquidityProvider],
            ["USDT"],
            miltonSpreadModel,
            MiltonUsdcCase.CASE0,
            MiltonUsdtCase.CASE0,
            MiltonDaiCase.CASE0,
            MockStanleyCase.CASE1,
            JosephUsdcMockCases.CASE0,
            JosephUsdtMockCases.CASE0,
            JosephDaiMockCases.CASE0
        );

        const { tokenUsdt, iporOracle, josephUsdt, miltonUsdt } = testData;

        if (tokenUsdt === undefined || josephUsdt === undefined || miltonUsdt === undefined) {
            expect(true).to.be.false;
            return;
        }

        const params = getReceiveFixedDerivativeParamsUSDTCase1(userTwo, tokenUsdt);

        await iporOracle
            .connect(userOne)
            .itfUpdateIndex(params.asset, PERCENTAGE_3_18DEC, params.openTimestamp);

        let balanceLiquidityPool = BigNumber.from("10000000000");

        await prepareApproveForUsers(
            [userOne, userTwo, userThree, liquidityProvider],
            "USDT",
            testData
        );
        await setupTokenUsdtInitialValuesForUsers(
            [admin, userOne, userTwo, userThree, liquidityProvider],
            tokenUsdt
        );

        await josephUsdt
            .connect(liquidityProvider)
            .itfProvideLiquidity(balanceLiquidityPool, params.openTimestamp);

        await miltonUsdt
            .connect(userTwo)
            .itfOpenSwapReceiveFixed(
                params.openTimestamp,
                BigNumber.from("1000000000"),
                params.acceptableFixedInterestRate,
                params.leverage
            );

        //when
        let actualSpreadValue = await miltonUsdt
            .connect(userOne)
            .callStatic.itfCalculateSpread(params.openTimestamp.add(BigNumber.from("1")));

        //then
        expect(actualSpreadValue.spreadPayFixed).to.be.gt(ZERO);
    });

    it.skip("should calculate Spread Pay Fixed - initial state with Liquidity Pool", async () => {
        //given
        let testData = await prepareTestData(
            [admin, userOne, userTwo, userThree, liquidityProvider],
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
        const calculateTimestamp = Math.floor(Date.now() / 1000);
        const expectedSpreadPayFixed = BigNumber.from("360000000000000");
        const timestamp = Math.floor(Date.now() / 1000);

        const { josephDai, miltonDai } = testData;
        if (josephDai === undefined || miltonDai === undefined) {
            expect(true).to.be.false;
            return;
        }

        await prepareApproveForUsers([liquidityProvider], "DAI", testData);

        await setupTokenDaiInitialValuesForUsers([liquidityProvider], testData);
        await josephDai
            .connect(liquidityProvider)
            .itfProvideLiquidity(USD_10_000_000_18DEC, timestamp);

        //when
        let actualSpreadValue = await miltonDai
            .connect(userOne)
            .callStatic.itfCalculateSpread(calculateTimestamp);

        //then
        expect(actualSpreadValue.spreadPayFixed).to.be.eq(expectedSpreadPayFixed);
    });

    it.skip("should calculate Spread Pay Fixed - spread premiums higher than IPOR Index", async () => {
        //given
        let testData = await prepareTestData(
            [admin, userOne, userTwo, userThree, liquidityProvider],
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

        const { tokenUsdt, iporOracle, josephUsdt, miltonUsdt } = testData;

        if (tokenUsdt === undefined || josephUsdt === undefined || miltonUsdt === undefined) {
            expect(true).to.be.false;
            return;
        }

        const params = getReceiveFixedDerivativeParamsUSDTCase1(userTwo, tokenUsdt);

        await iporOracle
            .connect(userOne)
            .itfUpdateIndex(params.asset, PERCENTAGE_3_18DEC, params.openTimestamp);

        let balanceLiquidityPool = BigNumber.from("10000000000");

        await prepareApproveForUsers(
            [userOne, userTwo, userThree, liquidityProvider],
            "USDT",
            testData
        );
        await setupTokenUsdtInitialValuesForUsers(
            [admin, userOne, userTwo, userThree, liquidityProvider],
            tokenUsdt
        );

        await josephUsdt
            .connect(liquidityProvider)
            .itfProvideLiquidity(balanceLiquidityPool, params.openTimestamp);

        await miltonUsdt
            .connect(userTwo)
            .itfOpenSwapReceiveFixed(
                params.openTimestamp,
                BigNumber.from("1000000000"),
                params.acceptableFixedInterestRate,
                params.leverage
            );

        //when
        let actualSpreadValue = await miltonUsdt
            .connect(userOne)
            .callStatic.itfCalculateSpread(params.openTimestamp.add(BigNumber.from("1")));

        //then
        expect(actualSpreadValue.spreadPayFixed).to.be.gt(ZERO);
    });
});

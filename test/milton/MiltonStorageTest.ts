import hre from "hardhat";
import chai from "chai";
import { Signer, BigNumber } from "ethers";
import { MockSpreadModel } from "../../types";
import {
    USD_28_000_18DEC,
    N1__0_18DEC,
    PERCENTAGE_5_18DEC,
    LEVERAGE_18DEC,
    TC_TOTAL_AMOUNT_10_000_18DEC,
    N0__1_18DEC,
    PERIOD_25_DAYS_IN_SECONDS,
    PERIOD_6_HOURS_IN_SECONDS,
    PERCENTAGE_95_18DEC,
    USD_28_000_6DEC,
    USD_10_000_6DEC,
    N1__0_6DEC,
    ZERO,
    N0__01_18DEC,
} from "../utils/Constants";
import { assertError } from "../utils/AssertUtils";
import {
    MiltonUsdcCase,
    MiltonUsdtCase,
    MiltonDaiCase,
    prepareMockSpreadModel,
} from "../utils/MiltonUtils";
import {
    prepareTestData,
    prepareApproveForUsers,
    setupTokenDaiInitialValuesForUsers,
    setupTokenUsdtInitialValuesForUsers,
} from "../utils/DataUtils";
import { MockStanleyCase } from "../utils/StanleyUtils";
import { JosephUsdcMockCases, JosephUsdtMockCases, JosephDaiMockCases } from "../utils/JosephUtils";
import {
    prepareSwapPayFixedStruct18DecSimpleCase1,
    openSwapPayFixed,
    testCasePaginationPayFixed,
    testCasePaginationReceiveFixed,
    testCaseIdsPaginationPayFixed,
    testCaseIdsPaginationReceiveFixed,
    testCaseIdsPagination,
} from "../utils/MiltonStorageUtils";

const { expect } = chai;

describe("MiltonStorage", () => {
    let miltonSpreadModel: MockSpreadModel;
    let admin: Signer,
        userOne: Signer,
        userTwo: Signer,
        userThree: Signer,
        liquidityProvider: Signer,
        miltonStorageAddress: Signer;

    before(async () => {
        [admin, userOne, userTwo, userThree, liquidityProvider, miltonStorageAddress] =
            await hre.ethers.getSigners();
        miltonSpreadModel = await prepareMockSpreadModel(
            BigNumber.from(6).mul(N0__01_18DEC),
            BigNumber.from(4).mul(N0__01_18DEC),
            ZERO,
            ZERO
        );
    });

    it("should transfer ownership - simple case 1", async () => {
        //given
        const { miltonStorageDai } = await prepareTestData(
            BigNumber.from(Math.floor(Date.now() / 1000)),
            [admin, userOne, userTwo, userThree, liquidityProvider],
            ["DAI"],
            [],
            miltonSpreadModel,
            MiltonUsdcCase.CASE0,
            MiltonUsdtCase.CASE0,
            MiltonDaiCase.CASE0,
            MockStanleyCase.CASE1,
            JosephUsdcMockCases.CASE0,
            JosephUsdtMockCases.CASE0,
            JosephDaiMockCases.CASE0
        );
        const expectedNewOwner = userTwo;

        if (miltonStorageDai === undefined) {
            expect(true).to.be.false;
            return;
        }

        //when
        await miltonStorageDai
            .connect(admin)
            .transferOwnership(await expectedNewOwner.getAddress());

        await miltonStorageDai.connect(expectedNewOwner).confirmTransferOwnership();

        //then
        const actualNewOwner = await miltonStorageDai.connect(userOne).owner();
        expect(await expectedNewOwner.getAddress()).to.be.equal(actualNewOwner);
    });

    it("should NOT transfer ownership - sender not current owner", async () => {
        //given
        const { miltonStorageDai } = await prepareTestData(
            BigNumber.from(Math.floor(Date.now() / 1000)),
            [admin, userOne, userTwo, userThree, liquidityProvider],
            ["DAI"],
            [],
            miltonSpreadModel,
            MiltonUsdcCase.CASE0,
            MiltonUsdtCase.CASE0,
            MiltonDaiCase.CASE0,
            MockStanleyCase.CASE1,
            JosephUsdcMockCases.CASE0,
            JosephUsdtMockCases.CASE0,
            JosephDaiMockCases.CASE0
        );
        const expectedNewOwner = userTwo;
        if (miltonStorageDai === undefined) {
            expect(true).to.be.false;
            return;
        }
        //when
        await assertError(
            miltonStorageDai
                .connect(userThree)
                .transferOwnership(await expectedNewOwner.getAddress()),
            //then
            "Ownable: caller is not the owner"
        );
    });

    it("should NOT confirm transfer ownership - sender not appointed owner", async () => {
        //given
        const { miltonStorageDai } = await prepareTestData(
            BigNumber.from(Math.floor(Date.now() / 1000)),
            [admin, userOne, userTwo, userThree, liquidityProvider],
            ["DAI"],
            [],
            miltonSpreadModel,
            MiltonUsdcCase.CASE0,
            MiltonUsdtCase.CASE0,
            MiltonDaiCase.CASE0,
            MockStanleyCase.CASE1,
            JosephUsdcMockCases.CASE0,
            JosephUsdtMockCases.CASE0,
            JosephDaiMockCases.CASE0
        );
        const expectedNewOwner = userTwo;
        if (miltonStorageDai === undefined) {
            expect(true).to.be.false;
            return;
        }

        //when
        await miltonStorageDai
            .connect(admin)
            .transferOwnership(await expectedNewOwner.getAddress());

        await assertError(
            miltonStorageDai.connect(userThree).confirmTransferOwnership(),
            //then
            "IPOR_007"
        );
    });

    it("should NOT confirm transfer ownership twice - sender not appointed owner", async () => {
        //given
        const { miltonStorageDai } = await prepareTestData(
            BigNumber.from(Math.floor(Date.now() / 1000)),
            [admin, userOne, userTwo, userThree, liquidityProvider],
            ["DAI"],
            [],
            miltonSpreadModel,
            MiltonUsdcCase.CASE0,
            MiltonUsdtCase.CASE0,
            MiltonDaiCase.CASE0,
            MockStanleyCase.CASE1,
            JosephUsdcMockCases.CASE0,
            JosephUsdtMockCases.CASE0,
            JosephDaiMockCases.CASE0
        );
        const expectedNewOwner = userTwo;

        if (miltonStorageDai === undefined) {
            expect(true).to.be.false;
            return;
        }

        //when
        await miltonStorageDai
            .connect(admin)
            .transferOwnership(await expectedNewOwner.getAddress());

        await miltonStorageDai.connect(expectedNewOwner).confirmTransferOwnership();

        await assertError(
            miltonStorageDai.connect(expectedNewOwner).confirmTransferOwnership(),
            "IPOR_007"
        );
    });

    it("should NOT transfer ownership - sender already lost ownership", async () => {
        //given
        const { miltonStorageDai } = await prepareTestData(
            BigNumber.from(Math.floor(Date.now() / 1000)),
            [admin, userOne, userTwo, userThree, liquidityProvider],
            ["DAI"],
            [],
            miltonSpreadModel,
            MiltonUsdcCase.CASE0,
            MiltonUsdtCase.CASE0,
            MiltonDaiCase.CASE0,
            MockStanleyCase.CASE1,
            JosephUsdcMockCases.CASE0,
            JosephUsdtMockCases.CASE0,
            JosephDaiMockCases.CASE0
        );
        const expectedNewOwner = userTwo;

        if (miltonStorageDai === undefined) {
            expect(true).to.be.false;
            return;
        }

        await miltonStorageDai
            .connect(admin)
            .transferOwnership(await expectedNewOwner.getAddress());

        await miltonStorageDai.connect(expectedNewOwner).confirmTransferOwnership();

        //when
        await assertError(
            miltonStorageDai.connect(admin).transferOwnership(await expectedNewOwner.getAddress()),
            //then
            "Ownable: caller is not the owner"
        );
    });

    it("should have rights to transfer ownership - sender still have rights", async () => {
        //given
        const { miltonStorageDai } = await prepareTestData(
            BigNumber.from(Math.floor(Date.now() / 1000)),
            [admin, userOne, userTwo, userThree, liquidityProvider],
            ["DAI"],
            [],
            miltonSpreadModel,
            MiltonUsdcCase.CASE0,
            MiltonUsdtCase.CASE0,
            MiltonDaiCase.CASE0,
            MockStanleyCase.CASE1,
            JosephUsdcMockCases.CASE0,
            JosephUsdtMockCases.CASE0,
            JosephDaiMockCases.CASE0
        );
        const expectedNewOwner = userTwo;

        if (miltonStorageDai === undefined) {
            expect(true).to.be.false;
            return;
        }

        await miltonStorageDai
            .connect(admin)
            .transferOwnership(await expectedNewOwner.getAddress());

        //when
        await miltonStorageDai
            .connect(admin)
            .transferOwnership(await expectedNewOwner.getAddress());

        //then
        const actualNewOwner = await miltonStorageDai.connect(userOne).owner();
        expect(await admin.getAddress()).to.be.equal(actualNewOwner);
    });

    it("should update Milton Storage when open position, caller has rights to update", async () => {
        //given
        const testData = await prepareTestData(
            BigNumber.from(Math.floor(Date.now() / 1000)),
            [admin, userOne, userTwo, userThree, liquidityProvider, miltonStorageAddress],
            ["DAI"],
            [],
            miltonSpreadModel,
            MiltonUsdcCase.CASE0,
            MiltonUsdtCase.CASE0,
            MiltonDaiCase.CASE0,
            MockStanleyCase.CASE1,
            JosephUsdcMockCases.CASE0,
            JosephUsdtMockCases.CASE0,
            JosephDaiMockCases.CASE0
        );
        await prepareApproveForUsers(
            [userOne, userTwo, userThree, liquidityProvider],
            "DAI",
            testData
        );
        const { miltonStorageDai, miltonDai } = testData;
        if (miltonStorageDai === undefined || miltonDai === undefined) {
            expect(true).to.be.false;
            return;
        }

        await setupTokenDaiInitialValuesForUsers([admin, userOne, liquidityProvider], testData);

        await miltonStorageDai.setMilton(await miltonStorageAddress.getAddress());

        //when
        await miltonStorageDai
            .connect(miltonStorageAddress)
            .updateStorageWhenOpenSwapPayFixed(
                prepareSwapPayFixedStruct18DecSimpleCase1(await userTwo.getAddress()),
                await miltonDai.getIporPublicationFee()
            );
        //then
    });

    it("should NOT update Milton Storage when open position, caller dont have rights to update", async () => {
        //given
        const { miltonStorageDai, miltonDai } = await prepareTestData(
            BigNumber.from(Math.floor(Date.now() / 1000)),
            [admin, userOne, userTwo, userThree, liquidityProvider, miltonStorageAddress],
            ["DAI"],
            [],
            miltonSpreadModel,
            MiltonUsdcCase.CASE0,
            MiltonUsdtCase.CASE0,
            MiltonDaiCase.CASE0,
            MockStanleyCase.CASE1,
            JosephUsdcMockCases.CASE0,
            JosephUsdtMockCases.CASE0,
            JosephDaiMockCases.CASE0
        );
        if (miltonStorageDai === undefined || miltonDai === undefined) {
            expect(true).to.be.false;
            return;
        }
        const derivativeStruct = prepareSwapPayFixedStruct18DecSimpleCase1(await userTwo.getAddress());
        await assertError(
            //when
            miltonStorageDai
                .connect(userThree)
                .updateStorageWhenOpenSwapPayFixed(
                    derivativeStruct,
                    await miltonDai.getIporPublicationFee()
                ),
            //then
            "IPOR_008"
        );
    });

    it("should NOT add Liquidity when assetAmount is zero", async () => {
        //given
        const { miltonStorageDai, miltonDai } = await prepareTestData(
            BigNumber.from(Math.floor(Date.now() / 1000)),
            [admin, userOne, userTwo, userThree, liquidityProvider, miltonStorageAddress],
            ["DAI"],
            [],
            miltonSpreadModel,
            MiltonUsdcCase.CASE0,
            MiltonUsdtCase.CASE0,
            MiltonDaiCase.CASE0,
            MockStanleyCase.CASE1,
            JosephUsdcMockCases.CASE0,
            JosephUsdtMockCases.CASE0,
            JosephDaiMockCases.CASE0
        );
        if (miltonStorageDai === undefined || miltonDai === undefined) {
            expect(true).to.be.false;
            return;
        }
        await miltonStorageDai.setJoseph(await admin.getAddress());
        await assertError(
            //when
            miltonStorageDai.addLiquidity(
                await liquidityProvider.getAddress(),
                ZERO,
                BigNumber.from("10000000").mul(N1__0_18DEC),
                BigNumber.from("1000000").mul(N1__0_18DEC)
            ),
            //then
            "IPOR_328"
        );
    });

    it("should NOT update Storage When transferredAmount > balance", async () => {
        //given
        const { miltonStorageDai, miltonDai } = await prepareTestData(
            BigNumber.from(Math.floor(Date.now() / 1000)),
            [admin, userOne, userTwo, userThree, liquidityProvider, miltonStorageAddress],
            ["DAI"],
            [],
            miltonSpreadModel,
            MiltonUsdcCase.CASE0,
            MiltonUsdtCase.CASE0,
            MiltonDaiCase.CASE0,
            MockStanleyCase.CASE1,
            JosephUsdcMockCases.CASE0,
            JosephUsdtMockCases.CASE0,
            JosephDaiMockCases.CASE0
        );
        if (miltonStorageDai === undefined || miltonDai === undefined) {
            expect(true).to.be.false;
            return;
        }
        await miltonStorageDai.setJoseph(await admin.getAddress());
        await assertError(
            //when
            miltonStorageDai.updateStorageWhenTransferToTreasury(N1__0_18DEC.mul(N1__0_18DEC)),
            //then
            "IPOR_330"
        );
    });

    it("should NOT update Storage When vaultBalance < depositAmount", async () => {
        //given
        const { miltonStorageDai, miltonDai } = await prepareTestData(
            BigNumber.from(Math.floor(Date.now() / 1000)),
            [admin, userOne, userTwo, userThree, liquidityProvider, miltonStorageAddress],
            ["DAI"],
            [],
            miltonSpreadModel,
            MiltonUsdcCase.CASE0,
            MiltonUsdtCase.CASE0,
            MiltonDaiCase.CASE0,
            MockStanleyCase.CASE1,
            JosephUsdcMockCases.CASE0,
            JosephUsdtMockCases.CASE0,
            JosephDaiMockCases.CASE0
        );
        if (miltonStorageDai === undefined || miltonDai === undefined) {
            expect(true).to.be.false;
            return;
        }
        await miltonStorageDai.setMilton(await admin.getAddress());
        await assertError(
            //when
            miltonStorageDai.updateStorageWhenDepositToStanley(N1__0_18DEC, ZERO),
            //then
            "IPOR_329"
        );
    });

    it("should NOT update Storage When transferredAmount > balance", async () => {
        //given
        const { miltonStorageDai, miltonDai } = await prepareTestData(
            BigNumber.from(Math.floor(Date.now() / 1000)),
            [admin, userOne, userTwo, userThree, liquidityProvider, miltonStorageAddress],
            ["DAI"],
            [],
            miltonSpreadModel,
            MiltonUsdcCase.CASE0,
            MiltonUsdtCase.CASE0,
            MiltonDaiCase.CASE0,
            MockStanleyCase.CASE1,
            JosephUsdcMockCases.CASE0,
            JosephUsdtMockCases.CASE0,
            JosephDaiMockCases.CASE0
        );
        if (miltonStorageDai === undefined || miltonDai === undefined) {
            expect(true).to.be.false;
            return;
        }
        await miltonStorageDai.setJoseph(await admin.getAddress());
        await assertError(
            //when
            miltonStorageDai.updateStorageWhenTransferToCharlieTreasury(
                N1__0_18DEC.mul(N1__0_18DEC)
            ),
            //then
            "IPOR_326"
        );
    });

    it("Should not update Storage when send 0", async () => {
        //given
        const { miltonStorageDai, miltonDai } = await prepareTestData(
            BigNumber.from(Math.floor(Date.now() / 1000)),
            [admin, userOne, userTwo, userThree, liquidityProvider, miltonStorageAddress],
            ["DAI"],
            [],
            miltonSpreadModel,
            MiltonUsdcCase.CASE0,
            MiltonUsdtCase.CASE0,
            MiltonDaiCase.CASE0,
            MockStanleyCase.CASE1,
            JosephUsdcMockCases.CASE0,
            JosephUsdtMockCases.CASE0,
            JosephDaiMockCases.CASE0
        );
        if (miltonStorageDai === undefined || miltonDai === undefined) {
            expect(true).to.be.false;
            return;
        }
        await miltonStorageDai.setJoseph(await admin.getAddress());
        await assertError(
            //when
            miltonStorageDai.updateStorageWhenTransferToCharlieTreasury(ZERO),
            //then
            "IPOR_006"
        );
    });

    it("should update Milton Storage when close position, caller has rights to update, DAI 18 decimals", async () => {
        //given
        const testData = await prepareTestData(
            BigNumber.from(Math.floor(Date.now() / 1000)),
            [admin, userOne, userTwo, userThree, liquidityProvider, miltonStorageAddress],
            ["DAI"],
            [PERCENTAGE_5_18DEC],
            miltonSpreadModel,
            MiltonUsdcCase.CASE0,
            MiltonUsdtCase.CASE0,
            MiltonDaiCase.CASE0,
            MockStanleyCase.CASE1,
            JosephUsdcMockCases.CASE0,
            JosephUsdtMockCases.CASE0,
            JosephDaiMockCases.CASE0
        );

        await prepareApproveForUsers(
            [userOne, userTwo, userThree, liquidityProvider],
            "DAI",
            testData
        );

        const { miltonStorageDai, miltonDai, tokenDai, iporOracle, josephDai } = testData;
        if (
            miltonStorageDai === undefined ||
            miltonDai === undefined ||
            tokenDai === undefined ||
            iporOracle === undefined ||
            josephDai === undefined
        ) {
            expect(true).to.be.false;
            return;
        }

        await setupTokenDaiInitialValuesForUsers(
            [admin, userOne, userTwo, liquidityProvider],
            testData
        );

        const derivativeParams = {
            asset: tokenDai,
            totalAmount: TC_TOTAL_AMOUNT_10_000_18DEC,
            acceptableFixedInterestRate: BigNumber.from("9").mul(N0__1_18DEC),
            leverage: LEVERAGE_18DEC,
            openTimestamp: BigNumber.from(Math.floor(Date.now() / 1000)),
            from: userTwo,
            direction: 0,
        };

        await iporOracle
            .connect(userOne)
            .itfUpdateIndex(
                derivativeParams.asset.address,
                PERCENTAGE_5_18DEC,
                derivativeParams.openTimestamp
            );

        await josephDai
            .connect(liquidityProvider)
            .itfProvideLiquidity(USD_28_000_18DEC, derivativeParams.openTimestamp);

        await openSwapPayFixed(testData, derivativeParams);
        let derivativeItem = await miltonStorageDai.getSwapPayFixed(1);
        let closeSwapTimestamp = derivativeParams.openTimestamp.add(PERIOD_25_DAYS_IN_SECONDS);

        await miltonStorageDai.setMilton(await miltonStorageAddress.getAddress());

        //when
        await miltonStorageDai
            .connect(miltonStorageAddress)
            .updateStorageWhenCloseSwapPayFixed(
                derivativeItem,
                BigNumber.from("10").mul(N1__0_18DEC),
                BigNumber.from("1").mul(N1__0_18DEC),
                closeSwapTimestamp
            );

        await miltonStorageDai.setMilton(miltonDai.address);

        //then
        // assert(true); //no exception this line is achieved
    });

    it("should update Milton Storage when close position, caller has rights to update, USDT 6 decimals", async () => {
        //given
        let testData = await prepareTestData(
            BigNumber.from(Math.floor(Date.now() / 1000)),
            [admin, userOne, userTwo, userThree, liquidityProvider, miltonStorageAddress],
            ["USDT"],
            [PERCENTAGE_5_18DEC],
            miltonSpreadModel,
            MiltonUsdcCase.CASE0,
            MiltonUsdtCase.CASE0,
            MiltonDaiCase.CASE0,
            MockStanleyCase.CASE1,
            JosephUsdcMockCases.CASE0,
            JosephUsdtMockCases.CASE0,
            JosephDaiMockCases.CASE0
        );

        await prepareApproveForUsers(
            [userOne, userTwo, userThree, liquidityProvider],
            "USDT",
            testData
        );

        const { tokenUsdt, iporOracle, josephUsdt, miltonStorageUsdt, miltonUsdt } = testData;
        if (
            tokenUsdt === undefined ||
            josephUsdt === undefined ||
            miltonStorageUsdt === undefined ||
            miltonUsdt === undefined
        ) {
            expect(true).to.be.false;
            return;
        }

        await setupTokenUsdtInitialValuesForUsers(
            [admin, userOne, userTwo, liquidityProvider],
            tokenUsdt
        );

        const derivativeParams = {
            asset: tokenUsdt,
            totalAmount: USD_10_000_6DEC,
            acceptableFixedInterestRate: BigNumber.from("9").mul(N0__1_18DEC),
            leverage: LEVERAGE_18DEC,
            openTimestamp: BigNumber.from(Math.floor(Date.now() / 1000)),
            from: userTwo,
            direction: 0,
        };

        await iporOracle
            .connect(userOne)
            .itfUpdateIndex(
                derivativeParams.asset.address,
                PERCENTAGE_5_18DEC,
                derivativeParams.openTimestamp
            );

        await josephUsdt
            .connect(liquidityProvider)
            .itfProvideLiquidity(USD_28_000_6DEC, derivativeParams.openTimestamp);

        await openSwapPayFixed(testData, derivativeParams);
        const derivativeItem = await miltonStorageUsdt.getSwapPayFixed(1);
        const closeSwapTimestamp = derivativeParams.openTimestamp.add(PERIOD_25_DAYS_IN_SECONDS);

        await miltonStorageUsdt.setMilton(await miltonStorageAddress.getAddress());

        //when
        await miltonStorageUsdt
            .connect(miltonStorageAddress)
            .updateStorageWhenCloseSwapPayFixed(
                derivativeItem,
                BigNumber.from("10").mul(N1__0_6DEC),
                BigNumber.from("1").mul(N1__0_6DEC),
                closeSwapTimestamp
            );
        //then
        //assert(true); //no exception this line is achieved
    });

    it("should NOT update Milton Storage when close position, caller don't have rights to update", async () => {
        // given
        const testData = await prepareTestData(
            BigNumber.from(Math.floor(Date.now() / 1000)),
            [admin, userOne, userTwo, userThree, liquidityProvider, miltonStorageAddress],
            ["DAI"],
            [PERCENTAGE_5_18DEC],
            miltonSpreadModel,
            MiltonUsdcCase.CASE0,
            MiltonUsdtCase.CASE0,
            MiltonDaiCase.CASE0,
            MockStanleyCase.CASE1,
            JosephUsdcMockCases.CASE0,
            JosephUsdtMockCases.CASE0,
            JosephDaiMockCases.CASE0
        );

        await prepareApproveForUsers(
            [userOne, userTwo, userThree, liquidityProvider],
            "DAI",
            testData
        );
        const { tokenDai, iporOracle, josephDai, miltonStorageDai, miltonDai } = testData;
        if (
            miltonStorageDai === undefined ||
            miltonDai === undefined ||
            tokenDai === undefined ||
            iporOracle === undefined ||
            josephDai === undefined
        ) {
            expect(true).to.be.false;
            return;
        }
        await setupTokenDaiInitialValuesForUsers(
            [admin, userOne, userTwo, liquidityProvider],
            testData
        );
        const derivativeParams = {
            asset: tokenDai,
            totalAmount: TC_TOTAL_AMOUNT_10_000_18DEC,
            acceptableFixedInterestRate: BigNumber.from("9").mul(N0__1_18DEC),
            leverage: LEVERAGE_18DEC,
            openTimestamp: BigNumber.from(Math.floor(Date.now() / 1000)),
            from: userTwo,
            direction: 0,
        };

        await iporOracle
            .connect(userOne)
            .itfUpdateIndex(
                derivativeParams.asset.address,
                PERCENTAGE_5_18DEC,
                derivativeParams.openTimestamp
            );

        await josephDai
            .connect(liquidityProvider)
            .itfProvideLiquidity(USD_28_000_18DEC, derivativeParams.openTimestamp);

        await openSwapPayFixed(testData, derivativeParams);
        const derivativeItem = await miltonStorageDai.getSwapPayFixed(1);
        const closeSwapTimestamp = derivativeParams.openTimestamp.add(PERIOD_25_DAYS_IN_SECONDS);

        //when
        await assertError(
            miltonStorageDai
                .connect(userThree)
                .updateStorageWhenCloseSwapPayFixed(
                    derivativeItem,
                    BigNumber.from("10").mul(N1__0_18DEC),
                    BigNumber.from("1").mul(N1__0_18DEC),
                    closeSwapTimestamp
                ),
            //then
            "IPOR_008"
        );
    });

    it("get swaps - pay fixed, should fail when page size is equal 0", async () => {
        await testCasePaginationPayFixed(
            [admin, userOne, userTwo, userThree, liquidityProvider, miltonStorageAddress],
            ZERO,
            ZERO,
            ZERO,
            ZERO,
            "IPOR_009",
            miltonSpreadModel
        );
    });

    it("get swaps - pay fixed, should return empty list of swaps", async () => {
        await testCasePaginationPayFixed(
            [admin, userOne, userTwo, userThree, liquidityProvider, miltonStorageAddress],
            ZERO,
            ZERO,
            BigNumber.from("10"),
            ZERO,
            null,
            miltonSpreadModel
        );
    });

    it("get swaps - pay fixed, should receive empty list of swaps when user passes non zero offset and doesn't have any swap", async () => {
        await testCasePaginationPayFixed(
            [admin, userOne, userTwo, userThree, liquidityProvider, miltonStorageAddress],
            ZERO,
            BigNumber.from("10"),
            BigNumber.from("10"),
            ZERO,
            null,
            miltonSpreadModel
        );
    });

    it("get swaps - pay fixed, should receive limited swap array", async () => {
        await testCasePaginationPayFixed(
            [admin, userOne, userTwo, userThree, liquidityProvider, miltonStorageAddress],
            BigNumber.from("11"),
            ZERO,
            BigNumber.from("10"),
            BigNumber.from("10"),
            null,
            miltonSpreadModel
        );
    });

    it("get swaps - pay fixed, should receive limited swap array with offset", async () => {
        await testCasePaginationPayFixed(
            [admin, userOne, userTwo, userThree, liquidityProvider, miltonStorageAddress],
            BigNumber.from("22"),
            BigNumber.from("10"),

            BigNumber.from("10"),
            BigNumber.from("10"),
            null,
            miltonSpreadModel
        );
    });

    it("get swaps - pay fixed, should receive rest of swaps only", async () => {
        await testCasePaginationPayFixed(
            [admin, userOne, userTwo, userThree, liquidityProvider, miltonStorageAddress],
            BigNumber.from("22"),
            BigNumber.from("20"),
            BigNumber.from("10"),
            BigNumber.from("2"),
            null,
            miltonSpreadModel
        );
    });

    it("get swaps - pay fixed, should receive empty list of swaps when offset is equal to number of swaps", async () => {
        await testCasePaginationPayFixed(
            [admin, userOne, userTwo, userThree, liquidityProvider, miltonStorageAddress],
            BigNumber.from("20"),
            BigNumber.from("20"),
            BigNumber.from("10"),
            ZERO,
            null,
            miltonSpreadModel
        );
    });

    it("get swaps - receive fixed, should fail when page size is equal 0", async () => {
        await testCasePaginationReceiveFixed(
            [admin, userOne, userTwo, userThree, liquidityProvider, miltonStorageAddress],
            ZERO,
            ZERO,
            ZERO,
            ZERO,
            "IPOR_009",
            miltonSpreadModel
        );
    });

    it("get swaps - receive fixed, should return empty list of swaps", async () => {
        await testCasePaginationReceiveFixed(
            [admin, userOne, userTwo, userThree, liquidityProvider, miltonStorageAddress],
            ZERO,
            ZERO,
            BigNumber.from("10"),
            ZERO,
            null,
            miltonSpreadModel
        );
    });

    it("get swaps - receive fixed, should receive empty list of swaps when user passes non zero offset and doesn't have any swap", async () => {
        await testCasePaginationReceiveFixed(
            [admin, userOne, userTwo, userThree, liquidityProvider, miltonStorageAddress],
            ZERO,
            BigNumber.from("10"),
            BigNumber.from("10"),
            ZERO,
            null,
            miltonSpreadModel
        );
    });

    it("get swaps - receive fixed, should receive limited swap array", async () => {
        await testCasePaginationReceiveFixed(
            [admin, userOne, userTwo, userThree, liquidityProvider, miltonStorageAddress],
            BigNumber.from("11"),
            BigNumber.from("10"),
            BigNumber.from("10"),
            ZERO,
            null,
            miltonSpreadModel
        );
    });

    it("get swaps - receive fixed, should receive limited swap array with offset", async () => {
        await testCasePaginationReceiveFixed(
            [admin, userOne, userTwo, userThree, liquidityProvider, miltonStorageAddress],
            BigNumber.from("22"),
            BigNumber.from("10"),
            BigNumber.from("10"),
            ZERO,
            null,
            miltonSpreadModel
        );
    });

    it("get swaps - receive fixed, should receive rest of swaps only", async () => {
        await testCasePaginationReceiveFixed(
            [admin, userOne, userTwo, userThree, liquidityProvider, miltonStorageAddress],
            BigNumber.from("22"),
            BigNumber.from("20"),
            BigNumber.from("10"),
            BigNumber.from("2"),
            null,
            miltonSpreadModel
        );
    });

    it("get swaps - receive fixed, should receive empty list of swaps when offset is equal to number of swaps", async () => {
        await testCasePaginationReceiveFixed(
            [admin, userOne, userTwo, userThree, liquidityProvider, miltonStorageAddress],
            BigNumber.from("20"),
            BigNumber.from("20"),
            BigNumber.from("10"),
            ZERO,
            null,
            miltonSpreadModel
        );
    });

    it("get swap ids - pay fixed, should fail when page size is equal 0", async () => {
        await testCaseIdsPaginationPayFixed(
            [admin, userOne, userTwo, userThree, liquidityProvider, miltonStorageAddress],
            ZERO,
            ZERO,
            ZERO,
            ZERO,
            "IPOR_009",
            miltonSpreadModel
        );
    });

    it("get swap ids - pay fixed, should return empty list of swaps", async () => {
        await testCaseIdsPaginationPayFixed(
            [admin, userOne, userTwo, userThree, liquidityProvider, miltonStorageAddress],
            ZERO,
            ZERO,
            BigNumber.from("10"),
            ZERO,
            null,
            miltonSpreadModel
        );
    });

    it("get swap ids - pay fixed, should receive empty list of swaps when user passes non zero offset and doesn't have any swap", async () => {
        await testCaseIdsPaginationPayFixed(
            [admin, userOne, userTwo, userThree, liquidityProvider, miltonStorageAddress],
            ZERO,
            BigNumber.from("10"),
            BigNumber.from("10"),
            ZERO,
            null,
            miltonSpreadModel
        );
    });

    it("get swap ids - pay fixed, should receive limited swap array", async () => {
        await testCaseIdsPaginationPayFixed(
            [admin, userOne, userTwo, userThree, liquidityProvider, miltonStorageAddress],
            BigNumber.from("11"),
            ZERO,
            BigNumber.from("10"),
            BigNumber.from("10"),
            null,
            miltonSpreadModel
        );
    });

    it("get swap ids - pay fixed, should receive limited swap array with offset", async () => {
        await testCaseIdsPaginationPayFixed(
            [admin, userOne, userTwo, userThree, liquidityProvider, miltonStorageAddress],
            BigNumber.from("22"),
            BigNumber.from("10"),
            BigNumber.from("10"),
            BigNumber.from("10"),
            null,
            miltonSpreadModel
        );
    });

    it("get swap ids - pay fixed, should receive rest of swaps only", async () => {
        await testCaseIdsPaginationPayFixed(
            [admin, userOne, userTwo, userThree, liquidityProvider, miltonStorageAddress],
            BigNumber.from("22"),
            BigNumber.from("20"),
            BigNumber.from("10"),
            BigNumber.from("2"),
            null,
            miltonSpreadModel
        );
    });

    it("get swap ids - pay fixed, should receive empty list of swaps when offset is equal to number of swaps", async () => {
        await testCaseIdsPaginationPayFixed(
            [admin, userOne, userTwo, userThree, liquidityProvider, miltonStorageAddress],
            BigNumber.from("20"),
            BigNumber.from("20"),
            BigNumber.from("10"),
            ZERO,
            null,
            miltonSpreadModel
        );
    });

    it("get swap ids - receive fixed, should fail when page size is equal 0", async () => {
        await testCaseIdsPaginationReceiveFixed(
            [admin, userOne, userTwo, userThree, liquidityProvider, miltonStorageAddress],
            ZERO,
            ZERO,
            ZERO,
            ZERO,
            "IPOR_009",
            miltonSpreadModel
        );
    });

    it("get swap ids - receive fixed, should return empty list of swaps", async () => {
        await testCaseIdsPaginationReceiveFixed(
            [admin, userOne, userTwo, userThree, liquidityProvider, miltonStorageAddress],
            ZERO,
            ZERO,
            BigNumber.from("10"),
            ZERO,
            null,
            miltonSpreadModel
        );
    });

    it("get swap ids - receive fixed, should receive empty list of swaps when user passes non zero offset and doesn't have any swap", async () => {
        await testCaseIdsPaginationReceiveFixed(
            [admin, userOne, userTwo, userThree, liquidityProvider, miltonStorageAddress],
            ZERO,
            BigNumber.from("10"),
            BigNumber.from("10"),
            ZERO,
            null,
            miltonSpreadModel
        );
    });

    it("get swap ids - receive fixed, should receive limited swap array", async () => {
        await testCaseIdsPaginationReceiveFixed(
            [admin, userOne, userTwo, userThree, liquidityProvider, miltonStorageAddress],
            BigNumber.from("11"),
            ZERO,
            BigNumber.from("10"),
            BigNumber.from("10"),
            null,
            miltonSpreadModel
        );
    });

    it("get swap ids - receive fixed, should receive limited swap array with offset", async () => {
        await testCaseIdsPaginationReceiveFixed(
            [admin, userOne, userTwo, userThree, liquidityProvider, miltonStorageAddress],
            BigNumber.from("22"),
            BigNumber.from("10"),
            BigNumber.from("10"),
            BigNumber.from("10"),
            null,
            miltonSpreadModel
        );
    });

    it("get swap ids - receive fixed, should receive rest of swaps only", async () => {
        await testCaseIdsPaginationReceiveFixed(
            [admin, userOne, userTwo, userThree, liquidityProvider, miltonStorageAddress],
            BigNumber.from("22"),
            BigNumber.from("20"),
            BigNumber.from("10"),
            BigNumber.from("2"),
            null,
            miltonSpreadModel
        );
    });

    it("get swap ids - receive fixed, should receive empty list of swaps when offset is equal to number of swaps", async () => {
        await testCaseIdsPaginationReceiveFixed(
            [admin, userOne, userTwo, userThree, liquidityProvider, miltonStorageAddress],
            BigNumber.from("20"),
            BigNumber.from("20"),
            BigNumber.from("10"),
            ZERO,
            null,
            miltonSpreadModel
        );
    });

    it("get swap ids - all, should fail when page size is equal 0", async () => {
        await testCaseIdsPagination(
            [admin, userOne, userTwo, userThree, liquidityProvider, miltonStorageAddress],
            ZERO,
            ZERO,
            ZERO,
            ZERO,
            ZERO,
            "IPOR_009",
            miltonSpreadModel
        );
    });

    it("get swap ids - all, should receive empty list of swap ids", async () => {
        await testCaseIdsPagination(
            [admin, userOne, userTwo, userThree, liquidityProvider, miltonStorageAddress],
            ZERO,
            ZERO,
            ZERO,
            BigNumber.from("10"),
            ZERO,
            null,
            miltonSpreadModel
        );
    });

    it("get swap ids - all, should receive empty list of swap ids when user passes non zero offset and doesn't have any swap", async () => {
        await testCaseIdsPagination(
            [admin, userOne, userTwo, userThree, liquidityProvider, miltonStorageAddress],
            ZERO,
            ZERO,
            BigNumber.from("10"),
            BigNumber.from("10"),
            ZERO,
            null,
            miltonSpreadModel
        );
    });

    it("get swap ids - all, should return pay fixed swaps if user doesn't have receive fixed swaps", async () => {
        await testCaseIdsPagination(
            [admin, userOne, userTwo, userThree, liquidityProvider, miltonStorageAddress],
            BigNumber.from("5"),
            ZERO,
            ZERO,
            BigNumber.from("10"),
            BigNumber.from("5"),
            null,
            miltonSpreadModel
        );
    });

    it("get swap ids - all, should return receive fixed swaps if user doesn't have pay fixed swaps", async () => {
        await testCaseIdsPagination(
            [admin, userOne, userTwo, userThree, liquidityProvider, miltonStorageAddress],
            ZERO,
            BigNumber.from("5"),
            ZERO,
            BigNumber.from("10"),
            BigNumber.from("5"),
            null,
            miltonSpreadModel
        );
    });

    it("get swap ids - all, should return all swaps", async () => {
        await testCaseIdsPagination(
            [admin, userOne, userTwo, userThree, liquidityProvider, miltonStorageAddress],
            BigNumber.from("3"),
            BigNumber.from("3"),
            ZERO,
            BigNumber.from("10"),
            BigNumber.from("6"),
            null,
            miltonSpreadModel
        );
    });

    it("get swap ids - all, should return limited swap id array if user has more swaps than page size", async () => {
        await testCaseIdsPagination(
            [admin, userOne, userTwo, userThree, liquidityProvider, miltonStorageAddress],
            BigNumber.from("9"),
            BigNumber.from("12"),
            ZERO,
            BigNumber.from("10"),
            BigNumber.from("10"),
            null,
            miltonSpreadModel
        );
    });

    it("get swap ids - all, should return empty array when offset is higher than total number of user swaps", async () => {
        await testCaseIdsPagination(
            [admin, userOne, userTwo, userThree, liquidityProvider, miltonStorageAddress],
            BigNumber.from("9"),
            BigNumber.from("12"),
            BigNumber.from("80"),
            BigNumber.from("10"),
            ZERO,
            null,
            miltonSpreadModel
        );
    });
});

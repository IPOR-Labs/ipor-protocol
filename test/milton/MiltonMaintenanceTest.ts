import hre from "hardhat";
import chai from "chai";
import { Signer, BigNumber } from "ethers";
import { PERCENTAGE_3_18DEC, USD_28_000_18DEC, USD_50_000_18DEC } from "../utils/Constants";
import {
    MockMiltonSpreadModel,
    MiltonSpreadModels,
    prepareMockMiltonSpreadModel,
    MiltonUsdcCase,
    MiltonUsdtCase,
    MiltonDaiCase,
} from "../utils/MiltonUtils";
import { assertError } from "../utils/AssertUtils";
import {
    prepareComplexTestDataDaiCase000,
    prepareTestDataDaiCase000,
    getPayFixedDerivativeParamsDAICase1,
    prepareTestData,
} from "../utils/DataUtils";
import { MockStanleyCase } from "../utils/StanleyUtils";
import { JosephUsdcMockCases, JosephUsdtMockCases, JosephDaiMockCases } from "../utils/JosephUtils";

const { expect } = chai;

describe("Milton Maintenance", () => {
    let miltonSpreadModel: MockMiltonSpreadModel;
    let admin: Signer,
        userOne: Signer,
        userTwo: Signer,
        userThree: Signer,
        liquidityProvider: Signer;

    before(async () => {
        [admin, userOne, userTwo, userThree, liquidityProvider] = await hre.ethers.getSigners();
        miltonSpreadModel = await prepareMockMiltonSpreadModel(MiltonSpreadModels.CASE1);
    });

    it("should pause Smart Contract, sender is an admin", async () => {
        //given
        const { tokenDai, warren, josephDai, miltonDai } = await prepareComplexTestDataDaiCase000(
            [admin, userOne, userTwo, userThree, liquidityProvider],
            miltonSpreadModel
        );

        if (tokenDai === undefined || josephDai === undefined || miltonDai === undefined) {
            expect(true).to.be.false;
            return;
        }

        const params = getPayFixedDerivativeParamsDAICase1(userTwo, tokenDai);

        await warren
            .connect(userOne)
            .itfUpdateIndex(params.asset, PERCENTAGE_3_18DEC, params.openTimestamp);

        await josephDai
            .connect(liquidityProvider)
            .itfProvideLiquidity(USD_28_000_18DEC, params.openTimestamp);

        //when
        await miltonDai.connect(admin).pause();

        //then
        await assertError(
            miltonDai
                .connect(userOne)
                .openSwapPayFixed(
                    params.totalAmount,
                    params.maxAcceptableFixedInterestRate,
                    params.leverage
                ),
            "Pausable: paused"
        );
    });

    it("should pause Smart Contract specific methods", async () => {
        //given
        const { tokenDai, warren, josephDai, miltonDai } = await prepareComplexTestDataDaiCase000(
            [admin, userOne, userTwo, userThree, liquidityProvider],
            miltonSpreadModel
        );

        if (tokenDai === undefined || josephDai === undefined || miltonDai === undefined) {
            expect(true).to.be.false;
            return;
        }

        const params = getPayFixedDerivativeParamsDAICase1(userTwo, tokenDai);

        await warren
            .connect(userOne)
            .itfUpdateIndex(params.asset, PERCENTAGE_3_18DEC, params.openTimestamp);

        await josephDai
            .connect(liquidityProvider)
            .itfProvideLiquidity(USD_28_000_18DEC, params.openTimestamp);

        //simulate that userTwo is a Joseph
        await miltonDai.connect(admin).setJoseph(await userTwo.getAddress());

        //when
        await miltonDai.connect(admin).pause();

        //then
        await assertError(
            miltonDai
                .connect(userOne)
                .openSwapPayFixed(
                    params.totalAmount,
                    params.maxAcceptableFixedInterestRate,
                    params.leverage
                ),
            "Pausable: paused"
        );

        await assertError(
            miltonDai
                .connect(userOne)
                .openSwapReceiveFixed(
                    params.totalAmount,
                    params.maxAcceptableFixedInterestRate,
                    params.leverage
                ),
            "Pausable: paused"
        );

        await assertError(miltonDai.connect(userOne).closeSwapPayFixed(1), "Pausable: paused");

        await assertError(miltonDai.connect(userOne).closeSwapReceiveFixed(1), "Pausable: paused");

        await assertError(
            miltonDai.connect(userOne).closeSwapsPayFixed([1, 2]),
            "Pausable: paused"
        );

        await assertError(
            miltonDai.connect(userOne).closeSwapsReceiveFixed([1, 2]),
            "Pausable: paused"
        );

        await assertError(miltonDai.connect(userTwo).depositToStanley(1), "Pausable: paused");

        await assertError(miltonDai.connect(userTwo).withdrawFromStanley(1), "Pausable: paused");

        await assertError(
            miltonDai.connect(admin).setupMaxAllowanceForAsset(await userThree.getAddress()),
            "Pausable: paused"
        );

        await assertError(
            miltonDai.connect(admin).setJoseph(await userThree.getAddress()),
            "Pausable: paused"
        );
    });

    it("should NOT pause Smart Contract specific methods when paused", async () => {
        //given
        const { tokenDai, warren, josephDai, miltonDai, miltonStorageDai } =
            await prepareComplexTestDataDaiCase000(
                [admin, userOne, userTwo, userThree, liquidityProvider],
                miltonSpreadModel
            );

        if (
            tokenDai === undefined ||
            josephDai === undefined ||
            miltonDai === undefined ||
            miltonStorageDai === undefined
        ) {
            expect(true).to.be.false;
            return;
        }

        const params = getPayFixedDerivativeParamsDAICase1(userTwo, tokenDai);

        await warren
            .connect(userOne)
            .itfUpdateIndex(params.asset, PERCENTAGE_3_18DEC, params.openTimestamp);

        await josephDai
            .connect(liquidityProvider)
            .itfProvideLiquidity(USD_50_000_18DEC, params.openTimestamp);

        await miltonDai
            .connect(userTwo)
            .itfOpenSwapPayFixed(
                params.openTimestamp,
                params.totalAmount,
                params.maxAcceptableFixedInterestRate,
                params.leverage
            );
        const swapPayFixed = await miltonStorageDai.connect(userTwo).getSwapPayFixed(1);

        await miltonDai
            .connect(userTwo)
            .itfOpenSwapReceiveFixed(
                params.openTimestamp,
                params.totalAmount,
                params.maxAcceptableFixedInterestRate,
                params.leverage
            );

        const swapReceiveFixed = await miltonStorageDai.connect(userTwo).getSwapReceiveFixed(1);

        //when
        await miltonDai.connect(admin).pause();

        //then
        await miltonDai.connect(userOne).getVersion();
        await miltonDai.connect(userOne).getAccruedBalance();
        await miltonDai.connect(userOne).calculateSpread();
        await miltonDai.connect(userOne).calculateSoap();
        await miltonDai.connect(userOne).calculateSoapAtTimestamp(params.openTimestamp);
        await miltonDai.connect(userOne).calculateSwapPayFixedValue(swapPayFixed);
        await miltonDai.connect(userOne).calculateSwapReceiveFixedValue(swapReceiveFixed);
        await miltonDai.connect(userOne).getMiltonSpreadModel();
        await miltonDai.connect(userOne).getMaxSwapCollateralAmount();
        await miltonDai.connect(userOne).getMaxLpUtilizationRate();
        await miltonDai.connect(userOne).getMaxLpUtilizationPerLegRate();
        await miltonDai.connect(userOne).getIncomeFeeRate();
        await miltonDai.connect(userOne).getOpeningFeeRate();
        await miltonDai.connect(userOne).getOpeningFeeTreasuryPortionRate();
        await miltonDai.connect(userOne).getIporPublicationFee();
        await miltonDai.connect(userOne).getLiquidationDepositAmount();
        await miltonDai.connect(userOne).getMaxLeverage();
        await miltonDai.connect(userOne).getMinLeverage();
        await miltonDai.connect(userOne).getJoseph();
    });

    it("should NOT pause Smart Contract, sender is NOT an admin", async () => {
        //given
        const { miltonDai } = await prepareTestDataDaiCase000(
            [admin, userOne, userTwo, userThree, liquidityProvider],
            miltonSpreadModel
        );

        if (miltonDai === undefined) {
            expect(true).to.be.false;
            return;
        }

        //when
        await assertError(
            miltonDai.connect(userThree).pause(),
            //then
            "Ownable: caller is not the owner"
        );
    });

    it("should unpause Smart Contract, sender is an admin", async () => {
        //given
        const { tokenDai, warren, josephDai, miltonDai, miltonStorageDai } =
            await prepareComplexTestDataDaiCase000(
                [admin, userOne, userTwo, userThree, liquidityProvider],
                miltonSpreadModel
            );

        if (
            tokenDai === undefined ||
            josephDai === undefined ||
            miltonDai === undefined ||
            miltonStorageDai === undefined
        ) {
            expect(true).to.be.false;
            return;
        }

        const params = getPayFixedDerivativeParamsDAICase1(userTwo, tokenDai);
        const timestamp = params.openTimestamp;
        await warren.connect(userOne).itfUpdateIndex(params.asset, PERCENTAGE_3_18DEC, timestamp);

        await josephDai.connect(liquidityProvider).itfProvideLiquidity(USD_50_000_18DEC, timestamp);

        await miltonDai.connect(admin).pause();

        await assertError(
            miltonDai
                .connect(userTwo)
                .openSwapPayFixed(
                    params.totalAmount,
                    params.maxAcceptableFixedInterestRate,
                    params.leverage
                ),
            "Pausable: paused"
        );

        const expectedCollateral = BigNumber.from("9967009897030890732780");

        //when
        await miltonDai.connect(admin).unpause();
        await miltonDai
            .connect(userTwo)
            .openSwapPayFixed(
                params.totalAmount,
                params.maxAcceptableFixedInterestRate,
                params.leverage
            );

        //then
        const swapPayFixed = await miltonStorageDai.connect(userTwo).getSwapPayFixed(1);
        const actualCollateral = swapPayFixed.collateral;

        expect(actualCollateral, "Incorrect collateral").to.be.eql(expectedCollateral);
    });

    it("should NOT unpause Smart Contract, sender is NOT an admin", async () => {
        //given
        const { miltonDai } = await prepareTestDataDaiCase000(
            [admin, userOne, userTwo, userThree, liquidityProvider],
            miltonSpreadModel
        );
        if (miltonDai === undefined) {
            expect(true).to.be.false;
            return;
        }

        await miltonDai.connect(admin).pause();

        //when
        await assertError(
            miltonDai.connect(userThree).unpause(),
            //then
            "Ownable: caller is not the owner"
        );
    });

    it("should transfer ownership - simple case 1", async () => {
        //given
        const { miltonDai } = await prepareTestDataDaiCase000(
            [admin, userOne, userTwo, userThree, liquidityProvider],
            miltonSpreadModel
        );
        const expectedNewOwner = userTwo;
        if (miltonDai === undefined) {
            expect(true).to.be.false;
            return;
        }

        //when
        await miltonDai.connect(admin).transferOwnership(await expectedNewOwner.getAddress());

        await miltonDai.connect(expectedNewOwner).confirmTransferOwnership();

        //then
        const actualNewOwner = await miltonDai.connect(userOne).owner();
        expect(await expectedNewOwner.getAddress()).to.be.eql(actualNewOwner);
    });

    it("should NOT transfer ownership - sender not current owner", async () => {
        //given
        const { miltonDai } = await prepareTestDataDaiCase000(
            [admin, userOne, userTwo, userThree, liquidityProvider],
            miltonSpreadModel
        );
        const expectedNewOwner = userTwo;
        if (miltonDai === undefined) {
            expect(true).to.be.false;
            return;
        }

        //when
        await assertError(
            miltonDai.connect(userThree).transferOwnership(await expectedNewOwner.getAddress()),
            //then
            "Ownable: caller is not the owner"
        );
    });

    it("should NOT confirm transfer ownership - sender not appointed owner", async () => {
        //given
        const { miltonDai } = await prepareTestDataDaiCase000(
            [admin, userOne, userTwo, userThree, liquidityProvider],
            miltonSpreadModel
        );
        const expectedNewOwner = userTwo;
        if (miltonDai === undefined) {
            expect(true).to.be.false;
            return;
        }
        //when
        await miltonDai.connect(admin).transferOwnership(await expectedNewOwner.getAddress());

        await assertError(
            miltonDai.connect(userThree).confirmTransferOwnership(),
            //then
            "IPOR_007"
        );
    });

    it("should NOT confirm transfer ownership twice - sender not appointed owner", async () => {
        //given
        const { miltonDai } = await prepareTestDataDaiCase000(
            [admin, userOne, userTwo, userThree, liquidityProvider],
            miltonSpreadModel
        );
        const expectedNewOwner = userTwo;
        if (miltonDai === undefined) {
            expect(true).to.be.false;
            return;
        }
        //when
        await miltonDai.connect(admin).transferOwnership(await expectedNewOwner.getAddress());

        await miltonDai.connect(expectedNewOwner).confirmTransferOwnership();

        await assertError(
            miltonDai.connect(expectedNewOwner).confirmTransferOwnership(),
            "IPOR_007"
        );
    });

    it("should NOT transfer ownership - sender already lost ownership", async () => {
        //given
        const { miltonDai } = await prepareTestDataDaiCase000(
            [admin, userOne, userTwo, userThree, liquidityProvider],
            miltonSpreadModel
        );
        const expectedNewOwner = userTwo;
        if (miltonDai === undefined) {
            expect(true).to.be.false;
            return;
        }
        await miltonDai.connect(admin).transferOwnership(await expectedNewOwner.getAddress());

        await miltonDai.connect(expectedNewOwner).confirmTransferOwnership();

        //when
        await assertError(
            miltonDai.connect(admin).transferOwnership(await expectedNewOwner.getAddress()),
            //then
            "Ownable: caller is not the owner"
        );
    });

    it("should have rights to transfer ownership - sender still have rights", async () => {
        //given
        const { miltonDai } = await prepareTestDataDaiCase000(
            [admin, userOne, userTwo, userThree, liquidityProvider],
            miltonSpreadModel
        );
        const expectedNewOwner = userTwo;
        if (miltonDai === undefined) {
            expect(true).to.be.false;
            return;
        }
        await miltonDai.connect(admin).transferOwnership(await expectedNewOwner.getAddress());

        //when
        await miltonDai.connect(admin).transferOwnership(await expectedNewOwner.getAddress());

        //then
        const actualNewOwner = await miltonDai.connect(userOne).owner();
        expect(await admin.getAddress()).to.be.eql(actualNewOwner);
    });

    it("should not sent ETH to Milton DAI, USDT, USDC", async () => {
        //given
        const { miltonDai, miltonUsdt, miltonUsdc } = await prepareTestData(
            [admin],
            ["DAI", "USDT", "USDC"],
            miltonSpreadModel,
            MiltonUsdcCase.CASE0,
            MiltonUsdtCase.CASE0,
            MiltonDaiCase.CASE0,
            MockStanleyCase.CASE0,
            JosephUsdcMockCases.CASE0,
            JosephUsdtMockCases.CASE0,
            JosephDaiMockCases.CASE0
        );

        if (miltonDai === undefined || miltonUsdt === undefined || miltonUsdc === undefined) {
            expect(true).to.be.false;
            return;
        }

        await assertError(
            //when
            admin.sendTransaction({
                to: miltonDai.address,
                value: hre.ethers.utils.parseEther("1.0"),
            }),
            //then
            "Transaction reverted: function selector was not recognized and there's no fallback nor receive function"
        );

        await assertError(
            //when
            admin.sendTransaction({
                to: miltonUsdt.address,
                value: hre.ethers.utils.parseEther("1.0"),
            }),
            //then
            "Transaction reverted: function selector was not recognized and there's no fallback nor receive function"
        );

        await assertError(
            //when
            admin.sendTransaction({
                to: miltonUsdc.address,
                value: hre.ethers.utils.parseEther("1.0"),
            }),
            //then
            "Transaction reverted: function selector was not recognized and there's no fallback nor receive function"
        );
    });

    it("should not sent ETH to MiltonStorage DAI, USDT, USDC", async () => {
        //given
        const { miltonStorageDai, miltonStorageUsdt, miltonStorageUsdc } = await prepareTestData(
            [admin],
            ["DAI", "USDT", "USDC"],
            miltonSpreadModel,
            MiltonUsdcCase.CASE0,
            MiltonUsdtCase.CASE0,
            MiltonDaiCase.CASE0,
            MockStanleyCase.CASE0,
            JosephUsdcMockCases.CASE0,
            JosephUsdtMockCases.CASE0,
            JosephDaiMockCases.CASE0
        );

        if (
            miltonStorageDai === undefined ||
            miltonStorageUsdt === undefined ||
            miltonStorageUsdc === undefined
        ) {
            expect(true).to.be.false;
            return;
        }

        await assertError(
            //when
            admin.sendTransaction({
                to: miltonStorageDai.address,
                value: hre.ethers.utils.parseEther("1.0"),
            }),
            //then
            "Transaction reverted: function selector was not recognized and there's no fallback nor receive function"
        );

        await assertError(
            //when
            admin.sendTransaction({
                to: miltonStorageUsdt.address,
                value: hre.ethers.utils.parseEther("1.0"),
            }),
            //then
            "Transaction reverted: function selector was not recognized and there's no fallback nor receive function"
        );

        await assertError(
            //when
            admin.sendTransaction({
                to: miltonStorageUsdc.address,
                value: hre.ethers.utils.parseEther("1.0"),
            }),
            //then
            "Transaction reverted: function selector was not recognized and there's no fallback nor receive function"
        );
    });
});

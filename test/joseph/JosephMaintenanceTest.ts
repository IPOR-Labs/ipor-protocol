import hre from "hardhat";
import chai from "chai";
import { Signer, BigNumber } from "ethers";
import { TC_TOTAL_AMOUNT_10_000_18DEC } from "../utils/Constants";
import { assertError } from "../utils/AssertUtils";
import {
    MockMiltonSpreadModel,
    MiltonSpreadModels,
    MiltonUsdcCase,
    MiltonUsdtCase,
    MiltonDaiCase,
    prepareMockMiltonSpreadModel,
} from "../utils/MiltonUtils";
import {
    prepareTestData,
    prepareTestDataDaiCase000,
    prepareComplexTestDataDaiCase000,
} from "../utils/DataUtils";
import { MockStanleyCase } from "../utils/StanleyUtils";
import { JosephUsdcMockCases, JosephUsdtMockCases, JosephDaiMockCases } from "../utils/JosephUtils";

const { expect } = chai;

describe("Joseph Maintenance", () => {
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
        //when
        const { josephDai } = await prepareTestData(
            [admin, userOne, userTwo, userThree, liquidityProvider],
            ["DAI"],
            miltonSpreadModel,
            MiltonUsdcCase.CASE1,
            MiltonUsdtCase.CASE1,
            MiltonDaiCase.CASE1,
            MockStanleyCase.CASE1,
            JosephUsdcMockCases.CASE0,
            JosephUsdtMockCases.CASE0,
            JosephDaiMockCases.CASE0
        );

        if (josephDai === undefined) {
            expect(true).to.be.false;
            return;
        }

        await josephDai.connect(admin).pause();

        //then
        await assertError(josephDai.connect(userOne).provideLiquidity(123), "Pausable: paused");
    });

    it("should pause Smart Contract specific methods", async () => {
        //given
        const { josephDai } = await prepareTestData(
            [admin, userOne, userTwo, userThree, liquidityProvider],
            ["DAI"],
            miltonSpreadModel,
            MiltonUsdcCase.CASE1,
            MiltonUsdtCase.CASE1,
            MiltonDaiCase.CASE1,
            MockStanleyCase.CASE1,
            JosephUsdcMockCases.CASE0,
            JosephUsdtMockCases.CASE0,
            JosephDaiMockCases.CASE0
        );

        if (josephDai === undefined) {
            expect(true).to.be.false;
            return;
        }

        //when
        await josephDai.connect(admin).pause();

        //then
        await assertError(josephDai.connect(admin).rebalance(), "Pausable: paused");

        await assertError(josephDai.connect(admin).depositToStanley(123), "Pausable: paused");

        await assertError(josephDai.connect(admin).withdrawFromStanley(123), "Pausable: paused");

        await assertError(josephDai.connect(userOne).provideLiquidity(123), "Pausable: paused");

        await assertError(josephDai.connect(userOne).redeem(123), "Pausable: paused");

        await assertError(josephDai.connect(userOne).transferToTreasury(123), "Pausable: paused");

        await assertError(
            josephDai.connect(userOne).transferToCharlieTreasury(123),
            "Pausable: paused"
        );

        await assertError(
            josephDai.connect(admin).setCharlieTreasury(await userTwo.getAddress()),
            "Pausable: paused"
        );
        await assertError(
            josephDai.connect(admin).setTreasury(await userTwo.getAddress()),
            "Pausable: paused"
        );
        await assertError(
            josephDai.connect(admin).setCharlieTreasuryManager(await userTwo.getAddress()),
            "Pausable: paused"
        );
        await assertError(
            josephDai.connect(admin).setTreasuryManager(await userTwo.getAddress()),
            "Pausable: paused"
        );
    });

    it("should NOT pause Smart Contract specific methods when paused", async () => {
        //given
        const { josephDai } = await prepareComplexTestDataDaiCase000(
            [admin, userOne, userTwo, userThree, liquidityProvider],
            miltonSpreadModel
        );

        if (josephDai === undefined) {
            expect(true).to.be.false;
            return;
        }

        const timestamp = Math.floor(Date.now() / 1000);

        await josephDai
            .connect(liquidityProvider)
            .itfProvideLiquidity(TC_TOTAL_AMOUNT_10_000_18DEC, timestamp);

        //when
        await josephDai.connect(admin).pause();

        //then
        await josephDai.connect(userOne).getVersion();
        await josephDai.connect(userOne).checkVaultReservesRatio();
        await josephDai.connect(userOne).getCharlieTreasury();
        await josephDai.connect(userOne).getTreasury();
        await josephDai.connect(userOne).getCharlieTreasuryManager();
        await josephDai.connect(userOne).getTreasuryManager();
        await josephDai.connect(userOne).getRedeemLpMaxUtilizationRate();
        await josephDai.connect(userOne).getMiltonStanleyBalanceRatio();
        await josephDai.connect(userOne).getAsset();
        await josephDai.connect(userOne).calculateExchangeRate();
    });

    it("should NOT pause Smart Contract, sender is NOT an admin", async () => {
        //given
        const { josephDai } = await prepareTestDataDaiCase000(
            [admin, userOne, userTwo, userThree, liquidityProvider],
            miltonSpreadModel
        );

        if (josephDai === undefined) {
            expect(true).to.be.false;
            return;
        }

        //when
        await assertError(
            josephDai.connect(userThree).pause(),
            //then
            "Ownable: caller is not the owner"
        );
    });

    it("should unpause Smart Contract, sender is an admin", async () => {
        //given
        const { josephDai, ipTokenDai } = await prepareComplexTestDataDaiCase000(
            [admin, userOne, userTwo, userThree, liquidityProvider],
            miltonSpreadModel
        );

        if (josephDai === undefined || ipTokenDai === undefined) {
            expect(true).to.be.false;
            return;
        }

        await josephDai.connect(admin).pause();

        await assertError(josephDai.connect(userOne).provideLiquidity(123), "Pausable: paused");

        const expectedIpTokenBalance = BigNumber.from("123");

        //when
        await josephDai.connect(admin).unpause();
        await josephDai.connect(userOne).provideLiquidity(123);

        //then
        const actualIpTokenBalance = await ipTokenDai.balanceOf(await userOne.getAddress());
        expect(actualIpTokenBalance, "Incorrect IpToken balance.").to.be.eql(
            expectedIpTokenBalance
        );
    });

    it("should NOT unpause Smart Contract, sender is NOT an admin", async () => {
        //given
        const { josephDai } = await prepareTestDataDaiCase000(
            [admin, userOne, userTwo, userThree, liquidityProvider],
            miltonSpreadModel
        );

        if (josephDai === undefined) {
            expect(true).to.be.false;
            return;
        }

        await josephDai.connect(admin).pause();

        //when
        await assertError(
            josephDai.connect(userThree).unpause(),
            //then
            "Ownable: caller is not the owner"
        );
    });

    it("should transfer ownership - simple case 1", async () => {
        //given
        const { josephDai } = await prepareTestDataDaiCase000(
            [admin, userOne, userTwo, userThree, liquidityProvider],
            miltonSpreadModel
        );
        if (josephDai === undefined) {
            expect(true).to.be.false;
            return;
        }
        const expectedNewOwner = userTwo;

        //when
        await josephDai.connect(admin).transferOwnership(await expectedNewOwner.getAddress());

        await josephDai.connect(expectedNewOwner).confirmTransferOwnership();

        //then
        const actualNewOwner = await josephDai.connect(userOne).owner();
        expect(await expectedNewOwner.getAddress()).to.be.eql(actualNewOwner);
    });

    it("should NOT transfer ownership - sender not current owner", async () => {
        //given
        const { josephDai } = await prepareTestDataDaiCase000(
            [admin, userOne, userTwo, userThree, liquidityProvider],
            miltonSpreadModel
        );

        if (josephDai === undefined) {
            expect(true).to.be.false;
            return;
        }
        const expectedNewOwner = userTwo;

        //when
        await assertError(
            josephDai.connect(userThree).transferOwnership(await expectedNewOwner.getAddress()),
            //then
            "Ownable: caller is not the owner"
        );
    });

    it("should NOT confirm transfer ownership - sender not appointed owner", async () => {
        //given
        const { josephDai } = await prepareTestDataDaiCase000(
            [admin, userOne, userTwo, userThree, liquidityProvider],
            miltonSpreadModel
        );

        if (josephDai === undefined) {
            expect(true).to.be.false;
            return;
        }
        const expectedNewOwner = userTwo;

        //when
        await josephDai.connect(admin).transferOwnership(await expectedNewOwner.getAddress());

        await assertError(
            josephDai.connect(userThree).confirmTransferOwnership(),
            //then
            "IPOR_007"
        );
    });

    it("should NOT confirm transfer ownership twice - sender not appointed owner", async () => {
        //given
        const { josephDai } = await prepareTestDataDaiCase000(
            [admin, userOne, userTwo, userThree, liquidityProvider],
            miltonSpreadModel
        );

        if (josephDai === undefined) {
            expect(true).to.be.false;
            return;
        }
        const expectedNewOwner = userTwo;

        //when
        await josephDai.connect(admin).transferOwnership(await expectedNewOwner.getAddress());

        await josephDai.connect(expectedNewOwner).confirmTransferOwnership();

        await assertError(
            josephDai.connect(expectedNewOwner).confirmTransferOwnership(),
            "IPOR_007"
        );
    });

    it("should NOT transfer ownership - sender already lost ownership", async () => {
        //given
        const { josephDai } = await prepareTestDataDaiCase000(
            [admin, userOne, userTwo, userThree, liquidityProvider],
            miltonSpreadModel
        );

        if (josephDai === undefined) {
            expect(true).to.be.false;
            return;
        }
        const expectedNewOwner = userTwo;

        await josephDai.connect(admin).transferOwnership(await expectedNewOwner.getAddress());

        await josephDai.connect(expectedNewOwner).confirmTransferOwnership();

        //when
        await assertError(
            josephDai.connect(admin).transferOwnership(await expectedNewOwner.getAddress()),
            //then
            "Ownable: caller is not the owner"
        );
    });

    it("should have rights to transfer ownership - sender still have rights", async () => {
        //given
        const { josephDai } = await prepareTestDataDaiCase000(
            [admin, userOne, userTwo, userThree, liquidityProvider],
            miltonSpreadModel
        );

        if (josephDai === undefined) {
            expect(true).to.be.false;
            return;
        }
        const expectedNewOwner = userTwo;

        await josephDai.connect(admin).transferOwnership(await expectedNewOwner.getAddress());

        //when
        await josephDai.connect(admin).transferOwnership(await expectedNewOwner.getAddress());

        //then
        const actualNewOwner = await josephDai.connect(userOne).owner();
        expect(await admin.getAddress()).to.be.eql(actualNewOwner);
    });

    it("should not sent ETH to Joseph DAI, USDT, USDC", async () => {
        //given
        const { josephDai, josephUsdt, josephUsdc } = await prepareTestData(
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

        if (josephDai === undefined || josephUsdt === undefined || josephUsdc === undefined) {
            expect(true).to.be.false;
            return;
        }

        await assertError(
            //when
            admin.sendTransaction({
                to: josephDai.address,
                value: hre.ethers.utils.parseEther("1.0"),
            }),
            //then
            "Transaction reverted: function selector was not recognized and there's no fallback nor receive function"
        );

        await assertError(
            //when
            admin.sendTransaction({
                to: josephUsdt.address,
                value: hre.ethers.utils.parseEther("1.0"),
            }),
            //then
            "Transaction reverted: function selector was not recognized and there's no fallback nor receive function"
        );

        await assertError(
            //when
            admin.sendTransaction({
                to: josephUsdc.address,
                value: hre.ethers.utils.parseEther("1.0"),
            }),
            //then
            "Transaction reverted: function selector was not recognized and there's no fallback nor receive function"
        );
    });
});

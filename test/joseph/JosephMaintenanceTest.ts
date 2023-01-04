import hre, { upgrades } from "hardhat";
import chai from "chai";
import { Signer, BigNumber } from "ethers";
import {
    JosephDai,
    JosephUsdc,
    JosephUsdt,
    TestERC20,
    IpToken,
    MockSpreadModel,
} from "../../types";
import {
    N0__01_18DEC,
    N1__0_18DEC,
    PERCENTAGE_3_18DEC,
    TC_TOTAL_AMOUNT_10_000_18DEC,
    ZERO,
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
    prepareTestDataDaiCase000,
    prepareComplexTestDataDaiCase000,
} from "../utils/DataUtils";
import { MockStanleyCase } from "../utils/StanleyUtils";
import { JosephUsdcMockCases, JosephUsdtMockCases, JosephDaiMockCases } from "../utils/JosephUtils";

const { expect } = chai;

describe("Joseph Maintenance", () => {
    let miltonSpreadModel: MockSpreadModel;
    let admin: Signer,
        userOne: Signer,
        userTwo: Signer,
        userThree: Signer,
        liquidityProvider: Signer;

    before(async () => {
        [admin, userOne, userTwo, userThree, liquidityProvider] = await hre.ethers.getSigners();
        miltonSpreadModel = await prepareMockSpreadModel(ZERO, ZERO, ZERO, ZERO);
    });

    it("should pause Smart Contract, sender is an admin", async () => {
        //when
        const { josephDai } = await prepareTestData(
            BigNumber.from(Math.floor(Date.now() / 1000)),
            [admin, userOne, userTwo, userThree, liquidityProvider],
            ["DAI"],
            [],
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
            BigNumber.from(Math.floor(Date.now() / 1000)),
            [admin, userOne, userTwo, userThree, liquidityProvider],
            ["DAI"],
            [PERCENTAGE_3_18DEC],
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

        await assertError(josephDai.connect(admin).withdrawAllFromStanley(), "Pausable: paused");

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
            BigNumber.from(Math.floor(Date.now() / 1000)),
            [admin, userOne, userTwo, userThree, liquidityProvider],
            miltonSpreadModel,
            PERCENTAGE_3_18DEC
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
            BigNumber.from(Math.floor(Date.now() / 1000)),
            [admin, userOne, userTwo, userThree, liquidityProvider],
            miltonSpreadModel,
            PERCENTAGE_3_18DEC
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
            BigNumber.from(Math.floor(Date.now() / 1000)),
            [admin, userOne, userTwo, userThree, liquidityProvider],
            miltonSpreadModel,
            PERCENTAGE_3_18DEC
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
        expect(actualIpTokenBalance, "Incorrect IpToken balance.").to.be.equal(
            expectedIpTokenBalance
        );
    });

    it("should NOT unpause Smart Contract, sender is NOT an admin", async () => {
        //given
        const { josephDai } = await prepareTestDataDaiCase000(
            BigNumber.from(Math.floor(Date.now() / 1000)),
            [admin, userOne, userTwo, userThree, liquidityProvider],
            miltonSpreadModel,
            PERCENTAGE_3_18DEC
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
            BigNumber.from(Math.floor(Date.now() / 1000)),
            [admin, userOne, userTwo, userThree, liquidityProvider],
            miltonSpreadModel,
            PERCENTAGE_3_18DEC
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
        expect(await expectedNewOwner.getAddress()).to.be.equal(actualNewOwner);
    });

    it("should NOT transfer ownership - sender not current owner", async () => {
        //given
        const { josephDai } = await prepareTestDataDaiCase000(
            BigNumber.from(Math.floor(Date.now() / 1000)),
            [admin, userOne, userTwo, userThree, liquidityProvider],
            miltonSpreadModel,
            PERCENTAGE_3_18DEC
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
            BigNumber.from(Math.floor(Date.now() / 1000)),
            [admin, userOne, userTwo, userThree, liquidityProvider],
            miltonSpreadModel,
            PERCENTAGE_3_18DEC
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
            BigNumber.from(Math.floor(Date.now() / 1000)),
            [admin, userOne, userTwo, userThree, liquidityProvider],
            miltonSpreadModel,
            PERCENTAGE_3_18DEC
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
            BigNumber.from(Math.floor(Date.now() / 1000)),
            [admin, userOne, userTwo, userThree, liquidityProvider],
            miltonSpreadModel,
            PERCENTAGE_3_18DEC
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
            BigNumber.from(Math.floor(Date.now() / 1000)),
            [admin, userOne, userTwo, userThree, liquidityProvider],
            miltonSpreadModel,
            PERCENTAGE_3_18DEC
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
        expect(await admin.getAddress()).to.be.equal(actualNewOwner);
    });

    it("should not sent ETH to Joseph DAI, USDT, USDC", async () => {
        //given
        const { josephDai, josephUsdt, josephUsdc } = await prepareTestData(
            BigNumber.from(Math.floor(Date.now() / 1000)),
            [admin],
            ["DAI", "USDT", "USDC"],
            [],
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

    it("should deploy JosephDai", async () => {
        // given
        const JosephDaiFactory = await hre.ethers.getContractFactory("JosephDai");
        const tokenFactory = await hre.ethers.getContractFactory("TestERC20");

        const dai = (await tokenFactory.deploy(BigNumber.from(2).pow(255))) as TestERC20;
        await dai.setDecimals(BigNumber.from("18"));
        const IpToken = await hre.ethers.getContractFactory("IpToken");
        const ipTokenDai = (await IpToken.deploy("IP DAI", "ipDai", dai.address)) as IpToken;

        // when
        const josephDai = await upgrades.deployProxy(
            JosephDaiFactory,
            [
                false,
                dai.address, // we check only this position the rest could be random
                ipTokenDai.address,
                dai.address,
                dai.address,
                dai.address,
            ],
            {
                kind: "uups",
            }
        );

        // then
        expect(josephDai.address).to.be.not.empty;
        expect(await josephDai.getAsset()).to.be.equal(dai.address);
    });

    it("should deploy JosephUsdc", async () => {
        // given
        const JosephUsdcFactory = await hre.ethers.getContractFactory("JosephUsdc");
        const tokenFactory = await hre.ethers.getContractFactory("TestERC20");

        const usdc = (await tokenFactory.deploy(BigNumber.from(2).pow(255))) as TestERC20;
        await usdc.setDecimals(BigNumber.from("6"));
        const IpToken = await hre.ethers.getContractFactory("IpToken");
        const ipTokenUsdc = (await IpToken.deploy("IP USDC", "ipUSDC", usdc.address)) as IpToken;

        // when
        const josephUsdc = (await upgrades.deployProxy(
            JosephUsdcFactory,
            [
                false,
                usdc.address, // we check only this position the rest could be random
                ipTokenUsdc.address,
                usdc.address,
                usdc.address,
                usdc.address,
            ],
            {
                kind: "uups",
            }
        )) as JosephUsdc;

        // then
        expect(josephUsdc.address).to.be.not.empty;
        expect(await josephUsdc.getAsset()).to.be.equal(usdc.address);
    });

    it("should deploy JosephUsdt", async () => {
        // given
        const JosephUsdtFactory = await hre.ethers.getContractFactory("JosephUsdt");
        const tokenFactory = await hre.ethers.getContractFactory("TestERC20");
        const usdt = (await tokenFactory.deploy(BigNumber.from(2).pow(255))) as TestERC20;
        await usdt.setDecimals(BigNumber.from("6"));
        const IpToken = await hre.ethers.getContractFactory("IpToken");
        const ipTokenUsdt = (await IpToken.deploy("IP USDT", "ipUSDT", usdt.address)) as IpToken;

        // when
        const josephUsdt = (await upgrades.deployProxy(
            JosephUsdtFactory,
            [
                false,
                usdt.address, // we check only this position the rest could be random
                ipTokenUsdt.address,
                usdt.address,
                usdt.address,
                usdt.address,
            ],
            {
                kind: "uups",
            }
        )) as JosephUsdt;

        // then
        expect(josephUsdt.address).to.be.not.empty;
        expect(await josephUsdt.getAsset()).to.be.equal(usdt.address);
    });

    it("should return default milton Stanley Balance Ratio", async () => {
        //given
        const { josephDai } = await prepareTestData(
            BigNumber.from(Math.floor(Date.now() / 1000)),
            [admin, userOne, userTwo, userThree, liquidityProvider],
            ["DAI"],
            [PERCENTAGE_3_18DEC],
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
        const ratio = await josephDai.connect(admin).getMiltonStanleyBalanceRatio();

        //then
        expect(ratio).to.be.equal(BigNumber.from("85").mul(N0__01_18DEC));
    });

    it("should change milton Stanley Balance Ratio", async () => {
        //given
        const newRatio = BigNumber.from("50").mul(N0__01_18DEC);

        const { josephDai } = await prepareTestData(
            BigNumber.from(Math.floor(Date.now() / 1000)),
            [admin, userOne, userTwo, userThree, liquidityProvider],
            ["DAI"],
            [PERCENTAGE_3_18DEC],
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
        await josephDai.connect(admin).setMiltonStanleyBalanceRatio(newRatio);

        //then
        const newRatioFromContract = await josephDai.connect(admin).getMiltonStanleyBalanceRatio();

        expect(newRatioFromContract).to.be.equal(newRatio);
    });

    it("should not change milton Stanley Balance Ratio when new ratio = 0", async () => {
        //given
        const { josephDai } = await prepareTestData(
            BigNumber.from(Math.floor(Date.now() / 1000)),
            [admin, userOne, userTwo, userThree, liquidityProvider],
            ["DAI"],
            [PERCENTAGE_3_18DEC],
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
        await expect(
            josephDai.connect(admin).setMiltonStanleyBalanceRatio(ZERO)
        ).to.be.revertedWith("IPOR_409");
    });

    it("should not change milton Stanley Balance Ratio when new ratio >= 1", async () => {
        //given
        const { josephDai } = await prepareTestData(
            BigNumber.from(Math.floor(Date.now() / 1000)),
            [admin, userOne, userTwo, userThree, liquidityProvider],
            ["DAI"],
            [PERCENTAGE_3_18DEC],
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
        await expect(
            josephDai.connect(admin).setMiltonStanleyBalanceRatio(N1__0_18DEC)
        ).to.be.revertedWith("IPOR_409");
    });
});

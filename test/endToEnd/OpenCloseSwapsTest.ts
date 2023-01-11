import hre from "hardhat";
import { BigNumber, Signer } from "ethers";
import { expect } from "chai";
import { N0__01_18DEC } from "../utils/Constants";
import {
    ERC20,
    TestnetFaucet,
    StrategyAave,
    StrategyCompound,
    StanleyUsdt,
    MiltonUsdc,
    MiltonUsdt,
    MiltonDai,
    JosephDai,
    JosephUsdc,
    JosephUsdt,
    IpToken,
    IvToken,
    MiltonFacadeDataProvider,
} from "../../types";

import { deploy, DeployType, setup } from "./deploy";

import { transferUsdtToAddress, transferUsdcToAddress, transferDaiToAddress } from "./tokens";

const ONE_18 = BigNumber.from("1000000000000000000");
const ONE_6 = BigNumber.from("1000000");

// Mainnet Fork and test case for mainnet with hardhat network by impersonate account from mainnet
// work for blockNumber: 14222088,
describe("Open/Close Swap", function () {
    if (process.env.FORK_ENABLED != "true") {
        return;
    }
    let admin: Signer;
    let userOne: Signer;
    let userTwo: Signer;

    let miltonDai: MiltonDai;
    let miltonUsdc: MiltonUsdc;
    let miltonUsdt: MiltonUsdt;

    let josephDai: JosephDai;
    let josephUsdc: JosephUsdc;
    let josephUsdt: JosephUsdt;

    let stanleyUsdt: StanleyUsdt;

    let strategyAaveDai: StrategyAave;
    let strategyAaveUsdc: StrategyAave;

    let strategyCompoundUsdt: StrategyCompound;

    let dai: ERC20;
    let usdc: ERC20;
    let usdt: ERC20;

    let ipTokenDai: IpToken;
    let ipTokenUsdc: IpToken;
    let ipTokenUsdt: IpToken;

    let ivTokenUsdt: IvToken;

    let testnetFaucet: TestnetFaucet;
    let miltonFacadeDataProvider: MiltonFacadeDataProvider;

    before(async () => {
        [admin, userOne, userTwo] = await hre.ethers.getSigners();

        const deployed: DeployType = await deploy();
        ({
            testnetFaucet,
            usdc,
            usdt,
            dai,
            strategyAaveDai,
            strategyAaveUsdc,
            strategyCompoundUsdt,
            stanleyUsdt,
            miltonDai,
            miltonUsdc,
            miltonUsdt,
            josephDai,
            josephUsdc,
            josephUsdt,
            ipTokenDai,
            ipTokenUsdc,
            ipTokenUsdt,
            ivTokenUsdt,
            miltonFacadeDataProvider,
        } = deployed);

        // #####################################################################
        // ##################          Setup            ########################
        // #####################################################################

        await setup(deployed);
    });

    describe("Dai", function () {
        let swapPayFixedId: BigNumber;
        let swapReceiveFixedId: BigNumber;

        it("ProvideLiquidity for 50000 dai - no auto-rebalance threshold", async () => {
            //given
            await josephDai.connect(admin).setAutoRebalanceThreshold(0);
            const deposit = ONE_18.mul("50000");
            await transferDaiToAddress(
                "0xbebc44782c7db0a1a60cb6fe97d0b483032ff1c7",
                await admin.getAddress(),
                ONE_18.mul("500000")
            );
            await dai.connect(admin).approve(josephDai.address, ONE_18.mul("500000"));
            await dai.connect(admin).approve(miltonDai.address, ONE_18.mul("500000"));
            //when
            await josephDai.connect(admin).provideLiquidity(deposit);

            //then
            const daiMiltonBalanceAfter = await dai.balanceOf(miltonDai.address);
            expect(daiMiltonBalanceAfter, "daiMiltonBalanceAfter").to.be.equal(deposit);
        });

        it("ProvideLiquidity for 50000 dai - below auto-rebalance threshold", async () => {
            //given
            const deposit = ONE_18.mul("50000");
            await josephDai.connect(admin).setAutoRebalanceThreshold(BigNumber.from("70"));
            await transferDaiToAddress(
                "0xbebc44782c7db0a1a60cb6fe97d0b483032ff1c7",
                await userOne.getAddress(),
                ONE_18.mul("500000")
            );
            await dai.connect(userOne).approve(josephDai.address, ONE_18.mul("500000"));
            await dai.connect(userOne).approve(miltonDai.address, ONE_18.mul("500000"));
            //when
            await josephDai.connect(userOne).provideLiquidity(deposit);

            //then
            const daiMiltonBalanceAfter = await dai.balanceOf(miltonDai.address);
            expect(daiMiltonBalanceAfter, "daiMiltonBalanceAfter").to.be.equal(
                BigNumber.from("100000000000000000000000")
            );
        });

        it("ProvideLiquidity for 50000 dai - above auto-rebalance threshold", async () => {
            //given
            await josephDai.connect(admin).setAutoRebalanceThreshold(BigNumber.from("40"));
            const deposit = ONE_18.mul("50000");
            await transferDaiToAddress(
                "0xbebc44782c7db0a1a60cb6fe97d0b483032ff1c7",
                await userTwo.getAddress(),
                ONE_18.mul("500000")
            );
            await dai.connect(userTwo).approve(josephDai.address, ONE_18.mul("500000"));
            await dai.connect(userTwo).approve(miltonDai.address, ONE_18.mul("500000"));
            //when
            await josephDai.connect(userTwo).provideLiquidity(deposit);

            //then
            const daiMiltonBalanceAfter = await dai.balanceOf(miltonDai.address);
            expect(daiMiltonBalanceAfter, "daiMiltonBalanceAfter").to.be.equal(
                BigNumber.from("127500000000000000000000")
            );
        });

        it("Should open Swap Pay Fixed, DAI", async () => {
            //when
            await miltonDai.openSwapPayFixed(
                ONE_18.mul("100"),
                BigNumber.from("90000000000000000"),
                ONE_18.mul("10")
            );
            //then

            const swaps = await miltonFacadeDataProvider.getMySwaps(
                dai.address,
                BigNumber.from("0"),
                BigNumber.from("10")
            );
            const numberOfOpenSwaps = swaps[0];
            swapPayFixedId = swaps[1][0].id;
            expect(numberOfOpenSwaps, "numberOfOpenSwaps = 1").to.be.equal(1);
        });

        it("Should open Swap Receive Fixed, DAI", async () => {
            //when
            await miltonDai.openSwapReceiveFixed(ONE_18.mul("100"), N0__01_18DEC, ONE_18.mul("10"));

            //then
            const swaps = await miltonFacadeDataProvider.getMySwaps(
                dai.address,
                BigNumber.from("0"),
                BigNumber.from("10")
            );
            const numberOfOpenSwaps = swaps[0];
            swapReceiveFixedId = swaps[1][1].id;
            expect(numberOfOpenSwaps, "numberOfOpenSwaps = 2").to.be.equal(2);
        });

        it("Should close Swap Pay Fixed, DAI", async () => {
            //when
            await miltonDai.closeSwapPayFixed(swapPayFixedId);
            //then

            const swaps = await miltonFacadeDataProvider.getMySwaps(
                dai.address,
                BigNumber.from("0"),
                BigNumber.from("10")
            );
            const numberOfOpenSwaps = swaps[0];
            expect(numberOfOpenSwaps, "numberOfOpenSwaps = 1").to.be.equal(1);
            expect(swaps[1][0].id, "swapReceiveFixed should be open ").to.be.equal(
                swapReceiveFixedId
            );
        });

        it("Should close Swap Receive Fixed, DAI", async () => {
            //when
            await miltonDai.closeSwapReceiveFixed(swapReceiveFixedId);
            //then

            const swaps = await miltonFacadeDataProvider.getMySwaps(
                dai.address,
                BigNumber.from("0"),
                BigNumber.from("10")
            );
            const numberOfOpenSwaps = swaps[0];
            expect(numberOfOpenSwaps, "numberOfOpenSwaps = 0").to.be.equal(0);
        });
    });

    describe("USDC", function () {
        let swapPayFixedId: BigNumber;
        let swapReceiveFixedId: BigNumber;

        it("ProvideLiquidity for 50000 usdc", async () => {
            //given
            await josephUsdc.connect(admin).setAutoRebalanceThreshold(0);
            const deposit = ONE_6.mul("50000");
            await transferUsdcToAddress(
                testnetFaucet.address,
                await admin.getAddress(),
                ONE_6.mul("500000")
            );
            await usdc.connect(admin).approve(josephUsdc.address, ONE_6.mul("500000"));
            await usdc.connect(admin).approve(miltonUsdc.address, ONE_6.mul("500000"));
            //when
            await josephUsdc.connect(admin).provideLiquidity(deposit);

            //then
            const usdcMiltonBalanceAfter = await usdc.balanceOf(miltonUsdc.address);
            expect(usdcMiltonBalanceAfter, "usdcMiltonBalanceAfter").to.be.equal(deposit);
        });

        it("Should rebalance and deposit(usdc) into vault (aave)", async () => {
            //given
            const strategyAaveBalance = await strategyAaveUsdc.balanceOf();
            //when
            await josephUsdc.rebalance();
            //then
            const strategyAaveAfter = await strategyAaveUsdc.balanceOf();
            expect(
                strategyAaveBalance.lt(strategyAaveAfter),
                "strategyAaveBalance < strategyAaveAfter"
            ).to.be.true;
        });

        it("Should open Swap Pay Fixed, USDC", async () => {
            //when
            await miltonUsdc.openSwapPayFixed(
                ONE_6.mul("300"),
                BigNumber.from("39999999999999999"),
                ONE_18.mul("10")
            );
            //then

            const swaps = await miltonFacadeDataProvider.getMySwaps(
                usdc.address,
                BigNumber.from("0"),
                BigNumber.from("10")
            );
            const numberOfOpenSwaps = swaps[0];
            swapPayFixedId = swaps[1][0].id;
            expect(numberOfOpenSwaps, "numberOfOpenSwaps = 1").to.be.equal(1);
        });

        it("Should open Swap Receive Fixed, USDC", async () => {
            //when
            await miltonUsdc.openSwapReceiveFixed(ONE_6.mul("300"), N0__01_18DEC, ONE_18.mul("10"));
            //then

            const swaps = await miltonFacadeDataProvider.getMySwaps(
                usdc.address,
                BigNumber.from("0"),
                BigNumber.from("10")
            );
            const numberOfOpenSwaps = swaps[0];
            swapReceiveFixedId = swaps[1][1].id;
            expect(numberOfOpenSwaps, "numberOfOpenSwaps = 2").to.be.equal(2);
        });

        it("Should close Swap Pay Fixed, USDC", async () => {
            //when
            await miltonUsdc.closeSwapPayFixed(swapPayFixedId);
            //then

            const swaps = await miltonFacadeDataProvider.getMySwaps(
                usdc.address,
                BigNumber.from("0"),
                BigNumber.from("10")
            );
            const numberOfOpenSwaps = swaps[0];
            expect(numberOfOpenSwaps, "numberOfOpenSwaps = 1").to.be.equal(1);
            expect(swaps[1][0].id, "swapReceiveFixed should be open ").to.be.equal(
                swapReceiveFixedId
            );
        });

        it("Should close Swap Receive Fixed, USDC", async () => {
            //when
            await miltonUsdc.closeSwapReceiveFixed(swapReceiveFixedId);
            //then

            const swaps = await miltonFacadeDataProvider.getMySwaps(
                usdc.address,
                BigNumber.from("0"),
                BigNumber.from("10")
            );
            const numberOfOpenSwaps = swaps[0];
            expect(numberOfOpenSwaps, "numberOfOpenSwaps = 0").to.be.equal(0);
        });
    });

    describe("USDT", function () {
        let swapPayFixedId: BigNumber;
        let swapReceiveFixedId: BigNumber;

        it("ProvideLiquidity for 50000 usdt", async () => {
            //given
            await josephUsdt.connect(admin).setAutoRebalanceThreshold(0);
            const deposit = ONE_6.mul("50000");
            await transferUsdtToAddress(
                testnetFaucet.address,
                await admin.getAddress(),
                ONE_6.mul("500000")
            );
            await usdt.connect(admin).approve(josephUsdt.address, ONE_6.mul("500000"));
            await usdt.connect(admin).approve(miltonUsdt.address, ONE_6.mul("500000"));
            //when
            await josephUsdt.connect(admin).provideLiquidity(deposit);

            //then
            const usdtMiltonBalanceAfter = await usdt.balanceOf(miltonUsdt.address);
            expect(usdtMiltonBalanceAfter, "usdtMiltonBalanceAfter").to.be.equal(deposit);
        });

        it("Should rebalance and deposit(usdt) into vault (compound)", async () => {
            //given
            await josephUsdt.connect(admin).setAutoRebalanceThreshold(0);
            const strategyCompoundBefore = await strategyCompoundUsdt.balanceOf();
            //when
            await josephUsdt.rebalance();
            //then
            const strategyCompoundAfter = await strategyCompoundUsdt.balanceOf();
            expect(
                strategyCompoundBefore.lt(strategyCompoundAfter),
                "strategyCompoundBefore < strategyCompoundAfter"
            ).to.be.true;
        });

        it("Should open Swap Pay Fixed, USDT", async () => {
            //when
            await miltonUsdt.openSwapPayFixed(
                ONE_6.mul("300"),
                BigNumber.from("59999999999999999"),
                ONE_18.mul("10")
            );
            //then

            const swaps = await miltonFacadeDataProvider.getMySwaps(
                usdt.address,
                BigNumber.from("0"),
                BigNumber.from("10")
            );
            const numberOfOpenSwaps = swaps[0];
            swapPayFixedId = swaps[1][0].id;
            expect(numberOfOpenSwaps, "numberOfOpenSwaps = 1").to.be.equal(1);
        });

        it("Should open Swap Receive Fixed, USDT", async () => {
            //when
            await miltonUsdt.openSwapReceiveFixed(ONE_6.mul("300"), N0__01_18DEC, ONE_18.mul("10"));

            //then
            const swaps = await miltonFacadeDataProvider.getMySwaps(
                usdt.address,
                BigNumber.from("0"),
                BigNumber.from("10")
            );
            const numberOfOpenSwaps = swaps[0];
            swapReceiveFixedId = swaps[1][1].id;
            expect(numberOfOpenSwaps, "numberOfOpenSwaps = 2").to.be.equal(2);
        });

        it("Should close Swap Pay Fixed, USDT", async () => {
            //when
            await miltonUsdt.closeSwapPayFixed(swapPayFixedId);
            //then

            const swaps = await miltonFacadeDataProvider.getMySwaps(
                usdt.address,
                BigNumber.from("0"),
                BigNumber.from("10")
            );
            const numberOfOpenSwaps = swaps[0];
            expect(numberOfOpenSwaps, "numberOfOpenSwaps = 1").to.be.equal(1);
            expect(swaps[1][0].id, "swapReceiveFixed should be open ").to.be.equal(
                swapReceiveFixedId
            );
        });

        it("Should close Swap Receive Fixed, USDT", async () => {
            //when
            await miltonUsdt.closeSwapReceiveFixed(swapReceiveFixedId);

            //then
            const swaps = await miltonFacadeDataProvider.getMySwaps(
                usdt.address,
                BigNumber.from("0"),
                BigNumber.from("10")
            );
            const numberOfOpenSwaps = swaps[0];
            expect(numberOfOpenSwaps, "numberOfOpenSwaps = 0").to.be.equal(0);
        });

        it("Redeem tokens from Joseph(usdt)", async () => {
            //given
            const ipTokenUsdtBalansBefore = await ipTokenUsdt.balanceOf(await admin.getAddress());
            const toRedeem = BigNumber.from("1000000");
            //when
            await josephUsdt.redeem(toRedeem);
            //then
            const ipTokenUsdtBalansAfter = await ipTokenUsdt.balanceOf(await admin.getAddress());
            expect(
                ipTokenUsdtBalansAfter.lt(ipTokenUsdtBalansBefore),
                "ipTokenUsdtBalansAfter < ipTokenUsdtBalansBefore"
            ).to.be.true;
        });
    });
});

import { BigNumber, Signer } from "ethers";
const { expect } = require("chai");
import {
    ERC20,
    MiltonFaucet,
    AaveStrategy,
    CompoundStrategy,
    StanleyUsdt,
    MiltonUsdc,
    MiltonUsdt,
    MiltonDai,
    JosephDai,
    JosephUsdc,
    JosephUsdt,
    IpToken,
    IvToken,
    MiltonDarcyDataProvider,
} from "../../types";

import { deploy, DeployType, setup } from "./deploy";

import { transferUsdtToAddress, transferUsdcToAddress, transferDaiToAddress } from "./tokens";

const ONE_18 = BigNumber.from("1000000000000000000");
const ONE_6 = BigNumber.from("100000000");
// Mainnet Fork and test case for mainnet with hardhat network by impersonate account from mainnet
// work for blockNumber: 14222088,
describe("Open/Close Swap", function () {
    if (process.env.FORK_ENABLED != "true") {
        return;
    }
    let admin: Signer;

    let miltonDai: MiltonDai;
    let miltonUsdc: MiltonUsdc;
    let miltonUsdt: MiltonUsdt;

    let josephDai: JosephDai;
    let josephUsdc: JosephUsdc;
    let josephUsdt: JosephUsdt;

    let stanleyUsdt: StanleyUsdt;

    let strategyAaveDai: AaveStrategy;
    let strategyAaveUsdc: AaveStrategy;

    let strategyCompoundUsdt: CompoundStrategy;

    let dai: ERC20;
    let usdc: ERC20;
    let usdt: ERC20;

    let ipTokenDai: IpToken;
    let ipTokenUsdc: IpToken;
    let ipTokenUsdt: IpToken;

    let ivTokenUsdt: IvToken;

    let miltonFaucet: MiltonFaucet;
    let miltonDarcyDataProvider: MiltonDarcyDataProvider;

    before(async () => {
        [admin] = await hre.ethers.getSigners();

        const deployd: DeployType = await deploy();
        ({
            miltonFaucet,
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
            miltonDarcyDataProvider,
        } = deployd);

        // #####################################################################
        // ##################          Setup            ########################
        // #####################################################################

        await setup(deployd);
    });

    describe("Dai", function () {
        let swapPayFixedId: BigNumber;
        let swapReceiveFixedId: BigNumber;

        it("ProvideLiquidity for 1000000 dai", async () => {
            //given

            const deposit = ONE_18.mul("10000");
            await transferDaiToAddress(
                miltonFaucet.address,
                await admin.getAddress(),
                ONE_18.mul("10000000")
            );
            await dai.connect(admin).approve(josephDai.address, ONE_18.mul("1000000000"));
            await dai.connect(admin).approve(miltonDai.address, ONE_18.mul("1000000000"));
            //when
            await josephDai.connect(admin).provideLiquidity(deposit);

            //then
            const daiMiltonBalanceAfter = await dai.balanceOf(miltonDai.address);
            expect(daiMiltonBalanceAfter, "daiMiltonBalanceAfter").to.be.equal(deposit);
        });

        it("Should rebalanse and deposit(dai) into vault (aave)", async () => {
            //given
            const aaveStrategyBalance = await strategyAaveDai.balanceOf();
            //when
            await josephDai.rebalance();
            //then
            const aaveStrategyAfter = await strategyAaveDai.balanceOf();
            expect(
                aaveStrategyBalance.lt(aaveStrategyAfter),
                "aaveStrategyBalance < aaveStrategyAfter"
            ).to.be.true;
        });

        it("Should open Swap Pay Fixed", async () => {
            //when
            await miltonDai.openSwapPayFixed(
                ONE_18.mul("100"),
                BigNumber.from("900000000000000000"),
                ONE_18.mul("10")
            );
            //then

            const swaps = await miltonDarcyDataProvider.getMySwaps(
                dai.address,
                BigNumber.from("0"),
                BigNumber.from("10")
            );
            const numberOfOpenSwaps = swaps[0];
            swapPayFixedId = swaps[1][0].id;
            expect(numberOfOpenSwaps, "numberOfOpenSwaps = 1").to.be.equal(1);
        });

        it("Should open Swap Receive Fixed", async () => {
            //when
            await miltonDai.openSwapReceiveFixed(
                ONE_18.mul("100"),
                BigNumber.from("900000000000000000"),
                ONE_18.mul("10")
            );
            //then

            const swaps = await miltonDarcyDataProvider.getMySwaps(
                dai.address,
                BigNumber.from("0"),
                BigNumber.from("10")
            );
            const numberOfOpenSwaps = swaps[0];
            swapReceiveFixedId = swaps[1][1].id;
            expect(numberOfOpenSwaps, "numberOfOpenSwaps = 2").to.be.equal(2);
        });

        it("Should close Swap Pay Fixed", async () => {
            //when
            await miltonDai.closeSwapPayFixed(swapPayFixedId);
            //then

            const swaps = await miltonDarcyDataProvider.getMySwaps(
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

        it("Should close Swap Receive Fixed", async () => {
            //when
            await miltonDai.closeSwapReceiveFixed(swapReceiveFixedId);
            //then

            const swaps = await miltonDarcyDataProvider.getMySwaps(
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

        it("ProvideLiquidity for usdc", async () => {
            //given

            const deposit = BigNumber.from("10000000000");
            await transferUsdcToAddress(
                miltonFaucet.address,
                await admin.getAddress(),
                BigNumber.from("1000000000000000")
            );
            await usdc
                .connect(admin)
                .approve(josephUsdc.address, BigNumber.from("10000000000000000"));
            await usdc
                .connect(admin)
                .approve(miltonUsdc.address, BigNumber.from("10000000000000000"));
            //when
            await josephUsdc.connect(admin).provideLiquidity(deposit);

            //then
            const usdcMiltonBalanceAfter = await usdc.balanceOf(miltonUsdc.address);
            expect(usdcMiltonBalanceAfter, "usdcMiltonBalanceAfter").to.be.equal(deposit);
        });

        it("Should rebalanse and deposit(usdc) into vault (aave)", async () => {
            //given
            const aaveStrategyBalance = await strategyAaveUsdc.balanceOf();
            //when
            await josephUsdc.rebalance();
            //then
            const aaveStrategyAfter = await strategyAaveUsdc.balanceOf();
            expect(
                aaveStrategyBalance.lt(aaveStrategyAfter),
                "aaveStrategyBalance < aaveStrategyAfter"
            ).to.be.true;
        });

        it("Should open Swap Pay Fixed", async () => {
            //when
            await miltonUsdc.openSwapPayFixed(
                ONE_6.mul("3"),
                BigNumber.from("39999999999999999"),
                ONE_18.mul("10")
            );
            //then

            const swaps = await miltonDarcyDataProvider.getMySwaps(
                usdc.address,
                BigNumber.from("0"),
                BigNumber.from("10")
            );
            const numberOfOpenSwaps = swaps[0];
            swapPayFixedId = swaps[1][0].id;
            expect(numberOfOpenSwaps, "numberOfOpenSwaps = 1").to.be.equal(1);
        });

        it("Should open Swap Receive Fixed", async () => {
            //when
            await miltonUsdc.openSwapReceiveFixed(
                ONE_6.mul("3"),
                BigNumber.from("39999999999999999"),
                ONE_18.mul("10")
            );
            //then

            const swaps = await miltonDarcyDataProvider.getMySwaps(
                usdc.address,
                BigNumber.from("0"),
                BigNumber.from("10")
            );
            const numberOfOpenSwaps = swaps[0];
            swapReceiveFixedId = swaps[1][1].id;
            expect(numberOfOpenSwaps, "numberOfOpenSwaps = 2").to.be.equal(2);
        });

        it("Should close Swap Pay Fixed", async () => {
            //when
            await miltonUsdc.closeSwapPayFixed(swapPayFixedId);
            //then

            const swaps = await miltonDarcyDataProvider.getMySwaps(
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

        it("Should close Swap Receive Fixed", async () => {
            //when
            await miltonUsdc.closeSwapReceiveFixed(swapReceiveFixedId);
            //then

            const swaps = await miltonDarcyDataProvider.getMySwaps(
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

        it("ProvideLiquidity for usdt", async () => {
            //given

            const deposit = BigNumber.from("10000000000");
            await transferUsdtToAddress(
                miltonFaucet.address,
                await admin.getAddress(),
                BigNumber.from("1000000000000000")
            );
            await usdt.connect(admin).approve(josephUsdt.address, BigNumber.from("100000000000"));
            await usdt.connect(admin).approve(miltonUsdt.address, BigNumber.from("100000000000"));
            //when
            await josephUsdt.connect(admin).provideLiquidity(deposit);

            //then
            const usdtMiltonBalanceAfter = await usdt.balanceOf(miltonUsdt.address);
            expect(usdtMiltonBalanceAfter, "usdtMiltonBalanceAfter").to.be.equal(deposit);
        });

        it("Should rebalanse and deposit(usdt) into vault (compound)", async () => {
            //given
            const compoundStrategyBefore = await strategyCompoundUsdt.balanceOf();
            //when
            await josephUsdt.rebalance();
            //then
            const compoundStrategyAfter = await strategyCompoundUsdt.balanceOf();
            expect(
                compoundStrategyBefore.lt(compoundStrategyAfter),
                "compoundStrategyBefore < compoundStrategyAfter"
            ).to.be.true;
        });

        it("Should open Swap Pay Fixed", async () => {
            //when
            await miltonUsdt.openSwapPayFixed(
                ONE_6.mul("3"),
                BigNumber.from("39999999999999999"),
                ONE_18.mul("10")
            );
            //then

            const swaps = await miltonDarcyDataProvider.getMySwaps(
                usdt.address,
                BigNumber.from("0"),
                BigNumber.from("10")
            );
            const numberOfOpenSwaps = swaps[0];
            swapPayFixedId = swaps[1][0].id;
            expect(numberOfOpenSwaps, "numberOfOpenSwaps = 1").to.be.equal(1);
        });

        it("Should open Swap Receive Fixed", async () => {
            //when
            await miltonUsdt.openSwapReceiveFixed(
                ONE_6.mul("3"),
                BigNumber.from("39999999999999999"),
                ONE_18.mul("10")
            );
            //then

            const swaps = await miltonDarcyDataProvider.getMySwaps(
                usdt.address,
                BigNumber.from("0"),
                BigNumber.from("10")
            );
            const numberOfOpenSwaps = swaps[0];
            swapReceiveFixedId = swaps[1][1].id;
            expect(numberOfOpenSwaps, "numberOfOpenSwaps = 2").to.be.equal(2);
        });

        it("Should close Swap Pay Fixed", async () => {
            //when
            await miltonUsdt.closeSwapPayFixed(swapPayFixedId);
            //then

            const swaps = await miltonDarcyDataProvider.getMySwaps(
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

        it("Should close Swap Receive Fixed", async () => {
            //when
            await miltonUsdt.closeSwapReceiveFixed(swapReceiveFixedId);
            //then

            const swaps = await miltonDarcyDataProvider.getMySwaps(
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

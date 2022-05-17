import hre from "hardhat";
import { expect } from "chai";
import { BigNumber, Signer } from "ethers";
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
} from "../../types";

import { deploy, DeployType, setup } from "./deploy";

import { transferUsdtToAddress, transferUsdcToAddress, transferDaiToAddress } from "./tokens";
import { N0__01_18DEC, N0__1_18DEC, N1__0_18DEC, N1__0_6DEC } from "../utils/Constants";

// Mainnet Fork and test case for mainnet with hardhat network by impersonate account from mainnet
// work for blockNumber: 14222088,
describe("Josepf rebalance, deposit/withdraw from vault", function () {
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

    before(async () => {
        [admin] = await hre.ethers.getSigners();

        const deployd: DeployType = await deploy();
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
        } = deployd);

        // #####################################################################
        // ##################          Setup            ########################
        // #####################################################################

        await setup(deployd);
    });

    it("ProvideLiquidity for dai", async () => {
        //given

        const deposit = BigNumber.from("10").mul(N1__0_18DEC);
        await transferDaiToAddress(testnetFaucet.address, await admin.getAddress(), N1__0_18DEC);
        await dai
            .connect(admin)
            .approve(josephDai.address, BigNumber.from("1000").mul(N1__0_18DEC));
        //when
        await josephDai.connect(admin).provideLiquidity(deposit);

        //then
        const daiMiltonBalanceAfter = await dai.balanceOf(miltonDai.address);
        expect(daiMiltonBalanceAfter, "daiMiltonBalanceAfter").to.be.equal(deposit);
    });

    it("Should rebalanse and deposit(dai) into vault (aave)", async () => {
        //given
        const strategyAaveBalance = await strategyAaveDai.balanceOf();
        //when
        await josephDai.rebalance();
        //then
        const strategyAaveAfter = await strategyAaveDai.balanceOf();
        expect(strategyAaveBalance.lt(strategyAaveAfter), "strategyAaveBalance < strategyAaveAfter")
            .to.be.true;
    });

    it("Redeem tokens from Joseph(dai)", async () => {
        //given
        const ipTokenDaiBalansBefore = await ipTokenDai.balanceOf(await admin.getAddress());
        const toRedeem = N0__01_18DEC;
        //when
        await josephDai.redeem(toRedeem);
        //then
        const ipTokenDaiBalansAfter = await ipTokenDai.balanceOf(await admin.getAddress());
        expect(
            ipTokenDaiBalansAfter.lt(ipTokenDaiBalansBefore),
            "ipTokenDaiBalansAfter < ipTokenDaiBalansBefore"
        ).to.be.true;
    });

    it("Should rebalanse and withdraw(dai) from vault (aave)", async () => {
        //given
        const strategyAaveBalance = await strategyAaveDai.balanceOf();
        //when
        await josephDai.rebalance();
        //then
        const strategyAaveAfter = await strategyAaveDai.balanceOf();
        expect(strategyAaveAfter.lt(strategyAaveBalance), "strategyAaveAfter < strategyAaveBalance")
            .to.be.true;
    });

    it("ProvideLiquidity for usdc", async () => {
        //given

        const deposit = BigNumber.from("1000").mul(N1__0_6DEC);
        await transferUsdcToAddress(
            testnetFaucet.address,
            await admin.getAddress(),
            BigNumber.from("10000").mul(N1__0_6DEC)
        );
        await usdc
            .connect(admin)
            .approve(josephUsdc.address, BigNumber.from("100000").mul(N1__0_6DEC));
        //when
        await josephUsdc.connect(admin).provideLiquidity(deposit);

        //then
        const usdcMiltonBalanceAfter = await usdc.balanceOf(miltonUsdc.address);
        expect(usdcMiltonBalanceAfter, "usdcMiltonBalanceAfter").to.be.equal(deposit);
    });

    it("Should rebalanse and deposit(usdc) into vault (aave)", async () => {
        //given
        const strategyAaveBalance = await strategyAaveUsdc.balanceOf();
        //when
        await josephUsdc.rebalance();
        //then
        const strategyAaveAfter = await strategyAaveUsdc.balanceOf();
        expect(strategyAaveBalance.lt(strategyAaveAfter), "strategyAaveBalance < strategyAaveAfter")
            .to.be.true;
    });

    it("Redeem tokens from Joseph(usdc)", async () => {
        //given
        const ipTokenUsdcBalansBefore = await ipTokenUsdc.balanceOf(await admin.getAddress());
        const toRedeem = N0__1_18DEC;
        //when
        await josephUsdc.redeem(toRedeem);
        //then
        const ipTokenUsdcBalansAfter = await ipTokenUsdc.balanceOf(await admin.getAddress());
        expect(
            ipTokenUsdcBalansAfter.lt(ipTokenUsdcBalansBefore),
            "ipTokenUsdcBalansAfter < ipTokenUsdcBalansBefore"
        ).to.be.true;
    });

    it("Should rebalanse and withdraw(usdc) from vault (aave)", async () => {
        //given
        const strategyAaveBalance = await strategyAaveUsdc.balanceOf();
        //when
        await josephUsdc.rebalance();
        //then
        const strategyAaveAfter = await strategyAaveUsdc.balanceOf();
        expect(strategyAaveAfter.lt(strategyAaveBalance), "strategyAaveAfter < strategyAaveBalance")
            .to.be.true;
    });

    it("ProvideLiquidity for usdt", async () => {
        //given

        const deposit = BigNumber.from("1000").mul(N1__0_6DEC);
        await transferUsdtToAddress(
            testnetFaucet.address,
            await admin.getAddress(),
            BigNumber.from("10000").mul(N1__0_6DEC)
        );
        await usdt
            .connect(admin)
            .approve(josephUsdt.address, BigNumber.from("100000").mul(N1__0_6DEC));
        //when
        await josephUsdt.connect(admin).provideLiquidity(deposit);

        //then
        const usdtMiltonBalanceAfter = await usdt.balanceOf(miltonUsdt.address);
        expect(usdtMiltonBalanceAfter, "usdtMiltonBalanceAfter").to.be.equal(deposit);
    });

    it("Should rebalanse and deposit(usdt) into vault (compound)", async () => {
        //given
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

    it("Redeem tokens from Joseph(usdt)", async () => {
        //given
        const ipTokenUsdtBalansBefore = await ipTokenUsdt.balanceOf(await admin.getAddress());
        const toRedeem = N1__0_6DEC;
        //when
        await josephUsdt.redeem(toRedeem);
        //then
        const ipTokenUsdtBalansAfter = await ipTokenUsdt.balanceOf(await admin.getAddress());
        expect(
            ipTokenUsdtBalansAfter.lt(ipTokenUsdtBalansBefore),
            "ipTokenUsdtBalansAfter < ipTokenUsdtBalansBefore"
        ).to.be.true;
    });

    it("Should not rebalanse and withdraw(usdt) from vault (compound)", async () => {
        //given
        const strategyCompoundBalance = await strategyCompoundUsdt.balanceOf();
        //when
        await expect(josephUsdt.rebalance()).to.be.revertedWith("IPOR_319");
        //then
        const strategyCompoundAfter = await strategyCompoundUsdt.balanceOf();
        expect(
            strategyCompoundAfter.eq(strategyCompoundBalance),
            "strategyCompoundAfter = strategyCompoundBalance"
        ).to.be.true;
    });

    it("Should rebalanse and withdraw(usdt) from vault (compound)", async () => {
        //given
        // this set of acttion generate change on compound balance
        await usdt
            .connect(admin)
            .approve(stanleyUsdt.address, BigNumber.from("100000").mul(N1__0_6DEC));
        await stanleyUsdt.setMilton(await admin.getAddress());
        await stanleyUsdt.deposit(N1__0_6DEC);
        await stanleyUsdt.setMilton(miltonUsdt.address);
        // END this set of acttion generate change on compound balance
        const ivTokenUsdtBalanceBefore = await ivTokenUsdt.balanceOf(miltonUsdt.address);

        // //when
        await josephUsdt.rebalance();
        // //then
        const ivTokenUsdtBalanceAfter = await ivTokenUsdt.balanceOf(miltonUsdt.address);

        expect(
            ivTokenUsdtBalanceAfter.lt(ivTokenUsdtBalanceBefore),
            "ivTokenUsdtBalanceAfter < ivTokenUsdtBalanceBefore"
        ).to.be.true;
    });
});

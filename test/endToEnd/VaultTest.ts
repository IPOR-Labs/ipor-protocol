import hre from "hardhat";
import { BigNumber } from "ethers";
import { expect } from "chai";
import {
    ERC20,
    MockCUSDT,
    TestnetFaucet,
    StrategyAave,
    StrategyCompound,
    StanleyDai,
    StanleyUsdc,
    StanleyUsdt,
    MiltonUsdc,
    MiltonUsdt,
    MiltonDai,
    JosephDai,
    JosephUsdc,
    JosephUsdt,
} from "../../types";

import { transferFromFaucetTo } from "./milton";

import { deploy, DeployType, setup } from "./deploy";
import { cUsdtAddress } from "./tokens";

// Mainnet Fork and test case for mainnet with hardhat network by impersonate account from mainnet
// work for blockNumber: 14222088,
describe("End to End tests on mainnet fork", function () {
    if (process.env.FORK_ENABLED != "true") {
        return;
    }
    let dai: ERC20;
    let usdc: ERC20;
    let usdt: ERC20;
    let cUsdc: MockCUSDT;
    let cUsdt: MockCUSDT;

    let testnetFaucet: TestnetFaucet;

    let strategyAaveDai: StrategyAave;
    let strategyAaveUsdc: StrategyAave;
    let strategyAaveUsdt: StrategyAave;

    let strategyCompoundDai: StrategyCompound;
    let strategyCompoundUsdc: StrategyCompound;
    let strategyCompoundUsdt: StrategyCompound;

    let stanleyDai: StanleyDai;
    let stanleyUsdc: StanleyUsdc;
    let stanleyUsdt: StanleyUsdt;

    let miltonDai: MiltonDai;
    let miltonUsdc: MiltonUsdc;
    let miltonUsdt: MiltonUsdt;

    let josephDai: JosephDai;
    let josephUsdc: JosephUsdc;
    let josephUsdt: JosephUsdt;

    before(async () => {
        const deployd: DeployType = await deploy();
        ({
            testnetFaucet,
            usdc,
            usdt,
            dai,
            cUsdc,
            cUsdt,
            strategyAaveDai,
            strategyAaveUsdc,
            strategyAaveUsdt,
            strategyCompoundDai,
            strategyCompoundUsdc,
            strategyCompoundUsdt,
            stanleyDai,
            stanleyUsdc,
            stanleyUsdt,
            miltonDai,
            miltonUsdc,
            miltonUsdt,
            josephDai,
            josephUsdc,
            josephUsdt,
        } = deployd);

        // #####################################################################
        // ##################          Setup            ########################
        // #####################################################################

        await setup(deployd);
    });

    it("Should deposit to stanley Dai", async () => {
        // given
        const stanleyDaiBalanceBefore = await stanleyDai.totalBalance(miltonDai.address);

        await transferFromFaucetTo(
            testnetFaucet,
            dai,
            miltonDai.address,
            BigNumber.from("1000000000000000000")
        );
        //when
        await josephDai.depositToStanley(BigNumber.from("100000000000000000"));

        //then
        const stanleyDaiBalanceAfter = await stanleyDai.totalBalance(miltonDai.address);
        expect(
            stanleyDaiBalanceAfter.gt(stanleyDaiBalanceBefore),
            "stanleyDaiBalanceAfter > stanleyDaiBalanceBefore"
        ).to.be.true;
    });

    it("Should deposit to stanley Usdc", async () => {
        // given
        const stanleyUsdcBalanceBefore = await stanleyUsdc.totalBalance(miltonUsdc.address);
        await transferFromFaucetTo(
            testnetFaucet,
            usdc,
            miltonUsdc.address,
            BigNumber.from("1000000000")
        );

        // when
        await josephUsdc.depositToStanley(BigNumber.from("1000000000000000000"));

        // then
        const stanleyUsdcBalanceAfter = await stanleyUsdc.totalBalance(miltonUsdc.address);
        expect(
            stanleyUsdcBalanceAfter.gt(stanleyUsdcBalanceBefore),
            "stanleyUsdcBalanceAfter > stanleyUsdcBalanceBefore"
        ).to.be.true;
    });

    it("Should deposit to stanley Usdt", async () => {
        // given
        const stanleyUsdtBalanceBefore = await stanleyUsdt.totalBalance(miltonUsdt.address);
        await transferFromFaucetTo(
            testnetFaucet,
            usdt,
            miltonUsdt.address,
            BigNumber.from("1000000000")
        );

        // when
        await josephUsdt.depositToStanley(BigNumber.from("1000000000000000000"));

        // then
        const stanleyUsdtBalanceAfter = await stanleyUsdt.totalBalance(miltonUsdt.address);
        expect(
            stanleyUsdtBalanceAfter.gt(stanleyUsdtBalanceBefore),
            "stanleyUsdtBalanceAfter > stanleyUsdtBalanceBefore"
        ).to.be.true;
    });

    it("Should be able to withdraw from stanley Dai", async () => {
        // given
        const stanleyDaiBalanceBefore = await stanleyDai.totalBalance(miltonDai.address);
        //when
        await josephDai.withdrawFromStanley(BigNumber.from("100000000000000000"));

        //then
        const stanleyDaiBalanceAfter = await stanleyDai.totalBalance(miltonDai.address);
        expect(
            stanleyDaiBalanceAfter.lt(stanleyDaiBalanceBefore),
            "stanleyDaiBalanceAfter < stanleyDaiBalanceBefore"
        ).to.be.true;
    });

    it("Should be able to withdraw from stanley Usdc", async () => {
        // given
        await josephUsdc.depositToStanley(BigNumber.from("1000000000000000000"));

        const timestamp = Math.floor(Date.now() / 1000) + 864000 * 2;
        await hre.network.provider.send("evm_increaseTime", [timestamp]);
        await hre.network.provider.send("evm_mine");

        await cUsdc.accrueInterest();

        const stanleyUsdcBalanceBefore = await stanleyUsdc.totalBalance(miltonUsdc.address);

        // when
        await josephUsdc.withdrawFromStanley(BigNumber.from("100000000000000000"));

        // then
        const stanleyUsdcBalanceAfter = await stanleyUsdc.totalBalance(miltonUsdc.address);
        expect(
            stanleyUsdcBalanceAfter.lt(stanleyUsdcBalanceBefore),
            "stanleyUsdcBalanceAfter < stanleyUsdcBalanceBefore"
        ).to.be.true;
    });

    it("Should not be able to withdraw from stanley Usdt", async () => {
        // given
        await transferFromFaucetTo(
            testnetFaucet,
            usdt,
            miltonUsdt.address,
            BigNumber.from("20000000000")
        );
        await cUsdt.accrueInterest();
        await josephUsdt.depositToStanley(BigNumber.from("10000000000000000000000"));
        await josephUsdt.withdrawFromStanley(BigNumber.from("10000000000000000000000"));

        const stanleyUsdtBalanceBefore = await stanleyUsdt.totalBalance(miltonUsdt.address);

        // when
        await expect(
            josephUsdt.withdrawFromStanley(BigNumber.from("10000000000000000000000"))
        ).to.be.revertedWith("IPOR_322");

        // then
        const stanleyUsdtBalanceAfter = await stanleyUsdt.totalBalance(miltonUsdt.address);
        expect(
            stanleyUsdtBalanceAfter.eq(stanleyUsdtBalanceBefore),
            "stanleyUsdtBalanceAfter = stanleyUsdtBalanceBefore"
        ).to.be.true;
    });

    it("Should not be able deposit when strategies is pause", async () => {
        // given
        const one = BigNumber.from("1000000000000000000");
        await strategyAaveDai.pause();
        await strategyAaveUsdc.pause();
        await strategyAaveUsdt.pause();
        await strategyCompoundDai.pause();
        await strategyCompoundUsdc.pause();
        await strategyCompoundUsdt.pause();

        const stanleyDaiBalanceBefore = await stanleyDai.totalBalance(miltonDai.address);
        const stanleyUsdcBalanceBefore = await stanleyUsdc.totalBalance(miltonUsdc.address);
        const stanleyUsdtBalanceBefore = await stanleyUsdt.totalBalance(miltonUsdt.address);
        //when
        await expect(josephDai.depositToStanley(one)).to.be.revertedWith("Pausable: paused");
        await expect(josephUsdc.depositToStanley(one)).to.be.revertedWith("Pausable: paused");
        await expect(josephUsdt.depositToStanley(one)).to.be.revertedWith("Pausable: paused");

        // then
        const stanleyDaiBalanceAfter = await stanleyDai.totalBalance(miltonDai.address);
        const stanleyUsdcBalanceAfter = await stanleyUsdc.totalBalance(miltonUsdc.address);
        const stanleyUsdtBalanceAfter = await stanleyUsdt.totalBalance(miltonUsdt.address);

        expect(
            stanleyDaiBalanceAfter.lt(stanleyDaiBalanceBefore.add(one)),
            "stanleyDaiBalanceAfter < stanleyDaiBalanceBefore + one"
        ).to.be.true;
        expect(
            stanleyUsdcBalanceAfter.lt(stanleyUsdcBalanceBefore.add(one)),
            "stanleyUsdcBalanceAfter < stanleyUsdcBalanceBefore + one"
        ).to.be.true;
        expect(
            stanleyUsdtBalanceAfter.lt(stanleyUsdtBalanceBefore.add(one)),
            "stanleyUsdtBalanceAfter < stanleyUsdtBalanceBefore +one"
        ).to.be.true;
    });

    it("Should not be able withdraw when strategies is pause", async () => {
        // given
        const one = BigNumber.from("1000000000000000000");
        const stanleyDaiBalanceBefore = await stanleyDai.totalBalance(miltonDai.address);
        const stanleyUsdcBalanceBefore = await stanleyUsdc.totalBalance(miltonUsdc.address);
        const stanleyUsdtBalanceBefore = await stanleyUsdt.totalBalance(miltonUsdt.address);
        //when
        await expect(josephDai.withdrawFromStanley(one)).to.be.revertedWith("Pausable: paused");
        await expect(josephUsdc.withdrawFromStanley(one)).to.be.revertedWith("Pausable: paused");
        await expect(josephUsdt.withdrawFromStanley(one)).to.be.revertedWith("Pausable: paused");

        // then
        const stanleyDaiBalanceAfter = await stanleyDai.totalBalance(miltonDai.address);
        const stanleyUsdcBalanceAfter = await stanleyUsdc.totalBalance(miltonUsdc.address);
        const stanleyUsdtBalanceAfter = await stanleyUsdt.totalBalance(miltonUsdt.address);

        expect(
            stanleyDaiBalanceAfter.gte(stanleyDaiBalanceBefore),
            "stanleyDaiBalanceAfter > stanleyDaiBalanceBefore"
        ).to.be.true;
        expect(
            stanleyUsdcBalanceAfter.gte(stanleyUsdcBalanceBefore),
            "stanleyUsdcBalanceAfter > stanleyUsdcBalanceBefore"
        ).to.be.true;
        expect(
            stanleyUsdtBalanceAfter.gte(stanleyUsdtBalanceBefore),
            "stanleyUsdtBalanceAfter > stanleyUsdtBalanceBefore"
        ).to.be.true;
    });

    it("Should not be able deposit when stanley is pause", async () => {
        // given
        const one = BigNumber.from("1000000000000000000");
        await strategyAaveDai.unpause();
        await strategyAaveUsdc.unpause();
        await strategyAaveUsdt.unpause();
        await strategyCompoundDai.unpause();
        await strategyCompoundUsdc.unpause();
        await strategyCompoundUsdt.unpause();
        await stanleyDai.pause();
        await stanleyUsdc.pause();
        await stanleyUsdt.pause();
        const stanleyDaiBalanceBefore = await stanleyDai.totalBalance(miltonDai.address);
        const stanleyUsdcBalanceBefore = await stanleyUsdc.totalBalance(miltonUsdc.address);
        const stanleyUsdtBalanceBefore = await stanleyUsdt.totalBalance(miltonUsdt.address);
        //when
        await expect(josephDai.depositToStanley(one)).to.be.revertedWith("Pausable: paused");
        await expect(josephUsdc.depositToStanley(one)).to.be.revertedWith("Pausable: paused");
        await expect(josephUsdt.depositToStanley(one)).to.be.revertedWith("Pausable: paused");

        // then
        const stanleyDaiBalanceAfter = await stanleyDai.totalBalance(miltonDai.address);
        const stanleyUsdcBalanceAfter = await stanleyUsdc.totalBalance(miltonUsdc.address);
        const stanleyUsdtBalanceAfter = await stanleyUsdt.totalBalance(miltonUsdt.address);

        expect(
            stanleyDaiBalanceAfter.lt(stanleyDaiBalanceBefore.add(one)),
            "stanleyDaiBalanceAfter < stanleyDaiBalanceBefore + one"
        ).to.be.true;
        expect(
            stanleyUsdcBalanceAfter.lt(stanleyUsdcBalanceBefore.add(one)),
            "stanleyUsdcBalanceAfter < stanleyUsdcBalanceBefore + one"
        ).to.be.true;
        expect(
            stanleyUsdtBalanceAfter.lt(stanleyUsdtBalanceBefore.add(one)),
            "stanleyUsdtBalanceAfter < stanleyUsdtBalanceBefore +one"
        ).to.be.true;
    });

    it("Should not be able withdraw when stanley is pause", async () => {
        // given
        const one = BigNumber.from("1000000000000000000");
        const stanleyDaiBalanceBefore = await stanleyDai.totalBalance(miltonDai.address);
        const stanleyUsdcBalanceBefore = await stanleyUsdc.totalBalance(miltonUsdc.address);
        const stanleyUsdtBalanceBefore = await stanleyUsdt.totalBalance(miltonUsdt.address);
        //when
        await expect(josephDai.withdrawFromStanley(one)).to.be.revertedWith("Pausable: paused");
        await expect(josephUsdc.withdrawFromStanley(one)).to.be.revertedWith("Pausable: paused");
        await expect(josephUsdt.withdrawFromStanley(one)).to.be.revertedWith("Pausable: paused");

        // then
        const stanleyDaiBalanceAfter = await stanleyDai.totalBalance(miltonDai.address);
        const stanleyUsdcBalanceAfter = await stanleyUsdc.totalBalance(miltonUsdc.address);
        const stanleyUsdtBalanceAfter = await stanleyUsdt.totalBalance(miltonUsdt.address);

        expect(
            stanleyDaiBalanceAfter.gte(stanleyDaiBalanceBefore),
            "stanleyDaiBalanceAfter > stanleyDaiBalanceBefore"
        ).to.be.true;
        expect(
            stanleyUsdcBalanceAfter.gte(stanleyUsdcBalanceBefore),
            "stanleyUsdcBalanceAfter > stanleyUsdcBalanceBefore"
        ).to.be.true;
        expect(
            stanleyUsdtBalanceAfter.gte(stanleyUsdtBalanceBefore),
            "stanleyUsdtBalanceAfter > stanleyUsdtBalanceBefore"
        ).to.be.true;
    });
});

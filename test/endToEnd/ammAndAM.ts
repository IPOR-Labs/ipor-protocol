import { getEnabledCategories } from "node:trace_events";
import hre, { upgrades } from "hardhat";
import { BigNumber } from "ethers";
const { expect } = require("chai");
import {
    ERC20,
    IpToken,
    IvToken,
    MiltonFaucet,
    AaveStrategy,
    CompoundStrategy,
    StanleyDai,
    StanleyUsdc,
    StanleyUsdt,
    MiltonStorageDai,
    MiltonStorageUsdc,
    MiltonStorageUsdt,
    MiltonSpreadModel,
    Warren,
    MiltonUsdc,
    MiltonUsdt,
    MiltonDai,
    JosephDai,
    JosephUsdc,
    JosephUsdt,
} from "../../types";

import {
    aaveTokenFactory,
    aaveUsdtStrategyFactory,
    aaveUsdcStrategyFactory,
    aaveDaiStrategyFactory,
    aaveStrategySetup,
} from "./aave";

import {
    compTokenFactory,
    compoundDaiStrategyFactory,
    compoundUsdcStrategyFactory,
    compoundUsdtStrategyFactory,
    compoundStrategySetup,
} from "./compound";
import {
    miltonFaucetFactory,
    miltonFaucetSetup,
    transferFromFaucetTo,
    miltonStorageDaiFactory,
    miltonStorageUsdcFactory,
    miltonStorageUsdtFactory,
    miltonStorageSetup,
    miltonSpreadModelFactory,
    miltonDaiFactory,
    miltonUsdcFactory,
    miltonUsdtFactory,
    miltonSetup,
} from "./milton";
import {
    aDaiFactory,
    aUsdcFactory,
    aUsdtFactory,
    cDaiFactory,
    cUsdcFactory,
    cUsdtFactory,
    daiFactory,
    usdcFactory,
    usdtFactory,
    ipTokenUsdcFactory,
    ipTokenUsdtFactory,
    ipTokenDaiFactory,
    ipTokenSetup,
    ivTokenUsdcFactory,
    ivTokenUsdtFactory,
    ivTokenDaiFactory,
    ivTokenSetup,
} from "./tokens";
import { josephDaiFactory, josephUsdcFactory, josephUsdtFactory } from "./joseph";

import { warrenFactory, warrenSetup, initIporValuse } from "./warren";
import { stanleyDaiFactory, stanleyUsdcFactory, stanleyUsdtFactory, stanleySetup } from "./stanley";

// Mainnet Fork and test case for mainnet with hardhat network by impersonate account from mainnet
// work for blockNumber: 14222087,
describe("End to End tests on mainnet fork", function () {
    if (process.env.FORK_ENABLED != "true") {
        return;
    }

    let dai: ERC20;
    let usdc: ERC20;
    let usdt: ERC20;

    let aDai: ERC20;
    let aUsdc: ERC20;
    let aUsdt: ERC20;

    let aaveToken: ERC20;
    let compToken: ERC20;

    let cDai: ERC20;
    let cUsdc: ERC20;
    let cUsdt: ERC20;

    let miltonFaucet: MiltonFaucet;

    let ipTokenDai: IpToken;
    let ipTokenUsdc: IpToken;
    let ipTokenUsdt: IpToken;

    let ivTokenDai: IvToken;
    let ivTokenUsdc: IvToken;
    let ivTokenUsdt: IvToken;

    let strategyAaveDai: AaveStrategy;
    let strategyAaveUsdc: AaveStrategy;
    let strategyAaveUsdt: AaveStrategy;

    let strategyCompoundDai: CompoundStrategy;
    let strategyCompoundUsdc: CompoundStrategy;
    let strategyCompoundUsdt: CompoundStrategy;

    let stanleyDai: StanleyDai;
    let stanleyUsdc: StanleyUsdc;
    let stanleyUsdt: StanleyUsdt;

    let miltonStorageDai: MiltonStorageDai;
    let miltonStorageUsdc: MiltonStorageUsdc;
    let miltonStorageUsdt: MiltonStorageUsdt;
    let miltonSpreadModel: MiltonSpreadModel;

    let warren: Warren;

    let miltonDai: MiltonDai;
    let miltonUsdc: MiltonUsdc;
    let miltonUsdt: MiltonUsdt;

    let josephDai: JosephDai;
    let josephUsdc: JosephUsdc;
    let josephUsdt: JosephUsdt;

    before(async () => {
        miltonFaucet = await miltonFaucetFactory();

        aUsdc = await aUsdcFactory();
        aUsdt = await aUsdtFactory();
        aDai = await aDaiFactory();

        cUsdc = await cUsdcFactory();
        cUsdt = await cUsdtFactory();
        cDai = await cDaiFactory();

        usdc = await usdcFactory();
        usdt = await usdtFactory();
        dai = await daiFactory();

        aaveToken = await aaveTokenFactory();

        ipTokenUsdt = await ipTokenUsdtFactory();
        ipTokenUsdc = await ipTokenUsdcFactory();
        ipTokenDai = await ipTokenDaiFactory();

        ivTokenUsdt = await ivTokenUsdtFactory();
        ivTokenUsdc = await ivTokenUsdcFactory();
        ivTokenDai = await ivTokenDaiFactory();

        strategyAaveDai = await aaveDaiStrategyFactory();
        strategyAaveUsdc = await aaveUsdcStrategyFactory();
        strategyAaveUsdt = await aaveUsdtStrategyFactory();

        compToken = await compTokenFactory();

        strategyCompoundDai = await compoundDaiStrategyFactory();
        strategyCompoundUsdc = await compoundUsdcStrategyFactory();
        strategyCompoundUsdt = await compoundUsdtStrategyFactory();

        stanleyDai = await stanleyDaiFactory(
            ivTokenDai.address,
            strategyAaveDai.address,
            strategyCompoundDai.address
        );
        stanleyUsdc = await stanleyUsdcFactory(
            ivTokenUsdc.address,
            strategyAaveUsdc.address,
            strategyCompoundUsdc.address
        );
        stanleyUsdt = await stanleyUsdtFactory(
            ivTokenUsdt.address,
            strategyAaveUsdt.address,
            strategyCompoundUsdt.address
        );

        miltonStorageDai = await miltonStorageDaiFactory();
        miltonStorageUsdc = await miltonStorageUsdcFactory();
        miltonStorageUsdt = await miltonStorageUsdtFactory();
        miltonSpreadModel = await miltonSpreadModelFactory();

        warren = await warrenFactory();
        warren.deployed();

        miltonDai = await miltonDaiFactory(
            ipTokenDai.address,
            warren.address,
            miltonStorageDai.address,
            miltonSpreadModel.address,
            stanleyDai.address
        );
        miltonUsdc = await miltonUsdcFactory(
            ipTokenUsdc.address,
            warren.address,
            miltonStorageUsdc.address,
            miltonSpreadModel.address,
            stanleyUsdc.address
        );
        miltonUsdt = await miltonUsdtFactory(
            ipTokenUsdt.address,
            warren.address,
            miltonStorageUsdt.address,
            miltonSpreadModel.address,
            stanleyUsdt.address
        );

        josephDai = await josephDaiFactory(
            ipTokenDai.address,
            miltonDai.address,
            miltonStorageDai.address,
            stanleyDai.address
        );
        josephUsdc = await josephUsdcFactory(
            ipTokenUsdc.address,
            miltonUsdc.address,
            miltonStorageUsdc.address,
            stanleyUsdc.address
        );
        josephUsdt = await josephUsdtFactory(
            ipTokenUsdt.address,
            miltonUsdt.address,
            miltonStorageUsdt.address,
            stanleyUsdt.address
        );

        // #####################################################################
        // ##################          Setup            ########################
        // #####################################################################
        await miltonSetup(miltonDai, josephDai, stanleyDai);
        await miltonSetup(miltonUsdc, josephUsdc, stanleyUsdc);
        await miltonSetup(miltonUsdt, josephUsdt, stanleyUsdt);

        await ipTokenSetup(ipTokenDai, josephDai.address);
        await ipTokenSetup(ipTokenUsdc, josephUsdc.address);
        await ipTokenSetup(ipTokenUsdt, josephUsdt.address);

        await miltonStorageSetup(miltonStorageDai, miltonDai, josephDai);
        await miltonStorageSetup(miltonStorageUsdc, miltonUsdc, josephUsdc);
        await miltonStorageSetup(miltonStorageUsdt, miltonUsdt, josephUsdt);

        await stanleySetup(stanleyDai, miltonDai.address);
        await stanleySetup(stanleyUsdc, miltonUsdc.address);
        await stanleySetup(stanleyUsdt, miltonUsdt.address);

        await ivTokenSetup(ivTokenDai, stanleyDai.address);
        await ivTokenSetup(ivTokenUsdc, stanleyUsdc.address);
        await ivTokenSetup(ivTokenUsdt, stanleyUsdt.address);

        await aaveStrategySetup(strategyAaveDai, stanleyDai.address);
        await aaveStrategySetup(strategyAaveUsdc, stanleyUsdc.address);
        await aaveStrategySetup(strategyAaveUsdt, stanleyUsdt.address);

        await compoundStrategySetup(strategyCompoundDai, stanleyDai.address);
        await compoundStrategySetup(strategyCompoundUsdc, stanleyUsdc.address);
        await compoundStrategySetup(strategyCompoundUsdt, stanleyUsdt.address);

        await warrenSetup(warren);
        await initIporValuse(warren);

        await miltonFaucetSetup(miltonFaucet, dai, usdc, usdt);
    });

    it("Should deposit to stanley Dai", async () => {
        // given
        const stanleyDaiBalanceBefore = await stanleyDai.totalBalance(miltonDai.address);

        await transferFromFaucetTo(
            miltonFaucet,
            dai,
            miltonDai.address,
            BigNumber.from("10000000000000000000")
        );
        //when
        await josephDai.depositToStanley(BigNumber.from("1000000000000000000"));

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
            miltonFaucet,
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
            miltonFaucet,
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
        const stanleyUsdtBalanceBefore = await stanleyUsdt.totalBalance(miltonUsdt.address);

        // when
        await expect(
            josephUsdt.withdrawFromStanley(BigNumber.from("100000000000000000"))
        ).to.be.revertedWith("IPOR_332");

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

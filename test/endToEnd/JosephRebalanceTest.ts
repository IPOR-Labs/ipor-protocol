import hre from "hardhat";
import { expect } from "chai";
import { BigNumber, Signer } from "ethers";
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
    IpToken,
    IvToken,
} from "../../types";

import { deploy, DeployType, setup } from "./deploy";
import { assertError } from "../utils/AssertUtils";

import { transferUsdtToAddress, transferUsdcToAddress, transferDaiToAddress } from "./tokens";
import { N0__01_18DEC, N0__1_18DEC, N1__0_18DEC, N1__0_6DEC, ZERO } from "../utils/Constants";

describe("Joseph rebalance, deposit/withdraw from vault", function () {
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

    let stanleyDai: StanleyDai;
    let stanleyUsdc: StanleyUsdc;
    let stanleyUsdt: StanleyUsdt;

    let strategyAaveDai: StrategyAave;
    let strategyAaveDaiV2: StrategyAave;
    let strategyAaveUsdc: StrategyAave;
    let strategyAaveUsdt: StrategyAave;

    let strategyCompoundDai: StrategyCompound;
    let strategyCompoundUsdt: StrategyCompound;
    let strategyCompoundUsdc: StrategyCompound;

    let dai: ERC20;
    let usdc: ERC20;
    let usdt: ERC20;

    let cUsdt: MockCUSDT;

    let ipTokenDai: IpToken;
    let ipTokenUsdc: IpToken;
    let ipTokenUsdt: IpToken;

    let ivTokenDai: IvToken;
    let ivTokenUsdt: IvToken;
    let ivTokenUsdc: IvToken;

    let testnetFaucet: TestnetFaucet;

    before(async () => {
        [admin] = await hre.ethers.getSigners();

        const deployed: DeployType = await deploy(admin);
        ({
            testnetFaucet,
            usdc,
            usdt,
            dai,
            cUsdt,
            strategyAaveDai,
            strategyAaveDaiV2,
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
            ipTokenDai,
            ipTokenUsdc,
            ipTokenUsdt,
            ivTokenDai,
            ivTokenUsdt,
            ivTokenUsdc,
        } = deployed);

        await setup(deployed);
    });

    it("ProvideLiquidity for DAI", async () => {
        //given
        const deposit = BigNumber.from("10").mul(N1__0_18DEC);
        await transferDaiToAddress(testnetFaucet.address, await admin.getAddress(), deposit);
        await dai
            .connect(admin)
            .approve(josephDai.address, BigNumber.from("1000").mul(N1__0_18DEC));

        //when
        await josephDai.connect(admin).provideLiquidity(deposit);

        //then
        const daiMiltonBalanceAfter = await dai.balanceOf(miltonDai.address);
        expect(daiMiltonBalanceAfter, "daiMiltonBalanceAfter").to.be.equal(deposit);
    });

    it("Should rebalance and deposit(DAI) into vault (AAVE)", async () => {
        //given
        const deposit = BigNumber.from("10").mul(N1__0_18DEC);
        await josephDai.connect(admin).provideLiquidity(deposit);

        const strategyAaveBalanceBefore = await strategyAaveDai.balanceOf();
        const strategyCompoundBalanceBefore = await strategyCompoundDai.balanceOf();
        const miltonAssetBalanceBefore = await dai.balanceOf(miltonDai.address);
        const ivTokenBalanceBefore = await ivTokenDai.balanceOf(miltonDai.address);

        //when
        await josephDai.rebalance();

        //then
        const miltonAssetBalanceAfter = await dai.balanceOf(miltonDai.address);
        const strategyCompoundBalanceAfter = await strategyCompoundDai.balanceOf();
        const strategyAaveBalanceAfter = await strategyAaveDai.balanceOf();
        const ivTokenBalanceAfter = await ivTokenDai.balanceOf(miltonDai.address);

        expect(
            strategyAaveBalanceBefore.lt(strategyAaveBalanceAfter),
            "strategyAaveBalanceBefore < strategyAaveBalanceAfter"
        ).to.be.true;

        expect(strategyAaveBalanceBefore.eq(ZERO), "strategyAaveBalanceBefore = 0").to.be.true;

        expect(strategyCompoundBalanceBefore.eq(ZERO), "strategyCompoundBalanceBefore = 0").to.be
            .true;

        expect(
            miltonAssetBalanceBefore.eq(BigNumber.from("20").mul(N1__0_18DEC)),
            "miltonAssetBalanceBefore = 20"
        ).to.be.true;

        expect(
            miltonAssetBalanceAfter.eq(BigNumber.from("17").mul(N1__0_18DEC)),
            "miltonAssetBalanceAfter = 17"
        ).to.be.true;

        expect(
            strategyAaveBalanceAfter.eq(BigNumber.from("3").mul(N1__0_18DEC)),
            "strategyAaveBalanceAfter = 3"
        ).to.be.true;

        expect(
            strategyCompoundBalanceBefore.eq(strategyCompoundBalanceAfter),
            "strategyCompoundBalanceBefore = strategyCompoundBalanceAfter"
        ).to.be.true;

        expect(
            ivTokenBalanceBefore.lt(ivTokenBalanceAfter),
            "ivTokenBalanceBefore < ivTokenBalanceAfter"
        ).to.be.true;
    });

    it("Should set new AAVE strategy and rebalance and deposit(DAI) into vault (AAVE)", async () => {
        //given
        const deposit = BigNumber.from("10").mul(N1__0_18DEC);
        await transferDaiToAddress(testnetFaucet.address, await admin.getAddress(), deposit);
        await josephDai.connect(admin).provideLiquidity(deposit);

        const strategyAaveBalanceV2BeforeSet = await strategyAaveDaiV2.balanceOf();
        const strategyAaveBalanceBefore = await strategyAaveDai.balanceOf();

        const oldAaveStrategyAddress = await stanleyDai.getStrategyAave();
        await stanleyDai.setStrategyAave(strategyAaveDaiV2.address);
        const strategyAaveBalanceV2AfterSet = await strategyAaveDaiV2.balanceOf();
        const miltonAssetBalanceBefore = await dai.balanceOf(miltonDai.address);
        const ivTokenBalanceBefore = await ivTokenDai.balanceOf(miltonDai.address);

        // when
        await josephDai.rebalance();

        //then
        const miltonAssetBalanceAfter = await dai.balanceOf(miltonDai.address);
        const ivTokenBalanceAfter = await ivTokenDai.balanceOf(miltonDai.address);
        expect(
            miltonAssetBalanceAfter.lt(miltonAssetBalanceBefore),
            "miltonAssetBalanceAfter < miltonAssetBalanceBefore"
        ).to.be.true;

        const strategyAaveBalanceV2AfterRebalance = await strategyAaveDaiV2.balanceOf();
        const strategyAaveBalanceAfterRebalance = await strategyAaveDai.balanceOf();

        expect(strategyAaveBalanceV2BeforeSet).to.be.equal(ZERO);
        expect(strategyAaveBalanceAfterRebalance).to.be.equal(ZERO);

        expect(
            strategyAaveBalanceV2BeforeSet.lt(strategyAaveBalanceV2AfterSet),
            "strategyAaveBalanceV2BeforeSet < strategyAaveBalanceV2AfterSet"
        ).to.be.true;

        expect(
            strategyAaveBalanceBefore.lt(strategyAaveBalanceV2AfterRebalance),
            "strategyAaveBalanceBefore < strategyAaveBalanceV2AfterRebalance"
        ).to.be.true;

        const balanceMinimum = BigNumber.from("3").mul(N1__0_18DEC);
        expect(
            balanceMinimum.lt(strategyAaveBalanceV2AfterRebalance),
            "balanceMinimum < strategyAaveBalanceV2AfterRebalance"
        ).to.be.true;

        expect(
            ivTokenBalanceBefore.lt(ivTokenBalanceAfter),
            "ivTokenBalanceBefore < ivTokenBalanceAfter"
        ).to.be.true;

        await stanleyDai.setStrategyAave(oldAaveStrategyAddress);
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

    it("Should rebalance and withdraw(DAI) from vault (AAVE)", async () => {
        //given

        const strategyAaveBalanceBefore = await strategyAaveDai.balanceOf();
        const strategyCompoundBalanceBefore = await strategyCompoundDai.balanceOf();
        const miltonAssetBalanceBefore = await dai.balanceOf(miltonDai.address);
        const ivTokenBalanceBefore = await ivTokenDai.balanceOf(miltonDai.address);

        await hre.network.provider.send("evm_mine");
        await hre.network.provider.send("evm_mine");
        await hre.network.provider.send("evm_mine");

        //when
        await josephDai.rebalance();

        //then
        const strategyAaveBalanceAfter = await strategyAaveDai.balanceOf();
        const miltonAssetBalanceAfter = await dai.balanceOf(miltonDai.address);
        const strategyCompoundBalanceAfter = await strategyCompoundDai.balanceOf();
        const ivTokenBalanceAfter = await ivTokenDai.balanceOf(miltonDai.address);

        expect(
            strategyAaveBalanceBefore.gt(strategyAaveBalanceAfter),
            "strategyAaveBalanceBefore > strategyAaveBalanceAfter"
        ).to.be.true;

        expect(
            strategyCompoundBalanceBefore.eq(strategyCompoundBalanceAfter),
            "strategyCompoundBalanceBefore = strategyCompoundBalanceAfter"
        ).to.be.true;

        expect(strategyCompoundBalanceBefore.eq(ZERO), "strategyCompoundBalanceBefore = 0").to.be
            .true;

        expect(
            miltonAssetBalanceAfter.gt(miltonAssetBalanceBefore),
            "miltonAssetBalanceAfter > miltonAssetBalanceBefore"
        ).to.be.true;

        expect(
            ivTokenBalanceBefore.gte(ivTokenBalanceAfter),
            "ivTokenBalanceBefore >= ivTokenBalanceAfter"
        ).to.be.true;
    });

    it("ProvideLiquidity for USDC", async () => {
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

    it("Should rebalance and deposit(USDC) into vault (AAVE)", async () => {
        //given
        const deposit = BigNumber.from("1000").mul(N1__0_6DEC);
        await josephUsdc.connect(admin).provideLiquidity(deposit);

        const strategyAaveBalanceBefore = await strategyAaveUsdc.balanceOf();
        const strategyCompoundBalanceBefore = await strategyCompoundUsdc.balanceOf();
        const miltonAssetBalanceBefore = await usdc.balanceOf(miltonUsdc.address);
        const ivTokenBalanceBefore = await ivTokenUsdc.balanceOf(miltonUsdc.address);

        //when
        await josephUsdc.rebalance();

        //then
        const strategyAaveBalanceAfter = await strategyAaveUsdc.balanceOf();
        const strategyCompoundBalanceAfter = await strategyCompoundUsdc.balanceOf();
        const miltonAssetBalanceAfter = await usdc.balanceOf(miltonUsdc.address);
        const ivTokenBalanceAfter = await ivTokenUsdc.balanceOf(miltonUsdc.address);

        expect(
            strategyAaveBalanceBefore.lt(strategyAaveBalanceAfter),
            "strategyAaveBalanceBefore < strategyAaveBalanceAfter"
        ).to.be.true;

        expect(
            strategyCompoundBalanceBefore.eq(strategyCompoundBalanceAfter),
            "strategyCompoundBalanceBefore = strategyCompoundBalanceAfter"
        ).to.be.true;

        expect(strategyAaveBalanceBefore.eq(ZERO), "strategyAaveBalanceBefore = 0").to.be.true;
        expect(strategyCompoundBalanceBefore.eq(ZERO), "strategyCompoundBalanceBefore = 0").to.be
            .true;

        expect(
            miltonAssetBalanceBefore.eq(BigNumber.from("2000").mul(N1__0_6DEC)),
            "miltonAssetBalanceBefore = 2000"
        ).to.be.true;

        expect(
            miltonAssetBalanceAfter.eq(BigNumber.from("1700").mul(N1__0_6DEC)),
            "miltonAssetBalanceAfter = 1700"
        ).to.be.true;

        expect(
            strategyAaveBalanceAfter.gte(BigNumber.from("300").mul(N1__0_18DEC)),
            "strategyAaveBalanceAfter > 300"
        ).to.be.true;

        expect(
            strategyAaveBalanceAfter.lt(BigNumber.from("301").mul(N1__0_18DEC)),
            "strategyAaveBalanceAfter < 301"
        ).to.be.true;

        expect(
            ivTokenBalanceAfter.gt(ivTokenBalanceBefore),
            "ivTokenBalanceAfter > ivTokenBalanceBefore"
        ).to.be.true;
    });

    it("Redeem tokens from Joseph(USDC)", async () => {
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

    it("Should rebalance and withdraw(USDC) from vault (AAVE)", async () => {
        //given
        const deposit = BigNumber.from("1000").mul(N1__0_18DEC);
        await josephUsdc.depositToStanley(deposit);

        const strategyAaveBalanceBefore = await strategyAaveUsdc.balanceOf();
        const strategyCompoundBalanceBefore = await strategyCompoundUsdc.balanceOf();
        const miltonAssetBalanceBefore = await usdc.balanceOf(miltonUsdc.address);
        const ivTokenBalanceBefore = await ivTokenUsdc.balanceOf(miltonUsdc.address);

        //when
        await josephUsdc.rebalance();

        //then
        const strategyAaveBalanceAfter = await strategyAaveUsdc.balanceOf();
        const strategyCompoundBalanceAfter = await strategyCompoundUsdc.balanceOf();
        const miltonAssetBalanceAfter = await usdc.balanceOf(miltonUsdc.address);
        const ivTokenBalanceAfter = await ivTokenUsdc.balanceOf(miltonUsdc.address);

        expect(
            strategyAaveBalanceBefore.gt(strategyAaveBalanceAfter),
            "strategyAaveBalanceBefore > strategyAaveBalanceAfter"
        ).to.be.true;

        expect(
            strategyCompoundBalanceBefore.eq(strategyCompoundBalanceAfter),
            "strategyCompoundBalanceBefore = strategyCompoundBalanceAfter"
        ).to.be.true;

        expect(strategyCompoundBalanceBefore.eq(ZERO), "strategyCompoundBalanceBefore = 0").to.be
            .true;

        expect(
            strategyAaveBalanceAfter.lte(strategyAaveBalanceBefore),
            "strategyAaveBalanceAfter < strategyAaveBalanceBefore"
        ).to.be.true;

        /// means that was withdraw from Stanley
        expect(
            miltonAssetBalanceAfter.gte(
                miltonAssetBalanceBefore.add(BigNumber.from("1000").mul(N1__0_6DEC))
            ),
            "miltonAssetBalanceAfter > miltonAssetBalanceBefore + 1000"
        ).to.be.true;

        expect(
            ivTokenBalanceAfter.lt(ivTokenBalanceBefore),
            "ivTokenBalanceAfter < ivTokenBalanceBefore"
        ).to.be.true;
    });

    it("ProvideLiquidity for USDT", async () => {
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

    it("Should rebalance and deposit(USDT) into vault (Compound)", async () => {
        //given
        const deposit = BigNumber.from("1000").mul(N1__0_6DEC);
        await josephUsdt.connect(admin).provideLiquidity(deposit);

        const strategyAaveBalanceBefore = await strategyAaveUsdt.balanceOf();
        const strategyCompoundBalanceBefore = await strategyCompoundUsdt.balanceOf();
        const miltonAssetBalanceBefore = await usdt.balanceOf(miltonUsdt.address);
        const ivTokenBalanceBefore = await ivTokenUsdt.balanceOf(miltonUsdt.address);

        //when
        await josephUsdt.rebalance();

        //then
        const strategyAaveBalanceAfter = await strategyAaveUsdt.balanceOf();
        const strategyCompoundBalanceAfter = await strategyCompoundUsdt.balanceOf();
        const miltonAssetBalanceAfter = await usdt.balanceOf(miltonUsdt.address);
        const ivTokenBalanceAfter = await ivTokenUsdt.balanceOf(miltonUsdt.address);

        expect(
            strategyAaveBalanceBefore.eq(strategyAaveBalanceAfter),
            "strategyAaveBalanceBefore = strategyAaveBalanceAfter"
        ).to.be.true;

        expect(
            strategyCompoundBalanceBefore.lt(strategyCompoundBalanceAfter),
            "strategyCompoundBalanceBefore < strategyCompoundBalanceAfter"
        ).to.be.true;

        expect(strategyAaveBalanceBefore.eq(ZERO), "strategyAaveBalanceBefore = 0").to.be.true;

        expect(strategyCompoundBalanceBefore.eq(ZERO), "strategyCompoundBalanceBefore = 0").to.be
            .true;

        expect(
            miltonAssetBalanceBefore.eq(BigNumber.from("2000").mul(N1__0_6DEC)),
            "miltonAssetBalanceBefore = 2000"
        ).to.be.true;

        expect(
            miltonAssetBalanceAfter.eq(BigNumber.from("1700").mul(N1__0_6DEC)),
            "miltonAssetBalanceAfter = 1700"
        ).to.be.true;

        expect(
            strategyCompoundBalanceAfter.lte(BigNumber.from("300").mul(N1__0_18DEC)),
            "strategyCompoundBalanceAfter <= 300"
        ).to.be.true;
        expect(
            strategyCompoundBalanceAfter.gt(BigNumber.from("299").mul(N1__0_18DEC)),
            "strategyCompoundBalanceAfter > 299"
        ).to.be.true;

        /// @dev [!] important test for Compound strategy
        await cUsdt.accrueInterest();

        const strategyCompoundBalanceAfterAccrued = await strategyCompoundUsdt.balanceOf();

        expect(
            strategyCompoundBalanceAfterAccrued.gt(BigNumber.from("300").mul(N1__0_18DEC)),
            "strategyCompoundBalanceAfterAccrued > 300"
        ).to.be.true;

        expect(
            ivTokenBalanceBefore.lt(ivTokenBalanceAfter),
            "ivTokenBalanceBefore < ivTokenBalanceAfter"
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

    it("Should rebalance and withdraw(USDT) from vault (Compound)", async () => {
        //given
        await josephUsdt.rebalance();

        for (let i = 0; i < 10; i++) {
            await hre.network.provider.send("evm_mine");
            await cUsdt.accrueInterest();
        }

        const strategyAaveBalanceBefore = await strategyAaveUsdt.balanceOf();
        const strategyCompoundBalanceBefore = await strategyCompoundUsdt.balanceOf();
        const miltonAssetBalanceBefore = await usdt.balanceOf(miltonUsdt.address);
        const ivTokenBalanceBefore = await ivTokenUsdt.balanceOf(miltonUsdt.address);

        //when
        await josephUsdt.rebalance();

        //then
        const strategyAaveBalanceAfter = await strategyAaveUsdt.balanceOf();
        const strategyCompoundBalanceAfter = await strategyCompoundUsdt.balanceOf();
        const miltonAssetBalanceAfter = await usdt.balanceOf(miltonUsdt.address);
        const ivTokenBalanceAfter = await ivTokenUsdt.balanceOf(miltonUsdt.address);

        expect(
            strategyAaveBalanceBefore.eq(strategyAaveBalanceAfter),
            "strategyAaveBalanceBefore = strategyAaveBalanceAfter"
        ).to.be.true;

        expect(strategyAaveBalanceBefore.eq(ZERO), "strategyAaveBalanceBefore = 0").to.be.true;

        expect(
            strategyCompoundBalanceBefore.gte(strategyCompoundBalanceAfter),
            "strategyCompoundBalanceBefore >= strategyCompoundBalanceAfter"
        ).to.be.true;

        /// means that was withdraw from Stanley
        expect(
            miltonAssetBalanceAfter.gte(miltonAssetBalanceBefore),
            "miltonAssetBalanceAfter > miltonAssetBalanceBefore"
        ).to.be.true;

        expect(
            ivTokenBalanceAfter.lt(ivTokenBalanceBefore),
            "ivTokenBalanceAfter < ivTokenBalanceBefore"
        ).to.be.true;
    });

    it("Should not change IP Token exchange rate when rebalance and withdraw all - usdc, 1% in Milton, 99% in Stanley", async () => {
        //given
        const oldMiltonStanleyBalanceRation = await josephUsdc.getMiltonStanleyBalanceRatio();
        //99% ERC20 balance move from Milton to Stanley
        await josephUsdc.setMiltonStanleyBalanceRatio(BigNumber.from("10000000000000000"));

        const deposit = BigNumber.from("1000").mul(N1__0_6DEC);

        await usdc
            .connect(admin)
            .approve(josephUsdc.address, BigNumber.from("100000").mul(N1__0_6DEC));

        await transferUsdcToAddress(
            testnetFaucet.address,
            await admin.getAddress(),
            BigNumber.from("10000").mul(N1__0_6DEC)
        );

        //when
        await josephUsdc.connect(admin).provideLiquidity(deposit);

        let exchangeRateBefore = await josephUsdc.connect(admin).calculateExchangeRate();

        //when
        await josephUsdc.rebalance();
        await josephUsdc.withdrawAllFromStanley();

        //then
        let exchangeRateAfter = await josephUsdc.connect(admin).calculateExchangeRate();
        const stanleyBalance = await usdc.balanceOf(stanleyUsdc.address);
        const exchangeRateBeforeLittleHigher = exchangeRateBefore.add(
            BigNumber.from("1100000000000")
        );
        expect(exchangeRateBeforeLittleHigher.gt(exchangeRateAfter)).to.be.true;
        expect(stanleyBalance.eq(0)).to.be.true;

        await josephUsdc.setMiltonStanleyBalanceRatio(oldMiltonStanleyBalanceRation);
    });

    it("Should not change IP Token exchange rate when rebalance and withdraw ALMOST all - usdc, 1% in Milton, 99% in Stanley", async () => {
        // given
        const oldMaxLpAccountContribution = await josephUsdc.getMaxLpAccountContribution();
        const oldMiltonStanleyBalanceRation = await josephUsdc.getMiltonStanleyBalanceRatio();
        //99% ERC20 balance move from Milton to Stanley
        await josephUsdc.setMiltonStanleyBalanceRatio(BigNumber.from("10000000000000000"));
        await josephUsdc.setMaxLpAccountContribution(BigNumber.from("1000000"));

        const deposit = BigNumber.from("100000").mul(N1__0_6DEC);

        await usdc
            .connect(admin)
            .approve(josephUsdc.address, BigNumber.from("10000000").mul(N1__0_6DEC));

        await transferUsdcToAddress(
            testnetFaucet.address,
            await admin.getAddress(),
            BigNumber.from(deposit)
        );

        await josephUsdc.connect(admin).provideLiquidity(deposit);

        let exchangeRateBefore = await josephUsdc.connect(admin).calculateExchangeRate();

        //when
        await josephUsdc.rebalance();
        await josephUsdc.withdrawFromStanley(BigNumber.from("98999000000000000000000"));

        //then
        let exchangeRateAfter = await josephUsdc.connect(admin).calculateExchangeRate();
        const stanleyBalance = await usdc.balanceOf(stanleyUsdc.address);

        const exchangeRateBeforeLittleHigher = exchangeRateBefore.add(
            BigNumber.from("1100000000000")
        );

        expect(exchangeRateBeforeLittleHigher.gt(exchangeRateAfter)).to.be.true;
        expect(stanleyBalance.eq(0)).to.be.true;

        //clean up
        await josephUsdc.setMiltonStanleyBalanceRatio(oldMiltonStanleyBalanceRation);
        await josephUsdc.setMaxLpAccountContribution(oldMaxLpAccountContribution);
    });

    it("Should not close position because Joseph rebalance from Milton to Stanley - usdc, 1% in Milton, 99% in Stanley", async () => {
        //given
        const oldMaxLpAccountContribution = await josephUsdc.getMaxLpAccountContribution();
        const oldMiltonStanleyBalanceRation = await josephUsdc.getMiltonStanleyBalanceRatio();
        //99% ERC20 balance move from Milton to Stanley
        await josephUsdc.setMiltonStanleyBalanceRatio(BigNumber.from("10000000000000000"));
        await josephUsdc.setMaxLpAccountContribution(BigNumber.from("1000000"));

        const accountBalance = BigNumber.from("1000000").mul(N1__0_6DEC);

        await transferUsdcToAddress(
            testnetFaucet.address,
            await admin.getAddress(),
            accountBalance
        );

        await usdc.connect(admin).approve(josephUsdc.address, accountBalance);
        await usdc.connect(admin).approve(miltonUsdc.address, accountBalance);

        await josephUsdc.connect(admin).provideLiquidity(BigNumber.from("200000").mul(N1__0_6DEC));

        await miltonUsdc
            .connect(admin)
            .openSwapPayFixed(
                BigNumber.from("100000").mul(N1__0_6DEC),
                BigNumber.from("90000000000000000"),
                BigNumber.from("1000000000000000000000")
            );

        //when
        await josephUsdc.rebalance();

        //then
        await assertError(
            //when
            miltonUsdc.closeSwapPayFixed(1),
            //then
            "ERC20: transfer amount exceeds balance"
        );

        //clean up
        await josephUsdc.setMiltonStanleyBalanceRatio(oldMiltonStanleyBalanceRation);
        await josephUsdc.setMaxLpAccountContribution(oldMaxLpAccountContribution);
    });
});

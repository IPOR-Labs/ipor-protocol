import hre, { upgrades } from "hardhat";
import chai from "chai";
const keccak256 = require("keccak256");
import { BigNumber, Signer } from "ethers";

import { solidity } from "ethereum-waffle";
import {
    StrategyAave,
    StrategyCompound,
    TestERC20,
    MockADai as MockADAI,
    MockAaveLendingPoolProvider,
    MockAaveLendingPoolCore,
    AaveInterestRateMockStrategyV2,
    MockAaveStableDebtToken,
    MockAaveVariableDebtToken,
    MockAaveLendingPoolV2,
    MockStakedAave,
    MockAaveIncentivesController,
    StanleyDai,
    MockCDAI,
    MockWhitePaper,
    MockComptroller,
    IvToken,
} from "../../../../types";
import { ZERO } from "../../../utils/Constants";

chai.use(solidity);
const { expect } = chai;

describe("Stanley -> Withdraw", () => {
    // let wallet: Wallet
    const one = BigNumber.from("1000000000000000000");
    const oneRay = BigNumber.from("1000000000000000000000000000");
    const zero = BigNumber.from("0");

    let admin: Signer, userOne: Signer, userTwo: Signer;

    let stanley: StanleyDai;
    let DAI: TestERC20;
    let tokenFactory: any;

    let aDAI: MockADAI;
    let AAVE: TestERC20;
    let aaveNewStartegyInstance: StrategyAave;
    let lendingPool: MockAaveLendingPoolV2;
    let stakedAave: MockStakedAave;

    let cDAI: MockCDAI;
    let compoundStartegyInstance: StrategyCompound;
    let comptroller: MockComptroller;
    let COMP: TestERC20;
    let ivToken: IvToken;

    const TC_AAVE_CURRENT_LIQUIDITY_RATE = oneRay.div("100").mul("10");
    const TC_AMOUNT_10_USD_18DEC = one.mul(10);
    const TC_AMOUNT_10000_USD_18DEC = one.mul(10000);

    beforeEach(async () => {
        //##############################################################
        //                          Users
        //##############################################################
        [admin, userOne, userTwo] = await hre.ethers.getSigners();

        //##############################################################
        //                          Tokens
        //##############################################################

        tokenFactory = await hre.ethers.getContractFactory("TestERC20");
        DAI = (await tokenFactory.deploy(BigNumber.from(2).pow(255))) as TestERC20;

        //##############################################################
        //                        IvToken
        //##############################################################
        const tokenFactoryIvToken = await hre.ethers.getContractFactory("IvToken");
        ivToken = (await tokenFactoryIvToken.deploy("IvToken", "IVT", DAI.address)) as IvToken;

        //##############################################################
        //                        AAVE Mock
        //##############################################################

        const MockADAIFactory = await hre.ethers.getContractFactory("MockADAI");
        aDAI = (await MockADAIFactory.deploy(DAI.address, await admin.getAddress())) as MockADAI;
        DAI.mint(aDAI.address, one.mul(10000));
        AAVE = (await tokenFactory.deploy(BigNumber.from(2).pow(255))) as TestERC20;
        const stkAAVE = (await tokenFactory.deploy(BigNumber.from(2).pow(255))) as TestERC20;
        const MockAaveLendingPoolProvider = await hre.ethers.getContractFactory(
            "MockAaveLendingPoolProvider"
        );
        const MockAaveLendingPoolCore = await hre.ethers.getContractFactory(
            "MockAaveLendingPoolCore"
        );
        const aaveInterestRateMockStrategyV2 = await hre.ethers.getContractFactory(
            "AaveInterestRateMockStrategyV2"
        );
        const MockAaveStableDebtToken = await hre.ethers.getContractFactory(
            "MockAaveStableDebtToken"
        );
        const MockAaveVariableDebtToken = await hre.ethers.getContractFactory(
            "MockAaveVariableDebtToken"
        );
        const MockAaveLendingPool = await hre.ethers.getContractFactory("MockAaveLendingPoolV2");
        const MockStakedAave = await hre.ethers.getContractFactory("MockStakedAave");
        const MockAaveIncentivesController = await hre.ethers.getContractFactory(
            "MockAaveIncentivesController"
        );
        const addressProvider =
            (await MockAaveLendingPoolProvider.deploy()) as MockAaveLendingPoolProvider;
        const lendingPoolCore = (await MockAaveLendingPoolCore.deploy()) as MockAaveLendingPoolCore;
        const interestRateStrategyV2 =
            (await aaveInterestRateMockStrategyV2.deploy()) as AaveInterestRateMockStrategyV2;
        const stableDebtToken = (await MockAaveStableDebtToken.deploy(
            0,
            0
        )) as MockAaveStableDebtToken;
        const variableDebtToken = (await MockAaveVariableDebtToken.deploy(
            0
        )) as MockAaveVariableDebtToken;
        lendingPool = (await MockAaveLendingPool.deploy(
            DAI.address,
            aDAI.address
        )) as MockAaveLendingPoolV2;
        stakedAave = (await MockStakedAave.deploy(AAVE.address)) as MockStakedAave;
        const aaveIncentivesController = (await MockAaveIncentivesController.deploy(
            stakedAave.address
        )) as MockAaveIncentivesController;
        await stakedAave.transfer(aaveIncentivesController.address, one.mul(1000));
        await AAVE.transfer(stakedAave.address, one.mul(1000));
        await addressProvider._setLendingPoolCore(lendingPoolCore.address);
        await addressProvider._setLendingPool(lendingPool.address);
        await lendingPoolCore.setReserve(interestRateStrategyV2.address);
        await lendingPoolCore.setReserveCurrentLiquidityRate(oneRay.div("100").mul("2"));
        await interestRateStrategyV2.setSupplyRate(oneRay.div("100").mul("2"));
        await interestRateStrategyV2.setBorrowRate(oneRay.div("100").mul("3"));
        await lendingPool.setStableDebtTokenAddress(stableDebtToken.address);
        await lendingPool.setVariableDebtTokenAddress(variableDebtToken.address);
        await lendingPool.setInterestRateStrategyAddress(interestRateStrategyV2.address);
        await lendingPool.setCurrentLiquidityRate(oneRay.div("100").mul("2"));
        aDAI.connect(admin).transfer(lendingPool.address, one.mul(1000));
        const aaveNewStartegy = await hre.ethers.getContractFactory("StrategyAave");
        aaveNewStartegyInstance = (await upgrades.deployProxy(aaveNewStartegy, [
            DAI.address,
            aDAI.address,
            addressProvider.address,
            stakedAave.address,
            aaveIncentivesController.address,
            AAVE.address,
        ])) as StrategyAave;
        await aaveNewStartegyInstance.setTreasuryManager(await admin.getAddress());
        await aaveNewStartegyInstance.setTreasury(await userTwo.getAddress());
        //##############################################################
        //                        Compound Mock
        //##############################################################
        const MockCDAIFactory = await hre.ethers.getContractFactory("MockCDAI");
        COMP = (await tokenFactory.deploy(BigNumber.from(2).pow(255))) as TestERC20;
        const MockWhitePaper = await hre.ethers.getContractFactory("MockWhitePaper");
        let MockWhitePaperInstance = (await MockWhitePaper.deploy()) as MockWhitePaper;
        cDAI = (await MockCDAIFactory.deploy(
            DAI.address,
            MockWhitePaperInstance.address
        )) as MockCDAI;
        DAI.mint(cDAI.address, TC_AMOUNT_10000_USD_18DEC);
        const MockComptroller = await hre.ethers.getContractFactory("MockComptroller");
        comptroller = (await MockComptroller.deploy(COMP.address, cDAI.address)) as MockComptroller;
        await COMP.transfer(comptroller.address, one.mul(1000));
        const compoundNewStartegy = await hre.ethers.getContractFactory("StrategyCompound");
        compoundStartegyInstance = (await upgrades.deployProxy(compoundNewStartegy, [
            DAI.address,
            cDAI.address,
            comptroller.address,
            COMP.address,
        ])) as StrategyCompound;
        await compoundStartegyInstance.setTreasuryManager(await admin.getAddress());
        await compoundStartegyInstance.setTreasury(await userTwo.getAddress());
        //##############################################################
        //                        Stanley
        //##############################################################
        const StanleyDaiFactory = await hre.ethers.getContractFactory("StanleyDai");
        stanley = (await await upgrades.deployProxy(StanleyDaiFactory, [
            DAI.address,
            ivToken.address,
            aaveNewStartegyInstance.address,
            compoundStartegyInstance.address,
        ])) as StanleyDai;
        await aaveNewStartegyInstance.setStanley(stanley.address);
        await compoundStartegyInstance.setStanley(stanley.address);
        await ivToken.setStanley(stanley.address);
        await stanley.setMilton(await admin.getAddress());

        //##############################################################
        //                        admin user setup
        //##############################################################
        await DAI.mint(await admin.getAddress(), TC_AMOUNT_10000_USD_18DEC);
    });

    it("Should withdraw from AAVE when only AAVE has funds and AAVE has max APR", async () => {
        //given
        const adminAddress = await await admin.getAddress();

        await DAI.approve(await admin.getAddress(), TC_AMOUNT_10000_USD_18DEC);
        await DAI.approve(stanley.address, TC_AMOUNT_10000_USD_18DEC);

        await lendingPool.setCurrentLiquidityRate(TC_AAVE_CURRENT_LIQUIDITY_RATE);

        await stanley.deposit(TC_AMOUNT_10_USD_18DEC);

        const aaveBalanceBefore = await aaveNewStartegyInstance.balanceOf();
        const userIvTokenBefore = await ivToken.balanceOf(adminAddress);

        expect(aaveBalanceBefore).to.be.equal(TC_AMOUNT_10_USD_18DEC);
        expect(userIvTokenBefore).to.be.equal(TC_AMOUNT_10_USD_18DEC);

        //when

        await stanley.withdraw(TC_AMOUNT_10_USD_18DEC);
        //then
        const aaveBalanceAfter = await aaveNewStartegyInstance.balanceOf();
        const userIvTokenAfter = await ivToken.balanceOf(adminAddress);
        const balanceOfIporeVault = await DAI.balanceOf(stanley.address);

        expect(aaveBalanceAfter).to.be.equal(BigNumber.from("0"));
        expect(userIvTokenAfter).to.be.equal(BigNumber.from("0"));
        expect(balanceOfIporeVault).to.be.equal(BigNumber.from("0"));
    });

    it("Should withdraw from AAVE when only AAVE has funds and AAVE hasn't max APR", async () => {
        //given
        const adminAddress = await await admin.getAddress();
        await lendingPool.setCurrentLiquidityRate(TC_AAVE_CURRENT_LIQUIDITY_RATE);
        await DAI.approve(await admin.getAddress(), one.mul(10000));
        await DAI.approve(stanley.address, one.mul(10000));
        await stanley.deposit(TC_AMOUNT_10_USD_18DEC);
        const aaveBalanceBefore = await aaveNewStartegyInstance.balanceOf();
        const userIvTokenBefore = await ivToken.balanceOf(adminAddress);
        expect(aaveBalanceBefore).to.be.equal(TC_AMOUNT_10_USD_18DEC);
        expect(userIvTokenBefore).to.be.equal(TC_AMOUNT_10_USD_18DEC);
        await lendingPool.setCurrentLiquidityRate(oneRay.div("1000"));
        //when

        await stanley.withdraw(TC_AMOUNT_10_USD_18DEC);
        //then
        const aaveBalanceAfter = await aaveNewStartegyInstance.balanceOf();
        const userIvTokenAfter = await ivToken.balanceOf(adminAddress);
        const balanceOfIporeVault = await DAI.balanceOf(stanley.address);

        expect(aaveBalanceAfter).to.be.equal(BigNumber.from("0"));
        expect(userIvTokenAfter).to.be.equal(BigNumber.from("0"));
        expect(balanceOfIporeVault).to.be.equal(BigNumber.from("0"));
    });

    it("Should withdraw part of funds from AAVE when only AAVE has funds and AAVE has max APR", async () => {
        //given
        const adminAddress = await await admin.getAddress();
        await lendingPool.setCurrentLiquidityRate(TC_AAVE_CURRENT_LIQUIDITY_RATE);
        await DAI.approve(await admin.getAddress(), one.mul(10000));
        await DAI.approve(stanley.address, one.mul(10000));
        await stanley.deposit(TC_AMOUNT_10_USD_18DEC);
        const aaveBalanceBefore = await aaveNewStartegyInstance.balanceOf();
        const userIvTokenBefore = await ivToken.balanceOf(adminAddress);
        expect(aaveBalanceBefore).to.be.equal(TC_AMOUNT_10_USD_18DEC);
        expect(userIvTokenBefore).to.be.equal(TC_AMOUNT_10_USD_18DEC);
        //when

        await stanley.withdraw(one.mul(6));
        //then
        const aaveBalanceAfter = await aaveNewStartegyInstance.balanceOf();
        const userIvTokenAfter = await ivToken.balanceOf(adminAddress);
        const balanceOfIporeVault = await DAI.balanceOf(stanley.address);
        expect(aaveBalanceAfter).to.be.equal(one.mul(4));
        expect(userIvTokenAfter).to.be.equal(one.mul(4));
        expect(balanceOfIporeVault).to.be.equal(BigNumber.from("0"));
    });

    it("Should withdraw from AAVE when only AAVE has funds and AAVE hasn't max APR", async () => {
        //given
        const adminAddress = await await admin.getAddress();
        await lendingPool.setCurrentLiquidityRate(TC_AAVE_CURRENT_LIQUIDITY_RATE);
        await DAI.approve(await admin.getAddress(), one.mul(10000));
        await DAI.approve(stanley.address, one.mul(10000));
        await stanley.deposit(TC_AMOUNT_10_USD_18DEC);
        const aaveBalanceBefore = await aaveNewStartegyInstance.balanceOf();
        const userIvTokenBefore = await ivToken.balanceOf(adminAddress);
        expect(aaveBalanceBefore).to.be.equal(TC_AMOUNT_10_USD_18DEC);
        expect(userIvTokenBefore).to.be.equal(TC_AMOUNT_10_USD_18DEC);
        await lendingPool.setCurrentLiquidityRate(oneRay.div("1000"));
        //when

        await stanley.withdraw(one.mul(7));
        //then
        const aaveBalanceAfter = await aaveNewStartegyInstance.balanceOf();
        const userIvTokenAfter = await ivToken.balanceOf(adminAddress);
        const balanceOfIporeVault = await DAI.balanceOf(stanley.address);

        expect(aaveBalanceAfter).to.be.equal(one.mul(3));
        expect(userIvTokenAfter).to.be.equal(one.mul(3));
        expect(balanceOfIporeVault).to.be.equal(BigNumber.from("0"));
    });

    it("Should withdraw from COMPOUND when only COMPOUND has funds and COMPOUND has max APR", async () => {
        //given
        const adminAddress = await await admin.getAddress();
        await DAI.approve(await admin.getAddress(), one.mul(10000));
        await DAI.approve(stanley.address, one.mul(10000));
        await stanley.deposit(TC_AMOUNT_10_USD_18DEC);
        const compoundBalanceBefore = await compoundStartegyInstance.balanceOf();
        const userIvTokenBefore = await ivToken.balanceOf(adminAddress);
        expect(compoundBalanceBefore).to.be.equal(TC_AMOUNT_10_USD_18DEC);
        expect(userIvTokenBefore).to.be.equal(TC_AMOUNT_10_USD_18DEC);

        //when
        await stanley.withdraw(TC_AMOUNT_10_USD_18DEC);
        //then
        const compoundBalanceAfter = await compoundStartegyInstance.balanceOf();
        const userIvTokenAfter = await ivToken.balanceOf(adminAddress);
        const balanceOfIporeVault = await DAI.balanceOf(stanley.address);

        expect(compoundBalanceAfter).to.be.equal(BigNumber.from("0"));
        expect(userIvTokenAfter).to.be.equal(BigNumber.from("0"));
        expect(balanceOfIporeVault).to.be.equal(BigNumber.from("0"));
    });

    it("Should withdraw from COMPOUND when only COMPOUND has funds and COMPOUND hasn't max APR", async () => {
        //given
        const adminAddress = await await admin.getAddress();
        await DAI.approve(await admin.getAddress(), one.mul(10000));
        await DAI.approve(stanley.address, one.mul(10000));
        await stanley.deposit(TC_AMOUNT_10_USD_18DEC);
        const compoundBalanceBefore = await compoundStartegyInstance.balanceOf();
        const userIvTokenBefore = await ivToken.balanceOf(adminAddress);
        expect(compoundBalanceBefore).to.be.equal(TC_AMOUNT_10_USD_18DEC);
        expect(userIvTokenBefore).to.be.equal(TC_AMOUNT_10_USD_18DEC);
        await lendingPool.setCurrentLiquidityRate(TC_AAVE_CURRENT_LIQUIDITY_RATE);
        //when

        await stanley.withdraw(TC_AMOUNT_10_USD_18DEC);
        //then
        const compoundBalanceAfter = await compoundStartegyInstance.balanceOf();
        const userIvTokenAfter = await ivToken.balanceOf(adminAddress);
        const balanceOfIporeVault = await DAI.balanceOf(stanley.address);

        expect(compoundBalanceAfter).to.be.equal(BigNumber.from("0"));
        expect(userIvTokenAfter).to.be.equal(BigNumber.from("0"));
        expect(balanceOfIporeVault).to.be.equal(BigNumber.from("0"));
    });

    it("Should withdraw part of funds from COMPOUND when only COMPOUND has funds and COMPOUND has max APR", async () => {
        //given
        const adminAddress = await await admin.getAddress();
        await DAI.approve(await admin.getAddress(), one.mul(10000));
        await DAI.approve(stanley.address, one.mul(10000));
        await stanley.deposit(TC_AMOUNT_10_USD_18DEC);
        const compoundBalanceBefore = await compoundStartegyInstance.balanceOf();
        const userIvTokenBefore = await ivToken.balanceOf(adminAddress);
        expect(compoundBalanceBefore).to.be.equal(TC_AMOUNT_10_USD_18DEC);
        expect(userIvTokenBefore).to.be.equal(TC_AMOUNT_10_USD_18DEC);
        //when

        await stanley.withdraw(one.mul(6));
        //then
        const compoundBalanceAfter = await compoundStartegyInstance.balanceOf();
        const userIvTokenAfter = await ivToken.balanceOf(adminAddress);
        const balanceOfIporeVault = await DAI.balanceOf(stanley.address);
        expect(compoundBalanceAfter).to.be.equal(one.mul(4));
        expect(userIvTokenAfter).to.be.equal(one.mul(4));
        expect(balanceOfIporeVault).to.be.equal(BigNumber.from("0"));
    });

    it("Should withdraw from COMPOUND when only COMPOUND has funds and COMPOUND hasn't max APR2", async () => {
        //given
        const adminAddress = await await admin.getAddress();
        await DAI.approve(await admin.getAddress(), one.mul(10000));
        await DAI.approve(stanley.address, one.mul(10000));
        await stanley.deposit(TC_AMOUNT_10_USD_18DEC);
        const compoundBalanceBefore = await compoundStartegyInstance.balanceOf();
        const userIvTokenBefore = await ivToken.balanceOf(adminAddress);
        expect(compoundBalanceBefore).to.be.equal(TC_AMOUNT_10_USD_18DEC);
        expect(userIvTokenBefore).to.be.equal(TC_AMOUNT_10_USD_18DEC);
        await lendingPool.setCurrentLiquidityRate(TC_AAVE_CURRENT_LIQUIDITY_RATE);
        //when

        await stanley.withdraw(one.mul(7));
        //then
        const compoundBalanceAfter = await compoundStartegyInstance.balanceOf();
        const userIvTokenAfter = await ivToken.balanceOf(adminAddress);
        const balanceOfIporeVault = await DAI.balanceOf(stanley.address);

        expect(compoundBalanceAfter).to.be.equal(one.mul(3));
        expect(userIvTokenAfter).to.be.equal(one.mul(3));
        expect(balanceOfIporeVault).to.be.equal(BigNumber.from("0"));
    });

    it("Should withdraw from AAVE when deposit to both but COMPOUND has max APR", async () => {
        const adminAddress = await await admin.getAddress();
        await lendingPool.setCurrentLiquidityRate(TC_AAVE_CURRENT_LIQUIDITY_RATE);
        await DAI.approve(await admin.getAddress(), one.mul(10000));
        await DAI.approve(stanley.address, one.mul(10000));
        await stanley.deposit(TC_AMOUNT_10_USD_18DEC);
        const aaveBalanceBefore = await aaveNewStartegyInstance.balanceOf();
        expect(aaveBalanceBefore).to.be.equal(TC_AMOUNT_10_USD_18DEC);

        await lendingPool.setCurrentLiquidityRate(oneRay.div("100"));

        await stanley.deposit(one.mul(20));
        const compoundBalanceBefore = await compoundStartegyInstance.balanceOf();
        const userIvTokenBefore = await ivToken.balanceOf(adminAddress);
        expect(compoundBalanceBefore).to.be.equal(one.mul(20));
        expect(userIvTokenBefore).to.be.equal(one.mul(30));
        //when

        await stanley.withdraw(TC_AMOUNT_10_USD_18DEC);
        //then
        const aaveBalanceAfter = await aaveNewStartegyInstance.balanceOf();
        const userIvTokenAfter = await ivToken.balanceOf(adminAddress);
        const balanceOfIporeVault = await DAI.balanceOf(stanley.address);

        expect(aaveBalanceAfter).to.be.equal(BigNumber.from("0"));
        expect(userIvTokenAfter).to.be.equal(one.mul(20));
        expect(balanceOfIporeVault).to.be.equal(BigNumber.from("0"));
    });
    it("Should withdraw from COMPOUND when deposit to both but COMPOUND has max APR but in AAVE has less balanse", async () => {
        const adminAddress = await await admin.getAddress();
        await lendingPool.setCurrentLiquidityRate(TC_AAVE_CURRENT_LIQUIDITY_RATE);
        await DAI.approve(await admin.getAddress(), one.mul(10000));
        await DAI.approve(stanley.address, one.mul(10000));
        await stanley.deposit(TC_AMOUNT_10_USD_18DEC);
        const aaveBalanceBefore = await aaveNewStartegyInstance.balanceOf();
        expect(aaveBalanceBefore).to.be.equal(TC_AMOUNT_10_USD_18DEC);

        // decrise aave APR
        await lendingPool.setCurrentLiquidityRate(oneRay.div("100"));

        await stanley.deposit(one.mul(20));
        const compoundBalanceBefore = await compoundStartegyInstance.balanceOf();
        const userIvTokenBefore = await ivToken.balanceOf(adminAddress);
        expect(compoundBalanceBefore).to.be.equal(one.mul(20));
        expect(userIvTokenBefore).to.be.equal(one.mul(30));
        //when

        await stanley.withdraw(one.mul(15));
        //then
        const compoundBalanceAfter = await compoundStartegyInstance.balanceOf();
        const userIvTokenAfter = await ivToken.balanceOf(adminAddress);
        const balanceOfIporeVault = await DAI.balanceOf(stanley.address);

        expect(compoundBalanceAfter).to.be.equal(one.mul(5));
        expect(userIvTokenAfter).to.be.equal(one.mul(15));
        expect(balanceOfIporeVault).to.be.equal(BigNumber.from("0"));
    });

    it("Should withdrow from COMPOUND when deposit to both but AAVE has max APR", async () => {
        await DAI.approve(await admin.getAddress(), one.mul(10000));
        await DAI.approve(stanley.address, one.mul(10000));

        const adminAddress = await await admin.getAddress();
        await stanley.deposit(one.mul(20));
        const compoundBalanceBefore = await compoundStartegyInstance.balanceOf();
        expect(compoundBalanceBefore).to.be.equal(one.mul(20));

        await lendingPool.setCurrentLiquidityRate(TC_AAVE_CURRENT_LIQUIDITY_RATE);
        await stanley.deposit(TC_AMOUNT_10_USD_18DEC);
        const aaveBalanceBefore = await aaveNewStartegyInstance.balanceOf();
        const userIvTokenBefore = await ivToken.balanceOf(adminAddress);
        expect(aaveBalanceBefore).to.be.equal(TC_AMOUNT_10_USD_18DEC);
        expect(userIvTokenBefore).to.be.equal(one.mul(30));

        //when

        await stanley.withdraw(TC_AMOUNT_10_USD_18DEC);
        //then
        const compoundBalanceAfter = await compoundStartegyInstance.balanceOf();
        const userIvTokenAfter = await ivToken.balanceOf(adminAddress);
        const balanceOfIporeVault = await DAI.balanceOf(stanley.address);

        expect(compoundBalanceAfter).to.be.equal(TC_AMOUNT_10_USD_18DEC);
        expect(userIvTokenAfter).to.be.equal(one.mul(20));
        expect(balanceOfIporeVault).to.be.equal(BigNumber.from("0"));
    });
    it("Should withdrow from AAVE when deposit to both but AAVE has max APR but in COMPOUND has less balanse", async () => {
        const adminAddress = await await admin.getAddress();
        await lendingPool.setCurrentLiquidityRate(TC_AAVE_CURRENT_LIQUIDITY_RATE);
        await DAI.approve(await admin.getAddress(), one.mul(10000));
        await DAI.approve(stanley.address, one.mul(10000));
        await stanley.deposit(one.mul(40));
        const aaveBalanceBefore = await aaveNewStartegyInstance.balanceOf();
        expect(aaveBalanceBefore).to.be.equal(one.mul(40));

        await lendingPool.setCurrentLiquidityRate(oneRay.div("100"));

        await stanley.deposit(one.mul(20));
        const compoundBalanceBefore = await compoundStartegyInstance.balanceOf();
        const userIvTokenBefore = await ivToken.balanceOf(adminAddress);
        expect(compoundBalanceBefore).to.be.equal(one.mul(20));
        expect(userIvTokenBefore).to.be.equal(one.mul(60));

        await lendingPool.setCurrentLiquidityRate(TC_AAVE_CURRENT_LIQUIDITY_RATE);
        //when

        await stanley.withdraw(one.mul(25));
        //then
        const aaveBalanceAfter = await aaveNewStartegyInstance.balanceOf();
        const userIvTokenAfter = await ivToken.balanceOf(adminAddress);
        const balanceOfIporeVault = await DAI.balanceOf(stanley.address);

        expect(aaveBalanceAfter).to.be.equal(one.mul(15));
        expect(userIvTokenAfter).to.be.equal(one.mul(35));
        expect(balanceOfIporeVault).to.be.equal(BigNumber.from("0"));
    });

    it("Should not withdraw when has less tokens", async () => {
        //given
        const adminAddress = await await admin.getAddress();
        await lendingPool.setCurrentLiquidityRate(TC_AAVE_CURRENT_LIQUIDITY_RATE);
        await DAI.approve(await admin.getAddress(), one.mul(10000));
        await DAI.approve(stanley.address, one.mul(10000));
        await stanley.deposit(TC_AMOUNT_10_USD_18DEC);
        const aaveBalanceBefore = await aaveNewStartegyInstance.balanceOf();
        const userIvTokenBefore = await ivToken.balanceOf(adminAddress);
        expect(aaveBalanceBefore).to.be.equal(TC_AMOUNT_10_USD_18DEC);
        expect(userIvTokenBefore).to.be.equal(TC_AMOUNT_10_USD_18DEC);
        //when
        await stanley.withdraw(one.mul(20));

        //then
        const userIvTokenAfter = await ivToken.balanceOf(adminAddress);
        expect(userIvTokenAfter).to.be.equal(zero);
    });

    it("Should withdraw all from  AAVE and COMPOUND", async () => {
        const adminAddress = await await admin.getAddress();
        await lendingPool.setCurrentLiquidityRate(TC_AAVE_CURRENT_LIQUIDITY_RATE);
        await DAI.approve(await admin.getAddress(), one.mul(10000));
        await DAI.approve(stanley.address, one.mul(10000));
        await stanley.deposit(TC_AMOUNT_10_USD_18DEC);
        const aaveBalanceBefore = await aaveNewStartegyInstance.balanceOf();
        expect(aaveBalanceBefore).to.be.equal(TC_AMOUNT_10_USD_18DEC);

        await lendingPool.setCurrentLiquidityRate(oneRay.div("100"));

        await stanley.deposit(one.mul(20));
        const compoundBalanceBefore = await compoundStartegyInstance.balanceOf();
        const userIvTokenBefore = await ivToken.balanceOf(adminAddress);
        expect(compoundBalanceBefore).to.be.equal(one.mul(20));
        expect(userIvTokenBefore).to.be.equal(one.mul(30));
        //when

        await stanley.withdrawAll();
        //then
        const aaveBalanceAfter = await aaveNewStartegyInstance.balanceOf();
        const compoundBalanceAfter = await compoundStartegyInstance.balanceOf();
        const userIvTokenAfter = await ivToken.balanceOf(adminAddress);
        const balanceOfIporeVault = await DAI.balanceOf(stanley.address);

        expect(compoundBalanceAfter).to.be.equal(ZERO);
        expect(aaveBalanceAfter).to.be.equal(ZERO);
        expect(userIvTokenAfter).to.be.equal(ZERO);
        expect(balanceOfIporeVault).to.be.equal(ZERO);
    });

    it("Should withdraw from Compound when deposit to both but AAVE has max APR", async () => {
        const adminAddress = await await admin.getAddress();
        await lendingPool.setCurrentLiquidityRate(TC_AAVE_CURRENT_LIQUIDITY_RATE);
        await DAI.approve(await admin.getAddress(), one.mul(10000));
        await DAI.approve(stanley.address, one.mul(10000));
        await stanley.deposit(one.mul(40));
        const aaveBalanceBefore = await aaveNewStartegyInstance.balanceOf();
        expect(aaveBalanceBefore).to.be.equal(one.mul(40));

        await lendingPool.setCurrentLiquidityRate(oneRay.div("100"));

        await stanley.deposit(one.mul(20));
        const compoundBalanceBefore = await compoundStartegyInstance.balanceOf();
        const userIvTokenBefore = await ivToken.balanceOf(adminAddress);
        expect(compoundBalanceBefore).to.be.equal(one.mul(20));
        expect(userIvTokenBefore).to.be.equal(one.mul(60));

        await lendingPool.setCurrentLiquidityRate(TC_AAVE_CURRENT_LIQUIDITY_RATE);
        //when

        await stanley.withdraw(one.mul(10));
        //then
        const compoundBalanceAfter = await compoundStartegyInstance.balanceOf();
        const aaveBalanceAfter = await aaveNewStartegyInstance.balanceOf();
        const userIvTokenAfter = await ivToken.balanceOf(adminAddress);
        const balanceOfIporeVault = await DAI.balanceOf(stanley.address);

        expect(compoundBalanceAfter).to.be.equal(one.mul(10));
        expect(aaveBalanceAfter).to.be.equal(one.mul(40));
        expect(userIvTokenAfter).to.be.equal(one.mul(50));
        expect(balanceOfIporeVault).to.be.equal(ZERO);
    });

    it("Should withdraw from Aave when not all ampund in one strategy when deposit to both but AAVE has max APR", async () => {
        const adminAddress = await await admin.getAddress();
        await lendingPool.setCurrentLiquidityRate(TC_AAVE_CURRENT_LIQUIDITY_RATE);
        await DAI.approve(await admin.getAddress(), one.mul(10000));
        await DAI.approve(stanley.address, one.mul(10000));
        await stanley.deposit(one.mul(40));
        const aaveBalanceBefore = await aaveNewStartegyInstance.balanceOf();
        expect(aaveBalanceBefore).to.be.equal(one.mul(40));

        await lendingPool.setCurrentLiquidityRate(oneRay.div("100"));

        await stanley.deposit(one.mul(40));
        const compoundBalanceBefore = await compoundStartegyInstance.balanceOf();
        const userIvTokenBefore = await ivToken.balanceOf(adminAddress);
        expect(compoundBalanceBefore).to.be.equal(one.mul(40));
        expect(userIvTokenBefore).to.be.equal(one.mul(80));

        await lendingPool.setCurrentLiquidityRate(TC_AAVE_CURRENT_LIQUIDITY_RATE);
        //when

        await stanley.withdraw(one.mul(50));
        //then
        const compoundBalanceAfter = await compoundStartegyInstance.balanceOf();
        const aaveBalanceAfter = await aaveNewStartegyInstance.balanceOf();
        const userIvTokenAfter = await ivToken.balanceOf(adminAddress);
        const balanceOfIporeVault = await DAI.balanceOf(stanley.address);

        expect(compoundBalanceAfter).to.be.equal(one.mul(40));
        expect(aaveBalanceAfter).to.be.equal(ZERO);
        expect(userIvTokenAfter).to.be.equal(one.mul(40));
        expect(balanceOfIporeVault).to.be.equal(ZERO);
    });

    it("Should withdraw from Compound when not all ampund in one strategy when deposit to both but AAVE has max APR", async () => {
        const adminAddress = await await admin.getAddress();
        await lendingPool.setCurrentLiquidityRate(TC_AAVE_CURRENT_LIQUIDITY_RATE);
        await DAI.approve(await admin.getAddress(), one.mul(10000));
        await DAI.approve(stanley.address, one.mul(10000));
        await stanley.deposit(one.mul(30));
        const aaveBalanceBefore = await aaveNewStartegyInstance.balanceOf();
        expect(aaveBalanceBefore).to.be.equal(one.mul(30));

        await lendingPool.setCurrentLiquidityRate(oneRay.div("100"));

        await stanley.deposit(one.mul(40));
        const compoundBalanceBefore = await compoundStartegyInstance.balanceOf();
        const userIvTokenBefore = await ivToken.balanceOf(adminAddress);
        expect(compoundBalanceBefore).to.be.equal(one.mul(40));
        expect(userIvTokenBefore).to.be.equal(one.mul(70));

        await lendingPool.setCurrentLiquidityRate(TC_AAVE_CURRENT_LIQUIDITY_RATE);
        //when

        await stanley.withdraw(one.mul(50));
        //then
        const compoundBalanceAfter = await compoundStartegyInstance.balanceOf();
        const aaveBalanceAfter = await aaveNewStartegyInstance.balanceOf();
        const userIvTokenAfter = await ivToken.balanceOf(adminAddress);
        const balanceOfIporeVault = await DAI.balanceOf(stanley.address);

        expect(compoundBalanceAfter).to.be.equal(ZERO);
        expect(aaveBalanceAfter).to.be.equal(one.mul(30));
        expect(userIvTokenAfter).to.be.equal(one.mul(30));
        expect(balanceOfIporeVault).to.be.equal(ZERO);
    });
});

import hre, { upgrades } from "hardhat";
import chai from "chai";
const keccak256 = require("keccak256");
import { constants, BigNumber, Signer } from "ethers";

const { MaxUint256 } = constants;
import { solidity } from "ethereum-waffle";
import {
    StrategyAave,
    ERC20,
    DaiMockedToken,
    UsdcMockedToken,
    UsdtMockedToken,
    MockStakedAave,
    MockAaveIncentivesController,
} from "../../../../types";

chai.use(solidity);
const { expect } = chai;

const stableTotalSupply18Decimals = "1000000000000000000000000000000";
const totalSupply6Decimals = "100000000000000000000";

const ZERO = BigNumber.from("0");
const TC_1000_USD_6DEC = BigNumber.from("1000000000");
const TC_1000_USD_18DEC = BigNumber.from("1000000000000000000000");
const TC_9_000_USD_18DEC = BigNumber.from("9000000000000000000000");
const TC_10_000_USD_18DEC = BigNumber.from("10000000000000000000000");
const TC_9_000_USD_6DEC = BigNumber.from("9000000000");
const TC_10_000_USD_6DEC = BigNumber.from("10000000000");

describe("AAVE strategy", () => {
    let strategyAaveInstanceDAI: StrategyAave;
    let strategyAaveInstanceUSDC: StrategyAave;
    let strategyAaveInstanceUSDT: StrategyAave;
    let DAI: DaiMockedToken;
    let USDC: UsdcMockedToken;
    let USDT: UsdtMockedToken;
    let aDAI: ERC20;
    let aUSDC: ERC20;
    let aUSDT: ERC20;
    let stkAAVE: ERC20;
    let AAVE: ERC20;
    let stakedAave: MockStakedAave;
    let admin: Signer, userOne: Signer, userTwo: Signer;

    beforeEach(async () => {
        [admin, userOne, userTwo] = await hre.ethers.getSigners();

        // #################################################################################
        // #####################        USDC / aUSDC     ###################################
        // #################################################################################

        const UsdcMockedToken = await hre.ethers.getContractFactory("UsdcMockedToken");
        USDC = (await UsdcMockedToken.deploy(totalSupply6Decimals, 6)) as UsdcMockedToken;
        const AUSDCFactory = await hre.ethers.getContractFactory("MockAUsdc");
        aUSDC = (await AUSDCFactory.deploy()) as ERC20;

        // #################################################################################
        // #####################        USDT / aUSDT     ###################################
        // #################################################################################

        const UsdtMockedToken = await hre.ethers.getContractFactory("UsdtMockedToken");
        USDT = (await UsdtMockedToken.deploy(totalSupply6Decimals, 6)) as UsdtMockedToken;
        const AUSDTFactory = await hre.ethers.getContractFactory("MockAUsdt");
        aUSDT = (await AUSDTFactory.deploy()) as ERC20;

        // #################################################################################
        // #####################         DAI / aDAI      ###################################
        // #################################################################################

        const DAIFactory = await hre.ethers.getContractFactory("DaiMockedToken");
        DAI = (await DAIFactory.deploy(stableTotalSupply18Decimals, 18)) as DaiMockedToken;

        const ADAIFactory = await hre.ethers.getContractFactory("MockADai");
        aDAI = (await ADAIFactory.deploy()) as ERC20;

        stkAAVE = (await DAIFactory.deploy(stableTotalSupply18Decimals, 18)) as ERC20;
        await stkAAVE.deployed();

        AAVE = (await DAIFactory.deploy(stableTotalSupply18Decimals, 18)) as ERC20;
        await AAVE.deployed();

        // #################################################################################
        // #####################         AAVE MOCK       ###################################
        // #################################################################################

        const MockLendingPoolAave = await hre.ethers.getContractFactory("MockLendingPoolAave");
        const lendingPool = await MockLendingPoolAave.deploy(
            DAI.address,
            aDAI.address,
            BigNumber.from("100000"),
            USDC.address,
            aUSDC.address,
            BigNumber.from("200000"),
            USDT.address,
            aUSDT.address,
            BigNumber.from("200000")
        );

        const MockProviderAave = await hre.ethers.getContractFactory("MockProviderAave");
        const addressProvider = await MockProviderAave.deploy(lendingPool.address);

        const MockStakedAave = await hre.ethers.getContractFactory("MockStakedAave");
        stakedAave = (await MockStakedAave.deploy(AAVE.address)) as MockStakedAave;
        const MockAaveIncentivesController = await hre.ethers.getContractFactory(
            "MockAaveIncentivesController"
        );

        const aaveIncentivesController = (await MockAaveIncentivesController.deploy(
            stakedAave.address
        )) as MockAaveIncentivesController;

        // #################################################################################
        // #####################         AAVE Strategy   ###################################
        // #################################################################################

        const StrategyAaveInstance = await hre.ethers.getContractFactory("StrategyAave");
        strategyAaveInstanceDAI = (await upgrades.deployProxy(StrategyAaveInstance, [
            DAI.address,
            aDAI.address,
            addressProvider.address,
            stakedAave.address,
            aaveIncentivesController.address,
            AAVE.address,
        ])) as StrategyAave;

        strategyAaveInstanceUSDC = (await upgrades.deployProxy(StrategyAaveInstance, [
            USDC.address,
            aUSDC.address,
            addressProvider.address,
            stakedAave.address,
            aaveIncentivesController.address,
            AAVE.address,
        ])) as StrategyAave;

        strategyAaveInstanceUSDT = (await upgrades.deployProxy(StrategyAaveInstance, [
            USDT.address,
            aUSDT.address,
            addressProvider.address,
            stakedAave.address,
            aaveIncentivesController.address,
            AAVE.address,
        ])) as StrategyAave;
    });

    it("Should be able to setup Stanley and interact with DAI", async () => {
        //given
        const newStanleyAddress = await userTwo.getAddress(); // random address
        const oldStanleyAddress = await strategyAaveInstanceUSDC.getStanley();
        await expect(strategyAaveInstanceDAI.setStanley(newStanleyAddress))
            .to.emit(strategyAaveInstanceDAI, "StanleyChanged")
            .withArgs(await admin.getAddress, oldStanleyAddress, newStanleyAddress);

        await DAI.setupInitialAmount(newStanleyAddress, TC_10_000_USD_18DEC);

        DAI.connect(userTwo).increaseAllowance(
            strategyAaveInstanceDAI.address,
            TC_10_000_USD_18DEC
        );

        await strategyAaveInstanceDAI.connect(userTwo).deposit(TC_1000_USD_18DEC);

        expect(await DAI.balanceOf(newStanleyAddress)).to.be.equal(TC_9_000_USD_18DEC);
        expect(await aDAI.balanceOf(strategyAaveInstanceDAI.address)).to.be.equal(
            TC_1000_USD_18DEC
        );

        await strategyAaveInstanceDAI.connect(userTwo).withdraw(TC_1000_USD_18DEC);

        expect(await DAI.balanceOf(newStanleyAddress)).to.be.equal(TC_10_000_USD_18DEC);
        expect(await aDAI.balanceOf(strategyAaveInstanceDAI.address)).to.be.equal(ZERO);
    });

    it("Should be able to setup Stanley and interact with USDC", async () => {
        //given
        const newStanleyAddress = await userTwo.getAddress(); // random address
        const oldStanleyAddress = await strategyAaveInstanceUSDC.getStanley();

        await expect(strategyAaveInstanceUSDC.setStanley(newStanleyAddress))
            .to.emit(strategyAaveInstanceUSDC, "StanleyChanged")
            .withArgs(await admin.getAddress, oldStanleyAddress, newStanleyAddress);

        await USDC.setupInitialAmount(newStanleyAddress, TC_10_000_USD_6DEC);

        USDC.connect(userTwo).increaseAllowance(
            strategyAaveInstanceUSDC.address,
            TC_10_000_USD_6DEC
        );

        await strategyAaveInstanceUSDC.connect(userTwo).deposit(TC_1000_USD_18DEC);

        expect((await USDC.balanceOf(newStanleyAddress)).toString()).to.be.equal(TC_9_000_USD_6DEC);
        expect(await aUSDC.balanceOf(strategyAaveInstanceUSDC.address)).to.be.equal(
            TC_1000_USD_6DEC
        );

        await strategyAaveInstanceUSDC.connect(userTwo).withdraw(TC_1000_USD_18DEC);

        expect(await USDC.balanceOf(newStanleyAddress)).to.be.equal(TC_10_000_USD_6DEC);
        expect(await aUSDC.balanceOf(strategyAaveInstanceUSDT.address)).to.be.equal(ZERO);
    });

    it("Should be able to setup Stanley and interacti with USDT", async () => {
        //given
        const newStanleyAddress = await userTwo.getAddress(); // random address
        const oldStanleyAddress = await strategyAaveInstanceUSDT.getStanley();
        await expect(strategyAaveInstanceUSDT.setStanley(newStanleyAddress))
            .to.emit(strategyAaveInstanceUSDT, "StanleyChanged")
            .withArgs(await admin.getAddress, oldStanleyAddress, newStanleyAddress);

        await USDT.setupInitialAmount(newStanleyAddress, TC_10_000_USD_6DEC);

        USDT.connect(userTwo).increaseAllowance(
            strategyAaveInstanceUSDT.address,
            TC_10_000_USD_6DEC
        );

        await strategyAaveInstanceUSDT.connect(userTwo).deposit(TC_1000_USD_18DEC);

        expect(await USDT.balanceOf(newStanleyAddress)).to.be.equal(TC_9_000_USD_6DEC);
        expect(await aUSDT.balanceOf(strategyAaveInstanceUSDT.address)).to.be.equal(
            TC_1000_USD_6DEC
        );

        await strategyAaveInstanceUSDT.connect(userTwo).withdraw(TC_1000_USD_18DEC);

        expect(await USDT.balanceOf(newStanleyAddress)).to.be.equal(TC_10_000_USD_6DEC);
        expect(await aUSDT.balanceOf(strategyAaveInstanceUSDT.address)).to.be.equal(ZERO);
    });
});

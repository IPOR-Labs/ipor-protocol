const hre = require("hardhat");
import chai from "chai";
const keccak256 = require("keccak256");
import { constants, BigNumber, Signer } from "ethers";

const { MaxUint256 } = constants;
import { solidity } from "ethereum-waffle";
import {
    AaveStrategy,
    ERC20,
    DaiMockedToken,
    MockStakedAave,
    MockAaveIncentivesController,
} from "../../../../types";

chai.use(solidity);
const { expect } = chai;

const stableTotalSupply18Decimals = "1000000000000000000000000000000";
const totalSupply6Decimals = "100000000000000000000";

describe("AAVE strategy", () => {
    let aaveStrategyInstanceDAI: AaveStrategy;
    let aaveStrategyInstanceUSDC: AaveStrategy;
    let aaveStrategyInstanceUSDT: AaveStrategy;
    let DAI: DaiMockedToken;
    let USDC: DaiMockedToken;
    let USDT: DaiMockedToken;
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
        USDC = await UsdcMockedToken.deploy(totalSupply6Decimals, 6);
        const AUSDCFactory = await hre.ethers.getContractFactory("MockAUsdc");
        aUSDC = await AUSDCFactory.deploy();

        // #################################################################################
        // #####################        USDT / aUSDT     ###################################
        // #################################################################################

        const UsdtMockedToken = await hre.ethers.getContractFactory("UsdtMockedToken");
        USDT = await UsdtMockedToken.deploy(totalSupply6Decimals, 6);
        const AUSDTFactory = await hre.ethers.getContractFactory("MockAUsdt");
        aUSDT = await AUSDTFactory.deploy();

        // #################################################################################
        // #####################         DAI / aDAI      ###################################
        // #################################################################################

        const DAIFactory = await hre.ethers.getContractFactory("DaiMockedToken");
        DAI = (await DAIFactory.deploy(stableTotalSupply18Decimals, 18)) as DaiMockedToken;

        const ADAIFactory = await hre.ethers.getContractFactory("MockADai");
        aDAI = await ADAIFactory.deploy();

        stkAAVE = await DAIFactory.deploy(stableTotalSupply18Decimals, 18);
        await stkAAVE.deployed();

        AAVE = await DAIFactory.deploy(stableTotalSupply18Decimals, 18);
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

        const AaveStrategyInstance = await hre.ethers.getContractFactory("AaveStrategy");
        aaveStrategyInstanceDAI = await upgrades.deployProxy(AaveStrategyInstance, [
            DAI.address,
            aDAI.address,
            addressProvider.address,
            stakedAave.address,
            aaveIncentivesController.address,
            AAVE.address,
        ]);

        aaveStrategyInstanceUSDC = await upgrades.deployProxy(AaveStrategyInstance, [
            USDC.address,
            aUSDC.address,
            addressProvider.address,
            stakedAave.address,
            aaveIncentivesController.address,
            AAVE.address,
        ]);

        aaveStrategyInstanceUSDT = await upgrades.deployProxy(AaveStrategyInstance, [
            USDT.address,
            aUSDT.address,
            addressProvider.address,
            stakedAave.address,
            aaveIncentivesController.address,
            AAVE.address,
        ]);
    });

    it("Should be able to setup Stanley and interacti with DAI", async () => {
        //given
        const stanleyAddress = await userTwo.getAddress(); // random address
        await expect(aaveStrategyInstanceDAI.setStanley(stanleyAddress))
            .to.emit(aaveStrategyInstanceDAI, "SetStanley")
            .withArgs(await admin.getAddress, stanleyAddress, aaveStrategyInstanceDAI.address);

        await DAI.setupInitialAmount(stanleyAddress, BigNumber.from("100000000000000000000"));

        DAI.connect(userTwo).increaseAllowance(
            aaveStrategyInstanceDAI.address,
            BigNumber.from("100000000000000000000")
        );

        await aaveStrategyInstanceDAI
            .connect(userTwo)
            .deposit(BigNumber.from("1000000000000000000"));

        expect((await DAI.balanceOf(stanleyAddress)).toString()).to.be.equal(
            "99000000000000000000"
        );
        expect((await aDAI.balanceOf(aaveStrategyInstanceDAI.address)).toString()).to.be.equal(
            "1000000000000000000"
        );

        await aaveStrategyInstanceDAI
            .connect(userTwo)
            .withdraw(BigNumber.from("1000000000000000000"));

        expect((await DAI.balanceOf(stanleyAddress)).toString()).to.be.equal(
            "100000000000000000000"
        );
        expect((await aDAI.balanceOf(aaveStrategyInstanceDAI.address)).toString()).to.be.equal("0");
    });

    it("Should be able to setup Stanley and interacti with USDC", async () => {
        //given
        const stanleyAddress = await userTwo.getAddress(); // random address
        await expect(aaveStrategyInstanceUSDC.setStanley(stanleyAddress))
            .to.emit(aaveStrategyInstanceUSDC, "SetStanley")
            .withArgs(await admin.getAddress, stanleyAddress, aaveStrategyInstanceUSDC.address);

        await USDC.setupInitialAmount(stanleyAddress, BigNumber.from("100000000000000000000"));

        USDC.connect(userTwo).increaseAllowance(
            aaveStrategyInstanceUSDC.address,
            BigNumber.from("100000000000000000000")
        );

        await aaveStrategyInstanceUSDC
            .connect(userTwo)
            .deposit(BigNumber.from("1000000000000000000"));

        expect((await USDC.balanceOf(stanleyAddress)).toString()).to.be.equal(
            "99000000000000000000"
        );
        expect((await aUSDC.balanceOf(aaveStrategyInstanceUSDC.address)).toString()).to.be.equal(
            "1000000000000000000"
        );

        await aaveStrategyInstanceUSDC
            .connect(userTwo)
            .withdraw(BigNumber.from("1000000000000000000"));

        expect((await USDC.balanceOf(stanleyAddress)).toString()).to.be.equal(
            "100000000000000000000"
        );
        expect((await aUSDC.balanceOf(aaveStrategyInstanceUSDT.address)).toString()).to.be.equal(
            "0"
        );
    });

    it("Should be able to setup Stanley and interacti with USDT", async () => {
        //given
        const stanleyAddress = await userTwo.getAddress(); // random address
        await expect(aaveStrategyInstanceUSDT.setStanley(stanleyAddress))
            .to.emit(aaveStrategyInstanceUSDT, "SetStanley")
            .withArgs(await admin.getAddress, stanleyAddress, aaveStrategyInstanceUSDT.address);

        await USDT.setupInitialAmount(stanleyAddress, BigNumber.from("100000000000000000000"));

        USDT.connect(userTwo).increaseAllowance(
            aaveStrategyInstanceUSDT.address,
            BigNumber.from("100000000000000000000")
        );

        await aaveStrategyInstanceUSDT
            .connect(userTwo)
            .deposit(BigNumber.from("1000000000000000000"));

        expect((await USDT.balanceOf(stanleyAddress)).toString()).to.be.equal(
            "99000000000000000000"
        );
        expect((await aUSDT.balanceOf(aaveStrategyInstanceUSDT.address)).toString()).to.be.equal(
            "1000000000000000000"
        );

        await aaveStrategyInstanceUSDT
            .connect(userTwo)
            .withdraw(BigNumber.from("1000000000000000000"));

        expect((await USDT.balanceOf(stanleyAddress)).toString()).to.be.equal(
            "100000000000000000000"
        );
        expect((await aUSDT.balanceOf(aaveStrategyInstanceUSDT.address)).toString()).to.be.equal(
            "0"
        );
    });
});

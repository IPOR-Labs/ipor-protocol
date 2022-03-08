const hre = require("hardhat");
import chai from "chai";
const keccak256 = require("keccak256");
import { constants, BigNumber, Signer } from "ethers";

const { MaxUint256 } = constants;
import { solidity } from "ethereum-waffle";
import daiAbi from "../../../../artifacts/contracts/vault/mocks/aave/MockDAI.sol/MockDAI.json";
// import daiAbi from "../../../../"
import {
    AaveStrategy,
    ERC20,
    MockWhitePaper,
    MockCDAI,
    MockComptroller,
    UsdcMockedToken,
    UsdtMockedToken,
    MockCToken,
    DaiMockedToken,
} from "../../../../types";

chai.use(solidity);
const { expect } = chai;

const stableTotalSupply18Decimals = "1000000000000000000000000000000";
const totalSupply6Decimals = "100000000000000000000";

describe("Compound strategy", () => {
    let compoundStrategyInstanceDAI: AaveStrategy;
    let compoundStrategyInstanceUSDC: AaveStrategy;
    let compoundStrategyInstanceUSDT: AaveStrategy;
    let DAI: DaiMockedToken;
    let USDC: UsdcMockedToken;
    let USDT: UsdtMockedToken;
    let cDAI: MockCToken;
    let cUSDC: MockCToken;
    let cUSDT: MockCToken;
    let COMP: ERC20;
    let admin: Signer, userOne: Signer, userTwo: Signer;
    let comptrollerDAI: MockComptroller;
    let comptrollerUSDC: MockComptroller;
    let comptrollerUSDT: MockComptroller;

    beforeEach(async () => {
        [admin, userOne, userTwo] = await hre.ethers.getSigners();
        const MockWhitePaper = await hre.ethers.getContractFactory("MockWhitePaper");
        const MockWhitePaperInstance = (await MockWhitePaper.deploy()) as MockWhitePaper;

        // #################################################################################
        // #####################        USDC / aUSDC     ###################################
        // #################################################################################

        const MockedCToken = await hre.ethers.getContractFactory("UsdcMockedToken");
        USDC = await MockedCToken.deploy(totalSupply6Decimals, 6);
        const cTokenFactory = await hre.ethers.getContractFactory("MockCToken");
        cUSDC = await cTokenFactory.deploy(
            USDC.address,
            MockWhitePaperInstance.address,
            BigNumber.from("6"),
            "cUSDC",
            "cUSDC"
        );

        // #################################################################################
        // #####################        USDT / aUSDT     ###################################
        // #################################################################################

        const UsdtMockedToken = await hre.ethers.getContractFactory("UsdtMockedToken");
        USDT = await UsdtMockedToken.deploy(totalSupply6Decimals, 6);
        cUSDT = await cTokenFactory.deploy(
            USDT.address,
            MockWhitePaperInstance.address,
            BigNumber.from("6"),
            "cUSDT",
            "cUSDT"
        );

        // #################################################################################
        // #####################         DAI / aDAI      ###################################
        // #################################################################################

        const DAIFactory = await hre.ethers.getContractFactory("DaiMockedToken");
        DAI = (await DAIFactory.deploy(stableTotalSupply18Decimals, 18)) as DaiMockedToken;
        cDAI = await cTokenFactory.deploy(
            DAI.address,
            MockWhitePaperInstance.address,
            BigNumber.from("18"),
            "cDAI",
            "cDAI"
        );

        COMP = await DAIFactory.deploy(stableTotalSupply18Decimals, 18);

        const MockComptroller = await hre.ethers.getContractFactory("MockComptroller");
        comptrollerDAI = (await MockComptroller.deploy(
            COMP.address,
            cDAI.address
        )) as MockComptroller;
        comptrollerUSDT = (await MockComptroller.deploy(
            COMP.address,
            cUSDT.address
        )) as MockComptroller;
        comptrollerUSDC = (await MockComptroller.deploy(
            COMP.address,
            cUSDC.address
        )) as MockComptroller;

        const compoundNewStartegy = await hre.ethers.getContractFactory("CompoundStrategy");
        compoundStrategyInstanceDAI = await upgrades.deployProxy(compoundNewStartegy, [
            DAI.address,
            cDAI.address,
            comptrollerDAI.address,
            COMP.address,
        ]);
        await compoundStrategyInstanceDAI.setTreasury(await admin.getAddress());
        compoundStrategyInstanceUSDT = await upgrades.deployProxy(compoundNewStartegy, [
            USDT.address,
            cUSDT.address,
            comptrollerUSDT.address,
            COMP.address,
        ]);
        await compoundStrategyInstanceUSDT.setTreasury(await admin.getAddress());
        compoundStrategyInstanceUSDC = await upgrades.deployProxy(compoundNewStartegy, [
            USDC.address,
            cUSDC.address,
            comptrollerUSDT.address,
            COMP.address,
        ]);
        await compoundStrategyInstanceUSDC.setTreasury(await admin.getAddress());
    });

    it("Should be able to setup Stanley", async () => {
        //given
        const stanleyAddress = await userTwo.getAddress(); // random address
        //when
        await expect(compoundStrategyInstanceDAI.setStanley(stanleyAddress))
            .to.emit(compoundStrategyInstanceDAI, "SetStanley")
            .withArgs(await admin.getAddress, stanleyAddress, compoundStrategyInstanceDAI.address);
    });

    it("Should not be able to setup Stanley when non owner want to setup new address", async () => {
        //given
        const stanleyAddress = await userTwo.getAddress(); // random address
        //when
        await expect(
            compoundStrategyInstanceDAI.connect(userOne).setStanley(stanleyAddress)
        ).to.be.revertedWith("Ownable: caller is not the owner");
    });

    it("Should be able to setup Stanley and interacti with DAI", async () => {
        //given
        const stanleyAddress = await userTwo.getAddress(); // random address
        await expect(compoundStrategyInstanceDAI.setStanley(stanleyAddress))
            .to.emit(compoundStrategyInstanceDAI, "SetStanley")
            .withArgs(await admin.getAddress, stanleyAddress, compoundStrategyInstanceDAI.address);

        await DAI.setupInitialAmount(stanleyAddress, BigNumber.from("100000000000000000000"));

        DAI.connect(userTwo).increaseAllowance(
            compoundStrategyInstanceDAI.address,
            BigNumber.from("100000000000000000000")
        );

        await compoundStrategyInstanceDAI
            .connect(userTwo)
            .deposit(BigNumber.from("1000000000000000000"));

        expect((await DAI.balanceOf(stanleyAddress)).toString()).to.be.equal(
            "99000000000000000000"
        );
        expect((await cDAI.balanceOf(compoundStrategyInstanceDAI.address)).toString()).to.be.equal(
            "50000000000"
        );

        await compoundStrategyInstanceDAI
            .connect(userTwo)
            .withdraw(BigNumber.from("1000000000000000000"));

        expect((await DAI.balanceOf(stanleyAddress)).toString()).to.be.equal(
            "100000000000000000000"
        );
        expect((await cDAI.balanceOf(compoundStrategyInstanceDAI.address)).toString()).to.be.equal(
            "0"
        );
    });

    it("Should be able to setup Stanley and interacti with USDT", async () => {
        //given
        const stanleyAddress = await userTwo.getAddress(); // random address
        await expect(compoundStrategyInstanceUSDT.setStanley(stanleyAddress))
            .to.emit(compoundStrategyInstanceUSDT, "SetStanley")
            .withArgs(await admin.getAddress, stanleyAddress, compoundStrategyInstanceUSDT.address);

        await USDT.setupInitialAmount(stanleyAddress, BigNumber.from("10000000000000000000000000"));

        USDT.connect(userTwo).increaseAllowance(
            compoundStrategyInstanceUSDT.address,
            BigNumber.from("100000000000000000000000")
        );

        await compoundStrategyInstanceUSDT
            .connect(userTwo)
            .deposit(BigNumber.from("1000000000000000000"));

        expect((await USDT.balanceOf(stanleyAddress)).toString()).to.be.equal(
            "9999999000000000000000000"
        );
        expect(
            (await cUSDT.balanceOf(compoundStrategyInstanceUSDT.address)).toString()
        ).to.be.equal("50000000000");

        await compoundStrategyInstanceUSDT
            .connect(userTwo)
            .withdraw(BigNumber.from("1000000000000000000"));

        expect((await USDT.balanceOf(stanleyAddress)).toString()).to.be.equal(
            "10000000000000000000000000"
        );
        expect(
            (await cUSDC.balanceOf(compoundStrategyInstanceUSDT.address)).toString()
        ).to.be.equal("0");
    });

    it("Should be able to setup Stanley and interacti with USDC", async () => {
        //given
        const stanleyAddress = await userTwo.getAddress(); // random address
        await expect(compoundStrategyInstanceUSDC.setStanley(stanleyAddress))
            .to.emit(compoundStrategyInstanceUSDC, "SetStanley")
            .withArgs(await admin.getAddress, stanleyAddress, compoundStrategyInstanceUSDC.address);

        await USDC.setupInitialAmount(stanleyAddress, BigNumber.from("10000000000000000000000000"));

        USDC.connect(userTwo).increaseAllowance(
            compoundStrategyInstanceUSDC.address,
            BigNumber.from("100000000000000000000000")
        );

        await compoundStrategyInstanceUSDC
            .connect(userTwo)
            .deposit(BigNumber.from("1000000000000000000"));

        expect((await USDC.balanceOf(stanleyAddress)).toString()).to.be.equal(
            "9999999000000000000000000"
        );
        expect(
            (await cUSDC.balanceOf(compoundStrategyInstanceUSDC.address)).toString()
        ).to.be.equal("50000000000");

        await compoundStrategyInstanceUSDC
            .connect(userTwo)
            .withdraw(BigNumber.from("1000000000000000000"));

        expect((await USDC.balanceOf(stanleyAddress)).toString()).to.be.equal(
            "10000000000000000000000000"
        );
        expect(
            (await cUSDC.balanceOf(compoundStrategyInstanceUSDC.address)).toString()
        ).to.be.equal("0");
    });
});

const hre = require("hardhat");
import chai from "chai";
import { BigNumber, Signer, constants } from "ethers";
import { solidity } from "ethereum-waffle";
import {
    StrategyAave,
    ERC20,
    MockWhitePaper,
    MockComptroller,
    UsdcMockedToken,
    UsdtMockedToken,
    MockCToken,
    DaiMockedToken,
    StrategyCompound,
} from "../../../../types";

chai.use(solidity);
const { expect } = chai;

const stableTotalSupply18Decimals = "1000000000000000000000000000000";
const totalSupply6Decimals = "100000000000000000000";

const ZERO = BigNumber.from("0");
const ONE = BigNumber.from("1");
const TC_1000_USD_18DEC = BigNumber.from("1000000000000000000000");
const TC_9_000_USD_18DEC = BigNumber.from("9000000000000000000000");
const TC_10_000_USD_18DEC = BigNumber.from("10000000000000000000000");
const TC_9_999_USD_18DEC = BigNumber.from("9999999999999999999999");

const TC_9_000_USD_6DEC = BigNumber.from("9000000000");
const TC_10_000_USD_6DEC = BigNumber.from("10000000000");

describe("Compound strategy", () => {
    let strategyCompoundInstanceDAI: StrategyCompound;
    let strategyCompoundInstanceUSDC: StrategyCompound;
    let strategyCompoundInstanceUSDT: StrategyCompound;
    let DAI: DaiMockedToken;
    let USDC: UsdcMockedToken;
    let USDT: UsdtMockedToken;
    let cDAI: MockCToken;
    let cUSDC: MockCToken;
    let cUSDT: MockCToken;
    let COMP: ERC20;
    let admin: Signer, userOne: Signer, userTwo: Signer;
    let comptroller: MockComptroller;
    // let comptrollerUSDC: MockComptroller;
    // let comptrollerUSDT: MockComptroller;

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
        comptroller = (await MockComptroller.deploy(
            COMP.address,
            cUSDT.address,
            cUSDC.address,
            cDAI.address
        )) as MockComptroller;

        const compoundNewStartegy = await hre.ethers.getContractFactory("StrategyCompound");
        strategyCompoundInstanceDAI = await upgrades.deployProxy(compoundNewStartegy, [
            DAI.address,
            cDAI.address,
            comptroller.address,
            COMP.address,
        ]);
        await strategyCompoundInstanceDAI.setTreasury(await admin.getAddress());
        strategyCompoundInstanceUSDT = await upgrades.deployProxy(compoundNewStartegy, [
            USDT.address,
            cUSDT.address,
            comptroller.address,
            COMP.address,
        ]);
        await strategyCompoundInstanceUSDT.setTreasury(await admin.getAddress());
        strategyCompoundInstanceUSDC = await upgrades.deployProxy(compoundNewStartegy, [
            USDC.address,
            cUSDC.address,
            comptroller.address,
            COMP.address,
        ]);
        await strategyCompoundInstanceUSDC.setTreasury(await admin.getAddress());
    });

    it("Should be able to setup Stanley", async () => {
        //given
        const newStanleyAddress = await userTwo.getAddress(); // random address
        const oldStanleyAddress = await strategyCompoundInstanceDAI.getStanley();
        //when
        await expect(strategyCompoundInstanceDAI.setStanley(newStanleyAddress))
            .to.emit(strategyCompoundInstanceDAI, "StanleyChanged")
            .withArgs(await admin.getAddress, oldStanleyAddress, newStanleyAddress);
    });

    it("Should not be able to setup Stanley when non owner want to setup new address", async () => {
        //given
        const stanleyAddress = await userTwo.getAddress(); // random address
        //when
        await expect(
            strategyCompoundInstanceDAI.connect(userOne).setStanley(stanleyAddress)
        ).to.be.revertedWith("Ownable: caller is not the owner");
    });

    it("Should be able to setup Stanley and interact with DAI", async () => {
        //given
        const newStanleyAddress = await userTwo.getAddress(); // random address
        const oldStanleyAddress = await strategyCompoundInstanceDAI.getStanley();

        await expect(strategyCompoundInstanceDAI.setStanley(newStanleyAddress))
            .to.emit(strategyCompoundInstanceDAI, "StanleyChanged")
            .withArgs(await admin.getAddress, oldStanleyAddress, newStanleyAddress);

        await DAI.setupInitialAmount(newStanleyAddress, TC_10_000_USD_18DEC);

        DAI.connect(userTwo).increaseAllowance(
            strategyCompoundInstanceDAI.address,
            TC_1000_USD_18DEC
        );

        await strategyCompoundInstanceDAI.connect(userTwo).deposit(TC_1000_USD_18DEC);

        expect(await DAI.balanceOf(newStanleyAddress)).to.be.equal(TC_9_000_USD_18DEC);
        expect((await cDAI.balanceOf(strategyCompoundInstanceDAI.address)).toString()).to.be.equal(
            "754533916231843181332"
        );

        await strategyCompoundInstanceDAI.connect(userTwo).withdraw(TC_1000_USD_18DEC);

        expect(await DAI.balanceOf(newStanleyAddress)).to.be.equal(TC_9_999_USD_18DEC);
        expect(await cDAI.balanceOf(strategyCompoundInstanceDAI.address)).to.be.equal(ONE);
    });

    it("Should be able to setup Stanley and interact with USDT", async () => {
        //given
        const newStanleyAddress = await userTwo.getAddress(); // random address
        const oldStanleyAddress = await strategyCompoundInstanceUSDT.getStanley();
        await expect(strategyCompoundInstanceUSDT.setStanley(newStanleyAddress))
            .to.emit(strategyCompoundInstanceUSDT, "StanleyChanged")
            .withArgs(await admin.getAddress, oldStanleyAddress, newStanleyAddress);

        await USDT.setupInitialAmount(newStanleyAddress, TC_10_000_USD_6DEC);

        USDT.connect(userTwo).increaseAllowance(
            strategyCompoundInstanceUSDT.address,
            TC_10_000_USD_6DEC
        );

        await strategyCompoundInstanceUSDT.connect(userTwo).deposit(TC_1000_USD_18DEC);

        expect(await USDT.balanceOf(newStanleyAddress)).to.be.equal(TC_9_000_USD_6DEC);

        expect(
            (await cUSDT.balanceOf(strategyCompoundInstanceUSDT.address)).toString()
        ).to.be.equal("754533916");

        await strategyCompoundInstanceUSDT.connect(userTwo).withdraw(TC_1000_USD_18DEC);

        expect(await USDT.balanceOf(newStanleyAddress)).to.be.equal(TC_10_000_USD_6DEC);
        expect(await cUSDC.balanceOf(strategyCompoundInstanceUSDT.address)).to.be.equal(ZERO);
    });

    it("Should be able to setup Stanley and interact with USDC", async () => {
        //given
        const newStanleyAddress = await userTwo.getAddress(); // random address
        const oldStanleyAddress = await strategyCompoundInstanceUSDC.getStanley();
        await expect(strategyCompoundInstanceUSDC.setStanley(newStanleyAddress))
            .to.emit(strategyCompoundInstanceUSDC, "StanleyChanged")
            .withArgs(await admin.getAddress, oldStanleyAddress, newStanleyAddress);

        await USDC.setupInitialAmount(newStanleyAddress, TC_10_000_USD_6DEC);

        USDC.connect(userTwo).increaseAllowance(
            strategyCompoundInstanceUSDC.address,
            TC_10_000_USD_6DEC
        );

        await strategyCompoundInstanceUSDC.connect(userTwo).deposit(TC_1000_USD_18DEC);

        expect(await USDC.balanceOf(newStanleyAddress)).to.be.equal(TC_9_000_USD_6DEC);
        expect(
            (await cUSDC.balanceOf(strategyCompoundInstanceUSDC.address)).toString()
        ).to.be.equal("754533916");

        await strategyCompoundInstanceUSDC.connect(userTwo).withdraw(TC_1000_USD_18DEC);

        expect(await USDC.balanceOf(newStanleyAddress)).to.be.equal(TC_10_000_USD_6DEC);
        expect(await cUSDC.balanceOf(strategyCompoundInstanceUSDC.address)).to.be.equal(ZERO);
    });

    it("Should not be able to setup Treasury aave strategy when sender is not Treasury Manager", async () => {
        await expect(
            strategyCompoundInstanceUSDC.connect(userOne).setTreasury(constants.AddressZero)
        ).to.be.revertedWith("IPOR_505");
    });

    it("Should not be able to setup Treasury Manager aave strategy", async () => {
        await expect(
            strategyCompoundInstanceUSDC.connect(userOne).setTreasuryManager(constants.AddressZero)
        ).to.be.revertedWith("Ownable: caller is not the owner");
    });

    it("Should setup new blocksPerYear", async () => {
        // whan
        await expect(strategyCompoundInstanceDAI.setBlocksPerYear(BigNumber.from("2102500")))
            .to.emit(strategyCompoundInstanceDAI, "BlocksPerYearChanged")
            .withArgs(await admin.getAddress, BigNumber.from("2102400"), BigNumber.from("2102500"));
    });

    it("Should not setup new blocksPerYear to zero", async () => {
        // whan
        await expect(strategyCompoundInstanceDAI.setBlocksPerYear(ZERO)).to.be.revertedWith(
            "IPOR_004"
        );
    });

    it("Should be able do claim", async () => {
        //when
        await strategyCompoundInstanceDAI.doClaim();
        await expect(strategyCompoundInstanceDAI.doClaim()).to.emit(
            strategyCompoundInstanceDAI,
            "DoClaim"
        );
    });

    it("Should not be able do claim when not owner", async () => {
        await expect(strategyCompoundInstanceUSDC.connect(userOne).doClaim()).to.be.revertedWith(
            "Ownable: caller is not the owner"
        );
    });

    it("Should not setup new blocksPerYear when no owner", async () => {
        // whan
        await expect(
            strategyCompoundInstanceDAI.connect(userOne).setBlocksPerYear(BigNumber.from("2102500"))
        ).to.be.revertedWith("Ownable: caller is not the owner");
    });
});

import hre, { upgrades } from "hardhat";
import chai from "chai";
import { BigNumber, Signer } from "ethers";

import { solidity } from "ethereum-waffle";
import {
    ERC20,
    MockWhitePaper,
    MockComptroller,
    UsdcMockedToken,
    UsdtMockedToken,
    MockCToken,
    DaiMockedToken,
    StrategyCompound,
} from "../../../../types";

import { assertError } from "../../../utils/AssertUtils";

chai.use(solidity);
const { expect } = chai;

const stableTotalSupply18Decimals = "1000000000000000000000000000000";
const totalSupply6Decimals = "100000000000000000000";
const TC_1000_USD_18DEC = BigNumber.from("1000000000000000000000");

describe("COMPOUND strategy pauseable", () => {
    let strategy: StrategyCompound;
    let USDC: UsdcMockedToken;
    let USDT: UsdtMockedToken;
    let DAI: DaiMockedToken;
    let cUSDC: MockCToken;
    let cUSDT: MockCToken;
    let cDAI: MockCToken;
    let COMP: ERC20;
    let admin: Signer, userOne: Signer, userTwo: Signer;
    let comptroller: MockComptroller;

    beforeEach(async () => {
        [admin, userOne, userTwo] = await hre.ethers.getSigners();
        const MockWhitePaper = await hre.ethers.getContractFactory("MockWhitePaper");
        const MockWhitePaperInstance = (await MockWhitePaper.deploy()) as MockWhitePaper;

        // #################################################################################
        // #####################        USDC / aUSDC     ###################################
        // #################################################################################

        const UsdcMockedToken = await hre.ethers.getContractFactory("UsdcMockedToken");
        const UsdtMockedToken = await hre.ethers.getContractFactory("UsdtMockedToken");
        const DaiMockedToken = await hre.ethers.getContractFactory("DaiMockedToken");
        USDC = (await UsdcMockedToken.deploy(totalSupply6Decimals, 6)) as UsdcMockedToken;
        USDT = (await UsdtMockedToken.deploy(totalSupply6Decimals, 6)) as UsdtMockedToken;
        DAI = (await DaiMockedToken.deploy(stableTotalSupply18Decimals, 18)) as DaiMockedToken;
        const cTokenFactory = await hre.ethers.getContractFactory("MockCToken");
        cUSDC = (await cTokenFactory.deploy(
            USDC.address,
            MockWhitePaperInstance.address,
            BigNumber.from("6"),
            "cUSDC",
            "cUSDC"
        )) as MockCToken;

        cUSDT = (await cTokenFactory.deploy(
            USDT.address,
            MockWhitePaperInstance.address,
            BigNumber.from("6"),
            "cUSDT",
            "cUSDT"
        )) as MockCToken;

        cDAI = (await cTokenFactory.deploy(
            DAI.address,
            MockWhitePaperInstance.address,
            BigNumber.from("18"),
            "cDAI",
            "cDAI"
        )) as MockCToken;

        const DAIFactory = await hre.ethers.getContractFactory("DaiMockedToken");
        COMP = (await DAIFactory.deploy(stableTotalSupply18Decimals, 18)) as ERC20;

        const MockComptroller = await hre.ethers.getContractFactory("MockComptroller");
        comptroller = (await MockComptroller.deploy(
            COMP.address,
            cUSDT.address,
            cUSDC.address,
            cDAI.address
        )) as MockComptroller;

        const compoundNewStartegy = await hre.ethers.getContractFactory("StrategyCompound");
        strategy = (await upgrades.deployProxy(compoundNewStartegy, [
            USDC.address,
            cUSDC.address,
            comptroller.address,
            COMP.address,
        ])) as StrategyCompound;
        await strategy.setTreasuryManager(await admin.getAddress());
        await strategy.setTreasury(await admin.getAddress());
    });

    it("Should be able to pause contract when sender is owner", async () => {
        //given
        //when
        await strategy.pause();
        //then
        expect(await strategy.paused()).to.be.true;
    });

    it("Should be able to unpause contract when sender is owner", async () => {
        //given
        await strategy.pause();
        expect(await strategy.paused()).to.be.true;
        //when
        await strategy.unpause();
        //then
        expect(await strategy.paused()).to.be.false;
    });

    it("Should not be able to unpause contract when sender is not owner", async () => {
        //given
        await strategy.pause();
        expect(await strategy.paused()).to.be.true;
        //when
        await assertError(
            strategy.connect(userOne).unpause(),
            //then
            "Ownable: caller is not the owner"
        );
    });

    it("should NOT pause Smart Contract specific methods when paused", async () => {
        //given
        //when
        await strategy.pause();
        //then
        expect(await strategy.paused()).to.be.true;
        await strategy.getAsset();
        await strategy.getShareToken();
        await strategy.balanceOf();
        await strategy.getAsset();
    });

    it("should pause Smart Contract specific methods", async () => {
        //given
        //when
        await strategy.pause();
        //then
        const mockAddress = await userTwo.getAddress();

        expect(await strategy.paused()).to.be.true;
        await assertError(strategy.deposit(TC_1000_USD_18DEC), "Pausable: paused");
        await assertError(strategy.withdraw(TC_1000_USD_18DEC), "Pausable: paused");
        await assertError(strategy.setBlocksPerYear(BigNumber.from("2102400")), "Pausable: paused");
        await assertError(strategy.doClaim(), "Pausable: paused");
        await assertError(strategy.setStanley(mockAddress), "Pausable: paused");
        await assertError(strategy.setTreasury(mockAddress), "Pausable: paused");
        await assertError(strategy.setTreasuryManager(mockAddress), "Pausable: paused");
    });
});

const hre = require("hardhat");
import chai from "chai";
import { BigNumber, Signer } from "ethers";

import { solidity } from "ethereum-waffle";
import {
    AaveStrategy,
    ERC20,
    MockWhitePaper,
    MockComptroller,
    UsdcMockedToken,
    UsdtMockedToken,
    MockCToken,
    DaiMockedToken,
    CompoundStrategy,
} from "../../../../types";

const { assertError } = require("../../../Utils");

chai.use(solidity);
const { expect } = chai;

const stableTotalSupply18Decimals = "1000000000000000000000000000000";
const totalSupply6Decimals = "100000000000000000000";
const TC_1000_USD_18DEC = BigNumber.from("1000000000000000000000");

describe("COMPOUND strategy pauseable", () => {
    let strategy: CompoundStrategy;
    let USDC: UsdcMockedToken;
    let cUSDC: MockCToken;
    let COMP: ERC20;
    let admin: Signer, userOne: Signer, userTwo: Signer;
    let comptrollerUSDC: MockComptroller;

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

        const DAIFactory = await hre.ethers.getContractFactory("DaiMockedToken");
        COMP = await DAIFactory.deploy(stableTotalSupply18Decimals, 18);

        const MockComptroller = await hre.ethers.getContractFactory("MockComptroller");
        comptrollerUSDC = (await MockComptroller.deploy(
            COMP.address,
            cUSDC.address
        )) as MockComptroller;

        const compoundNewStartegy = await hre.ethers.getContractFactory("CompoundStrategy");
        strategy = await upgrades.deployProxy(compoundNewStartegy, [
            USDC.address,
            cUSDC.address,
            comptrollerUSDC.address,
            COMP.address,
        ]);
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
        await assertError(strategy.beforeClaim(), "Pausable: paused");
        await assertError(strategy.doClaim(), "Pausable: paused");
        await assertError(strategy.setStanley(mockAddress), "Pausable: paused");
        await assertError(strategy.setTreasury(mockAddress), "Pausable: paused");
        await assertError(strategy.setTreasuryManager(mockAddress), "Pausable: paused");
    });
});

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
    MockAaveIncentivesController,
    MockAaveLendingPoolV2,
} from "../../../../types";

chai.use(solidity);
const { expect } = chai;

const stableTotalSupply18Decimals = "1000000000000000000000000000000";

describe("Compound strategy", () => {
    let compoundStrategyInstance: AaveStrategy;
    let DAI: ERC20;
    let cDAI: MockCDAI;
    let COMP: ERC20;
    let admin: Signer, userOne: Signer, userTwo: Signer;
    let comptroller: MockComptroller;

    beforeEach(async () => {
        [admin, userOne, userTwo] = await hre.ethers.getSigners();

        const DAIFactory = await hre.ethers.getContractFactory("DaiMockedToken");
        DAI = await DAIFactory.deploy(stableTotalSupply18Decimals, 18);
        COMP = await DAIFactory.deploy(stableTotalSupply18Decimals, 18);
        const MockWhitePaper = await hre.ethers.getContractFactory("MockWhitePaper");
        const MockCDAIFactory = await hre.ethers.getContractFactory("MockCDAI");
        const MockWhitePaperInstance = (await MockWhitePaper.deploy()) as MockWhitePaper;

        cDAI = (await MockCDAIFactory.deploy(
            DAI.address,
            await admin.getAddress(),
            MockWhitePaperInstance.address
        )) as MockCDAI;
        const MockComptroller = await hre.ethers.getContractFactory("MockComptroller");
        comptroller = (await MockComptroller.deploy(COMP.address, cDAI.address)) as MockComptroller;

        const compoundNewStartegy = await hre.ethers.getContractFactory("CompoundStrategy");
        compoundStrategyInstance = await upgrades.deployProxy(compoundNewStartegy, [
            DAI.address,
            cDAI.address,
            comptroller.address,
            COMP.address,
        ]);
    });

    it("Should be able to setup Stanley", async () => {
        //given
        const stanleyAddress = await userTwo.getAddress(); // random address
        //when
        await expect(compoundStrategyInstance.setStanley(stanleyAddress))
            .to.emit(compoundStrategyInstance, "SetStanley")
            .withArgs(await admin.getAddress, stanleyAddress, compoundStrategyInstance.address);
    });

    it("Should not be able to setup Stanley when non owner want to setup new address", async () => {
        //given
        const stanleyAddress = await userTwo.getAddress(); // random address
        //when
        await expect(
            compoundStrategyInstance.connect(userOne).setStanley(stanleyAddress)
        ).to.be.revertedWith("Ownable: caller is not the owner");
    });
});

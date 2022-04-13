const hre = require("hardhat");
import chai from "chai";
import { constants, Signer } from "ethers";

const { AddressZero } = constants;
import { solidity } from "ethereum-waffle";
import {
    StrategyAave,
    ERC20,
    MockAaveLendingPoolProvider,
    MockStakedAave,
    MockAaveIncentivesController,
    MockAaveLendingPoolV2,
} from "../../../../types";

chai.use(solidity);
const { expect } = chai;

const stableTotalSupply18Decimals = "1000000000000000000000000000000";

describe("AAVE strategy", () => {
    let strategyAaveInstance: StrategyAave;
    let DAI: ERC20;
    let aDAI: ERC20;
    let stkAAVE: ERC20;
    let AAVE: ERC20;
    let stakedAave: MockStakedAave;
    let admin: Signer, userOne: Signer, userTwo: Signer;
    let addressProvider: MockAaveLendingPoolProvider;
    let aaveIncentivesController: MockAaveIncentivesController;
    let StrategyAaveInstance: any;

    beforeEach(async () => {
        [admin, userOne, userTwo] = await hre.ethers.getSigners();

        const DAIFactory = await hre.ethers.getContractFactory("DaiMockedToken");
        DAI = await DAIFactory.deploy(stableTotalSupply18Decimals, 18);
        await DAI.deployed();
        aDAI = await DAIFactory.deploy(stableTotalSupply18Decimals, 18);
        await aDAI.deployed();
        stkAAVE = await DAIFactory.deploy(stableTotalSupply18Decimals, 18);
        await stkAAVE.deployed();
        AAVE = await DAIFactory.deploy(stableTotalSupply18Decimals, 18);
        await AAVE.deployed();
        const MockAaveLendingPoolProvider = await hre.ethers.getContractFactory(
            "MockAaveLendingPoolProvider"
        );
        addressProvider =
            (await MockAaveLendingPoolProvider.deploy()) as MockAaveLendingPoolProvider;
        const MockAaveLendingPool = await hre.ethers.getContractFactory("MockAaveLendingPoolV2");
        const lendingPool = (await MockAaveLendingPool.deploy(
            DAI.address,
            aDAI.address
        )) as MockAaveLendingPoolV2;
        await addressProvider._setLendingPool(lendingPool.address);
        const MockStakedAave = await hre.ethers.getContractFactory("MockStakedAave");
        stakedAave = (await MockStakedAave.deploy(AAVE.address)) as MockStakedAave;

        const MockAaveIncentivesController = await hre.ethers.getContractFactory(
            "MockAaveIncentivesController"
        );
        aaveIncentivesController = (await MockAaveIncentivesController.deploy(
            stakedAave.address
        )) as MockAaveIncentivesController;

        StrategyAaveInstance = await hre.ethers.getContractFactory("StrategyAave");
        strategyAaveInstance = await upgrades.deployProxy(StrategyAaveInstance, [
            DAI.address,
            aDAI.address,
            addressProvider.address,
            stakedAave.address,
            aaveIncentivesController.address,
            AAVE.address,
        ]);
        await strategyAaveInstance.setTreasury(await userTwo.getAddress());
    });

    it("Should be able to setup Stanley", async () => {
        //given
        const newStanleyAddress = await userTwo.getAddress(); // random address
        const oldStanleyAddress = await strategyAaveInstance.getStanley();
        //when
        await expect(strategyAaveInstance.setStanley(newStanleyAddress))
            .to.emit(strategyAaveInstance, "StanleyChanged")
            .withArgs(await admin.getAddress, oldStanleyAddress, newStanleyAddress);
    });

    it("Should not be able to setup Stanley when non owner want to setup new address", async () => {
        //given
        const stanleyAddress = await userTwo.getAddress(); // random address
        //when
        await expect(
            strategyAaveInstance.connect(userOne).setStanley(stanleyAddress)
        ).to.be.revertedWith("Ownable: caller is not the owner");
    });

    it("Should not be able to setup Treasury aave strategy", async () => {
        await expect(strategyAaveInstance.setTreasury(AddressZero)).to.be.revertedWith("IPOR_502");
    });

    it("Should not be able to setup Treasury aave strategy when sender is not Treasury Manager", async () => {
        await expect(
            strategyAaveInstance.connect(userOne).setTreasury(AddressZero)
        ).to.be.revertedWith("IPOR_505");
    });

    it("Should not be able to setup Treasury Manager aave strategy", async () => {
        await expect(
            strategyAaveInstance.connect(userOne).setTreasuryManager(AddressZero)
        ).to.be.revertedWith("Ownable: caller is not the owner");
    });

    it("Should be able do before claim", async () => {
        //when
        await expect(strategyAaveInstance.beforeClaim()).to.emit(
            strategyAaveInstance,
            "DoBeforeClaim"
        );
    });

    it("Should be able do claim", async () => {
        //when
        await expect(strategyAaveInstance.doClaim()).to.emit(strategyAaveInstance, "DoClaim");
    });

    it("Should be able to set StkAave address", async () => {
        //when
        await expect(strategyAaveInstance.setStkAave(await admin.getAddress())).to.emit(
            strategyAaveInstance,
            "StkAaveChanged"
        );
    });
});

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
    MockAaveLendingPoolProvider,
    MockStakedAave,
    MockAaveIncentivesController,
    MockAaveLendingPoolV2,
} from "../../../../types";

chai.use(solidity);
const { expect } = chai;

const stableTotalSupply18Decimals = "1000000000000000000000000000000";

describe("AAVE strategy", () => {
    let aaveStrategyInstance: AaveStrategy;
    let DAI: ERC20;
    let aDAI: ERC20;
    let stkAAVE: ERC20;
    let AAVE: ERC20;
    let stakedAave: MockStakedAave;
    let admin: Signer, userOne: Signer, userTwo: Signer;

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
        const addressProvider =
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
        const aaveIncentivesController = (await MockAaveIncentivesController.deploy(
            stakedAave.address
        )) as MockAaveIncentivesController;

        const AaveStrategyInstance = await hre.ethers.getContractFactory("AaveStrategy");
        aaveStrategyInstance = await upgrades.deployProxy(AaveStrategyInstance, [
            DAI.address,
            aDAI.address,
            addressProvider.address,
            stakedAave.address,
            aaveIncentivesController.address,
            AAVE.address,
            await userTwo.getAddress(),
        ]);
    });

    it("Should be able to setup Stanley", async () => {
        //given
        const stanleyAddress = await userTwo.getAddress(); // random address
        //when
        await expect(aaveStrategyInstance.setStanley(stanleyAddress))
            .to.emit(aaveStrategyInstance, "SetStanley")
            .withArgs(await admin.getAddress, stanleyAddress, aaveStrategyInstance.address);
    });

    it("Should not be able to setup Stanley when non owner want to setup new address", async () => {
        //given
        const stanleyAddress = await userTwo.getAddress(); // random address
        //when
        await expect(
            aaveStrategyInstance.connect(userOne).setStanley(stanleyAddress)
        ).to.be.revertedWith("Ownable: caller is not the owner");
    });
});

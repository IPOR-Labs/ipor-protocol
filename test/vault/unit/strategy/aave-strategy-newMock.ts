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
    DaiMockedToken,
    MockStakedAave,
    MockAaveIncentivesController,
    MockAaveLendingPoolV2,
} from "../../../../types";

chai.use(solidity);
const { expect } = chai;

const stableTotalSupply18Decimals = "1000000000000000000000000000000";

describe("AAVE strategy", () => {
    let aaveStrategyInstance: AaveStrategy;
    let DAI: DaiMockedToken;
    let aDAI: ERC20;
    let stkAAVE: ERC20;
    let AAVE: ERC20;
    let stakedAave: MockStakedAave;
    let admin: Signer, userOne: Signer, userTwo: Signer;

    beforeEach(async () => {
        [admin, userOne, userTwo] = await hre.ethers.getSigners();

        const DAIFactory = await hre.ethers.getContractFactory("DaiMockedToken");
        DAI = (await DAIFactory.deploy(stableTotalSupply18Decimals, 18)) as DaiMockedToken;

        stkAAVE = await DAIFactory.deploy(stableTotalSupply18Decimals, 18);
        await stkAAVE.deployed();
        AAVE = await DAIFactory.deploy(stableTotalSupply18Decimals, 18);
        await AAVE.deployed();

        // new Mock Start

        const ADAIFactory = await hre.ethers.getContractFactory("MockADai");
        aDAI = await ADAIFactory.deploy();

        const MockLendingPoolAave = await hre.ethers.getContractFactory("MockLendingPoolAave");
        const lendingPool = await MockLendingPoolAave.deploy(
            DAI.address,
            aDAI.address,
            BigNumber.from("100000"),
            DAI.address, // usdc
            aDAI.address, // usdc
            BigNumber.from("200000"), // usdc
            DAI.address, // usdt
            aDAI.address, // usdt
            BigNumber.from("200000") // usdt
        );

        const MockProviderAave = await hre.ethers.getContractFactory("MockProviderAave");
        const addressProvider = await MockProviderAave.deploy(lendingPool.address);

        // new Mock End

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
        ]);
    });

    it("Should be able to setup Stanley", async () => {
        //given
        const stanleyAddress = await userTwo.getAddress(); // random address
        await expect(aaveStrategyInstance.setStanley(stanleyAddress))
            .to.emit(aaveStrategyInstance, "SetStanley")
            .withArgs(await admin.getAddress, stanleyAddress, aaveStrategyInstance.address);

        await DAI.setupInitialAmount(stanleyAddress, BigNumber.from("100000000000000000000"));

        DAI.connect(userTwo).increaseAllowance(
            aaveStrategyInstance.address,
            BigNumber.from("100000000000000000000")
        );

        await aaveStrategyInstance.connect(userTwo).deposit(BigNumber.from("1000000000000000000"));

        console.log((await DAI.balanceOf(stanleyAddress)).toString());
        console.log((await aDAI.balanceOf(aaveStrategyInstance.address)).toString());

        await aaveStrategyInstance.connect(userTwo).withdraw(BigNumber.from("1000000000000000000"));

        console.log((await DAI.balanceOf(stanleyAddress)).toString());
        console.log((await aDAI.balanceOf(aaveStrategyInstance.address)).toString());
    });

    it.skip("Should not be able to setup Stanley when non owner want to setup new address", async () => {
        //given
        const stanleyAddress = await userTwo.getAddress(); // random address
        //when
        await expect(
            aaveStrategyInstance.connect(userOne).setStanley(stanleyAddress)
        ).to.be.revertedWith("Ownable: caller is not the owner");
    });
});

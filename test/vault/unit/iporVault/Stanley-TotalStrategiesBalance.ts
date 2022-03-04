import hre, { upgrades } from "hardhat";
const keccak256 = require("keccak256");
import chai from "chai";
import { BigNumber, Signer } from "ethers";
import { solidity } from "ethereum-waffle";

import { MockStrategy, Stanley, TestERC20 } from "../../../../types";

chai.use(solidity);
const { expect } = chai;

describe("Stanley -> totalStrategiesBalance", () => {
    let admin: Signer;
    let stanley: Stanley;
    let DAI: TestERC20;
    let aaveStrategy: MockStrategy;
    let compoundStrategy: MockStrategy;

    beforeEach(async () => {
        [admin] = await hre.ethers.getSigners();
        const tokenFactory = await hre.ethers.getContractFactory("TestERC20");
        DAI = (await tokenFactory.deploy(
            BigNumber.from(2).pow(255)
        )) as TestERC20;
        const StanleyFactory = await hre.ethers.getContractFactory("Stanley");
        const tokenFactoryIvToken = await hre.ethers.getContractFactory(
            "IvToken"
        );

        const AaveStrategy = await hre.ethers.getContractFactory(
            "MockStrategy"
        );
        aaveStrategy = (await AaveStrategy.deploy()) as MockStrategy;
        await aaveStrategy.setShareToken(DAI.address);
        await aaveStrategy.setAsset(DAI.address);
        const CompoundStrategy = await hre.ethers.getContractFactory(
            "MockStrategy"
        );
        compoundStrategy = (await CompoundStrategy.deploy()) as MockStrategy;
        await compoundStrategy.setShareToken(DAI.address);
        await compoundStrategy.setAsset(DAI.address);

        const ivToken = await tokenFactoryIvToken.deploy(
            "IvToken",
            "IVT",
            "0x6b175474e89094c44da98b954eedeac495271d0f"
        );

        const Stanley = await hre.ethers.getContractFactory("Stanley");
        stanley = (await await upgrades.deployProxy(Stanley, [
            DAI.address,
            ivToken.address,
            aaveStrategy.address,
            compoundStrategy.address,
        ])) as Stanley;

        await ivToken.setStanley(stanley.address);
    });

    it("Should should return balance from aave", async () => {
        //  given
        const aaveBalance = BigNumber.from("100000");
        await aaveStrategy.setBalance(aaveBalance);
        await stanley.setAaveStrategy(aaveStrategy.address);
        await stanley.setCompoundStrategy(compoundStrategy.address);
        //  when
        const balance = await stanley.totalBalance(await admin.getAddress());
        //  then
        expect(balance).to.be.equal(aaveBalance);
    });

    it("Should should return balance from compound", async () => {
        //  given
        const compoundBalance = BigNumber.from("100000");
        await compoundStrategy.setBalance(compoundBalance);
        await stanley.setAaveStrategy(aaveStrategy.address);
        await stanley.setCompoundStrategy(compoundStrategy.address);
        //  when
        const balance = await stanley.totalBalance(await admin.getAddress());
        //  then
        expect(balance).to.be.equal(compoundBalance);
    });

    it("Should should return sum of balances from aave and compound", async () => {
        //  given
        const aaveBalance = BigNumber.from("9999");
        await aaveStrategy.setBalance(aaveBalance);
        const compoundBalance = BigNumber.from("100000");
        await compoundStrategy.setBalance(compoundBalance);

        await stanley.setAaveStrategy(aaveStrategy.address);
        await stanley.setCompoundStrategy(compoundStrategy.address);
        //  when
        const balance = await stanley.totalBalance(await admin.getAddress());
        //  then
        expect(balance).to.be.equal(compoundBalance.add(aaveBalance));
    });
});

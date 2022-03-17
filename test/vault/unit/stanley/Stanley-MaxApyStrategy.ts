import hre, { upgrades } from "hardhat";
const keccak256 = require("keccak256");
import chai from "chai";
import { BigNumber, Signer } from "ethers";
import { solidity } from "ethereum-waffle";

import { MockStrategy, ItfStanleyDai, TestERC20 } from "../../../../types";

chai.use(solidity);
const { expect } = chai;

describe("Stanley -> maxApyStrategy", () => {
    let admin: Signer;
    let stanley: ItfStanleyDai;
    let DAI: TestERC20;
    let aaveStrategy: MockStrategy;
    let compoundStrategy: MockStrategy;

    beforeEach(async () => {
        [admin] = await hre.ethers.getSigners();
        const tokenFactory = await hre.ethers.getContractFactory("TestERC20");
        DAI = (await tokenFactory.deploy(BigNumber.from(2).pow(255))) as TestERC20;

        const tokenFactoryIvToken = await hre.ethers.getContractFactory("IvToken");
        const ivToken = await tokenFactoryIvToken.deploy("IvToken", "IVT", DAI.address);

        const AaveStrategy = await hre.ethers.getContractFactory("MockStrategy");
        aaveStrategy = (await AaveStrategy.deploy()) as MockStrategy;

        await aaveStrategy.setShareToken(DAI.address);
        await aaveStrategy.setAsset(DAI.address);

        const CompoundStrategy = await hre.ethers.getContractFactory("MockStrategy");
        compoundStrategy = (await CompoundStrategy.deploy()) as MockStrategy;
        await compoundStrategy.setShareToken(DAI.address);
        await compoundStrategy.setAsset(DAI.address);

        const ItfStanleyDai = await hre.ethers.getContractFactory("ItfStanleyDai");
        stanley = (await await upgrades.deployProxy(ItfStanleyDai, [
            DAI.address,
            ivToken.address,
            aaveStrategy.address,
            compoundStrategy.address,
        ])) as ItfStanleyDai;
        await ivToken.setStanley(stanley.address);
    });

    it("Should select aave strategy", async () => {
        //  given
        await aaveStrategy.setApy(BigNumber.from("100000"));
        await compoundStrategy.setApy(BigNumber.from("99999"));

        await stanley.setAaveStrategy(aaveStrategy.address);
        await stanley.setCompoundStrategy(compoundStrategy.address);

        //  when
        const result = await stanley.getMaxApyStrategy();

        //  then
        expect(result.strategyMaxApy).to.be.equal(aaveStrategy.address);
    });

    it("Should select aave strategy when aaveApy == compoundApy", async () => {
        //  given
        await aaveStrategy.setApy(BigNumber.from("10"));
        await compoundStrategy.setApy(BigNumber.from("10"));

        await stanley.setAaveStrategy(aaveStrategy.address);
        await stanley.setCompoundStrategy(compoundStrategy.address);

        //  when
        const result = await stanley.getMaxApyStrategy();

        //  then
        expect(result.strategyMaxApy).to.be.equal(aaveStrategy.address);
    });

    it("Should select compound strategy", async () => {
        //  given
        await aaveStrategy.setApy(BigNumber.from("1000"));
        await compoundStrategy.setApy(BigNumber.from("99999"));

        await stanley.setAaveStrategy(aaveStrategy.address);
        await stanley.setCompoundStrategy(compoundStrategy.address);

        //  when
        const result = await stanley.getMaxApyStrategy();

        //  then
        expect(result.strategyMaxApy).to.be.equal(compoundStrategy.address);
    });
});

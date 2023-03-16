import hre, { upgrades } from "hardhat";
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
    let strategyAave: MockStrategy;
    let strategyCompound: MockStrategy;

    beforeEach(async () => {
        [admin] = await hre.ethers.getSigners();
        const tokenFactory = await hre.ethers.getContractFactory("TestERC20");
        DAI = (await tokenFactory.deploy(BigNumber.from(2).pow(255))) as TestERC20;

        const tokenFactoryIvToken = await hre.ethers.getContractFactory("IvToken");
        const ivToken = await tokenFactoryIvToken.deploy("IvToken", "IVT", DAI.address);

        const StrategyAave = await hre.ethers.getContractFactory("MockStrategy");
        strategyAave = (await StrategyAave.deploy()) as MockStrategy;
        await strategyAave.setShareToken(DAI.address);
        await strategyAave.setAsset(DAI.address);

        const StrategyCompound = await hre.ethers.getContractFactory("MockStrategy");
        strategyCompound = (await StrategyCompound.deploy()) as MockStrategy;
        await strategyCompound.setShareToken(DAI.address);
        await strategyCompound.setAsset(DAI.address);

        const ItfStanleyDai = await hre.ethers.getContractFactory("ItfStanleyDai");
        stanley = (await upgrades.deployProxy(ItfStanleyDai, [
            DAI.address,
            ivToken.address,
            strategyAave.address,
            strategyCompound.address,
        ])) as ItfStanleyDai;
        await ivToken.setStanley(stanley.address);
    });

    it("Should select AAVE strategy", async () => {
        //  given
        await strategyAave.setApr(BigNumber.from("100000"));
        await strategyCompound.setApr(BigNumber.from("99999"));

        //  when
        const result = await stanley.getMaxApyStrategy();

        //  then
        expect(result.strategyMaxApy).to.be.equal(strategyAave.address);
    });

    it("Should select aave strategy when aaveApy == compoundApy", async () => {
        //  given
        await strategyAave.setApr(BigNumber.from("10"));
        await strategyCompound.setApr(BigNumber.from("10"));

        //  when
        const result = await stanley.getMaxApyStrategy();

        //  then
        expect(result.strategyMaxApy).to.be.equal(strategyAave.address);
    });

    it("Should select compound strategy", async () => {
        //  given
        await strategyAave.setApr(BigNumber.from("1000"));
        await strategyCompound.setApr(BigNumber.from("99999"));

        //  when
        const result = await stanley.getMaxApyStrategy();

        //  then
        expect(result.strategyMaxApy).to.be.equal(strategyCompound.address);
    });
});

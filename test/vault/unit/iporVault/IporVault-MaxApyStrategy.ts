import hre, { upgrades } from "hardhat";
const keccak256 = require("keccak256");
import chai from "chai";
import { BigNumber, Signer } from "ethers";
import { solidity } from "ethereum-waffle";

import { MockStrategy, Stanley, TestERC20 } from "../../../../types";

chai.use(solidity);
const { expect } = chai;

describe("Stanley -> maxApyStrategy", () => {
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
        const ivToken = await tokenFactoryIvToken.deploy(
            "IvToken",
            "IVT",
            "0x6b175474e89094c44da98b954eedeac495271d0f"
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

        const Stanley = await hre.ethers.getContractFactory("Stanley");
        stanley = (await await upgrades.deployProxy(Stanley, [
            DAI.address,
            ivToken.address,
            aaveStrategy.address,
            compoundStrategy.address,
        ])) as Stanley;

        await stanley.grantRole(
            keccak256("GOVERNANCE_ROLE"),
            await admin.getAddress()
        );
        await ivToken.setVault(stanley.address);
    });

    it("Should select aave strategy", async () => {
        //  given

        await aaveStrategy.setApy(BigNumber.from("100000"));
        await compoundStrategy.setApy(BigNumber.from("99999"));

        await stanley.setAaveStrategy(aaveStrategy.address);
        await stanley.setCompoundStrategy(compoundStrategy.address);
        //  when
        const maxApyStrategy = await stanley.getMaxApyStrategy();
        //  then
        expect(maxApyStrategy).to.be.equal(aaveStrategy.address);
    });

    it("Should select aave strategy when aaveApy == compoundApy", async () => {
        //  given
        await aaveStrategy.setApy(BigNumber.from("10"));
        await compoundStrategy.setApy(BigNumber.from("10"));

        await stanley.setAaveStrategy(aaveStrategy.address);
        await stanley.setCompoundStrategy(compoundStrategy.address);
        //  when
        const maxApyStrategy = await stanley.getMaxApyStrategy();
        //  then
        expect(maxApyStrategy).to.be.equal(aaveStrategy.address);
    });

    it("Should select compound strategy", async () => {
        //  given
        await aaveStrategy.setApy(BigNumber.from("1000"));
        await compoundStrategy.setApy(BigNumber.from("99999"));

        await stanley.setAaveStrategy(aaveStrategy.address);
        await stanley.setCompoundStrategy(compoundStrategy.address);
        //  when
        const maxApyStrategy = await stanley.getMaxApyStrategy();
        //  then
        expect(maxApyStrategy).to.be.equal(compoundStrategy.address);
    });
});

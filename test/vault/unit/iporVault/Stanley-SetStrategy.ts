import hre, { upgrades } from "hardhat";
const keccak256 = require("keccak256");
import chai from "chai";
import { BigNumber, Signer, constants } from "ethers";
import { solidity } from "ethereum-waffle";

import { MockStrategy, Stanley, TestERC20 } from "../../../../types";

chai.use(solidity);
const { expect } = chai;

describe("Stanley -> SetStrategy", () => {
    let admin: Signer;
    let stanley: Stanley;
    let DAI: TestERC20;
    let USDt: TestERC20;
    let aaveStrategy: MockStrategy;
    let compoundStrategy: MockStrategy;

    beforeEach(async () => {
        [admin] = await hre.ethers.getSigners();
        const tokenFactory = await hre.ethers.getContractFactory("TestERC20");
        DAI = (await tokenFactory.deploy(
            BigNumber.from(2).pow(255)
        )) as TestERC20;
        USDt = (await tokenFactory.deploy(
            BigNumber.from(2).pow(255)
        )) as TestERC20;
        const StanleyFactory = await hre.ethers.getContractFactory("Stanley");
        const tokenFactoryIvToken = await hre.ethers.getContractFactory(
            "IvToken"
        );
        const ivToken = await tokenFactoryIvToken.deploy(
            "IvToken",
            "IVT",
            DAI.address
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

        await ivToken.setStanley(stanley.address);
    });

    describe("aaveStrategy", () => {
        it("Should setup aave strategy", async () => {
            //given
            const NewAaveStrategy = await hre.ethers.getContractFactory(
                "MockStrategy"
            );
            const newAaveStrategy = await NewAaveStrategy.deploy();
            await newAaveStrategy.setShareToken(DAI.address);
            await newAaveStrategy.setAsset(DAI.address);
            //when
            await expect(stanley.setAaveStrategy(newAaveStrategy.address))
                //then
                .to.emit(stanley, "SetStrategy")
                .withArgs(newAaveStrategy.address, DAI.address);
        });

        it("Should not setup new strategy when underlying Token don't match", async () => {
            //given
            const NewAaveStrategy = await hre.ethers.getContractFactory(
                "MockStrategy"
            );
            const newAaveStrategy = await NewAaveStrategy.deploy();
            await newAaveStrategy.setShareToken(DAI.address);
            await newAaveStrategy.setAsset(USDt.address);
            await expect(
                //when
                stanley.setAaveStrategy(newAaveStrategy.address)
                //then
            ).to.revertedWith("IPOR_102");
        });

        it("Should not setup new strategy when pass zero address", async () => {
            //given
            const NewAaveStrategy = await hre.ethers.getContractFactory(
                "MockStrategy"
            );
            await expect(
                //when
                stanley.setAaveStrategy(constants.AddressZero)
                //then
            ).to.revertedWith("IPOR_37");
        });
    });

    describe("compoundStrategy", () => {
        it("Should setup compound strategy", async () => {
            //given
            const NewCompoundStrategy = await hre.ethers.getContractFactory(
                "MockStrategy"
            );
            const newCompoundStrategy = await NewCompoundStrategy.deploy();
            await newCompoundStrategy.setShareToken(DAI.address);
            await newCompoundStrategy.setAsset(DAI.address);
            //when
            await expect(
                stanley.setCompoundStrategy(newCompoundStrategy.address)
            )
                //then
                .to.emit(stanley, "SetStrategy")
                .withArgs(newCompoundStrategy.address, DAI.address);
            //then
        });

        it("Should not setup new strategy when underlying Token don't match", async () => {
            //given
            const NewCompoundStrategy = await hre.ethers.getContractFactory(
                "MockStrategy"
            );
            const newCompoundStrategy = await NewCompoundStrategy.deploy();
            await newCompoundStrategy.setShareToken(DAI.address);
            await newCompoundStrategy.setAsset(USDt.address);
            await expect(
                //when
                stanley.setCompoundStrategy(newCompoundStrategy.address)
                //then
            ).to.revertedWith("IPOR_102");
        });

        it("Should not setup new strategy when pass zero address", async () => {
            //given
            const NewAaveStrategy = await hre.ethers.getContractFactory(
                "MockStrategy"
            );
            await expect(
                //when
                stanley.setCompoundStrategy(constants.AddressZero)
                //then
            ).to.revertedWith("IPOR_37");
        });
    });
});

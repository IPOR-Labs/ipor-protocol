import hre, { upgrades } from "hardhat";
import chai from "chai";
const keccak256 = require("keccak256");
import { BigNumber, Signer } from "ethers";

import { solidity } from "ethereum-waffle";
import { TestERC20, Stanley } from "../../../../types";

chai.use(solidity);
const { expect } = chai;
const itParam = require("mocha-param");

const ADMIN_ROLE = keccak256("ADMIN_ROLE");
const GOVERNANCE_ROLE = keccak256("GOVERNANCE_ROLE");
const DEPOSIT_ROLE = keccak256("DEPOSIT_ROLE");
const WITHDRAW_ROLE = keccak256("WITHDRAW_ROLE");
const CLAIM_ROLE = keccak256("CLAIM_ROLE");

type NotGrant = { name: string; code: string; role: string };

const rolesNotGrant: NotGrant[] = [
    {
        name: "GOVERNANCE_ROLE",
        code: "",
        role: GOVERNANCE_ROLE,
    },
    {
        name: "DEPOSIT_ROLE",
        code: "",
        role: DEPOSIT_ROLE,
    },
    {
        name: "WITHDRAW_ROLE",
        code: "",
        role: WITHDRAW_ROLE,
    },
    {
        name: "CLAIM_ROLE",
        code: "",
        role: CLAIM_ROLE,
    },
];

describe("#Roles Localhost test", () => {
    let stanley: Stanley;
    let DAI: TestERC20;
    let tokenFactory: any;
    let admin: Signer, userOne: Signer, userTwo: Signer;

    beforeEach(async () => {
        [admin, userOne, userTwo] = await hre.ethers.getSigners();
        const tokenFactory = await hre.ethers.getContractFactory("TestERC20");
        DAI = (await tokenFactory.deploy(
            BigNumber.from(2).pow(255)
        )) as TestERC20;
        const tokenFactoryIvToken = await hre.ethers.getContractFactory(
            "IvToken"
        );
        const ivToken = await tokenFactoryIvToken.deploy(
            "IvToken",
            "IVT",
            "0x6b175474e89094c44da98b954eedeac495271d0f"
        );

        const AaveStrategy = await hre.ethers.getContractFactory(
            "StrategyMock"
        );
        const aaveStrategy = await AaveStrategy.deploy();
        await aaveStrategy.setShareToken(DAI.address);
        await aaveStrategy.setAsset(DAI.address);
        const CompoundStrategy = await hre.ethers.getContractFactory(
            "StrategyMock"
        );
        const compoundStrategy = await CompoundStrategy.deploy();
        await compoundStrategy.setShareToken(DAI.address);
        await compoundStrategy.setAsset(DAI.address);

        const StanleyFactory = await hre.ethers.getContractFactory("Stanley");
        stanley = (await await upgrades.deployProxy(StanleyFactory, [
            DAI.address,
            ivToken.address,
            aaveStrategy.address,
            compoundStrategy.address,
        ])) as Stanley;
        await ivToken.setVault(stanley.address);
    });

    describe("#ADMIN ROLE Localhost test", () => {
        it("should has ADMIN ROLE", async () => {
            //then
            const result = await stanley.hasRole(
                keccak256("ADMIN_ROLE"),
                await admin.getAddress()
            );
            expect(result).to.be.true;
        });

        itParam(
            "Should be able to grant ${value.name} role",
            rolesNotGrant,
            async (value: NotGrant) => {
                //given
                const { role } = value;
                const beforeGrant = await stanley.hasRole(
                    role,
                    await userOne.getAddress()
                );
                expect(beforeGrant).to.be.false;
                //when
                await stanley.grantRole(role, await userOne.getAddress());
                //then
                const afterGrant = await stanley.hasRole(
                    role,
                    await userOne.getAddress()
                );
                expect(afterGrant).to.be.true;
            }
        );

        itParam(
            "should not be able to grant ${value.name} role without ADMIN_ROLE",
            rolesNotGrant,
            async (value: NotGrant) => {
                //given
                const { role } = value;
                const hasAdminRole = await stanley.hasRole(
                    ADMIN_ROLE,
                    await userOne.getAddress()
                );
                expect(hasAdminRole).to.be.false;
                await expect(
                    //when
                    stanley
                        .connect(userOne)
                        .grantRole(role, await userTwo.getAddress())
                    //then
                ).to.be.revertedWith(
                    "AccessControl: account 0x70997970c51812dc3a010c7d01b50e0d17dc79c8 is missing role 0xa49807205ce4d355092ef5a8a18f56e8913cf4a201fbe287825b095693c21775"
                );
            }
        );

        it("should not be able to take away his ADMIN_ROLE role", async () => {
            await expect(
                //when
                stanley.revokeRole(ADMIN_ROLE, await admin.getAddress())
                //then
            ).to.be.revertedWith("IPOR_50");
        });

        it("should be able to grant ADMIN_ROLE", async () => {
            //given
            const hasAdminRole = await stanley.hasRole(
                ADMIN_ROLE,
                await userOne.getAddress()
            );
            expect(hasAdminRole).to.be.false;
            //when
            await stanley.grantRole(ADMIN_ROLE, await userOne.getAddress());
            //then
            const afterGrant = await stanley.hasRole(
                ADMIN_ROLE,
                await userOne.getAddress()
            );
            expect(afterGrant).to.be.true;
        });

        it("should be able to revolk ADMIN_ROLE", async () => {
            //given
            const hasAdminRole = await stanley.hasRole(
                ADMIN_ROLE,
                await userOne.getAddress()
            );
            expect(hasAdminRole).to.be.false;
            await stanley.grantRole(ADMIN_ROLE, await userOne.getAddress());
            const userOneHasAdminRole = await stanley.hasRole(
                ADMIN_ROLE,
                await userOne.getAddress()
            );
            expect(userOneHasAdminRole).to.be.true;
            //when
            await stanley
                .connect(userOne)
                .revokeRole(ADMIN_ROLE, await admin.getAddress());
            //then
            const afterRevoke = await stanley.hasRole(
                ADMIN_ROLE,
                await admin.getAddress()
            );
            expect(afterRevoke).to.be.false;
        });
    });

    describe("#Functional protection", () => {
        it("should not be able to migrate Asset In Max Apy Strategy", async () => {
            await expect(
                //when
                stanley.migrateAssetInMaxApyStrategy()
            ).to.be.revertedWith(
                //then
                "AccessControl: account 0xf39fd6e51aad88f6f4ce6ab8827279cfffb92266 is missing role 0x71840dc4906352362b0cdaf79870196c8e42acafade72d5d5a6d59291253ceb1"
            );
        });

        it("should not be able to deposit", async () => {
            await expect(
                //when
                stanley.deposit(BigNumber.from(10))
            ).to.be.revertedWith(
                //then
                "AccessControl: account 0xf39fd6e51aad88f6f4ce6ab8827279cfffb92266 is missing role 0x2561bf26f818282a3be40719542054d2173eb0d38539e8a8d3cff22f29fd2384"
            );
        });

        // TODO: update after withdraw tests
        it("should not be able to withdraw", async () => {
            await expect(
                //when
                stanley.withdraw(BigNumber.from(10))
                //then
            ).to.be.revertedWith(
                "AccessControl: account 0xf39fd6e51aad88f6f4ce6ab8827279cfffb92266 is missing role 0x5d8e12c39142ff96d79d04d15d1ba1269e4fe57bb9d26f43523628b34ba108ec"
            );
        });

        it("should not be able to withdrawAll", async () => {
            await expect(
                //when
                stanley.withdrawAll()
                //then
            ).to.be.revertedWith(
                "AccessControl: account 0xf39fd6e51aad88f6f4ce6ab8827279cfffb92266 is missing role 0x5d8e12c39142ff96d79d04d15d1ba1269e4fe57bb9d26f43523628b34ba108ec"
            );
        });

        it("should not be able to aaveDoClaim", async () => {
            await expect(
                //when
                stanley.aaveDoClaim(await userTwo.getAddress())
                //then
            ).to.be.revertedWith(
                "AccessControl: account 0xf39fd6e51aad88f6f4ce6ab8827279cfffb92266 is missing role 0xf7db13299c8a9e501861f04c20f69a2444829a36a363cfad4b58864709c75560"
            );
        });

        it("should not be able to compoundDoClaim", async () => {
            await expect(
                //when
                stanley.compoundDoClaim(await userTwo.getAddress())
                //then
            ).to.be.revertedWith(
                "AccessControl: account 0xf39fd6e51aad88f6f4ce6ab8827279cfffb92266 is missing role 0xf7db13299c8a9e501861f04c20f69a2444829a36a363cfad4b58864709c75560"
            );
        });

        it("should not be able to aaveBeforeClaim", async () => {
            await expect(
                //when
                stanley.aaveBeforeClaim(
                    [await userTwo.getAddress()],
                    Buffer.from("xxx")
                )
                //then
            ).to.be.revertedWith(
                "AccessControl: account 0xf39fd6e51aad88f6f4ce6ab8827279cfffb92266 is missing role 0xf7db13299c8a9e501861f04c20f69a2444829a36a363cfad4b58864709c75560"
            );
        });
    });
});

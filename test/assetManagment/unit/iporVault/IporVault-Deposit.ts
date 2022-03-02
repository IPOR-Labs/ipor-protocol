import hre, { upgrades } from "hardhat";
import chai from "chai";
const keccak256 = require("keccak256");
import { BigNumber, Signer } from "ethers";

import { solidity } from "ethereum-waffle";
import {
    AaveStrategy,
    CompoundStrategy,
    TestERC20,
    ADAIMock,
    AaveLendingPoolProviderMock,
    AaveLendingPoolCoreMock,
    AaveInterestRateStrategyMockV2,
    AaveStableDebtTokenMock,
    AaveVariableDebtTokenMock,
    AaveLendingPoolMockV2,
    StakedAaveMock,
    AaveIncentivesControllerMock,
    Stanley,
    CDAIMock,
    WhitePaperMock,
    ComptrollerMock,
    IvToken,
} from "../../../../types";

chai.use(solidity);
const { expect } = chai;

describe("Stanley -> Deposit", () => {
    // let wallet: Wallet
    const one: any = BigNumber.from("1000000000000000000");
    const oneRay: any = BigNumber.from("1000000000000000000000000000");
    const maxValue: any = BigNumber.from(
        "115792089237316195423570985008687907853269984665640564039457584007913129639935"
    );
    let admin: Signer, userOne: Signer, userTwo: Signer;

    let stanley: Stanley;
    let DAI: TestERC20;
    let tokenFactory: any;

    let aDAI: ADAIMock;
    let AAVE: TestERC20;
    let aaveNewStartegyInstance: AaveStrategy;
    let lendingPool: AaveLendingPoolMockV2;
    let stakedAave: StakedAaveMock;

    let cDAI: CDAIMock;
    let compoundStartegyInstance: CompoundStrategy;
    let comptroller: ComptrollerMock;
    let COMP: TestERC20;
    let ivToken: IvToken;

    beforeEach(async () => {
        //##############################################################
        //                          Users
        //##############################################################
        [admin, userOne, userTwo] = await hre.ethers.getSigners();

        //##############################################################
        //                          Tokens
        //##############################################################

        tokenFactory = await hre.ethers.getContractFactory("TestERC20");
        DAI = (await tokenFactory.deploy(
            BigNumber.from(2).pow(255)
        )) as TestERC20;

        //##############################################################
        //                        IvToken
        //##############################################################
        const tokenFactoryIvToken = await hre.ethers.getContractFactory(
            "IvToken"
        );
        ivToken = (await tokenFactoryIvToken.deploy(
            "IvToken",
            "IVT",
            DAI.address
        )) as IvToken;

        //##############################################################
        //                        AAVE Mock
        //##############################################################

        const ADAIMockFactory = await hre.ethers.getContractFactory("ADAIMock");
        aDAI = (await ADAIMockFactory.deploy(
            DAI.address,
            await admin.getAddress()
        )) as ADAIMock;
        DAI.mint(aDAI.address, one.mul(10000));
        AAVE = (await tokenFactory.deploy(
            BigNumber.from(2).pow(255)
        )) as TestERC20;
        const stkAAVE = (await tokenFactory.deploy(
            BigNumber.from(2).pow(255)
        )) as TestERC20;
        const aaveLendingPoolProviderMock = await hre.ethers.getContractFactory(
            "AaveLendingPoolProviderMock"
        );
        const aaveLendingPoolCoreMock = await hre.ethers.getContractFactory(
            "AaveLendingPoolCoreMock"
        );
        const aaveInterestRateStrategyMockV2 =
            await hre.ethers.getContractFactory(
                "AaveInterestRateStrategyMockV2"
            );
        const aaveStableDebtTokenMock = await hre.ethers.getContractFactory(
            "AaveStableDebtTokenMock"
        );
        const aaveVariableDebtTokenMock = await hre.ethers.getContractFactory(
            "AaveVariableDebtTokenMock"
        );
        const aaveLendingPoolMock = await hre.ethers.getContractFactory(
            "AaveLendingPoolMockV2"
        );
        const stakedAaveMock = await hre.ethers.getContractFactory(
            "StakedAaveMock"
        );
        const aaveIncentivesControllerMock =
            await hre.ethers.getContractFactory("AaveIncentivesControllerMock");
        const addressProvider =
            (await aaveLendingPoolProviderMock.deploy()) as AaveLendingPoolProviderMock;
        const lendingPoolCore =
            (await aaveLendingPoolCoreMock.deploy()) as AaveLendingPoolCoreMock;
        const interestRateStrategyV2 =
            (await aaveInterestRateStrategyMockV2.deploy()) as AaveInterestRateStrategyMockV2;
        const stableDebtToken = (await aaveStableDebtTokenMock.deploy(
            0,
            0
        )) as AaveStableDebtTokenMock;
        const variableDebtToken = (await aaveVariableDebtTokenMock.deploy(
            0
        )) as AaveVariableDebtTokenMock;
        lendingPool = (await aaveLendingPoolMock.deploy(
            DAI.address,
            aDAI.address
        )) as AaveLendingPoolMockV2;
        stakedAave = (await stakedAaveMock.deploy(
            AAVE.address
        )) as StakedAaveMock;
        const aaveIncentivesController =
            (await aaveIncentivesControllerMock.deploy(
                stakedAave.address
            )) as AaveIncentivesControllerMock;
        await stakedAave.transfer(
            aaveIncentivesController.address,
            one.mul(1000)
        );
        await AAVE.transfer(stakedAave.address, one.mul(1000));
        await addressProvider._setLendingPoolCore(lendingPoolCore.address);
        await addressProvider._setLendingPool(lendingPool.address);
        await lendingPoolCore.setReserve(interestRateStrategyV2.address);
        await lendingPoolCore.setReserveCurrentLiquidityRate(
            oneRay.div("100").mul("2")
        );
        await interestRateStrategyV2.setSupplyRate(oneRay.div("100").mul("2"));
        await interestRateStrategyV2.setBorrowRate(oneRay.div("100").mul("3"));
        await lendingPool.setStableDebtTokenAddress(stableDebtToken.address);
        await lendingPool.setVariableDebtTokenAddress(
            variableDebtToken.address
        );
        await lendingPool.setInterestRateStrategyAddress(
            interestRateStrategyV2.address
        );
        await lendingPool.setCurrentLiquidityRate(oneRay.div("100").mul("2"));
        aDAI.connect(admin).transfer(lendingPool.address, one.mul(1000));
        const aaveNewStartegy = await hre.ethers.getContractFactory(
            "AaveStrategy"
        );
        aaveNewStartegyInstance = (await upgrades.deployProxy(aaveNewStartegy, [
            DAI.address,
            aDAI.address,
            addressProvider.address,
            stakedAave.address,
            aaveIncentivesController.address,
            AAVE.address,
        ])) as AaveStrategy;
        //##############################################################
        //                        Compound Mock
        //##############################################################
        const CDAIMockFactory = await hre.ethers.getContractFactory("CDAIMock");
        COMP = (await tokenFactory.deploy(
            BigNumber.from(2).pow(255)
        )) as TestERC20;
        const whitePaperMock = await hre.ethers.getContractFactory(
            "WhitePaperMock"
        );
        let whitePaperMockInstance =
            (await whitePaperMock.deploy()) as WhitePaperMock;
        cDAI = (await CDAIMockFactory.deploy(
            DAI.address,
            await admin.getAddress(),
            whitePaperMockInstance.address
        )) as CDAIMock;
        DAI.mint(cDAI.address, one.mul(10000));
        const ComptrollerMock = await hre.ethers.getContractFactory(
            "ComptrollerMock"
        );
        comptroller = (await ComptrollerMock.deploy(
            COMP.address,
            cDAI.address
        )) as ComptrollerMock;
        await COMP.transfer(comptroller.address, one.mul(1000));
        const compoundNewStartegy = await hre.ethers.getContractFactory(
            "CompoundStrategy"
        );

        compoundStartegyInstance = (await upgrades.deployProxy(
            compoundNewStartegy,
            [DAI.address, cDAI.address, comptroller.address, COMP.address]
        )) as CompoundStrategy;

        //##############################################################
        //                        Stanley
        //##############################################################
        const Stanley = await hre.ethers.getContractFactory("Stanley");
        stanley = (await await upgrades.deployProxy(Stanley, [
            DAI.address,
            ivToken.address,
            aaveNewStartegyInstance.address,
            compoundStartegyInstance.address,
        ])) as Stanley;
        await stanley.grantRole(
            keccak256("GOVERNANCE_ROLE"),
            await admin.getAddress()
        );
        await aaveNewStartegyInstance.transferOwnership(stanley.address);
        await stanley.confirmTransferOwnership(aaveNewStartegyInstance.address);
        await compoundStartegyInstance.transferOwnership(stanley.address);
        await stanley.confirmTransferOwnership(
            compoundStartegyInstance.address
        );
        await ivToken.setVault(stanley.address);

        //##############################################################
        //                        admin user setup
        //##############################################################
        await DAI.mint(await admin.getAddress(), one.mul(10000));
        await stanley.grantRole(
            keccak256("DEPOSIT_ROLE"),
            await admin.getAddress()
        );
    });

    describe("Mock setup example", () => {
        it("Should change AVE APY", async () => {
            //given
            const apyBefore = await aaveNewStartegyInstance.getApy();
            // when
            await lendingPool.setCurrentLiquidityRate(
                oneRay.div("100").mul("5")
            );
            // then
            const apyAfter = await aaveNewStartegyInstance.getApy();
            expect(apyBefore).to.be.equal(
                BigNumber.from("2000000000000000000")
            );
            expect(apyAfter).to.be.equal(BigNumber.from("5000000000000000000"));
        });

        it("Should change Compound APY", async () => {
            //
            const apyBefore = await compoundStartegyInstance.getApy();
            // when
            await cDAI.setSupplyRate(BigNumber.from("10"));
            // then
            const apyAfter = await compoundStartegyInstance.getApy();
            expect(apyBefore).to.be.equal(
                BigNumber.from("6905953687075200000")
            );
            expect(apyAfter).to.be.equal(BigNumber.from("2102400000"));
        });
    });

    it("Should accept deposit and transfer tokens into AAVE", async () => {
        //given
        const adminAddress = await await admin.getAddress();
        await lendingPool.setCurrentLiquidityRate(oneRay.div("100").mul("10"));
        await DAI.approve(await admin.getAddress(), one.mul(10000));
        await DAI.approve(stanley.address, one.mul(10000));

        //when
        await stanley.deposit(one.mul(10));

        //then

        const aaveBalance = await aaveNewStartegyInstance.balanceOf();
        const userIvToken = await ivToken.balanceOf(adminAddress);
        const balanceOfIporeVault = await DAI.balanceOf(stanley.address);

        expect(aaveBalance).to.be.equal(one.mul(10));
        expect(userIvToken).to.be.equal(one.mul(10));
        expect(balanceOfIporeVault).to.be.equal(BigNumber.from("0"));
    });

    it("Should accept deposit and transfer tokens into Compound", async () => {
        //given
        const adminAddress = await await admin.getAddress();
        await DAI.approve(await admin.getAddress(), one.mul(10000));
        await DAI.approve(stanley.address, one.mul(10000));

        //when
        await stanley.deposit(one.mul(10));

        //then
        const compoundBalance = await compoundStartegyInstance.balanceOf();
        const userIvToken = await ivToken.balanceOf(adminAddress);
        const balanceOfIporeVault = await DAI.balanceOf(stanley.address);

        expect(compoundBalance).to.be.equal(one.mul(10));
        expect(userIvToken).to.be.equal(one.mul(10));
        expect(balanceOfIporeVault).to.be.equal(BigNumber.from("0"));
    });

    it("Should accept deposits and transfer tokens into AAVE 2 times when one user make deposits", async () => {
        const adminAddress = await await admin.getAddress();
        await lendingPool.setCurrentLiquidityRate(oneRay.div("100").mul("10"));
        await DAI.approve(await admin.getAddress(), one.mul(10000));
        await DAI.approve(stanley.address, one.mul(10000));

        //when
        await stanley.deposit(one.mul(10));
        await stanley.deposit(one.mul(10));

        //then

        const aaveBalance = await aaveNewStartegyInstance.balanceOf();
        const userIvToken = await ivToken.balanceOf(adminAddress);
        const balanceOfIporeVault = await DAI.balanceOf(stanley.address);

        expect(aaveBalance).to.be.equal(one.mul(20));
        expect(userIvToken).to.be.equal(one.mul(20));
        expect(balanceOfIporeVault).to.be.equal(BigNumber.from("0"));
    });
    it("Should accept deposits and transfer tokens into Compound 2 times when one user make deposits", async () => {
        //given
        const adminAddress = await await admin.getAddress();
        await DAI.approve(await admin.getAddress(), one.mul(10000));
        await DAI.approve(stanley.address, one.mul(10000));

        //when
        await stanley.deposit(one.mul(10));
        await stanley.deposit(one.mul(10));

        //then
        const compoundBalance = await compoundStartegyInstance.balanceOf();
        const userIvToken = await ivToken.balanceOf(adminAddress);
        const balanceOfIporeVault = await DAI.balanceOf(stanley.address);

        expect(compoundBalance).to.be.equal(one.mul(20));
        expect(userIvToken).to.be.equal(one.mul(20));
        expect(balanceOfIporeVault).to.be.equal(BigNumber.from("0"));
    });
    it("Should accept deposits and transfer tokens first into AAVE second into Compound when one user make deposits", async () => {
        const adminAddress = await await admin.getAddress();
        await lendingPool.setCurrentLiquidityRate(oneRay.div("100").mul("10"));
        await DAI.approve(await admin.getAddress(), one.mul(10000));
        await DAI.approve(stanley.address, one.mul(10000));

        //when
        await stanley.deposit(one.mul(10)); // into aave
        await lendingPool.setCurrentLiquidityRate(oneRay.div("100"));
        await stanley.deposit(one.mul(20)); // into compound

        //then

        const aaveBalance = await aaveNewStartegyInstance.balanceOf();
        const compoundBalance = await compoundStartegyInstance.balanceOf();
        const userIvToken = await ivToken.balanceOf(adminAddress);
        const balanceOfIporeVault = await DAI.balanceOf(stanley.address);

        expect(aaveBalance).to.be.equal(one.mul(10));
        expect(compoundBalance).to.be.equal(one.mul(20));
        expect(userIvToken).to.be.equal(one.mul(30));
        expect(balanceOfIporeVault).to.be.equal(BigNumber.from("0"));
    });
    it("Should accept deposits and transfer tokens first into Compound second into AAVE when one user make deposits", async () => {
        const adminAddress = await await admin.getAddress();
        await DAI.approve(await admin.getAddress(), one.mul(10000));
        await DAI.approve(stanley.address, one.mul(10000));

        //when
        await stanley.deposit(one.mul(10)); // into compound
        await lendingPool.setCurrentLiquidityRate(oneRay.div("100").mul("10"));
        await stanley.deposit(one.mul(20)); // into aave

        //then

        const aaveBalance = await aaveNewStartegyInstance.balanceOf();
        const compoundBalance = await compoundStartegyInstance.balanceOf();
        const userIvToken = await ivToken.balanceOf(adminAddress);
        const balanceOfIporeVault = await DAI.balanceOf(stanley.address);

        expect(aaveBalance).to.be.equal(one.mul(20));
        expect(compoundBalance).to.be.equal(one.mul(10));
        expect(userIvToken).to.be.equal(one.mul(30));
        expect(balanceOfIporeVault).to.be.equal(BigNumber.from("0"));
    });

    it("Should 2 diffrent user deposit into aave", async () => {
        // given
        await stanley.grantRole(
            keccak256("DEPOSIT_ROLE"),
            await userOne.getAddress()
        );
        await stanley.grantRole(
            keccak256("DEPOSIT_ROLE"),
            await userTwo.getAddress()
        );
        await DAI.mint(await userOne.getAddress(), one.mul(10000));
        await DAI.mint(await userTwo.getAddress(), one.mul(10000));
        await DAI.connect(userOne).approve(stanley.address, one.mul(10000));
        await DAI.connect(userTwo).approve(stanley.address, one.mul(10000));

        await lendingPool.setCurrentLiquidityRate(oneRay.div("100").mul("10"));

        //when
        await stanley.connect(userOne).deposit(one.mul(10));
        await stanley.connect(userTwo).deposit(one.mul(20));

        //then

        const aaveBalance = await aaveNewStartegyInstance.balanceOf();
        const userOneIvToken = await ivToken.balanceOf(
            await userOne.getAddress()
        );
        const userTwoIvToken = await ivToken.balanceOf(
            await userTwo.getAddress()
        );
        const balanceOfIporeVault = await DAI.balanceOf(stanley.address);

        expect(aaveBalance).to.be.equal(one.mul(30));
        expect(userOneIvToken).to.be.equal(one.mul(10));
        expect(userTwoIvToken).to.be.equal(one.mul(20));
        expect(balanceOfIporeVault).to.be.equal(BigNumber.from("0"));
    });
    it("Should 2 diffrent user deposit into compound", async () => {
        // given
        await stanley.grantRole(
            keccak256("DEPOSIT_ROLE"),
            await userOne.getAddress()
        );
        await stanley.grantRole(
            keccak256("DEPOSIT_ROLE"),
            await userTwo.getAddress()
        );
        await DAI.mint(await userOne.getAddress(), one.mul(10000));
        await DAI.mint(await userTwo.getAddress(), one.mul(10000));
        await DAI.connect(userOne).approve(stanley.address, one.mul(10000));
        await DAI.connect(userTwo).approve(stanley.address, one.mul(10000));

        //when
        await stanley.connect(userOne).deposit(one.mul(10));
        await stanley.connect(userTwo).deposit(one.mul(20));

        //then
        const compoundBalance = await compoundStartegyInstance.balanceOf();
        const userOneIvToken = await ivToken.balanceOf(
            await userOne.getAddress()
        );
        const userTwoIvToken = await ivToken.balanceOf(
            await userTwo.getAddress()
        );
        const balanceOfIporeVault = await DAI.balanceOf(stanley.address);

        expect(compoundBalance).to.be.equal(one.mul(30));
        expect(userOneIvToken).to.be.equal(one.mul(10));
        expect(userTwoIvToken).to.be.equal(one.mul(20));
        expect(balanceOfIporeVault).to.be.equal(BigNumber.from("0"));
    });
    it("Should first user deposit into compound second into aave", async () => {
        // given
        await stanley.grantRole(
            keccak256("DEPOSIT_ROLE"),
            await userOne.getAddress()
        );
        await stanley.grantRole(
            keccak256("DEPOSIT_ROLE"),
            await userTwo.getAddress()
        );
        await DAI.mint(await userOne.getAddress(), one.mul(10000));
        await DAI.mint(await userTwo.getAddress(), one.mul(10000));
        await DAI.connect(userOne).approve(stanley.address, one.mul(10000));
        await DAI.connect(userTwo).approve(stanley.address, one.mul(10000));

        //when
        await stanley.connect(userOne).deposit(one.mul(10));
        await lendingPool.setCurrentLiquidityRate(oneRay.div("100").mul("10"));
        await stanley.connect(userTwo).deposit(one.mul(20));

        //then
        const compoundBalance = await compoundStartegyInstance.balanceOf();
        const aaveBalance = await aaveNewStartegyInstance.balanceOf();
        const userOneIvToken = await ivToken.balanceOf(
            await userOne.getAddress()
        );
        const userTwoIvToken = await ivToken.balanceOf(
            await userTwo.getAddress()
        );
        const balanceOfIporeVault = await DAI.balanceOf(stanley.address);

        expect(compoundBalance).to.be.equal(one.mul(10));
        expect(aaveBalance).to.be.equal(one.mul(20));
        expect(userOneIvToken).to.be.equal(one.mul(10));
        expect(userTwoIvToken).to.be.equal(one.mul(20));
        expect(balanceOfIporeVault).to.be.equal(BigNumber.from("0"));
    });

    it("Should not deposit when user has no DEPOSIT_ROLE", async () => {
        // given

        await DAI.mint(await userOne.getAddress(), one.mul(10000));
        await DAI.connect(userOne).approve(stanley.address, one.mul(10000));

        //when
        await expect(
            stanley.connect(userOne).deposit(one.mul(10))
        ).to.be.revertedWith(
            "AccessControl: account 0x70997970c51812dc3a010c7d01b50e0d17dc79c8 is missing role 0x2561bf26f818282a3be40719542054d2173eb0d38539e8a8d3cff22f29fd2384"
        );
    });

    it("Should not deposit when user try deposit 0", async () => {
        // given
        await stanley.grantRole(
            keccak256("DEPOSIT_ROLE"),
            await userOne.getAddress()
        );

        await DAI.mint(await userOne.getAddress(), one.mul(10000));
        await DAI.connect(userOne).approve(stanley.address, one.mul(10000));

        //when
        await expect(
            stanley.connect(userOne).deposit(BigNumber.from("0"))
        ).to.be.revertedWith("IPOR_103");
    });
});

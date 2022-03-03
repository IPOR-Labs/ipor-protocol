import hre, { upgrades } from "hardhat";
import chai from "chai";
const keccak256 = require("keccak256");
import { BigNumber, Signer } from "ethers";

import { solidity } from "ethereum-waffle";
import {
    AaveStrategy,
    CompoundStrategy,
    TestERC20,
    MockADAI,
    MockAaveLendingPoolProvider,
    MockAaveLendingPoolCore,
    AaveInterestRateMockStrategyV2,
    MockAaveStableDebtToken,
    MockAaveVariableDebtToken,
    MockAaveLendingPoolV2,
    MockStakedAave,
    MockAaveIncentivesController,
    Stanley,
    MockCDAI,
    MockWhitePaper,
    MockComptroller,
    IvToken,
} from "../../../../types";

chai.use(solidity);
const { expect } = chai;

describe("Stanley -> Withdraw", () => {
    // let wallet: Wallet
    const one: any = BigNumber.from("1000000000000000000");
    const oneRay: any = BigNumber.from("1000000000000000000000000000");

    let admin: Signer, userOne: Signer, userTwo: Signer;

    let stanley: Stanley;
    let DAI: TestERC20;
    let tokenFactory: any;

    let aDAI: MockADAI;
    let AAVE: TestERC20;
    let aaveNewStartegyInstance: AaveStrategy;
    let lendingPool: MockAaveLendingPoolV2;
    let stakedAave: MockStakedAave;

    let cDAI: MockCDAI;
    let compoundStartegyInstance: CompoundStrategy;
    let comptroller: MockComptroller;
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

        const MockADAIFactory = await hre.ethers.getContractFactory("MockADAI");
        aDAI = (await MockADAIFactory.deploy(
            DAI.address,
            await admin.getAddress()
        )) as MockADAI;
        DAI.mint(aDAI.address, one.mul(10000));
        AAVE = (await tokenFactory.deploy(
            BigNumber.from(2).pow(255)
        )) as TestERC20;
        const stkAAVE = (await tokenFactory.deploy(
            BigNumber.from(2).pow(255)
        )) as TestERC20;
        const MockAaveLendingPoolProvider = await hre.ethers.getContractFactory(
            "MockAaveLendingPoolProvider"
        );
        const MockAaveLendingPoolCore = await hre.ethers.getContractFactory(
            "MockAaveLendingPoolCore"
        );
        const aaveInterestRateMockStrategyV2 =
            await hre.ethers.getContractFactory(
                "AaveInterestRateMockStrategyV2"
            );
        const MockAaveStableDebtToken = await hre.ethers.getContractFactory(
            "MockAaveStableDebtToken"
        );
        const MockAaveVariableDebtToken = await hre.ethers.getContractFactory(
            "MockAaveVariableDebtToken"
        );
        const MockAaveLendingPool = await hre.ethers.getContractFactory(
            "MockAaveLendingPoolV2"
        );
        const MockStakedAave = await hre.ethers.getContractFactory(
            "MockStakedAave"
        );
        const MockAaveIncentivesController =
            await hre.ethers.getContractFactory("MockAaveIncentivesController");
        const addressProvider =
            (await MockAaveLendingPoolProvider.deploy()) as MockAaveLendingPoolProvider;
        const lendingPoolCore =
            (await MockAaveLendingPoolCore.deploy()) as MockAaveLendingPoolCore;
        const interestRateStrategyV2 =
            (await aaveInterestRateMockStrategyV2.deploy()) as AaveInterestRateMockStrategyV2;
        const stableDebtToken = (await MockAaveStableDebtToken.deploy(
            0,
            0
        )) as MockAaveStableDebtToken;
        const variableDebtToken = (await MockAaveVariableDebtToken.deploy(
            0
        )) as MockAaveVariableDebtToken;
        lendingPool = (await MockAaveLendingPool.deploy(
            DAI.address,
            aDAI.address
        )) as MockAaveLendingPoolV2;
        stakedAave = (await MockStakedAave.deploy(
            AAVE.address
        )) as MockStakedAave;
        const aaveIncentivesController =
            (await MockAaveIncentivesController.deploy(
                stakedAave.address
            )) as MockAaveIncentivesController;
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
        const MockCDAIFactory = await hre.ethers.getContractFactory("MockCDAI");
        COMP = (await tokenFactory.deploy(
            BigNumber.from(2).pow(255)
        )) as TestERC20;
        const MockWhitePaper = await hre.ethers.getContractFactory(
            "MockWhitePaper"
        );
        let MockWhitePaperInstance =
            (await MockWhitePaper.deploy()) as MockWhitePaper;
        cDAI = (await MockCDAIFactory.deploy(
            DAI.address,
            await admin.getAddress(),
            MockWhitePaperInstance.address
        )) as MockCDAI;
        DAI.mint(cDAI.address, one.mul(10000));
        const MockComptroller = await hre.ethers.getContractFactory(
            "MockComptroller"
        );
        comptroller = (await MockComptroller.deploy(
            COMP.address,
            cDAI.address
        )) as MockComptroller;
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
        const StanleyFactory = await hre.ethers.getContractFactory("Stanley");
        stanley = (await await upgrades.deployProxy(StanleyFactory, [
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
        await ivToken.setStanley(stanley.address);

        //##############################################################
        //                        admin user setup
        //##############################################################
        await DAI.mint(await admin.getAddress(), one.mul(10000));
        await stanley.grantRole(
            keccak256("DEPOSIT_ROLE"),
            await admin.getAddress()
        );
        await stanley.grantRole(
            keccak256("WITHDRAW_ROLE"),
            await admin.getAddress()
        );
    });

    it("Should withdraw from AAVE when only AAVE has funds and AAVE has max APY", async () => {
        //given
        const adminAddress = await await admin.getAddress();
        await lendingPool.setCurrentLiquidityRate(oneRay.div("100").mul("10"));
        await DAI.approve(await admin.getAddress(), one.mul(10000));
        await DAI.approve(stanley.address, one.mul(10000));
        await stanley.deposit(one.mul(10));
        const aaveBalanceBefore = await aaveNewStartegyInstance.balanceOf();
        const userIvTokenBefore = await ivToken.balanceOf(adminAddress);
        expect(aaveBalanceBefore).to.be.equal(one.mul(10));
        expect(userIvTokenBefore).to.be.equal(one.mul(10));
        //when

        await stanley.withdraw(one.mul(10));
        //then
        const aaveBalanceAfter = await aaveNewStartegyInstance.balanceOf();
        const userIvTokenAfter = await ivToken.balanceOf(adminAddress);
        const balanceOfIporeVault = await DAI.balanceOf(stanley.address);

        expect(aaveBalanceAfter).to.be.equal(BigNumber.from("0"));
        expect(userIvTokenAfter).to.be.equal(BigNumber.from("0"));
        expect(balanceOfIporeVault).to.be.equal(BigNumber.from("0"));
    });

    it("Should withdraw from AAVE when only AAVE has funds and AAVE hasn't max APY", async () => {
        //given
        const adminAddress = await await admin.getAddress();
        await lendingPool.setCurrentLiquidityRate(oneRay.div("100").mul("10"));
        await DAI.approve(await admin.getAddress(), one.mul(10000));
        await DAI.approve(stanley.address, one.mul(10000));
        await stanley.deposit(one.mul(10));
        const aaveBalanceBefore = await aaveNewStartegyInstance.balanceOf();
        const userIvTokenBefore = await ivToken.balanceOf(adminAddress);
        expect(aaveBalanceBefore).to.be.equal(one.mul(10));
        expect(userIvTokenBefore).to.be.equal(one.mul(10));
        await lendingPool.setCurrentLiquidityRate(oneRay.div("1000"));
        //when

        await stanley.withdraw(one.mul(10));
        //then
        const aaveBalanceAfter = await aaveNewStartegyInstance.balanceOf();
        const userIvTokenAfter = await ivToken.balanceOf(adminAddress);
        const balanceOfIporeVault = await DAI.balanceOf(stanley.address);

        expect(aaveBalanceAfter).to.be.equal(BigNumber.from("0"));
        expect(userIvTokenAfter).to.be.equal(BigNumber.from("0"));
        expect(balanceOfIporeVault).to.be.equal(BigNumber.from("0"));
    });

    it("Should withdraw part of funds from AAVE when only AAVE has funds and AAVE has max APY", async () => {
        //given
        const adminAddress = await await admin.getAddress();
        await lendingPool.setCurrentLiquidityRate(oneRay.div("100").mul("10"));
        await DAI.approve(await admin.getAddress(), one.mul(10000));
        await DAI.approve(stanley.address, one.mul(10000));
        await stanley.deposit(one.mul(10));
        const aaveBalanceBefore = await aaveNewStartegyInstance.balanceOf();
        const userIvTokenBefore = await ivToken.balanceOf(adminAddress);
        expect(aaveBalanceBefore).to.be.equal(one.mul(10));
        expect(userIvTokenBefore).to.be.equal(one.mul(10));
        //when

        await stanley.withdraw(one.mul(6));
        //then
        const aaveBalanceAfter = await aaveNewStartegyInstance.balanceOf();
        const userIvTokenAfter = await ivToken.balanceOf(adminAddress);
        const balanceOfIporeVault = await DAI.balanceOf(stanley.address);
        expect(aaveBalanceAfter).to.be.equal(one.mul(4));
        expect(userIvTokenAfter).to.be.equal(one.mul(4));
        expect(balanceOfIporeVault).to.be.equal(BigNumber.from("0"));
    });

    it("Should withdraw from AAVE when only AAVE has funds and AAVE hasn't max APY", async () => {
        //given
        const adminAddress = await await admin.getAddress();
        await lendingPool.setCurrentLiquidityRate(oneRay.div("100").mul("10"));
        await DAI.approve(await admin.getAddress(), one.mul(10000));
        await DAI.approve(stanley.address, one.mul(10000));
        await stanley.deposit(one.mul(10));
        const aaveBalanceBefore = await aaveNewStartegyInstance.balanceOf();
        const userIvTokenBefore = await ivToken.balanceOf(adminAddress);
        expect(aaveBalanceBefore).to.be.equal(one.mul(10));
        expect(userIvTokenBefore).to.be.equal(one.mul(10));
        await lendingPool.setCurrentLiquidityRate(oneRay.div("1000"));
        //when

        await stanley.withdraw(one.mul(7));
        //then
        const aaveBalanceAfter = await aaveNewStartegyInstance.balanceOf();
        const userIvTokenAfter = await ivToken.balanceOf(adminAddress);
        const balanceOfIporeVault = await DAI.balanceOf(stanley.address);

        expect(aaveBalanceAfter).to.be.equal(one.mul(3));
        expect(userIvTokenAfter).to.be.equal(one.mul(3));
        expect(balanceOfIporeVault).to.be.equal(BigNumber.from("0"));
    });

    it("Should withdraw from COMPOUND when only COMPOUND has funds and COMPOUND has max APY", async () => {
        //given
        const adminAddress = await await admin.getAddress();
        await DAI.approve(await admin.getAddress(), one.mul(10000));
        await DAI.approve(stanley.address, one.mul(10000));
        await stanley.deposit(one.mul(10));
        const compoundBalanceBefore =
            await compoundStartegyInstance.balanceOf();
        const userIvTokenBefore = await ivToken.balanceOf(adminAddress);
        expect(compoundBalanceBefore).to.be.equal(one.mul(10));
        expect(userIvTokenBefore).to.be.equal(one.mul(10));

        //when
        await stanley.withdraw(one.mul(10));
        //then
        const compoundBalanceAfter = await compoundStartegyInstance.balanceOf();
        const userIvTokenAfter = await ivToken.balanceOf(adminAddress);
        const balanceOfIporeVault = await DAI.balanceOf(stanley.address);

        expect(compoundBalanceAfter).to.be.equal(BigNumber.from("0"));
        expect(userIvTokenAfter).to.be.equal(BigNumber.from("0"));
        expect(balanceOfIporeVault).to.be.equal(BigNumber.from("0"));
    });

    it("Should withdraw from COMPOUND when only COMPOUND has funds and COMPOUND hasn't max APY", async () => {
        //given
        const adminAddress = await await admin.getAddress();
        await DAI.approve(await admin.getAddress(), one.mul(10000));
        await DAI.approve(stanley.address, one.mul(10000));
        await stanley.deposit(one.mul(10));
        const compoundBalanceBefore =
            await compoundStartegyInstance.balanceOf();
        const userIvTokenBefore = await ivToken.balanceOf(adminAddress);
        expect(compoundBalanceBefore).to.be.equal(one.mul(10));
        expect(userIvTokenBefore).to.be.equal(one.mul(10));
        await lendingPool.setCurrentLiquidityRate(oneRay.div("100").mul("10"));
        //when

        await stanley.withdraw(one.mul(10));
        //then
        const compoundBalanceAfter = await compoundStartegyInstance.balanceOf();
        const userIvTokenAfter = await ivToken.balanceOf(adminAddress);
        const balanceOfIporeVault = await DAI.balanceOf(stanley.address);

        expect(compoundBalanceAfter).to.be.equal(BigNumber.from("0"));
        expect(userIvTokenAfter).to.be.equal(BigNumber.from("0"));
        expect(balanceOfIporeVault).to.be.equal(BigNumber.from("0"));
    });

    it("Should withdraw part of funds from COMPOUND when only COMPOUND has funds and COMPOUND has max APY", async () => {
        //given
        const adminAddress = await await admin.getAddress();
        await DAI.approve(await admin.getAddress(), one.mul(10000));
        await DAI.approve(stanley.address, one.mul(10000));
        await stanley.deposit(one.mul(10));
        const compoundBalanceBefore =
            await compoundStartegyInstance.balanceOf();
        const userIvTokenBefore = await ivToken.balanceOf(adminAddress);
        expect(compoundBalanceBefore).to.be.equal(one.mul(10));
        expect(userIvTokenBefore).to.be.equal(one.mul(10));
        //when

        await stanley.withdraw(one.mul(6));
        //then
        const compoundBalanceAfter = await compoundStartegyInstance.balanceOf();
        const userIvTokenAfter = await ivToken.balanceOf(adminAddress);
        const balanceOfIporeVault = await DAI.balanceOf(stanley.address);
        expect(compoundBalanceAfter).to.be.equal(one.mul(4));
        expect(userIvTokenAfter).to.be.equal(one.mul(4));
        expect(balanceOfIporeVault).to.be.equal(BigNumber.from("0"));
    });

    it("Should withdraw from COMPOUND when only COMPOUND has funds and COMPOUND hasn't max APY2", async () => {
        //given
        const adminAddress = await await admin.getAddress();
        await DAI.approve(await admin.getAddress(), one.mul(10000));
        await DAI.approve(stanley.address, one.mul(10000));
        await stanley.deposit(one.mul(10));
        const compoundBalanceBefore =
            await compoundStartegyInstance.balanceOf();
        const userIvTokenBefore = await ivToken.balanceOf(adminAddress);
        expect(compoundBalanceBefore).to.be.equal(one.mul(10));
        expect(userIvTokenBefore).to.be.equal(one.mul(10));
        await lendingPool.setCurrentLiquidityRate(oneRay.div("100").mul("10"));
        //when

        await stanley.withdraw(one.mul(7));
        //then
        const compoundBalanceAfter = await compoundStartegyInstance.balanceOf();
        const userIvTokenAfter = await ivToken.balanceOf(adminAddress);
        const balanceOfIporeVault = await DAI.balanceOf(stanley.address);

        expect(compoundBalanceAfter).to.be.equal(one.mul(3));
        expect(userIvTokenAfter).to.be.equal(one.mul(3));
        expect(balanceOfIporeVault).to.be.equal(BigNumber.from("0"));
    });

    it("Should withdrow from AAVE when deposit to both but COMPOUND has max APY", async () => {
        const adminAddress = await await admin.getAddress();
        await lendingPool.setCurrentLiquidityRate(oneRay.div("100").mul("10"));
        await DAI.approve(await admin.getAddress(), one.mul(10000));
        await DAI.approve(stanley.address, one.mul(10000));
        await stanley.deposit(one.mul(10));
        const aaveBalanceBefore = await aaveNewStartegyInstance.balanceOf();
        expect(aaveBalanceBefore).to.be.equal(one.mul(10));

        await lendingPool.setCurrentLiquidityRate(oneRay.div("100"));

        await stanley.deposit(one.mul(20));
        const compoundBalanceBefore =
            await compoundStartegyInstance.balanceOf();
        const userIvTokenBefore = await ivToken.balanceOf(adminAddress);
        expect(compoundBalanceBefore).to.be.equal(one.mul(20));
        expect(userIvTokenBefore).to.be.equal(one.mul(30));
        //when

        await stanley.withdraw(one.mul(10));
        //then
        const aaveBalanceAfter = await aaveNewStartegyInstance.balanceOf();
        const userIvTokenAfter = await ivToken.balanceOf(adminAddress);
        const balanceOfIporeVault = await DAI.balanceOf(stanley.address);

        expect(aaveBalanceAfter).to.be.equal(BigNumber.from("0"));
        expect(userIvTokenAfter).to.be.equal(one.mul(20));
        expect(balanceOfIporeVault).to.be.equal(BigNumber.from("0"));
    });
    it("Should withdraw from COMPOUND when deposit to both but COMPOUND has max APY but in AAVE has less balanse", async () => {
        const adminAddress = await await admin.getAddress();
        await lendingPool.setCurrentLiquidityRate(oneRay.div("100").mul("10"));
        await DAI.approve(await admin.getAddress(), one.mul(10000));
        await DAI.approve(stanley.address, one.mul(10000));
        await stanley.deposit(one.mul(10));
        const aaveBalanceBefore = await aaveNewStartegyInstance.balanceOf();
        expect(aaveBalanceBefore).to.be.equal(one.mul(10));

        // decrise aave APY
        await lendingPool.setCurrentLiquidityRate(oneRay.div("100"));

        await stanley.deposit(one.mul(20));
        const compoundBalanceBefore =
            await compoundStartegyInstance.balanceOf();
        const userIvTokenBefore = await ivToken.balanceOf(adminAddress);
        expect(compoundBalanceBefore).to.be.equal(one.mul(20));
        expect(userIvTokenBefore).to.be.equal(one.mul(30));
        //when

        await stanley.withdraw(one.mul(15));
        //then
        const compoundBalanceAfter = await compoundStartegyInstance.balanceOf();
        const userIvTokenAfter = await ivToken.balanceOf(adminAddress);
        const balanceOfIporeVault = await DAI.balanceOf(stanley.address);

        expect(compoundBalanceAfter).to.be.equal(one.mul(5));
        expect(userIvTokenAfter).to.be.equal(one.mul(15));
        expect(balanceOfIporeVault).to.be.equal(BigNumber.from("0"));
    });

    it("Should withdrow from COMPOUND when deposit to both but AAVE has max APY", async () => {
        await DAI.approve(await admin.getAddress(), one.mul(10000));
        await DAI.approve(stanley.address, one.mul(10000));

        const adminAddress = await await admin.getAddress();
        await stanley.deposit(one.mul(20));
        const compoundBalanceBefore =
            await compoundStartegyInstance.balanceOf();
        expect(compoundBalanceBefore).to.be.equal(one.mul(20));

        await lendingPool.setCurrentLiquidityRate(oneRay.div("100").mul("10"));
        await stanley.deposit(one.mul(10));
        const aaveBalanceBefore = await aaveNewStartegyInstance.balanceOf();
        const userIvTokenBefore = await ivToken.balanceOf(adminAddress);
        expect(aaveBalanceBefore).to.be.equal(one.mul(10));
        expect(userIvTokenBefore).to.be.equal(one.mul(30));

        //when

        await stanley.withdraw(one.mul(10));
        //then
        const compoundBalanceAfter = await compoundStartegyInstance.balanceOf();
        const userIvTokenAfter = await ivToken.balanceOf(adminAddress);
        const balanceOfIporeVault = await DAI.balanceOf(stanley.address);

        expect(compoundBalanceAfter).to.be.equal(one.mul(10));
        expect(userIvTokenAfter).to.be.equal(one.mul(20));
        expect(balanceOfIporeVault).to.be.equal(BigNumber.from("0"));
    });
    it("Should withdrow from AAVE when deposit to both but AAVE has max APY but in COMPOUND has less balanse", async () => {
        const adminAddress = await await admin.getAddress();
        await lendingPool.setCurrentLiquidityRate(oneRay.div("100").mul("10"));
        await DAI.approve(await admin.getAddress(), one.mul(10000));
        await DAI.approve(stanley.address, one.mul(10000));
        await stanley.deposit(one.mul(40));
        const aaveBalanceBefore = await aaveNewStartegyInstance.balanceOf();
        expect(aaveBalanceBefore).to.be.equal(one.mul(40));

        await lendingPool.setCurrentLiquidityRate(oneRay.div("100"));

        await stanley.deposit(one.mul(20));
        const compoundBalanceBefore =
            await compoundStartegyInstance.balanceOf();
        const userIvTokenBefore = await ivToken.balanceOf(adminAddress);
        expect(compoundBalanceBefore).to.be.equal(one.mul(20));
        expect(userIvTokenBefore).to.be.equal(one.mul(60));

        await lendingPool.setCurrentLiquidityRate(oneRay.div("100").mul("10"));
        //when

        await stanley.withdraw(one.mul(25));
        //then
        const aaveBalanceAfter = await aaveNewStartegyInstance.balanceOf();
        const userIvTokenAfter = await ivToken.balanceOf(adminAddress);
        const balanceOfIporeVault = await DAI.balanceOf(stanley.address);

        expect(aaveBalanceAfter).to.be.equal(one.mul(15));
        expect(userIvTokenAfter).to.be.equal(one.mul(35));
        expect(balanceOfIporeVault).to.be.equal(BigNumber.from("0"));
    });

    it("Should not withdraw when has less tokens", async () => {
        //given
        const adminAddress = await await admin.getAddress();
        await lendingPool.setCurrentLiquidityRate(oneRay.div("100").mul("10"));
        await DAI.approve(await admin.getAddress(), one.mul(10000));
        await DAI.approve(stanley.address, one.mul(10000));
        await stanley.deposit(one.mul(10));
        const aaveBalanceBefore = await aaveNewStartegyInstance.balanceOf();
        const userIvTokenBefore = await ivToken.balanceOf(adminAddress);
        expect(aaveBalanceBefore).to.be.equal(one.mul(10));
        expect(userIvTokenBefore).to.be.equal(one.mul(10));
        //when

        await expect(stanley.withdraw(one.mul(20))).to.be.revertedWith(
            "IPOR_103"
        );
    });
});

import { expect } from "chai";
import { BigNumber, Signer } from "ethers";
const usdcAbi = require("../../abis/usdcAbi.json");
const comptrollerAbi = require("../../abis/comptroller.json");
import hre, { upgrades } from "hardhat";

const ZERO = BigNumber.from("0");
const ONE_18 = BigNumber.from("1000000000000000000");
const ONE_12 = BigNumber.from("1000000000000");
const ONE_6 = BigNumber.from("1000000");
const maxValue = BigNumber.from(
    "115792089237316195423570985008687907853269984665640564039457584007913129639935"
);

import {
    StrategyCompound,
    StanleyUsdc,
    IvToken,
    ERC20,
    IAaveIncentivesController,
    MockStrategy,
} from "../../types";

// // Mainnet Fork and test case for mainnet with hardhat network by impersonate account from mainnet
// work for blockNumber: 14222087,
describe("Deposit -> deployed Contract on Mainnet fork  Compound USDC", function () {
    let accounts: Signer[];
    let accountToImpersonate: string;
    let usdcAddress: string;
    let usdcContract: ERC20;
    let strategyAaveContract_Instance: MockStrategy;
    let signer: Signer;
    let cUsdcAddress: string;
    let COMP: string;
    let compContract: ERC20;
    let cTokenContract: ERC20;
    let ComptrollerAddress: string;
    let compTrollerContract: any;
    let strategyCompoundContractInstance: StrategyCompound;
    let ivToken: IvToken;
    let stanley: StanleyUsdc;

    if (process.env.FORK_ENABLED != "true") {
        return;
    }

    before(async () => {
        accounts = await hre.ethers.getSigners();

        //  ********************************************************************************************
        //  **************                     GENERAL                                    **************
        //  ********************************************************************************************

        accountToImpersonate = "0xa191e578a6736167326d05c119ce0c90849e84b7"; // Usdc rich address
        usdcAddress = "0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48"; // usdc

        await hre.network.provider.send("hardhat_setBalance", [
            accountToImpersonate,
            "0x100000000000000000000",
        ]);

        await hre.network.provider.request({
            method: "hardhat_impersonateAccount",
            params: [accountToImpersonate],
        });

        signer = await hre.ethers.provider.getSigner(accountToImpersonate);
        usdcContract = new hre.ethers.Contract(usdcAddress, usdcAbi, signer) as ERC20;
        const impersonateBalanceBefore = await usdcContract.balanceOf(accountToImpersonate);
        await usdcContract.transfer(await accounts[0].getAddress(), impersonateBalanceBefore);
        signer = await hre.ethers.provider.getSigner(await accounts[0].getAddress());
        usdcContract = new hre.ethers.Contract(usdcAddress, usdcAbi, signer) as ERC20;

        //  ********************************************************************************************
        //  **************                         AAVE                                   **************
        //  *******************************************************************************************

        // we mock aave bacoude we want compand APR > aave APR
        const StrategyAave = await hre.ethers.getContractFactory("MockStrategy");
        strategyAaveContract_Instance = (await StrategyAave.deploy()) as MockStrategy;

        await strategyAaveContract_Instance.setShareToken(usdcAddress);
        await strategyAaveContract_Instance.setAsset(usdcAddress);

        //  ********************************************************************************************
        //  **************                       COMPOUND                                 **************
        //  ********************************************************************************************

        cUsdcAddress = "0x39AA39c021dfbaE8faC545936693aC917d5E7563";
        COMP = "0xc00e94Cb662C3520282E6f5717214004A7f26888";
        ComptrollerAddress = "0x3d9819210A31b4961b30EF54bE2aeD79B9c9Cd3B";

        signer = await hre.ethers.provider.getSigner(accountToImpersonate);
        compContract = new hre.ethers.Contract(COMP, usdcAbi, signer) as ERC20;
        cTokenContract = new hre.ethers.Contract(cUsdcAddress, usdcAbi, signer) as ERC20;
        signer = await hre.ethers.provider.getSigner(await accounts[0].getAddress());

        const strategyCompoundContract = await hre.ethers.getContractFactory(
            "StrategyCompound",
            signer
        );

        strategyCompoundContractInstance = (await upgrades.deployProxy(strategyCompoundContract, [
            usdcAddress,
            cUsdcAddress,
            ComptrollerAddress,
            COMP,
        ])) as StrategyCompound;

        compTrollerContract = new hre.ethers.Contract(ComptrollerAddress, comptrollerAbi, signer);

        //  ********************************************************************************************
        //  **************                        IvToken                                 **************
        //  ********************************************************************************************

        const tokenFactoryIvToken = await hre.ethers.getContractFactory("IvToken", signer);
        ivToken = (await tokenFactoryIvToken.deploy("IvToken", "IVT", usdcAddress)) as IvToken;

        //  ********************************************************************************************
        //  **************                       Stanley                                **************
        //  ********************************************************************************************
        const StanleyFactory = await hre.ethers.getContractFactory("StanleyUsdc", signer);

        stanley = (await upgrades.deployProxy(StanleyFactory, [
            usdcAddress,
            ivToken.address,
            strategyAaveContract_Instance.address,
            strategyCompoundContractInstance.address,
        ])) as StanleyUsdc;

        await stanley.setMilton(await signer.getAddress());
        await strategyCompoundContractInstance.setStanley(stanley.address);
        await strategyCompoundContractInstance.setTreasury(await signer.getAddress());

        await usdcContract.approve(await signer.getAddress(), maxValue);
        await usdcContract.approve(stanley.address, maxValue);
        await ivToken.setStanley(stanley.address);
    });

    it("Should Compound APR > Aave APR ", async () => {
        // when
        const aaveApy = await strategyAaveContract_Instance.getApr();
        const compoundApy = await strategyCompoundContractInstance.getApr();
        // then
        expect(compoundApy.gt(aaveApy)).to.be.true;
    });

    it("Should accept deposit and transfer tokens into COMPOUND", async () => {
        //given
        const depositAmount = ONE_18.mul(10);
        const userAddress = await signer.getAddress();
        const userIvTokenBefore = await ivToken.balanceOf(userAddress);
        const strategyCompoundBalanceBefore = await strategyCompoundContractInstance.balanceOf();
        const userUsdcBalanceBefore = await usdcContract.balanceOf(userAddress);
        const strategyCTokenContractBefore = await cTokenContract.balanceOf(
            strategyCompoundContractInstance.address
        );

        expect(userIvTokenBefore, "userIvTokenBefore = 0").to.be.equal(ZERO);
        expect(strategyCompoundBalanceBefore, "strategyCompoundBalanceBefore = 0").to.be.equal(
            ZERO
        );

        //When
        await stanley.connect(signer).deposit(depositAmount);

        //Then
        const userIvTokenAfter = await ivToken.balanceOf(userAddress);
        const strategyCompoundBalanceAfter = await strategyCompoundContractInstance.balanceOf();
        const userUsdcBalanceAfter = await usdcContract.balanceOf(userAddress);
        const strategyCTokenContractAfter = await cTokenContract.balanceOf(
            strategyCompoundContractInstance.address
        );

        expect(userIvTokenAfter, "userIvTokenAfter = depositAmount").to.be.equal(depositAmount);
        expect(
            strategyCompoundBalanceAfter.gt(strategyCompoundBalanceBefore),
            "strategyCompoundBalanceAfter > strategyCompoundBalanceBefore"
        ).to.be.true;
        expect(
            userUsdcBalanceAfter.lt(userUsdcBalanceBefore),
            "userUsdcBalanceAfter < userUsdcBalanceBefore"
        ).to.be.true;
        expect(
            strategyCTokenContractAfter.gt(strategyCTokenContractBefore),
            "strategyATokenContractAfter > strategyCTokenContractBefore"
        ).to.be.true;
    });

    it("Should accept deposit twice and transfer tokens into COMPOUND", async () => {
        //given
        const depositAmount = ONE_18.mul(10);
        const userAddress = await signer.getAddress();
        const userIvTokenBefore = await ivToken.balanceOf(userAddress);
        const strategyCompoundBalanceBefore = await strategyCompoundContractInstance.balanceOf();
        const userUsdcBalanceBefore = await usdcContract.balanceOf(userAddress);
        const strategyCTokenContractBefore = await cTokenContract.balanceOf(
            strategyCompoundContractInstance.address
        );

        //When
        await stanley.connect(signer).deposit(depositAmount);
        await stanley.connect(signer).deposit(depositAmount);
        //Then
        const userIvTokenAfter = await ivToken.balanceOf(userAddress);
        const strategyCompoundBalanceAfter = await strategyCompoundContractInstance.balanceOf();
        const userUsdcBalanceAfter = await usdcContract.balanceOf(userAddress);
        const strategyCTokenContractAfter = await cTokenContract.balanceOf(
            strategyCompoundContractInstance.address
        );

        expect(userIvTokenAfter.gt(userIvTokenBefore), "ivToken > userIvTokenBefore").to.be.true;
        expect(
            strategyCompoundBalanceAfter.gt(strategyCompoundBalanceBefore),
            "strategyAaveBalanceAfter > strategyCompoundBalanceBefore"
        ).to.be.true;
        expect(
            userUsdcBalanceAfter.lt(userUsdcBalanceBefore),
            "userUsdcBalanceAfter < userUsdcBalanceBefore>"
        ).to.be.true;
        expect(
            strategyCTokenContractAfter.gt(strategyCTokenContractBefore),
            "strategyCTokenContractAfter > strategyCTokenContractBefore"
        ).to.be.true;
    });

    it("Should withdraw 10000000000000000000 from COMPOUND", async () => {
        //given
        const withdrawAmount = ONE_18.mul(10);
        await stanley.connect(signer).deposit(withdrawAmount);

        const userAddress = await signer.getAddress();
        const userIvTokenBefore = await ivToken.balanceOf(userAddress);
        const strategyCompoundBalanceBefore = await strategyCompoundContractInstance.balanceOf();
        const userUsdcBalanceBefore = await usdcContract.balanceOf(userAddress);
        const strategyCTokenContractBefore = await cTokenContract.balanceOf(
            strategyCompoundContractInstance.address
        );

        //when
        await stanley.withdraw(withdrawAmount);
        //then
        const userIvTokenAfter = await ivToken.balanceOf(userAddress);
        const strategyCompoundBalanceAfter = await strategyCompoundContractInstance.balanceOf();
        const userUsdcBalanceAfter = await usdcContract.balanceOf(userAddress);
        const strategyCTokenContractAfter = await cTokenContract.balanceOf(
            strategyCompoundContractInstance.address
        );

        expect(userIvTokenAfter.lt(userIvTokenBefore), "userIvTokenAfter < userIvTokenBefore").to.be
            .true;
        expect(
            strategyCompoundBalanceAfter.lt(strategyCompoundBalanceBefore),
            "strategyCompoundBalanceAfter < strategyCompoundBalanceBefore"
        ).to.be.true;
        expect(
            userUsdcBalanceAfter.gt(userUsdcBalanceBefore),
            "userUsdcBalanceAfter > userUsdcBalanceBefore"
        ).to.be.true;
        expect(
            strategyCTokenContractAfter.lt(strategyCTokenContractBefore),
            "strategyCTokenContractAfter < strategyCTokenContractBefore"
        ).to.be.true;
    });

    it("Should withdraw all user asset from COMPOUND - withdraw method", async () => {
        //given
        await stanley.connect(signer).deposit(ONE_18.mul(100));
        const userAddress = await signer.getAddress();
        const userIvTokenBefore = await ivToken.balanceOf(userAddress);
        const strategyCompoundBalanceBefore = await strategyCompoundContractInstance.balanceOf();
        const userUsdcBalanceBefore = await usdcContract.balanceOf(userAddress);

        //when
        await stanley.withdraw(strategyCompoundBalanceBefore);

        //then
        const userIvTokenAfter = await ivToken.balanceOf(userAddress);
        const strategyCompoundBalanceAfter = await strategyCompoundContractInstance.balanceOf();
        const userUsdcBalanceAfter = await usdcContract.balanceOf(userAddress);
        const strategyCTokenContractAfterWithdraw = await cTokenContract.balanceOf(
            strategyAaveContract_Instance.address
        );

        expect(userIvTokenAfter.lt(userIvTokenBefore), "userIvTokenAfter < userIvTokenBefore").to.be
            .true;
        expect(
            strategyCompoundBalanceAfter.lt(strategyCompoundBalanceBefore),
            "strategyCompoundBalanceAfter < strategyCompoundBalanceBefore>"
        ).to.be.true;

        /// Important check!
        expect(strategyCompoundBalanceAfter.lt(ONE_12), "strategyCompoundBalanceAfter <= ONE_12").to
            .be.true;

        expect(
            userUsdcBalanceAfter.gt(userUsdcBalanceBefore),
            "userUsdcBalanceAfter > userUsdcBalanceBefore"
        ).to.be.true;
        expect(
            strategyCTokenContractAfterWithdraw,
            "strategyCTokenContractAfterWithdraw = 0"
        ).to.be.equal(ZERO);
    });

    it("Should withdraw all user asset from COMPOUND - withdrawAll method", async () => {
        //given
        await stanley.connect(signer).deposit(ONE_18.mul(100));
        const userAddress = await signer.getAddress();
        const userIvTokenBefore = await ivToken.balanceOf(userAddress);
        const strategyCompoundBalanceBefore = await strategyCompoundContractInstance.balanceOf();
        const userUsdcBalanceBefore = await usdcContract.balanceOf(userAddress);

        //when
        await stanley.withdrawAll();

        //then
        const userIvTokenAfter = await ivToken.balanceOf(userAddress);
        const strategyCompoundBalanceAfter = await strategyCompoundContractInstance.balanceOf();
        const userUsdcBalanceAfter = await usdcContract.balanceOf(userAddress);
        const strategyCTokenContractAfterWithdraw = await cTokenContract.balanceOf(
            strategyAaveContract_Instance.address
        );

        expect(userIvTokenAfter.lt(userIvTokenBefore), "userIvTokenAfter < userIvTokenBefore").to.be
            .true;
        expect(
            strategyCompoundBalanceAfter.lt(strategyCompoundBalanceBefore),
            "strategyCompoundBalanceAfter < strategyCompoundBalanceBefore>"
        ).to.be.true;

        /// Important check!
        expect(strategyCompoundBalanceAfter.lt(ONE_12), "strategyCompoundBalanceAfter <= ONE_12").to
            .be.true;

        expect(
            userUsdcBalanceAfter.gt(userUsdcBalanceBefore),
            "userUsdcBalanceAfter > userUsdcBalanceBefore"
        ).to.be.true;
        expect(
            strategyCTokenContractAfterWithdraw,
            "strategyCTokenContractAfterWithdraw = 0"
        ).to.be.equal(ZERO);
    });
});

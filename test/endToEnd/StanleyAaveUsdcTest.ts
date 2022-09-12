import { BigNumber, Signer } from "ethers";
import hre, { upgrades } from "hardhat";
import { expect } from "chai";
const usdcAbi = require("../../abis/usdcAbi.json");
const comptrollerAbi = require("../../abis/comptroller.json");
const aaveIncentiveContractAbi = require("../../abis/aaveIncentiveContract.json");

const ZERO = BigNumber.from("0");
const ONE_18 = BigNumber.from("1000000000000000000");
const HALF_18 = BigNumber.from("500000000000000000");
const maxValue = BigNumber.from(
    "115792089237316195423570985008687907853269984665640564039457584007913129639935"
);

import {
    StrategyAave,
    StrategyCompound,
    StanleyUsdc,
    IvToken,
    ERC20,
    IAaveIncentivesController,
} from "../../types";

// // Mainnet Fork and test case for mainnet with hardhat network by impersonate account from mainnet
// work for blockNumber: 14222088,
describe("Deposit -> deployed Contract on Mainnet fork AAVE Usdc", function () {
    let accounts: Signer[];
    let accountToImpersonate: string;
    let usdcAddress: string;
    let usdcContract: ERC20;
    let strategyAave: StrategyAave;
    let strategyAaveV2: StrategyAave;
    let signer: Signer;
    let aUsdcAddress: string;
    let AAVE: string;
    let addressProvider: string;
    let cUsdcAddress: string;
    let COMP: string;
    let compContract: ERC20;
    let cTokenContract: ERC20;
    let ComptrollerAddress: string;
    let compTrollerContract: any;
    let aaveContract: ERC20;
    let aTokenContract: ERC20;
    let aaveIncentiveAddress: string;
    let aaveIncentiveContract: IAaveIncentivesController;
    let stkAave: string;
    let stakeAaveContract: ERC20;
    let strategyCompound: StrategyCompound;
    let ivToken: IvToken;
    let stanleyUsdc: StanleyUsdc;

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

        signer = hre.ethers.provider.getSigner(accountToImpersonate);
        usdcContract = new hre.ethers.Contract(usdcAddress, usdcAbi, signer) as ERC20;
        const impersonateBalanceBefore = await usdcContract.balanceOf(accountToImpersonate);
        await usdcContract.transfer(await accounts[0].getAddress(), impersonateBalanceBefore);
        signer = hre.ethers.provider.getSigner(await accounts[0].getAddress());
        usdcContract = new hre.ethers.Contract(usdcAddress, usdcAbi, signer) as ERC20;

        //  ********************************************************************************************
        //  **************                         AAVE                                   **************
        //  ********************************************************************************************

        aUsdcAddress = "0xBcca60bB61934080951369a648Fb03DF4F96263C";
        addressProvider = "0xB53C1a33016B2DC2fF3653530bfF1848a515c8c5"; // addressProvider mainnet
        AAVE = "0x7Fc66500c84A76Ad7e9c93437bFc5Ac33E2DDaE9";
        aaveIncentiveAddress = "0xd784927Ff2f95ba542BfC824c8a8a98F3495f6b5";
        stkAave = "0x4da27a545c0c5B758a6BA100e3a049001de870f5";

        aaveContract = new hre.ethers.Contract(AAVE, usdcAbi, signer) as ERC20;
        stakeAaveContract = new hre.ethers.Contract(stkAave, usdcAbi, signer) as ERC20;
        aTokenContract = new hre.ethers.Contract(aUsdcAddress, usdcAbi, signer) as ERC20;

        const strategyAaveContract = await hre.ethers.getContractFactory("StrategyAave", signer);

        strategyAave = (await upgrades.deployProxy(strategyAaveContract, [
            usdcAddress,
            aUsdcAddress,
            addressProvider,
            stkAave,
            aaveIncentiveAddress,
            AAVE,
        ])) as StrategyAave;

        strategyAaveV2 = (await upgrades.deployProxy(strategyAaveContract, [
            usdcAddress,
            aUsdcAddress,
            addressProvider,
            stkAave,
            aaveIncentiveAddress,
            AAVE,
        ])) as StrategyAave;

        aaveIncentiveContract = new hre.ethers.Contract(
            aaveIncentiveAddress,
            aaveIncentiveContractAbi,
            signer
        ) as IAaveIncentivesController;

        //  ********************************************************************************************
        //  **************                       COMPOUND                                 **************
        //  ********************************************************************************************

        cUsdcAddress = "0x39AA39c021dfbaE8faC545936693aC917d5E7563";
        COMP = "0xc00e94Cb662C3520282E6f5717214004A7f26888";
        ComptrollerAddress = "0x3d9819210A31b4961b30EF54bE2aeD79B9c9Cd3B";

        signer = hre.ethers.provider.getSigner(accountToImpersonate);
        compContract = new hre.ethers.Contract(COMP, usdcAbi, signer) as ERC20;
        cTokenContract = new hre.ethers.Contract(cUsdcAddress, usdcAbi, signer) as ERC20;
        signer = hre.ethers.provider.getSigner(await accounts[0].getAddress());

        const strategyCompoundContract = await hre.ethers.getContractFactory(
            "StrategyCompound",
            signer
        );

        strategyCompound = (await upgrades.deployProxy(strategyCompoundContract, [
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
        //  **************                        Stanley                                 **************
        //  ********************************************************************************************
        const IPORVaultFactory = await hre.ethers.getContractFactory("StanleyUsdc", signer);

        stanleyUsdc = (await upgrades.deployProxy(IPORVaultFactory, [
            usdcAddress,
            ivToken.address,
            strategyAave.address,
            strategyCompound.address,
        ])) as StanleyUsdc;

        await stanleyUsdc.setMilton(await signer.getAddress());
        await strategyAave.setStanley(stanleyUsdc.address);
        await strategyAaveV2.setStanley(stanleyUsdc.address);
        await strategyAave.setTreasury(await signer.getAddress());
        await strategyCompound.setStanley(stanleyUsdc.address);
        await strategyCompound.setTreasury(await signer.getAddress());

        await usdcContract.approve(await signer.getAddress(), maxValue);
        await usdcContract.approve(stanleyUsdc.address, maxValue);
        await ivToken.setStanley(stanleyUsdc.address);
    });

    it("Should accept deposit and transfer tokens into AAVE", async () => {
        //given
        const depositAmount = ONE_18.mul(10);
        const userAddress = await signer.getAddress();
        const userIvTokenBefore = await ivToken.balanceOf(userAddress);
        const strategyAaveBalanceBefore = await strategyAave.balanceOf();
        const userUsdcBalanceBefore = await usdcContract.balanceOf(userAddress);
        const strategyATokenContractBefore = await aTokenContract.balanceOf(strategyAave.address);

        expect(userIvTokenBefore, "userIvTokenBefore = 0").to.be.equal(ZERO);
        expect(strategyAaveBalanceBefore, "strategyAaveBalanceBefore = 0").to.be.equal(ZERO);

        //When
        const balance = await stanleyUsdc.connect(signer).deposit(depositAmount);

        //Then
        const userIvTokenAfter = await ivToken.balanceOf(userAddress);
        const strategyAaveBalanceAfter = await strategyAave.balanceOf();
        const userUsdcBalanceAfter = await usdcContract.balanceOf(userAddress);
        const strategyATokenContractAfter = await aTokenContract.balanceOf(strategyAave.address);

        expect(userIvTokenAfter.gt(userIvTokenBefore), "userIvTokenAfter > userIvTokenAfter").to.be
            .true;
        expect(
            strategyAaveBalanceAfter.gt(strategyAaveBalanceBefore),
            "strategyAaveBalanceAfter > strategyAaveBalanceAfter"
        ).to.be.true;
        expect(
            userUsdcBalanceAfter.lt(userUsdcBalanceBefore),
            "userUsdcBalanceAfter < userUsdcBalanceBefore"
        ).to.be.true;
        expect(
            strategyATokenContractAfter.gt(strategyATokenContractBefore),
            "strategyATokenContractAfter > strategyATokenContractBefore"
        ).to.be.true;
    });

    it("Should accept deposit twice and transfer tokens into AAVE", async () => {
        //given
        const depositAmount = ONE_18.mul(10);
        const userAddress = await signer.getAddress();
        const userIvTokenBefore = await ivToken.balanceOf(userAddress);
        const strategyAaveBalanceBefore = await strategyAave.balanceOf();
        const userUsdcBalanceBefore = await usdcContract.balanceOf(userAddress);
        const strategyATokenContractBefore = await aTokenContract.balanceOf(strategyAave.address);

        //When
        await stanleyUsdc.connect(signer).deposit(depositAmount);
        await stanleyUsdc.connect(signer).deposit(depositAmount);

        //Then
        const userIvTokenAfter = await ivToken.balanceOf(userAddress);
        const strategyAaveBalanceAfter = await strategyAave.balanceOf();
        const userUsdcBalanceAfter = await usdcContract.balanceOf(userAddress);
        const strategyATokenContractAfter = await aTokenContract.balanceOf(strategyAave.address);

        expect(userIvTokenAfter.gte(userIvTokenBefore), "userIvTokenAfter > userIvTokenBefore").to
            .be.true;
        expect(
            strategyAaveBalanceAfter.gt(strategyAaveBalanceBefore),
            "strategyAaveBalanceAfter > strategyAaveBalanceBefore"
        ).to.be.true;
        expect(
            userUsdcBalanceAfter.lt(userUsdcBalanceBefore),
            "userUsdcBalanceAfter < userUsdcBalanceBefore>"
        ).to.be.true;
        expect(
            strategyATokenContractAfter.gte(strategyATokenContractBefore),
            "strategyATokenContractAfter > strategyATokenContractBefore"
        ).to.be.true;
    });

    it("Should withdraw 10000000000000000000 from AAVE", async () => {
        //given
        const withdrawAmount = ONE_18.mul(10);
        const userAddress = await signer.getAddress();
        const userIvTokenBefore = await ivToken.balanceOf(userAddress);
        const strategyAaveBalanceBefore = await strategyAave.balanceOf();
        const userUsdcBalanceBefore = await usdcContract.balanceOf(userAddress);
        const strategyATokenContractBefore = await aTokenContract.balanceOf(strategyAave.address);

        //when
        await stanleyUsdc.withdraw(withdrawAmount);

        //then
        const userIvTokenAfter = await ivToken.balanceOf(userAddress);
        const strategyAaveBalanceAfter = await strategyAave.balanceOf();
        const userUsdcBalanceAfter = await usdcContract.balanceOf(userAddress);
        const strategyATokenContractAfter = await aTokenContract.balanceOf(strategyAave.address);

        expect(userIvTokenAfter.lt(userIvTokenBefore), "userIvTokenAfter < userIvTokenBefore").to.be
            .true;
        expect(
            strategyAaveBalanceAfter.lt(strategyAaveBalanceBefore),
            "strategyAaveBalanceAfter < strategyAaveBalanceBefore"
        ).to.be.true;
        expect(
            userUsdcBalanceAfter.gt(userUsdcBalanceBefore),
            "userUsdcBalanceAfter > userUsdcBalanceBefore"
        ).to.be.true;
        expect(
            strategyATokenContractAfter.lt(strategyATokenContractBefore),
            "strategyATokenContractAfter < strategyATokenContractBefore"
        ).to.be.true;
    });

    it("Should withdraw ALL stanley balance from AAVE - withdraw method", async () => {
        //given
        await stanleyUsdc.deposit(ONE_18.mul(10));
        const userAddress = await signer.getAddress();
        const userIvTokenBefore = await ivToken.balanceOf(userAddress);
        const strategyAaveBalanceBefore = await strategyAave.balanceOf();
        const userUsdcBalanceBefore = await usdcContract.balanceOf(userAddress);
        const strategyATokenContractBefore = await aTokenContract.balanceOf(strategyAave.address);

        //when
        await stanleyUsdc.withdraw(strategyAaveBalanceBefore);

        //then
        const userIvTokenAfter = await ivToken.balanceOf(userAddress);
        const strategyAaveBalanceAfter = await strategyAave.balanceOf();
        const userUsdcBalanceAfter = await usdcContract.balanceOf(userAddress);
        const strategyATokenContractAfter = await aTokenContract.balanceOf(strategyAave.address);

        expect(userIvTokenAfter.lt(userIvTokenBefore), "userIvTokenAfter < userIvTokenBefore").to.be
            .true;

        expect(
            strategyAaveBalanceAfter.lt(strategyAaveBalanceBefore),
            "strategyAaveBalanceAfter < strategyAaveBalanceBefore"
        ).to.be.true;

        /// Important check!
        expect(strategyAaveBalanceAfter.lt(HALF_18), "strategyAaveBalanceAfter <= HALF_18").to.be
            .true;

        expect(
            userUsdcBalanceAfter.gt(userUsdcBalanceBefore),
            "userUsdcBalanceAfter > userUsdcBalanceBefore"
        ).to.be.true;

        expect(
            strategyATokenContractAfter.lt(strategyATokenContractBefore),
            "strategyATokenContractAfter < strategyATokenContractBefore"
        ).to.be.true;
    });

    it("Should withdraw ALL stanley balance from AAVE - withdrawAll method", async () => {
        //given
        await stanleyUsdc.deposit(ONE_18.mul(10));
        const userAddress = await signer.getAddress();
        const userIvTokenBefore = await ivToken.balanceOf(userAddress);
        const strategyAaveBalanceBefore = await strategyAave.balanceOf();
        const userUsdcBalanceBefore = await usdcContract.balanceOf(userAddress);
        const strategyATokenContractBefore = await aTokenContract.balanceOf(strategyAave.address);

        //when
        await stanleyUsdc.withdrawAll();

        //then
        const userIvTokenAfter = await ivToken.balanceOf(userAddress);
        const strategyAaveBalanceAfter = await strategyAave.balanceOf();
        const userUsdcBalanceAfter = await usdcContract.balanceOf(userAddress);
        const strategyATokenContractAfter = await aTokenContract.balanceOf(strategyAave.address);

        expect(userIvTokenAfter.lt(userIvTokenBefore), "userIvTokenAfter < userIvTokenBefore").to.be
            .true;

        expect(
            strategyAaveBalanceAfter.lt(strategyAaveBalanceBefore),
            "strategyAaveBalanceAfter < strategyAaveBalanceBefore"
        ).to.be.true;

        /// Important check!
        expect(strategyAaveBalanceAfter.lt(HALF_18), "strategyAaveBalanceAfter <= HALF_18").to.be
            .true;

        expect(
            userUsdcBalanceAfter.gt(userUsdcBalanceBefore),
            "userUsdcBalanceAfter > userUsdcBalanceBefore"
        ).to.be.true;

        expect(
            strategyATokenContractAfter.lt(strategyATokenContractBefore),
            "strategyATokenContractAfter < strategyATokenContractBefore"
        ).to.be.true;
    });

    it("Should Claim from AAVE", async () => {
        //given
        const userOneAddres = await accounts[1].getAddress();
        const timestamp = Math.floor(Date.now() / 1000) + 864000 * 2;

        await hre.network.provider.send("evm_setNextBlockTimestamp", [timestamp]);
        await hre.network.provider.send("evm_mine");

        const claimable = await aaveIncentiveContract.getUserUnclaimedRewards(strategyAave.address);
        const aaveBalanceBefore = await aaveContract.balanceOf(userOneAddres);

        expect(claimable.gt(ZERO), "Aave Claimable Amount > 0").to.be.true;
        expect(aaveBalanceBefore, "Claimed Aave Balance Before").to.be.equal(ZERO);

        // when
        await strategyAave.beforeClaim();
        await hre.network.provider.send("evm_setNextBlockTimestamp", [timestamp + 865000]);
        await hre.network.provider.send("evm_mine");
        await strategyAave.doClaim();

        // then
        const userOneBalance = await aaveContract.balanceOf(await signer.getAddress());

        expect(userOneBalance.gt(ZERO), "Claimed Aave Balance > 0").to.be.true;
    });

    it("Should set new AAVE strategy for USDC", async () => {
        //given
        const depositAmount = ONE_18.mul(1000);
        await stanleyUsdc.connect(signer).deposit(depositAmount);

        const strategyAaveBalanceBefore = await strategyAave.balanceOf();
        const strategyAaveV2BalanceBefore = await strategyAaveV2.balanceOf();
        const miltonAssetBalanceBefore = await usdcContract.balanceOf(await signer.getAddress());

        //when
        await stanleyUsdc.setStrategyAave(strategyAaveV2.address);

        //then
        const strategyAaveBalanceAfter = await strategyAave.balanceOf();
        const strategyAaveV2BalanceAfter = await strategyAaveV2.balanceOf();
        const miltonAssetBalanceAfter = await usdcContract.balanceOf(await signer.getAddress());

        expect(strategyAaveBalanceBefore.eq(depositAmount), "strategyAaveBalanceBefore = 1000").to
            .be.true;
        expect(strategyAaveV2BalanceBefore.eq(ZERO), "strategyAaveV2BalanceBefore = 0").to.be.true;

        expect(strategyAaveBalanceAfter.eq(ZERO), "strategyAaveBalanceAfter = 0").to.be.true;

        /// Great Than Equal because with accrued interest
        expect(strategyAaveV2BalanceAfter.gte(depositAmount), "strategyAaveV2BalanceAfter > 1000")
            .to.be.true;
        expect(
            strategyAaveV2BalanceAfter.lt(depositAmount.add(ONE_18)),
            "strategyAaveV2BalanceAfter < 1001"
        ).to.be.true;

        expect(
            miltonAssetBalanceBefore.eq(miltonAssetBalanceAfter),
            "miltonAssetBalanceBefore = miltonAssetBalanceAfter"
        ).to.be.true;

        //clean up
        await stanleyUsdc.setStrategyAave(strategyAave.address);
    });

    it("Should migrate asset to strategy with max APR - Aave, USDC", async () => {
        //given
        const depositAmount = ONE_18.mul(1000);

        await stanleyUsdc.connect(signer).deposit(depositAmount);

        await strategyCompound.setStanley(await signer.getAddress());
        await usdcContract.approve(strategyCompound.address, depositAmount);
        await strategyCompound.connect(signer).deposit(depositAmount);
        await strategyCompound.setStanley(stanleyUsdc.address);

        const miltonIvTokenBefore = await ivToken.balanceOf(await signer.getAddress());
        const strategyAaveBalanceBefore = await strategyAave.balanceOf();
        const strategyCompoundBalanceBefore = await strategyCompound.balanceOf();
        const miltonAssetBalanceBefore = await usdcContract.balanceOf(await signer.getAddress());
        const miltonTotalBalanceBefore = await stanleyUsdc.totalBalance(await signer.getAddress());

        //when
        await stanleyUsdc.migrateAssetToStrategyWithMaxApr();

        //then
        const miltonIvTokenAfter = await ivToken.balanceOf(await signer.getAddress());
        const strategyAaveBalanceAfter = await strategyAave.balanceOf();
        const strategyCompoundBalanceAfter = await strategyCompound.balanceOf();
        const miltonAssetBalanceAfter = await usdcContract.balanceOf(await signer.getAddress());
        const miltonTotalBalanceAfter = await stanleyUsdc.totalBalance(await signer.getAddress());

        expect(
            miltonIvTokenAfter.eq(miltonIvTokenBefore),
            "miltonIvTokenAfter = miltonIvTokenBefore"
        ).to.be.true;

        expect(
            strategyAaveBalanceBefore.lt(strategyAaveBalanceAfter),
            "strategyAaveBalanceBefore < strategyAaveBalanceAfter"
        ).to.be.true;

        expect(
            strategyCompoundBalanceBefore.gt(strategyCompoundBalanceAfter),
            "strategyCompoundBalanceBefore > strategyCompoundBalanceAfter"
        ).to.be.true;

        expect(strategyCompoundBalanceAfter.gte(ZERO), "strategyCompoundBalanceAfter >= 0").to.be
            .true;
        expect(strategyCompoundBalanceAfter.lte(ONE_18), "strategyCompoundBalanceAfter <= 1").to.be
            .true;

        expect(
            miltonAssetBalanceAfter.eq(miltonAssetBalanceBefore),
            "miltonAssetBalanceAfter = miltonAssetBalanceBefore"
        ).to.be.true;

        expect(
            miltonTotalBalanceBefore.lte(miltonTotalBalanceAfter),
            "miltonTotalBalanceBefore <= miltonTotalBalanceAfter"
        ).to.be.true;

        expect(
            miltonTotalBalanceAfter.lte(miltonTotalBalanceBefore.add(ONE_18)),
            "miltonTotalBalanceAfter <= miltonTotalBalanceBefore+1"
        ).to.be.true;
    });
});

import { BigNumber, Signer } from "ethers";
import hre, { upgrades } from "hardhat";
import { expect } from "chai";
const daiAbi = require("../../abis/daiAbi.json");
const comptrollerAbi = require("../../abis/comptroller.json");
const aaveIncentiveContractAbi = require("../../abis/aaveIncentiveContract.json");

const ZERO = BigNumber.from("0");
const ONE_18 = BigNumber.from("1000000000000000000");
const ONE_12 = BigNumber.from("1000000000000");
const ONE_6 = BigNumber.from("1000000");
const maxValue = BigNumber.from(
    "115792089237316195423570985008687907853269984665640564039457584007913129639935"
);

import {
    StrategyAave,
    StrategyCompound,
    StanleyDai,
    IvToken,
    ERC20,
    IAaveIncentivesController,
} from "../../types";

// // Mainnet Fork and test case for mainnet with hardhat network by impersonate account from mainnet
// work for blockNumber: 14222087,
describe("Deposit -> deployed Contract on Mainnet fork AAVE Dai", function () {
    let accounts: Signer[];
    let accountToImpersonate: string;
    let daiAddress: string;
    let daiContract: ERC20;
    let strategyAave: StrategyAave;
    let strategyAaveV2: StrategyAave;
    let signer: Signer;
    let aDaiAddress: string;
    let AAVE: string;
    let addressProvider: string;
    let cDaiAddress: string;
    let COMP: string;
    let ComptrollerAddress: string;
    let aTokenContract: ERC20;
    let aaveIncentiveAddress: string;
    let stkAave: string;
    let strategyCompound: StrategyCompound;
    let ivToken: IvToken;
    let stanley: StanleyDai;

    if (process.env.FORK_ENABLED != "true") {
        return;
    }

    before(async () => {
        accounts = await hre.ethers.getSigners();

        //  ********************************************************************************************
        //  **************                     GENERAL                                    **************
        //  ********************************************************************************************

        accountToImpersonate = "0x6b175474e89094c44da98b954eedeac495271d0f"; // Dai rich address
        daiAddress = "0x6b175474e89094c44da98b954eedeac495271d0f"; // DAI

        await hre.network.provider.send("hardhat_setBalance", [
            accountToImpersonate,
            "0x100000000000000000000",
        ]);

        await hre.network.provider.request({
            method: "hardhat_impersonateAccount",
            params: [accountToImpersonate],
        });

        signer = hre.ethers.provider.getSigner(accountToImpersonate);
        daiContract = new hre.ethers.Contract(daiAddress, daiAbi, signer) as ERC20;
        const impersonateBalanceBefore = await daiContract.balanceOf(accountToImpersonate);
        await daiContract.transfer(await accounts[0].getAddress(), impersonateBalanceBefore);
        signer = hre.ethers.provider.getSigner(await accounts[0].getAddress());
        daiContract = new hre.ethers.Contract(daiAddress, daiAbi, signer) as ERC20;

        //  ********************************************************************************************
        //  **************                         AAVE                                   **************
        //  ********************************************************************************************

        aDaiAddress = "0x028171bCA77440897B824Ca71D1c56caC55b68A3";
        addressProvider = "0xB53C1a33016B2DC2fF3653530bfF1848a515c8c5"; // addressProvider mainnet
        AAVE = "0x7Fc66500c84A76Ad7e9c93437bFc5Ac33E2DDaE9";
        aaveIncentiveAddress = "0xd784927Ff2f95ba542BfC824c8a8a98F3495f6b5";
        stkAave = "0x4da27a545c0c5B758a6BA100e3a049001de870f5";

        const aaveContract = new hre.ethers.Contract(AAVE, daiAbi, signer) as ERC20;
        const stakeAaveContract = new hre.ethers.Contract(stkAave, daiAbi, signer) as ERC20;
        aTokenContract = new hre.ethers.Contract(aDaiAddress, daiAbi, signer) as ERC20;

        const strategyAaveContract = await hre.ethers.getContractFactory("StrategyAave", signer);

        strategyAave = (await upgrades.deployProxy(strategyAaveContract, [
            daiAddress,
            aDaiAddress,
            addressProvider,
            stkAave,
            aaveIncentiveAddress,
            AAVE,
        ])) as StrategyAave;

        strategyAaveV2 = (await upgrades.deployProxy(strategyAaveContract, [
            daiAddress,
            aDaiAddress,
            addressProvider,
            stkAave,
            aaveIncentiveAddress,
            AAVE,
        ])) as StrategyAave;

        const aaveIncentiveContract = new hre.ethers.Contract(
            aaveIncentiveAddress,
            aaveIncentiveContractAbi,
            signer
        ) as IAaveIncentivesController;

        //  ********************************************************************************************
        //  **************                       COMPOUND                                 **************
        //  ********************************************************************************************

        cDaiAddress = "0x5d3a536E4D6DbD6114cc1Ead35777bAB948E3643";
        COMP = "0xc00e94Cb662C3520282E6f5717214004A7f26888";
        ComptrollerAddress = "0x3d9819210A31b4961b30EF54bE2aeD79B9c9Cd3B";

        signer = await hre.ethers.provider.getSigner(accountToImpersonate);
        const compContract = new hre.ethers.Contract(COMP, daiAbi, signer) as ERC20;
        const cTokenContract = new hre.ethers.Contract(cDaiAddress, daiAbi, signer) as ERC20;
        signer = await hre.ethers.provider.getSigner(await accounts[0].getAddress());

        const strategyCompoundContract = await hre.ethers.getContractFactory(
            "StrategyCompound",
            signer
        );

        strategyCompound = (await upgrades.deployProxy(strategyCompoundContract, [
            daiAddress,
            cDaiAddress,
            ComptrollerAddress,
            COMP,
        ])) as StrategyCompound;

        const compTrollerContract = new hre.ethers.Contract(
            ComptrollerAddress,
            comptrollerAbi,
            signer
        );

        //  ********************************************************************************************
        //  **************                        IvToken                                 **************
        //  ********************************************************************************************

        const tokenFactoryIvToken = await hre.ethers.getContractFactory("IvToken", signer);
        ivToken = (await tokenFactoryIvToken.deploy("IvToken", "IVT", daiAddress)) as IvToken;

        //  ********************************************************************************************
        //  **************                        Stanley                                 **************
        //  ********************************************************************************************
        const IPORVaultFactory = await hre.ethers.getContractFactory("StanleyDai", signer);

        stanley = (await upgrades.deployProxy(IPORVaultFactory, [
            daiAddress,
            ivToken.address,
            strategyAave.address,
            strategyCompound.address,
        ])) as StanleyDai;

        await stanley.setMilton(await signer.getAddress());

        await strategyAave.setStanley(stanley.address);
        await strategyAaveV2.setStanley(stanley.address);
        await strategyAave.setTreasury(await signer.getAddress());
        await strategyCompound.setStanley(stanley.address);
        await strategyCompound.setTreasury(await signer.getAddress());

        await daiContract.approve(await signer.getAddress(), maxValue);
        await daiContract.approve(stanley.address, maxValue);
        await ivToken.setStanley(stanley.address);
    });

    it("Should accept deposit and transfer tokens into AAVE", async () => {
        //given
        const depositAmount = ONE_18.mul(10);
        const userAddress = await signer.getAddress();
        const userIvTokenBefore = await ivToken.balanceOf(userAddress);
        const strategyAaveBalanceBefore = await strategyAave.balanceOf();
        const userDaiBalanceBefore = await daiContract.balanceOf(userAddress);
        const strategyATokenContractBefore = await aTokenContract.balanceOf(strategyAave.address);

        expect(userIvTokenBefore, "userIvTokenBefore = 0").to.be.equal(ZERO);
        expect(strategyAaveBalanceBefore, "strategyAaveBalanceBefore = 0").to.be.equal(ZERO);

        //When
        await stanley.connect(signer).deposit(depositAmount);

        //Then
        const userIvTokenAfter = await ivToken.balanceOf(userAddress);
        const strategyAaveBalanceAfter = await strategyAave.balanceOf();
        const userDaiBalanceAfter = await daiContract.balanceOf(userAddress);
        const strategyATokenContractAfter = await aTokenContract.balanceOf(strategyAave.address);

        expect(
            userIvTokenAfter.gte(BigNumber.from("9999999999999999999")),
            "userIvTokenAfter >= 9999999999999999999"
        ).to.be.true;
        expect(
            strategyAaveBalanceAfter.gte(BigNumber.from("9999999999999999999")),
            "strategyAaveBalanceAfter >= 10 * 10^18"
        ).to.be.true;
        expect(
            userDaiBalanceAfter,
            "userDaiBalanceAfter = userDaiBalanceBefore - depositAmount"
        ).to.be.equal(userDaiBalanceBefore.sub(depositAmount));
        expect(
            strategyATokenContractAfter.sub(strategyATokenContractBefore).gte(depositAmount),
            "strategyATokenContractAfter >= depositAmount"
        ).to.be.true;
    });

    it("Should accept deposit twice and transfer tokens into AAVE", async () => {
        //given
        const depositAmount = ONE_18.mul(10);
        const userAddress = await signer.getAddress();
        const userIvTokenBefore = await ivToken.balanceOf(userAddress);
        const strategyAaveBalanceBefore = await strategyAave.balanceOf();
        const userDaiBalanceBefore = await daiContract.balanceOf(userAddress);
        const strategyATokenContractBefore = await aTokenContract.balanceOf(strategyAave.address);

        //When
        await stanley.connect(signer).deposit(depositAmount);
        await stanley.connect(signer).deposit(depositAmount);

        //Then
        const userIvTokenAfter = await ivToken.balanceOf(userAddress);
        const strategyATokenContractAfter = await aTokenContract.balanceOf(strategyAave.address);
        const userDaiBalanceAfter = await daiContract.balanceOf(userAddress);
        const strategyAaveBalanceAfter = await strategyAave.balanceOf();

        expect(userIvTokenAfter.gte(userIvTokenBefore), "userIvTokenAfter > userIvTokenBefore").to
            .be.true;
        expect(
            strategyAaveBalanceAfter.gt(strategyAaveBalanceBefore),
            "strategyAaveBalanceAfter > strategyAaveBalanceBefore"
        ).to.be.true;
        expect(
            userDaiBalanceAfter.lt(userDaiBalanceBefore),
            "userDaiBalanceAfter < userDaiBalanceBefore "
        ).to.be.true;
        expect(
            strategyATokenContractAfter.gt(strategyATokenContractBefore),
            "strategyATokenContractAfter > strategyATokenContractBefore"
        ).to.be.true;
    });

    it("Should withdraw 10000000000000000000 from AAVE", async () => {
        //given
        const withdrawAmount = ONE_18.mul(10);
        const userAddress = await signer.getAddress();
        const userIvTokenBefore = await ivToken.balanceOf(userAddress);
        const strategyAaveBalanceBefore = await strategyAave.balanceOf();
        const userDaiBalanceBefore = await daiContract.balanceOf(userAddress);
        const strategyATokenContractBefore = await aTokenContract.balanceOf(strategyAave.address);

        //when
        await stanley.withdraw(withdrawAmount);

        //then
        const strategyAaveBalanceAfter = await strategyAave.balanceOf();
        const userIvTokenAfter = await ivToken.balanceOf(userAddress);
        const userDaiBalanceAfter = await daiContract.balanceOf(userAddress);
        const strategyATokenContractAfter = await aTokenContract.balanceOf(strategyAave.address);

        expect(userIvTokenAfter.lt(userIvTokenBefore), "userIvTokenAfter < userIvTokenBefore").to.be
            .true;
        expect(
            strategyAaveBalanceAfter.lt(strategyAaveBalanceBefore),
            "strategyAaveBalanceAfter < strategyAaveBalanceBefore"
        ).to.be.true;
        expect(
            userDaiBalanceAfter.gte(userDaiBalanceAfter),
            "userDaiBalanceAfter > userDaiBalanceAfter"
        ).to.be.true;
        expect(
            strategyATokenContractAfter.lt(strategyATokenContractBefore),
            "strategyATokenContractAfter < strategyATokenContractBefore"
        ).to.be.true;
    });

    it("Should ALL withdraw stanley balance from AAVE - withdraw method", async () => {
        //given
        await stanley.deposit(ONE_18.mul(10));
        const userAddress = await signer.getAddress();
        const userIvTokenBefore = await ivToken.balanceOf(userAddress);
        const strategyAaveBalanceBefore = await strategyAave.balanceOf();
        const userDaiBalanceBefore = await daiContract.balanceOf(userAddress);
        const strategyATokenContractBefore = await aTokenContract.balanceOf(strategyAave.address);

        //when
        await stanley.withdraw(strategyAaveBalanceBefore);
        //then

        const userIvTokenAfter = await ivToken.balanceOf(userAddress);
        const strategyAaveBalanceAfter = await strategyAave.balanceOf();
        const userDaiBalanceAfter = await daiContract.balanceOf(userAddress);
        const strategyATokenContractAfter = await aTokenContract.balanceOf(strategyAave.address);

        expect(userIvTokenAfter.lt(userIvTokenBefore), "userIvTokenAfter < userIvTokenBefore").to.be
            .true;

        expect(
            strategyAaveBalanceAfter.lt(strategyAaveBalanceBefore),
            "strategyAaveBalanceAfter < strategyAaveBalanceBefore"
        ).to.be.true;

        /// Important check!
        expect(strategyAaveBalanceAfter.lt(ONE_12), "strategyAaveBalanceAfter = ONE_12").to.be.true;

        expect(
            userDaiBalanceAfter.gt(userDaiBalanceBefore),
            "userDaiBalanceAfter > userDaiBalanceBefore"
        ).to.be.true;

        expect(
            strategyATokenContractAfter.lt(strategyATokenContractBefore),
            "strategyATokenContractAfter < strategyATokenContractBefore"
        ).to.be.true;
    });

    it("Should ALL withdraw stanley balance from AAVE - withdrawAll method", async () => {
        //given
        await stanley.deposit(ONE_18.mul(10));
        const userAddress = await signer.getAddress();
        const userIvTokenBefore = await ivToken.balanceOf(userAddress);
        const strategyAaveBalanceBefore = await strategyAave.balanceOf();
        const userDaiBalanceBefore = await daiContract.balanceOf(userAddress);
        const strategyATokenContractBefore = await aTokenContract.balanceOf(strategyAave.address);

        //when
        await stanley.withdrawAll();
        //then

        const userIvTokenAfter = await ivToken.balanceOf(userAddress);
        const strategyAaveBalanceAfter = await strategyAave.balanceOf();
        const userDaiBalanceAfter = await daiContract.balanceOf(userAddress);
        const strategyATokenContractAfter = await aTokenContract.balanceOf(strategyAave.address);

        expect(userIvTokenAfter.lt(userIvTokenBefore), "userIvTokenAfter < userIvTokenBefore").to.be
            .true;

        expect(
            strategyAaveBalanceAfter.lt(strategyAaveBalanceBefore),
            "strategyAaveBalanceAfter < strategyAaveBalanceBefore"
        ).to.be.true;

        /// Important check!
        expect(strategyAaveBalanceAfter.eq(ZERO), "strategyAaveBalanceAfter = ZERO").to.be.true;

        expect(
            userDaiBalanceAfter.gt(userDaiBalanceBefore),
            "userDaiBalanceAfter > userDaiBalanceBefore"
        ).to.be.true;

        expect(
            strategyATokenContractAfter.lt(strategyATokenContractBefore),
            "strategyATokenContractAfter < strategyATokenContractBefore"
        ).to.be.true;
    });

    it("Should set new AAVE strategy for DAI", async () => {
        //given
        const depositAmount = ONE_18.mul(1000);
        await stanley.connect(signer).deposit(depositAmount);

        const strategyAaveBalanceBefore = await strategyAave.balanceOf();
        const strategyAaveV2BalanceBefore = await strategyAaveV2.balanceOf();
        const miltonAssetBalanceBefore = await daiContract.balanceOf(await signer.getAddress());

        //when
        await stanley.setStrategyAave(strategyAaveV2.address);

        //then
        const strategyAaveBalanceAfter = await strategyAave.balanceOf();
        const strategyAaveV2BalanceAfter = await strategyAaveV2.balanceOf();
        const miltonAssetBalanceAfter = await daiContract.balanceOf(await signer.getAddress());

        expect(strategyAaveBalanceBefore.eq(depositAmount), "strategyAaveBalanceBefore = 1000").to
            .be.true;
        expect(strategyAaveV2BalanceBefore.eq(ZERO), "strategyAaveV2BalanceBefore = 0").to.be.true;

        expect(strategyAaveBalanceAfter.eq(ZERO), "strategyAaveBalanceAfter = 0").to.be.true;

        /// Great Than Equal because with accrued interest
        expect(strategyAaveV2BalanceAfter.gte(depositAmount), "strategyAaveV2BalanceAfter = 1000")
            .to.be.true;

        expect(
            miltonAssetBalanceBefore.eq(miltonAssetBalanceAfter),
            "miltonAssetBalanceBefore = miltonAssetBalanceAfter"
        ).to.be.true;

        //clean up
        await stanley.setStrategyAave(strategyAave.address);
    });

    it("Should migrate asset to strategy with max APR - Aave, DAI", async () => {
        //given
        const depositAmount = ONE_18.mul(1000);

        await stanley.connect(signer).deposit(depositAmount);

        await strategyCompound.setStanley(await signer.getAddress());
        await daiContract.approve(strategyCompound.address, depositAmount);
        await strategyCompound.connect(signer).deposit(depositAmount);
        await strategyCompound.setStanley(stanley.address);

        const miltonIvTokenBefore = await ivToken.balanceOf(await signer.getAddress());
        const strategyAaveBalanceBefore = await strategyAave.balanceOf();
        const strategyCompoundBalanceBefore = await strategyCompound.balanceOf();
        const miltonAssetBalanceBefore = await daiContract.balanceOf(await signer.getAddress());
        const miltonTotalBalanceBefore = await stanley.totalBalance(await signer.getAddress());

        //when
        await stanley.migrateAssetToStrategyWithMaxApr();

        //then
        const miltonIvTokenAfter = await ivToken.balanceOf(await signer.getAddress());
        const strategyAaveBalanceAfter = await strategyAave.balanceOf();
        const strategyCompoundBalanceAfter = await strategyCompound.balanceOf();
        const miltonAssetBalanceAfter = await daiContract.balanceOf(await signer.getAddress());
        const miltonTotalBalanceAfter = await stanley.totalBalance(await signer.getAddress());

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

        expect(strategyCompoundBalanceAfter.eq(ZERO), "strategyCompoundBalanceAfter = 0").to.be
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

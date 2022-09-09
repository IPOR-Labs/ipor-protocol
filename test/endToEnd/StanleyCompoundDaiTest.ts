import { expect } from "chai";
import { BigNumber, Signer } from "ethers";
import hre, { upgrades } from "hardhat";
const daiAbi = require("../../abis/daiAbi.json");
const cTokenAbi = require("../../abis/cTokenAbi.json");
const comptrollerAbi = require("../../abis/comptroller.json");

const ZERO = BigNumber.from("0");
const ONE_18 = BigNumber.from("1000000000000000000");
const HALF_18 = BigNumber.from("500000000000000000");
const maxValue = BigNumber.from(
    "115792089237316195423570985008687907853269984665640564039457584007913129639935"
);

import { StrategyCompound, StanleyDai, IvToken, ERC20, MockCDAI, MockStrategy } from "../../types";

// // Mainnet Fork and test case for mainnet with hardhat network by impersonate account from mainnet
// work for blockNumber: 14222087,
describe("Deposit -> deployed Contract on Mainnet fork  Compound DAI", function () {
    let accounts: Signer[];
    let accountToImpersonate: string;
    let daiAddress: string;
    let daiContract: ERC20;
    let strategyAaveContractInstance: MockStrategy;
    let signer: Signer;
    let cDaiAddress: string;
    let COMP: string;
    let compContract: ERC20;
    let cTokenContract: MockCDAI;
    let ComptrollerAddress: string;
    let compTrollerContract: any;
    let strategyCompound: StrategyCompound;
    let strategyCompoundV2: StrategyCompound;
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
        //  *******************************************************************************************

        // we mock aave bacoude we want compand APR > aave APR
        const StrategyAave = await hre.ethers.getContractFactory("MockStrategy");
        strategyAaveContractInstance = (await StrategyAave.deploy()) as MockStrategy;

        await strategyAaveContractInstance.setShareToken(daiAddress);
        await strategyAaveContractInstance.setAsset(daiAddress);

        //  ********************************************************************************************
        //  **************                       COMPOUND                                 **************
        //  ********************************************************************************************

        cDaiAddress = "0x5d3a536E4D6DbD6114cc1Ead35777bAB948E3643";
        COMP = "0xc00e94Cb662C3520282E6f5717214004A7f26888";
        ComptrollerAddress = "0x3d9819210A31b4961b30EF54bE2aeD79B9c9Cd3B";

        signer = hre.ethers.provider.getSigner(accountToImpersonate);
        compContract = new hre.ethers.Contract(COMP, daiAbi, signer) as ERC20;
        cTokenContract = new hre.ethers.Contract(cDaiAddress, cTokenAbi, signer) as MockCDAI;
        signer = hre.ethers.provider.getSigner(await accounts[0].getAddress());

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

        strategyCompoundV2 = (await upgrades.deployProxy(strategyCompoundContract, [
            daiAddress,
            cDaiAddress,
            ComptrollerAddress,
            COMP,
        ])) as StrategyCompound;

        compTrollerContract = new hre.ethers.Contract(ComptrollerAddress, comptrollerAbi, signer);

        //  ********************************************************************************************
        //  **************                        IvToken                                 **************
        //  ********************************************************************************************

        const tokenFactoryIvToken = await hre.ethers.getContractFactory("IvToken", signer);
        ivToken = (await tokenFactoryIvToken.deploy("IvToken", "IVT", daiAddress)) as IvToken;

        //  ********************************************************************************************
        //  **************                       Stanley                                **************
        //  ********************************************************************************************
        const StanleyFactory = await hre.ethers.getContractFactory("StanleyDai", signer);

        stanley = (await upgrades.deployProxy(StanleyFactory, [
            daiAddress,
            ivToken.address,
            strategyAaveContractInstance.address,
            strategyCompound.address,
        ])) as StanleyDai;

        await stanley.setMilton(await signer.getAddress());
        await strategyCompound.setStanley(stanley.address);
        await strategyCompoundV2.setStanley(stanley.address);
        await strategyCompound.setTreasury(await signer.getAddress());

        await daiContract.approve(await signer.getAddress(), maxValue);
        await daiContract.approve(stanley.address, maxValue);
        await ivToken.setStanley(stanley.address);
    });

    it("Should compand APR > aave APR ", async () => {
        // when
        const aaveApy = await strategyAaveContractInstance.getApr();
        const compoundApy = await strategyCompound.getApr();
        // then
        expect(compoundApy.gt(aaveApy)).to.be.true;
    });

    it("Should accept deposit and transfer tokens into COMPOUND", async () => {
        //given
        const depositAmount = ONE_18.mul(10);
        const userAddress = await signer.getAddress();
        const userIvTokenBefore = await ivToken.balanceOf(userAddress);
        const strategyCompoundBalanceBefore = await strategyCompound.balanceOf();
        const userDaiBalanceBefore = await daiContract.balanceOf(userAddress);
        const strategyCTokenContractBefore = await cTokenContract.balanceOf(
            strategyCompound.address
        );

        expect(userIvTokenBefore, "userIvTokenBefore = 0").to.be.equal(ZERO);
        expect(strategyCompoundBalanceBefore, "strategyCompoundBalanceBefore = 0").to.be.equal(
            ZERO
        );

        //When
        await stanley.connect(signer).deposit(depositAmount);

        //Then
        const userIvTokenAfter = await ivToken.balanceOf(userAddress);
        const strategyCompoundBalanceAfter = await strategyCompound.balanceOf();
        const userDaiBalanceAfter = await daiContract.balanceOf(userAddress);
        const strategyCTokenContractAfter = await cTokenContract.balanceOf(
            strategyCompound.address
        );

        expect(userIvTokenAfter, "userIvTokenAfter = depositAmount").to.be.equal(depositAmount);
        expect(
            strategyCompoundBalanceAfter.gt(strategyCompoundBalanceBefore),
            "strategyCompoundBalanceAfter > strategyCompoundBalanceBefore"
        ).to.be.true;
        expect(
            userDaiBalanceAfter.lt(userDaiBalanceBefore),
            "userDaiBalanceAfter < userDaiBalanceAfter>"
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
        const strategyCompoundBalanceBefore = await strategyCompound.balanceOf();
        const userDaiBalanceBefore = await daiContract.balanceOf(userAddress);
        const strategyCTokenContractBefore = await cTokenContract.balanceOf(
            strategyCompound.address
        );

        //When
        await stanley.connect(signer).deposit(depositAmount);
        await stanley.connect(signer).deposit(depositAmount);

        //Then
        const userIvTokenAfter = await ivToken.balanceOf(userAddress);
        const strategyCompoundBalanceAfter = await strategyCompound.balanceOf();
        const userDaiBalanceAfter = await daiContract.balanceOf(userAddress);
        const strategyCTokenContractAfter = await cTokenContract.balanceOf(
            strategyCompound.address
        );

        expect(userIvTokenAfter.gt(userIvTokenBefore), "userIvTokenAfter > userIvTokenBefore").to.be
            .true;
        expect(
            strategyCompoundBalanceAfter.gt(strategyCompoundBalanceBefore),
            "strategyAaveBalanceAfter > strategyCompoundBalanceBefore"
        ).to.be.true;
        expect(
            userDaiBalanceAfter.lt(userDaiBalanceBefore),
            "userDaiBalanceAfter < userDaiBalanceBefore>"
        ).to.be.true;
        expect(
            strategyCTokenContractAfter.gte(strategyCTokenContractBefore),
            "strategyATokenContractAfter > strategyCTokenContractBefore"
        ).to.be.true;
    });

    it("Should withdraw 10000000000000000000 from COMPOUND", async () => {
        //given
        const withdrawAmount = ONE_18.mul(10);
        const userAddress = await signer.getAddress();
        const userIvTokenBefore = await ivToken.balanceOf(userAddress);
        const strategyCompoundBalanceBefore = await strategyCompound.balanceOf();
        const userDaiBalanceBefore = await daiContract.balanceOf(userAddress);
        const strategyCTokenContractBefore = await cTokenContract.balanceOf(
            strategyCompound.address
        );

        //when
        await stanley.withdraw(withdrawAmount);

        //then
        const userIvTokenAfter = await ivToken.balanceOf(userAddress);
        const strategyCompoundBalanceAfter = await strategyCompound.balanceOf();
        const userDaiBalanceAfter = await daiContract.balanceOf(userAddress);
        const strategyCTokenContractAfter = await cTokenContract.balanceOf(
            strategyCompound.address
        );

        expect(userIvTokenAfter.lt(userIvTokenBefore), "userIvTokenAfter < userIvTokenAfter").to.be
            .true;
        expect(
            strategyCompoundBalanceAfter.lt(strategyCompoundBalanceBefore),
            "strategyCompoundBalanceAfter < strategyCompoundBalanceBefore"
        ).to.be.true;
        expect(
            userDaiBalanceAfter.gt(userDaiBalanceBefore),
            "userDaiBalanceAfter > userDaiBalanceBefore "
        ).to.be.true;
        expect(
            strategyCTokenContractAfter.lt(strategyCTokenContractBefore),
            "strategyCTokenContractAfter < strategyCTokenContractBefore"
        ).to.be.true;
    });

    it("Should withdraw all user asset from COMPOUND - withdraw method", async () => {
        //given
        await stanley.deposit(ONE_18.mul(10));

        const userAddress = await signer.getAddress();
        const userIvTokenBefore = await ivToken.balanceOf(userAddress);
        const strategyCompoundBalanceBefore = await strategyCompound.balanceOf();
        const userDaiBalanceBefore = await daiContract.balanceOf(userAddress);

        //when
        await stanley.withdraw(strategyCompoundBalanceBefore);

        //then
        const userIvTokenAfter = await ivToken.balanceOf(userAddress);
        const strategyCompoundBalanceAfter = await strategyCompound.balanceOf();
        const userDaiBalanceAfter = await daiContract.balanceOf(userAddress);
        const strategyCTokenContractAfterWithdraw = await cTokenContract.balanceOf(
            strategyAaveContractInstance.address
        );

        expect(userIvTokenAfter.lt(userIvTokenBefore), "userIvTokenAfter < userIvTokenBefore").to.be
            .true;
        expect(
            strategyCompoundBalanceAfter.lt(strategyCompoundBalanceBefore),
            "strategyCompoundBalanceAfter <= strategyCompoundBalanceBefore"
        ).to.be.true;

        /// Important check!
        expect(strategyCompoundBalanceAfter.lt(HALF_18), "strategyCompoundBalanceAfter < HALF_18")
            .to.be.true;

        expect(
            userDaiBalanceAfter.gt(userDaiBalanceBefore),
            "userDaiBalanceAfter < userDaiBalanceBefore"
        ).to.be.true;
        expect(
            strategyCTokenContractAfterWithdraw,
            "strategyCTokenContractAfterWithdraw = 0"
        ).to.be.equal(ZERO);
    });

    it("Should withdraw all user asset from COMPOUND - withdrawAll method", async () => {
        //given
        await stanley.deposit(ONE_18.mul(10));

        const userAddress = await signer.getAddress();
        const userIvTokenBefore = await ivToken.balanceOf(userAddress);
        const strategyCompoundBalanceBefore = await strategyCompound.balanceOf();
        const userDaiBalanceBefore = await daiContract.balanceOf(userAddress);

        //when
        await stanley.withdrawAll();

        //then
        const userIvTokenAfter = await ivToken.balanceOf(userAddress);
        const strategyCompoundBalanceAfter = await strategyCompound.balanceOf();
        const userDaiBalanceAfter = await daiContract.balanceOf(userAddress);
        const strategyCTokenContractAfterWithdraw = await cTokenContract.balanceOf(
            strategyAaveContractInstance.address
        );

        expect(userIvTokenAfter.lt(userIvTokenBefore), "userIvTokenAfter < userIvTokenBefore").to.be
            .true;
        expect(
            strategyCompoundBalanceAfter.lt(strategyCompoundBalanceBefore),
            "strategyCompoundBalanceAfter <= strategyCompoundBalanceBefore"
        ).to.be.true;

        /// Important check!
        expect(strategyCompoundBalanceAfter.lt(HALF_18), "strategyCompoundBalanceAfter < HALF_18")
            .to.be.true;

        expect(
            userDaiBalanceAfter.gt(userDaiBalanceBefore),
            "userDaiBalanceAfter < userDaiBalanceBefore"
        ).to.be.true;
        expect(
            strategyCTokenContractAfterWithdraw,
            "strategyCTokenContractAfterWithdraw = 0"
        ).to.be.equal(ZERO);
    });

    it("Should set new Compound strategy for DAI", async () => {
        //given
        const depositAmount = ONE_18.mul(100000);
        await stanley.connect(signer).deposit(depositAmount);
        await cTokenContract.accrueInterest();

        const strategyCompoundBalanceBefore = await strategyCompound.balanceOf();
        const strategyCompoundV2BalanceBefore = await strategyCompoundV2.balanceOf();
        const miltonAssetBalanceBefore = await daiContract.balanceOf(await signer.getAddress());

        //when
        await stanley.setStrategyCompound(strategyCompoundV2.address);

        //then
        const strategyCompoundBalanceAfter = await strategyCompound.balanceOf();
        const strategyCompoundV2BalanceAfter = await strategyCompoundV2.balanceOf();
        const miltonAssetBalanceAfter = await daiContract.balanceOf(await signer.getAddress());

        expect(
            strategyCompoundBalanceBefore.gte(depositAmount),
            "strategyCompoundBalanceBefore >= 1000"
        ).to.be.true;

        expect(
            strategyCompoundBalanceBefore.lte(depositAmount.add(ONE_18)),
            "strategyCompoundBalanceBefore <= 1001"
        ).to.be.true;

        expect(strategyCompoundV2BalanceBefore.eq(ZERO), "strategyCompoundV2BalanceBefore = 0").to
            .be.true;

        expect(strategyCompoundBalanceAfter.eq(ZERO), "strategyCompoundBalanceAfter = 0").to.be
            .true;

        /// Great Than Equal because with accrued interest
        expect(
            strategyCompoundV2BalanceAfter.gte(depositAmount),
            "strategyCompoundV2BalanceAfter = 1000"
        ).to.be.true;

        expect(
            miltonAssetBalanceBefore.eq(miltonAssetBalanceAfter),
            "miltonAssetBalanceBefore = miltonAssetBalanceAfter"
        ).to.be.true;
    });
});

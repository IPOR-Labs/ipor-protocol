import { BigNumber, Signer } from "ethers";
import hre, { upgrades } from "hardhat";
import { expect } from "chai";
const usdtAbi = require("../../abis/usdtAbi.json");
const comptrollerAbi = require("../../abis/comptroller.json");
const aaveIncentiveContractAbi = require("../../abis/aaveIncentiveContract.json");

const zero = BigNumber.from("0");
const one = BigNumber.from("1000000000000000000");
const maxValue = BigNumber.from(
    "115792089237316195423570985008687907853269984665640564039457584007913129639935"
);

import {
    StrategyAave,
    StanleyUsdt,
    IvToken,
    ERC20,
    IAaveIncentivesController,
    MockStrategy,
} from "../../types";

// // Mainnet Fork and test case for mainnet with hardhat network by impersonate account from mainnet
// work for blockNumber: 14222087,
describe("Deposit -> deployed Contract on Mainnet fork AAVE Usdt", function () {
    let accounts: Signer[];
    let accountToImpersonate: string;
    let usdtAddress: string;
    let usdtContract: ERC20;
    let strategyAaveContract_Instance: StrategyAave;
    let signer: Signer;
    let aUsdtAddress: string;
    let AAVE: string;
    let addressProvider: string;
    let cUsdtAddress: string;
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
    let strategyCompoundContract_Instance: MockStrategy;
    let ivToken: IvToken;
    let stanleyUsdt: StanleyUsdt;

    if (process.env.FORK_ENABLED != "true") {
        return;
    }

    before(async () => {
        accounts = await hre.ethers.getSigners();

        //  ********************************************************************************************
        //  **************                     GENERAL                                    **************
        //  ********************************************************************************************

        accountToImpersonate = "0xad41bd1cf3fd753017ef5c0da8df31a3074ea1ea"; // Usdt rich address
        usdtAddress = "0xdAC17F958D2ee523a2206206994597C13D831ec7"; // usdt

        await hre.network.provider.send("hardhat_setBalance", [
            accountToImpersonate,
            "0x100000000000000000000",
        ]);

        await hre.network.provider.request({
            method: "hardhat_impersonateAccount",
            params: [accountToImpersonate],
        });

        signer = await hre.ethers.provider.getSigner(accountToImpersonate);
        usdtContract = new hre.ethers.Contract(usdtAddress, usdtAbi, signer) as ERC20;
        const impersonateBalanceBefore = await usdtContract.balanceOf(accountToImpersonate);
        await usdtContract.transfer(await accounts[0].getAddress(), impersonateBalanceBefore);
        signer = await hre.ethers.provider.getSigner(await accounts[0].getAddress());
        usdtContract = new hre.ethers.Contract(usdtAddress, usdtAbi, signer) as ERC20;

        //  ********************************************************************************************
        //  **************                         AAVE                                   **************
        //  ********************************************************************************************

        aUsdtAddress = "0x3Ed3B47Dd13EC9a98b44e6204A523E766B225811";
        addressProvider = "0xB53C1a33016B2DC2fF3653530bfF1848a515c8c5"; // addressProvider mainnet
        AAVE = "0x7Fc66500c84A76Ad7e9c93437bFc5Ac33E2DDaE9";
        aaveIncentiveAddress = "0xd784927Ff2f95ba542BfC824c8a8a98F3495f6b5";
        stkAave = "0x4da27a545c0c5B758a6BA100e3a049001de870f5";

        aaveContract = new hre.ethers.Contract(AAVE, usdtAbi, signer) as ERC20;
        stakeAaveContract = new hre.ethers.Contract(stkAave, usdtAbi, signer) as ERC20;
        aTokenContract = new hre.ethers.Contract(aUsdtAddress, usdtAbi, signer) as ERC20;

        const strategyAaveContract = await hre.ethers.getContractFactory("StrategyAave", signer);
        strategyAaveContract_Instance = (await upgrades.deployProxy(strategyAaveContract, [
            usdtAddress,
            aUsdtAddress,
            addressProvider,
            stkAave,
            aaveIncentiveAddress,
            AAVE,
        ])) as StrategyAave;
        // getUserUnclaimedRewards
        aaveIncentiveContract = new hre.ethers.Contract(
            aaveIncentiveAddress,
            aaveIncentiveContractAbi,
            signer
        ) as IAaveIncentivesController;

        //  ********************************************************************************************
        //  **************                       COMPOUND                                 **************
        //  ********************************************************************************************

        cUsdtAddress = "0xf650C3d88D12dB855b8bf7D11Be6C55A4e07dCC9";
        COMP = "0xc00e94Cb662C3520282E6f5717214004A7f26888";
        ComptrollerAddress = "0x3d9819210A31b4961b30EF54bE2aeD79B9c9Cd3B";

        signer = await hre.ethers.provider.getSigner(accountToImpersonate);
        compContract = new hre.ethers.Contract(COMP, usdtAbi, signer) as ERC20;
        cTokenContract = new hre.ethers.Contract(cUsdtAddress, usdtAbi, signer) as ERC20;
        signer = await hre.ethers.provider.getSigner(await accounts[0].getAddress());

        // becouse compand APR > aave APR we need to mock strategyCompoundContract_Instance
        const StrategyCompound = await hre.ethers.getContractFactory("MockStrategy");
        strategyCompoundContract_Instance = (await StrategyCompound.deploy()) as MockStrategy;

        await strategyCompoundContract_Instance.setShareToken(usdtAddress);
        await strategyCompoundContract_Instance.setAsset(usdtAddress);

        compTrollerContract = new hre.ethers.Contract(ComptrollerAddress, comptrollerAbi, signer);

        //  ********************************************************************************************
        //  **************                        IvToken                                 **************
        //  ********************************************************************************************

        const tokenFactoryIvToken = await hre.ethers.getContractFactory("IvToken", signer);
        ivToken = (await tokenFactoryIvToken.deploy("IvToken", "IVT", usdtAddress)) as IvToken;

        //  ********************************************************************************************
        //  **************                        Stanley                                 **************
        //  ********************************************************************************************
        const IPORVaultFactory = await hre.ethers.getContractFactory("StanleyUsdt", signer);

        stanleyUsdt = (await await upgrades.deployProxy(IPORVaultFactory, [
            usdtAddress,
            ivToken.address,
            strategyAaveContract_Instance.address,
            strategyCompoundContract_Instance.address,
        ])) as StanleyUsdt;

        await stanleyUsdt.setMilton(await signer.getAddress());
        await strategyAaveContract_Instance.setStanley(stanleyUsdt.address);
        await strategyAaveContract_Instance.setTreasury(await signer.getAddress());
        await strategyCompoundContract_Instance.setStanley(stanleyUsdt.address);
        await strategyCompoundContract_Instance.setTreasury(await signer.getAddress());

        await usdtContract.approve(await signer.getAddress(), maxValue);
        await usdtContract.approve(stanleyUsdt.address, maxValue);
        await ivToken.setStanley(stanleyUsdt.address);
    });

    it("Shoiuld compand APR < aave APR ", async () => {
        // when
        const aaveApr = await strategyAaveContract_Instance.getApr();
        const compoundApr = await strategyCompoundContract_Instance.getApr();

        // then
        expect(compoundApr.lt(aaveApr)).to.be.true;
    });

    it("Should accept deposit and transfer tokens into AAVE", async () => {
        //given
        const depositAmound = one.mul(10);
        const userAddress = await signer.getAddress();
        const userIvTokenBefore = await ivToken.balanceOf(userAddress);
        const strategyAaveBalanceBefore = await strategyAaveContract_Instance.balanceOf();
        const userUsdtBalanceBefore = await usdtContract.balanceOf(userAddress);
        const strategyATokenContractBefor = await aTokenContract.balanceOf(
            strategyAaveContract_Instance.address
        );

        expect(userIvTokenBefore, "userIvTokenBefore = 0").to.be.equal(zero);
        expect(strategyAaveBalanceBefore, "strategyAaveBalanceBefore = 0").to.be.equal(zero);

        //When
        await stanleyUsdt.connect(signer).deposit(depositAmound);

        //Then
        const userIvTokenAfter = await ivToken.balanceOf(userAddress);
        const strategyAaveBalanceAfter = await strategyAaveContract_Instance.balanceOf();
        const userUsdtBalanceAfter = await usdtContract.balanceOf(userAddress);
        const strategyATokenContractAfter = await aTokenContract.balanceOf(
            strategyAaveContract_Instance.address
        );

        expect(userIvTokenAfter.gte(userIvTokenBefore), "userIvTokenAfter >= userIvTokenBefore").to
            .be.true;
        expect(
            strategyAaveBalanceAfter.gte(strategyAaveBalanceBefore),
            "strategyAaveBalanceAfter >= strategyAaveBalanceBefore"
        ).to.be.true;
        expect(
            userUsdtBalanceAfter.lte(userUsdtBalanceBefore),
            "userUsdtBalanceAfter <= userUsdtBalanceBefore"
        ).to.be.true;
        expect(
            strategyATokenContractAfter.gte(strategyATokenContractBefor),
            "strategyATokenContractAfter >= strategyATokenContractBefor"
        ).to.be.true;
    });

    it("Should accept deposit twice and transfer tokens into AAVE", async () => {
        //given
        const depositAmound = one.mul(10);
        const userAddress = await signer.getAddress();
        const userIvTokenBefore = await ivToken.balanceOf(userAddress);
        const strategyAaveBalanceBefore = await strategyAaveContract_Instance.balanceOf();
        const userUsdtBalanceBefore = await usdtContract.balanceOf(userAddress);
        const strategyATokenContractBefore = await aTokenContract.balanceOf(
            strategyAaveContract_Instance.address
        );

        //When
        await stanleyUsdt.connect(signer).deposit(depositAmound);
        await stanleyUsdt.connect(signer).deposit(depositAmound);

        //Then
        const userIvTokenAfter = await ivToken.balanceOf(userAddress);
        const strategyAaveBalanceAfter = await strategyAaveContract_Instance.balanceOf();
        const userUsdtBalanceAfter = await usdtContract.balanceOf(userAddress);
        const strategyATokenContractAfter = await aTokenContract.balanceOf(
            strategyAaveContract_Instance.address
        );

        expect(userIvTokenAfter.gte(userIvTokenBefore), "userIvTokenAfter >= userIvTokenBefore").to
            .be.true;
        expect(
            strategyAaveBalanceAfter.gt(strategyAaveBalanceBefore),
            "strategyAaveBalanceAfter >= strategyAaveBalanceBefore"
        ).to.be.true;
        expect(
            userUsdtBalanceAfter.lte(userUsdtBalanceBefore),
            "userUsdtBalanceAfter <= userUsdtBalanceBefore"
        ).to.be.true;
        expect(
            strategyATokenContractAfter.gte(strategyATokenContractBefore),
            "strategyATokenContractAfter >= strategyATokenContractBefore"
        ).to.be.true;
    });

    it("Should withdrow 10000000000000000000 from AAVE", async () => {
        //given
        const withdrawAmount = one.mul(10);
        const userAddress = await signer.getAddress();
        const userIvTokenBefore = await ivToken.balanceOf(userAddress);
        const strategyAaveBalanceBefore = await strategyAaveContract_Instance.balanceOf();
        const userUsdtBalanceBefore = await usdtContract.balanceOf(userAddress);
        const strategyATokenContractBefore = await aTokenContract.balanceOf(
            strategyAaveContract_Instance.address
        );

        //when
        await stanleyUsdt.withdraw(withdrawAmount);

        //then
        const userIvTokenAfter = await ivToken.balanceOf(userAddress);
        const strategyAaveBalanceAfter = await strategyAaveContract_Instance.balanceOf();
        const userUsdtBalanceAfter = await usdtContract.balanceOf(userAddress);
        const strategyATokenContractAfter = await aTokenContract.balanceOf(
            strategyAaveContract_Instance.address
        );

        expect(userIvTokenAfter.lt(userIvTokenBefore), "userIvTokenAfter < userIvTokenBefore").to.be
            .true;
        expect(
            strategyAaveBalanceAfter.lt(strategyAaveBalanceBefore),
            "strategyAaveBalanceAfter < strategyAaveBalanceBefore"
        ).to.be.true;

        expect(
            userUsdtBalanceAfter.gt(userUsdtBalanceBefore),
            "userUsdtBalanceAfter > userUsdtBalanceBefore"
        ).to.be.true;
        expect(
            strategyATokenContractAfter.lt(strategyATokenContractBefore),
            "strategyATokenContractAfter < strategyATokenContractBefore"
        ).to.be.true;
    });

    it("Should withdrow stanley balanse from AAVE", async () => {
        //given
        const userAddress = await signer.getAddress();
        const userIvTokenBefore = await ivToken.balanceOf(userAddress);
        const strategyAaveBalanceBefore = await strategyAaveContract_Instance.balanceOf();
        const userUsdtBalanceBefore = await usdtContract.balanceOf(userAddress);
        const strategyATokenContractBefore = await aTokenContract.balanceOf(
            strategyAaveContract_Instance.address
        );

        //when
        await stanleyUsdt.withdraw(strategyAaveBalanceBefore);

        //then
        const userIvTokenAfter = await ivToken.balanceOf(userAddress);
        const userUsdtBalanceAfter = await usdtContract.balanceOf(userAddress);
        const strategyATokenContractAfter = await aTokenContract.balanceOf(
            strategyAaveContract_Instance.address
        );

        expect(userIvTokenAfter.lt(userIvTokenBefore), "userIvTokenAfter < userIvTokenBefore").to.be
            .true;
        expect(
            userUsdtBalanceAfter.gt(userUsdtBalanceBefore),
            "userUsdtBalanceAfter > userUsdtBalanceBefore"
        ).to.be.true;
        expect(
            strategyATokenContractAfter.lt(strategyATokenContractBefore),
            "strategyATokenContractAfter < strategyATokenContractBefore"
        ).to.be.true;
    });
});

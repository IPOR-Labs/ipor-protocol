import { BigNumber, Signer } from "ethers";
import hre, { upgrades } from "hardhat";
const { expect } = require("chai");
const usdcAbi = require("../../../abis/usdcAbi.json");
const comptrollerAbi = require("../../../abis/comptroller.json");
const aaveIncentiveContractAbi = require("../../../abis/aaveIncentiveContract.json");

const zero = BigNumber.from("0");
const one = BigNumber.from("1000000000000000000");
const maxValue = BigNumber.from(
    "115792089237316195423570985008687907853269984665640564039457584007913129639935"
);

import {
    AaveStrategy,
    CompoundStrategy,
    StanleyUsdc,
    IvToken,
    ERC20,
    IAaveIncentivesController,
} from "../../../types";

// // Mainnet Fork and test case for mainnet with hardhat network by impersonate account from mainnet
// work for blockNumber: 14222088,
describe("Deposit -> deployed Contract on Mainnet fork", function () {
    let accounts: Signer[];
    let accountToImpersonate: string;
    let usdcAddress: string;
    let usdcContract: ERC20;
    let aaveStrategyContract_Instance: AaveStrategy;
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
    let compoundStrategyContract_Instance: CompoundStrategy;
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

        signer = await hre.ethers.provider.getSigner(accountToImpersonate);
        usdcContract = new hre.ethers.Contract(usdcAddress, usdcAbi, signer) as ERC20;
        const impersonateBalanceBefore = await usdcContract.balanceOf(accountToImpersonate);
        await usdcContract.transfer(await accounts[0].getAddress(), impersonateBalanceBefore);
        signer = await hre.ethers.provider.getSigner(await accounts[0].getAddress());
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

        const aaveStrategyContract = await hre.ethers.getContractFactory("AaveStrategy", signer);
        aaveStrategyContract_Instance = (await upgrades.deployProxy(aaveStrategyContract, [
            usdcAddress,
            aUsdcAddress,
            addressProvider,
            stkAave,
            aaveIncentiveAddress,
            AAVE,
        ])) as AaveStrategy;
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

        signer = await hre.ethers.provider.getSigner(accountToImpersonate);
        compContract = new hre.ethers.Contract(COMP, usdcAbi, signer) as ERC20;
        cTokenContract = new hre.ethers.Contract(cUsdcAddress, usdcAbi, signer) as ERC20;
        signer = await hre.ethers.provider.getSigner(await accounts[0].getAddress());

        const compoundStrategyContract = await hre.ethers.getContractFactory(
            "CompoundStrategy",
            signer
        );

        compoundStrategyContract_Instance = (await upgrades.deployProxy(compoundStrategyContract, [
            usdcAddress,
            cUsdcAddress,
            ComptrollerAddress,
            COMP,
        ])) as CompoundStrategy;

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

        stanleyUsdc = (await await upgrades.deployProxy(IPORVaultFactory, [
            usdcAddress,
            ivToken.address,
            aaveStrategyContract_Instance.address,
            compoundStrategyContract_Instance.address,
        ])) as StanleyUsdc;

        await stanleyUsdc.setMilton(await signer.getAddress());
        await aaveStrategyContract_Instance.setStanley(stanleyUsdc.address);
        await aaveStrategyContract_Instance.setTreasury(await signer.getAddress());
        await compoundStrategyContract_Instance.setStanley(stanleyUsdc.address);
        await compoundStrategyContract_Instance.setTreasury(await signer.getAddress());

        await usdcContract.approve(await signer.getAddress(), maxValue);
        await usdcContract.approve(stanleyUsdc.address, maxValue);
        await ivToken.setStanley(stanleyUsdc.address);
    });

    it("Should accept deposit and transfer tokens into AAVE", async () => {
        //given
        const depositAmound = one.mul(10);
        const userAddress = await signer.getAddress();
        const userIvTokenBefore = await ivToken.balanceOf(userAddress);
        const aaveStrategyBalanceBefore = await aaveStrategyContract_Instance.balanceOf();
        const userUsdcBalanceBefore = await usdcContract.balanceOf(userAddress);
        const strategyATokenContractBefore = await aTokenContract.balanceOf(
            aaveStrategyContract_Instance.address
        );

        expect(userIvTokenBefore, "userIvTokenBefore = 0").to.be.equal(zero);
        expect(aaveStrategyBalanceBefore, "aaveStrategyBalanceBefore = 0").to.be.equal(zero);

        //When
        await stanleyUsdc.connect(signer).deposit(depositAmound);

        //Then
        const userIvTokenAfter = await ivToken.balanceOf(userAddress);
        const aaveStrategyBalanceAfter = await aaveStrategyContract_Instance.balanceOf();
        const userUsdcBalanceAfter = await usdcContract.balanceOf(userAddress);
        const strategyATokenContractAfter = await aTokenContract.balanceOf(
            aaveStrategyContract_Instance.address
        );

        expect(userIvTokenAfter.gt(userIvTokenBefore), "userIvTokenAfter > userIvTokenAfter").to.be
            .true;
        expect(
            aaveStrategyBalanceAfter.gt(aaveStrategyBalanceBefore),
            "aaveStrategyBalanceAfter > aaveStrategyBalanceAfter"
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
        const depositAmound = one.mul(10);
        const userAddress = await signer.getAddress();
        const userIvTokenBefore = await ivToken.balanceOf(userAddress);
        const aaveStrategyBalanceBefore = await aaveStrategyContract_Instance.balanceOf();
        const userUsdcBalanceBefore = await usdcContract.balanceOf(userAddress);
        const strategyATokenContractBefore = await aTokenContract.balanceOf(
            aaveStrategyContract_Instance.address
        );

        //When
        await stanleyUsdc.connect(signer).deposit(depositAmound);
        await stanleyUsdc.connect(signer).deposit(depositAmound);

        //Then
        const userIvTokenAfter = await ivToken.balanceOf(userAddress);
        const aaveStrategyBalanceAfter = await aaveStrategyContract_Instance.balanceOf();
        const userUsdcBalanceAfter = await usdcContract.balanceOf(userAddress);
        const strategyATokenContractAfter = await aTokenContract.balanceOf(
            aaveStrategyContract_Instance.address
        );

        expect(userIvTokenAfter.gte(userIvTokenBefore), "userIvTokenAfter > userIvTokenBefore").to
            .be.true;
        expect(
            aaveStrategyBalanceAfter.gt(aaveStrategyBalanceBefore),
            "aaveStrategyBalanceAfter > aaveStrategyBalanceBefore"
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

    it("Should withdrow 10000000000000000000 from AAVE", async () => {
        //given
        const withdrawAmount = one.mul(10);
        const userAddress = await signer.getAddress();
        const userIvTokenBefore = await ivToken.balanceOf(userAddress);
        const aaveStrategyBalanceBefore = await aaveStrategyContract_Instance.balanceOf();
        const userUsdcBalanceBefore = await usdcContract.balanceOf(userAddress);
        const strategyATokenContractBefore = await aTokenContract.balanceOf(
            aaveStrategyContract_Instance.address
        );

        //when
        await stanleyUsdc.withdraw(withdrawAmount);

        //then
        const userIvTokenAfter = await ivToken.balanceOf(userAddress);
        const aaveStrategyBalanceAfter = await aaveStrategyContract_Instance.balanceOf();
        const userUsdcBalanceAfter = await usdcContract.balanceOf(userAddress);
        const strategyATokenContractAfter = await aTokenContract.balanceOf(
            aaveStrategyContract_Instance.address
        );

        expect(userIvTokenAfter.lt(userIvTokenBefore), "userIvTokenAfter < userIvTokenBefore").to.be
            .true;
        expect(
            aaveStrategyBalanceAfter.lt(aaveStrategyBalanceBefore),
            "aaveStrategyBalanceAfter < aaveStrategyBalanceBefore"
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

    it("Should withdrow stanley balanse from AAVE", async () => {
        //given
        const userAddress = await signer.getAddress();
        const userIvTokenBefore = await ivToken.balanceOf(userAddress);
        const aaveStrategyBalanceBefore = await aaveStrategyContract_Instance.balanceOf();
        const userUsdcBalanceBefore = await usdcContract.balanceOf(userAddress);
        const strategyATokenContractBefore = await aTokenContract.balanceOf(
            aaveStrategyContract_Instance.address
        );

        //when
        await stanleyUsdc.withdraw(aaveStrategyBalanceBefore);

        //then
        const userIvTokenAfter = await ivToken.balanceOf(userAddress);
        const userUsdcBalanceAfter = await usdcContract.balanceOf(userAddress);
        const strategyATokenContractAfter = await aTokenContract.balanceOf(
            aaveStrategyContract_Instance.address
        );

        expect(userIvTokenAfter.lt(userIvTokenBefore), "userIvTokenAfter < userIvTokenBefore").to.be
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

        const claimable = await aaveIncentiveContract.getUserUnclaimedRewards(
            aaveStrategyContract_Instance.address
        );
        const aaveBalanceBefore = await aaveContract.balanceOf(userOneAddres);

        expect(claimable.gt(zero), "Aave Claimable Amount > 0").to.be.true;
        expect(aaveBalanceBefore, "Cliamed Aave Balance Before").to.be.equal(zero);

        // when
        await aaveStrategyContract_Instance.beforeClaim();
        await hre.network.provider.send("evm_setNextBlockTimestamp", [timestamp + 865000]);
        await hre.network.provider.send("evm_mine");
        await aaveStrategyContract_Instance.doClaim();

        // then
        const userOneBalance = await aaveContract.balanceOf(await signer.getAddress());

        expect(userOneBalance.gt(zero), "Cliamed Aave Balance > 0").to.be.true;
    });
});

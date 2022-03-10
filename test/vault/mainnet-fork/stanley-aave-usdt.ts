import { BigNumber, Signer } from "ethers";
import hre, { upgrades } from "hardhat";
const { expect } = require("chai");
const usdtAbi = require("../../../abis/usdtAbi.json");
const comptrollerAbi = require("../../../abis/comptroller.json");
const aaveIncentiveContractAbi = require("../../../abis/aaveIncentiveContract.json");

const zero = BigNumber.from("0");
const one = BigNumber.from("1000000000000000000");
const maxValue = BigNumber.from(
    "115792089237316195423570985008687907853269984665640564039457584007913129639935"
);

import {
    AaveStrategy,
    Stanley,
    IvToken,
    ERC20,
    IAaveIncentivesController,
    MockStrategy,
} from "../../../types";

// // Mainnet Fork and test case for mainnet with hardhat network by impersonate account from mainnet
// work for blockNumber: 14222087,
describe("Deposit -> deployed Contract on Mainnet fork", function () {
    let accounts: Signer[];
    let accountToImpersonate: string;
    let usdtAddress: string;
    let usdtContract: ERC20;
    let aaveStrategyContract_Instance: AaveStrategy;
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
    let compoundStrategyContract_Instance: MockStrategy;
    let ivToken: IvToken;
    let stanley: Stanley;

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

        const aaveStrategyContract = await hre.ethers.getContractFactory("AaveStrategy", signer);
        aaveStrategyContract_Instance = (await upgrades.deployProxy(aaveStrategyContract, [
            usdtAddress,
            aUsdtAddress,
            addressProvider,
            stkAave,
            aaveIncentiveAddress,
            AAVE,
        ])) as AaveStrategy;
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

        // becouse compand APR > aave APR we need to mock compoundStrategyContract_Instance
        const CompoundStrategy = await hre.ethers.getContractFactory("MockStrategy");
        compoundStrategyContract_Instance = (await CompoundStrategy.deploy()) as MockStrategy;

        await compoundStrategyContract_Instance.setShareToken(usdtAddress);
        await compoundStrategyContract_Instance.setAsset(usdtAddress);

        compTrollerContract = new hre.ethers.Contract(ComptrollerAddress, comptrollerAbi, signer);

        //  ********************************************************************************************
        //  **************                        IvToken                                 **************
        //  ********************************************************************************************

        const tokenFactoryIvToken = await hre.ethers.getContractFactory("IvToken", signer);
        ivToken = (await tokenFactoryIvToken.deploy("IvToken", "IVT", usdtAddress)) as IvToken;

        //  ********************************************************************************************
        //  **************                        Stanley                                 **************
        //  ********************************************************************************************
        const IPORVaultFactory = await hre.ethers.getContractFactory("Stanley", signer);

        stanley = (await await upgrades.deployProxy(IPORVaultFactory, [
            usdtAddress,
            ivToken.address,
            aaveStrategyContract_Instance.address,
            compoundStrategyContract_Instance.address,
        ])) as Stanley;

        await stanley.setMilton(await signer.getAddress());
        await aaveStrategyContract_Instance.setStanley(stanley.address);
        await aaveStrategyContract_Instance.setTreasury(await signer.getAddress());
        await compoundStrategyContract_Instance.setStanley(stanley.address);
        await compoundStrategyContract_Instance.setTreasury(await signer.getAddress());

        await usdtContract.approve(await signer.getAddress(), maxValue);
        await usdtContract.approve(stanley.address, maxValue);
        await ivToken.setStanley(stanley.address);
    });

    it("Shoiuld compand APR < aave APR ", async () => {
        // when
        const aaveApr = await aaveStrategyContract_Instance.getApr();
        const compoundApr = await compoundStrategyContract_Instance.getApr();

        // then
        expect(compoundApr.lt(aaveApr)).to.be.true;
    });

    it("Should accept deposit and transfer tokens into AAVE", async () => {
        //given
        const depositAmound = one.mul(10);
        const userAddress = await signer.getAddress();
        const userIvTokenBefore = await ivToken.balanceOf(userAddress);
        const aaveStrategyBalanceBefore = await aaveStrategyContract_Instance.balanceOf();

        expect(userIvTokenBefore, "userIvTokenBefore = 0").to.be.equal(zero);
        expect(aaveStrategyBalanceBefore, "aaveStrategyBalanceBefore = 0").to.be.equal(zero);

        //When
        await stanley.connect(signer).deposit(depositAmound);

        //Then
        const userIvTokenAfter = await ivToken.balanceOf(userAddress);
        const aaveStrategyBalanceAfter = await aaveStrategyContract_Instance.balanceOf();
        const userUsdtBalanceAfter = await usdtContract.balanceOf(userAddress);
        const strategyATokenContractAfter = await aTokenContract.balanceOf(
            aaveStrategyContract_Instance.address
        );

        expect(userIvTokenAfter, "userIvTokenAfter = 10 * 10^18").to.be.equal(
            BigNumber.from("10000000000000000000")
        );
        expect(aaveStrategyBalanceAfter, "aaveStrategyBalanceAfter = 10 * 10^18").to.be.equal(
            BigNumber.from("10000001000000000000")
        );
        expect(userUsdtBalanceAfter, "userUsdtBalanceAfter = 227357362977886").to.be.equal(
            BigNumber.from("64435243342735")
        );
        expect(strategyATokenContractAfter, "strategyATokenContractAfter = 10000001").to.be.equal(
            BigNumber.from("10000001")
        );
    });

    it("Should accept deposit twice and transfer tokens into AAVE", async () => {
        //given
        const depositAmound = one.mul(10);
        const userAddress = await signer.getAddress();
        const userIvTokenBefore = await ivToken.balanceOf(userAddress);
        const aaveStrategyBalanceBefore = await aaveStrategyContract_Instance.balanceOf();

        expect(userIvTokenBefore, "userIvTokenBefore").to.be.equal(depositAmound);
        expect(
            aaveStrategyBalanceBefore,
            "aaveStrategyBalanceBefore = 10000001000000000000"
        ).to.be.equal(BigNumber.from("10000001000000000000"));

        //When
        await stanley.connect(signer).deposit(depositAmound);
        await stanley.connect(signer).deposit(depositAmound);
        //Then
        const userIvTokenAfter = await ivToken.balanceOf(userAddress);
        const aaveStrategyBalanceAfter = await aaveStrategyContract_Instance.balanceOf();
        const userUsdtBalanceAfter = await usdtContract.balanceOf(userAddress);
        const strategyATokenContractAfter = await aTokenContract.balanceOf(
            aaveStrategyContract_Instance.address
        );

        expect(userIvTokenAfter.gte(BigNumber.from("29999999")), "ivToken = 29999999978664630715")
            .to.be.true;
        expect(aaveStrategyBalanceAfter.gt(BigNumber.from("30000000")), "aaveStrategyBalanceAfter")
            .to.be.true;
        expect(userUsdtBalanceAfter, "userUsdtBalanceAfter = 64435223342735").to.be.equal(
            BigNumber.from("64435223342735")
        );
        expect(
            strategyATokenContractAfter.gte(BigNumber.from("30000000")),
            "strategyATokenContractAfter > 30 * 10^6"
        ).to.be.true;
    });

    it("Should withdrow 10000000000000000000 from AAVE", async () => {
        //given
        const withdrawAmount = one.mul(10);
        const userAddress = await signer.getAddress();
        const userIvTokenBefore = await ivToken.balanceOf(userAddress);
        const aaveStrategyBalanceBefore = await aaveStrategyContract_Instance.balanceOf();
        const userUsdtBalanceBefore = await usdtContract.balanceOf(userAddress);

        expect(userIvTokenBefore.gt(BigNumber.from("29999999")), "userIvTokenBefore > 29999999").to
            .be.true;
        expect(
            aaveStrategyBalanceBefore.gte(BigNumber.from("30000000")),
            "aaveStrategyBalanceBefore >= 30 * 10^6"
        ).to.be.true;

        //when
        await stanley.withdraw(withdrawAmount);

        //then
        const userIvTokenAfter = await ivToken.balanceOf(userAddress);
        const aaveStrategyBalanceAfter = await aaveStrategyContract_Instance.balanceOf();
        const userUsdtBalanceAfter = await usdtContract.balanceOf(userAddress);
        const strategyATokenContractAfter = await aTokenContract.balanceOf(
            aaveStrategyContract_Instance.address
        );

        expect(userIvTokenAfter.gt(BigNumber.from("19999999")), "ivToken > 19999999").to.be.true;
        expect(
            aaveStrategyBalanceAfter.gte(BigNumber.from("20000000000000000000")),
            "aaveStrategyBalanceAfter >= 20 * 10^18"
        ).to.be.true;
        expect(
            aaveStrategyBalanceAfter.lt(BigNumber.from("30000000000000000000")),
            "aaveStrategyBalanceAfter < 30 * 10^18"
        ).to.be.true;
        expect(
            userUsdtBalanceAfter.gt(userUsdtBalanceBefore),
            "userUsdtBalanceAfter > userUsdtBalanceBefore"
        ).to.be.true;
        expect(
            strategyATokenContractAfter.gte(BigNumber.from("20000000")),
            "strategyATokenContractAfter > 20 * 10^6"
        ).to.be.true;
        expect(
            strategyATokenContractAfter.lt(BigNumber.from("30000000")),
            "strategyATokenContractAfter < 30 * 10^6"
        ).to.be.true;
    });

    it("Should withdrow stanley balanse from AAVE", async () => {
        //given
        const userAddress = await signer.getAddress();
        const withdrawAmount = await ivToken.balanceOf(userAddress);
        const userIvTokenBefore = await ivToken.balanceOf(userAddress);
        const aaveStrategyBalanceBefore = await aaveStrategyContract_Instance.balanceOf();

        expect(userIvTokenBefore.gt(BigNumber.from("19999999")), "userIvTokenBefore = 199999999").to
            .be.true;
        expect(
            aaveStrategyBalanceBefore.gte(BigNumber.from("20000000")),
            "aaveStrategyBalanceBefore > 20 * 10^6"
        ).to.be.true;

        //when
        await stanley.withdraw(aaveStrategyBalanceBefore);

        //then
        const userIvTokenAfter = await ivToken.balanceOf(userAddress);
        const userUsdtBalanceAfter = await usdtContract.balanceOf(userAddress);
        const strategyATokenContractAfter = await aTokenContract.balanceOf(
            aaveStrategyContract_Instance.address
        );

        expect(userIvTokenAfter.lte(BigNumber.from("14223579500")), "ivToken < 14223579500").to.be
            .true;
        expect(
            userUsdtBalanceAfter.gte(BigNumber.from("64435253342736")),
            "userUsdtBalanceAfter >= 64435253342736"
        ).to.be.true;
        expect(
            strategyATokenContractAfter.lt(BigNumber.from("14223579500")),
            "strategyATokenContractAfter"
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

        expect(claimable, "Aave Claimable Amount").to.be.equal(BigNumber.from("59469528"));
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

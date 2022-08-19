import { BigNumber, Signer } from "ethers";
import hre, { upgrades } from "hardhat";
import { expect } from "chai";
const daiAbi = require("../../abis/daiAbi.json");
const comptrollerAbi = require("../../abis/comptroller.json");
const aaveIncentiveContractAbi = require("../../abis/aaveIncentiveContract.json");

const zero = BigNumber.from("0");
const one = BigNumber.from("1000000000000000000");
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
    let strategyAaveContractInstance: StrategyAave;
    let signer: Signer;
    let aDaiAddress: string;
    let AAVE: string;
    let addressProvider: string;
    let cDaiAddress: string;
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
    let strategyCompoundContractInstance: StrategyCompound;
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

        signer = await hre.ethers.provider.getSigner(accountToImpersonate);
        daiContract = new hre.ethers.Contract(daiAddress, daiAbi, signer) as ERC20;
        const impersonateBalanceBefore = await daiContract.balanceOf(accountToImpersonate);
        await daiContract.transfer(await accounts[0].getAddress(), impersonateBalanceBefore);
        signer = await hre.ethers.provider.getSigner(await accounts[0].getAddress());
        daiContract = new hre.ethers.Contract(daiAddress, daiAbi, signer) as ERC20;

        //  ********************************************************************************************
        //  **************                         AAVE                                   **************
        //  ********************************************************************************************

        aDaiAddress = "0x028171bCA77440897B824Ca71D1c56caC55b68A3";
        addressProvider = "0xB53C1a33016B2DC2fF3653530bfF1848a515c8c5"; // addressProvider mainnet
        AAVE = "0x7Fc66500c84A76Ad7e9c93437bFc5Ac33E2DDaE9";
        aaveIncentiveAddress = "0xd784927Ff2f95ba542BfC824c8a8a98F3495f6b5";
        stkAave = "0x4da27a545c0c5B758a6BA100e3a049001de870f5";

        aaveContract = new hre.ethers.Contract(AAVE, daiAbi, signer) as ERC20;
        stakeAaveContract = new hre.ethers.Contract(stkAave, daiAbi, signer) as ERC20;
        aTokenContract = new hre.ethers.Contract(aDaiAddress, daiAbi, signer) as ERC20;

        const strategyAaveContract = await hre.ethers.getContractFactory("StrategyAave", signer);
        strategyAaveContractInstance = (await upgrades.deployProxy(strategyAaveContract, [
            daiAddress,
            aDaiAddress,
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

        cDaiAddress = "0x5d3a536E4D6DbD6114cc1Ead35777bAB948E3643";
        COMP = "0xc00e94Cb662C3520282E6f5717214004A7f26888";
        ComptrollerAddress = "0x3d9819210A31b4961b30EF54bE2aeD79B9c9Cd3B";

        signer = await hre.ethers.provider.getSigner(accountToImpersonate);
        compContract = new hre.ethers.Contract(COMP, daiAbi, signer) as ERC20;
        cTokenContract = new hre.ethers.Contract(cDaiAddress, daiAbi, signer) as ERC20;
        signer = await hre.ethers.provider.getSigner(await accounts[0].getAddress());

        const strategyCompoundContract = await hre.ethers.getContractFactory(
            "StrategyCompound",
            signer
        );

        strategyCompoundContractInstance = (await upgrades.deployProxy(strategyCompoundContract, [
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
        //  **************                        Stanley                                 **************
        //  ********************************************************************************************
        const IPORVaultFactory = await hre.ethers.getContractFactory("StanleyDai", signer);

        stanley = (await upgrades.deployProxy(IPORVaultFactory, [
            daiAddress,
            ivToken.address,
            strategyAaveContractInstance.address,
            strategyCompoundContractInstance.address,
        ])) as StanleyDai;

        await stanley.setMilton(await signer.getAddress());
        await strategyAaveContractInstance.setStanley(stanley.address);
        await strategyAaveContractInstance.setTreasury(await signer.getAddress());
        await strategyCompoundContractInstance.setStanley(stanley.address);
        await strategyCompoundContractInstance.setTreasury(await signer.getAddress());

        await daiContract.approve(await signer.getAddress(), maxValue);
        await daiContract.approve(stanley.address, maxValue);
        await ivToken.setStanley(stanley.address);
    });

    it("Should accept deposit and transfer tokens into AAVE", async () => {
        //given
        const depositAmount = one.mul(10);
        const userAddress = await signer.getAddress();
        const userIvTokenBefore = await ivToken.balanceOf(userAddress);
        const strategyAaveBalanceBefore = await strategyAaveContractInstance.balanceOf();
        const userDaiBalanceBefore = await daiContract.balanceOf(userAddress);
        const strategyATokenContractBefore = await aTokenContract.balanceOf(
            strategyAaveContractInstance.address
        );

        expect(userIvTokenBefore, "userIvTokenBefore = 0").to.be.equal(zero);
        expect(strategyAaveBalanceBefore, "strategyAaveBalanceBefore = 0").to.be.equal(zero);

        //When
        await stanley.connect(signer).deposit(depositAmount);

        //Then
        const userIvTokenAfter = await ivToken.balanceOf(userAddress);
        const strategyAaveBalanceAfter = await strategyAaveContractInstance.balanceOf();
        const userDaiBalanceAfter = await daiContract.balanceOf(userAddress);
        const strategyATokenContractAfter = await aTokenContract.balanceOf(
            strategyAaveContractInstance.address
        );

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
        const depositAmount = one.mul(10);
        const userAddress = await signer.getAddress();
        const userIvTokenBefore = await ivToken.balanceOf(userAddress);
        const strategyAaveBalanceBefore = await strategyAaveContractInstance.balanceOf();
        const userDaiBalanceBefore = await daiContract.balanceOf(userAddress);
        const strategyATokenContractBefore = await aTokenContract.balanceOf(
            strategyAaveContractInstance.address
        );

        //When
        await stanley.connect(signer).deposit(depositAmount);
        await stanley.connect(signer).deposit(depositAmount);

        //Then
        const userIvTokenAfter = await ivToken.balanceOf(userAddress);
        const strategyATokenContractAfter = await aTokenContract.balanceOf(
            strategyAaveContractInstance.address
        );
        const userDaiBalanceAfter = await daiContract.balanceOf(userAddress);
        const strategyAaveBalanceAfter = await strategyAaveContractInstance.balanceOf();

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

    it("Should withdrow 10000000000000000000 from AAVE", async () => {
        //given
        const withdrawAmount = one.mul(10);
        const userAddress = await signer.getAddress();
        const userIvTokenBefore = await ivToken.balanceOf(userAddress);
        const strategyAaveBalanceBefore = await strategyAaveContractInstance.balanceOf();
        const userDaiBalanceBefore = await daiContract.balanceOf(userAddress);
        const strategyATokenContractBefore = await aTokenContract.balanceOf(
            strategyAaveContractInstance.address
        );

        //when
        await stanley.withdraw(withdrawAmount);

        //then
        const strategyAaveBalanceAfter = await strategyAaveContractInstance.balanceOf();
        const userIvTokenAfter = await ivToken.balanceOf(userAddress);
        const userDaiBalanceAfter = await daiContract.balanceOf(userAddress);
        const strategyATokenContractAfter = await aTokenContract.balanceOf(
            strategyAaveContractInstance.address
        );

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

    it("Should withdrow stanley balanse from AAVE", async () => {
        //given
        const userAddress = await signer.getAddress();
        const withdrawAmount = await ivToken.balanceOf(userAddress);
        const userIvTokenBefore = await ivToken.balanceOf(userAddress);
        const strategyAaveBalanceBefore = await strategyAaveContractInstance.balanceOf();
        const userDaiBalanceBefore = await daiContract.balanceOf(userAddress);

        //when
        await stanley.withdraw(strategyAaveBalanceBefore);
        //then

        const userIvTokenAfter = await ivToken.balanceOf(userAddress);
        const strategyAaveBalanceAfter = await strategyAaveContractInstance.balanceOf();
        const userDaiBalanceAfter = await daiContract.balanceOf(userAddress);
        const strategyATokenContractAfter = await aTokenContract.balanceOf(
            strategyAaveContractInstance.address
        );

        expect(userIvTokenAfter.lt(userIvTokenBefore), "userIvTokenAfter < userIvTokenBefore").to.be
            .true;
        expect(
            userDaiBalanceAfter.gt(userDaiBalanceBefore),
            "userDaiBalanceAfter > userDaiBalanceBefore"
        ).to.be.true;
    });
});

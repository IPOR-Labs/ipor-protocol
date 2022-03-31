import { getEnabledCategories } from "node:trace_events";
import hre, { upgrades } from "hardhat";
import { BigNumber } from "ethers";
import usdtAbi from "../../../abis/usdtAbi.json";
const { expect } = require("chai");

import aaveIncentiveContractAbi from "../../../abis/aaveIncentiveContract.json";
import { ItfJoseph__factory } from "../../../types";
// Mainnet Fork and test case for mainnet with hardhat network by impersonate account from mainnet
// work for blockNumber: 14222087,
describe("aave deployed Contract on Mainnet fork", function () {
    let accounts: any;
    let accountToImpersonate: any;
    let usdtAddress: any;
    let usdtContract: any;
    let strategyContract: any;
    let strategyContract_Instance: any;
    let signer: any;
    let impersonateBalanceBefore: any;
    let maxValue: any;
    let addressProvider: any;
    let aUsdtAddress: any;
    let AAVE: any;
    let aaveContract: any;
    let aTokenContract: any;
    let aaveIncentiveAddress: any;
    let aaveIncentiveContract: any;
    let stkAave: any;
    let stakeAaveContract: any;

    if (process.env.FORK_ENABLED != "true") {
        return;
    }

    describe("AAVE strategy USDT fork test", () => {
        before(async () => {
            maxValue =
                "115792089237316195423570985008687907853269984665640564039457584007913129639935";
            accounts = await hre.ethers.getSigners();
            console.log(accounts[0].address);

            // Mainnet addresses we need account which has Dai
            accountToImpersonate = "0xad41bd1cf3fd753017ef5c0da8df31a3074ea1ea"; // usdt rich address
            usdtAddress = "0xdAC17F958D2ee523a2206206994597C13D831ec7"; // usdt
            aUsdtAddress = "0x3Ed3B47Dd13EC9a98b44e6204A523E766B225811";
            addressProvider = "0xB53C1a33016B2DC2fF3653530bfF1848a515c8c5"; // addressProvider mainnet
            AAVE = "0x7Fc66500c84A76Ad7e9c93437bFc5Ac33E2DDaE9";
            aaveIncentiveAddress = "0xd784927Ff2f95ba542BfC824c8a8a98F3495f6b5";
            stkAave = "0x4da27a545c0c5B758a6BA100e3a049001de870f5";

            await hre.network.provider.send("hardhat_setBalance", [
                accountToImpersonate,
                "0x100000000000000000000",
            ]);

            await hre.network.provider.request({
                method: "hardhat_impersonateAccount",
                params: [accountToImpersonate],
            });
            signer = await hre.ethers.provider.getSigner(accountToImpersonate);

            usdtContract = new hre.ethers.Contract(usdtAddress, usdtAbi, signer);
            aaveContract = new hre.ethers.Contract(AAVE, usdtAbi, signer);
            stakeAaveContract = new hre.ethers.Contract(stkAave, usdtAbi, signer);
            aTokenContract = new hre.ethers.Contract(aUsdtAddress, usdtAbi, signer);
            impersonateBalanceBefore = await usdtContract.balanceOf(accountToImpersonate);
            console.log("impersonateBalanceBefore: ", impersonateBalanceBefore.toString());
            await usdtContract.transfer(accounts[0].address, impersonateBalanceBefore);
            const impersonateBalanceAfter = await usdtContract.balanceOf(accountToImpersonate);
            console.log("impersonateBalanceAfter: ", impersonateBalanceAfter.toString());
            signer = await hre.ethers.provider.getSigner(accounts[0].address);
            usdtContract = new hre.ethers.Contract(usdtAddress, usdtAbi, signer);

            //  ********************************************************************************************
            //  **************                      Deploy strategy                           **************
            //  ********************************************************************************************

            strategyContract = await hre.ethers.getContractFactory("StrategyAave", signer);

            strategyContract_Instance = await upgrades.deployProxy(strategyContract, [
                usdtAddress,
                aUsdtAddress,
                addressProvider,
                stkAave,
                aaveIncentiveAddress,
                AAVE,
            ]);

            await strategyContract_Instance.setStanley(await signer.getAddress());
            await strategyContract_Instance.setTreasury(await signer.getAddress());

            aaveIncentiveContract = new hre.ethers.Contract(
                aaveIncentiveAddress,
                aaveIncentiveContractAbi,
                signer
            );
        });

        it("test", async () => {
            expect(true).to.be.true;
        });

        it("hardhat_impersonateAccount and check transferred balance to our account usdt", async function () {
            const usdtBalanceBefore = await usdtContract.balanceOf(accounts[0].address);
            console.log("Usdt Balance Before", usdtBalanceBefore.toString());

            await usdtContract.approve(strategyContract_Instance.address, maxValue);
            const aUsdtBalanceBeforeDeposit = await aTokenContract.balanceOf(
                strategyContract_Instance.address
            );
            console.log("aTokens balance before deposit: ", aUsdtBalanceBeforeDeposit.toString());

            await strategyContract_Instance.deposit(BigNumber.from("100000000000000000000"));
            console.log("Deposite complete");
            const aUsdtBalanceAfterDeposit = await aTokenContract.balanceOf(
                strategyContract_Instance.address
            );
            console.log("aTokens balance after deposit: ", aUsdtBalanceAfterDeposit.toString());

            const strategyBalance = await strategyContract_Instance.balanceOf();
            console.log("strategy balance after deposit: ", strategyBalance.toString());

            const timestamp = Math.floor(Date.now() / 1000) + 864000 * 2;
            // console.log("Timestamp: ", timestamp);

            await hre.network.provider.send("evm_setNextBlockTimestamp", [timestamp]);
            await hre.network.provider.send("evm_mine");

            const aUsdtBalanceAfterAddTime = await aTokenContract.balanceOf(
                strategyContract_Instance.address
            );
            console.log(
                "aTokens balanse after add extra time ",
                aUsdtBalanceAfterAddTime.toString()
            );

            await aTokenContract
                .connect(signer)
                .approve(strategyContract_Instance.address, maxValue);
            await strategyContract_Instance.withdraw(strategyBalance);
            console.log("Withdraw complete");

            const aUsdtBalanceAfterWithdraw = await aTokenContract.balanceOf(
                strategyContract_Instance.address
            );
            console.log("aTokens balance after withdraw: ", aUsdtBalanceAfterWithdraw.toString());

            const claimable2 = await aaveIncentiveContract.getUserUnclaimedRewards(
                strategyContract_Instance.address
            );
            console.log("Aave Claimable Amount: ", claimable2.toString());

            await strategyContract_Instance.beforeClaim();

            await hre.network.provider.send("evm_setNextBlockTimestamp", [timestamp + 865000]);
            await hre.network.provider.send("evm_mine");

            const aaveBalanceBefore = await aaveContract.balanceOf(accounts[0].address);
            console.log("Cliamed Aave Balance Before", aaveBalanceBefore.toString());

            await strategyContract_Instance.doClaim();

            const aaveBalance = await aaveContract.balanceOf(accounts[0].address);
            console.log("Cliamed Aave Balance", aaveBalance.toString()); // should be non-zero

            const daiBalanceAfter = await usdtContract.balanceOf(accounts[0].address);
            console.log("Usdt Balance After", daiBalanceAfter.toString());
        });
    });
});

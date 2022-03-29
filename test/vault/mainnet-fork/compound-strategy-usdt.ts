import { ItfJoseph__factory } from "../../../types";

const { expect } = require("chai");
const { upgrades } = require("hardhat");
const { BigNumber, Wallet } = require("ethers");
const { formatEther, parseEther } = require("@ethersproject/units");
const usdtAbi = require("../../../abis/usdtAbi.json");
const comptrollerAbi = require("../../../abis/comptroller.json");
const hre = require("hardhat");

// // Mainnet Fork and test case for mainnet with hardhat network by impersonate account from mainnet
// work for blockNumber: 14222087,
describe("compound deployed Contract on Mainnet fork", function () {
    let accounts: any;
    let accountToImpersonate: any;
    let usdtAddress: any;
    let usdtContract: any;
    let strategyContract: any;
    let strategyContract_Instance: any;
    let signer: any;
    let impersonateBalanceBefore: any;
    let ourAccountBalanceBefore: any;
    let ourAccountBalanceAfter: any;
    let maxValue: any;
    let cUsdtAddress: any;
    let COMP: any;
    let compContract: any;
    let cTokenContract: any;
    let ComptrollerAddress: any;
    let compTrollerContract: any;

    if (process.env.FORK_ENABLED != "true") {
        return;
    }

    describe("Compound Strategy Usdc", () => {
        before(async () => {
            maxValue =
                "115792089237316195423570985008687907853269984665640564039457584007913129639935";
            accounts = await hre.ethers.getSigners();

            // Mainnet addresses
            accountToImpersonate = "0xad41bd1cf3fd753017ef5c0da8df31a3074ea1ea"; // USDT rich address
            usdtAddress = "0xdAC17F958D2ee523a2206206994597C13D831ec7"; // USDT
            cUsdtAddress = "0xf650C3d88D12dB855b8bf7D11Be6C55A4e07dCC9";
            COMP = "0xc00e94Cb662C3520282E6f5717214004A7f26888";
            ComptrollerAddress = "0x3d9819210A31b4961b30EF54bE2aeD79B9c9Cd3B";

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
            compContract = new hre.ethers.Contract(COMP, usdtAbi, signer);
            cTokenContract = new hre.ethers.Contract(cUsdtAddress, usdtAbi, signer);

            impersonateBalanceBefore = await usdtContract.balanceOf(accountToImpersonate);
            ourAccountBalanceBefore = await usdtContract.balanceOf(accounts[0].address);

            await usdtContract.transfer(accounts[0].address, impersonateBalanceBefore);

            signer = await hre.ethers.provider.getSigner(accounts[0].address);
            usdtContract = new hre.ethers.Contract(usdtAddress, usdtAbi, signer);

            ourAccountBalanceAfter = await usdtContract.balanceOf(accounts[0].address);

            //  ********************************************************************************************
            //  **************                      Deploy strategy                           **************
            //  ********************************************************************************************

            strategyContract = await hre.ethers.getContractFactory("StrategyCompound", signer);
            strategyContract_Instance = await upgrades.deployProxy(strategyContract, [
                usdtAddress,
                cUsdtAddress,
                ComptrollerAddress,
                COMP,
            ]);

            await strategyContract_Instance.setStanley(await signer.getAddress());
            await strategyContract_Instance.setTreasury(await signer.getAddress());

            compTrollerContract = new hre.ethers.Contract(
                ComptrollerAddress,
                comptrollerAbi,
                signer
            );
        });

        it("hardhat_impersonateAccount and check transferred balance to our account", async function () {
            let usdcBalanceBefore = await usdtContract.balanceOf(accounts[0].address);
            console.log("USDC Balance Before", usdcBalanceBefore.toString());

            await usdtContract.approve(strategyContract_Instance.address, maxValue);
            console.log("Deposite amound: 100000000000000000000");
            await strategyContract_Instance.connect(signer).deposit("100000000000000000000");
            console.log("Deposite complete");
            const strategyBalanceAfterDeposit = await strategyContract_Instance.balanceOf();
            console.log("Strategy balanse after deposit: ", strategyBalanceAfterDeposit.toString());

            const timestamp = Math.floor(Date.now() / 1000) + 864000 * 4;
            await hre.network.provider.send("evm_setNextBlockTimestamp", [timestamp]);
            await hre.network.provider.send("evm_mine");

            const cTokenBal = await cTokenContract.balanceOf(strategyContract_Instance.address);
            console.log("cToken Balance: ", cTokenBal.toString());

            await cTokenContract
                .connect(signer)
                .approve(strategyContract_Instance.address, maxValue);
            await strategyContract_Instance.withdraw(strategyBalanceAfterDeposit);
            console.log("Withdraw Complete");
            const strategyBalAfterWithdraw = await strategyContract_Instance.balanceOf();
            console.log("Strategy Balance after withdraw: ", strategyBalAfterWithdraw.toString());

            let compGoveBalanceBeforeClaim = await compContract.balanceOf(accounts[0].address);
            console.log("Comp Balance before claim", compGoveBalanceBeforeClaim.toString());

            await strategyContract_Instance.doClaim();

            let compGoveBalance = await compContract.balanceOf(accounts[0].address);
            console.log("Claimed Comp Balance after claim", compGoveBalance.toString());

            let usdcBalanceAfter = await usdtContract.balanceOf(accounts[0].address);
            console.log("USDT Balance After", usdcBalanceAfter.toString());
        });
    });
});

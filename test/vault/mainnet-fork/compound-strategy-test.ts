const { expect } = require("chai");
const { upgrades } = require("hardhat");
const { BigNumber, Wallet } = require("ethers");
const { formatEther, parseEther } = require("@ethersproject/units");
const daiAbi = require("../../../abis/daiAbi.json");
const comptrollerAbi = require("../../../abis/comptroller.json");
const hre = require("hardhat");

// // Mainnet Fork and test case for mainnet with hardhat network by impersonate account from mainnet
// work for blockNumber: 14222087,
describe("compound deployed Contract on Mainnet fork", function () {
    let accounts: any;
    let accountToImpersonate: any;
    let daiAddress: any;
    let daiContract: any;
    let strategyContract: any;
    let strategyContract_Instance: any;
    let signer: any;
    let impersonateBalanceBefore: any;
    let ourAccountBalanceBefore: any;
    let ourAccountBalanceAfter: any;
    let maxValue: any;
    let cDaiAddress: any;
    let COMP: any;
    let compContract: any;
    let cTokenContract: any;
    let ComptrollerAddress: any;
    let compTrollerContract: any;

    if (process.env.FORK_ENABLED != "true") {
        return;
    }

    describe("create functions", () => {
        before(async () => {
            maxValue =
                "115792089237316195423570985008687907853269984665640564039457584007913129639935";
            accounts = await hre.ethers.getSigners();

            // Mainnet addresses
            accountToImpersonate = "0x6b175474e89094c44da98b954eedeac495271d0f"; // Dai rich address
            daiAddress = "0x6B175474E89094C44Da98b954EedeAC495271d0F"; // DAI
            cDaiAddress = "0x5d3a536E4D6DbD6114cc1Ead35777bAB948E3643";
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

            daiContract = new hre.ethers.Contract(daiAddress, daiAbi, signer);
            compContract = new hre.ethers.Contract(COMP, daiAbi, signer);
            cTokenContract = new hre.ethers.Contract(
                cDaiAddress,
                daiAbi,
                signer
            );

            impersonateBalanceBefore = await daiContract.balanceOf(
                accountToImpersonate
            );

            console.log(
                "impersonateBalanceBefore: ",
                impersonateBalanceBefore.toString()
            );
            ourAccountBalanceBefore = await daiContract.balanceOf(
                accounts[0].address
            );

            await daiContract.transfer(
                accounts[0].address,
                impersonateBalanceBefore
            );

            signer = await hre.ethers.provider.getSigner(accounts[0].address);
            daiContract = new hre.ethers.Contract(daiAddress, daiAbi, signer);

            ourAccountBalanceAfter = await daiContract.balanceOf(
                accounts[0].address
            );
            console.log(
                "ourAccountBalanceAfter: ",
                ourAccountBalanceAfter.toString()
            );

            //  ********************************************************************************************
            //  **************                      Deploy strategy                           **************
            //  ********************************************************************************************

            strategyContract = await hre.ethers.getContractFactory(
                "CompoundStrategy",
                signer
            );
            strategyContract_Instance = await upgrades.deployProxy(
                strategyContract,
                [daiAddress, cDaiAddress, ComptrollerAddress, COMP]
            );

            await strategyContract_Instance.setStanley(
                await signer.getAddress()
            );

            compTrollerContract = new hre.ethers.Contract(
                ComptrollerAddress,
                comptrollerAbi,
                signer
            );
        });

        it("hardhat_impersonateAccount and check transfered balance to our account", async function () {
            let daiBalanceBefore = await daiContract.balanceOf(
                accounts[0].address
            );
            console.log("Dai Balance Before", daiBalanceBefore.toString());

            await daiContract.approve(
                strategyContract_Instance.address,
                maxValue
            );

            await strategyContract_Instance
                .connect(signer)
                .deposit("10000000000000000000");
            console.log("Deposite complete");

            const timestamp = Math.floor(Date.now() / 1000) + 864000 * 4;
            console.log("Timestamp: ", timestamp);

            await hre.network.provider.send("evm_setNextBlockTimestamp", [
                timestamp,
            ]);
            await hre.network.provider.send("evm_mine");

            const cTokenBal = await cTokenContract.balanceOf(
                strategyContract_Instance.address
            );
            console.log("cToken Balance: ", cTokenBal.toString());

            await cTokenContract
                .connect(signer)
                .approve(strategyContract_Instance.address, maxValue);
            await strategyContract_Instance.withdraw(cTokenBal);
            console.log("Withdraw Complete");

            await strategyContract_Instance.doClaim(accounts[0].address, [
                cDaiAddress,
            ]);

            let compGoveBalance = await compContract.balanceOf(
                accounts[0].address
            );
            console.log("Claimed Comp Balance", compGoveBalance.toString());

            let daiBalanceAfter = await daiContract.balanceOf(
                accounts[0].address
            );
            console.log("Dai Balance After", daiBalanceAfter.toString());
        });
    });
});

import { getEnabledCategories } from "node:trace_events";
import hre, { upgrades } from "hardhat";
import daiAbi from "../../../abis/daiAbi.json";
import aaveIncentiveContractAbi from "../../../abis/aaveIncentiveContract.json";
// Mainnet Fork and test case for mainnet with hardhat network by impersonate account from mainnet
// work for blockNumber: 14222087,
describe("aave deployed Contract on Mainnet fork", function () {
    let accounts: any;
    let accountToImpersonate: any;
    let daiAddress: any;
    let daiContract: any;
    let strategyContract: any;
    let strategyContract_Instance: any;
    let signer: any;
    let impersonateBalanceBefore: any;
    let maxValue: any;
    let addressProvider: any;
    let aDaiAddress: any;
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

    describe("create functions", () => {
        before(async () => {
            maxValue =
                "115792089237316195423570985008687907853269984665640564039457584007913129639935";
            accounts = await hre.ethers.getSigners();
            console.log(accounts[0].address);

            // Mainnet addresses we need account which has Dai
            accountToImpersonate = "0x6b175474e89094c44da98b954eedeac495271d0f"; // Dai rich address
            daiAddress = "0x6b175474e89094c44da98b954eedeac495271d0f"; // DAI
            aDaiAddress = "0x028171bCA77440897B824Ca71D1c56caC55b68A3";
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

            daiContract = new hre.ethers.Contract(daiAddress, daiAbi, signer);
            aaveContract = new hre.ethers.Contract(AAVE, daiAbi, signer);
            stakeAaveContract = new hre.ethers.Contract(
                stkAave,
                daiAbi,
                signer
            );
            aTokenContract = new hre.ethers.Contract(
                aDaiAddress,
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
            await daiContract.transfer(
                accounts[0].address,
                impersonateBalanceBefore
            );
            const impersonateBalanceAfter = await daiContract.balanceOf(
                accountToImpersonate
            );
            console.log(
                "impersonateBalanceAfter: ",
                impersonateBalanceAfter.toString()
            );
            signer = await hre.ethers.provider.getSigner(accounts[0].address);
            daiContract = new hre.ethers.Contract(daiAddress, daiAbi, signer);
            daiContract = new hre.ethers.Contract(daiAddress, daiAbi, signer);

            //  ********************************************************************************************
            //  **************                      Deploy strategy                           **************
            //  ********************************************************************************************

            strategyContract = await hre.ethers.getContractFactory(
                "AaveStrategy",
                signer
            );

            strategyContract_Instance = await upgrades.deployProxy(
                strategyContract,
                [
                    daiAddress,
                    aDaiAddress,
                    addressProvider,
                    stkAave,
                    aaveIncentiveAddress,
                    AAVE,
                ]
            );

            aaveIncentiveContract = new hre.ethers.Contract(
                aaveIncentiveAddress,
                aaveIncentiveContractAbi,
                signer
            );
        });

        it("hardhat_impersonateAccount and check transfered balance to our account", async function () {
            const daiBalanceBefore = await daiContract.balanceOf(
                accounts[0].address
            );
            console.log("Dai Balance Before", daiBalanceBefore.toString());

            await daiContract.approve(
                strategyContract_Instance.address,
                maxValue
            );
            const aDaiBalanceBefore = await aTokenContract.balanceOf(
                strategyContract_Instance.address
            );
            console.log("abal1Before: ", aDaiBalanceBefore.toString());

            await strategyContract_Instance.deposit("1000000000000000000000");
            console.log("Deposite complete");

            const timestamp = Math.floor(Date.now() / 1000) + 864000 * 2;
            console.log("Timestamp: ", timestamp);

            await hre.network.provider.send("evm_setNextBlockTimestamp", [
                timestamp,
            ]);
            await hre.network.provider.send("evm_mine");

            const aDaiBalance = await aTokenContract.balanceOf(
                strategyContract_Instance.address
            );
            console.log("abal1: ", aDaiBalance.toString());

            await aTokenContract
                .connect(signer)
                .approve(strategyContract_Instance.address, maxValue);
            await strategyContract_Instance.withdraw(aDaiBalance);
            console.log("Withdraw complete");

            const claimable2 =
                await aaveIncentiveContract.getUserUnclaimedRewards(
                    strategyContract_Instance.address
                );
            console.log("Aave Claimable Amount: ", claimable2.toString());

            await strategyContract_Instance.beforeClaim(
                [aDaiAddress],
                maxValue
            );

            await hre.network.provider.send("evm_setNextBlockTimestamp", [
                timestamp + 865000,
            ]);
            await hre.network.provider.send("evm_mine");

            const aaveBalanceBefore = await aaveContract.balanceOf(
                accounts[0].address
            );
            console.log(
                "Cliamed Aave Balance Before",
                aaveBalanceBefore.toString()
            );

            await strategyContract_Instance.doClaim(accounts[0].address, [
                aDaiAddress,
            ]);

            const aaveBalance = await aaveContract.balanceOf(
                accounts[0].address
            );
            console.log("Cliamed Aave Balance", aaveBalance.toString()); // should be non-zero

            const daiBalanceAfter = await daiContract.balanceOf(
                accounts[0].address
            );
            console.log("Dai Balance After", daiBalanceAfter.toString());
        });
    });
});

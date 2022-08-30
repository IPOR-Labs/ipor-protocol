const helpers = require("@nomicfoundation/hardhat-network-helpers");
const hre = require("hardhat");
const ethers = hre.ethers;
const usdcAbi = require("../abis/usdcAbi.json");

async function main() {
    const myAddress = "0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266";
    await helpers.impersonateAccount(myAddress);
    const impersonatedSigner = await ethers.getSigner(myAddress);

    const josephUsdc = "0x3D63c50AD04DD5aE394CAB562b7691DD5de7CF6f";
    const usdcAddress = "0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48";

    //Mainnet Fork Admin address
    const adminAddress = "0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266";

    const usdcContract = new hre.ethers.Contract(usdcAddress, usdcAbi, impersonatedSigner);

    await usdcContract.approve(josephUsdc, 1000000000000);
}
main()
    .then(() => process.exit(0))
    .catch((error) => {
        console.error(error);
        process.exit(1);
    });

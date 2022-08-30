const helpers = require("@nomicfoundation/hardhat-network-helpers");
const hre = require("hardhat");
const ethers = hre.ethers;
const usdtAbi = require("../abis/usdtAbi.json");

async function main() {
    const myAddress = "0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266";
    await helpers.impersonateAccount(myAddress);
    const impersonatedSigner = await ethers.getSigner(myAddress);

    const josephUsdt = "0x5322471a7E37Ac2B8902cFcba84d266b37D811A0";
    const usdtAddress = "0xdAC17F958D2ee523a2206206994597C13D831ec7";

    //Mainnet Fork Admin address
    const adminAddress = "0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266";

    const usdcContract = new hre.ethers.Contract(usdtAddress, usdtAbi, impersonatedSigner);

    await usdcContract.approve(josephUsdt, 1000000000000);
}
main()
    .then(() => process.exit(0))
    .catch((error) => {
        console.error(error);
        process.exit(1);
    });

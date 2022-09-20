require("dotenv").config({ path: "../.env" });
const helpers = require("@nomicfoundation/hardhat-network-helpers");
const hre = require("hardhat");
const ethers = hre.ethers;
const iporAddressesFilePath = `../.ipor/${process.env.ENV_PROFILE}-${process.env.ETH_BC_NETWORK_NAME}-ipor-addresses.json`;
const addresses = require(iporAddressesFilePath);
const josephAbi = require("../.ipor/abis/pretty/contracts/amm/pool/Joseph.sol/Joseph.json");
const miltonAbi = require("../.ipor/abis/pretty/contracts/amm/Milton.sol/Milton.json");


async function main() {
    //Mainnet Fork Admin address
    const adminAddress = "0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266";

    //impersonate to admin address
    await helpers.impersonateAccount(adminAddress);
    const impersonatedAdminAddress = await ethers.getSigner(adminAddress);

    const josephUsdtContract = new hre.ethers.Contract(
        addresses.JosephProxyUsdt,
        josephAbi,
        impersonatedAdminAddress
    );

    const josephUsdcContract = new hre.ethers.Contract(
        addresses.JosephProxyUsdc,
        josephAbi,
        impersonatedAdminAddress
    );

    const josephDaiContract = new hre.ethers.Contract(
        addresses.JosephProxyDai,
        josephAbi,
        impersonatedAdminAddress
    );

    const miltonUsdtContract = new hre.ethers.Contract(
        addresses.MiltonProxyUsdt,
        miltonAbi,
        impersonatedAdminAddress
    );

    const miltonUsdcContract = new hre.ethers.Contract(
        addresses.MiltonProxyUsdc,
        miltonAbi,
        impersonatedAdminAddress
    );

    const miltonDaiContract = new hre.ethers.Contract(
        addresses.MiltonProxyDai,
        miltonAbi,
        impersonatedAdminAddress
    );


    await josephUsdtContract.unpause();
    await josephUsdcContract.unpause();
    await josephDaiContract.unpause();

    await miltonUsdtContract.unpause();
    await miltonUsdcContract.unpause();
    await miltonDaiContract.unpause();

}
main()
    .then(() => process.exit(0))
    .catch((error) => {
        console.error(error);
        process.exit(1);
    });

require("dotenv").config({ path: "../.env" });
const helpers = require("@nomicfoundation/hardhat-network-helpers");
const hre = require("hardhat");
const ethers = hre.ethers;
const iporAddressesFilePath = `../.ipor/${process.env.ENV_PROFILE}-${process.env.ETH_BC_NETWORK_NAME}-ipor-addresses.json`;
const addresses = require(iporAddressesFilePath);
const cTokenAbi = require("../.ipor/abis/pretty/contracts/mocks/stanley/compound/MockCDAI.sol/MockCDAI.json");


async function main() {
    //Mainnet Fork Admin address
    const adminAddress = "0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266";

    //impersonate to admin address
    await helpers.impersonateAccount(adminAddress);
    const impersonatedAdminAddress = await ethers.getSigner(adminAddress);

    const cTokenUsdtContract = new hre.ethers.Contract(
        addresses.cUSDT,
        cTokenAbi,
        impersonatedAdminAddress
    );

    const cTokenUsdcContract = new hre.ethers.Contract(
        addresses.cUSDC,
        cTokenAbi,
        impersonatedAdminAddress
    );

    const cTokenDaiContract = new hre.ethers.Contract(
        addresses.cDAI,
        cTokenAbi,
        impersonatedAdminAddress
    );

    await cTokenUsdtContract.exchangeRateCurrent();
    await cTokenUsdcContract.exchangeRateCurrent();
    await cTokenDaiContract.exchangeRateCurrent();

}
main()
    .then(() => process.exit(0))
    .catch((error) => {
        console.error(error);
        process.exit(1);
    });

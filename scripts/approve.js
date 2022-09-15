require("dotenv").config({ path: "../.env" });
const helpers = require("@nomicfoundation/hardhat-network-helpers");
const hre = require("hardhat");
const ethers = hre.ethers;
const iporAddressesFilePath = `../.ipor/${process.env.ENV_PROFILE}-${process.env.ETH_BC_NETWORK_NAME}-ipor-addresses.json`;
const addresses = require(iporAddressesFilePath);
const erc20Abi = require("../.ipor/abis/pretty/@openzeppelin/contracts/token/ERC20/ERC20.sol/ERC20.json");

async function main() {
    //Mainnet Fork Admin address
    const adminAddress = "0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266";

    //impersonate to admin address
    await helpers.impersonateAccount(adminAddress);
    const impersonatedAdminAddress = await ethers.getSigner(adminAddress);

    const usdtContract = new hre.ethers.Contract(addresses.USDT, erc20Abi, impersonatedAdminAddress);
    const usdcContract = new hre.ethers.Contract(addresses.USDC, erc20Abi, impersonatedAdminAddress);
    const daiContract = new hre.ethers.Contract(addresses.DAI, erc20Abi, impersonatedAdminAddress);

    await usdtContract.approve(addresses.JosephProxyUsdt, ethers.BigNumber.from("1000000000000"));
    await usdcContract.approve(addresses.JosephProxyUsdc, ethers.BigNumber.from("1000000000000"));
    await daiContract.approve(addresses.JosephProxyDai, ethers.BigNumber.from("1000000000000000000000000"));

    await usdtContract.approve(addresses.MiltonProxyUsdt, ethers.BigNumber.from("1000000000000"));
    await usdcContract.approve(addresses.MiltonProxyUsdc, ethers.BigNumber.from("1000000000000"));
    await daiContract.approve(addresses.MiltonProxyDai, ethers.BigNumber.from("1000000000000000000000000"));

}
main()
    .then(() => process.exit(0))
    .catch((error) => {
        console.error(error);
        process.exit(1);
    });

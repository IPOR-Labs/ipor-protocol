const helpers = require("@nomicfoundation/hardhat-network-helpers");
const hre = require("hardhat");
const ethers = hre.ethers;
const usdcAbi = require("../abis/usdcAbi.json");
async function main() {
    const address = "0xFcb19e6a322b27c06842A71e8c725399f049AE3a";
    await helpers.impersonateAccount(address);
    const impersonatedSigner = await ethers.getSigner(address);
    let usdcContract;
    let usdcAddress = "0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48";
    usdcContract = new hre.ethers.Contract(usdcAddress, usdcAbi, impersonatedSigner);
    await usdcContract.updateMasterMinter(address);
    await usdcContract.configureMinter(address, 1000000000000);
    await usdcContract.mint("0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266", 1000000000000);
}
main()
    .then(() => process.exit(0))
    .catch((error) => {
        console.error(error);
        process.exit(1);
    });
//USDC: 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48
//USDC Owner: 0xFcb19e6a322b27c06842A71e8c725399f049AE3a
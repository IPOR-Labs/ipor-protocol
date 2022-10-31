const helpers = require("@nomicfoundation/hardhat-network-helpers");
const hre = require("hardhat");
const ethers = hre.ethers;
const usdtAbi = require("../abis/usdtAbi.json");
async function main() {
    const myAddress = "0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266";

    const stableOwnerAddress = "0xc6cde7c39eb2f0f0095f41570af89efc2c1ea828";
    await helpers.impersonateAccount(stableOwnerAddress);
    const impersonatedSigner = await ethers.getSigner(stableOwnerAddress);

    const usdtAddress = "0xdAC17F958D2ee523a2206206994597C13D831ec7";

    const usdtContract = new hre.ethers.Contract(usdtAddress, usdtAbi, impersonatedSigner);

    await usdtContract.issue(ethers.BigNumber.from("1000000000000"));
    await usdtContract.transfer(myAddress, ethers.BigNumber.from("1000000000000"));
}
main()
    .then(() => process.exit(0))
    .catch((error) => {
        console.error(error);
        process.exit(1);
    });

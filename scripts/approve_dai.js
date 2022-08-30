const helpers = require("@nomicfoundation/hardhat-network-helpers");

const hre = require("hardhat");
const ethers = hre.ethers;
const daiAbi = require("../abis/daiAbi.json");

async function main() {
    const myAddress = "0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266";
    await helpers.impersonateAccount(myAddress);
    const impersonatedSigner = await ethers.getSigner(myAddress);

    const josephDai = "0xB9d9e972100a1dD01cd441774b45b5821e136043";
    const daiAddress = "0x6B175474E89094C44Da98b954EedeAC495271d0F";

    //Mainnet Fork Admin address
    const adminAddress = "0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266";

    const daiContract = new hre.ethers.Contract(daiAddress, daiAbi, impersonatedSigner);

    await daiContract.approve(josephDai, ethers.BigNumber.from("1000000000000000000000000"));
}
main()
    .then(() => process.exit(0))
    .catch((error) => {
        console.error(error);
        process.exit(1);
    });

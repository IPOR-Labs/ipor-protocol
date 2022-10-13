const helpers = require("@nomicfoundation/hardhat-network-helpers");
const hre = require("hardhat");
const ethers = hre.ethers;
const daiAbi = require("../abis/daiAbi.json");

async function main() {
    const myAddress = "0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266";

    //Mainnet Fork Admin address
    const adminAddress = "0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266";

    const daiAddress = "0x6B175474E89094C44Da98b954EedeAC495271d0F";

    const bigGuyAddress = "0x8D6F396D210d385033b348bCae9e4f9Ea4e045bD";

    //impersonate to admin address
    await helpers.impersonateAccount(adminAddress);
    const impersonatedAdminAddress = await ethers.getSigner(adminAddress);

    await impersonatedAdminAddress.sendTransaction({
        to: bigGuyAddress,
        value: ethers.utils.parseEther("1.0"), // Sends exactly 1.0 ether
    });

    // impersonate to big guy
    await helpers.impersonateAccount(bigGuyAddress);
    const impersonatedSigner = await ethers.getSigner(bigGuyAddress);

    const daiContract = new hre.ethers.Contract(daiAddress, daiAbi, impersonatedSigner);

    await daiContract.transfer(myAddress, ethers.BigNumber.from("400000000000000000000000"));
}

main()
    .then(() => process.exit(0))
    .catch((error) => {
        console.error(error);
        process.exit(1);
    });

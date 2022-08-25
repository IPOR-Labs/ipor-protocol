const helpers = require("@nomicfoundation/hardhat-network-helpers");
const hre = require("hardhat");
const ethers = hre.ethers;
const josephDaiAbi = require("../.ipor/abis/pretty/contracts/amm/pool/JosephUsdt.sol/JosephUsdt.json");
const adminAddress = "0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266";
async function main() {
    const timelockAddress = "0xD92E9F039E4189c342b4067CC61f5d063960D248";
    const myAddress = "0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266";

    //impersonate to admin address
    await helpers.impersonateAccount(adminAddress);
    const impersonatedAdminAddress = await ethers.getSigner(adminAddress);

    await impersonatedAdminAddress.sendTransaction({
        to: timelockAddress,
        value: ethers.utils.parseEther("1.0"), // Sends exactly 1.0 ether
    });

    await helpers.impersonateAccount(timelockAddress);
    const impersonatedSigner = await ethers.getSigner(timelockAddress);

    const josephUsdtAddress = "0x33C5A44fd6E76Fc2b50a9187CfeaC336A74324AC";
    const josephUsdt = new hre.ethers.Contract(josephUsdtAddress, josephUsdtAbi, impersonatedSigner);
    await josephUsdt.transferOwnership(myAddress);
}
main()
    .then(() => process.exit(0))
    .catch((error) => {
        console.error(error);
        process.exit(1);
    });

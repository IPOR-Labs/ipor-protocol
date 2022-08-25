const helpers = require("@nomicfoundation/hardhat-network-helpers");
const hre = require("hardhat");
const ethers = hre.ethers;
const josephDaiAbi = require("../.ipor/abis/pretty/contracts/amm/pool/JosephUsdc.sol/JosephUsdc.json");
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


    const josephUsdcAddress = "0xC52569b5A349A7055E9192dBdd271F1Bd8133277";
    const josephUsdc = new hre.ethers.Contract(josephUsdcAddress, josephUsdcAbi, impersonatedSigner);
    await josephUsdc.transferOwnership(myAddress);

}
main()
    .then(() => process.exit(0))
    .catch((error) => {
        console.error(error);
        process.exit(1);
    });

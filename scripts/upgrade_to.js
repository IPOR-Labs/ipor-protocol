const helpers = require("@nomicfoundation/hardhat-network-helpers");

const hre = require("hardhat");
const ethers = hre.ethers;

const stanleyAbi = require("../.ipor/abis/ugly/contracts/vault/Stanley.sol/Stanley.json");

async function main() {
    const adminAddress = "0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266";
    await helpers.impersonateAccount(adminAddress);
    const impersonatedSigner = await ethers.getSigner(adminAddress);

    const proxyAddress = "0xb007167714e2940013EC3bb551584130B7497E22";

    const stanleyContract = new hre.ethers.Contract(proxyAddress, stanleyAbi, impersonatedSigner);

    await stanleyContract.upgradeTo("0x0724F18B2aA7D6413D3fDcF6c0c27458a8170Dd9");
    // const implAddress = await hre.upgrades.erc1967.getImplementationAddress(proxyAddress);
    // console.log("implAddress=", implAddress);
    console.log("DONE!");
}

main()
    .then(() => process.exit(0))
    .catch((error) => {
        console.error(error);
        process.exit(1);
    });

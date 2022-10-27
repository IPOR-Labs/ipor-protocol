const helpers = require("@nomicfoundation/hardhat-network-helpers");

const hre = require("hardhat");
const ethers = hre.ethers;

async function main() {
    const proxyAddress = "0xb007167714e2940013EC3bb551584130B7497E22";

    const implAddress = await hre.upgrades.erc1967.getImplementationAddress(proxyAddress);
    console.log("implAddress=", implAddress);
}

main()
    .then(() => process.exit(0))
    .catch((error) => {
        console.error(error);
        process.exit(1);
    });

const hre = require("hardhat");
const ethers = hre.ethers;

async function main() {
    accounts = await hre.ethers.getSigners();
    signer = await hre.ethers.provider.getSigner(await accounts[0].getAddress());

    const Migrations = await ethers.getContractFactory("Migrations", signer);
    const migrations = Migrations.attach("0x987e855776C03A4682639eEb14e65b3089EE6310");

    const lastNumber = await migrations.last_completed_migration();

    console.log("Migration number = ", lastNumber);
}
main()
    .then(() => process.exit(0))
    .catch((error) => {
        console.error(error);
        process.exit(1);
    });

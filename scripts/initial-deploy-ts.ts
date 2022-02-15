  import { run, ethers, upgrades } from "hardhat";

async function main() {
    await run("compile");
    
    console.log("Deploying Issue...");
	const Issue = await ethers.getContractFactory("Issue");
    const issue = await upgrades.deployProxy(Issue);
    //IporConfiguration
}

main()
    .then(() => process.exit(0))
    .catch((error) => {
        console.error(error);
        process.exit(1);
    });

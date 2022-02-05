// import { run, ethers } from "hardhat";

async function main() {
    await run("compile");
    // const accounts = await ethers.getSigners();
    // console.log(
    //     "Accounts:",
    //     accounts.map((a) => a.address)
    // );
    console.log("Deploying Issue...");
    const Issue = await ethers.getContractFactory("Issue");
    const issue = await upgrades.deployProxy(Issue, { kind: "uups" });
	console.log("Issue address = ", issue);
    //IporConfiguration
}

main()
    .then(() => process.exit(0))
    .catch((error) => {
        console.error(error);
        process.exit(1);
    });

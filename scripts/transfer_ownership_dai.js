const helpers = require("@nomicfoundation/hardhat-network-helpers");
const hre = require("hardhat");
const ethers = hre.ethers;
const josephDaiAbi = require("../.ipor/abis/pretty/contracts/amm/pool/JosephDai.sol/JosephDai.json");
const stanleyDaiAbi = require("../.ipor/abis/pretty/contracts/vault/StanleyDai.sol/StanleyDai.json");
const strategyAaveDaiAbi = require("../.ipor/abis/pretty/contracts/vault/strategies/StrategyAave.sol/StrategyAaveDai.json");
const strategyCompoundDaiAbi = require("../.ipor/abis/pretty/contracts/vault/strategies/StrategyCompound.sol/StrategyCompoundDai.json");

async function main() {
    const myAddress = "0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266";

    //Mainnet Fork Admin address
    const adminAddress = "0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266";
    //IPOR Protocol Owner with Timelock
    const timelockAddress = "0xD92E9F039E4189c342b4067CC61f5d063960D248";
    //Joseph DAI address
    const josephDaiAddress = "0x086d4daab14741b195deE65aFF050ba184B65045";
    //Stanley DAI address
    const stanleyDaiAddress = "0xA6aC8B6AF789319A1Db994E25760Eb86F796e2B0";
    //Stanley Strategy Aave DAI address
    const strategyAaveDaiAddress = "0x526d0047725D48BBc6e24C7B82A3e47C1AF1f62f";
    //Stanley Strategy Compound DAI address
    const strategyCompoundDaiAddress = "0x87CEF19aCa214d12082E201e6130432Df39fc774";

    //impersonate to admin address
    await helpers.impersonateAccount(adminAddress);
    const impersonatedAdminAddress = await ethers.getSigner(adminAddress);

    await impersonatedAdminAddress.sendTransaction({
        to: timelockAddress,
        value: ethers.utils.parseEther("1.0"), // Sends exactly 1.0 ether
    });

    await helpers.impersonateAccount(timelockAddress);
    const impersonatedSigner = await ethers.getSigner(timelockAddress);

    const josephDaiContract = new hre.ethers.Contract(
        josephDaiAddress,
        josephDaiAbi,
        impersonatedSigner
    );
    const stanleyDaiContract = new hre.ethers.Contract(
        stanleyDaiAddress,
        stanleyDaiAbi,
        impersonatedSigner
    );
    const strategyAaveDaiContract = new hre.ethers.Contract(
        strategyAaveDaiAddress,
        strategyAaveDaiAbi,
        impersonatedSigner
    );
    const strategyCompoundDaiContract = new hre.ethers.Contract(
        strategyCompoundDaiAddress,
        strategyCompoundDaiAbi,
        impersonatedSigner
    );

    await josephDaiContract.transferOwnership(myAddress);
    await stanleyDaiContract.transferOwnership(myAddress);
    await strategyAaveDaiContract.transferOwnership(myAddress);
    await strategyCompoundDaiContract.transferOwnership(myAddress);
}
main()
    .then(() => process.exit(0))
    .catch((error) => {
        console.error(error);
        process.exit(1);
    });

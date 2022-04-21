// require("dotenv").config({ path: "../.env" });

const { deployProxy, erc1967 } = require("@openzeppelin/truffle-upgrades");

const IporOracleFacadeDataProvider = artifacts.require("IporOracleFacadeDataProvider");
const CockpitDataProvider = artifacts.require("CockpitDataProvider");
const MiltonFacadeDataProvider = artifacts.require("MiltonFacadeDataProvider");

module.exports = async function (deployer, _network) {


    const miltonDevToolDataProvider = await deployProxy(
        CockpitDataProvider,
        [
            iporOracle.address,
            [mockedUsdt.address, mockedUsdc.address, mockedDai.address],
            [miltonUsdt.address, miltonUsdc.address, miltonDai.address],
            [miltonStorageUsdt.address, miltonStorageUsdc.address, miltonStorageDai.address],
            [josephUsdt.address, josephUsdc.address, josephDai.address],
            [ipTokenUsdt.address, ipTokenUsdc.address, ipTokenDai.address],
            [ivTokenUsdt.address, ivTokenUsdc.address, ivTokenDai.address],
        ],
        {
            deployer: deployer,
            initializer: "initialize",
            kind: "uups",
        }
    );
    

    console.log("Congratulations! DEPLOY Smart Contracts finished!");
};

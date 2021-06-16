const IporOracle = artifacts.require("IporOracle");
const Amm = artifacts.require("Amm");

module.exports = async function (deployer, _network, addresses) {
    await deployer.deploy(IporOracle);
    const iporOracle = await IporOracle.deployed();
    await deployer.deploy(Amm, iporOracle.address);
};
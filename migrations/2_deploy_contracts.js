const IporOracle = artifacts.require("IporOracle");
const IporAmm = artifacts.require("IporAmm");

module.exports = async function (deployer, _network, addresses) {
    await deployer.deploy(IporOracle);
    const iporOracle = await IporOracle.deployed();
    await deployer.deploy(IporAmm, iporOracle.address);
};
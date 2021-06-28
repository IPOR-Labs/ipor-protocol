const IporOracle = artifacts.require("IporOracle");
const IporAmmV1 = artifacts.require("IporAmmV1");

module.exports = async function (deployer, _network, addresses) {
    await deployer.deploy(IporOracle);
    const iporOracle = await IporOracle.deployed();
    await deployer.deploy(IporAmmV1, iporOracle.address);
};
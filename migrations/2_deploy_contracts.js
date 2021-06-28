const IporOracle = artifacts.require("IporOracle");
const IporAmmV1 = artifacts.require("IporAmmV1");
const IporPool = artifacts.require("IporPool");

module.exports = async function (deployer, _network, addresses) {
    const [admin, oracle, usdtToken, usdcToken, daiToken, _] = addresses;
    await deployer.deploy(IporOracle);
    const iporOracle = await IporOracle.deployed();

    if (_network == "develop") {

    }

    await deployer.deploy(IporPool, usdtToken);
    const usdtPool = await IporPool.deployed();

    await deployer.deploy(IporPool, usdcToken);
    const usdcPool = await IporPool.deployed();

    await deployer.deploy(IporPool, daiToken);
    const daiPool = await IporPool.deployed();

    await deployer.deploy(IporAmmV1, iporOracle.address, usdtPool.address, usdcPool.address, daiPool.address);
};
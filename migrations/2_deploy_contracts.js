const IporOracle = artifacts.require("IporOracle");
const IporAmmV1 = artifacts.require("IporAmmV1");
const IporPool = artifacts.require("IporPool");
const SimpleToken = artifacts.require('SimpleToken');

module.exports = async function (deployer, _network, addresses) {
    const [admin, oracle, usdtToken, usdcToken, daiToken, _] = addresses;
    await deployer.deploy(IporOracle);
    const iporOracle = await IporOracle.deployed();

    await deployer.deploy(SimpleToken, 'Fake USDT', 'fUSDT', '10000000000000000000000');
    const fakeUsdt = await SimpleToken.deployed();
    await deployer.deploy(IporPool, fakeUsdt.address);
    const usdtPool = await IporPool.deployed();

    await deployer.deploy(SimpleToken, 'Fake USDC', 'fUSDC', '10000000000000000000000');
    const fakeUsdc = await SimpleToken.deployed();
    await deployer.deploy(IporPool, fakeUsdc.address);
    const usdcPool = await IporPool.deployed();


    await deployer.deploy(SimpleToken, 'Fake DAI', 'fDAI', '10000000000000000000000');
    const fakeDai = await SimpleToken.deployed();
    await deployer.deploy(IporPool, fakeDai.address);
    const daiPool = await IporPool.deployed();

    await deployer.deploy(IporAmmV1, iporOracle.address, usdtPool.address, usdcPool.address, daiPool.address);
};
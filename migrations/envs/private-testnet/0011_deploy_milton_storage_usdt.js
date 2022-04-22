const script = require("../../libs/contracts/deploy/milton_storage/usdt/0001_initial_deploy.js");

const MiltonStorageUsdt = artifacts.require("MiltonStorageUsdt");

module.exports = async function (deployer, _network, addresses) {
    await script(deployer, _network, addresses, MiltonStorageUsdt);
};

const { exit } = require("process");
const func = require("../../libs/json_func.js");
const script = require("../../libs/mocks/0004_deploy_mocks_weth.js");



const WethMockedToken = artifacts.require("WethMockedToken");


module.exports = async function (deployer, _network, addresses) {
    await script(deployer, _network, addresses, [
        WethMockedToken,
    ]);
    await func.updateLastCompletedMigration();
};

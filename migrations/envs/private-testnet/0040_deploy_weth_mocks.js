const func = require("../../libs/json_func.js");
const script = require("../../libs/mocks/0004_deploy_mocks_weth.js");

const MockTestnetTokenWeth = artifacts.require("MockTestnetTokenWeth");

module.exports = async function (deployer, _network, addresses) {
    await script(deployer, _network, addresses,
        MockTestnetTokenWeth);
    await func.updateLastCompletedMigration();
};

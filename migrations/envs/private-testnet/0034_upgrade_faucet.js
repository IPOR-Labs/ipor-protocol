const func = require("../../libs/json_func.js");
const script = require("../../libs/contracts/setup/faucet/0002_upgrade_faucet.js");

module.exports = async function (deployer, _network, addresses) {
    await script(deployer, _network, addresses);
    await func.updateLastCompletedMigration();
};

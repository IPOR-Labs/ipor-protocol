const func = require("../../libs/json_func.js");
const script = require("../../libs/contracts/upgrade/stanley_strategies/compound/usdt/0001_upgrade.js");

module.exports = async function (deployer, _network, addresses) {
    await script(deployer, _network, addresses);
    await func.updateLastCompletedMigration();
};

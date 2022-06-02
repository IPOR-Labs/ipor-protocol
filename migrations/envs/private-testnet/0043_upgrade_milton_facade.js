const func = require("../../libs/json_func.js");
const script = require("../../libs/contracts/upgrade/milton_facade/0001_upgrade_to_v2.js");

module.exports = async function (deployer, _network, addresses) {
    await script(deployer, _network, addresses);
    await func.updateLastCompletedMigration();
};

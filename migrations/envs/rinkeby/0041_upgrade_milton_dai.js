const script = require("../../libs/contracts/upgrade/milton/dai/0002_upgrade_to_v3.js");
const func = require("../../libs/json_func.js");

module.exports = async function (deployer, _network, addresses) {
    await script(deployer, _network, addresses);
    await func.updateLastCompletedMigration();
};

const script = require("../../libs/contracts/upgrade/milton/dai/0001_upgrade.js");
const func = require("../../libs/json_func.js");

module.exports = async function (deployer, _network, addresses) {
    await script(deployer, _network, addresses);
    await func.updateLastCompletedMigration();
};

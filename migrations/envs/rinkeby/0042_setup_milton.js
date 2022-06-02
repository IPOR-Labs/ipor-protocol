const func = require("../../libs/json_func.js");
const script = require("../../libs/contracts/setup/milton/0002_setup_spread_model.js");

module.exports = async function (deployer, _network, addresses) {
    await script(deployer, _network, addresses);
    await func.updateLastCompletedMigration();
};

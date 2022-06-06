const func = require("../../libs/json_func.js");
const script = require("../../libs/contracts/setup/milton/0003_setup_spread_model_v3.js");

module.exports = async function (deployer, _network, addresses) {
    await script(deployer, _network, addresses);
    await func.updateLastCompletedMigration();
};

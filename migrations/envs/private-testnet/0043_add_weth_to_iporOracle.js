const func = require("../../libs/json_func.js");
const script = require("../../libs/contracts/setup/ipor_oracle/0003_add_weth.js");

module.exports = async function (deployer, _network, addresses) {
    await script(deployer, _network, addresses);
	await func.updateLastCompletedMigration();
};

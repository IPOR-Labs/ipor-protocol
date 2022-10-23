require("dotenv").config({ path: "../../../.env" });
const func = require("../../libs/json_func.js");
const script = require("../../libs/contracts/deploy/milton_facade/0002_add_eth.js");
const itfScript = require("../../libs/itf/deploy/milton_facade/0002_add_eth.js");

module.exports = async function (deployer, _network, addresses) {
    if (process.env.ITF_ENABLED === "true") {
        await itfScript(deployer, _network);
    } else {
        await script(deployer, _network);
    }
	await func.updateLastCompletedMigration();
};

require("dotenv").config({ path: "../../../.env" });
const func = require("../../libs/json_func.js");
const keys = require("../../libs/json_keys.js");

module.exports = async function (deployer, _network, addresses) {
    //TODO: FIX it
    if (process.env.ITF_ENABLED === "true") {
        await func.update(keys.ItfStanleyProxyWeth, "0x9f5283ee01Ca781813fdaf50D034816F2a9E2CA9");
        await func.update(keys.ItfStanleyImplWeth, "0x9f5283ee01Ca781813fdaf50D034816F2a9E2CA9");
    } else {
        await func.update(keys.StanleyProxyWeth, "0x9f5283ee01Ca781813fdaf50D034816F2a9E2CA9");
        await func.update(keys.StanleyImplWeth, "0x9f5283ee01Ca781813fdaf50D034816F2a9E2CA9");
    }
	await func.updateLastCompletedMigration();
};

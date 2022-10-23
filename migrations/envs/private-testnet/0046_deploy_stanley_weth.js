require("dotenv").config({ path: "../../../.env" });
const func = require("../../libs/json_func.js");
const keys = require("../../libs/json_keys.js");

module.exports = async function (deployer, _network, addresses) {
    //TODO: FIX it
    if (process.env.ITF_ENABLED === "true") {
        await func.update(keys.ItfStanleyProxyWeth, await func.getValue(keys.ItfStanleyProxyDai));
        await func.update(keys.ItfStanleyImplWeth, await func.getValue(keys.ItfStanleyImplDai));
    } else {
        await func.update(keys.StanleyProxyWeth, await func.getValue(keys.StanleyProxyDai));
        await func.update(keys.StanleyImplWeth, await func.getValue(keys.StanleyImplDai));
    }
    await func.update(keys.ivWETH, "0x9f5283ee01Ca781813fdaf50D034816F2a9E2CA9");
	await func.updateLastCompletedMigration();
};

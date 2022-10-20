require("dotenv").config({ path: "../../../../../.env" });
const keys = require("../../../json_keys.js");
const func = require("../../../json_func.js");

const ItfMiltonWeth = artifacts.require("ItfMiltonWeth");

module.exports = async function (deployer, _network, addresses) {
    const josephWeth = await func.getValue(keys.ItfJosephProxyWeth);
    const stanleyWeth = await func.getValue(keys.ItfStanleyProxyWeth);
    const miltonWeth = await func.getValue(keys.ItfMiltonProxyWeth);

    const miltonWethInstance = await ItfMiltonWeth.at(miltonWeth);


    if (process.env.SC_MIGRATION_INITIAL_PAUSE_FLAG_MILTON == "true") {
        await miltonWethInstance.unpause();
        await miltonWethInstance.setJoseph(josephWeth);
        await miltonWethInstance.setupMaxAllowanceForAsset(josephWeth);
        await miltonWethInstance.setupMaxAllowanceForAsset(stanleyWeth);
        await miltonWethInstance.pause();

    } else {
        await miltonWethInstance.setJoseph(josephWeth);
        await miltonWethInstance.setupMaxAllowanceForAsset(josephWeth);
        await miltonWethInstance.setupMaxAllowanceForAsset(stanleyWeth);
    }
};

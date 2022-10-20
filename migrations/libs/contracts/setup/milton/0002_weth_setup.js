require("dotenv").config({ path: "../../../../../.env" });
const keys = require("../../../json_keys.js");
const func = require("../../../json_func.js");

const MiltonWeth = artifacts.require("MiltonWeth");


module.exports = async function (deployer, _network, addresses) {
    const josephWeth = await func.getValue(keys.JosephProxyWeth);


    const stanleyWeth = await func.getValue(keys.StanleyProxyWeth);


    const miltonWeth = await func.getValue(keys.MiltonProxyWeth);


    const miltonWethInstance = await MiltonWeth.at(miltonWeth);

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

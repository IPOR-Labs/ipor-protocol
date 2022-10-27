require("dotenv").config({ path: "../../../.env" });
const func = require("../../libs/json_func.js");
const keys = require("../../libs/json_keys.js");

module.exports = async function (deployer, _network, addresses) {
    await func.update(keys.Multicall, "0x5ba1e12693dc8f9c48aad8770482f4739beed696");

    await func.updateLastCompletedMigration();
};

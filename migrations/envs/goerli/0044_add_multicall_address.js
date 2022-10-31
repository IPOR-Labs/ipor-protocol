require("dotenv").config({ path: "../../../.env" });
const func = require("../../libs/json_func.js");
const keys = require("../../libs/json_keys.js");

module.exports = async function (deployer, _network, addresses) {
    await func.update(keys.Multicall, "0x5BA1e12693Dc8F9c48aAD8770482f4739bEeD696");
    await func.updateLastCompletedMigration();
};

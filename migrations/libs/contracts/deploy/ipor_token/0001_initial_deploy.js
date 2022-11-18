require("dotenv").config({ path: "../../../../../.env" });
const keys = require("../../../json_keys.js");
const func = require("../../../json_func.js");

module.exports = async function (deployer, _network, addresses, IporToken) {
    if (!process.env.SC_MIGRATION_INITIAL_IPOR_TOKEN_DAO_ADDRESS) {
        throw new Error(
            "Migration stopped! Environment parameter SC_MIGRATION_INITIAL_IPOR_TOKEN_DAO_ADDRESS is not set!"
        );
    }
    await deployer.deploy(
        IporToken,
        "IPOR Token",
        "IPOR",
        process.env.SC_MIGRATION_INITIAL_IPOR_TOKEN_DAO_ADDRESS
    );

    const iporToken = await IporToken.deployed();

    await func.update(keys.IPOR, iporToken.address);
};

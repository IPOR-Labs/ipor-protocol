const keys = require("../../json_keys.js");
const func = require("../../json_func.js");

module.exports = async function (deployer, _network, addresses, Migrations) {
    await deployer.deploy(Migrations);
    const migration = await Migrations.deployed();
    await func.update(keys.Migration, migration.address);
};

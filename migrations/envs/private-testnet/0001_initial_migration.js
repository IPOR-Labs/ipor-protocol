const script = require("../../libs/contracts/deploy/0001_initial_migration.js");

module.exports = async function (deployer, _network, addresses) {
    await script(deployer, _network, addresses);
};

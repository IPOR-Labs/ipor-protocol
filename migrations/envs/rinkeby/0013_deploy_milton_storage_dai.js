const script = require("../../libs/contracts/deploy/milton_storage/dai/0001_initial_deploy.js");

module.exports = async function (deployer, _network) {
    await script(deployer, _network);
};

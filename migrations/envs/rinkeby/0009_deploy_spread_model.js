const script = require("../../libs/contracts/deploy/spread_model/0001_deploy.js");

module.exports = async function (deployer, _network) {
    await script(deployer, _network);
};

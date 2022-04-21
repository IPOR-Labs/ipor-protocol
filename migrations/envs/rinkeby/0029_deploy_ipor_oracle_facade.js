const script = require("../../libs/contracts/deploy/ipor_oracle_facade/0001_deploy.js");

module.exports = async function (deployer, _network) {
    await script(deployer, _network);
};

const script = require("../../libs/contracts/deploy/stanley_strategies/aave/dai/0001_initial_deploy.js");

module.exports = async function (deployer, _network) {
    await script(deployer, _network);
};

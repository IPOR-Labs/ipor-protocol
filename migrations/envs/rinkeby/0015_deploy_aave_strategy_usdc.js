const script = require("../../libs/contracts/deploy/strategy/aave/usdc/0001_deploy.js");

module.exports = async function (deployer, _network) {
    await script(deployer, _network);
};

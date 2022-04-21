var Migrations = artifacts.require("Migrations");

const initial_migration = function (deployer) {
    deployer.deploy(Migrations);
};

module.exports = {
    execute: initial_migration,
};

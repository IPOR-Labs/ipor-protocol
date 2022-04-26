require("dotenv").config({ path: "../../.env" });
const Migrations = artifacts.require("Migrations");

const fs = require("fs");
const editJsonFile = require("edit-json-file");
const keys = require("./json_keys.js");

const iporAddressesFilePath = `${__dirname}/../../.ipor/${process.env.ENV_PROFILE}-${process.env.ETH_BC_NETWORK_NAME}-ipor-addresses.json`;
const lastCompletedMigrationFilePath = `${__dirname}/../../.ipor/${process.env.ENV_PROFILE}-${process.env.ETH_BC_NETWORK_NAME}-last-completed-migration.json`;

const update = async function update(name, value) {
    console.log(`[update] Name: ${name}, value: ${value}`);
    let file = editJsonFile(iporAddressesFilePath);
    file.set(name, value);
    file.save();
    file = editJsonFile(iporAddressesFilePath, {
        autosave: true,
    });
};

const getValue = async function getValue(name) {
    let file = editJsonFile(iporAddressesFilePath);
    const value = file.get(name);
    console.log(`[getValue] Name: ${name}, value: ${value}`);
    return value;
};

const updateLastCompletedMigration = async function updateLastCompletedMigration() {
    let file = editJsonFile(lastCompletedMigrationFilePath);

    const migrationAddress = await getValue(keys.Migration);
    const migrationInstance = await Migrations.at(migrationAddress);
    const lastCompletedMigration = await migrationInstance.last_completed_migration.call();

    //additional +1 because truffle current script is still in progress
    file.set("lastCompletedMigration", Number(lastCompletedMigration) + Number(1));
    file.save();
    file = editJsonFile(lastCompletedMigrationFilePath, {
        autosave: true,
    });
};

module.exports = {
    update: update,
    getValue: getValue,
    updateLastCompletedMigration: updateLastCompletedMigration,
};

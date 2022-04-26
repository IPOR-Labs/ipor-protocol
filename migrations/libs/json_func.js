#!/usr/bin/node

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

const get_value = async function get_value(name) {
    let file = editJsonFile(iporAddressesFilePath);
    const value = file.get(name);
    console.log(`[get_value] Name: ${name}, value: ${value}`);
    return value;
};

const updateLastCompletedMigration = async function updateLastCompletedMigration() {
    let file = editJsonFile(lastCompletedMigrationFilePath);

    const migrationAddress = await get_value(keys.Migration);
    const migrationInstance = await Migrations.at(migrationAddress);
    const lastCompletedMigration = await migrationInstance.last_completed_migration.call();
    console.log("lastCompletedMigration=", lastCompletedMigration);

    file.set("lastCompletedMigration", BigInt(lastCompletedMigration).toString());
    file.save();
    file = editJsonFile(lastCompletedMigrationFilePath, {
        autosave: true,
    });
};

module.exports = {
    update: update,
    get_value: get_value,
    updateLastCompletedMigration: updateLastCompletedMigration,
};

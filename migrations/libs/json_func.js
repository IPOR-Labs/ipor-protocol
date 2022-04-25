#!/usr/bin/node
require("dotenv").config({ path: "../../.env" });
const fs = require("fs");
const editJsonFile = require("edit-json-file");

const iporAddressesFilePath = `${__dirname}/../../.ipor/${process.env.ENV_PROFILE}-${process.env.ETH_BC_NETWORK_NAME}-ipor-addresses.json`;

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

module.exports = {
    update: update,
    get_value: get_value,
};

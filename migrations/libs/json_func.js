#!/usr/bin/node
require("dotenv").config({ path: "../../.env" });
const fs = require("fs");
const editJsonFile = require("edit-json-file");

const update = async function update(name, value) {
    console.log(`[update] Name: ${name}, value: ${value}`);
    let file = editJsonFile(
        `${__dirname}/../../.ipor/${process.env.ENV_PROFILE}-ipor-addresses.json`
    );
    file.set(name, value);
    file.save();
    file = editJsonFile(`${__dirname}/../../.ipor/${process.env.ENV_PROFILE}-ipor-addresses.json`, {
        autosave: true,
    });
};

const get_value = async function get_value(name) {
    let file = editJsonFile(
        `${__dirname}/../../.ipor/${process.env.ENV_PROFILE}-ipor-addresses.json`
    );
    const value = file.get(name);
    console.log(`[get_value] Name: ${name}, value: ${value}`);
    return value;
};

module.exports = {
    update: update,
    get_value: get_value,
};

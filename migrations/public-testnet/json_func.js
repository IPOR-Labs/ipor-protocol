#!/usr/bin/node
const fs = require("fs");
const editJsonFile = require("edit-json-file");

const update = async function update(name, value) {
    console.log(`[update] Name: ${name}, value: ${value}`);
    let file = editJsonFile(`${__dirname}/ipor-addresses.json`);
    file.set(name, value);
    file.save();
    file = editJsonFile(`${__dirname}/ipor-addresses.json`, {
        autosave: true,
    });
};

const get_value = async function get_value(name) {
    console.log(`[get_value] Name: ${name}`);
    let file = editJsonFile(`${__dirname}/ipor-addresses.json`);
    return file.get(name);
};

module.exports = {
    update: update,
    get_value: get_value,
};

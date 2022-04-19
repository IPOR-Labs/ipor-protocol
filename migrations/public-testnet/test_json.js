#!/usr/bin/node
const fs = require("fs");
const editJsonFile = require("edit-json-file");

module.exports = async function update(name, value) {
    console.log(`[update] Name: ${name}, value: ${value}`);
    let file = editJsonFile(`${__dirname}/ipor-addresses.json`);
    file.set(name, value);
    file.save();
    file = editJsonFile(`${__dirname}/ipor-addresses.json`, {
        autosave: true,
    });
};

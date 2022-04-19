#!/usr/bin/node
const fs = require("fs");
const editJsonFile = require("edit-json-file");

// fs.writeFile(fileName, JSON.stringify(file), function writeJSON(err) {
//     if (err) return console.log(err);
//     console.log(JSON.stringify(file));
// });

// module.exports = async function () {
//     console.log("Start...");
//     await update("milton", "add1");
// };

module.exports = async function update(name, value) {
    console.log(`[update] Name: ${name}, value: ${value}`);
    let file = editJsonFile(`${__dirname}/ipor-addresses.json`);
    file.set(name, value);
    file.save();
    file = editJsonFile(`${__dirname}/ipor-addresses.json`, {
        autosave: true,
    });
};

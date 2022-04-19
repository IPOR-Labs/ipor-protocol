require("dotenv").config({ path: "../.env" });
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

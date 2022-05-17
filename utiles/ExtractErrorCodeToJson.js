const fs = require("fs");
const pathToErrorFiles = "./contracts/libraries/errors";

const readFile = (path, errorCodes) => {
    console.info(`Extract error codes from: ${path}`);
    const allFileContents = fs.readFileSync(path, "utf-8");
    allFileContents.split(/\r?\n/).forEach((line) => {
        const trimline = line.trim();
        const elements = trimline.split(" ");
        if (elements[0] === "string") {
            errorCodes[elements[5].substring(1, 9)] = elements[3];
        }
    });
};

const readFiles = (path) => {
    console.info("Read List of error code files");
    return fs.readdirSync(path);
};

const save = (errorCodes) => {
    console.info("Save file with new errors code");
    fs.writeFile("iporErrorList.json", JSON.stringify(errorCodes), (err) => {
        if (err) {
            throw err;
        }
        console.info("JSON data is saved.");
    });
};

const run = async () => {
    const errorCodes = {};
    const files = readFiles(pathToErrorFiles);
    for (let file of files) {
        await readFile(`${pathToErrorFiles}/${file}`, errorCodes);
    }
    save(errorCodes);
};

run();

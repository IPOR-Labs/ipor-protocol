module.exports = {
    tabWidth: 4,
    semi: true,
    singleQuote: false,
    printWidth: 120,
    plugins: ["prettier-plugin-solidity"],
    overrides: [
        {
            files: "*.sol",
            options: {
                parser: "solidity-parse",
                printWidth: 120,
                tabWidth: 4,
                useTabs: false,
                singleQuote: false,
                bracketSpacing: false,
            },
        },
    ],
};

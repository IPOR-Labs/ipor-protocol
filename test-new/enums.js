const { BigNumber } = require("ethers");

function Enum(...options) {
    return Object.fromEntries(
        options.map((key, i) => [key, BigNumber.from(i)])
    );
}

module.exports = {
    Enum,
    DerivativeState: Enum("INACTIVE", "ACTIVE"),
};

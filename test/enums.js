const { BigNumber } = require("ethers");

function Enum(...options) {
    return Object.fromEntries(
        options.map((key, i) => [key, BigNumber.from(i)])
    );
}

module.exports = {
    Enum,
    SwapState: Enum("INACTIVE", "ACTIVE"),
    SwapDirection: Enum(
        "PAY_FIXED_RECEIVE_FLOATING",
        "PAY_FLOATING_RECEIVE_FIXED"
    ),
};

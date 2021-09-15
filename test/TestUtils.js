module.exports.assertError = async (promise, error) => {
    try {
        await promise;
    } catch (e) {
        assert(e.message.includes(error), `Expected exception with message ${error} but actu
        al error message: ${e.message}`)
        return;
    }
    assert(false);
}

module.exports.ZERO = BigInt("0");
module.exports.PERIOD_1_DAY_IN_SECONDS = 60 * 60 * 24 * 1;
module.exports.PERIOD_25_DAYS_IN_SECONDS = 60 * 60 * 24 * 25;
module.exports.PERIOD_28_DAYS_IN_SECONDS = 60 * 60 * 24 * 28;
module.exports.PERIOD_50_DAYS_IN_SECONDS = 60 * 60 * 24 * 50;
module.exports.MILTON_10_USD = BigInt("10000000000000000000");
module.exports.MILTON_20_USD = BigInt("20000000000000000000");
module.exports.MILTON_99__7_USD = BigInt("99700000000000000000")
module.exports.MILTON_10_000_USD = BigInt("10000000000000000000000");
module.exports.MILTON_10_400_USD = BigInt("10400000000000000000000");
module.exports.MILTON_14_000_USD = BigInt("14000000000000000000000");
module.exports.MILTON_10_000_000_USD = BigInt("10000000000000000000000000");
module.exports.MILTON_3_PERCENTAGE = BigInt("30000000000000000");
module.exports.MILTON_5_PERCENTAGE = BigInt("50000000000000000");
module.exports.MILTON_6_PERCENTAGE = BigInt("60000000000000000");
module.exports.MILTON_10_PERCENTAGE = BigInt("100000000000000000");
module.exports.MILTON_20_PERCENTAGE = BigInt("200000000000000000");
module.exports.MILTON_50_PERCENTAGE = BigInt("500000000000000000");
module.exports.MILTON_100_PERCENTAGE = BigInt("1000000000000000000");
module.exports.MILTON_120_PERCENTAGE = BigInt("1200000000000000000");
module.exports.MILTON_160_PERCENTAGE = BigInt("1600000000000000000");
module.exports.MILTON_365_PERCENTAGE = BigInt("3650000000000000000");

module.exports.TOTAL_SUPPLY_6_DECIMALS = BigInt('1000000000000000000000');
module.exports.TOTAL_SUPPLY_18_DECIMALS = BigInt('10000000000000000000000000000000000');
module.exports.USER_SUPPLY_6_DECIMALS = BigInt('10000000000000');

//10.000.000 USD = 10 000 000 000000000000000000 = 10MLN USD
module.exports.USER_SUPPLY_18_DECIMALS = BigInt('10000000000000000000000000');

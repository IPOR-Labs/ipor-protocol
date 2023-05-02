contract BuilderUtils {
    enum IporOracleInitialParamsTestCase {
        /// lastUpdateTimestamp = 1
        /// exponentialMovingAverage = 1
        /// exponentialWeightedMovingVariance = 1
        CASE1
    }

    enum MiltonTestCase {
        DEFAULT, CASE0, CASE6
    }

    enum SpreadModelTestCase{
        DEFAULT, CASE1
    }
    enum AssetType { USDT, USDC, DAI}

}
contract BuilderUtils {
    enum IporOracleInitialParamsTestCase {
        /// @dev lastUpdateTimestamp = 0
        /// @dev exponentialMovingAverage = 0
        /// @dev exponentialWeightedMovingVariance = 0
        DEFAULT,
        /// @dev lastUpdateTimestamp = 1
        /// @dev exponentialMovingAverage = 1
        /// @dev exponentialWeightedMovingVariance = 1
        CASE1,
        /// @dev lastUpdateTimestamp = block.timestamp
        /// @dev exponentialMovingAverage = 8 * 1e16
        /// @dev exponentialWeightedMovingVariance = 0
        CASE2,
        /// @dev lastUpdateTimestamp = block.timestamp
        /// @dev exponentialMovingAverage = 50 * 1e16
        /// @dev exponentialWeightedMovingVariance = 0
        CASE3
    }

    enum MiltonTestCase {
        DEFAULT,
        CASE0,
        CASE6
    }

    enum SpreadModelTestCase {
        DEFAULT,
        CASE1
    }
    enum AssetType {
        USDT,
        USDC,
        DAI
    }
}

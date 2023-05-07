contract BuilderUtils {
    enum IporOracleInitialParamsTestCase {
        /// @dev lastUpdateTimestamp = block.timestamp
        /// @dev exponentialMovingAverage = 3 * 1e16
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
        CASE3,
        /// @dev lastUpdateTimestamp = block.timestamp
        /// @dev exponentialMovingAverage = 120 * 1e16
        /// @dev exponentialWeightedMovingVariance = 0
        CASE4,
        /// @dev lastUpdateTimestamp = block.timestamp
        /// @dev exponentialMovingAverage = 5 * 1e16
        /// @dev exponentialWeightedMovingVariance = 0
        CASE5,
        /// @dev lastUpdateTimestamp = block.timestamp
        /// @dev exponentialMovingAverage = 160 * 1e16
        /// @dev exponentialWeightedMovingVariance = 0
        CASE6,
        /// @dev lastUpdateTimestamp = block.timestamp
        /// @dev exponentialMovingAverage = 0
        /// @dev exponentialWeightedMovingVariance = 0
        CASE7,
        /// @dev lastUpdateTimestamp = block.timestamp
        /// @dev exponentialMovingAverage = 6 * 1e16
        /// @dev exponentialWeightedMovingVariance = 0
        CASE8,
        /// @dev lastUpdateTimestamp = block.timestamp
        /// @dev exponentialMovingAverage = 150 * 1e16
        /// @dev exponentialWeightedMovingVariance = 0
        CASE9
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

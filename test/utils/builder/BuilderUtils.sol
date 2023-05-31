// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.16;
import "../../../contracts/mocks/tokens/MockTestnetToken.sol";
import "../../../contracts/tokens/IpToken.sol";
import "../../../contracts/tokens/IvToken.sol";
import "../../../contracts/itf/ItfIporOracle.sol";
import "../../../contracts/oracles/IporRiskManagementOracle.sol";
import "../../../contracts/mocks/MockIporWeighted.sol";
import "../../../contracts/amm/AmmStorage.sol";
import "../../../contracts/amm/AmmTreasury.sol";
import "../../../contracts/amm/spread/SpreadRouter.sol";
import "../../../contracts/itf/ItfAssetManagement.sol";
import "../../../contracts/router/IporProtocolRouter.sol";
import "../../mocks/MockSpreadXDays.sol";

contract BuilderUtils {
    struct IporProtocol {
        IporProtocolRouter router;
        IAmmSwapsLens ammSwapsLens;
        IAmmPoolsService ammPoolsService;
        IAmmPoolsLens ammPoolsLens;
        IAmmOpenSwapService ammOpenSwapService;
        IAmmCloseSwapService ammCloseSwapService;
        IAmmGovernanceService ammGovernanceService;
        MockTestnetToken asset;
        IpToken ipToken;
        IvToken ivToken;
        ItfIporOracle iporOracle;
        IporRiskManagementOracle iporRiskManagementOracle;
        MockIporWeighted iporWeighted;
        AmmStorage ammStorage;
        SpreadRouter spreadRouter;
        ItfAssetManagement assetManagement;
        AmmTreasury ammTreasury;
    }

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

    enum IporRiskManagementOracleInitialParamsTestCase {
        /// @dev Utilization rate per leg 48%
        /// @dev Max utilization rate 90%
        /// @dev Max notional 1 000 000
        DEFAULT,
        /// @dev Utilization rate per leg 0%
        /// @dev Max utilization rate 0%
        /// @dev Max notional 1 000 000
        CASE1,
        /// @dev Utilization rate per leg 20%
        /// @dev Max utilization rate 20%
        /// @dev Max notional 0
        CASE2,
        /// @dev Utilization rate per leg 20%
        /// @dev Max utilization rate 20%
        /// @dev Max notional max uint64
        CASE3,
        /// @dev Utilization rate per leg max uint16
        /// @dev Max utilization rate max uint16
        /// @dev Max notional max uint64
        CASE4,
        /// @dev Utilization rate per leg 30%
        /// @dev Max utilization rate 80%
        /// @dev Max notional 1 000 000
        CASE5,
        /// @dev Utilization rate per leg 48%
        /// @dev Max utilization rate 80%
        /// @dev Max notional 1 000 000
        CASE6
    }
    enum AmmOpenSwapServiceTestCase {
        DEFAULT,
        CASE1
    }

    enum AmmCloseSwapServiceTestCase {
        DEFAULT,
        CASE1
    }

    enum AmmPoolsServiceTestCase {
        DEFAULT,
        CASE1
    }

    enum AmmTreasuryTestCase {
        DEFAULT,
        CASE0,
        CASE1,
        CASE2,
        CASE3,
        CASE4,
        CASE5,
        CASE6,
        CASE7,
        CASE8
    }

    enum Spread28DaysTestCase {
        DEFAULT,
        /// @dev Pay Fixed Quote Value 0%
        /// @dev Receive Fixed Quote Value 0%
        CASE0,
        /// @dev Pay Fixed Quote Value 4%
        /// @dev Receive Fixed Quote Value 0%
        CASE1,
        /// @dev Pay Fixed Quote Value 0%
        /// @dev Receive Fixed Quote Value 2%
        CASE2,
        /// @dev Pay Fixed Quote Value 6%
        /// @dev Receive Fixed Quote Value 0%
        CASE3,
        /// @dev Pay Fixed Quote Value 2%
        /// @dev Receive Fixed Quote Value 0%
        CASE4,
        /// @dev Pay Fixed Quote Value 4%
        /// @dev Receive Fixed Quote Value 2%
        CASE5,
        /// @dev Pay Fixed Quote Value in 18 decimals: 41683900567904584
        /// @dev Receive Fixed Quote Value 0%
        CASE6,
        /// @dev Pay Fixed Quote Value 0%
        /// @dev Receive Fixed Quote Value in 18 decimals: 38877399621396944
        CASE7,
        /// @dev Pay Fixed Quote Value 0%
        /// @dev Receive Fixed Quote Value 7%
        CASE8,
        /// @dev Pay Fixed Quote Value 0%
        /// @dev Receive Fixed Quote Value 49%
        CASE9,
        /// @dev Pay Fixed Quote Value 51%
        /// @dev Receive Fixed Quote Value 0%
        CASE10
    }

    enum Spread60DaysTestCase {
        DEFAULT,
        CASE1
    }

    enum Spread90DaysTestCase {
        DEFAULT,
        CASE1
    }

    enum AssetType {
        USDT,
        USDC,
        DAI
    }
}

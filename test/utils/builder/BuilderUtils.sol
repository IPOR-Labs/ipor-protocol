// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.20;
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
        IAmmGovernanceLens ammGovernanceLens;
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
        ILiquidityMiningLens liquidityMiningLens;
        IPowerTokenLens powerTokenLens;
        IPowerTokenFlowsService flowService;
        IPowerTokenStakeService stakeService;
    }

    struct LiquidityMiningLensData {
        bytes32 contractId;
        uint256 balanceOf;
    }

    struct PowerTokenLensData {
        string name;
        bytes32 contractId;
        string symbol;
        uint8 decimals;
        uint256 totalSupply;
        uint256 balanceOf;
        uint256 delegatedPowerTokensToLiquidityMiningBalanceOf;
        uint256 getUnstakeWithoutCooldownFee;
        uint256 unstakeWithoutCooldownFee;
        PowerTokenTypes.PwTokenCooldown activeCooldown;
        uint256 coolDownInSeconds;
        uint256 exchangeRate;
        uint256 totalSupplyBase;
    }

    enum IporOracleInitialParamsTestCase {
        /// @dev lastUpdateTimestamp = block.timestamp
        DEFAULT,
        /// @dev lastUpdateTimestamp = 1
        CASE1
    }

    enum IporRiskManagementOracleInitialParamsTestCase {
        /// @dev collateral ratio per leg 48%
        /// @dev Max collateral ratio 90%
        /// @dev Max notional 1 000 000
        DEFAULT,
        /// @dev collateral ratio per leg 0%
        /// @dev Max collateral ratio 0%
        /// @dev Max notional 1 000 000
        CASE1,
        /// @dev collateral ratio per leg 20%
        /// @dev Max collateral ratio 20%
        /// @dev Max notional 0
        CASE2,
        /// @dev collateral ratio per leg 20%
        /// @dev Max collateral ratio 20%
        /// @dev Max notional max uint64
        CASE3,
        /// @dev collateral ratio per leg max uint16
        /// @dev Max collateral ratio max uint16
        /// @dev Max notional max uint64
        CASE4,
        /// @dev collateral ratio per leg 30%
        /// @dev Max collateral ratio 80%
        /// @dev Max notional 1 000 000
        CASE5,
        /// @dev collateral ratio per leg 48%
        /// @dev Max collateral ratio 80%
        /// @dev Max notional 1 000 000
        CASE6
    }
    enum AmmOpenSwapServiceTestCase {
        DEFAULT,
        CASE1,
        CASE2,
        CASE3
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
        /// @dev Real calculation
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

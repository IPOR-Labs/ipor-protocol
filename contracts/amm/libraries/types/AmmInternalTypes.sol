// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.20;

import "contracts/interfaces/types/IporTypes.sol";
import "contracts/interfaces/types/AmmTypes.sol";

/// @notice The types used in the AmmTreasury's interface.
/// @dev All values, where applicable, are represented in 18 decimals.
library AmmInternalTypes {
    struct BeforeOpenSwapStruct {
        /// @notice Sum of all asset transfered when opening swap. It includes the collateral, fees and desposits.
        /// @dev The amount is represented in 18 decimals regardless of the decimals of the asset.
        uint256 wadTotalAmount;
        /// @notice Swap's collateral.
        uint256 collateral;
        /// @notice Swap's notional amount.
        uint256 notional;
        /// @notice The part of the opening fee that will be added to the liquidity pool balance.
        uint256 openingFeeLPAmount;
        /// @notice Part of the opening fee that will be added to the treasury balance.
        uint256 openingFeeTreasuryAmount;
        /// @notice Amount of asset set aside for the oracle subsidization.
        uint256 iporPublicationFeeAmount;
        /// @notice Refundable deposit blocked for the entity that will close the swap.
        /// For more information on how the liquidations work refer to the documentation.
        /// https://ipor-labs.gitbook.io/ipor-labs/automated-market-maker/liquidations
        /// @dev value represented without decimals, as an integer
        uint256 liquidationDepositAmount;
        /// @notice The struct describing the IPOR and its params calculated for the time when it was most recently updated and the change that took place since the update.
        /// Namely, the interest that would be computed into IBT should the rebalance occur.
        IporTypes.AccruedIpor accruedIpor;
    }

    struct RiskIndicatorsContext {
        address asset;
        address iporRiskManagementOracle;
        IporTypes.SwapTenor tenor;
        uint256 liquidityPoolBalance;
        uint256 minLeverage;
    }

    struct SpreadContext {
        address asset;
        bytes4 spreadFunctionSig;
        IporTypes.SwapTenor tenor;
        uint256 notional;
        uint256 minLeverage;
        uint256 indexValue;
        AmmTypes.OpenSwapRiskIndicators riskIndicators;
        IporTypes.AmmBalancesForOpenSwapMemory balance;
    }

    struct OpenSwapItem {
        uint32 swapId;
        uint32 nextSwapId;
        uint32 previousSwapId;
        uint32 openSwapTimestamp;
    }

    struct OpenSwapList {
        uint32 headSwapId;
        mapping(uint32 => OpenSwapItem) swaps;
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.20;

import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";

import "../interfaces/types/IporTypes.sol";
import "../interfaces/types/AmmTypes.sol";
import "../interfaces/IIporOracle.sol";
import "../interfaces/IAmmCloseSwapLens.sol";
import "../interfaces/IAmmCloseSwapServiceStable.sol";
import "../libraries/errors/IporErrors.sol";
import "../libraries/IporContractValidator.sol";
import "./libraries/SwapCloseLogicLib.sol";
import "../base/amm/libraries/SwapLogicBaseV1.sol";
import "../base/types/AmmTypesBaseV1.sol";
import "../base/amm/libraries/SwapCloseLogicLibBaseV1.sol";

/// @dev It is not recommended to use service contract directly, should be used only through IporProtocolRouter.
contract AmmCloseSwapLens is IAmmCloseSwapLens {
    using Address for address;
    using IporContractValidator for address;

    address public immutable usdt;
    address public immutable usdc;
    address public immutable dai;

    address public immutable iporOracle;
    address public immutable messageSigner;
    address public immutable spreadRouter;

    address public immutable closeSwapServiceUsdt;
    address public immutable closeSwapServiceUsdc;
    address public immutable closeSwapServiceDai;

    constructor(
        address usdtInput,
        address usdcInput,
        address daiInput,
        address iporOracleInput,
        address messageSignerInput,
        address spreadRouterInput,
        address closeSwapServiceUsdtInput,
        address closeSwapServiceUsdcInput,
        address closeSwapServiceDaiInput
    ) {
        usdt = usdtInput.checkAddress();
        usdc = usdcInput.checkAddress();
        dai = daiInput.checkAddress();

        iporOracle = iporOracleInput.checkAddress();
        messageSigner = messageSignerInput.checkAddress();
        spreadRouter = spreadRouterInput.checkAddress();

        closeSwapServiceUsdt = closeSwapServiceUsdtInput.checkAddress();
        closeSwapServiceUsdc = closeSwapServiceUsdcInput.checkAddress();
        closeSwapServiceDai = closeSwapServiceDaiInput.checkAddress();
    }

    function getAmmCloseSwapServicePoolConfiguration(
        address asset
    ) external view override returns (AmmCloseSwapServicePoolConfiguration memory) {
        return _getPoolConfiguration(asset);
    }

    function _getPoolConfiguration(address asset) internal view returns (AmmCloseSwapServicePoolConfiguration memory) {
        if (asset == usdt) {
            return IAmmCloseSwapServiceStable(closeSwapServiceUsdt).getPoolConfiguration();
        } else if (asset == usdc) {
            return IAmmCloseSwapServiceStable(closeSwapServiceUsdc).getPoolConfiguration();
        } else if (asset == dai) {
            return IAmmCloseSwapServiceStable(closeSwapServiceDai).getPoolConfiguration();
        } else {
            revert IporErrors.UnsupportedAsset(IporErrors.ASSET_NOT_SUPPORTED, asset);
        }
    }

    function getClosingSwapDetails(
        address asset,
        address account,
        AmmTypes.SwapDirection direction,
        uint256 swapId,
        uint256 closeTimestamp,
        AmmTypes.CloseSwapRiskIndicatorsInput memory riskIndicatorsInput
    ) external view override returns (AmmTypes.ClosingSwapDetails memory closingSwapDetails) {
        AmmCloseSwapServicePoolConfiguration memory poolCfg = _getPoolConfiguration(asset);

        IporTypes.AccruedIpor memory accruedIpor = IIporOracle(iporOracle).getAccruedIndex(
            block.timestamp,
            poolCfg.asset
        );

        AmmTypes.Swap memory swap = IAmmStorage(poolCfg.ammStorage).getSwap(direction, swapId);

        require(swap.id > 0, AmmErrors.INCORRECT_SWAP_ID);

        int256 swapPnlValueToDate;

        if (direction == AmmTypes.SwapDirection.PAY_FIXED_RECEIVE_FLOATING) {
            swapPnlValueToDate = SwapLogicBaseV1.calculatePnlPayFixed(
                swap.openTimestamp,
                swap.collateral,
                swap.notional,
                swap.fixedInterestRate,
                swap.ibtQuantity,
                block.timestamp,
                accruedIpor.ibtPrice
            );
        } else if (direction == AmmTypes.SwapDirection.PAY_FLOATING_RECEIVE_FIXED) {
            swapPnlValueToDate = SwapLogicBaseV1.calculatePnlReceiveFixed(
                swap.openTimestamp,
                swap.collateral,
                swap.notional,
                swap.fixedInterestRate,
                swap.ibtQuantity,
                block.timestamp,
                accruedIpor.ibtPrice
            );
        } else {
            revert(AmmErrors.UNSUPPORTED_DIRECTION);
        }

        (closingSwapDetails.closableStatus, closingSwapDetails.swapUnwindRequired) = SwapCloseLogicLibBaseV1
            .getClosableStatusForSwap(
                AmmTypesBaseV1.ClosableSwapInput({
                    account: account,
                    asset: poolCfg.asset,
                    closeTimestamp: closeTimestamp,
                    swapBuyer: swap.buyer,
                    swapOpenTimestamp: swap.openTimestamp,
                    swapCollateral: swap.collateral,
                    swapTenor: swap.tenor,
                    swapState: swap.state,
                    swapPnlValueToDate: swapPnlValueToDate,
                    minLiquidationThresholdToCloseBeforeMaturityByCommunity: poolCfg
                        .minLiquidationThresholdToCloseBeforeMaturityByCommunity,
                    minLiquidationThresholdToCloseBeforeMaturityByBuyer: poolCfg
                        .minLiquidationThresholdToCloseBeforeMaturityByBuyer,
                    timeBeforeMaturityAllowedToCloseSwapByCommunity: poolCfg
                        .timeBeforeMaturityAllowedToCloseSwapByCommunity,
                    timeBeforeMaturityAllowedToCloseSwapByBuyer: poolCfg.timeBeforeMaturityAllowedToCloseSwapByBuyer,
                    timeAfterOpenAllowedToCloseSwapWithUnwinding: poolCfg.timeAfterOpenAllowedToCloseSwapWithUnwinding
                })
            );

        if (closingSwapDetails.swapUnwindRequired == true) {
            (
                closingSwapDetails.swapUnwindPnlValue,
                closingSwapDetails.swapUnwindOpeningFeeAmount,
                closingSwapDetails.swapUnwindFeeLPAmount,
                closingSwapDetails.swapUnwindFeeTreasuryAmount,
                closingSwapDetails.pnlValue
            ) = SwapCloseLogicLib.calculateSwapUnwindWhenUnwindRequired(
                AmmTypes.UnwindParams({
                    messageSigner: messageSigner,
                    spreadRouter: spreadRouter,
                    ammStorage: poolCfg.ammStorage,
                    ammTreasury: poolCfg.ammTreasury,
                    direction: direction,
                    closeTimestamp: closeTimestamp,
                    swapPnlValueToDate: swapPnlValueToDate,
                    indexValue: accruedIpor.indexValue,
                    swap: swap,
                    poolCfg: poolCfg,
                    riskIndicatorsInputs: riskIndicatorsInput
                })
            );
        } else {
            closingSwapDetails.pnlValue = swapPnlValueToDate;
        }
    }
}

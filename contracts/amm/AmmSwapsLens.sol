// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.20;

import "@openzeppelin/contracts/utils/Address.sol";
import "../interfaces/IAmmSwapsLens.sol";
import "./libraries/IporSwapLogic.sol";
import "../libraries/AmmLib.sol";
import "../interfaces/IAmmOpenSwapService.sol";
import "../amm/spread/ISpread28DaysLens.sol";
import "../amm/spread/ISpread60DaysLens.sol";
import "../amm/spread/ISpread90DaysLens.sol";
import "../libraries/RiskManagementLogic.sol";

contract AmmSwapsLens is IAmmSwapsLens {
    using Address for address;
    using IporSwapLogic for AmmTypes.Swap;
    using AmmLib for AmmTypes.AmmPoolCoreModel;
    using AmmLib for AmmInternalTypes.RiskIndicatorsContext;

    address internal immutable _usdtAsset;
    address internal immutable _usdtAmmStorage;
    address internal immutable _usdtAmmTreasury;
    uint256 internal immutable _usdtMinLeverage;

    address internal immutable _usdcAsset;
    address internal immutable _usdcAmmStorage;
    address internal immutable _usdcAmmTreasury;
    uint256 internal immutable _usdcMinLeverage;

    address internal immutable _daiAsset;
    address internal immutable _daiAmmStorage;
    address internal immutable _daiAmmTreasury;
    uint256 internal immutable _daiMinLeverage;

    address internal immutable _iporOracle;
    address internal immutable _riskManagementOracle;

    address internal immutable _spreadRouter;

    constructor(
        SwapLensPoolConfiguration memory usdtCfg,
        SwapLensPoolConfiguration memory usdcCfg,
        SwapLensPoolConfiguration memory daiCfg,
        address iporOracle,
        address riskManagementOracle,
        address spreadRouter
    ) {
        require(
            usdtCfg.asset != address(0),
            string.concat(IporErrors.WRONG_ADDRESS, " USDT asset address cannot be 0")
        );
        require(
            usdtCfg.ammStorage != address(0),
            string.concat(IporErrors.WRONG_ADDRESS, " USDT ammStorage address cannot be 0")
        );
        require(
            usdtCfg.ammTreasury != address(0),
            string.concat(IporErrors.WRONG_ADDRESS, " USDT ammTreasury address cannot be 0")
        );

        require(
            usdcCfg.asset != address(0),
            string.concat(IporErrors.WRONG_ADDRESS, " USDC asset address cannot be 0")
        );
        require(
            usdcCfg.ammStorage != address(0),
            string.concat(IporErrors.WRONG_ADDRESS, " USDC ammStorage address cannot be 0")
        );
        require(
            usdcCfg.ammTreasury != address(0),
            string.concat(IporErrors.WRONG_ADDRESS, " USDC ammTreasury address cannot be 0")
        );

        require(daiCfg.asset != address(0), string.concat(IporErrors.WRONG_ADDRESS, " DAI asset address cannot be 0"));
        require(
            daiCfg.ammStorage != address(0),
            string.concat(IporErrors.WRONG_ADDRESS, " DAI ammStorage address cannot be 0")
        );
        require(
            daiCfg.ammTreasury != address(0),
            string.concat(IporErrors.WRONG_ADDRESS, " DAI ammTreasury address cannot be 0")
        );
        require(
            address(iporOracle) != address(0),
            string.concat(IporErrors.WRONG_ADDRESS, " iporOracle address cannot be 0")
        );
        require(
            riskManagementOracle != address(0),
            string.concat(IporErrors.WRONG_ADDRESS, " riskManagementOracle address cannot be 0")
        );

        require(
            spreadRouter != address(0),
            string.concat(IporErrors.WRONG_ADDRESS, " spreadRouter address cannot be 0")
        );


        _usdtAsset = usdtCfg.asset;
        _usdtAmmStorage = usdtCfg.ammStorage;
        _usdtAmmTreasury = usdtCfg.ammTreasury;
        _usdtMinLeverage = usdtCfg.minLeverage;

        _usdcAsset = usdcCfg.asset;
        _usdcAmmStorage = usdcCfg.ammStorage;
        _usdcAmmTreasury = usdcCfg.ammTreasury;
        _usdcMinLeverage = usdcCfg.minLeverage;

        _daiAsset = daiCfg.asset;
        _daiAmmStorage = daiCfg.ammStorage;
        _daiAmmTreasury = daiCfg.ammTreasury;
        _daiMinLeverage = daiCfg.minLeverage;

        _iporOracle = iporOracle;
        _riskManagementOracle = riskManagementOracle;
        _spreadRouter = spreadRouter;
    }

    function getSwapLensPoolConfiguration(address asset) external view returns (SwapLensPoolConfiguration memory) {
        return _getSwapLensPoolConfiguration(asset);
        _spreadRouter = spreadRouter;
    }

    function getSwaps(
        address asset,
        address account,
        uint256 offset,
        uint256 chunkSize
    ) external view returns (uint256 totalCount, IAmmSwapsLens.IporSwap[] memory swaps) {
        IAmmStorage ammStorage = _getAmmStorage(asset);
        (uint256 count, AmmStorageTypes.IporSwapId[] memory swapIds) = ammStorage.getSwapIds(
            account,
            offset,
            chunkSize
        );
        return (count, _mapSwaps(asset, ammStorage, swapIds));
    }

    function getPayoffPayFixed(address asset, uint256 swapId) external view override returns (int256) {
        IAmmStorage ammStorage = _getAmmStorage(asset);
        AmmTypes.Swap memory swap = ammStorage.getSwap(AmmTypes.SwapDirection.PAY_FIXED_RECEIVE_FLOATING, swapId);
        uint256 accruedIbtPrice = IIporOracle(_iporOracle).calculateAccruedIbtPrice(asset, block.timestamp);
        return swap.calculatePayoffPayFixed(block.timestamp, accruedIbtPrice);
    }

    function getPayoffReceiveFixed(address asset, uint256 swapId) external view override returns (int256) {
        IAmmStorage ammStorage = _getAmmStorage(asset);
        AmmTypes.Swap memory swap = ammStorage.getSwap(AmmTypes.SwapDirection.PAY_FLOATING_RECEIVE_FIXED, swapId);
        uint256 accruedIbtPrice = IIporOracle(_iporOracle).calculateAccruedIbtPrice(asset, block.timestamp);
        return swap.calculatePayoffReceiveFixed(block.timestamp, accruedIbtPrice);
    }

    function getSOAP(
        address asset
    ) external view override returns (int256 soapPayFixed, int256 soapReceiveFixed, int256 soap) {
        IAmmStorage ammStorage = _getAmmStorage(asset);
        AmmTypes.AmmPoolCoreModel memory ammCoreModel;
        ammCoreModel.asset = asset;
        ammCoreModel.ammStorage = address(ammStorage);
        ammCoreModel.iporOracle = _iporOracle;
        (soapPayFixed, soapReceiveFixed, soap) = ammCoreModel.getSOAP();
    }

    function getOfferedRate(
        address asset,
        IporTypes.SwapTenor tenor,
        uint256 notional
    ) external override returns (uint256 offeredRatePayFixed, uint256 offeredRateReceiveFixed) {
        require(notional > 0, AmmErrors.INVALID_NOTIONAL);

        SwapLensPoolConfiguration memory poolCfg = _getSwapLensPoolConfiguration(asset);

        (bytes4 payFixedSig, bytes4 receiveFixedSig) = _getSpreadRouterSignatures(tenor);
        (uint256 indexValue,,) = IIporOracle(_iporOracle).getIndex(asset);
        IporTypes.AmmBalancesForOpenSwapMemory memory balance = IAmmStorage(poolCfg.ammStorage)
            .getBalancesForOpenSwap();

        AmmInternalTypes.OpenSwapRiskIndicators memory riskIndicatorsPayFixed = _getRiskIndicators(
            asset,
            tenor,
            balance.liquidityPool,
            poolCfg.minLeverage,
            0
        );
        AmmInternalTypes.SpreadContext memory spreadContextPayFixed;
        spreadContextPayFixed.asset = asset;
        spreadContextPayFixed.spreadFunctionSig = payFixedSig;
        spreadContextPayFixed.tenor = tenor;
        spreadContextPayFixed.notional = notional;
        spreadContextPayFixed.minLeverage = poolCfg.minLeverage;
        spreadContextPayFixed.indexValue = indexValue;
        spreadContextPayFixed.riskIndicators = riskIndicatorsPayFixed;
        spreadContextPayFixed.balance = balance;
        offeredRatePayFixed = _getOfferedRatePerLeg(spreadContextPayFixed);

        AmmInternalTypes.OpenSwapRiskIndicators memory riskIndicatorsReceiveFixed = _getRiskIndicators(
            asset,
            tenor,
            balance.liquidityPool,
            poolCfg.minLeverage,
            1
        );
        AmmInternalTypes.SpreadContext memory spreadContextReceiveFixed;
        spreadContextReceiveFixed.asset = asset;
        spreadContextReceiveFixed.spreadFunctionSig = receiveFixedSig;
        spreadContextReceiveFixed.tenor = tenor;
        spreadContextReceiveFixed.notional = notional;
        spreadContextReceiveFixed.minLeverage = poolCfg.minLeverage;
        spreadContextReceiveFixed.indexValue = indexValue;
        spreadContextReceiveFixed.riskIndicators = riskIndicatorsReceiveFixed;
        spreadContextReceiveFixed.balance = balance;
        offeredRateReceiveFixed = _getOfferedRatePerLeg(spreadContextReceiveFixed);
    }

    function _getOfferedRatePerLeg(
        AmmInternalTypes.SpreadContext memory spreadContext
    ) internal returns (uint256 offeredRate) {
        offeredRate = abi.decode(
            _spreadRouter.functionCall(
                abi.encodeWithSelector(
                    spreadContext.spreadFunctionSig,
                    spreadContext.asset,
                    spreadContext.notional,
                    spreadContext.riskIndicators.maxLeveragePerLeg,
                    spreadContext.riskIndicators.maxCollateralRatioPerLeg,
                    spreadContext.riskIndicators.spread,
                    spreadContext.balance.totalCollateralPayFixed,
                    spreadContext.balance.totalCollateralReceiveFixed,
                    spreadContext.balance.liquidityPool,
                    spreadContext.balance.totalNotionalPayFixed,
                    spreadContext.balance.totalNotionalReceiveFixed,
                    spreadContext.indexValue,
                    spreadContext.riskIndicators.fixedRateCap
                )
            ),
            (uint256)
        );
    }

    function _getRiskIndicators(
        address asset,
        IporTypes.SwapTenor tenor,
        uint256 liquidityPoolBalance,
        uint256 minLeverage,
        uint256 direction
    ) internal returns (AmmInternalTypes.OpenSwapRiskIndicators memory riskIndicators) {
        AmmInternalTypes.RiskIndicatorsContext memory riskIndicatorsContext;

        riskIndicatorsContext.asset = asset;
        riskIndicatorsContext.iporRiskManagementOracle = _riskManagementOracle;
        riskIndicatorsContext.tenor = tenor;
        riskIndicatorsContext.liquidityPoolBalance = liquidityPoolBalance;
        riskIndicatorsContext.minLeverage = minLeverage;

        riskIndicators = riskIndicatorsContext.getRiskIndicators(direction);
    }

    function getBalancesForOpenSwap(
        address asset
    ) external view returns (IporTypes.AmmBalancesForOpenSwapMemory memory) {
        IAmmStorage ammStorage = _getAmmStorage(asset);
        return ammStorage.getBalancesForOpenSwap();
    }

    function getOpenSwapRiskIndicators(
        address asset,
        uint256 direction,
        IporTypes.SwapTenor tenor
    ) external view override returns (AmmTypes.OpenSwapRiskIndicators memory riskIndicators) {
        SwapLensPoolConfiguration memory swapLensPoolCfg = _getSwapLensPoolConfiguration(asset);

        IporTypes.AmmBalancesForOpenSwapMemory memory balances = IAmmStorage(swapLensPoolCfg.ammStorage)
            .getBalancesForOpenSwap();

        riskIndicators = RiskManagementLogic.getRiskIndicators(
            asset,
            direction,
            tenor,
            balances.liquidityPool,
            swapLensPoolCfg.minLeverage,
            _riskManagementOracle
        );
    }

    function _mapSwaps(
        address asset,
        IAmmStorage ammStorage,
        AmmStorageTypes.IporSwapId[] memory swapIds
    ) internal view returns (IAmmSwapsLens.IporSwap[] memory swaps) {
        uint256 accruedIbtPrice = IIporOracle(_iporOracle).calculateAccruedIbtPrice(asset, block.timestamp);
        uint256 swapCount = swapIds.length;
        IAmmSwapsLens.IporSwap[] memory mappedSwaps = new IAmmSwapsLens.IporSwap[](swapCount);
        for (uint256 i; i != swapCount; ) {
            AmmStorageTypes.IporSwapId memory swapId = swapIds[i];
            if (swapId.direction == 0) {
                AmmTypes.Swap memory swap = ammStorage.getSwap(
                    AmmTypes.SwapDirection.PAY_FIXED_RECEIVE_FLOATING,
                    swapId.id
                );
                int256 swapValue = swap.calculatePayoffPayFixed(block.timestamp, accruedIbtPrice);
                mappedSwaps[i] = _mapSwap(asset, swap, 0, swapValue);
            } else {
                AmmTypes.Swap memory swap = ammStorage.getSwap(
                    AmmTypes.SwapDirection.PAY_FLOATING_RECEIVE_FIXED,
                    swapId.id
                );
                int256 swapValue = swap.calculatePayoffReceiveFixed(block.timestamp, accruedIbtPrice);
                mappedSwaps[i] = _mapSwap(asset, swap, 1, swapValue);
            }
            unchecked {
                ++i;
            }
        }
        return mappedSwaps;
    }

    function _mapSwap(
        address asset,
        AmmTypes.Swap memory swap,
        uint256 direction,
        int256 swapValue
    ) internal pure returns (IAmmSwapsLens.IporSwap memory) {
        return
            IAmmSwapsLens.IporSwap({
                id: swap.id,
                asset: asset,
                buyer: swap.buyer,
                collateral: swap.collateral,
                notional: swap.notional,
                leverage: IporMath.division(swap.notional * 1e18, swap.collateral),
                direction: direction,
                ibtQuantity: swap.ibtQuantity,
                fixedInterestRate: swap.fixedInterestRate,
                payoff: swapValue,
                openTimestamp: swap.openTimestamp,
                endTimestamp: swap.getSwapEndTimestamp(),
                liquidationDepositAmount: swap.liquidationDepositAmount,
                state: uint256(swap.state)
            });
    }

    function _getAmmStorage(address asset) internal view returns (IAmmStorage ammStorage) {
        if (asset == _usdtAsset) {
            return IAmmStorage(_usdtAmmStorage);
        } else if (asset == _usdcAsset) {
            return IAmmStorage(_usdcAmmStorage);
        } else if (asset == _daiAsset) {
            return IAmmStorage(_daiAmmStorage);
        } else {
            revert(IporErrors.ASSET_NOT_SUPPORTED);
        }
    }

    function _getSwapLensPoolConfiguration(address asset) internal view returns (SwapLensPoolConfiguration memory) {
        if (asset == _usdtAsset) {
            return
                SwapLensPoolConfiguration({
                    asset: _usdtAsset,
                    ammStorage: _usdtAmmStorage,
                    ammTreasury: _usdtAmmTreasury,
                    minLeverage: _usdtMinLeverage
                });
        } else if (asset == _usdcAsset) {
            return
                SwapLensPoolConfiguration({
                    asset: _usdcAsset,
                    ammStorage: _usdcAmmStorage,
                    ammTreasury: _usdcAmmTreasury,
                    minLeverage: _usdcMinLeverage
                });
        } else if (asset == _daiAsset) {
            return
                SwapLensPoolConfiguration({
                    asset: _daiAsset,
                    ammStorage: _daiAmmStorage,
                    ammTreasury: _daiAmmTreasury,
                    minLeverage: _daiMinLeverage
                });
        } else {
            revert(IporErrors.ASSET_NOT_SUPPORTED);
        }
    }

    function _getSpreadRouterSignatures(
        IporTypes.SwapTenor tenor
    ) internal view returns (bytes4 payFixedSig, bytes4 receiveFixedSig) {
        if (tenor == IporTypes.SwapTenor.DAYS_28) {
            payFixedSig = ISpread28DaysLens.calculateOfferedRatePayFixed28Days.selector;
            receiveFixedSig = ISpread28DaysLens.calculateOfferedRateReceiveFixed28Days.selector;
        } else if (tenor == IporTypes.SwapTenor.DAYS_60) {
            payFixedSig = ISpread60DaysLens.calculateOfferedRatePayFixed60Days.selector;
            receiveFixedSig = ISpread60DaysLens.calculateOfferedRateReceiveFixed60Days.selector;
        } else if (tenor == IporTypes.SwapTenor.DAYS_90) {
            payFixedSig = ISpread90DaysLens.calculateOfferedRatePayFixed90Days.selector;
            receiveFixedSig = ISpread90DaysLens.calculateOfferedRateReceiveFixed90Days.selector;
        } else {
            revert(AmmErrors.UNSUPPORTED_SWAP_TENOR);
        }
    }
}

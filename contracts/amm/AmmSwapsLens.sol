// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.20;

import "@openzeppelin/contracts/utils/Address.sol";
import "../interfaces/IAmmSwapsLens.sol";
import "../libraries/IporContractValidator.sol";
import "./spread/ISpread28DaysLens.sol";
import "./spread/ISpread60DaysLens.sol";
import "./spread/ISpread90DaysLens.sol";
import "../libraries/AmmLib.sol";
import "../libraries/RiskManagementLogic.sol";
import "./libraries/IporSwapLogic.sol";

/// @dev It is not recommended to use lens contract directly, should be used only through IporProtocolRouter.
contract AmmSwapsLens is IAmmSwapsLens {
    using Address for address;
    using IporContractValidator for address;
    using IporSwapLogic for AmmTypes.Swap;
    using AmmLib for AmmTypes.AmmPoolCoreModel;

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
        _usdtAsset = usdtCfg.asset.checkAddress();
        _usdtAmmStorage = usdtCfg.ammStorage.checkAddress();
        _usdtAmmTreasury = usdtCfg.ammTreasury.checkAddress();
        _usdtMinLeverage = usdtCfg.minLeverage;

        _usdcAsset = usdcCfg.asset.checkAddress();
        _usdcAmmStorage = usdcCfg.ammStorage.checkAddress();
        _usdcAmmTreasury = usdcCfg.ammTreasury.checkAddress();
        _usdcMinLeverage = usdcCfg.minLeverage;

        _daiAsset = daiCfg.asset.checkAddress();
        _daiAmmStorage = daiCfg.ammStorage.checkAddress();
        _daiAmmTreasury = daiCfg.ammTreasury.checkAddress();
        _daiMinLeverage = daiCfg.minLeverage;

        _iporOracle = iporOracle.checkAddress();
        _riskManagementOracle = riskManagementOracle.checkAddress();
        _spreadRouter = spreadRouter.checkAddress();
    }

    function getSwapLensPoolConfiguration(
        address asset
    ) external view override returns (SwapLensPoolConfiguration memory) {
        return _getSwapLensPoolConfiguration(asset);
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

    function getPnlPayFixed(address asset, uint256 swapId) external view override returns (int256) {
        IAmmStorage ammStorage = _getAmmStorage(asset);
        AmmTypes.Swap memory swap = ammStorage.getSwap(AmmTypes.SwapDirection.PAY_FIXED_RECEIVE_FLOATING, swapId);

        require(swap.id > 0, AmmErrors.INCORRECT_SWAP_ID);

        uint256 accruedIbtPrice = IIporOracle(_iporOracle).calculateAccruedIbtPrice(asset, block.timestamp);
        return swap.calculatePnlPayFixed(block.timestamp, accruedIbtPrice);
    }

    function getPnlReceiveFixed(address asset, uint256 swapId) external view override returns (int256) {
        IAmmStorage ammStorage = _getAmmStorage(asset);
        AmmTypes.Swap memory swap = ammStorage.getSwap(AmmTypes.SwapDirection.PAY_FLOATING_RECEIVE_FIXED, swapId);

        require(swap.id > 0, AmmErrors.INCORRECT_SWAP_ID);

        uint256 accruedIbtPrice = IIporOracle(_iporOracle).calculateAccruedIbtPrice(asset, block.timestamp);
        return swap.calculatePnlReceiveFixed(block.timestamp, accruedIbtPrice);
    }

    function getSoap(
        address asset
    ) external view override returns (int256 soapPayFixed, int256 soapReceiveFixed, int256 soap) {
        IAmmStorage ammStorage = _getAmmStorage(asset);
        AmmTypes.AmmPoolCoreModel memory ammCoreModel;
        ammCoreModel.asset = asset;
        ammCoreModel.ammStorage = address(ammStorage);
        ammCoreModel.iporOracle = _iporOracle;
        (soapPayFixed, soapReceiveFixed, soap) = ammCoreModel.getSoap();
    }

    function getOfferedRate(
        address asset,
        IporTypes.SwapTenor tenor,
        uint256 notional
    ) external view override returns (uint256 offeredRatePayFixed, uint256 offeredRateReceiveFixed) {
        require(notional > 0, AmmErrors.INVALID_NOTIONAL);

        SwapLensPoolConfiguration memory poolCfg = _getSwapLensPoolConfiguration(asset);

        (bytes4 payFixedSig, bytes4 receiveFixedSig) = _getSpreadRouterSignatures(tenor);
        (uint256 indexValue, , ) = IIporOracle(_iporOracle).getIndex(asset);

        IporTypes.AmmBalancesForOpenSwapMemory memory balance = IAmmStorage(poolCfg.ammStorage)
            .getBalancesForOpenSwap();

        AmmInternalTypes.SpreadContext memory spreadContextPayFixed;
        spreadContextPayFixed.asset = asset;
        spreadContextPayFixed.spreadFunctionSig = payFixedSig;
        spreadContextPayFixed.tenor = tenor;
        spreadContextPayFixed.notional = notional;
        spreadContextPayFixed.minLeverage = poolCfg.minLeverage;
        spreadContextPayFixed.indexValue = indexValue;
        spreadContextPayFixed.riskIndicators = RiskManagementLogic.getRiskIndicators(
            asset,
            0,
            tenor,
            balance.liquidityPool,
            poolCfg.minLeverage,
            _riskManagementOracle
        );
        spreadContextPayFixed.balance = balance;
        offeredRatePayFixed = _getOfferedRatePerLeg(spreadContextPayFixed);

        AmmInternalTypes.SpreadContext memory spreadContextReceiveFixed;
        spreadContextReceiveFixed.asset = asset;
        spreadContextReceiveFixed.spreadFunctionSig = receiveFixedSig;
        spreadContextReceiveFixed.tenor = tenor;
        spreadContextReceiveFixed.notional = notional;
        spreadContextReceiveFixed.minLeverage = poolCfg.minLeverage;
        spreadContextReceiveFixed.indexValue = indexValue;
        spreadContextReceiveFixed.riskIndicators = RiskManagementLogic.getRiskIndicators(
            asset,
            1,
            tenor,
            balance.liquidityPool,
            poolCfg.minLeverage,
            _riskManagementOracle
        );
        spreadContextReceiveFixed.balance = balance;
        offeredRateReceiveFixed = _getOfferedRatePerLeg(spreadContextReceiveFixed);
    }

    function _getOfferedRatePerLeg(
        AmmInternalTypes.SpreadContext memory spreadContext
    ) internal view returns (uint256 offeredRate) {
        offeredRate = abi.decode(
            _spreadRouter.functionStaticCall(
                abi.encodeWithSelector(
                    spreadContext.spreadFunctionSig,
                    spreadContext.asset,
                    spreadContext.notional,
                    spreadContext.riskIndicators.maxLeveragePerLeg,
                    spreadContext.riskIndicators.maxCollateralRatioPerLeg,
                    spreadContext.riskIndicators.baseSpreadPerLeg,
                    spreadContext.balance.totalCollateralPayFixed,
                    spreadContext.balance.totalCollateralReceiveFixed,
                    spreadContext.balance.liquidityPool,
                    spreadContext.balance.totalNotionalPayFixed,
                    spreadContext.balance.totalNotionalReceiveFixed,
                    spreadContext.indexValue,
                    spreadContext.riskIndicators.fixedRateCapPerLeg
                )
            ),
            (uint256)
        );
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
        AmmStorageTypes.IporSwapId memory swapId;
        AmmTypes.Swap memory swap;
        int256 swapValue;

        for (uint256 i; i != swapCount; ) {
            swapId = swapIds[i];

            if (swapId.direction == 0) {
                swap = ammStorage.getSwap(AmmTypes.SwapDirection.PAY_FIXED_RECEIVE_FLOATING, swapId.id);
                swapValue = swap.calculatePnlPayFixed(block.timestamp, accruedIbtPrice);
                mappedSwaps[i] = _mapSwap(asset, swap, 0, swapValue);
            } else {
                swap = ammStorage.getSwap(AmmTypes.SwapDirection.PAY_FLOATING_RECEIVE_FIXED, swapId.id);
                swapValue = swap.calculatePnlReceiveFixed(block.timestamp, accruedIbtPrice);
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
        int256 pnlValue
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
                pnlValue: pnlValue,
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
    ) internal pure returns (bytes4 payFixedSig, bytes4 receiveFixedSig) {
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

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.20;

import "@openzeppelin/contracts/utils/Address.sol";
import "../basic/types/AmmTypesGenOne.sol";
import "../basic/interfaces/IAmmStorageGenOne.sol";
import "../interfaces/IAmmSwapsLens.sol";
import "../libraries/IporContractValidator.sol";
import "../libraries/RiskIndicatorsValidatorLib.sol";
import "../libraries/AmmLib.sol";
import "./spread/ISpread28DaysLens.sol";
import "./spread/ISpread60DaysLens.sol";
import "./spread/ISpread90DaysLens.sol";
import "./libraries/IporSwapLogic.sol";
import "../basic/amm/libraries/SwapLogicGenOne.sol";

/// @dev It is not recommended to use lens contract directly, should be used only through IporProtocolRouter.
contract AmmSwapsLens is IAmmSwapsLens {
    using Address for address;
    using IporContractValidator for address;
    using IporSwapLogic for AmmTypes.Swap;
    using SwapLogicGenOne for AmmTypesGenOne.Swap;
    using AmmLib for AmmTypes.AmmPoolCoreModel;
    using RiskIndicatorsValidatorLib for AmmTypes.RiskIndicatorsInputs;

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

    address internal immutable _stEthAsset;
    address internal immutable _stEthAmmStorage;
    address internal immutable _stEthAmmTreasury;
    uint256 internal immutable _stEthMinLeverage;

    address public immutable iporOracle;
    address public immutable messageSigner;
    address public immutable spreadRouter;

    constructor(
        SwapLensPoolConfiguration memory usdtCfg,
        SwapLensPoolConfiguration memory usdcCfg,
        SwapLensPoolConfiguration memory daiCfg,
        SwapLensPoolConfiguration memory stEthCfg,
        address iporOracleInput,
        address messageSignerInput,
        address spreadRouterInput
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

        _stEthAsset = stEthCfg.asset.checkAddress();
        _stEthAmmStorage = stEthCfg.ammStorage.checkAddress();
        _stEthAmmTreasury = stEthCfg.ammTreasury.checkAddress();
        _stEthMinLeverage = stEthCfg.minLeverage;

        iporOracle = iporOracleInput.checkAddress();
        messageSigner = messageSignerInput.checkAddress();
        spreadRouter = spreadRouterInput.checkAddress();
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
        if (asset == _stEthAsset) {
            IAmmStorageGenOne ammStorageGenOne = IAmmStorageGenOne(_stEthAmmStorage);
            (uint256 count, AmmStorageTypes.IporSwapId[] memory swapIds) = ammStorageGenOne.getSwapIds(
                account,
                offset,
                chunkSize
            );
            return (count, _mapSwapsGenOne(asset, ammStorageGenOne, swapIds));
        } else {
            IAmmStorage ammStorage = IAmmStorage(_getAmmStorage(asset));
            (uint256 count, AmmStorageTypes.IporSwapId[] memory swapIds) = ammStorage.getSwapIds(
                account,
                offset,
                chunkSize
            );
            return (count, _mapSwaps(asset, ammStorage, swapIds));
        }
    }

    function getPnlPayFixed(address asset, uint256 swapId) external view override returns (int256) {
        uint256 accruedIbtPrice = IIporOracle(iporOracle).calculateAccruedIbtPrice(asset, block.timestamp);

        if (asset == _stEthAsset) {
            AmmTypesGenOne.Swap memory swapGenOne = IAmmStorageGenOne(_getAmmStorage(asset)).getSwap(
                AmmTypes.SwapDirection.PAY_FIXED_RECEIVE_FLOATING,
                swapId
            );

            require(swapGenOne.id > 0, AmmErrors.INCORRECT_SWAP_ID);

            return swapGenOne.calculatePnlPayFixed(block.timestamp, accruedIbtPrice);
        } else {
            AmmTypes.Swap memory swap = IAmmStorage(_getAmmStorage(asset)).getSwap(
                AmmTypes.SwapDirection.PAY_FIXED_RECEIVE_FLOATING,
                swapId
            );

            require(swap.id > 0, AmmErrors.INCORRECT_SWAP_ID);

            return swap.calculatePnlPayFixed(block.timestamp, accruedIbtPrice);
        }
    }

    function getPnlReceiveFixed(address asset, uint256 swapId) external view override returns (int256) {
        uint256 accruedIbtPrice = IIporOracle(iporOracle).calculateAccruedIbtPrice(asset, block.timestamp);
        if (asset == _stEthAsset) {
            AmmTypesGenOne.Swap memory swapGenOne = IAmmStorageGenOne(_getAmmStorage(asset)).getSwap(
                AmmTypes.SwapDirection.PAY_FLOATING_RECEIVE_FIXED,
                swapId
            );

            require(swapGenOne.id > 0, AmmErrors.INCORRECT_SWAP_ID);

            return swapGenOne.calculatePnlReceiveFixed(block.timestamp, accruedIbtPrice);
        } else {
            AmmTypes.Swap memory swap = IAmmStorage(_getAmmStorage(asset)).getSwap(
                AmmTypes.SwapDirection.PAY_FLOATING_RECEIVE_FIXED,
                swapId
            );

            require(swap.id > 0, AmmErrors.INCORRECT_SWAP_ID);

            return swap.calculatePnlReceiveFixed(block.timestamp, accruedIbtPrice);
        }
    }

    function getSoap(
        address asset
    ) external view override returns (int256 soapPayFixed, int256 soapReceiveFixed, int256 soap) {
        AmmTypes.AmmPoolCoreModel memory ammCoreModel;
        ammCoreModel.asset = asset;
        ammCoreModel.ammStorage = _getAmmStorage(asset);
        ammCoreModel.iporOracle = iporOracle;
        (soapPayFixed, soapReceiveFixed, soap) = ammCoreModel.getSoap();
    }

    function getOfferedRate(
        address asset,
        IporTypes.SwapTenor tenor,
        uint256 notional,
        AmmTypes.RiskIndicatorsInputs calldata payFixedRiskIndicatorsInputs,
        AmmTypes.RiskIndicatorsInputs calldata receiveFixedRiskIndicatorsInputs
    ) external view override returns (uint256 offeredRatePayFixed, uint256 offeredRateReceiveFixed) {
        require(notional > 0, AmmErrors.INVALID_NOTIONAL);

        SwapLensPoolConfiguration memory poolCfg = _getSwapLensPoolConfiguration(asset);

        (bytes4 payFixedSig, bytes4 receiveFixedSig) = _getSpreadRouterSignatures(tenor);
        (uint256 indexValue, , ) = IIporOracle(iporOracle).getIndex(asset);

        IporTypes.AmmBalancesForOpenSwapMemory memory balance = IAmmStorage(poolCfg.ammStorage)
            .getBalancesForOpenSwap();

        AmmInternalTypes.SpreadContext memory spreadContextPayFixed;
        spreadContextPayFixed.asset = asset;
        spreadContextPayFixed.spreadFunctionSig = payFixedSig;
        spreadContextPayFixed.tenor = tenor;
        spreadContextPayFixed.notional = notional;
        spreadContextPayFixed.minLeverage = poolCfg.minLeverage;
        spreadContextPayFixed.indexValue = indexValue;
        spreadContextPayFixed.riskIndicators = payFixedRiskIndicatorsInputs.verify(
            asset,
            uint256(tenor),
            uint256(AmmTypes.SwapDirection.PAY_FIXED_RECEIVE_FLOATING),
            messageSigner
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
        spreadContextReceiveFixed.riskIndicators = receiveFixedRiskIndicatorsInputs.verify(
            asset,
            uint256(tenor),
            uint256(AmmTypes.SwapDirection.PAY_FLOATING_RECEIVE_FIXED),
            messageSigner
        );
        spreadContextReceiveFixed.balance = balance;
        offeredRateReceiveFixed = _getOfferedRatePerLeg(spreadContextReceiveFixed);
    }

    function _getOfferedRatePerLeg(
        AmmInternalTypes.SpreadContext memory spreadContext
    ) internal view returns (uint256 offeredRate) {
        offeredRate = abi.decode(
            spreadRouter.functionStaticCall(
                abi.encodeWithSelector(
                    spreadContext.spreadFunctionSig,
                    spreadContext.asset,
                    spreadContext.notional,
                    spreadContext.riskIndicators.demandSpreadFactor,
                    spreadContext.riskIndicators.baseSpreadPerLeg,
                    spreadContext.balance.totalCollateralPayFixed,
                    spreadContext.balance.totalCollateralReceiveFixed,
                    spreadContext.balance.liquidityPool,
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
        return IAmmStorage(_getAmmStorage(asset)).getBalancesForOpenSwap();
    }

    function _mapSwaps(
        address asset,
        IAmmStorage ammStorage,
        AmmStorageTypes.IporSwapId[] memory swapIds
    ) internal view returns (IAmmSwapsLens.IporSwap[] memory swaps) {
        uint256 accruedIbtPrice = IIporOracle(iporOracle).calculateAccruedIbtPrice(asset, block.timestamp);
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

    function _mapSwapsGenOne(
        address asset,
        IAmmStorageGenOne ammStorage,
        AmmStorageTypes.IporSwapId[] memory swapIds
    ) internal view returns (IAmmSwapsLens.IporSwap[] memory swaps) {
        uint256 accruedIbtPrice = IIporOracle(iporOracle).calculateAccruedIbtPrice(asset, block.timestamp);
        uint256 swapCount = swapIds.length;

        IAmmSwapsLens.IporSwap[] memory mappedSwaps = new IAmmSwapsLens.IporSwap[](swapCount);
        AmmStorageTypes.IporSwapId memory swapId;
        AmmTypesGenOne.Swap memory swap;
        int256 swapValue;

        for (uint256 i; i != swapCount; ) {
            swapId = swapIds[i];

            if (swapId.direction == 0) {
                swap = ammStorage.getSwap(AmmTypes.SwapDirection.PAY_FIXED_RECEIVE_FLOATING, swapId.id);
                swapValue = swap.calculatePnlPayFixed(block.timestamp, accruedIbtPrice);
                mappedSwaps[i] = _mapSwapGenOne(asset, swap, swapValue);
            } else {
                swap = ammStorage.getSwap(AmmTypes.SwapDirection.PAY_FLOATING_RECEIVE_FIXED, swapId.id);
                swapValue = swap.calculatePnlReceiveFixed(block.timestamp, accruedIbtPrice);
                mappedSwaps[i] = _mapSwapGenOne(asset, swap, swapValue);
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

    function _mapSwapGenOne(
        address asset,
        AmmTypesGenOne.Swap memory swap,
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
                direction: uint256(swap.direction),
                ibtQuantity: swap.ibtQuantity,
                fixedInterestRate: swap.fixedInterestRate,
                pnlValue: pnlValue,
                openTimestamp: swap.openTimestamp,
                endTimestamp: swap.getSwapEndTimestamp(),
                liquidationDepositAmount: swap.liquidationDepositAmount,
                state: uint256(swap.state)
            });
    }

    function _getAmmStorage(address asset) internal view returns (address ammStorage) {
        if (asset == _usdtAsset) {
            return _usdtAmmStorage;
        } else if (asset == _usdcAsset) {
            return _usdcAmmStorage;
        } else if (asset == _daiAsset) {
            return _daiAmmStorage;
        } else if (asset == _stEthAsset) {
            return _stEthAmmStorage;
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
        } else if (asset == _stEthAsset) {
            return
                SwapLensPoolConfiguration({
                    asset: _stEthAsset,
                    ammStorage: _stEthAmmStorage,
                    ammTreasury: _stEthAmmTreasury,
                    minLeverage: _stEthMinLeverage
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

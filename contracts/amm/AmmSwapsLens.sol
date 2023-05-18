// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.16;

import "../interfaces/IIporOracle.sol";
import "../interfaces/IMiltonSpreadModel.sol";
import "../interfaces/IMiltonStorage.sol";
import "../interfaces/IAmmSwapsLens.sol";
import "./libraries/IporSwapLogic.sol";

contract AmmSwapsLens is IAmmSwapsLens {
    using IporSwapLogic for IporTypes.IporSwapMemory;

    address internal immutable _usdcAsset;
    IMiltonStorage internal immutable _usdcMiltonStorage;

    address internal immutable _usdtAsset;
    IMiltonStorage internal immutable _usdtMiltonStorage;

    address internal immutable _daiAsset;
    IMiltonStorage internal immutable _daiMiltonStorage;

    IIporOracle internal immutable _iporOracle;

    constructor(
        address usdcAsset,
        IMiltonStorage usdcMiltonStorage,
        address usdtAsset,
        IMiltonStorage usdtMiltonStorage,
        address daiAsset,
        IMiltonStorage daiMiltonStorage,
        IIporOracle iporOracle
    ) {
        _usdcAsset = usdcAsset;
        _usdcMiltonStorage = usdcMiltonStorage;

        _usdtAsset = usdtAsset;
        _usdtMiltonStorage = usdtMiltonStorage;

        _daiAsset = daiAsset;
        _daiMiltonStorage = daiMiltonStorage;

        _iporOracle = iporOracle;
    }

    function getSwapsPayFixed(
        address asset,
        address account,
        uint256 offset,
        uint256 chunkSize
    ) external view override returns (uint256 totalCount, IAmmSwapsLens.IporSwap[] memory swaps) {
        IMiltonStorage miltonStorage = _getMiltonStorageImplementation(asset);
        (uint256 count, uint256[] memory swapIds) = miltonStorage.getSwapPayFixedIds(account, offset, chunkSize);
        return (count, _mapSwapsPayFixed(asset, miltonStorage, swapIds));
    }

    function getSwapsReceiveFixed(
        address asset,
        address account,
        uint256 offset,
        uint256 chunkSize
    ) external view override returns (uint256 totalCount, IAmmSwapsLens.IporSwap[] memory swaps) {
        IMiltonStorage miltonStorage = _getMiltonStorageImplementation(asset);
        (uint256 count, uint256[] memory swapIds) = miltonStorage.getSwapReceiveFixedIds(account, offset, chunkSize);
        return (count, _mapSwapsReceiveFixed(asset, miltonStorage, swapIds));
    }

    function getSwaps(
        address asset,
        address account,
        uint256 offset,
        uint256 chunkSize
    ) external view returns (uint256 totalCount, IAmmSwapsLens.IporSwap[] memory swaps) {
        IMiltonStorage miltonStorage = _getMiltonStorageImplementation(asset);
        (uint256 count, MiltonStorageTypes.IporSwapId[] memory swapIds) = miltonStorage.getSwapIds(
            account,
            offset,
            chunkSize
        );
        return (count, _mapSwaps(asset, miltonStorage, swapIds));
    }

    function _mapSwapsPayFixed(
        address asset,
        IMiltonStorage miltonStorage,
        uint256[] memory swapIds
    ) internal view returns (IAmmSwapsLens.IporSwap[] memory swaps) {
        uint256 swapCount = swapIds.length;
        MiltonStorageTypes.IporSwapId[] memory swapIdsWithDirection = new MiltonStorageTypes.IporSwapId[](swapCount);
        for (uint256 i; i != swapCount; ++i) {
            swapIdsWithDirection[i] = MiltonStorageTypes.IporSwapId({id: swapIds[i], direction: 0});
        }
        return _mapSwaps(asset, miltonStorage, swapIdsWithDirection);
    }

    function _mapSwapsReceiveFixed(
        address asset,
        IMiltonStorage miltonStorage,
        uint256[] memory swapIds
    ) internal view returns (IAmmSwapsLens.IporSwap[] memory swaps) {
        uint256 swapCount = swapIds.length;
        MiltonStorageTypes.IporSwapId[] memory swapIdsWithDirection = new MiltonStorageTypes.IporSwapId[](swapCount);
        for (uint256 i; i != swapCount; ++i) {
            swapIdsWithDirection[i] = MiltonStorageTypes.IporSwapId({id: swapIds[i], direction: 1});
        }
        return _mapSwaps(asset, miltonStorage, swapIdsWithDirection);
    }

    function _mapSwaps(
        address asset,
        IMiltonStorage miltonStorage,
        MiltonStorageTypes.IporSwapId[] memory swapIds
    ) internal view returns (IAmmSwapsLens.IporSwap[] memory swaps) {
        uint256 accruedIbtPrice = _iporOracle.calculateAccruedIbtPrice(asset, block.timestamp);
        uint256 swapCount = swapIds.length;
        IAmmSwapsLens.IporSwap[] memory mappedSwaps = new IAmmSwapsLens.IporSwap[](swapCount);
        for (uint256 i; i != swapCount; ++i) {
            MiltonStorageTypes.IporSwapId memory swapId = swapIds[i];
            if (swapId.direction == 0) {
                IporTypes.IporSwapMemory memory iporSwap = miltonStorage.getSwapPayFixed(swapId.id);
                int256 swapValue = iporSwap.calculatePayoffPayFixed(block.timestamp, accruedIbtPrice);
                mappedSwaps[i] = _mapSwap(asset, iporSwap, 0, swapValue);
            } else {
                IporTypes.IporSwapMemory memory iporSwap = miltonStorage.getSwapReceiveFixed(swapId.id);
                int256 swapValue = iporSwap.calculatePayoffReceiveFixed(block.timestamp, accruedIbtPrice);
                mappedSwaps[i] = _mapSwap(asset, iporSwap, 1, swapValue);
            }
        }
        return mappedSwaps;
    }

    function _mapSwap(
        address asset,
        IporTypes.IporSwapMemory memory swap,
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
                leverage: IporMath.division(swap.notional * Constants.D18, swap.collateral),
                direction: direction,
                ibtQuantity: swap.ibtQuantity,
                fixedInterestRate: swap.fixedInterestRate,
                payoff: swapValue,
                openTimestamp: swap.openTimestamp,
                endTimestamp: swap.endTimestamp,
                liquidationDepositAmount: swap.liquidationDepositAmount,
                state: swap.state
            });
    }

    function _getMiltonStorageImplementation(address asset) internal view returns (IMiltonStorage miltonStorage) {
        if (asset == _usdcAsset) {
            return _usdcMiltonStorage;
        } else if (asset == _usdtAsset) {
            return _usdtMiltonStorage;
        } else if (asset == _daiAsset) {
            return _daiMiltonStorage;
        } else {
            revert("Unsupported asset");
        }
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.16;

import "../interfaces/IIporOracle.sol";
import "../interfaces/IMiltonSpreadModel.sol";
import "../interfaces/IMiltonStorage.sol";
import "../interfaces/IAmmSwapsLens.sol";
import "./libraries/IporSwapLogic.sol";
import "../libraries/AmmLib.sol";

contract AmmSwapsLens is IAmmSwapsLens {
    using IporSwapLogic for IporTypes.IporSwapMemory;

    address internal immutable _usdcAsset;
    IMiltonStorage internal immutable _usdcAmmStorage;

    address internal immutable _usdtAsset;
    IMiltonStorage internal immutable _usdtAmmStorage;

    address internal immutable _daiAsset;
    IMiltonStorage internal immutable _daiAmmStorage;

    IIporOracle internal immutable _iporOracle;

    constructor(
        address usdcAsset,
        IMiltonStorage usdcAmmStorage,
        address usdtAsset,
        IMiltonStorage usdtAmmStorage,
        address daiAsset,
        IMiltonStorage daiAmmStorage,
        IIporOracle iporOracle
    ) {
        _usdcAsset = usdcAsset;
        _usdcAmmStorage = usdcAmmStorage;

        _usdtAsset = usdtAsset;
        _usdtAmmStorage = usdtAmmStorage;

        _daiAsset = daiAsset;
        _daiAmmStorage = daiAmmStorage;

        _iporOracle = iporOracle;
    }

    function getSwapsPayFixed(
        address asset,
        address account,
        uint256 offset,
        uint256 chunkSize
    ) external view override returns (uint256 totalCount, IAmmSwapsLens.IporSwap[] memory swaps) {
        IMiltonStorage ammStorage = _getAmmStorageImplementation(asset);
        (uint256 count, uint256[] memory swapIds) = ammStorage.getSwapPayFixedIds(account, offset, chunkSize);
        return (count, _mapSwapsPayFixed(asset, ammStorage, swapIds));
    }

    function getSwapsReceiveFixed(
        address asset,
        address account,
        uint256 offset,
        uint256 chunkSize
    ) external view override returns (uint256 totalCount, IAmmSwapsLens.IporSwap[] memory swaps) {
        IMiltonStorage ammStorage = _getAmmStorageImplementation(asset);
        (uint256 count, uint256[] memory swapIds) = ammStorage.getSwapReceiveFixedIds(account, offset, chunkSize);
        return (count, _mapSwapsReceiveFixed(asset, ammStorage, swapIds));
    }

    function getSwaps(
        address asset,
        address account,
        uint256 offset,
        uint256 chunkSize
    ) external view returns (uint256 totalCount, IAmmSwapsLens.IporSwap[] memory swaps) {
        IMiltonStorage ammStorage = _getAmmStorageImplementation(asset);
        (uint256 count, MiltonStorageTypes.IporSwapId[] memory swapIds) = ammStorage.getSwapIds(
            account,
            offset,
            chunkSize
        );
        return (count, _mapSwaps(asset, ammStorage, swapIds));
    }

    function getPayoffPayFixed(address asset, uint256 swapId) external view override returns (int256) {
        IMiltonStorage ammStorage = _getAmmStorageImplementation(asset);
        IporTypes.IporSwapMemory memory iporSwap = ammStorage.getSwapPayFixed(swapId);
        uint256 accruedIbtPrice = _iporOracle.calculateAccruedIbtPrice(asset, block.timestamp);
        return iporSwap.calculatePayoffPayFixed(block.timestamp, accruedIbtPrice);
    }

    function getPayoffReceiveFixed(address asset, uint256 swapId) external view override returns (int256) {
        IMiltonStorage ammStorage = _getAmmStorageImplementation(asset);
        IporTypes.IporSwapMemory memory iporSwap = ammStorage.getSwapReceiveFixed(swapId);
        uint256 accruedIbtPrice = _iporOracle.calculateAccruedIbtPrice(asset, block.timestamp);
        return iporSwap.calculatePayoffReceiveFixed(block.timestamp, accruedIbtPrice);
    }

    function getSOAP(address asset)
        external
        view
        override
        returns (
            int256 soapPayFixed,
            int256 soapReceiveFixed,
            int256 soap
        )
    {
        IMiltonStorage ammStorage = _getAmmStorageImplementation(asset);

        (soapPayFixed, soapReceiveFixed, soap) = AmmLib.getSOAP(asset, address(ammStorage), address(_iporOracle));
    }

    function _mapSwapsPayFixed(
        address asset,
        IMiltonStorage ammStorage,
        uint256[] memory swapIds
    ) internal view returns (IAmmSwapsLens.IporSwap[] memory swaps) {
        uint256 swapCount = swapIds.length;
        MiltonStorageTypes.IporSwapId[] memory swapIdsWithDirection = new MiltonStorageTypes.IporSwapId[](swapCount);
        for (uint256 i; i != swapCount; ++i) {
            swapIdsWithDirection[i] = MiltonStorageTypes.IporSwapId({id: swapIds[i], direction: 0});
        }
        return _mapSwaps(asset, ammStorage, swapIdsWithDirection);
    }

    function _mapSwapsReceiveFixed(
        address asset,
        IMiltonStorage ammStorage,
        uint256[] memory swapIds
    ) internal view returns (IAmmSwapsLens.IporSwap[] memory swaps) {
        uint256 swapCount = swapIds.length;
        MiltonStorageTypes.IporSwapId[] memory swapIdsWithDirection = new MiltonStorageTypes.IporSwapId[](swapCount);
        for (uint256 i; i != swapCount; ++i) {
            swapIdsWithDirection[i] = MiltonStorageTypes.IporSwapId({id: swapIds[i], direction: 1});
        }
        return _mapSwaps(asset, ammStorage, swapIdsWithDirection);
    }

    function _mapSwaps(
        address asset,
        IMiltonStorage ammStorage,
        MiltonStorageTypes.IporSwapId[] memory swapIds
    ) internal view returns (IAmmSwapsLens.IporSwap[] memory swaps) {
        uint256 accruedIbtPrice = _iporOracle.calculateAccruedIbtPrice(asset, block.timestamp);
        uint256 swapCount = swapIds.length;
        IAmmSwapsLens.IporSwap[] memory mappedSwaps = new IAmmSwapsLens.IporSwap[](swapCount);
        for (uint256 i; i != swapCount; ++i) {
            MiltonStorageTypes.IporSwapId memory swapId = swapIds[i];
            if (swapId.direction == 0) {
                IporTypes.IporSwapMemory memory iporSwap = ammStorage.getSwapPayFixed(swapId.id);
                int256 swapValue = iporSwap.calculatePayoffPayFixed(block.timestamp, accruedIbtPrice);
                mappedSwaps[i] = _mapSwap(asset, iporSwap, 0, swapValue);
            } else {
                IporTypes.IporSwapMemory memory iporSwap = ammStorage.getSwapReceiveFixed(swapId.id);
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
                endTimestamp: swap.calculateSwapMaturity(),
                liquidationDepositAmount: swap.liquidationDepositAmount,
                state: swap.state
            });
    }

    function _getAmmStorageImplementation(address asset) internal view returns (IMiltonStorage ammStorage) {
        if (asset == _usdcAsset) {
            return _usdcAmmStorage;
        } else if (asset == _usdtAsset) {
            return _usdtAmmStorage;
        } else if (asset == _daiAsset) {
            return _daiAmmStorage;
        } else {
            revert("Unsupported asset");
        }
    }

    function getConfiguration()
        public
        pure
        returns (
            address usdcAsset,
            address usdcAmmStorage,
            address usdtAsset,
            address usdtAmmStorage,
            address daiAsset,
            address daiAmmStorage,
            address iporOracle
        )
    {
        return (
            usdcAsset,
            address(usdcAmmStorage),
            usdtAsset,
            address(usdtAmmStorage),
            daiAsset,
            address(daiAmmStorage),
            address(iporOracle)
        );
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.20;

import "../interfaces/IAmmSwapsLens.sol";
import "./libraries/IporSwapLogic.sol";
import "../libraries/AmmLib.sol";
import "../interfaces/IAmmOpenSwapService.sol";
import "../libraries/RiskManagementLogic.sol";

contract AmmSwapsLens is IAmmSwapsLens {
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

    constructor(
        SwapLensPoolConfiguration memory usdtCfg,
        SwapLensPoolConfiguration memory usdcCfg,
        SwapLensPoolConfiguration memory daiCfg,
        address iporOracle,
        address riskManagementOracle
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
    }

    function getSwapLensPoolConfiguration(address asset) external view returns (SwapLensPoolConfiguration memory) {
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
}

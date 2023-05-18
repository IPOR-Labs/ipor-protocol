// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.16;

import "../interfaces/IIporOracle.sol";
import "../interfaces/IMiltonSpreadModel.sol";
import "../interfaces/IMiltonStorage.sol";
import "../interfaces/IAmmSwapsLens.sol";
import "./libraries/IporSwapLogic.sol";

contract AmmSwapsLens is IAmmSwapsLens {
    using IporSwapLogic for IporTypes.IporSwapMemory;

    address public immutable usdcAsset;
    address public immutable usdcMiltonStorage;
    uint256 public immutable usdcMinLiquidationThresholdToCloseBeforeMaturityByBuyer;
    uint256 public immutable usdcMinLiquidationThresholdToCloseBeforeMaturityByCommunity;
    uint256 public immutable usdcTimeBeforeMaturityAllowedToCloseSwapByBuyer;
    uint256 public immutable usdcTimeBeforeMaturityAllowedToCloseSwapByCommunity;

    address public immutable usdtAsset;
    address public immutable usdtMiltonStorage;
    uint256 public immutable usdtMinLiquidationThresholdToCloseBeforeMaturityByBuyer;
    uint256 public immutable usdtMinLiquidationThresholdToCloseBeforeMaturityByCommunity;
    uint256 public immutable usdtTimeBeforeMaturityAllowedToCloseSwapByBuyer;
    uint256 public immutable usdtTimeBeforeMaturityAllowedToCloseSwapByCommunity;

    address public immutable daiAsset;
    address public immutable daiMiltonStorage;
    uint256 public immutable daiMinLiquidationThresholdToCloseBeforeMaturityByBuyer;
    uint256 public immutable daiMinLiquidationThresholdToCloseBeforeMaturityByCommunity;
    uint256 public immutable daiTimeBeforeMaturityAllowedToCloseSwapByBuyer;
    uint256 public immutable daiTimeBeforeMaturityAllowedToCloseSwapByCommunity;

    IIporOracle public immutable iporOracle;

    address public immutable liquidator0;

    constructor(
        AssetConfiguration memory _usdcConfiguration,
        AssetConfiguration memory _usdtConfiguration,
        AssetConfiguration memory _daiConfiguration,
        IIporOracle _iporOracle,
        address _liquidator0
    ) {
        usdcAsset = _usdcConfiguration.asset;
        usdcMiltonStorage = _usdcConfiguration.miltonStorage;
        usdcMinLiquidationThresholdToCloseBeforeMaturityByBuyer = _usdcConfiguration
            .minLiquidationThresholdToCloseBeforeMaturityByBuyer;
        usdcMinLiquidationThresholdToCloseBeforeMaturityByCommunity = _usdcConfiguration
            .minLiquidationThresholdToCloseBeforeMaturityByCommunity;
        usdcTimeBeforeMaturityAllowedToCloseSwapByBuyer = _usdcConfiguration
            .timeBeforeMaturityAllowedToCloseSwapByBuyer;
        usdcTimeBeforeMaturityAllowedToCloseSwapByCommunity = _usdcConfiguration
            .timeBeforeMaturityAllowedToCloseSwapByCommunity;

        usdtAsset = _usdtConfiguration.asset;
        usdtMiltonStorage = _usdtConfiguration.miltonStorage;
        usdtMinLiquidationThresholdToCloseBeforeMaturityByBuyer = _usdtConfiguration
            .minLiquidationThresholdToCloseBeforeMaturityByBuyer;
        usdtMinLiquidationThresholdToCloseBeforeMaturityByCommunity = _usdtConfiguration
            .minLiquidationThresholdToCloseBeforeMaturityByCommunity;
        usdtTimeBeforeMaturityAllowedToCloseSwapByBuyer = _usdtConfiguration
            .timeBeforeMaturityAllowedToCloseSwapByBuyer;
        usdtTimeBeforeMaturityAllowedToCloseSwapByCommunity = _usdtConfiguration
            .timeBeforeMaturityAllowedToCloseSwapByCommunity;

        daiAsset = _daiConfiguration.asset;
        daiMiltonStorage = _daiConfiguration.miltonStorage;
        daiMinLiquidationThresholdToCloseBeforeMaturityByBuyer = _daiConfiguration
            .minLiquidationThresholdToCloseBeforeMaturityByBuyer;
        daiMinLiquidationThresholdToCloseBeforeMaturityByCommunity = _daiConfiguration
            .minLiquidationThresholdToCloseBeforeMaturityByCommunity;
        daiTimeBeforeMaturityAllowedToCloseSwapByBuyer = _daiConfiguration.timeBeforeMaturityAllowedToCloseSwapByBuyer;
        daiTimeBeforeMaturityAllowedToCloseSwapByCommunity = _daiConfiguration
            .timeBeforeMaturityAllowedToCloseSwapByCommunity;

        iporOracle = _iporOracle;

        liquidator0 = _liquidator0;
    }

    function getClosableStatusForPayFixedSwap(address asset, uint256 swapId, address account)
        external
        view
        override
        returns (uint256 closableStatus)
    {
        AssetConfiguration memory assetConfiguration = _getAssetConfiguration(asset);
        IMiltonStorage miltonStorage = IMiltonStorage(assetConfiguration.miltonStorage);
        IporTypes.IporSwapMemory memory iporSwap = miltonStorage.getSwapPayFixed(swapId);
        uint256 accruedIbtPrice = iporOracle.calculateAccruedIbtPrice(asset, block.timestamp);

        closableStatus = _getClosableStatusForSwap(
            assetConfiguration,
            account,
            iporSwap,
            iporSwap.calculatePayoffPayFixed(block.timestamp, accruedIbtPrice),
            block.timestamp
        );
    }

    function getClosableStatusForReceiveFixedSwap(address asset, uint256 swapId, address account)
        external
        view
        override
        returns (uint256 closableStatus)
    {
        AssetConfiguration memory assetConfiguration = _getAssetConfiguration(asset);
        IMiltonStorage miltonStorage = IMiltonStorage(assetConfiguration.miltonStorage);
        IporTypes.IporSwapMemory memory iporSwap = miltonStorage.getSwapReceiveFixed(swapId);
        uint256 accruedIbtPrice = iporOracle.calculateAccruedIbtPrice(asset, block.timestamp);

        closableStatus = _getClosableStatusForSwap(
            assetConfiguration,
            account,
            iporSwap,
            iporSwap.calculatePayoffReceiveFixed(block.timestamp, accruedIbtPrice),
            block.timestamp
        );
    }

    /// @notice Check closable status for Swap given as a parameter.
    /// @param account Account address for which closable status is scoped
    /// @param iporSwap The swap to be checked
    /// @param payoff The payoff of the swap
    /// @param closeTimestamp The timestamp of closing
    /// @return closableStatus Closable status for Swap.
    /// @dev Closable status is a one of the following values:
    /// 0 - Swap is closable
    /// 1 - Swap is already closed
    /// 2 - Swap state required Buyer or Liquidator to close. Account is not Buyer nor Liquidator.
    /// 3 - Cannot close swap, closing is too early for Buyer
    /// 4 - Cannot close swap, closing is too early for Community
    function _getClosableStatusForSwap(
        AssetConfiguration memory assetConfiguration,
        address account,
        IporTypes.IporSwapMemory memory iporSwap,
        int256 payoff,
        uint256 closeTimestamp
    ) internal view returns (uint256) {
        if (iporSwap.state != uint256(AmmTypes.SwapState.ACTIVE)) {
            return 1;
        }

        if (account != owner()) {
            uint256 absPayoff = IporMath.absoluteValue(payoff);

            uint256 minPayoffToCloseBeforeMaturityByCommunity = IporMath.percentOf(
                iporSwap.collateral,
                assetConfiguration.minLiquidationThresholdToCloseBeforeMaturityByCommunity
            );

            if (closeTimestamp >= iporSwap.endTimestamp) {
                if (absPayoff < minPayoffToCloseBeforeMaturityByCommunity || absPayoff == iporSwap.collateral) {
                    if (!_isLiquidator(account) && account != iporSwap.buyer) {
                        return 2;
                    }
                }
            } else {
                uint256 minPayoffToCloseBeforeMaturityByBuyer = IporMath.percentOf(
                    iporSwap.collateral,
                    assetConfiguration.minLiquidationThresholdToCloseBeforeMaturityByBuyer
                );

                if (
                    (absPayoff >= minPayoffToCloseBeforeMaturityByBuyer &&
                        absPayoff < minPayoffToCloseBeforeMaturityByCommunity) || absPayoff == iporSwap.collateral
                ) {
                    if (!_isLiquidator(account) && account != iporSwap.buyer) {
                        return 2;
                    }
                }

                if (absPayoff < minPayoffToCloseBeforeMaturityByBuyer) {
                    if (account == iporSwap.buyer) {
                        if (
                            iporSwap.endTimestamp - assetConfiguration.timeBeforeMaturityAllowedToCloseSwapByBuyer >
                            closeTimestamp
                        ) {
                            return 3;
                        }
                    } else {
                        if (
                            iporSwap.endTimestamp - assetConfiguration.timeBeforeMaturityAllowedToCloseSwapByCommunity >
                            closeTimestamp
                        ) {
                            return 4;
                        }
                    }
                }
            }
        }

        return 0;
    }

    function _isLiquidator(address liquidator) internal view returns (bool) {
        return liquidator0 == liquidator;
    }

    function getSwapsPayFixed(
        address asset,
        address account,
        uint256 offset,
        uint256 chunkSize
    ) external view override returns (uint256 totalCount, IAmmSwapsLens.IporSwap[] memory swaps) {
        AssetConfiguration memory assetConfiguration = _getAssetConfiguration(asset);
        IMiltonStorage miltonStorage = IMiltonStorage(assetConfiguration.miltonStorage);
        (uint256 count, uint256[] memory swapIds) = miltonStorage.getSwapPayFixedIds(account, offset, chunkSize);
        return (count, _mapSwapsPayFixed(assetConfiguration, swapIds));
    }

    function getSwapsReceiveFixed(
        address asset,
        address account,
        uint256 offset,
        uint256 chunkSize
    ) external view override returns (uint256 totalCount, IAmmSwapsLens.IporSwap[] memory swaps) {
        AssetConfiguration memory assetConfiguration = _getAssetConfiguration(asset);
        IMiltonStorage miltonStorage = IMiltonStorage(assetConfiguration.miltonStorage);
        (uint256 count, uint256[] memory swapIds) = miltonStorage.getSwapReceiveFixedIds(account, offset, chunkSize);
        return (count, _mapSwapsReceiveFixed(assetConfiguration, swapIds));
    }

    function getSwaps(
        address asset,
        address account,
        uint256 offset,
        uint256 chunkSize
    ) external view returns (uint256 totalCount, IAmmSwapsLens.IporSwap[] memory swaps) {
        AssetConfiguration memory assetConfiguration = _getAssetConfiguration(asset);
        IMiltonStorage miltonStorage = IMiltonStorage(assetConfiguration.miltonStorage);
        (uint256 count, MiltonStorageTypes.IporSwapId[] memory swapIds) = miltonStorage.getSwapIds(
            account,
            offset,
            chunkSize
        );
        return (count, _mapSwaps(assetConfiguration, swapIds));
    }

    function _mapSwapsPayFixed(AssetConfiguration memory assetConfiguration, uint256[] memory swapIds)
        internal
        view
        returns (IAmmSwapsLens.IporSwap[] memory swaps)
    {
        MiltonStorageTypes.IporSwapId[] memory swapIdsWithDirection = new MiltonStorageTypes.IporSwapId[](
            swapIds.length
        );
        for (uint256 i = 0; i != swapIds.length; i++) {
            swapIdsWithDirection[i] = MiltonStorageTypes.IporSwapId({id: swapIds[i], direction: 0});
        }
        return _mapSwaps(assetConfiguration, swapIdsWithDirection);
    }

    function _mapSwapsReceiveFixed(AssetConfiguration memory assetConfiguration, uint256[] memory swapIds)
        internal
        view
        returns (IAmmSwapsLens.IporSwap[] memory swaps)
    {
        MiltonStorageTypes.IporSwapId[] memory swapIdsWithDirection = new MiltonStorageTypes.IporSwapId[](
            swapIds.length
        );
        for (uint256 i = 0; i != swapIds.length; i++) {
            swapIdsWithDirection[i] = MiltonStorageTypes.IporSwapId({id: swapIds[i], direction: 1});
        }
        return _mapSwaps(assetConfiguration, swapIdsWithDirection);
    }

    function _mapSwaps(AssetConfiguration memory assetConfiguration, MiltonStorageTypes.IporSwapId[] memory swapIds)
        internal
        view
        returns (IAmmSwapsLens.IporSwap[] memory swaps)
    {
        IMiltonStorage miltonStorage = IMiltonStorage(assetConfiguration.miltonStorage);
        uint256 accruedIbtPrice = iporOracle.calculateAccruedIbtPrice(assetConfiguration.asset, block.timestamp);
        IAmmSwapsLens.IporSwap[] memory mappedSwaps = new IAmmSwapsLens.IporSwap[](swapIds.length);
        for (uint256 i = 0; i != swapIds.length; i++) {
            MiltonStorageTypes.IporSwapId memory swapId = swapIds[i];
            if (swapId.direction == 0) {
                IporTypes.IporSwapMemory memory iporSwap = miltonStorage.getSwapPayFixed(swapId.id);
                int256 swapValue = iporSwap.calculatePayoffPayFixed(block.timestamp, accruedIbtPrice);
                mappedSwaps[i] = _mapSwap(assetConfiguration.asset, iporSwap, 0, swapValue);
            } else {
                IporTypes.IporSwapMemory memory iporSwap = miltonStorage.getSwapReceiveFixed(swapId.id);
                int256 swapValue = iporSwap.calculatePayoffReceiveFixed(block.timestamp, accruedIbtPrice);
                mappedSwaps[i] = _mapSwap(assetConfiguration.asset, iporSwap, 1, swapValue);
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

    function owner() public view virtual returns (address) {
        //TODO
        return address(0);
    }

    function _getAssetConfiguration(address asset)
        internal
        view
        returns (AssetConfiguration memory assetConfiguration)
    {
        if (asset == usdcAsset) {
            return
                AssetConfiguration(
                    usdcAsset,
                    usdcMiltonStorage,
                    usdcMinLiquidationThresholdToCloseBeforeMaturityByBuyer,
                    usdcMinLiquidationThresholdToCloseBeforeMaturityByCommunity,
                    usdcTimeBeforeMaturityAllowedToCloseSwapByBuyer,
                    usdcTimeBeforeMaturityAllowedToCloseSwapByCommunity
                );
        } else if (asset == usdtAsset) {
            return
                AssetConfiguration(
                    usdtAsset,
                    usdtMiltonStorage,
                    usdtMinLiquidationThresholdToCloseBeforeMaturityByBuyer,
                    usdtMinLiquidationThresholdToCloseBeforeMaturityByCommunity,
                    usdtTimeBeforeMaturityAllowedToCloseSwapByBuyer,
                    usdtTimeBeforeMaturityAllowedToCloseSwapByCommunity
                );
        } else if (asset == daiAsset) {
            return
                AssetConfiguration(
                    daiAsset,
                    daiMiltonStorage,
                    daiMinLiquidationThresholdToCloseBeforeMaturityByBuyer,
                    daiMinLiquidationThresholdToCloseBeforeMaturityByCommunity,
                    daiTimeBeforeMaturityAllowedToCloseSwapByBuyer,
                    daiTimeBeforeMaturityAllowedToCloseSwapByCommunity
                );
        } else {
            revert("Unsupported asset");
        }
    }

    struct AssetConfiguration {
        address asset;
        address miltonStorage;
        uint256 minLiquidationThresholdToCloseBeforeMaturityByBuyer;
        uint256 minLiquidationThresholdToCloseBeforeMaturityByCommunity;
        uint256 timeBeforeMaturityAllowedToCloseSwapByBuyer;
        uint256 timeBeforeMaturityAllowedToCloseSwapByCommunity;
    }
}

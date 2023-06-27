// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.20;

import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "../interfaces/types/IporTypes.sol";
import "../interfaces/types/AmmTypes.sol";
import "../interfaces/IIporOracle.sol";
import "../interfaces/IAmmTreasury.sol";
import "../interfaces/IAmmCloseSwapService.sol";
import "./spread/ISpreadCloseSwapService.sol";
import "../libraries/errors/IporErrors.sol";
import "../governance/AmmConfigurationManager.sol";
import "../security/OwnerManager.sol";
import "../libraries/math/IporMath.sol";
import "../libraries/AmmLib.sol";
import "../libraries/AssetManagementLogic.sol";
import "../libraries/RiskManagementLogic.sol";
import "./libraries/IporSwapLogic.sol";

contract AmmCloseSwapService is IAmmCloseSwapService {
    using Address for address;
    using SafeCast for uint256;
    using SafeCast for int256;
    using SafeERC20Upgradeable for IERC20Upgradeable;
    using IporSwapLogic for AmmTypes.Swap;
    using AmmLib for AmmTypes.AmmPoolCoreModel;

    address internal immutable _usdt;
    uint256 internal immutable _usdtDecimals;
    address internal immutable _usdtAmmStorage;
    address internal immutable _usdtAmmTreasury;
    address internal immutable _usdtAssetManagement;

    uint256 internal immutable _usdtOpeningFeeRateForSwapUnwind;
    uint256 internal immutable _usdtOpeningFeeTreasuryPortionRateForSwapUnwind;
    uint256 internal immutable _usdtLiquidationLegLimit;
    uint256 internal immutable _usdtTimeBeforeMaturityAllowedToCloseSwapByCommunity;
    uint256 internal immutable _usdtTimeBeforeMaturityAllowedToCloseSwapByBuyer;
    uint256 internal immutable _usdtMinLiquidationThresholdToCloseBeforeMaturityByCommunity;
    uint256 internal immutable _usdtMinLiquidationThresholdToCloseBeforeMaturityByBuyer;
    uint256 internal immutable _usdtMinLeverage;

    address internal immutable _usdc;
    uint256 internal immutable _usdcDecimals;
    address internal immutable _usdcAmmStorage;
    address internal immutable _usdcAmmTreasury;
    address internal immutable _usdcAssetManagement;

    uint256 internal immutable _usdcOpeningFeeRateForSwapUnwind;
    uint256 internal immutable _usdcOpeningFeeTreasuryPortionRateForSwapUnwind;
    uint256 internal immutable _usdcLiquidationLegLimit;
    uint256 internal immutable _usdcTimeBeforeMaturityAllowedToCloseSwapByCommunity;
    uint256 internal immutable _usdcTimeBeforeMaturityAllowedToCloseSwapByBuyer;
    uint256 internal immutable _usdcMinLiquidationThresholdToCloseBeforeMaturityByCommunity;
    uint256 internal immutable _usdcMinLiquidationThresholdToCloseBeforeMaturityByBuyer;
    uint256 internal immutable _usdcMinLeverage;

    address internal immutable _dai;
    uint256 internal immutable _daiDecimals;
    address internal immutable _daiAmmStorage;
    address internal immutable _daiAmmTreasury;
    address internal immutable _daiAssetManagement;

    uint256 internal immutable _daiOpeningFeeRateForSwapUnwind;
    uint256 internal immutable _daiOpeningFeeTreasuryPortionRateForSwapUnwind;
    uint256 internal immutable _daiLiquidationLegLimit;
    uint256 internal immutable _daiTimeBeforeMaturityAllowedToCloseSwapByCommunity;
    uint256 internal immutable _daiTimeBeforeMaturityAllowedToCloseSwapByBuyer;
    uint256 internal immutable _daiMinLiquidationThresholdToCloseBeforeMaturityByCommunity;
    uint256 internal immutable _daiMinLiquidationThresholdToCloseBeforeMaturityByBuyer;
    uint256 internal immutable _daiMinLeverage;

    address internal immutable _iporOracle;
    address internal immutable _iporRiskManagementOracle;
    address internal immutable _spreadRouter;

    constructor(
        AmmCloseSwapServicePoolConfiguration memory usdtPoolCfg,
        AmmCloseSwapServicePoolConfiguration memory usdcPoolCfg,
        AmmCloseSwapServicePoolConfiguration memory daiPoolCfg,
        address iporOracle,
        address iporRiskManagementOracle,
        address spreadRouter
    ) {
        require(usdtPoolCfg.asset != address(0), string.concat(IporErrors.WRONG_ADDRESS, " USDT pool asset"));
        require(usdtPoolCfg.ammStorage != address(0), string.concat(IporErrors.WRONG_ADDRESS, " USDT pool ammStorage"));
        require(
            usdtPoolCfg.ammTreasury != address(0),
            string.concat(IporErrors.WRONG_ADDRESS, " USDT pool ammTreasury")
        );
        require(
            usdtPoolCfg.assetManagement != address(0),
            string.concat(IporErrors.WRONG_ADDRESS, " USDT pool assetManagement")
        );

        require(usdcPoolCfg.asset != address(0), string.concat(IporErrors.WRONG_ADDRESS, " USDC pool asset"));
        require(usdcPoolCfg.ammStorage != address(0), string.concat(IporErrors.WRONG_ADDRESS, " USDC pool ammStorage"));
        require(
            usdcPoolCfg.ammTreasury != address(0),
            string.concat(IporErrors.WRONG_ADDRESS, " USDC pool ammTreasury")
        );
        require(
            usdcPoolCfg.assetManagement != address(0),
            string.concat(IporErrors.WRONG_ADDRESS, " USDC pool assetManagement")
        );

        require(daiPoolCfg.asset != address(0), string.concat(IporErrors.WRONG_ADDRESS, " DAI pool asset"));
        require(daiPoolCfg.ammStorage != address(0), string.concat(IporErrors.WRONG_ADDRESS, " DAI pool ammStorage"));
        require(daiPoolCfg.ammTreasury != address(0), string.concat(IporErrors.WRONG_ADDRESS, " DAI pool ammTreasury"));

        require(
            daiPoolCfg.assetManagement != address(0),
            string.concat(IporErrors.WRONG_ADDRESS, " DAI pool assetManagement")
        );

        require(iporOracle != address(0), string.concat(IporErrors.WRONG_ADDRESS, " iporOracle"));
        require(
            iporRiskManagementOracle != address(0),
            string.concat(IporErrors.WRONG_ADDRESS, " iporRiskManagementOracle")
        );
        require(spreadRouter != address(0), string.concat(IporErrors.WRONG_ADDRESS, " spreadRouter"));

        _usdt = usdtPoolCfg.asset;
        _usdtDecimals = usdtPoolCfg.decimals;
        _usdtAmmStorage = usdtPoolCfg.ammStorage;
        _usdtAmmTreasury = usdtPoolCfg.ammTreasury;
        _usdtAssetManagement = usdtPoolCfg.assetManagement;
        _usdtOpeningFeeRateForSwapUnwind = usdtPoolCfg.openingFeeRateForSwapUnwind;
        _usdtOpeningFeeTreasuryPortionRateForSwapUnwind = usdtPoolCfg.openingFeeTreasuryPortionRateForSwapUnwind;
        _usdtLiquidationLegLimit = usdtPoolCfg.maxLengthOfLiquidatedSwapsPerLeg;
        _usdtTimeBeforeMaturityAllowedToCloseSwapByCommunity = usdtPoolCfg
            .timeBeforeMaturityAllowedToCloseSwapByCommunity;
        _usdtTimeBeforeMaturityAllowedToCloseSwapByBuyer = usdtPoolCfg.timeBeforeMaturityAllowedToCloseSwapByBuyer;
        _usdtMinLiquidationThresholdToCloseBeforeMaturityByCommunity = usdtPoolCfg
            .minLiquidationThresholdToCloseBeforeMaturityByCommunity;
        _usdtMinLiquidationThresholdToCloseBeforeMaturityByBuyer = usdtPoolCfg
            .minLiquidationThresholdToCloseBeforeMaturityByBuyer;
        _usdtMinLeverage = usdtPoolCfg.minLeverage;

        _usdc = usdcPoolCfg.asset;
        _usdcDecimals = usdcPoolCfg.decimals;
        _usdcAmmStorage = usdcPoolCfg.ammStorage;
        _usdcAmmTreasury = usdcPoolCfg.ammTreasury;
        _usdcAssetManagement = usdcPoolCfg.assetManagement;
        _usdcOpeningFeeRateForSwapUnwind = usdcPoolCfg.openingFeeRateForSwapUnwind;
        _usdcOpeningFeeTreasuryPortionRateForSwapUnwind = usdcPoolCfg.openingFeeTreasuryPortionRateForSwapUnwind;
        _usdcLiquidationLegLimit = usdcPoolCfg.maxLengthOfLiquidatedSwapsPerLeg;
        _usdcTimeBeforeMaturityAllowedToCloseSwapByCommunity = usdcPoolCfg
            .timeBeforeMaturityAllowedToCloseSwapByCommunity;
        _usdcTimeBeforeMaturityAllowedToCloseSwapByBuyer = usdcPoolCfg.timeBeforeMaturityAllowedToCloseSwapByBuyer;
        _usdcMinLiquidationThresholdToCloseBeforeMaturityByCommunity = usdcPoolCfg
            .minLiquidationThresholdToCloseBeforeMaturityByCommunity;
        _usdcMinLiquidationThresholdToCloseBeforeMaturityByBuyer = usdcPoolCfg
            .minLiquidationThresholdToCloseBeforeMaturityByBuyer;
        _usdcMinLeverage = usdcPoolCfg.minLeverage;

        _dai = daiPoolCfg.asset;
        _daiDecimals = daiPoolCfg.decimals;
        _daiAmmStorage = daiPoolCfg.ammStorage;
        _daiAmmTreasury = daiPoolCfg.ammTreasury;
        _daiAssetManagement = daiPoolCfg.assetManagement;
        _daiOpeningFeeRateForSwapUnwind = daiPoolCfg.openingFeeRateForSwapUnwind;
        _daiOpeningFeeTreasuryPortionRateForSwapUnwind = daiPoolCfg.openingFeeTreasuryPortionRateForSwapUnwind;
        _daiLiquidationLegLimit = daiPoolCfg.maxLengthOfLiquidatedSwapsPerLeg;
        _daiTimeBeforeMaturityAllowedToCloseSwapByCommunity = daiPoolCfg
            .timeBeforeMaturityAllowedToCloseSwapByCommunity;
        _daiTimeBeforeMaturityAllowedToCloseSwapByBuyer = daiPoolCfg.timeBeforeMaturityAllowedToCloseSwapByBuyer;
        _daiMinLiquidationThresholdToCloseBeforeMaturityByCommunity = daiPoolCfg
            .minLiquidationThresholdToCloseBeforeMaturityByCommunity;
        _daiMinLiquidationThresholdToCloseBeforeMaturityByBuyer = daiPoolCfg
            .minLiquidationThresholdToCloseBeforeMaturityByBuyer;
        _daiMinLeverage = daiPoolCfg.minLeverage;

        _iporOracle = iporOracle;
        _iporRiskManagementOracle = iporRiskManagementOracle;
        _spreadRouter = spreadRouter;
    }

    function getAmmCloseSwapServicePoolConfiguration(
        address asset
    ) external view override returns (AmmCloseSwapServicePoolConfiguration memory) {
        return _getPoolConfiguration(asset);
    }

    function closeSwapPayFixedUsdt(address beneficiary, uint256 swapId) external override {
        _closeSwapPayFixedWithTransferLiquidationDeposit(beneficiary, swapId, _getPoolConfiguration(_usdt));
    }

    function closeSwapPayFixedUsdc(address beneficiary, uint256 swapId) external override {
        _closeSwapPayFixedWithTransferLiquidationDeposit(beneficiary, swapId, _getPoolConfiguration(_usdc));
    }

    function closeSwapPayFixedDai(address beneficiary, uint256 swapId) external override {
        _closeSwapPayFixedWithTransferLiquidationDeposit(beneficiary, swapId, _getPoolConfiguration(_dai));
    }

    function closeSwapReceiveFixedUsdt(address beneficiary, uint256 swapId) external override {
        _closeSwapReceiveFixedWithTransferLiquidationDeposit(beneficiary, swapId, _getPoolConfiguration(_usdt));
    }

    function closeSwapReceiveFixedUsdc(address beneficiary, uint256 swapId) external override {
        _closeSwapReceiveFixedWithTransferLiquidationDeposit(beneficiary, swapId, _getPoolConfiguration(_usdc));
    }

    function closeSwapReceiveFixedDai(address beneficiary, uint256 swapId) external override {
        _closeSwapReceiveFixedWithTransferLiquidationDeposit(beneficiary, swapId, _getPoolConfiguration(_dai));
    }

    function closeSwapsUsdt(
        address beneficiary,
        uint256[] memory payFixedSwapIds,
        uint256[] memory receiveFixedSwapIds
    )
        external
        override
        returns (
            AmmTypes.IporSwapClosingResult[] memory closedPayFixedSwaps,
            AmmTypes.IporSwapClosingResult[] memory closedReceiveFixedSwaps
        )
    {
        (closedPayFixedSwaps, closedReceiveFixedSwaps) = _closeSwaps(
            beneficiary,
            payFixedSwapIds,
            receiveFixedSwapIds,
            _getPoolConfiguration(_usdt)
        );
    }

    function closeSwapsUsdc(
        address beneficiary,
        uint256[] memory payFixedSwapIds,
        uint256[] memory receiveFixedSwapIds
    )
        external
        override
        returns (
            AmmTypes.IporSwapClosingResult[] memory closedPayFixedSwaps,
            AmmTypes.IporSwapClosingResult[] memory closedReceiveFixedSwaps
        )
    {
        (closedPayFixedSwaps, closedReceiveFixedSwaps) = _closeSwaps(
            beneficiary,
            payFixedSwapIds,
            receiveFixedSwapIds,
            _getPoolConfiguration(_usdc)
        );
    }

    function closeSwapsDai(
        address beneficiary,
        uint256[] memory payFixedSwapIds,
        uint256[] memory receiveFixedSwapIds
    )
        external
        override
        returns (
            AmmTypes.IporSwapClosingResult[] memory closedPayFixedSwaps,
            AmmTypes.IporSwapClosingResult[] memory closedReceiveFixedSwaps
        )
    {
        (closedPayFixedSwaps, closedReceiveFixedSwaps) = _closeSwaps(
            beneficiary,
            payFixedSwapIds,
            receiveFixedSwapIds,
            _getPoolConfiguration(_dai)
        );
    }

    function emergencyCloseSwapPayFixedUsdt(uint256 swapId) external override {
        _closeSwapPayFixedWithTransferLiquidationDeposit(msg.sender, swapId, _getPoolConfiguration(_usdt));
    }

    function emergencyCloseSwapPayFixedUsdc(uint256 swapId) external override {
        _closeSwapPayFixedWithTransferLiquidationDeposit(msg.sender, swapId, _getPoolConfiguration(_usdc));
    }

    function emergencyCloseSwapPayFixedDai(uint256 swapId) external override {
        _closeSwapPayFixedWithTransferLiquidationDeposit(msg.sender, swapId, _getPoolConfiguration(_dai));
    }

    function emergencyCloseSwapReceiveFixedUsdt(uint256 swapId) external override {
        _closeSwapReceiveFixedWithTransferLiquidationDeposit(msg.sender, swapId, _getPoolConfiguration(_usdt));
    }

    function emergencyCloseSwapReceiveFixedUsdc(uint256 swapId) external override {
        _closeSwapReceiveFixedWithTransferLiquidationDeposit(msg.sender, swapId, _getPoolConfiguration(_usdc));
    }

    function emergencyCloseSwapReceiveFixedDai(uint256 swapId) external override {
        _closeSwapReceiveFixedWithTransferLiquidationDeposit(msg.sender, swapId, _getPoolConfiguration(_dai));
    }

    function emergencyCloseSwapsPayFixedUsdt(
        uint256[] memory swapIds
    ) external override returns (AmmTypes.IporSwapClosingResult[] memory closedSwaps) {
        closedSwaps = _closeSwapsPayFixedWithTransferLiquidationDeposit(_usdt, msg.sender, swapIds);
    }

    function emergencyCloseSwapsPayFixedUsdc(
        uint256[] memory swapIds
    ) external override returns (AmmTypes.IporSwapClosingResult[] memory closedSwaps) {
        closedSwaps = _closeSwapsPayFixedWithTransferLiquidationDeposit(_usdc, msg.sender, swapIds);
    }

    function emergencyCloseSwapsPayFixedDai(
        uint256[] memory swapIds
    ) external override returns (AmmTypes.IporSwapClosingResult[] memory closedSwaps) {
        closedSwaps = _closeSwapsPayFixedWithTransferLiquidationDeposit(_dai, msg.sender, swapIds);
    }

    function emergencyCloseSwapsReceiveFixedUsdt(
        uint256[] memory swapIds
    ) external override returns (AmmTypes.IporSwapClosingResult[] memory closedSwaps) {
        closedSwaps = _closeSwapsReceiveFixedWithTransferLiquidationDeposit(_usdt, msg.sender, swapIds);
    }

    function emergencyCloseSwapsReceiveFixedUsdc(
        uint256[] memory swapIds
    ) external override returns (AmmTypes.IporSwapClosingResult[] memory closedSwaps) {
        closedSwaps = _closeSwapsReceiveFixedWithTransferLiquidationDeposit(_usdc, msg.sender, swapIds);
    }

    function emergencyCloseSwapsReceiveFixedDai(
        uint256[] memory swapIds
    ) external override returns (AmmTypes.IporSwapClosingResult[] memory closedSwaps) {
        closedSwaps = _closeSwapsReceiveFixedWithTransferLiquidationDeposit(_dai, msg.sender, swapIds);
    }

    function _getPoolConfiguration(address asset) internal view returns (AmmCloseSwapServicePoolConfiguration memory) {
        if (asset == _usdt) {
            return
                AmmCloseSwapServicePoolConfiguration({
                    asset: _usdt,
                    decimals: _usdtDecimals,
                    ammStorage: _usdtAmmStorage,
                    ammTreasury: _usdtAmmTreasury,
                    assetManagement: _usdtAssetManagement,
                    openingFeeRateForSwapUnwind: _usdtOpeningFeeRateForSwapUnwind,
                    openingFeeTreasuryPortionRateForSwapUnwind: _usdtOpeningFeeTreasuryPortionRateForSwapUnwind,
                    maxLengthOfLiquidatedSwapsPerLeg: _usdtLiquidationLegLimit,
                    timeBeforeMaturityAllowedToCloseSwapByCommunity: _usdtTimeBeforeMaturityAllowedToCloseSwapByCommunity,
                    timeBeforeMaturityAllowedToCloseSwapByBuyer: _usdtTimeBeforeMaturityAllowedToCloseSwapByBuyer,
                    minLiquidationThresholdToCloseBeforeMaturityByCommunity: _usdtMinLiquidationThresholdToCloseBeforeMaturityByCommunity,
                    minLiquidationThresholdToCloseBeforeMaturityByBuyer: _usdtMinLiquidationThresholdToCloseBeforeMaturityByBuyer,
                    minLeverage: _usdtMinLeverage
                });
        } else if (asset == _usdc) {
            return
                AmmCloseSwapServicePoolConfiguration({
                    asset: _usdc,
                    decimals: _usdcDecimals,
                    ammStorage: _usdcAmmStorage,
                    ammTreasury: _usdcAmmTreasury,
                    assetManagement: _usdcAssetManagement,
                    openingFeeRateForSwapUnwind: _usdcOpeningFeeRateForSwapUnwind,
                    openingFeeTreasuryPortionRateForSwapUnwind: _usdcOpeningFeeTreasuryPortionRateForSwapUnwind,
                    maxLengthOfLiquidatedSwapsPerLeg: _usdcLiquidationLegLimit,
                    timeBeforeMaturityAllowedToCloseSwapByCommunity: _usdcTimeBeforeMaturityAllowedToCloseSwapByCommunity,
                    timeBeforeMaturityAllowedToCloseSwapByBuyer: _usdcTimeBeforeMaturityAllowedToCloseSwapByBuyer,
                    minLiquidationThresholdToCloseBeforeMaturityByCommunity: _usdcMinLiquidationThresholdToCloseBeforeMaturityByCommunity,
                    minLiquidationThresholdToCloseBeforeMaturityByBuyer: _usdcMinLiquidationThresholdToCloseBeforeMaturityByBuyer,
                    minLeverage: _usdcMinLeverage
                });
        } else if (asset == _dai) {
            return
                AmmCloseSwapServicePoolConfiguration({
                    asset: _dai,
                    decimals: _daiDecimals,
                    ammStorage: _daiAmmStorage,
                    ammTreasury: _daiAmmTreasury,
                    assetManagement: _daiAssetManagement,
                    openingFeeRateForSwapUnwind: _daiOpeningFeeRateForSwapUnwind,
                    openingFeeTreasuryPortionRateForSwapUnwind: _daiOpeningFeeTreasuryPortionRateForSwapUnwind,
                    maxLengthOfLiquidatedSwapsPerLeg: _daiLiquidationLegLimit,
                    timeBeforeMaturityAllowedToCloseSwapByCommunity: _daiTimeBeforeMaturityAllowedToCloseSwapByCommunity,
                    timeBeforeMaturityAllowedToCloseSwapByBuyer: _daiTimeBeforeMaturityAllowedToCloseSwapByBuyer,
                    minLiquidationThresholdToCloseBeforeMaturityByCommunity: _daiMinLiquidationThresholdToCloseBeforeMaturityByCommunity,
                    minLiquidationThresholdToCloseBeforeMaturityByBuyer: _daiMinLiquidationThresholdToCloseBeforeMaturityByBuyer,
                    minLeverage: _daiMinLeverage
                });
        } else {
            revert(IporErrors.WRONG_ADDRESS);
        }
    }

    function _closeSwaps(
        address beneficiary,
        uint256[] memory payFixedSwapIds,
        uint256[] memory receiveFixedSwapIds,
        AmmCloseSwapServicePoolConfiguration memory poolCfg
    )
        internal
        returns (
            AmmTypes.IporSwapClosingResult[] memory closedPayFixedSwaps,
            AmmTypes.IporSwapClosingResult[] memory closedReceiveFixedSwaps
        )
    {
        require(
            payFixedSwapIds.length <= poolCfg.maxLengthOfLiquidatedSwapsPerLeg &&
                receiveFixedSwapIds.length <= poolCfg.maxLengthOfLiquidatedSwapsPerLeg,
            AmmErrors.MAX_LENGTH_LIQUIDATED_SWAPS_PER_LEG_EXCEEDED
        );

        uint256 payoutForLiquidatorPayFixed;
        uint256 payoutForLiquidatorReceiveFixed;

        (payoutForLiquidatorPayFixed, closedPayFixedSwaps) = _closeSwapsPerLeg(
            beneficiary,
            AmmTypes.SwapDirection.PAY_FIXED_RECEIVE_FLOATING,
            payFixedSwapIds,
            poolCfg
        );

        (payoutForLiquidatorReceiveFixed, closedReceiveFixedSwaps) = _closeSwapsPerLeg(
            beneficiary,
            AmmTypes.SwapDirection.PAY_FLOATING_RECEIVE_FIXED,
            receiveFixedSwapIds,
            poolCfg
        );

        _transferLiquidationDepositAmount(
            beneficiary,
            payoutForLiquidatorPayFixed + payoutForLiquidatorReceiveFixed,
            poolCfg
        );
    }

    function _closeSwapPayFixed(
        address beneficiary,
        uint256 indexValue,
        uint256 ibtPrice,
        AmmTypes.Swap memory swap,
        AmmCloseSwapServicePoolConfiguration memory poolCfg
    ) internal returns (uint256 payoutForLiquidator) {
        (
            int256 payoff,
            uint256 swapUnwindOpeningFeeLPAmount,
            uint256 swapUnwindOpeningFeeTreasuryAmount
        ) = _calculatePayoff(
                0,
                block.timestamp,
                swap.calculatePayoffPayFixed(block.timestamp, ibtPrice),
                indexValue,
                swap,
                poolCfg
            );

        ISpreadCloseSwapService(_spreadRouter).updateTimeWeightedNotionalOnClose(
            poolCfg.asset,
            0,
            swap.tenor,
            swap.notional,
            IAmmStorage(poolCfg.ammStorage).updateStorageWhenCloseSwapPayFixedInternal(
                swap,
                payoff,
                swapUnwindOpeningFeeLPAmount,
                swapUnwindOpeningFeeTreasuryAmount,
                block.timestamp
            ),
            poolCfg.ammStorage
        );

        uint256 transferredToBuyer;

        (transferredToBuyer, payoutForLiquidator) = _transferTokensBasedOnPayoff(beneficiary, payoff, swap, poolCfg);

        emit CloseSwap(swap.id, poolCfg.asset, block.timestamp, beneficiary, transferredToBuyer, payoutForLiquidator);
    }

    function _closeSwapReceiveFixed(
        address beneficiary,
        uint256 indexValue,
        uint256 ibtPrice,
        AmmTypes.Swap memory swap,
        AmmCloseSwapServicePoolConfiguration memory poolCfg
    ) internal returns (uint256 payoutForLiquidator) {
        (
            int256 payoff,
            uint256 swapUnwindOpeningFeeLPAmount,
            uint256 swapUnwindOpeningFeeTreasuryAmount
        ) = _calculatePayoff(
                1,
                block.timestamp,
                swap.calculatePayoffReceiveFixed(block.timestamp, ibtPrice),
                indexValue,
                swap,
                poolCfg
            );
        ISpreadCloseSwapService(_spreadRouter).updateTimeWeightedNotionalOnClose(
            poolCfg.asset,
            1,
            swap.tenor,
            swap.notional,
            IAmmStorage(poolCfg.ammStorage).updateStorageWhenCloseSwapReceiveFixedInternal(
                swap,
                payoff,
                swapUnwindOpeningFeeLPAmount,
                swapUnwindOpeningFeeTreasuryAmount,
                block.timestamp
            ),
            poolCfg.ammStorage
        );

        uint256 transferredToBuyer;

        (transferredToBuyer, payoutForLiquidator) = _transferTokensBasedOnPayoff(beneficiary, payoff, swap, poolCfg);

        emit CloseSwap(swap.id, poolCfg.asset, block.timestamp, beneficiary, transferredToBuyer, payoutForLiquidator);
    }

    function _closeSwapsPerLeg(
        address beneficiary,
        AmmTypes.SwapDirection direction,
        uint256[] memory swapIds,
        AmmCloseSwapServicePoolConfiguration memory poolCfg
    ) internal returns (uint256 payoutForLiquidator, AmmTypes.IporSwapClosingResult[] memory closedSwaps) {
        uint256 swapIdsLength = swapIds.length;
        require(
            swapIdsLength <= poolCfg.maxLengthOfLiquidatedSwapsPerLeg,
            AmmErrors.MAX_LENGTH_LIQUIDATED_SWAPS_PER_LEG_EXCEEDED
        );

        closedSwaps = new AmmTypes.IporSwapClosingResult[](swapIdsLength);
        AmmTypes.Swap memory swap;

        IporTypes.AccruedIpor memory accruedIpor = IIporOracle(_iporOracle).getAccruedIndex(
            block.timestamp,
            poolCfg.asset
        );

        for (uint256 i; i != swapIdsLength; ) {
            uint256 swapId = swapIds[i];
            require(swapId > 0, AmmErrors.INCORRECT_SWAP_ID);

            swap = IAmmStorage(poolCfg.ammStorage).getSwap(direction, swapId);

            if (swap.state == IporTypes.SwapState.ACTIVE) {
                if (direction == AmmTypes.SwapDirection.PAY_FIXED_RECEIVE_FLOATING) {
                    payoutForLiquidator += _closeSwapPayFixed(
                        beneficiary,
                        accruedIpor.indexValue,
                        accruedIpor.ibtPrice,
                        swap,
                        poolCfg
                    );
                } else if (direction == AmmTypes.SwapDirection.PAY_FLOATING_RECEIVE_FIXED) {
                    payoutForLiquidator += _closeSwapReceiveFixed(
                        beneficiary,
                        accruedIpor.indexValue,
                        accruedIpor.ibtPrice,
                        swap,
                        poolCfg
                    );
                } else {
                    revert(AmmErrors.UNSUPPORTED_DIRECTION);
                }
                closedSwaps[i] = AmmTypes.IporSwapClosingResult(swapId, true);
            } else {
                closedSwaps[i] = AmmTypes.IporSwapClosingResult(swapId, false);
            }

            unchecked {
                ++i;
            }
        }
    }

    function _closeSwapsPayFixedWithTransferLiquidationDeposit(
        address asset,
        address beneficiary,
        uint256[] memory swapIds
    ) internal returns (AmmTypes.IporSwapClosingResult[] memory closedSwaps) {
        AmmCloseSwapServicePoolConfiguration memory poolCfg = _getPoolConfiguration(asset);

        uint256 payoutForLiquidator;
        (payoutForLiquidator, closedSwaps) = _closeSwapsPerLeg(
            beneficiary,
            AmmTypes.SwapDirection.PAY_FIXED_RECEIVE_FLOATING,
            swapIds,
            poolCfg
        );

        _transferLiquidationDepositAmount(beneficiary, payoutForLiquidator, poolCfg);
    }

    function _closeSwapsReceiveFixedWithTransferLiquidationDeposit(
        address asset,
        address beneficiary,
        uint256[] memory swapIds
    ) internal returns (AmmTypes.IporSwapClosingResult[] memory closedSwaps) {
        AmmCloseSwapServicePoolConfiguration memory poolCfg = _getPoolConfiguration(asset);

        uint256 payoutForLiquidator;
        (payoutForLiquidator, closedSwaps) = _closeSwapsPerLeg(
            beneficiary,
            AmmTypes.SwapDirection.PAY_FLOATING_RECEIVE_FIXED,
            swapIds,
            poolCfg
        );

        _transferLiquidationDepositAmount(beneficiary, payoutForLiquidator, poolCfg);
    }

    /// @notice Transfer sum of all liquidation deposits to liquidator
    /// @param liquidator address of liquidator
    /// @param liquidationDepositAmount liquidation deposit amount, value represented in 18 decimals
    function _transferLiquidationDepositAmount(
        address liquidator,
        uint256 liquidationDepositAmount,
        AmmCloseSwapServicePoolConfiguration memory poolCfg
    ) internal {
        if (liquidationDepositAmount > 0) {
            IERC20Upgradeable(poolCfg.asset).safeTransferFrom(
                poolCfg.ammTreasury,
                liquidator,
                IporMath.convertWadToAssetDecimals(liquidationDepositAmount, poolCfg.decimals)
            );
        }
    }

    function _calculatePayoff(
        uint256 direction,
        uint256 closeTimestamp,
        int256 swapPayoffToDate,
        uint256 indexValue,
        AmmTypes.Swap memory swap,
        AmmCloseSwapServicePoolConfiguration memory poolCfg
    )
        internal
        returns (int256 payoff, uint256 swapUnwindOpeningFeeLPAmount, uint256 swapUnwindOpeningFeeTreasuryAmount)
    {
        if (
            _validateAllowanceToCloseSwap(OwnerManager.getOwner(), swapPayoffToDate, closeTimestamp, swap, poolCfg) ==
            true
        ) {
            uint256 oppositeLegFixedRate = RiskManagementLogic.calculateOfferedRate(
                direction == 0 ? 1 : 0,
                swap.tenor,
                swap.notional,
                RiskManagementLogic.SpreadOfferedRateContext({
                    asset: poolCfg.asset,
                    ammStorage: poolCfg.ammStorage,
                    iporRiskManagementOracle: _iporRiskManagementOracle,
                    spreadRouter: _spreadRouter,
                    minLeverage: poolCfg.minLeverage,
                    indexValue: indexValue
                })
            );

            int256 swapUnwindAmount = swap.calculateSwapUnwindAmount(
                closeTimestamp,
                swapPayoffToDate,
                oppositeLegFixedRate
            );

            uint256 swapUnwindOpeningFeeAmount = swap.calculateSwapUnwindOpeningFeeAmount(
                closeTimestamp,
                poolCfg.openingFeeRateForSwapUnwind
            );

            (swapUnwindOpeningFeeLPAmount, swapUnwindOpeningFeeTreasuryAmount) = IporSwapLogic.splitOpeningFeeAmount(
                swapUnwindOpeningFeeAmount,
                poolCfg.openingFeeTreasuryPortionRateForSwapUnwind
            );

            payoff = swapPayoffToDate + swapUnwindAmount - swapUnwindOpeningFeeAmount.toInt256();

            emit SwapUnwind(
                swap.id,
                swapPayoffToDate,
                swapUnwindAmount,
                swapUnwindOpeningFeeLPAmount,
                swapUnwindOpeningFeeTreasuryAmount
            );
        } else {
            payoff = swapPayoffToDate;
        }

        if (payoff > 0) {
            if (IporMath.absoluteValue(payoff) > swap.collateral) {
                payoff = swap.collateral.toInt256();
            }
        } else {
            if (IporMath.absoluteValue(payoff) > swap.collateral) {
                payoff = -swap.collateral.toInt256();
            }
        }
    }

    /**
     * @notice Function that transfers payout of the swap to the owner.
     * @dev Function:
     * # checks if swap profit, loss or achieve maturity allows for liquidation
     * # checks if swap's payout is larger than the collateral used to open it
     * # should the payout be larger than the collateral then it transfers payout to the buyer
     * @param swap - Derivative struct
     * @param payoff - Net earnings of the derivative. Can be positive (swap has a possitive earnings) or negative (swap looses)
     * @param poolCfg - Pool configuration
     **/
    function _transferTokensBasedOnPayoff(
        address beneficiary,
        int256 payoff,
        AmmTypes.Swap memory swap,
        AmmCloseSwapServicePoolConfiguration memory poolCfg
    ) internal returns (uint256 transferredToBuyer, uint256 payoutForLiquidator) {
        uint256 absPayoff = IporMath.absoluteValue(payoff);

        if (payoff > 0) {
            //Buyer earns, AmmTreasury looses
            (transferredToBuyer, payoutForLiquidator) = _transferDerivativeAmount(
                beneficiary,
                swap.buyer,
                swap.liquidationDepositAmount,
                swap.collateral + absPayoff,
                poolCfg
            );
        } else {
            //AmmTreasury earns, Buyer looses
            (transferredToBuyer, payoutForLiquidator) = _transferDerivativeAmount(
                beneficiary,
                swap.buyer,
                swap.liquidationDepositAmount,
                swap.collateral - absPayoff,
                poolCfg
            );
        }
    }

    function _validateAllowanceToCloseSwap(
        address owner,
        int256 payoff,
        uint256 closeTimestamp,
        AmmTypes.Swap memory swap,
        AmmCloseSwapServicePoolConfiguration memory poolCfg
    ) internal view returns (bool swapUnwindRequired) {
        uint256 closableStatus = _getClosableStatusForSwap(owner, payoff, closeTimestamp, swap, poolCfg);

        if (closableStatus == 1) revert(AmmErrors.INCORRECT_SWAP_STATUS);
        if (closableStatus == 2) revert(AmmErrors.CANNOT_CLOSE_SWAP_SENDER_IS_NOT_BUYER_NOR_LIQUIDATOR);

        if (closableStatus == 3 || closableStatus == 4) {
            if (msg.sender == swap.buyer) {
                swapUnwindRequired = true;
            } else {
                if (closableStatus == 3) revert(AmmErrors.CANNOT_CLOSE_SWAP_CLOSING_IS_TOO_EARLY_FOR_BUYER);
                if (closableStatus == 4) revert(AmmErrors.CANNOT_CLOSE_SWAP_CLOSING_IS_TOO_EARLY);
            }
        }
    }

    function _closeSwapPayFixedWithTransferLiquidationDeposit(
        address beneficiary,
        uint256 swapId,
        AmmCloseSwapServicePoolConfiguration memory poolCfg
    ) internal {
        require(swapId > 0, AmmErrors.INCORRECT_SWAP_ID);
        IporTypes.AccruedIpor memory accruedIpor = IIporOracle(_iporOracle).getAccruedIndex(
            block.timestamp,
            poolCfg.asset
        );
        _transferLiquidationDepositAmount(
            beneficiary,
            _closeSwapPayFixed(
                beneficiary,
                accruedIpor.indexValue,
                accruedIpor.ibtPrice,
                IAmmStorage(poolCfg.ammStorage).getSwap(AmmTypes.SwapDirection.PAY_FIXED_RECEIVE_FLOATING, swapId),
                poolCfg
            ),
            poolCfg
        );
    }

    function _closeSwapReceiveFixedWithTransferLiquidationDeposit(
        address beneficiary,
        uint256 swapId,
        AmmCloseSwapServicePoolConfiguration memory poolCfg
    ) internal {
        require(swapId > 0, AmmErrors.INCORRECT_SWAP_ID);

        IporTypes.AccruedIpor memory accruedIpor = IIporOracle(_iporOracle).getAccruedIndex(
            block.timestamp,
            poolCfg.asset
        );

        _transferLiquidationDepositAmount(
            beneficiary,
            _closeSwapReceiveFixed(
                beneficiary,
                accruedIpor.indexValue,
                accruedIpor.ibtPrice,
                IAmmStorage(poolCfg.ammStorage).getSwap(AmmTypes.SwapDirection.PAY_FLOATING_RECEIVE_FIXED, swapId),
                poolCfg
            ),
            poolCfg
        );
    }

    /// @notice Check closable status for Swap given as a parameter.
    /// @param owner The address of the owner
    /// @param swap The swap to be checked
    /// @param payoff The payoff of the swap
    /// @param closeTimestamp The timestamp of closing
    /// @return closableStatus Closable status for Swap.
    /// @dev Closable status is a one of the following values:
    /// 0 - Swap is closable
    /// 1 - Swap is already closed
    /// 2 - Swap state required Buyer or Liquidator to close. Sender is not Buyer nor Liquidator.
    /// 3 - Cannot close swap, closing is too early for Buyer
    /// 4 - Cannot close swap, closing is too early for Community
    function _getClosableStatusForSwap(
        address owner,
        int256 payoff,
        uint256 closeTimestamp,
        AmmTypes.Swap memory swap,
        AmmCloseSwapServicePoolConfiguration memory poolCfg
    ) internal view returns (uint256) {
        if (swap.state != IporTypes.SwapState.ACTIVE) {
            return 1;
        }

        address msgSender = msg.sender;

        if (msgSender != owner) {
            uint256 absPayoff = IporMath.absoluteValue(payoff);

            uint256 minPayoffToCloseBeforeMaturityByCommunity = IporMath.percentOf(
                swap.collateral,
                poolCfg.minLiquidationThresholdToCloseBeforeMaturityByCommunity
            );

            uint256 swapEndTimestamp = swap.getSwapEndTimestamp();

            if (closeTimestamp >= swapEndTimestamp) {
                if (absPayoff < minPayoffToCloseBeforeMaturityByCommunity || absPayoff == swap.collateral) {
                    if (
                        AmmConfigurationManager.isSwapLiquidator(poolCfg.asset, msgSender) != true &&
                        msgSender != swap.buyer
                    ) {
                        return 2;
                    }
                }
            } else {
                uint256 minPayoffToCloseBeforeMaturityByBuyer = IporMath.percentOf(
                    swap.collateral,
                    poolCfg.minLiquidationThresholdToCloseBeforeMaturityByBuyer
                );

                if (
                    (absPayoff >= minPayoffToCloseBeforeMaturityByBuyer &&
                        absPayoff < minPayoffToCloseBeforeMaturityByCommunity) || absPayoff == swap.collateral
                ) {
                    if (
                        AmmConfigurationManager.isSwapLiquidator(poolCfg.asset, msgSender) != true &&
                        msgSender != swap.buyer
                    ) {
                        return 2;
                    }
                }

                if (absPayoff < minPayoffToCloseBeforeMaturityByBuyer) {
                    if (msgSender == swap.buyer) {
                        if (swapEndTimestamp - poolCfg.timeBeforeMaturityAllowedToCloseSwapByBuyer > closeTimestamp) {
                            return 3;
                        }
                    } else {
                        if (
                            swapEndTimestamp - poolCfg.timeBeforeMaturityAllowedToCloseSwapByCommunity > closeTimestamp
                        ) {
                            return 4;
                        }
                    }
                }
            }
        }

        return 0;
    }

    function _transferDerivativeAmount(
        address beneficiary,
        address buyer,
        uint256 liquidationDepositAmount,
        uint256 transferAmount,
        AmmCloseSwapServicePoolConfiguration memory poolCfg
    ) internal returns (uint256 transferredToBuyer, uint256 payoutForLiquidator) {
        if (beneficiary == buyer) {
            transferAmount = transferAmount + liquidationDepositAmount;
        } else {
            //transfer liquidation deposit amount from AmmTreasury to Liquidator address (beneficiary),
            // transfer to be made outside this function, to avoid multiple transfers
            payoutForLiquidator = liquidationDepositAmount;
        }

        if (transferAmount > 0) {
            uint256 transferAmountAssetDecimals = IporMath.convertWadToAssetDecimals(transferAmount, poolCfg.decimals);
            uint256 wadAmmTreasuryErc20BalanceBeforeRedeem = IERC20Upgradeable(poolCfg.asset).balanceOf(
                poolCfg.ammTreasury
            );

            if (wadAmmTreasuryErc20BalanceBeforeRedeem <= transferAmountAssetDecimals) {
                AmmTypes.AmmPoolCoreModel memory model;

                model.ammStorage = poolCfg.ammStorage;
                model.ammTreasury = poolCfg.ammTreasury;
                model.assetManagement = poolCfg.assetManagement;

                IporTypes.AmmBalancesMemory memory balance = model.getAccruedBalance();

                StorageLib.AmmPoolsParamsValue memory ammPoolsParamsCfg = AmmConfigurationManager.getAmmPoolsParams(
                    poolCfg.asset
                );

                int256 rebalanceAmount = AssetManagementLogic.calculateRebalanceAmountBeforeWithdraw(
                    wadAmmTreasuryErc20BalanceBeforeRedeem,
                    balance.vault,
                    transferAmount + liquidationDepositAmount,
                    uint256(ammPoolsParamsCfg.ammTreasuryAndAssetManagementRatio) * 1e14
                );

                if (rebalanceAmount < 0) {
                    IAmmTreasury(poolCfg.ammTreasury).withdrawFromAssetManagementInternal(
                        (-rebalanceAmount).toUint256()
                    );
                }
            }

            //transfer from AmmTreasury to Trader
            IERC20Upgradeable(poolCfg.asset).safeTransferFrom(poolCfg.ammTreasury, buyer, transferAmountAssetDecimals);

            transferredToBuyer = IporMath.convertToWad(transferAmountAssetDecimals, poolCfg.decimals);
        }
    }
}

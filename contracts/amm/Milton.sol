// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.16;
import "../interfaces/types/AmmTypes.sol";
import "../libraries/math/IporMath.sol";
import "../interfaces/IIporOracle.sol";
import "../interfaces/IMilton.sol";
import "../interfaces/IJoseph.sol";
import "../interfaces/IStanley.sol";
import "../interfaces/IMiltonSpreadModel.sol";
import "../interfaces/IIporRiskManagementOracle.sol";
import "./MiltonInternal.sol";
import "./libraries/types/AmmMiltonTypes.sol";
import "./MiltonStorage.sol";

/**
 * @title Milton - Automated Market Maker for trading Interest Rate Swaps derivatives based on IPOR Index.
 * @dev Milton is scoped per asset (USDT, USDC, DAI or other type of ERC20 asset included by the DAO)
 * Users can:
 *  # open and close own interest rate swaps
 *  # liquidate other's swaps at maturity
 *  # calculate the SOAP
 *  # calculate spread
 * @author IPOR Labs
 */
abstract contract Milton is MiltonInternal, IMilton {
    using SafeERC20Upgradeable for IERC20Upgradeable;
    using SafeCast for uint256;
    using SafeCast for uint128;
    using SafeCast for int256;
    using IporSwapLogic for IporTypes.IporSwapMemory;

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor(address iporRiskManagementOracle) MiltonInternal(iporRiskManagementOracle) {
        _disableInitializers();
    }

    /**
     * @param paused - Initial flag to determine if smart contract is paused or not
     * @param asset - Instance of Milton is initialised in the context of the given ERC20 asset. Every trasaction is by the default scoped to that ERC20.
     * @param iporOracle - Address of Oracle treated as the source of true IPOR rate.
     * @param miltonStorage - Address of contract responsible for managing the state of Milton.
     * @param miltonSpreadModel - Address of smart contract responsible for calculating spreads on the interst rate swaps.
     * @param stanley - Address of smart contract responsible for asset management.
     * For more details refer to the documentation: https://ipor-labs.gitbook.io/ipor-labs/automated-market-maker/asset-management
     **/

    function initialize(
        bool paused,
        address asset,
        address iporOracle,
        address miltonStorage,
        address miltonSpreadModel,
        address stanley
    ) public initializer {
        __Pausable_init();
        __Ownable_init();
        __UUPSUpgradeable_init();

        require(asset != address(0), IporErrors.WRONG_ADDRESS);
        require(iporOracle != address(0), IporErrors.WRONG_ADDRESS);
        require(miltonStorage != address(0), IporErrors.WRONG_ADDRESS);
        require(miltonSpreadModel != address(0), IporErrors.WRONG_ADDRESS);
        require(stanley != address(0), IporErrors.WRONG_ADDRESS);
        require(_getDecimals() == ERC20Upgradeable(asset).decimals(), IporErrors.WRONG_DECIMALS);

        if (paused) {
            _pause();
        }

        _miltonStorage = IMiltonStorage(miltonStorage);
        _miltonSpreadModel = IMiltonSpreadModel(miltonSpreadModel);
        _iporOracle = IIporOracle(iporOracle);
        _asset = asset;
        _stanley = IStanley(stanley);
    }

    function calculateSoap()
        external
        view
        override
        returns (
            int256 soapPayFixed,
            int256 soapReceiveFixed,
            int256 soap
        )
    {
        (int256 _soapPayFixed, int256 _soapReceiveFixed, int256 _soap) = _calculateSoap(block.timestamp);
        return (soapPayFixed = _soapPayFixed, soapReceiveFixed = _soapReceiveFixed, soap = _soap);
    }

    function getClosableStatusForPayFixedSwap(uint256 swapId) external view override returns (uint256 closableStatus) {
        IporTypes.IporSwapMemory memory iporSwap = _getMiltonStorage().getSwapPayFixed(swapId);
        uint256 accruedIbtPrice = _getIporOracle().calculateAccruedIbtPrice(_asset, block.timestamp);

        closableStatus = _getClosableStatusForSwap(
            _msgSender(),
            owner(),
            iporSwap,
            iporSwap.calculatePayoffPayFixed(block.timestamp, accruedIbtPrice),
            block.timestamp
        );
    }

    function getClosableStatusForReceiveFixedSwap(uint256 swapId)
        external
        view
        override
        returns (uint256 closableStatus)
    {
        IporTypes.IporSwapMemory memory iporSwap = _getMiltonStorage().getSwapReceiveFixed(swapId);
        uint256 accruedIbtPrice = _getIporOracle().calculateAccruedIbtPrice(_asset, block.timestamp);

        closableStatus = _getClosableStatusForSwap(
            _msgSender(),
            owner(),
            iporSwap,
            iporSwap.calculatePayoffReceiveFixed(block.timestamp, accruedIbtPrice),
            block.timestamp
        );
    }

    function closeSwapPayFixed(uint256 swapId) external override nonReentrant whenNotPaused {
        _closeSwapPayFixedWithTransferLiquidationDeposit(swapId, block.timestamp);
    }

    function closeSwapReceiveFixed(uint256 swapId) external override nonReentrant whenNotPaused {
        _closeSwapReceiveFixedWithTransferLiquidationDeposit(swapId, block.timestamp);
    }

    function closeSwaps(uint256[] memory payFixedSwapIds, uint256[] memory receiveFixedSwapIds)
        external
        override
        nonReentrant
        whenNotPaused
        returns (
            MiltonTypes.IporSwapClosingResult[] memory closedPayFixedSwaps,
            MiltonTypes.IporSwapClosingResult[] memory closedReceiveFixedSwaps
        )
    {
        (closedPayFixedSwaps, closedReceiveFixedSwaps) = _closeSwaps(
            payFixedSwapIds,
            receiveFixedSwapIds,
            block.timestamp
        );
    }

    function emergencyCloseSwapPayFixed(uint256 swapId) external override onlyOwner whenPaused {
        _closeSwapPayFixedWithTransferLiquidationDeposit(swapId, block.timestamp);
    }

    function emergencyCloseSwapReceiveFixed(uint256 swapId) external override onlyOwner whenPaused {
        _closeSwapReceiveFixedWithTransferLiquidationDeposit(swapId, block.timestamp);
    }

    function emergencyCloseSwapsPayFixed(uint256[] memory swapIds)
        external
        override
        onlyOwner
        whenPaused
        returns (MiltonTypes.IporSwapClosingResult[] memory closedSwaps)
    {
        closedSwaps = _closeSwapsPayFixedWithTransferLiquidationDeposit(swapIds, block.timestamp);
    }

    function emergencyCloseSwapsReceiveFixed(uint256[] memory swapIds)
        external
        override
        onlyOwner
        whenPaused
        returns (MiltonTypes.IporSwapClosingResult[] memory closedSwaps)
    {
        closedSwaps = _closeSwapsReceiveFixedWithTransferLiquidationDeposit(swapIds, block.timestamp);
    }

    function _closeSwaps(
        uint256[] memory payFixedSwapIds,
        uint256[] memory receiveFixedSwapIds,
        uint256 closeTimestamp
    )
        internal
        returns (
            MiltonTypes.IporSwapClosingResult[] memory closedPayFixedSwaps,
            MiltonTypes.IporSwapClosingResult[] memory closedReceiveFixedSwaps
        )
    {
        require(
            payFixedSwapIds.length <= _getLiquidationLegLimit() &&
                receiveFixedSwapIds.length <= _getLiquidationLegLimit(),
            MiltonErrors.LIQUIDATION_LEG_LIMIT_EXCEEDED
        );

        uint256 payoutForLiquidatorPayFixed;
        uint256 payoutForLiquidatorReceiveFixed;

        (payoutForLiquidatorPayFixed, closedPayFixedSwaps) = _closeSwapsPayFixed(payFixedSwapIds, closeTimestamp);

        (payoutForLiquidatorReceiveFixed, closedReceiveFixedSwaps) = _closeSwapsReceiveFixed(
            receiveFixedSwapIds,
            closeTimestamp
        );

        _transferLiquidationDepositAmount(_msgSender(), payoutForLiquidatorPayFixed + payoutForLiquidatorReceiveFixed);
    }

    function _closeSwapPayFixedWithTransferLiquidationDeposit(uint256 swapId, uint256 closeTimestamp) internal {
        require(swapId > 0, MiltonErrors.INCORRECT_SWAP_ID);

        IporTypes.IporSwapMemory memory iporSwap = _getMiltonStorage().getSwapPayFixed(swapId);

        _transferLiquidationDepositAmount(_msgSender(), _closeSwapPayFixed(iporSwap, closeTimestamp));
    }

    function _closeSwapReceiveFixedWithTransferLiquidationDeposit(uint256 swapId, uint256 closeTimestamp) internal {
        require(swapId > 0, MiltonErrors.INCORRECT_SWAP_ID);

        IporTypes.IporSwapMemory memory iporSwap = _getMiltonStorage().getSwapReceiveFixed(swapId);

        _transferLiquidationDepositAmount(_msgSender(), _closeSwapReceiveFixed(iporSwap, closeTimestamp));
    }

    function _closeSwapsPayFixedWithTransferLiquidationDeposit(uint256[] memory swapIds, uint256 closeTimestamp)
        internal
        returns (MiltonTypes.IporSwapClosingResult[] memory closedSwaps)
    {
        uint256 payoutForLiquidator;
        (payoutForLiquidator, closedSwaps) = _closeSwapsPayFixed(swapIds, closeTimestamp);
        _transferLiquidationDepositAmount(_msgSender(), payoutForLiquidator);
    }

    function _closeSwapsReceiveFixedWithTransferLiquidationDeposit(uint256[] memory swapIds, uint256 closeTimestamp)
        internal
        returns (MiltonTypes.IporSwapClosingResult[] memory closedSwaps)
    {
        uint256 payoutForLiquidator;
        (payoutForLiquidator, closedSwaps) = _closeSwapsReceiveFixed(swapIds, closeTimestamp);
        _transferLiquidationDepositAmount(_msgSender(), payoutForLiquidator);
    }

    function _calculatePayoff(
        IporTypes.IporSwapMemory memory iporSwap,
        MiltonTypes.SwapDirection direction,
        uint256 closeTimestamp,
        int256 swapPayoffToDate,
        IporTypes.AccruedIpor memory accruedIpor,
        IporTypes.MiltonBalancesMemory memory balance
    ) internal returns (int256 payoff) {
        bool swapUnwindRequired = _validateAllowanceToCloseSwap(
            _msgSender(),
            owner(),
            iporSwap,
            swapPayoffToDate,
            closeTimestamp
        );

        int256 swapUnwindValueAndOpeningFee;

        if (swapUnwindRequired == true) {
            uint256 oppositeLegFixedRate;

            if (direction == MiltonTypes.SwapDirection.PAY_FIXED_RECEIVE_FLOATING) {
                oppositeLegFixedRate = _miltonSpreadModel.calculateQuoteReceiveFixed(accruedIpor, balance);
            } else {
                oppositeLegFixedRate = _miltonSpreadModel.calculateQuotePayFixed(accruedIpor, balance);
            }

            int256 swapUnwindValue = iporSwap.calculateSwapUnwindValue(
                closeTimestamp,
                swapPayoffToDate,
                oppositeLegFixedRate,
                _getOpeningFeeRateForSwapUnwind()
            );

            uint256 swapUnwindOpeningFee = IporMath.division(
                iporSwap.notional * _getOpeningFeeRate() * IporMath.division(28 * Constants.D18, 365),
                Constants.D36
            );

            swapUnwindValueAndOpeningFee = swapUnwindValue - swapUnwindOpeningFee.toInt256();

            emit SwapUnwind(iporSwap.id, swapPayoffToDate, swapUnwindValue, swapUnwindOpeningFee);
        }

        payoff = swapPayoffToDate + swapUnwindValueAndOpeningFee;
    }

    function _closeSwapPayFixed(IporTypes.IporSwapMemory memory iporSwap, uint256 closeTimestamp)
        internal
        returns (uint256 payoutForLiquidator)
    {
        address asset = _asset;

        IMiltonStorage miltonStorage = _getMiltonStorage();
        IporTypes.AccruedIpor memory accruedIpor = _getIporOracle().getAccruedIndex(closeTimestamp, asset);

        int256 payoff = _calculatePayoff(
            iporSwap,
            MiltonTypes.SwapDirection.PAY_FIXED_RECEIVE_FLOATING,
            closeTimestamp,
            iporSwap.calculatePayoffPayFixed(closeTimestamp, accruedIpor.ibtPrice),
            accruedIpor,
            miltonStorage.getBalance()
        );

        miltonStorage.updateStorageWhenCloseSwapPayFixed(iporSwap, payoff, closeTimestamp);

        uint256 transferredToBuyer;

        (transferredToBuyer, payoutForLiquidator) = _transferTokensBasedOnPayoff(iporSwap, payoff);

        emit CloseSwap(iporSwap.id, asset, closeTimestamp, _msgSender(), transferredToBuyer, payoutForLiquidator);
    }

    /// @notice Check closable status for Swap given as a parameter.
    /// @param msgSender The address of the caller
    /// @param owner The address of the owner
    /// @param iporSwap The swap to be checked
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
        address msgSender,
        address owner,
        IporTypes.IporSwapMemory memory iporSwap,
        int256 payoff,
        uint256 closeTimestamp
    ) internal view returns (uint256) {
        if (iporSwap.state != uint256(AmmTypes.SwapState.ACTIVE)) {
            return 1;
        }

        if (msgSender != owner) {
            uint256 absPayoff = IporMath.absoluteValue(payoff);

            uint256 minPayoffToCloseBeforeMaturityByCommunity = IporMath.percentOf(
                iporSwap.collateral,
                _getMinLiquidationThresholdToCloseBeforeMaturityByCommunity()
            );

            if (closeTimestamp >= iporSwap.endTimestamp) {
                if (absPayoff < minPayoffToCloseBeforeMaturityByCommunity || absPayoff == iporSwap.collateral) {
                    if (_swapLiquidators[msgSender] != true && msgSender != iporSwap.buyer) {
                        return 2;
                    }
                }
            } else {
                uint256 minPayoffToCloseBeforeMaturityByBuyer = IporMath.percentOf(
                    iporSwap.collateral,
                    _getMinLiquidationThresholdToCloseBeforeMaturityByBuyer()
                );

                if (
                    (absPayoff >= minPayoffToCloseBeforeMaturityByBuyer &&
                        absPayoff < minPayoffToCloseBeforeMaturityByCommunity) || absPayoff == iporSwap.collateral
                ) {
                    if (_swapLiquidators[msgSender] != true && msgSender != iporSwap.buyer) {
                        return 2;
                    }
                }

                if (absPayoff < minPayoffToCloseBeforeMaturityByBuyer) {
                    if (msgSender == iporSwap.buyer) {
                        if (
                            iporSwap.endTimestamp - _getTimeBeforeMaturityAllowedToCloseSwapByBuyer() > closeTimestamp
                        ) {
                            return 3;
                        }
                    } else {
                        if (
                            iporSwap.endTimestamp - _getTimeBeforeMaturityAllowedToCloseSwapByCommunity() >
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

    function _validateAllowanceToCloseSwap(
        address msgSender,
        address owner,
        IporTypes.IporSwapMemory memory iporSwap,
        int256 payoff,
        uint256 closeTimestamp
    ) internal view returns (bool swapUnwindRequired) {
        uint256 closableStatus = _getClosableStatusForSwap(msgSender, owner, iporSwap, payoff, closeTimestamp);

        if (closableStatus == 1) revert(MiltonErrors.INCORRECT_SWAP_STATUS);
        if (closableStatus == 2) revert(MiltonErrors.CANNOT_CLOSE_SWAP_SENDER_IS_NOT_BUYER_NOR_LIQUIDATOR);

        if (closableStatus == 3 || closableStatus == 4) {
            if (msgSender == iporSwap.buyer) {
                swapUnwindRequired = true;
            } else {
                if (closableStatus == 3) revert(MiltonErrors.CANNOT_CLOSE_SWAP_CLOSING_IS_TOO_EARLY_FOR_BUYER);
                if (closableStatus == 4) revert(MiltonErrors.CANNOT_CLOSE_SWAP_CLOSING_IS_TOO_EARLY);
            }
        }
    }

    function _closeSwapReceiveFixed(IporTypes.IporSwapMemory memory iporSwap, uint256 closeTimestamp)
        internal
        returns (uint256 payoutForLiquidator)
    {
        address asset = _asset;
        IMiltonStorage miltonStorage = _getMiltonStorage();
        IporTypes.AccruedIpor memory accruedIpor = _getIporOracle().getAccruedIndex(closeTimestamp, asset);

        int256 payoff = _calculatePayoff(
            iporSwap,
            MiltonTypes.SwapDirection.PAY_FLOATING_RECEIVE_FIXED,
            closeTimestamp,
            iporSwap.calculatePayoffReceiveFixed(closeTimestamp, accruedIpor.ibtPrice),
            accruedIpor,
            miltonStorage.getBalance()
        );

        miltonStorage.updateStorageWhenCloseSwapReceiveFixed(iporSwap, payoff, closeTimestamp);

        uint256 transferredToBuyer;

        (transferredToBuyer, payoutForLiquidator) = _transferTokensBasedOnPayoff(iporSwap, payoff);

        emit CloseSwap(iporSwap.id, asset, closeTimestamp, _msgSender(), transferredToBuyer, payoutForLiquidator);
    }

    function _closeSwapsPayFixed(uint256[] memory swapIds, uint256 closeTimestamp)
        internal
        returns (uint256 payoutForLiquidator, MiltonTypes.IporSwapClosingResult[] memory closedSwaps)
    {
        require(swapIds.length <= _getLiquidationLegLimit(), MiltonErrors.LIQUIDATION_LEG_LIMIT_EXCEEDED);

        closedSwaps = new MiltonTypes.IporSwapClosingResult[](swapIds.length);

        for (uint256 i = 0; i < swapIds.length; i++) {
            uint256 swapId = swapIds[i];
            require(swapId > 0, MiltonErrors.INCORRECT_SWAP_ID);

            IporTypes.IporSwapMemory memory iporSwap = _getMiltonStorage().getSwapPayFixed(swapId);

            if (iporSwap.state == uint256(AmmTypes.SwapState.ACTIVE)) {
                payoutForLiquidator += _closeSwapPayFixed(iporSwap, closeTimestamp);
                closedSwaps[i] = MiltonTypes.IporSwapClosingResult(swapId, true);
            } else {
                closedSwaps[i] = MiltonTypes.IporSwapClosingResult(swapId, false);
            }
        }
    }

    function _closeSwapsReceiveFixed(uint256[] memory swapIds, uint256 closeTimestamp)
        internal
        returns (uint256 payoutForLiquidator, MiltonTypes.IporSwapClosingResult[] memory closedSwaps)
    {
        require(swapIds.length <= _getLiquidationLegLimit(), MiltonErrors.LIQUIDATION_LEG_LIMIT_EXCEEDED);

        closedSwaps = new MiltonTypes.IporSwapClosingResult[](swapIds.length);

        for (uint256 i = 0; i < swapIds.length; i++) {
            uint256 swapId = swapIds[i];
            require(swapId > 0, MiltonErrors.INCORRECT_SWAP_ID);

            IporTypes.IporSwapMemory memory iporSwap = _getMiltonStorage().getSwapReceiveFixed(swapId);

            if (iporSwap.state == uint256(AmmTypes.SwapState.ACTIVE)) {
                payoutForLiquidator += _closeSwapReceiveFixed(iporSwap, closeTimestamp);
                closedSwaps[i] = MiltonTypes.IporSwapClosingResult(swapId, true);
            } else {
                closedSwaps[i] = MiltonTypes.IporSwapClosingResult(swapId, false);
            }
        }
    }

    /**
     * @notice Function that transfers payout of the swap to the owner.
     * @dev Function:
     * # checks if swap profit, loss or maturity allows for liquidataion
     * # checks if swap's payout is larger than the collateral used to open it
     * # should the payout be larger than the collateral then it transfers payout to the buyer
     * @param derivativeItem - Derivative struct
     * @param payoff - Net earnings of the derivative. Can be positive (swap has a possitive earnings) or negative (swap looses)
     **/

    function _transferTokensBasedOnPayoff(IporTypes.IporSwapMemory memory derivativeItem, int256 payoff)
        internal
        returns (uint256 transferredToBuyer, uint256 payoutForLiquidator)
    {
        uint256 absPayoff = IporMath.absoluteValue(payoff);

        if (payoff > 0) {
            //Buyer earns, Milton looses
            (transferredToBuyer, payoutForLiquidator) = _transferDerivativeAmount(
                derivativeItem.buyer,
                derivativeItem.liquidationDepositAmount,
                derivativeItem.collateral + absPayoff
            );
        } else {
            //Milton earns, Buyer looses
            (transferredToBuyer, payoutForLiquidator) = _transferDerivativeAmount(
                derivativeItem.buyer,
                derivativeItem.liquidationDepositAmount,
                derivativeItem.collateral - absPayoff
            );
        }
    }

    /**
     * @notice Function that transfers the assets at the time of derivative closing
     * @dev It trasfers the asset to the swap buyer and the liquidator.
     * Should buyer and the liquidator are the same entity it performs only one transfer.
     * @param buyer - address that opened the swap
     * @param liquidationDepositAmount - amount of asset transfered to the liquidator, value represented in 18 decimals
     * @param transferAmount - amount of asset transfered to the swap owner
     **/
    function _transferDerivativeAmount(
        address buyer,
        uint256 liquidationDepositAmount,
        uint256 transferAmount
    ) internal returns (uint256 transferredToBuyer, uint256 payoutForLiquidator) {
        uint256 decimals = _getDecimals();

        if (_msgSender() == buyer) {
            transferAmount = transferAmount + liquidationDepositAmount;
        } else {
            //transfer liquidation deposit amount from Milton to Liquidator,
            // transfer to be made outside this function, to avoid multiple transfers
            payoutForLiquidator = liquidationDepositAmount;
        }

        if (transferAmount > 0) {
            uint256 transferAmountAssetDecimals = IporMath.convertWadToAssetDecimals(transferAmount, decimals);
            uint256 wadMiltonErc20BalanceBeforeRedeem = IERC20Upgradeable(_asset).balanceOf(address(this));
            if (wadMiltonErc20BalanceBeforeRedeem <= transferAmountAssetDecimals) {
                IporTypes.MiltonBalancesMemory memory balance = _getAccruedBalance();
                int256 rebalanceAmount = IJoseph(_joseph).calculateRebalanceAmountBeforeWithdraw(
                    wadMiltonErc20BalanceBeforeRedeem,
                    balance.vault,
                    transferAmount + liquidationDepositAmount
                );

                if (rebalanceAmount < 0) {
                    _withdrawFromStanley((-rebalanceAmount).toUint256());
                }
            }

            //transfer from Milton to Trader
            IERC20Upgradeable(_asset).safeTransfer(buyer, transferAmountAssetDecimals);

            transferredToBuyer = IporMath.convertToWad(transferAmountAssetDecimals, decimals);
        }
    }

    //Transfer sum of all liquidation deposits to liquidator
    /// @param liquidator address of liquidator
    /// @param liquidationDepositAmount liquidation deposit amount, value represented in 18 decimals
    function _transferLiquidationDepositAmount(address liquidator, uint256 liquidationDepositAmount) internal {
        if (liquidationDepositAmount > 0) {
            IERC20Upgradeable(_asset).safeTransfer(
                liquidator,
                IporMath.convertWadToAssetDecimals(liquidationDepositAmount, _getDecimals())
            );
        }
    }

    /**
     * @notice Function run at the time of the contract upgrade via proxy. Available only to the contract's owner.
     **/
    //solhint-disable no-empty-blocks
    function _authorizeUpgrade(address) internal override onlyOwner {}
}

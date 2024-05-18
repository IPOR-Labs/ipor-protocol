// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.20;

import "@openzeppelin/contracts/utils/math/SafeCast.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";

import "../../interfaces/IProxyImplementation.sol";
import "../../interfaces/types/AmmStorageTypes.sol";
import "../interfaces/IAmmStorageBaseV1.sol";
import "../../libraries/Constants.sol";
import "../../libraries/PaginationUtils.sol";
import "../../libraries/IporContractValidator.sol";
import "../../security/IporOwnableUpgradeable.sol";
import "../../amm/libraries/types/AmmInternalTypes.sol";
import "../../amm/libraries/types/StorageInternalTypes.sol";
import "../../amm/libraries/SoapIndicatorRebalanceLogic.sol";
import "../types/StorageTypesBaseV1.sol";

/// @dev all stored values related to tokens are in 18 decimals.
contract AmmStorageBaseV1 is
    Initializable,
    UUPSUpgradeable,
    IporOwnableUpgradeable,
    IAmmStorageBaseV1,
    IProxyImplementation
{
    using IporContractValidator for address;
    using SafeCast for uint256;
    using SafeCast for int256;
    using SoapIndicatorRebalanceLogic for AmmStorageTypes.SoapIndicators;

    /// @dev to achieve 18 decimals precision we multiply by 1e12 because for stETH pool liquidationDepositAmount is represented in 6 decimals in storage.
    /// @dev in structure AmmTypes.NewSwap liquidationDepositAmount is represented in 6 decimals for stETH swaps.
    uint256 private constant _DECIMALS_OFFSET_LIQUIDATION_DEPOSIT = 1e12;

    address public immutable iporProtocolRouter;

    uint32 private _lastSwapId;

    StorageTypesBaseV1.Balance internal _balance;
    StorageInternalTypes.SoapIndicatorsStorage internal _soapIndicatorsPayFixed;
    StorageInternalTypes.SoapIndicatorsStorage internal _soapIndicatorsReceiveFixed;
    StorageInternalTypes.SwapContainer internal _swapsPayFixed;
    StorageInternalTypes.SwapContainer internal _swapsReceiveFixed;

    mapping(IporTypes.SwapTenor tenor => AmmInternalTypes.OpenSwapList) private _openedSwapsPayFixed;
    mapping(IporTypes.SwapTenor tenor => AmmInternalTypes.OpenSwapList) private _openedSwapsReceiveFixed;

    uint128 internal totalLiquidationDepositBalance;

    modifier onlyRouter() {
        if (msg.sender != iporProtocolRouter) {
            revert IporErrors.CallerNotIporProtocolRouter(IporErrors.CALLER_NOT_IPOR_PROTOCOL_ROUTER, msg.sender);
        }
        _;
    }

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor(address iporProtocolRouterInput) {
        iporProtocolRouter = iporProtocolRouterInput.checkAddress();
        _disableInitializers();
    }

    function initialize() public initializer {
        __Ownable_init();
        __UUPSUpgradeable_init();
    }

    function getVersion() external pure virtual override returns (uint256) {
        return 2_001;
    }

    function getLastSwapId() external view override returns (uint256) {
        return _lastSwapId;
    }

    function getLastOpenedSwap(
        IporTypes.SwapTenor tenor,
        uint256 direction
    ) external view override returns (AmmInternalTypes.OpenSwapItem memory) {
        return
            direction == 0
                ? _openedSwapsPayFixed[tenor].swaps[_openedSwapsPayFixed[tenor].headSwapId]
                : _openedSwapsReceiveFixed[tenor].swaps[_openedSwapsReceiveFixed[tenor].headSwapId];
    }

    function getBalance() external view override returns (AmmTypesBaseV1.Balance memory) {
        StorageTypesBaseV1.Balance memory balance = _balance;
        return
            AmmTypesBaseV1.Balance({
                totalCollateralPayFixed: balance.totalCollateralPayFixed,
                totalCollateralReceiveFixed: balance.totalCollateralReceiveFixed,
                iporPublicationFee: balance.iporPublicationFee,
                treasury: balance.treasury,
                totalLiquidationDepositBalance: totalLiquidationDepositBalance
            });
    }

    function getBalancesForOpenSwap() external view override returns (AmmTypesBaseV1.AmmBalanceForOpenSwap memory) {
        return
            AmmTypesBaseV1.AmmBalanceForOpenSwap({
                totalCollateralPayFixed: _balance.totalCollateralPayFixed,
                totalNotionalPayFixed: _soapIndicatorsPayFixed.totalNotional,
                totalCollateralReceiveFixed: _balance.totalCollateralReceiveFixed,
                totalNotionalReceiveFixed: _soapIndicatorsReceiveFixed.totalNotional
            });
    }

    function getSwap(
        AmmTypes.SwapDirection direction,
        uint256 swapId
    ) external view override returns (AmmTypesBaseV1.Swap memory) {
        uint32 id = swapId.toUint32();
        StorageInternalTypes.Swap storage swap;

        if (direction == AmmTypes.SwapDirection.PAY_FIXED_RECEIVE_FLOATING) {
            swap = _swapsPayFixed.swaps[id];
        } else if (direction == AmmTypes.SwapDirection.PAY_FLOATING_RECEIVE_FIXED) {
            swap = _swapsReceiveFixed.swaps[id];
        } else {
            revert(AmmErrors.UNSUPPORTED_DIRECTION);
        }

        return
            AmmTypesBaseV1.Swap({
                id: swap.id,
                buyer: swap.buyer,
                openTimestamp: swap.openTimestamp,
                tenor: swap.tenor,
                direction: direction,
                idsIndex: swap.idsIndex,
                collateral: swap.collateral,
                notional: swap.notional,
                ibtQuantity: swap.ibtQuantity,
                fixedInterestRate: swap.fixedInterestRate,
                wadLiquidationDepositAmount: uint256(swap.liquidationDepositAmount) *
                    _DECIMALS_OFFSET_LIQUIDATION_DEPOSIT,
                state: swap.state
            });
    }

    function getSwapsPayFixed(
        address account,
        uint256 offset,
        uint256 chunkSize
    ) external view override returns (uint256 totalCount, AmmTypesBaseV1.Swap[] memory swaps) {
        uint32[] storage ids = _swapsPayFixed.ids[account];
        return (
            ids.length,
            _getPositions(
                AmmTypes.SwapDirection.PAY_FIXED_RECEIVE_FLOATING,
                _swapsPayFixed.swaps,
                ids,
                offset,
                chunkSize
            )
        );
    }

    function getSwapsReceiveFixed(
        address account,
        uint256 offset,
        uint256 chunkSize
    ) external view override returns (uint256 totalCount, AmmTypesBaseV1.Swap[] memory swaps) {
        uint32[] storage ids = _swapsReceiveFixed.ids[account];
        return (
            ids.length,
            _getPositions(
                AmmTypes.SwapDirection.PAY_FLOATING_RECEIVE_FIXED,
                _swapsReceiveFixed.swaps,
                ids,
                offset,
                chunkSize
            )
        );
    }

    function getSwapIds(
        address account,
        uint256 offset,
        uint256 chunkSize
    ) external view override returns (uint256 totalCount, AmmStorageTypes.IporSwapId[] memory ids) {
        require(chunkSize > 0, IporErrors.CHUNK_SIZE_EQUAL_ZERO);
        require(chunkSize <= Constants.MAX_CHUNK_SIZE, IporErrors.CHUNK_SIZE_TOO_BIG);

        uint32[] storage payFixedIdsRef = _swapsPayFixed.ids[account];
        uint256 payFixedLength = payFixedIdsRef.length;

        uint32[] storage receiveFixedIdsRef = _swapsReceiveFixed.ids[account];
        uint256 receiveFixedLength = receiveFixedIdsRef.length;

        totalCount = payFixedLength + receiveFixedLength;

        uint256 resultSetSize = PaginationUtils.resolveResultSetSize(totalCount, offset, chunkSize);

        ids = new AmmStorageTypes.IporSwapId[](resultSetSize);

        for (uint256 i; i != resultSetSize; ) {
            if (offset + i < payFixedLength) {
                ids[i] = AmmStorageTypes.IporSwapId(payFixedIdsRef[offset + i], 0);
            } else {
                ids[i] = AmmStorageTypes.IporSwapId(receiveFixedIdsRef[offset + i - payFixedLength], 1);
            }
            unchecked {
                ++i;
            }
        }
    }

    function updateStorageWhenOpenSwapPayFixedInternal(
        AmmTypes.NewSwap memory newSwap,
        uint256 cfgIporPublicationFee
    ) external override onlyRouter returns (uint256) {
        uint256 id = _updateSwapsWhenOpen(AmmTypes.SwapDirection.PAY_FIXED_RECEIVE_FLOATING, newSwap);
        _updateBalancesWhenOpenSwapPayFixed(newSwap, cfgIporPublicationFee);

        _updateSoapIndicatorsWhenOpenSwapPayFixed(
            newSwap.openTimestamp,
            newSwap.notional,
            newSwap.fixedInterestRate,
            newSwap.ibtQuantity
        );
        _updateOpenedSwapWhenOpenPayFixed(newSwap.tenor, id, newSwap.openTimestamp);
        return id;
    }

    function updateStorageWhenOpenSwapReceiveFixedInternal(
        AmmTypes.NewSwap memory newSwap,
        uint256 cfgIporPublicationFee
    ) external override onlyRouter returns (uint256) {
        uint256 id = _updateSwapsWhenOpen(AmmTypes.SwapDirection.PAY_FLOATING_RECEIVE_FIXED, newSwap);
        _updateBalancesWhenOpenSwapReceiveFixed(newSwap, cfgIporPublicationFee);
        _updateSoapIndicatorsWhenOpenSwapReceiveFixed(
            newSwap.openTimestamp,
            newSwap.notional,
            newSwap.fixedInterestRate,
            newSwap.ibtQuantity
        );
        _updateOpenedSwapWhenOpenReceiveFixed(newSwap.tenor, id, newSwap.openTimestamp);
        return id;
    }

    function updateStorageWhenCloseSwapPayFixedInternal(
        AmmTypesBaseV1.Swap memory swap,
        int256 pnlValue,
        uint256 swapUnwindFeeLPAmount,
        uint256 swapUnwindFeeTreasuryAmount,
        uint256 closingTimestamp
    ) external override onlyRouter returns (AmmInternalTypes.OpenSwapItem memory closedSwap) {
        _updateSwapsWhenClosePayFixed(swap);
        _updateBalancesWhenCloseSwapPayFixed(swap, pnlValue, swapUnwindFeeLPAmount, swapUnwindFeeTreasuryAmount);
        _updateSoapIndicatorsWhenCloseSwapPayFixed(swap, closingTimestamp);
        return _updateOpenedSwapWhenClosePayFixed(swap.tenor, swap.id);
    }

    function updateStorageWhenCloseSwapReceiveFixedInternal(
        AmmTypesBaseV1.Swap memory swap,
        int256 pnlValue,
        uint256 swapUnwindFeeLPAmount,
        uint256 swapUnwindFeeTreasuryAmount,
        uint256 closingTimestamp
    ) external override onlyRouter returns (AmmInternalTypes.OpenSwapItem memory closedSwap) {
        _updateSwapsWhenCloseReceiveFixed(swap);
        _updateBalancesWhenCloseSwapReceiveFixed(swap, pnlValue, swapUnwindFeeLPAmount, swapUnwindFeeTreasuryAmount);
        _updateSoapIndicatorsWhenCloseSwapReceiveFixed(swap, closingTimestamp);
        return _updateOpenedSwapWhenCloseReceiveFixed(swap.tenor, swap.id);
    }

    function updateStorageWhenTransferToCharlieTreasuryInternal(
        uint256 transferredAmount
    ) external override onlyRouter {
        require(transferredAmount > 0, IporErrors.NOT_ENOUGH_AMOUNT_TO_TRANSFER);

        uint256 balance = _balance.iporPublicationFee;

        require(transferredAmount <= balance, AmmErrors.PUBLICATION_FEE_BALANCE_IS_TOO_LOW);

        balance = balance - transferredAmount;

        _balance.iporPublicationFee = balance.toUint128();
    }

    function updateStorageWhenTransferToTreasuryInternal(uint256 transferredAmount) external override onlyRouter {
        require(transferredAmount > 0, IporErrors.NOT_ENOUGH_AMOUNT_TO_TRANSFER);

        uint256 balance = _balance.treasury;

        require(transferredAmount <= balance, AmmErrors.TREASURY_BALANCE_IS_TOO_LOW);

        balance = balance - transferredAmount;

        _balance.treasury = balance.toUint128();
    }

    function getImplementation() external view override returns (address) {
        return StorageSlotUpgradeable.getAddressSlot(_IMPLEMENTATION_SLOT).value;
    }

    function getSoapIndicators()
        external
        view
        returns (
            AmmStorageTypes.SoapIndicators memory indicatorsPayFixed,
            AmmStorageTypes.SoapIndicators memory indicatorsReceiveFixed
        )
    {
        StorageInternalTypes.SoapIndicatorsStorage memory soapIndicatorsPayFixed = _soapIndicatorsPayFixed;
        StorageInternalTypes.SoapIndicatorsStorage memory soapIndicatorsReceiveFixed = _soapIndicatorsReceiveFixed;

        indicatorsPayFixed = AmmStorageTypes.SoapIndicators({
            hypotheticalInterestCumulative: soapIndicatorsPayFixed.hypotheticalInterestCumulative,
            totalNotional: soapIndicatorsPayFixed.totalNotional,
            totalIbtQuantity: soapIndicatorsPayFixed.totalIbtQuantity,
            averageInterestRate: soapIndicatorsPayFixed.averageInterestRate,
            rebalanceTimestamp: soapIndicatorsPayFixed.rebalanceTimestamp
        });

        indicatorsReceiveFixed = AmmStorageTypes.SoapIndicators({
            hypotheticalInterestCumulative: soapIndicatorsReceiveFixed.hypotheticalInterestCumulative,
            totalNotional: soapIndicatorsReceiveFixed.totalNotional,
            totalIbtQuantity: soapIndicatorsReceiveFixed.totalIbtQuantity,
            averageInterestRate: soapIndicatorsReceiveFixed.averageInterestRate,
            rebalanceTimestamp: soapIndicatorsReceiveFixed.rebalanceTimestamp
        });
    }

    function _getPositions(
        AmmTypes.SwapDirection direction,
        mapping(uint32 => StorageInternalTypes.Swap) storage swaps,
        uint32[] storage ids,
        uint256 offset,
        uint256 chunkSize
    ) internal view returns (AmmTypesBaseV1.Swap[] memory) {
        require(chunkSize > 0, IporErrors.CHUNK_SIZE_EQUAL_ZERO);
        require(chunkSize <= Constants.MAX_CHUNK_SIZE, IporErrors.CHUNK_SIZE_TOO_BIG);

        uint256 swapsIdsLength = PaginationUtils.resolveResultSetSize(ids.length, offset, chunkSize);
        AmmTypesBaseV1.Swap[] memory derivatives = new AmmTypesBaseV1.Swap[](swapsIdsLength);

        uint32 id;

        for (uint256 i; i != swapsIdsLength; ) {
            id = ids[i + offset];
            StorageInternalTypes.Swap storage swap = swaps[id];
            derivatives[i] = AmmTypesBaseV1.Swap(
                swap.id,
                swap.buyer,
                swap.openTimestamp,
                swap.tenor,
                direction,
                swap.idsIndex,
                swap.collateral,
                swap.notional,
                swap.ibtQuantity,
                swap.fixedInterestRate,
                uint256(swap.liquidationDepositAmount) * _DECIMALS_OFFSET_LIQUIDATION_DEPOSIT,
                swaps[id].state
            );
            unchecked {
                ++i;
            }
        }
        return derivatives;
    }

    function _updateBalancesWhenOpenSwapPayFixed(
        AmmTypes.NewSwap memory newSwap,
        uint256 cfgIporPublicationFee
    ) internal {
        _balance.totalCollateralPayFixed = _balance.totalCollateralPayFixed + newSwap.collateral.toUint128();
        _balance.iporPublicationFee = _balance.iporPublicationFee + cfgIporPublicationFee.toUint128();
        _balance.treasury = _balance.treasury + newSwap.openingFeeTreasuryAmount.toUint128();
        totalLiquidationDepositBalance =
            totalLiquidationDepositBalance +
            (newSwap.liquidationDepositAmount * _DECIMALS_OFFSET_LIQUIDATION_DEPOSIT).toUint128();
    }

    function _updateBalancesWhenOpenSwapReceiveFixed(
        AmmTypes.NewSwap memory newSwap,
        uint256 cfgIporPublicationFee
    ) internal {
        _balance.totalCollateralReceiveFixed = _balance.totalCollateralReceiveFixed + newSwap.collateral.toUint128();
        _balance.iporPublicationFee = _balance.iporPublicationFee + cfgIporPublicationFee.toUint128();
        _balance.treasury = _balance.treasury + newSwap.openingFeeTreasuryAmount.toUint128();
        totalLiquidationDepositBalance =
            totalLiquidationDepositBalance +
            (newSwap.liquidationDepositAmount * _DECIMALS_OFFSET_LIQUIDATION_DEPOSIT).toUint128();
    }

    function _updateBalancesWhenCloseSwapPayFixed(
        AmmTypesBaseV1.Swap memory swap,
        int256 pnlValue,
        uint256 swapUnwindFeeLPAmount,
        uint256 swapUnwindFeeTreasuryAmount
    ) internal {
        _balance.totalCollateralPayFixed = _balance.totalCollateralPayFixed - swap.collateral.toUint128();
        _balance.treasury = _balance.treasury + swapUnwindFeeTreasuryAmount.toUint128();
        totalLiquidationDepositBalance = totalLiquidationDepositBalance - swap.wadLiquidationDepositAmount.toUint128();
    }

    function _updateBalancesWhenCloseSwapReceiveFixed(
        AmmTypesBaseV1.Swap memory swap,
        int256 pnlValue,
        uint256 swapUnwindFeeLPAmount,
        uint256 swapUnwindFeeTreasuryAmount
    ) internal {
        _balance.totalCollateralReceiveFixed = _balance.totalCollateralReceiveFixed - swap.collateral.toUint128();
        _balance.treasury = _balance.treasury + swapUnwindFeeTreasuryAmount.toUint128();
        totalLiquidationDepositBalance = totalLiquidationDepositBalance - swap.wadLiquidationDepositAmount.toUint128();
    }

    function _updateSwapsWhenOpen(
        AmmTypes.SwapDirection direction,
        AmmTypes.NewSwap memory newSwap
    ) internal returns (uint256) {
        uint32 id = _lastSwapId + 1;

        StorageInternalTypes.Swap storage swap;
        uint32 idsIndexLocal;

        if (direction == AmmTypes.SwapDirection.PAY_FIXED_RECEIVE_FLOATING) {
            swap = _swapsPayFixed.swaps[id];
            idsIndexLocal = _swapsPayFixed.ids[newSwap.buyer].length.toUint32();
        } else if (direction == AmmTypes.SwapDirection.PAY_FLOATING_RECEIVE_FIXED) {
            swap = _swapsReceiveFixed.swaps[id];
            idsIndexLocal = _swapsReceiveFixed.ids[newSwap.buyer].length.toUint32();
        } else {
            revert(AmmErrors.UNSUPPORTED_DIRECTION);
        }

        swap.id = id;
        swap.buyer = newSwap.buyer;
        swap.openTimestamp = newSwap.openTimestamp.toUint32();
        swap.idsIndex = idsIndexLocal;
        swap.collateral = newSwap.collateral.toUint128();
        swap.notional = newSwap.notional.toUint128();
        swap.ibtQuantity = newSwap.ibtQuantity.toUint128();
        swap.fixedInterestRate = newSwap.fixedInterestRate.toUint64();
        swap.liquidationDepositAmount = newSwap.liquidationDepositAmount.toUint32();
        swap.state = IporTypes.SwapState.ACTIVE;
        swap.tenor = newSwap.tenor;

        if (direction == AmmTypes.SwapDirection.PAY_FIXED_RECEIVE_FLOATING) {
            _swapsPayFixed.ids[newSwap.buyer].push(id);
        } else if (direction == AmmTypes.SwapDirection.PAY_FLOATING_RECEIVE_FIXED) {
            _swapsReceiveFixed.ids[newSwap.buyer].push(id);
        } else {
            revert(AmmErrors.UNSUPPORTED_DIRECTION);
        }

        _lastSwapId = id;

        return id;
    }

    function _updateSwapsWhenClosePayFixed(AmmTypesBaseV1.Swap memory swap) internal {
        require(swap.id > 0, AmmErrors.INCORRECT_SWAP_ID);
        require(swap.state != IporTypes.SwapState.INACTIVE, AmmErrors.INCORRECT_SWAP_STATUS);

        uint32 idsIndexToDelete = swap.idsIndex.toUint32();
        address buyer = swap.buyer;
        uint256 idsLength = _swapsPayFixed.ids[buyer].length - 1;
        if (idsIndexToDelete < idsLength) {
            uint32 accountDerivativeIdToMove = _swapsPayFixed.ids[buyer][idsLength];

            _swapsPayFixed.swaps[accountDerivativeIdToMove].idsIndex = idsIndexToDelete;

            _swapsPayFixed.ids[buyer][idsIndexToDelete] = accountDerivativeIdToMove;
        }

        _swapsPayFixed.swaps[swap.id.toUint32()].state = IporTypes.SwapState.INACTIVE;
        _swapsPayFixed.ids[buyer].pop();
    }

    function _updateSwapsWhenCloseReceiveFixed(AmmTypesBaseV1.Swap memory swap) internal {
        require(swap.id > 0, AmmErrors.INCORRECT_SWAP_ID);
        require(swap.state != IporTypes.SwapState.INACTIVE, AmmErrors.INCORRECT_SWAP_STATUS);

        uint32 idsIndexToDelete = swap.idsIndex.toUint32();
        address buyer = swap.buyer;
        uint256 idsLength = _swapsReceiveFixed.ids[buyer].length - 1;

        if (idsIndexToDelete < idsLength) {
            uint32 accountDerivativeIdToMove = _swapsReceiveFixed.ids[buyer][idsLength];

            _swapsReceiveFixed.swaps[accountDerivativeIdToMove].idsIndex = idsIndexToDelete;

            _swapsReceiveFixed.ids[buyer][idsIndexToDelete] = accountDerivativeIdToMove;
        }

        _swapsReceiveFixed.swaps[swap.id.toUint32()].state = IporTypes.SwapState.INACTIVE;
        _swapsReceiveFixed.ids[buyer].pop();
    }

    function _updateSoapIndicatorsWhenOpenSwapPayFixed(
        uint256 openTimestamp,
        uint256 swapNotional,
        uint256 fixedInterestRate,
        uint256 ibtQuantity
    ) internal {
        AmmStorageTypes.SoapIndicators memory pf = AmmStorageTypes.SoapIndicators(
            _soapIndicatorsPayFixed.hypotheticalInterestCumulative,
            _soapIndicatorsPayFixed.totalNotional,
            _soapIndicatorsPayFixed.totalIbtQuantity,
            _soapIndicatorsPayFixed.averageInterestRate,
            _soapIndicatorsPayFixed.rebalanceTimestamp
        );

        pf = pf.rebalanceWhenOpenSwap(openTimestamp, swapNotional, fixedInterestRate, ibtQuantity);

        _soapIndicatorsPayFixed.rebalanceTimestamp = pf.rebalanceTimestamp.toUint32();
        _soapIndicatorsPayFixed.totalNotional = pf.totalNotional.toUint128();
        _soapIndicatorsPayFixed.averageInterestRate = pf.averageInterestRate.toUint64();
        _soapIndicatorsPayFixed.totalIbtQuantity = pf.totalIbtQuantity.toUint128();
        _soapIndicatorsPayFixed.hypotheticalInterestCumulative = pf.hypotheticalInterestCumulative;
    }

    function _updateSoapIndicatorsWhenOpenSwapReceiveFixed(
        uint256 openTimestamp,
        uint256 swapNotional,
        uint256 fixedInterestRate,
        uint256 ibtQuantity
    ) internal {
        AmmStorageTypes.SoapIndicators memory rf = AmmStorageTypes.SoapIndicators(
            _soapIndicatorsReceiveFixed.hypotheticalInterestCumulative,
            _soapIndicatorsReceiveFixed.totalNotional,
            _soapIndicatorsReceiveFixed.totalIbtQuantity,
            _soapIndicatorsReceiveFixed.averageInterestRate,
            _soapIndicatorsReceiveFixed.rebalanceTimestamp
        );
        rf = rf.rebalanceWhenOpenSwap(openTimestamp, swapNotional, fixedInterestRate, ibtQuantity);

        _soapIndicatorsReceiveFixed.rebalanceTimestamp = rf.rebalanceTimestamp.toUint32();
        _soapIndicatorsReceiveFixed.totalNotional = rf.totalNotional.toUint128();
        _soapIndicatorsReceiveFixed.averageInterestRate = rf.averageInterestRate.toUint64();
        _soapIndicatorsReceiveFixed.totalIbtQuantity = rf.totalIbtQuantity.toUint128();
        _soapIndicatorsReceiveFixed.hypotheticalInterestCumulative = rf.hypotheticalInterestCumulative;
    }

    function _updateSoapIndicatorsWhenCloseSwapPayFixed(
        AmmTypesBaseV1.Swap memory swap,
        uint256 closingTimestamp
    ) internal {
        AmmStorageTypes.SoapIndicators memory pf = AmmStorageTypes.SoapIndicators(
            _soapIndicatorsPayFixed.hypotheticalInterestCumulative,
            _soapIndicatorsPayFixed.totalNotional,
            _soapIndicatorsPayFixed.totalIbtQuantity,
            _soapIndicatorsPayFixed.averageInterestRate,
            _soapIndicatorsPayFixed.rebalanceTimestamp
        );

        pf = pf.rebalanceWhenCloseSwap(
            closingTimestamp,
            swap.openTimestamp,
            swap.notional,
            swap.fixedInterestRate,
            swap.ibtQuantity
        );

        _soapIndicatorsPayFixed = StorageInternalTypes.SoapIndicatorsStorage(
            pf.hypotheticalInterestCumulative,
            pf.totalNotional.toUint128(),
            pf.totalIbtQuantity.toUint128(),
            pf.averageInterestRate.toUint64(),
            pf.rebalanceTimestamp.toUint32()
        );
    }

    function _updateSoapIndicatorsWhenCloseSwapReceiveFixed(
        AmmTypesBaseV1.Swap memory swap,
        uint256 closingTimestamp
    ) internal {
        AmmStorageTypes.SoapIndicators memory rf = AmmStorageTypes.SoapIndicators(
            _soapIndicatorsReceiveFixed.hypotheticalInterestCumulative,
            _soapIndicatorsReceiveFixed.totalNotional,
            _soapIndicatorsReceiveFixed.totalIbtQuantity,
            _soapIndicatorsReceiveFixed.averageInterestRate,
            _soapIndicatorsReceiveFixed.rebalanceTimestamp
        );

        rf = rf.rebalanceWhenCloseSwap(
            closingTimestamp,
            swap.openTimestamp,
            swap.notional,
            swap.fixedInterestRate,
            swap.ibtQuantity
        );

        _soapIndicatorsReceiveFixed = StorageInternalTypes.SoapIndicatorsStorage(
            rf.hypotheticalInterestCumulative,
            rf.totalNotional.toUint128(),
            rf.totalIbtQuantity.toUint128(),
            rf.averageInterestRate.toUint64(),
            rf.rebalanceTimestamp.toUint32()
        );
    }

    function _updateOpenedSwapWhenOpenPayFixed(
        IporTypes.SwapTenor tenor,
        uint256 swapId,
        uint256 openTimestamp
    ) internal {
        uint32 headSwapId = _openedSwapsPayFixed[tenor].headSwapId;
        _openedSwapsPayFixed[tenor].swaps[swapId.toUint32()] = AmmInternalTypes.OpenSwapItem(
            swapId.toUint32(),
            0,
            headSwapId,
            openTimestamp.toUint32()
        );
        _openedSwapsPayFixed[tenor].headSwapId = swapId.toUint32();
        _openedSwapsPayFixed[tenor].swaps[headSwapId].nextSwapId = swapId.toUint32();
    }

    function _updateOpenedSwapWhenClosePayFixed(
        IporTypes.SwapTenor tenor,
        uint256 swapId
    ) internal returns (AmmInternalTypes.OpenSwapItem memory closedSwap) {
        uint32 headSwapId = _openedSwapsPayFixed[tenor].headSwapId;
        AmmInternalTypes.OpenSwapItem memory swap = _openedSwapsPayFixed[tenor].swaps[swapId.toUint32()];
        if (swap.openSwapTimestamp == 0) {
            return swap;
        }
        if (swapId.toUint32() == headSwapId) {
            AmmInternalTypes.OpenSwapItem memory swapPrev = _openedSwapsPayFixed[tenor].swaps[swap.previousSwapId];
            swapPrev.nextSwapId = 0;
            _openedSwapsPayFixed[tenor].headSwapId = swapPrev.swapId;
            _openedSwapsPayFixed[tenor].swaps[swapPrev.swapId] = swapPrev;
            delete _openedSwapsPayFixed[tenor].swaps[swapId.toUint32()];
        } else {
            AmmInternalTypes.OpenSwapItem memory swapPrev = _openedSwapsPayFixed[tenor].swaps[swap.previousSwapId];
            AmmInternalTypes.OpenSwapItem memory swapNext = _openedSwapsPayFixed[tenor].swaps[swap.nextSwapId];
            swapPrev.nextSwapId = swapNext.swapId;
            swapNext.previousSwapId = swapPrev.swapId;
            _openedSwapsPayFixed[tenor].swaps[swap.previousSwapId] = swapPrev;
            _openedSwapsPayFixed[tenor].swaps[swap.nextSwapId] = swapNext;
            delete _openedSwapsPayFixed[tenor].swaps[swapId.toUint32()];
        }
        return swap;
    }

    function _updateOpenedSwapWhenOpenReceiveFixed(
        IporTypes.SwapTenor tenor,
        uint256 swapId,
        uint256 openTimestamp
    ) internal {
        uint32 headSwapId = _openedSwapsReceiveFixed[tenor].headSwapId;
        _openedSwapsReceiveFixed[tenor].swaps[swapId.toUint32()] = AmmInternalTypes.OpenSwapItem(
            swapId.toUint32(),
            0,
            headSwapId,
            openTimestamp.toUint32()
        );
        _openedSwapsReceiveFixed[tenor].headSwapId = swapId.toUint32();
        _openedSwapsReceiveFixed[tenor].swaps[headSwapId].nextSwapId = swapId.toUint32();
    }

    function _updateOpenedSwapWhenCloseReceiveFixed(
        IporTypes.SwapTenor tenor,
        uint256 swapId
    ) internal returns (AmmInternalTypes.OpenSwapItem memory closedSwap) {
        uint32 headSwapId = _openedSwapsReceiveFixed[tenor].headSwapId;
        AmmInternalTypes.OpenSwapItem memory swap = _openedSwapsReceiveFixed[tenor].swaps[swapId.toUint32()];
        if (swap.openSwapTimestamp == 0) {
            return swap;
        }
        if (swapId.toUint32() == headSwapId) {
            AmmInternalTypes.OpenSwapItem memory swapPrev = _openedSwapsReceiveFixed[tenor].swaps[swap.previousSwapId];
            swapPrev.nextSwapId = 0;
            _openedSwapsReceiveFixed[tenor].headSwapId = swapPrev.swapId;
            _openedSwapsReceiveFixed[tenor].swaps[swapPrev.swapId] = swapPrev;
            delete _openedSwapsReceiveFixed[tenor].swaps[swapId.toUint32()];
        } else {
            AmmInternalTypes.OpenSwapItem memory swapPrev = _openedSwapsReceiveFixed[tenor].swaps[swap.previousSwapId];
            AmmInternalTypes.OpenSwapItem memory swapNext = _openedSwapsReceiveFixed[tenor].swaps[swap.nextSwapId];
            swapPrev.nextSwapId = swapNext.swapId;
            swapNext.previousSwapId = swapPrev.swapId;
            _openedSwapsReceiveFixed[tenor].swaps[swap.previousSwapId] = swapPrev;
            _openedSwapsReceiveFixed[tenor].swaps[swap.nextSwapId] = swapNext;
            delete _openedSwapsReceiveFixed[tenor].swaps[swapId.toUint32()];
        }
        return swap;
    }

    //solhint-disable no-empty-blocks
    function _authorizeUpgrade(address) internal override onlyOwner {}
}

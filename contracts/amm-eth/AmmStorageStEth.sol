// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.20;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts/utils/math/SafeCast.sol";

import "../interfaces/types/AmmStorageTypes.sol";
import "../interfaces/IAmmStorage.sol";
import "../interfaces/IProxyImplementation.sol";
import "../interfaces/IIporContractCommonGov.sol";
import "../libraries/Constants.sol";
import "../libraries/PaginationUtils.sol";
import "../libraries/IporContractValidator.sol";
import "../security/PauseManager.sol";
import "../security/IporOwnableUpgradeable.sol";
import "../amm/libraries/types/AmmInternalTypes.sol";
import "../amm/libraries/types/StorageInternalTypes.sol";
import "../amm/libraries/SoapIndicatorRebalanceLogic.sol";

/// @dev all stored values related to tokens are in 18 decimals.
contract AmmStorageStEth is
    Initializable,
    PausableUpgradeable,
    UUPSUpgradeable,
    IporOwnableUpgradeable,
    IAmmStorage,
    IProxyImplementation,
    IIporContractCommonGov
{
    using IporContractValidator for address;
    using SafeCast for uint256;
    using SafeCast for int256;

    using SoapIndicatorRebalanceLogic for AmmStorageTypes.SoapIndicators;

    int256 private constant INTEREST_THRESHOLD = -1e18;

    address private immutable _iporProtocolRouter;
    address private immutable _ammTreasury;

    uint32 private _lastSwapId;

    StorageInternalTypes.Balances internal _balances;
    StorageInternalTypes.SoapIndicatorsStorage internal _soapIndicatorsPayFixed;
    StorageInternalTypes.SoapIndicatorsStorage internal _soapIndicatorsReceiveFixed;
    StorageInternalTypes.SwapContainer internal _swapsPayFixed;
    StorageInternalTypes.SwapContainer internal _swapsReceiveFixed;

    mapping(IporTypes.SwapTenor => AmmInternalTypes.OpenSwapList) private _openedSwapsPayFixed;
    mapping(IporTypes.SwapTenor => AmmInternalTypes.OpenSwapList) private _openedSwapsReceiveFixed;

    modifier onlyPauseGuardian() {
        if (!PauseManager.isPauseGuardian(msg.sender)) {
            revert IporErrors.CallerNotPauseGuardian(msg.sender);
        }
        _;
    }

    modifier onlyRouter() {
        if (msg.sender != _iporProtocolRouter) {
            revert IporErrors.CallerNotIporProtocolRouter(msg.sender);
        }
        _;
    }

    modifier onlyAmmTreasury() {
        if (msg.sender != _ammTreasury) {
            revert IporErrors.CallerNotAmmTreasury(msg.sender);
        }
        _;
    }

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor(address iporProtocolRouterInput, address ammTreasury) {
        _iporProtocolRouter = iporProtocolRouterInput.checkAddress();
        _ammTreasury = ammTreasury.checkAddress();
        _disableInitializers();
    }

    function initialize() public initializer {
        __Pausable_init();
        __Ownable_init();
        __UUPSUpgradeable_init();
    }

    function getVersion() external pure virtual override returns (uint256) {
        return 2_001;
    }

    function getConfiguration() external view override returns (address, address) {
        return (_ammTreasury, _iporProtocolRouter);
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

    function getBalance() external view virtual override returns (IporTypes.AmmBalancesMemory memory) {
        return
            IporTypes.AmmBalancesMemory(
                _balances.totalCollateralPayFixed,
                _balances.totalCollateralReceiveFixed,
                _balances.liquidityPool,
                _balances.vault
            );
    }

    function getBalancesForOpenSwap() external view override returns (IporTypes.AmmBalancesForOpenSwapMemory memory) {
        return
            IporTypes.AmmBalancesForOpenSwapMemory({
                totalCollateralPayFixed: _balances.totalCollateralPayFixed,
                totalNotionalPayFixed: _soapIndicatorsPayFixed.totalNotional,
                totalCollateralReceiveFixed: _balances.totalCollateralReceiveFixed,
                totalNotionalReceiveFixed: _soapIndicatorsReceiveFixed.totalNotional,
                liquidityPool: _balances.liquidityPool
            });
    }

    function getExtendedBalance() external view override returns (AmmStorageTypes.ExtendedBalancesMemory memory) {
        return
            AmmStorageTypes.ExtendedBalancesMemory(
                _balances.totalCollateralPayFixed,
                _balances.totalCollateralReceiveFixed,
                _balances.liquidityPool,
                _balances.vault,
                _balances.iporPublicationFee,
                _balances.treasury
            );
    }

    function getSwap(
        AmmTypes.SwapDirection direction,
        uint256 swapId
    ) external view override returns (AmmTypes.Swap memory) {
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
            AmmTypes.Swap(
                swap.id,
                swap.buyer,
                swap.openTimestamp,
                swap.tenor,
                swap.idsIndex,
                swap.collateral,
                swap.notional,
                swap.ibtQuantity,
                swap.fixedInterestRate,
                uint256(swap.liquidationDepositAmount) * 1e18,
                swap.state
            );
    }

    function getSwapsPayFixed(
        address account,
        uint256 offset,
        uint256 chunkSize
    ) external view override returns (uint256 totalCount, AmmTypes.Swap[] memory swaps) {
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
    ) external view override returns (uint256 totalCount, AmmTypes.Swap[] memory swaps) {
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

    function addLiquidityInternal(
        address account,
        uint256 assetAmount,
        uint256 cfgMaxLiquidityPoolBalance
    ) external override onlyRouter {
        require(assetAmount > 0, AmmErrors.DEPOSIT_AMOUNT_IS_TOO_LOW);

        uint128 newLiquidityPoolBalance = _balances.liquidityPool + assetAmount.toUint128();
        require(newLiquidityPoolBalance <= cfgMaxLiquidityPoolBalance, AmmErrors.LIQUIDITY_POOL_BALANCE_IS_TOO_HIGH);

        _balances.liquidityPool = newLiquidityPoolBalance;
    }

    function subtractLiquidityInternal(uint256 assetAmount) external override onlyRouter {
        _balances.liquidityPool = _balances.liquidityPool - assetAmount.toUint128();
    }

    function updateStorageWhenOpenSwapPayFixedInternal(
        AmmTypes.NewSwap memory newSwap,
        uint256 cfgIporPublicationFee
    ) external override onlyRouter returns (uint256) {
        uint256 id = _updateSwapsWhenOpen(AmmTypes.SwapDirection.PAY_FIXED_RECEIVE_FLOATING, newSwap);
        _updateBalancesWhenOpenSwapPayFixed(
            newSwap.collateral,
            newSwap.openingFeeLPAmount,
            newSwap.openingFeeTreasuryAmount,
            cfgIporPublicationFee
        );

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
        _updateBalancesWhenOpenSwapReceiveFixed(
            newSwap.collateral,
            newSwap.openingFeeLPAmount,
            newSwap.openingFeeTreasuryAmount,
            cfgIporPublicationFee
        );
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
        AmmTypes.Swap memory swap,
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
        AmmTypes.Swap memory swap,
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

    /// @dev vaultBalance is the balance of the vault after the withdraw
    function updateStorageWhenWithdrawFromAssetManagement(
        uint256 withdrawnAmount,
        uint256 vaultBalance
    ) external override onlyAmmTreasury {
        uint256 currentVaultBalance = _balances.vault;
        uint256 currentLiquidityPoolBalance = _balances.liquidityPool;

        int256 interest = (vaultBalance + withdrawnAmount).toInt256() - currentVaultBalance.toInt256();

        _updateStorageWhenInteractionWithAssetManagement(currentLiquidityPoolBalance, vaultBalance, interest);
    }

    function updateStorageWhenDepositToAssetManagement(
        uint256 depositAmount,
        uint256 vaultBalance
    ) external override onlyAmmTreasury {
        /// @dev vaultBalance is the balance of the vault after the deposit depositAmount, so should always be vaultBalance >= depositAmount
        require(vaultBalance >= depositAmount, AmmErrors.VAULT_BALANCE_LOWER_THAN_DEPOSIT_VALUE);

        uint256 currentVaultBalance = _balances.vault;
        uint256 currentLiquidityPoolBalance = _balances.liquidityPool;

        int256 interest = (vaultBalance - depositAmount).toInt256() - currentVaultBalance.toInt256();

        _updateStorageWhenInteractionWithAssetManagement(currentLiquidityPoolBalance, vaultBalance, interest);
    }

    function updateStorageWhenTransferToCharlieTreasuryInternal(
        uint256 transferredAmount
    ) external override onlyRouter {
        require(transferredAmount > 0, IporErrors.NOT_ENOUGH_AMOUNT_TO_TRANSFER);

        uint256 balance = _balances.iporPublicationFee;

        require(transferredAmount <= balance, AmmErrors.PUBLICATION_FEE_BALANCE_IS_TOO_LOW);

        balance = balance - transferredAmount;

        _balances.iporPublicationFee = balance.toUint128();
    }

    function updateStorageWhenTransferToTreasuryInternal(uint256 transferredAmount) external override onlyRouter {
        require(transferredAmount > 0, IporErrors.NOT_ENOUGH_AMOUNT_TO_TRANSFER);

        uint256 balance = _balances.treasury;

        require(transferredAmount <= balance, AmmErrors.TREASURY_BALANCE_IS_TOO_LOW);

        balance = balance - transferredAmount;

        _balances.treasury = balance.toUint128();
    }

    function pause() external override onlyPauseGuardian {
        _pause();
    }

    function unpause() external override onlyOwner {
        _unpause();
    }

    function isPauseGuardian(address account) external view override returns (bool) {
        return PauseManager.isPauseGuardian(account);
    }

    function addPauseGuardians(address[] calldata guardians) external override onlyOwner {
        PauseManager.addPauseGuardians(guardians);
    }

    function removePauseGuardians(address[] calldata guardians) external override onlyOwner {
        PauseManager.removePauseGuardians(guardians);
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

    function _updateStorageWhenInteractionWithAssetManagement(
        uint256 ammLiquidityPoolBalance,
        uint256 vaultBalance,
        int256 interest
    ) internal {
        /// @dev allow to have negative interest but not lower than INTEREST_THRESHOLD
        require(interest >= INTEREST_THRESHOLD, AmmErrors.INTEREST_FROM_STRATEGY_EXCEEDED_THRESHOLD);
        require(ammLiquidityPoolBalance.toInt256() >= -interest, AmmErrors.LIQUIDITY_POOL_AMOUNT_TOO_LOW);

        ammLiquidityPoolBalance = (ammLiquidityPoolBalance.toInt256() + interest).toUint256();

        _balances.liquidityPool = ammLiquidityPoolBalance.toUint128();
        _balances.vault = vaultBalance.toUint128();
    }

    function _getPositions(
        AmmTypes.SwapDirection direction,
        mapping(uint32 => StorageInternalTypes.Swap) storage swaps,
        uint32[] storage ids,
        uint256 offset,
        uint256 chunkSize
    ) internal view returns (AmmTypes.Swap[] memory) {
        require(chunkSize > 0, IporErrors.CHUNK_SIZE_EQUAL_ZERO);
        require(chunkSize <= Constants.MAX_CHUNK_SIZE, IporErrors.CHUNK_SIZE_TOO_BIG);

        uint256 swapsIdsLength = PaginationUtils.resolveResultSetSize(ids.length, offset, chunkSize);
        AmmTypes.Swap[] memory derivatives = new AmmTypes.Swap[](swapsIdsLength);

        uint32 id;

        for (uint256 i; i != swapsIdsLength; ) {
            id = ids[i + offset];
            StorageInternalTypes.Swap storage swap = swaps[id];
            derivatives[i] = AmmTypes.Swap(
                swap.id,
                swap.buyer,
                swap.openTimestamp,
                swap.tenor,
                swap.idsIndex,
                swap.collateral,
                swap.notional,
                swap.ibtQuantity,
                swap.fixedInterestRate,
                uint256(swap.liquidationDepositAmount) * 1e18,
                swaps[id].state
            );
            unchecked {
                ++i;
            }
        }
        return derivatives;
    }

    function _updateBalancesWhenOpenSwapPayFixed(
        uint256 collateral,
        uint256 openingFeeLPAmount,
        uint256 openingFeeTreasuryAmount,
        uint256 cfgIporPublicationFee
    ) internal {
        _balances.totalCollateralPayFixed = _balances.totalCollateralPayFixed + collateral.toUint128();

        _balances.iporPublicationFee = _balances.iporPublicationFee + cfgIporPublicationFee.toUint128();

        _balances.liquidityPool = _balances.liquidityPool + openingFeeLPAmount.toUint128();
        _balances.treasury = _balances.treasury + openingFeeTreasuryAmount.toUint128();
    }

    function _updateBalancesWhenOpenSwapReceiveFixed(
        uint256 collateral,
        uint256 openingFeeLPAmount,
        uint256 openingFeeTreasuryAmount,
        uint256 cfgIporPublicationFee
    ) internal {
        _balances.totalCollateralReceiveFixed = _balances.totalCollateralReceiveFixed + collateral.toUint128();

        _balances.iporPublicationFee = _balances.iporPublicationFee + cfgIporPublicationFee.toUint128();

        _balances.liquidityPool = _balances.liquidityPool + openingFeeLPAmount.toUint128();
        _balances.treasury = _balances.treasury + openingFeeTreasuryAmount.toUint128();
    }

    function _updateBalancesWhenCloseSwapPayFixed(
        AmmTypes.Swap memory swap,
        int256 pnlValue,
        uint256 swapUnwindFeeLPAmount,
        uint256 swapUnwindFeeTreasuryAmount
    ) internal {
        _updateBalancesWhenCloseSwap(pnlValue, swapUnwindFeeLPAmount, swapUnwindFeeTreasuryAmount);
        _balances.totalCollateralPayFixed = _balances.totalCollateralPayFixed - swap.collateral.toUint128();
    }

    function _updateBalancesWhenCloseSwapReceiveFixed(
        AmmTypes.Swap memory swap,
        int256 pnlValue,
        uint256 swapUnwindFeeLPAmount,
        uint256 swapUnwindFeeTreasuryAmount
    ) internal {
        _updateBalancesWhenCloseSwap(pnlValue, swapUnwindFeeLPAmount, swapUnwindFeeTreasuryAmount);
        _balances.totalCollateralReceiveFixed = _balances.totalCollateralReceiveFixed - swap.collateral.toUint128();
    }

    function _updateBalancesWhenCloseSwap(
        int256 pnlValue,
        uint256 swapUnwindFeeLPAmount,
        uint256 swapUnwindFeeTreasuryAmount
    ) internal {
        uint256 absPnlValue = IporMath.absoluteValue(pnlValue);

        if (pnlValue > 0) {
            /// @dev Buyer earns, AMM (LP) looses
            require(_balances.liquidityPool >= absPnlValue, AmmErrors.CANNOT_CLOSE_SWAP_LP_IS_TOO_LOW);
            /// @dev When AMM (LP) looses, then  always substract all pnlValue
            _balances.liquidityPool =
                _balances.liquidityPool -
                absPnlValue.toUint128() +
                swapUnwindFeeLPAmount.toUint128();
        } else {
            /// @dev AMM earns, Buyer looses,
            _balances.liquidityPool =
                _balances.liquidityPool +
                absPnlValue.toUint128() +
                swapUnwindFeeLPAmount.toUint128();
        }
        _balances.treasury = _balances.treasury + swapUnwindFeeTreasuryAmount.toUint128();
    }

    function _updateSwapsWhenOpen(
        AmmTypes.SwapDirection direction,
        AmmTypes.NewSwap memory newSwap
    ) internal returns (uint256) {
        _lastSwapId++;
        uint32 id = _lastSwapId;

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

    function _updateSwapsWhenClosePayFixed(AmmTypes.Swap memory swap) internal {
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

    function _updateSwapsWhenCloseReceiveFixed(AmmTypes.Swap memory swap) internal {
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

    function _updateSoapIndicatorsWhenCloseSwapPayFixed(AmmTypes.Swap memory swap, uint256 closingTimestamp) internal {
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
        AmmTypes.Swap memory swap,
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

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.16;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts/utils/math/SafeCast.sol";
import "../interfaces/types/AmmStorageTypes.sol";
import "../interfaces/IAmmStorage.sol";
import "../libraries/Constants.sol";
import "../libraries/PaginationUtils.sol";
import "../security/IporOwnableUpgradeable.sol";
import "contracts/amm/libraries/IporSwapLogic.sol";
import "./libraries/types/StorageInternalTypes.sol";
import "./libraries/SoapIndicatorLogic.sol";
import "./libraries/types/AmmInternalTypes.sol";

//@dev all stored valuse related with money are in 18 decimals.
contract AmmStorage is Initializable, PausableUpgradeable, UUPSUpgradeable, IporOwnableUpgradeable, IAmmStorage {
    using SafeCast for uint256;
    using SoapIndicatorLogic for StorageInternalTypes.SoapIndicatorsMemory;

    address private immutable IPOR_PROTOCOL_ROUTER;
    address private immutable AMM_TREASURY;

    uint32 private _lastSwapId;

    /// @dev DEPRECATED in V2
    address public miltonDeprecated;

    /// @dev DEPRECATED in V2
    address public josephDeprecated;

    StorageInternalTypes.Balances internal _balances;
    StorageInternalTypes.SoapIndicators internal _soapIndicatorsPayFixed;
    StorageInternalTypes.SoapIndicators internal _soapIndicatorsReceiveFixed;
    StorageInternalTypes.SwapContainer internal _swapsPayFixed;
    StorageInternalTypes.SwapContainer internal _swapsReceiveFixed;

    mapping(address => uint128) private _liquidityPoolAccountContribution;
    mapping(IporTypes.SwapTenor => AmmInternalTypes.OpenSwapList) private _openedSwapsPayFixed;
    mapping(IporTypes.SwapTenor => AmmInternalTypes.OpenSwapList) private _openedSwapsReceiveFixed;

    modifier onlyRouter() {
        require(_msgSender() == IPOR_PROTOCOL_ROUTER, IporErrors.CALLER_NOT_IPOR_PROTOCOL_ROUTER);
        _;
    }

    modifier onlyAmmTreasury() {
        require(_msgSender() == AMM_TREASURY, IporErrors.CALLER_NOT_AMM_TREASURY);
        _;
    }

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor(address iporProtocolRouterInput, address ammTreasury) {
        require(
            iporProtocolRouterInput != address(0),
            string.concat(IporErrors.WRONG_ADDRESS, " IPOR protocol router address cannot be 0")
        );
        require(
            ammTreasury != address(0),
            string.concat(IporErrors.WRONG_ADDRESS, " AMM treasury address cannot be 0")
        );

        IPOR_PROTOCOL_ROUTER = iporProtocolRouterInput;
        AMM_TREASURY = ammTreasury;
        _disableInitializers();
    }

    function initialize() public initializer {
        __Pausable_init();
        __Ownable_init();
        __UUPSUpgradeable_init();
    }

    function postUpgrade() public onlyOwner {
        _soapIndicatorsPayFixed.hypotheticalInterestCumulative = IporMath.division(
            _soapIndicatorsPayFixed.hypotheticalInterestCumulative,
            1e36 * Constants.YEAR_IN_SECONDS
        );
        _soapIndicatorsReceiveFixed.hypotheticalInterestCumulative = IporMath.division(
            _soapIndicatorsReceiveFixed.hypotheticalInterestCumulative,
            1e36 * Constants.YEAR_IN_SECONDS
        );
    }

    function getVersion() external pure virtual override returns (uint256) {
        return 2_000;
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

    function getTotalOutstandingNotional()
        external
        view
        override
        returns (uint256 totalNotionalPayFixed, uint256 totalNotionalReceiveFixed)
    {
        totalNotionalPayFixed = _soapIndicatorsPayFixed.totalNotional;
        totalNotionalReceiveFixed = _soapIndicatorsReceiveFixed.totalNotional;
    }

    function getSwapPayFixed(uint256 swapId) external view override returns (AmmTypes.Swap memory) {
        uint32 id = swapId.toUint32();
        StorageInternalTypes.Swap storage swap = _swapsPayFixed.swaps[id];
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

    function getSwapReceiveFixed(uint256 swapId) external view override returns (AmmTypes.Swap memory) {
        uint32 id = swapId.toUint32();
        StorageInternalTypes.Swap storage swap = _swapsReceiveFixed.swaps[id];
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
        return (ids.length, _getPositions(_swapsPayFixed.swaps, ids, offset, chunkSize));
    }

    function getSwapsReceiveFixed(
        address account,
        uint256 offset,
        uint256 chunkSize
    ) external view override returns (uint256 totalCount, AmmTypes.Swap[] memory swaps) {
        uint32[] storage ids = _swapsReceiveFixed.ids[account];
        return (ids.length, _getPositions(_swapsReceiveFixed.swaps, ids, offset, chunkSize));
    }

    function getSwapPayFixedIds(
        address account,
        uint256 offset,
        uint256 chunkSize
    ) external view override returns (uint256 totalCount, uint256[] memory ids) {
        require(chunkSize > 0, IporErrors.CHUNK_SIZE_EQUAL_ZERO);
        require(chunkSize <= Constants.MAX_CHUNK_SIZE, IporErrors.CHUNK_SIZE_TOO_BIG);

        uint32[] storage idsRef = _swapsPayFixed.ids[account];
        totalCount = idsRef.length;

        uint256 resultSetSize = PaginationUtils.resolveResultSetSize(totalCount, offset, chunkSize);

        ids = new uint256[](resultSetSize);

        for (uint256 i; i != resultSetSize; ) {
            ids[i] = idsRef[offset + i];
            unchecked {
                ++i;
            }
        }
    }

    function getSwapReceiveFixedIds(
        address account,
        uint256 offset,
        uint256 chunkSize
    ) external view override returns (uint256 totalCount, uint256[] memory ids) {
        require(chunkSize > 0, IporErrors.CHUNK_SIZE_EQUAL_ZERO);
        require(chunkSize <= Constants.MAX_CHUNK_SIZE, IporErrors.CHUNK_SIZE_TOO_BIG);

        uint32[] storage idsRef = _swapsReceiveFixed.ids[account];
        totalCount = idsRef.length;

        uint256 resultSetSize = PaginationUtils.resolveResultSetSize(totalCount, offset, chunkSize);

        ids = new uint256[](resultSetSize);

        for (uint256 i; i != resultSetSize; ) {
            ids[i] = idsRef[offset + i];
            unchecked {
                ++i;
            }
        }
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

    function calculateSoap(
        uint256 ibtPrice,
        uint256 calculateTimestamp
    ) external view override returns (int256 soapPayFixed, int256 soapReceiveFixed, int256 soap) {
        StorageInternalTypes.SoapIndicatorsMemory memory spf = StorageInternalTypes.SoapIndicatorsMemory(
            _soapIndicatorsPayFixed.hypotheticalInterestCumulative,
            _soapIndicatorsPayFixed.totalNotional,
            _soapIndicatorsPayFixed.totalIbtQuantity,
            _soapIndicatorsPayFixed.averageInterestRate,
            _soapIndicatorsPayFixed.rebalanceTimestamp
        );
        int256 _soapPayFixed = spf.calculateSoapPayFixed(calculateTimestamp, ibtPrice);

        StorageInternalTypes.SoapIndicatorsMemory memory srf = StorageInternalTypes.SoapIndicatorsMemory(
            _soapIndicatorsReceiveFixed.hypotheticalInterestCumulative,
            _soapIndicatorsReceiveFixed.totalNotional,
            _soapIndicatorsReceiveFixed.totalIbtQuantity,
            _soapIndicatorsReceiveFixed.averageInterestRate,
            _soapIndicatorsReceiveFixed.rebalanceTimestamp
        );
        int256 _soapReceiveFixed = srf.calculateSoapReceiveFixed(calculateTimestamp, ibtPrice);

        return (
            soapPayFixed = _soapPayFixed,
            soapReceiveFixed = _soapReceiveFixed,
            soap = _soapPayFixed + _soapReceiveFixed
        );
    }

    function calculateSoapPayFixed(
        uint256 ibtPrice,
        uint256 calculateTimestamp
    ) external view override returns (int256 soapPayFixed) {
        return _calculateSoapPayFixed(ibtPrice, calculateTimestamp);
    }

    function calculateSoapReceiveFixed(
        uint256 ibtPrice,
        uint256 calculateTimestamp
    ) external view override returns (int256 soapReceiveFixed) {
        return _calculateSoapReceiveFixed(ibtPrice, calculateTimestamp);
    }

    function addLiquidityInternal(
        address account,
        uint256 assetAmount,
        uint256 cfgMaxLiquidityPoolBalance,
        uint256 cfgMaxLpAccountContribution
    ) external override onlyRouter {
        require(assetAmount > 0, AmmErrors.DEPOSIT_AMOUNT_IS_TOO_LOW);

        uint128 newLiquidityPoolBalance = _balances.liquidityPool + assetAmount.toUint128();

        require(newLiquidityPoolBalance <= cfgMaxLiquidityPoolBalance, AmmErrors.LIQUIDITY_POOL_BALANCE_IS_TOO_HIGH);

        uint128 newLiquidityPoolAccountContribution = _liquidityPoolAccountContribution[account] +
            assetAmount.toUint128();

        require(
            newLiquidityPoolAccountContribution <= cfgMaxLpAccountContribution,
            AmmErrors.LP_ACCOUNT_CONTRIBUTION_IS_TOO_HIGH
        );

        _balances.liquidityPool = newLiquidityPoolBalance;
        _liquidityPoolAccountContribution[account] = newLiquidityPoolAccountContribution;
    }

    function subtractLiquidityInternal(uint256 assetAmount) external override onlyRouter {
        _balances.liquidityPool = _balances.liquidityPool - assetAmount.toUint128();
    }

    function updateStorageWhenOpenSwapPayFixedInternal(
        AmmTypes.NewSwap memory newSwap,
        uint256 cfgIporPublicationFee
    ) external override onlyRouter returns (uint256) {
        uint256 id = _updateSwapsWhenOpenPayFixed(newSwap);
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
        uint256 id = _updateSwapsWhenOpenReceiveFixed(newSwap);
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
        int256 payoff,
        uint256 closingTimestamp
    ) external override onlyRouter returns (AmmInternalTypes.OpenSwapItem memory closedSwap) {
        _updateSwapsWhenClosePayFixed(swap);
        _updateBalancesWhenCloseSwapPayFixed(swap, payoff);
        _updateSoapIndicatorsWhenCloseSwapPayFixed(swap, closingTimestamp);
        return _updateOpenedSwapWhenClosePayFixed(swap.tenor, swap.id);
    }

    function updateStorageWhenCloseSwapReceiveFixedInternal(
        AmmTypes.Swap memory swap,
        int256 payoff,
        uint256 closingTimestamp
    ) external override onlyRouter returns (AmmInternalTypes.OpenSwapItem memory closedSwap) {
        _updateSwapsWhenCloseReceiveFixed(swap);
        _updateBalancesWhenCloseSwapReceiveFixed(swap, payoff);
        _updateSoapIndicatorsWhenCloseSwapReceiveFixed(swap, closingTimestamp);
        return _updateOpenedSwapWhenCloseReceiveFixed(swap.tenor, swap.id);
    }

    function updateStorageWhenWithdrawFromAssetManagement(
        uint256 withdrawnAmount,
        uint256 vaultBalance
    ) external override onlyAmmTreasury {
        uint256 currentVaultBalance = _balances.vault;
        // We nedd this because for compound if we deposit and withdraw we could get negative intrest based on rounds
        require(vaultBalance + withdrawnAmount >= currentVaultBalance, AmmErrors.INTEREST_FROM_STRATEGY_BELOW_ZERO);

        uint256 interest = vaultBalance + withdrawnAmount - currentVaultBalance;

        uint256 liquidityPoolBalance = _balances.liquidityPool + interest;

        _balances.liquidityPool = liquidityPoolBalance.toUint128();
        _balances.vault = vaultBalance.toUint128();
    }

    function updateStorageWhenDepositToAssetManagement(
        uint256 depositAmount,
        uint256 vaultBalance
    ) external override onlyAmmTreasury {
        require(vaultBalance >= depositAmount, AmmErrors.VAULT_BALANCE_LOWER_THAN_DEPOSIT_VALUE);

        uint256 currentVaultBalance = _balances.vault;

        require(currentVaultBalance <= (vaultBalance - depositAmount), AmmErrors.INTEREST_FROM_STRATEGY_BELOW_ZERO);

        uint256 interest = currentVaultBalance > 0 ? (vaultBalance - currentVaultBalance - depositAmount) : 0;
        _balances.vault = vaultBalance.toUint128();
        uint256 liquidityPoolBalance = _balances.liquidityPool + interest;
        _balances.liquidityPool = liquidityPoolBalance.toUint128();
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

    function pause() external override onlyOwner {
        _pause();
    }

    function unpause() external override onlyOwner {
        _unpause();
    }

    function getLiquidityPoolAccountContribution(address account) external view returns (uint256) {
        return _liquidityPoolAccountContribution[account];
    }

    function _getPositions(
        mapping(uint32 => StorageInternalTypes.Swap) storage swaps,
        uint32[] storage ids,
        uint256 offset,
        uint256 chunkSize
    ) internal view returns (AmmTypes.Swap[] memory) {
        require(chunkSize > 0, IporErrors.CHUNK_SIZE_EQUAL_ZERO);
        require(chunkSize <= Constants.MAX_CHUNK_SIZE, IporErrors.CHUNK_SIZE_TOO_BIG);

        uint256 swapsIdsLength = PaginationUtils.resolveResultSetSize(ids.length, offset, chunkSize);
        AmmTypes.Swap[] memory derivatives = new AmmTypes.Swap[](swapsIdsLength);

        for (uint256 i; i != swapsIdsLength; ) {
            uint32 id = ids[i + offset];
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

    function _calculateSoapPayFixed(
        uint256 ibtPrice,
        uint256 calculateTimestamp
    ) internal view returns (int256 soapPayFixed) {
        StorageInternalTypes.SoapIndicatorsMemory memory spf = StorageInternalTypes.SoapIndicatorsMemory(
            _soapIndicatorsPayFixed.hypotheticalInterestCumulative,
            _soapIndicatorsPayFixed.totalNotional,
            _soapIndicatorsPayFixed.totalIbtQuantity,
            _soapIndicatorsPayFixed.averageInterestRate,
            _soapIndicatorsPayFixed.rebalanceTimestamp
        );
        soapPayFixed = spf.calculateSoapPayFixed(calculateTimestamp, ibtPrice);
    }

    function _calculateSoapReceiveFixed(
        uint256 ibtPrice,
        uint256 calculateTimestamp
    ) internal view returns (int256 soapReceiveFixed) {
        StorageInternalTypes.SoapIndicatorsMemory memory srf = StorageInternalTypes.SoapIndicatorsMemory(
            _soapIndicatorsReceiveFixed.hypotheticalInterestCumulative,
            _soapIndicatorsReceiveFixed.totalNotional,
            _soapIndicatorsReceiveFixed.totalIbtQuantity,
            _soapIndicatorsReceiveFixed.averageInterestRate,
            _soapIndicatorsReceiveFixed.rebalanceTimestamp
        );
        soapReceiveFixed = srf.calculateSoapReceiveFixed(calculateTimestamp, ibtPrice);
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

    function _updateBalancesWhenCloseSwapPayFixed(AmmTypes.Swap memory swap, int256 payoff) internal {
        _updateBalancesWhenCloseSwap(payoff);

        _balances.totalCollateralPayFixed = _balances.totalCollateralPayFixed - swap.collateral.toUint128();
    }

    function _updateBalancesWhenCloseSwapReceiveFixed(AmmTypes.Swap memory swap, int256 payoff) internal {
        _updateBalancesWhenCloseSwap(payoff);

        _balances.totalCollateralReceiveFixed = _balances.totalCollateralReceiveFixed - swap.collateral.toUint128();
    }

    function _updateBalancesWhenCloseSwap(int256 payoff) internal {
        uint256 absPayoff = IporMath.absoluteValue(payoff);

        if (payoff > 0) {
            /// @dev Buyer earns, AmmTreasury (LP) looses
            require(_balances.liquidityPool >= absPayoff, AmmErrors.CANNOT_CLOSE_SWAP_LP_IS_TOO_LOW);

            /// @dev When AmmTreasury (LP) looses, then  always substract all payoff
            _balances.liquidityPool = _balances.liquidityPool - absPayoff.toUint128();
        } else {
            /// @dev AmmTreasury earns, Buyer looses,
            _balances.liquidityPool = _balances.liquidityPool + absPayoff.toUint128();
        }
    }

    function _updateSwapsWhenOpenPayFixed(AmmTypes.NewSwap memory newSwap) internal returns (uint256) {
        _lastSwapId++;
        uint32 id = _lastSwapId;

        StorageInternalTypes.Swap storage swap = _swapsPayFixed.swaps[id];

        swap.id = id;
        swap.buyer = newSwap.buyer;
        swap.openTimestamp = newSwap.openTimestamp.toUint32();
        swap.idsIndex = _swapsPayFixed.ids[newSwap.buyer].length.toUint32();
        swap.collateral = newSwap.collateral.toUint128();
        swap.notional = newSwap.notional.toUint128();
        swap.ibtQuantity = newSwap.ibtQuantity.toUint128();
        swap.fixedInterestRate = newSwap.fixedInterestRate.toUint64();
        swap.liquidationDepositAmount = newSwap.liquidationDepositAmount.toUint32();
        swap.state = IporTypes.SwapState.ACTIVE;
        swap.tenor = newSwap.tenor;

        _swapsPayFixed.ids[newSwap.buyer].push(id);
        _lastSwapId = id;

        return id;
    }

    function _updateSwapsWhenOpenReceiveFixed(AmmTypes.NewSwap memory newSwap) internal returns (uint256) {
        _lastSwapId++;
        uint32 id = _lastSwapId;

        StorageInternalTypes.Swap storage swap = _swapsReceiveFixed.swaps[id];

        swap.id = id;
        swap.buyer = newSwap.buyer;
        swap.openTimestamp = newSwap.openTimestamp.toUint32();
        swap.idsIndex = _swapsReceiveFixed.ids[newSwap.buyer].length.toUint32();
        swap.collateral = newSwap.collateral.toUint128();
        swap.notional = newSwap.notional.toUint128();
        swap.ibtQuantity = newSwap.ibtQuantity.toUint128();
        swap.fixedInterestRate = newSwap.fixedInterestRate.toUint64();
        swap.liquidationDepositAmount = newSwap.liquidationDepositAmount.toUint32();
        swap.state = IporTypes.SwapState.ACTIVE;
        swap.tenor = newSwap.tenor;

        _swapsReceiveFixed.ids[newSwap.buyer].push(id);
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
        uint256 notional,
        uint256 fixedInterestRate,
        uint256 ibtQuantity
    ) internal {
        StorageInternalTypes.SoapIndicatorsMemory memory pf = StorageInternalTypes.SoapIndicatorsMemory(
            _soapIndicatorsPayFixed.hypotheticalInterestCumulative,
            _soapIndicatorsPayFixed.totalNotional,
            _soapIndicatorsPayFixed.totalIbtQuantity,
            _soapIndicatorsPayFixed.averageInterestRate,
            _soapIndicatorsPayFixed.rebalanceTimestamp
        );

        pf.rebalanceWhenOpenSwap(openTimestamp, notional, fixedInterestRate, ibtQuantity);

        _soapIndicatorsPayFixed.rebalanceTimestamp = pf.rebalanceTimestamp.toUint32();
        _soapIndicatorsPayFixed.totalNotional = pf.totalNotional.toUint128();
        _soapIndicatorsPayFixed.averageInterestRate = pf.averageInterestRate.toUint64();
        _soapIndicatorsPayFixed.totalIbtQuantity = pf.totalIbtQuantity.toUint128();
        _soapIndicatorsPayFixed.hypotheticalInterestCumulative = pf.hypotheticalInterestCumulative;
    }

    function _updateSoapIndicatorsWhenOpenSwapReceiveFixed(
        uint256 openTimestamp,
        uint256 notional,
        uint256 fixedInterestRate,
        uint256 ibtQuantity
    ) internal {
        StorageInternalTypes.SoapIndicatorsMemory memory rf = StorageInternalTypes.SoapIndicatorsMemory(
            _soapIndicatorsReceiveFixed.hypotheticalInterestCumulative,
            _soapIndicatorsReceiveFixed.totalNotional,
            _soapIndicatorsReceiveFixed.totalIbtQuantity,
            _soapIndicatorsReceiveFixed.averageInterestRate,
            _soapIndicatorsReceiveFixed.rebalanceTimestamp
        );
        rf.rebalanceWhenOpenSwap(openTimestamp, notional, fixedInterestRate, ibtQuantity);

        _soapIndicatorsReceiveFixed.rebalanceTimestamp = rf.rebalanceTimestamp.toUint32();
        _soapIndicatorsReceiveFixed.totalNotional = rf.totalNotional.toUint128();
        _soapIndicatorsReceiveFixed.averageInterestRate = rf.averageInterestRate.toUint64();
        _soapIndicatorsReceiveFixed.totalIbtQuantity = rf.totalIbtQuantity.toUint128();
        _soapIndicatorsReceiveFixed.hypotheticalInterestCumulative = rf.hypotheticalInterestCumulative;
    }

    function _updateSoapIndicatorsWhenCloseSwapPayFixed(AmmTypes.Swap memory swap, uint256 closingTimestamp) internal {
        StorageInternalTypes.SoapIndicatorsMemory memory pf = StorageInternalTypes.SoapIndicatorsMemory(
            _soapIndicatorsPayFixed.hypotheticalInterestCumulative,
            _soapIndicatorsPayFixed.totalNotional,
            _soapIndicatorsPayFixed.totalIbtQuantity,
            _soapIndicatorsPayFixed.averageInterestRate,
            _soapIndicatorsPayFixed.rebalanceTimestamp
        );

        pf.rebalanceWhenCloseSwap(
            closingTimestamp,
            swap.openTimestamp,
            swap.notional,
            swap.fixedInterestRate,
            swap.ibtQuantity
        );

        _soapIndicatorsPayFixed = StorageInternalTypes.SoapIndicators(
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
        StorageInternalTypes.SoapIndicatorsMemory memory rf = StorageInternalTypes.SoapIndicatorsMemory(
            _soapIndicatorsReceiveFixed.hypotheticalInterestCumulative,
            _soapIndicatorsReceiveFixed.totalNotional,
            _soapIndicatorsReceiveFixed.totalIbtQuantity,
            _soapIndicatorsReceiveFixed.averageInterestRate,
            _soapIndicatorsReceiveFixed.rebalanceTimestamp
        );

        rf.rebalanceWhenCloseSwap(
            closingTimestamp,
            swap.openTimestamp,
            swap.notional,
            swap.fixedInterestRate,
            swap.ibtQuantity
        );

        _soapIndicatorsReceiveFixed = StorageInternalTypes.SoapIndicators(
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

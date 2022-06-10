// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.14;

import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts/utils/math/SafeCast.sol";
import "../interfaces/types/MiltonStorageTypes.sol";
import "../libraries/Constants.sol";
import "../libraries/PaginationUtils.sol";
import "../interfaces/types/MiltonStorageTypes.sol";
import "../interfaces/IMiltonStorage.sol";
import "../security/IporOwnableUpgradeable.sol";
import "./libraries/types/AmmMiltonStorageTypes.sol";
import "./libraries/SoapIndicatorLogic.sol";

//@dev all stored valuse related with money are in 18 decimals.
contract MiltonStorage is
    UUPSUpgradeable,
    PausableUpgradeable,
    IporOwnableUpgradeable,
    IMiltonStorage
{
    using SafeCast for uint256;
    using SoapIndicatorLogic for AmmMiltonStorageTypes.SoapIndicatorsMemory;

    uint32 private _lastSwapId;
    address private _milton;
    address private _joseph;

    AmmMiltonStorageTypes.Balances internal _balances;
    AmmMiltonStorageTypes.SoapIndicators internal _soapIndicatorsPayFixed;
    AmmMiltonStorageTypes.SoapIndicators internal _soapIndicatorsReceiveFixed;
    AmmMiltonStorageTypes.IporSwapContainer internal _swapsPayFixed;
    AmmMiltonStorageTypes.IporSwapContainer internal _swapsReceiveFixed;

    modifier onlyMilton() {
        require(_msgSender() == _milton, IporErrors.CALLER_NOT_MILTON);
        _;
    }

    modifier onlyJoseph() {
        require(_msgSender() == _joseph, MiltonErrors.CALLER_NOT_JOSEPH);
        _;
    }

    function initialize() public initializer {
        __Ownable_init();
    }

    function getVersion() external pure virtual override returns (uint256) {
        return 1;
    }

    function getLastSwapId() external view override returns (uint256) {
        return _lastSwapId;
    }

    function getBalance()
        external
        view
        virtual
        override
        returns (IporTypes.MiltonBalancesMemory memory)
    {
        return
            IporTypes.MiltonBalancesMemory(
                _balances.totalCollateralPayFixed,
                _balances.totalCollateralReceiveFixed,
                _balances.liquidityPool,
                _balances.vault
            );
    }

    function getExtendedBalance()
        external
        view
        override
        returns (MiltonStorageTypes.ExtendedBalancesMemory memory)
    {
        return
            MiltonStorageTypes.ExtendedBalancesMemory(
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

    function getSwapPayFixed(uint256 swapId)
        external
        view
        override
        returns (IporTypes.IporSwapMemory memory)
    {
        uint32 id = swapId.toUint32();
        AmmMiltonStorageTypes.IporSwap storage swap = _swapsPayFixed.swaps[id];
        return
            IporTypes.IporSwapMemory(
                swap.id,
                swap.buyer,
                swap.openTimestamp,
                swap.openTimestamp + Constants.SWAP_DEFAULT_PERIOD_IN_SECONDS,
                swap.idsIndex,
                swap.collateral,
                swap.notional,
                swap.ibtQuantity,
                swap.fixedInterestRate,
                swap.liquidationDepositAmount * Constants.D18,
                uint256(swap.state)
            );
    }

    function getSwapReceiveFixed(uint256 swapId)
        external
        view
        override
        returns (IporTypes.IporSwapMemory memory)
    {
        uint32 id = swapId.toUint32();
        AmmMiltonStorageTypes.IporSwap storage swap = _swapsReceiveFixed.swaps[id];
        return
            IporTypes.IporSwapMemory(
                swap.id,
                swap.buyer,
                swap.openTimestamp,
                swap.openTimestamp + Constants.SWAP_DEFAULT_PERIOD_IN_SECONDS,
                swap.idsIndex,
                swap.collateral,
                swap.notional,
                swap.ibtQuantity,
                swap.fixedInterestRate,
                swap.liquidationDepositAmount * Constants.D18,
                uint256(swap.state)
            );
    }

    function getSwapsPayFixed(
        address account,
        uint256 offset,
        uint256 chunkSize
    ) external view override returns (uint256 totalCount, IporTypes.IporSwapMemory[] memory swaps) {
        uint32[] storage ids = _swapsPayFixed.ids[account];
        return (ids.length, _getPositions(_swapsPayFixed.swaps, ids, offset, chunkSize));
    }

    function getSwapsReceiveFixed(
        address account,
        uint256 offset,
        uint256 chunkSize
    ) external view override returns (uint256 totalCount, IporTypes.IporSwapMemory[] memory swaps) {
        uint32[] storage ids = _swapsReceiveFixed.ids[account];
        return (ids.length, _getPositions(_swapsReceiveFixed.swaps, ids, offset, chunkSize));
    }

    function getSwapPayFixedIds(
        address account,
        uint256 offset,
        uint256 chunkSize
    ) external view override returns (uint256 totalCount, uint256[] memory ids) {
        require(chunkSize != 0, IporErrors.CHUNK_SIZE_EQUAL_ZERO);
        require(chunkSize <= Constants.MAX_CHUNK_SIZE, IporErrors.CHUNK_SIZE_TOO_BIG);

        uint32[] storage idsRef = _swapsPayFixed.ids[account];
        uint256 resultSetSize = PaginationUtils.resolveResultSetSize(
            idsRef.length,
            offset,
            chunkSize
        );
        uint256[] memory ids = new uint256[](resultSetSize);
        for (uint256 i = 0; i != resultSetSize; i++) {
            ids[i] = idsRef[offset + i];
        }
        return (idsRef.length, ids);
    }

    function getSwapReceiveFixedIds(
        address account,
        uint256 offset,
        uint256 chunkSize
    ) external view override returns (uint256 totalCount, uint256[] memory ids) {
        require(chunkSize != 0, IporErrors.CHUNK_SIZE_EQUAL_ZERO);
        require(chunkSize <= Constants.MAX_CHUNK_SIZE, IporErrors.CHUNK_SIZE_TOO_BIG);

        uint32[] storage idsRef = _swapsReceiveFixed.ids[account];
        uint256 resultSetSize = PaginationUtils.resolveResultSetSize(
            idsRef.length,
            offset,
            chunkSize
        );
        uint256[] memory ids = new uint256[](resultSetSize);
        for (uint256 i = 0; i != resultSetSize; i++) {
            ids[i] = idsRef[offset + i];
        }
        return (idsRef.length, ids);
    }

    function getSwapIds(
        address account,
        uint256 offset,
        uint256 chunkSize
    )
        external
        view
        override
        returns (uint256 totalCount, MiltonStorageTypes.IporSwapId[] memory ids)
    {
        require(chunkSize != 0, IporErrors.CHUNK_SIZE_EQUAL_ZERO);
        require(chunkSize <= Constants.MAX_CHUNK_SIZE, IporErrors.CHUNK_SIZE_TOO_BIG);

        uint32[] storage payFixedIdsRef = _swapsPayFixed.ids[account];
        uint256 payFixedLength = payFixedIdsRef.length;

        uint32[] storage receiveFixedIdsRef = _swapsReceiveFixed.ids[account];
        uint256 receiveFixedLength = receiveFixedIdsRef.length;

        uint256 resultSetSize = PaginationUtils.resolveResultSetSize(
            payFixedLength + receiveFixedLength,
            offset,
            chunkSize
        );

        MiltonStorageTypes.IporSwapId[] memory ids = new MiltonStorageTypes.IporSwapId[](
            resultSetSize
        );
        for (uint256 i = 0; i != resultSetSize; i++) {
            if (offset + i < payFixedLength) {
                ids[i] = MiltonStorageTypes.IporSwapId(payFixedIdsRef[offset + i], 0);
            } else {
                ids[i] = MiltonStorageTypes.IporSwapId(
                    receiveFixedIdsRef[offset + i - payFixedLength],
                    1
                );
            }
        }
        return (payFixedLength + receiveFixedLength, ids);
    }

    function calculateSoap(uint256 ibtPrice, uint256 calculateTimestamp)
        external
        view
        override
        returns (
            int256 soapPayFixed,
            int256 soapReceiveFixed,
            int256 soap
        )
    {
        (int256 qSoapPf, int256 qSoapRf, int256 qSoap) = _calculateQuasiSoap(
            ibtPrice,
            calculateTimestamp
        );

        return (
            soapPayFixed = IporMath.divisionInt(qSoapPf, Constants.WAD_P2_YEAR_IN_SECONDS_INT),
            soapReceiveFixed = IporMath.divisionInt(qSoapRf, Constants.WAD_P2_YEAR_IN_SECONDS_INT),
            soap = IporMath.divisionInt(qSoap, Constants.WAD_P2_YEAR_IN_SECONDS_INT)
        );
    }

    function calculateSoapPayFixed(uint256 ibtPrice, uint256 calculateTimestamp)
        external
        view
        override
        returns (int256 soapPayFixed)
    {
        int256 qSoapPf = _calculateQuasiSoapPayFixed(ibtPrice, calculateTimestamp);

        soapPayFixed = IporMath.divisionInt(qSoapPf, Constants.WAD_P2_YEAR_IN_SECONDS_INT);
    }

    function calculateSoapReceiveFixed(uint256 ibtPrice, uint256 calculateTimestamp)
        external
        view
        override
        returns (int256 soapReceiveFixed)
    {
        int256 qSoapRf = _calculateQuasiSoapReceiveFixed(ibtPrice, calculateTimestamp);

        soapReceiveFixed = IporMath.divisionInt(qSoapRf, Constants.WAD_P2_YEAR_IN_SECONDS_INT);
    }

    function addLiquidity(uint256 assetAmount) external override onlyJoseph {
        require(assetAmount != 0, MiltonErrors.DEPOSIT_AMOUNT_TOO_LOW);
        _balances.liquidityPool = _balances.liquidityPool + assetAmount.toUint128();
    }

    function subtractLiquidity(uint256 assetAmount) external override onlyJoseph {
        _balances.liquidityPool = _balances.liquidityPool - assetAmount.toUint128();
    }

    function updateStorageWhenOpenSwapPayFixed(
        AmmTypes.NewSwap memory newSwap,
        uint256 cfgIporPublicationFee
    ) external override onlyMilton returns (uint256) {
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
        return id;
    }

    function updateStorageWhenOpenSwapReceiveFixed(
        AmmTypes.NewSwap memory newSwap,
        uint256 cfgIporPublicationFee
    ) external override onlyMilton returns (uint256) {
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
        return id;
    }

    function updateStorageWhenCloseSwapPayFixed(
        address liquidator,
        IporTypes.IporSwapMemory memory iporSwap,
        int256 payoff,
        uint256 closingTimestamp,
        uint256 cfgIncomeFeeRate,
        uint256 cfgMinLiquidationThresholdToCloseBeforeMaturity,
        uint256 cfgSecondsBeforeMaturityWhenPositionCanBeClosed
    ) external override onlyMilton {
        _updateSwapsWhenClosePayFixed(iporSwap);
        _updateBalancesWhenCloseSwapPayFixed(
            liquidator,
            iporSwap,
            payoff,
            closingTimestamp,
            cfgIncomeFeeRate,
            cfgMinLiquidationThresholdToCloseBeforeMaturity,
            cfgSecondsBeforeMaturityWhenPositionCanBeClosed
        );
        _updateSoapIndicatorsWhenCloseSwapPayFixed(iporSwap, closingTimestamp);
    }

    function updateStorageWhenCloseSwapReceiveFixed(
        address liquidator,
        IporTypes.IporSwapMemory memory iporSwap,
        int256 payoff,
        uint256 closingTimestamp,
        uint256 cfgIncomeFeeRate,
        uint256 cfgMinLiquidationThresholdToCloseBeforeMaturity,
        uint256 cfgSecondsBeforeMaturityWhenPositionCanBeClosed
    ) external override onlyMilton {
        _updateSwapsWhenCloseReceiveFixed(iporSwap);
        _updateBalancesWhenCloseSwapReceiveFixed(
            liquidator,
            iporSwap,
            payoff,
            closingTimestamp,
            cfgIncomeFeeRate,
            cfgMinLiquidationThresholdToCloseBeforeMaturity,
            cfgSecondsBeforeMaturityWhenPositionCanBeClosed
        );
        _updateSoapIndicatorsWhenCloseSwapReceiveFixed(iporSwap, closingTimestamp);
    }

    function updateStorageWhenWithdrawFromStanley(uint256 withdrawnAmount, uint256 vaultBalance)
        external
        override
        onlyMilton
    {
        uint256 currentVaultBalance = _balances.vault;
        // We nedd this becouse for compound if we deposit and withdraw we could get negative intrest based on rounds
        require(
            vaultBalance + withdrawnAmount >= currentVaultBalance,
            MiltonErrors.INTREST_FROM_STRATEGY_BELOW_ZERO
        );
        uint256 interest = vaultBalance + withdrawnAmount - currentVaultBalance;

        uint256 liquidityPoolBalance = _balances.liquidityPool + interest;
        _balances.liquidityPool = liquidityPoolBalance.toUint128();
        _balances.vault = vaultBalance.toUint128();
    }

    function updateStorageWhenDepositToStanley(uint256 depositAmount, uint256 vaultBalance)
        external
        override
        onlyMilton
    {
        require(vaultBalance >= depositAmount, MiltonErrors.VAULT_BALANCE_LOWER_THAN_DEPOSIT_VALUE);

        uint256 currentVaultBalance = _balances.vault;

        require(
            currentVaultBalance <= (vaultBalance - depositAmount),
            MiltonErrors.INTREST_FROM_STRATEGY_BELOW_ZERO
        );
        uint256 interest = currentVaultBalance != 0
            ? (vaultBalance - currentVaultBalance - depositAmount)
            : 0;
        _balances.vault = vaultBalance.toUint128();
        uint256 liquidityPoolBalance = _balances.liquidityPool + interest;
        _balances.liquidityPool = liquidityPoolBalance.toUint128();
    }

    function updateStorageWhenTransferToCharlieTreasury(uint256 transferredAmount)
        external
        override
        onlyJoseph
    {
        require(transferredAmount != 0, IporErrors.NOT_ENOUGH_AMOUNT_TO_TRANSFER);

        uint256 balance = _balances.iporPublicationFee;

        require(transferredAmount <= balance, MiltonErrors.PUBLICATION_FEE_BALANCE_TOO_LOW);

        balance = balance - transferredAmount;

        _balances.iporPublicationFee = balance.toUint128();
    }

    function updateStorageWhenTransferToTreasury(uint256 transferredAmount)
        external
        override
        onlyJoseph
    {
        require(transferredAmount != 0, IporErrors.NOT_ENOUGH_AMOUNT_TO_TRANSFER);

        uint256 balance = _balances.treasury;

        require(transferredAmount <= balance, MiltonErrors.TREASURE_BALANCE_TOO_LOW);

        balance = balance - transferredAmount;

        _balances.treasury = balance.toUint128();
    }

    function setMilton(address newMilton) external override onlyOwner {
        require(newMilton != address(0), IporErrors.WRONG_ADDRESS);
        address oldMilton = _milton;
        _milton = newMilton;
        emit MiltonChanged(_msgSender(), oldMilton, newMilton);
    }

    function setJoseph(address newJoseph) external override onlyOwner {
        require(newJoseph != address(0), IporErrors.WRONG_ADDRESS);
        address oldJoseph = _joseph;
        _joseph = newJoseph;
        emit JosephChanged(_msgSender(), oldJoseph, newJoseph);
    }

    function pause() external override onlyOwner {
        _pause();
    }

    function unpause() external override onlyOwner {
        _unpause();
    }

    function _getPositions(
        mapping(uint32 => AmmMiltonStorageTypes.IporSwap) storage swaps,
        uint32[] storage ids,
        uint256 offset,
        uint256 chunkSize
    ) internal view returns (IporTypes.IporSwapMemory[] memory) {
        require(chunkSize != 0, IporErrors.CHUNK_SIZE_EQUAL_ZERO);
        require(chunkSize <= Constants.MAX_CHUNK_SIZE, IporErrors.CHUNK_SIZE_TOO_BIG);

        uint256 swapsIdsLength = PaginationUtils.resolveResultSetSize(
            ids.length,
            offset,
            chunkSize
        );
        IporTypes.IporSwapMemory[] memory derivatives = new IporTypes.IporSwapMemory[](
            swapsIdsLength
        );

        for (uint256 i = 0; i != swapsIdsLength; i++) {
            uint32 id = ids[i + offset];
            AmmMiltonStorageTypes.IporSwap storage swap = swaps[id];
            derivatives[i] = IporTypes.IporSwapMemory(
                swap.id,
                swap.buyer,
                swap.openTimestamp,
                swap.openTimestamp + Constants.SWAP_DEFAULT_PERIOD_IN_SECONDS,
                swap.idsIndex,
                swap.collateral,
                swap.notional,
                swap.ibtQuantity,
                swap.fixedInterestRate,
                swap.liquidationDepositAmount * Constants.D18,
                uint256(swaps[id].state)
            );
        }
        return derivatives;
    }

    function _calculateQuasiSoap(uint256 ibtPrice, uint256 calculateTimestamp)
        internal
        view
        returns (
            int256 soapPayFixed,
            int256 soapReceiveFixed,
            int256 soap
        )
    {
        AmmMiltonStorageTypes.SoapIndicatorsMemory memory spf = AmmMiltonStorageTypes
            .SoapIndicatorsMemory(
                _soapIndicatorsPayFixed.quasiHypotheticalInterestCumulative,
                _soapIndicatorsPayFixed.totalNotional,
                _soapIndicatorsPayFixed.totalIbtQuantity,
                _soapIndicatorsPayFixed.averageInterestRate,
                _soapIndicatorsPayFixed.rebalanceTimestamp
            );
        int256 _soapPayFixed = spf.calculateQuasiSoapPayFixed(calculateTimestamp, ibtPrice);

        AmmMiltonStorageTypes.SoapIndicatorsMemory memory srf = AmmMiltonStorageTypes
            .SoapIndicatorsMemory(
                _soapIndicatorsReceiveFixed.quasiHypotheticalInterestCumulative,
                _soapIndicatorsReceiveFixed.totalNotional,
                _soapIndicatorsReceiveFixed.totalIbtQuantity,
                _soapIndicatorsReceiveFixed.averageInterestRate,
                _soapIndicatorsReceiveFixed.rebalanceTimestamp
            );
        int256 _soapReceiveFixed = srf.calculateQuasiSoapReceiveFixed(calculateTimestamp, ibtPrice);

        return (
            soapPayFixed = _soapPayFixed,
            soapReceiveFixed = _soapReceiveFixed,
            soap = _soapPayFixed + _soapReceiveFixed
        );
    }

    function _calculateQuasiSoapPayFixed(uint256 ibtPrice, uint256 calculateTimestamp)
        internal
        view
        returns (int256 soapPayFixed)
    {
        AmmMiltonStorageTypes.SoapIndicatorsMemory memory spf = AmmMiltonStorageTypes
            .SoapIndicatorsMemory(
                _soapIndicatorsPayFixed.quasiHypotheticalInterestCumulative,
                _soapIndicatorsPayFixed.totalNotional,
                _soapIndicatorsPayFixed.totalIbtQuantity,
                _soapIndicatorsPayFixed.averageInterestRate,
                _soapIndicatorsPayFixed.rebalanceTimestamp
            );
        soapPayFixed = spf.calculateQuasiSoapPayFixed(calculateTimestamp, ibtPrice);
    }

    function _calculateQuasiSoapReceiveFixed(uint256 ibtPrice, uint256 calculateTimestamp)
        internal
        view
        returns (int256 soapReceiveFixed)
    {
        AmmMiltonStorageTypes.SoapIndicatorsMemory memory srf = AmmMiltonStorageTypes
            .SoapIndicatorsMemory(
                _soapIndicatorsReceiveFixed.quasiHypotheticalInterestCumulative,
                _soapIndicatorsReceiveFixed.totalNotional,
                _soapIndicatorsReceiveFixed.totalIbtQuantity,
                _soapIndicatorsReceiveFixed.averageInterestRate,
                _soapIndicatorsReceiveFixed.rebalanceTimestamp
            );
        soapReceiveFixed = srf.calculateQuasiSoapReceiveFixed(calculateTimestamp, ibtPrice);
    }

    function _updateBalancesWhenOpenSwapPayFixed(
        uint256 collateral,
        uint256 openingFeeLPAmount,
        uint256 openingFeeTreasuryAmount,
        uint256 cfgIporPublicationFee
    ) internal {
        _balances.totalCollateralPayFixed =
            _balances.totalCollateralPayFixed +
            collateral.toUint128();

        _balances.iporPublicationFee =
            _balances.iporPublicationFee +
            cfgIporPublicationFee.toUint128();

        _balances.liquidityPool = _balances.liquidityPool + openingFeeLPAmount.toUint128();
        _balances.treasury = _balances.treasury + openingFeeTreasuryAmount.toUint128();
    }

    function _updateBalancesWhenOpenSwapReceiveFixed(
        uint256 collateral,
        uint256 openingFeeLPAmount,
        uint256 openingFeeTreasuryAmount,
        uint256 cfgIporPublicationFee
    ) internal {
        _balances.totalCollateralReceiveFixed =
            _balances.totalCollateralReceiveFixed +
            collateral.toUint128();

        _balances.iporPublicationFee =
            _balances.iporPublicationFee +
            cfgIporPublicationFee.toUint128();

        _balances.liquidityPool = _balances.liquidityPool + openingFeeLPAmount.toUint128();
        _balances.treasury = _balances.treasury + openingFeeTreasuryAmount.toUint128();
    }

    function _updateBalancesWhenCloseSwapPayFixed(
        address liquidator,
        IporTypes.IporSwapMemory memory swap,
        int256 payoff,
        uint256 closingTimestamp,
        uint256 cfgIncomeFeeRate,
        uint256 cfgMinLiquidationThresholdToCloseBeforeMaturity,
        uint256 cfgSecondsBeforeMaturityWhenPositionCanBeClosed
    ) internal {
        _updateBalancesWhenCloseSwap(
            liquidator,
            swap,
            payoff,
            closingTimestamp,
            cfgIncomeFeeRate,
            cfgMinLiquidationThresholdToCloseBeforeMaturity,
            cfgSecondsBeforeMaturityWhenPositionCanBeClosed
        );

        _balances.totalCollateralPayFixed =
            _balances.totalCollateralPayFixed -
            swap.collateral.toUint128();
    }

    function _updateBalancesWhenCloseSwapReceiveFixed(
        address liquidator,
        IporTypes.IporSwapMemory memory swap,
        int256 payoff,
        uint256 closingTimestamp,
        uint256 cfgIncomeFeeRate,
        uint256 cfgMinLiquidationThresholdToCloseBeforeMaturity,
        uint256 cfgSecondsBeforeMaturityWhenPositionCanBeClosed
    ) internal {
        _updateBalancesWhenCloseSwap(
            liquidator,
            swap,
            payoff,
            closingTimestamp,
            cfgIncomeFeeRate,
            cfgMinLiquidationThresholdToCloseBeforeMaturity,
            cfgSecondsBeforeMaturityWhenPositionCanBeClosed
        );

        _balances.totalCollateralReceiveFixed =
            _balances.totalCollateralReceiveFixed -
            swap.collateral.toUint128();
    }

    function _updateBalancesWhenCloseSwap(
        address liquidator,
        IporTypes.IporSwapMemory memory swap,
        int256 payoff,
        uint256 closingTimestamp,
        uint256 cfgIncomeFeeRate,
        uint256 cfgMinLiquidationThresholdToCloseBeforeMaturity,
        uint256 cfgSecondsBeforeMaturityWhenPositionCanBeClosed
    ) internal {
        uint256 absPayoff = IporMath.absoluteValue(payoff);
        uint256 minPayoffToCloseBeforeMaturity = IporMath.percentOf(
            swap.collateral,
            cfgMinLiquidationThresholdToCloseBeforeMaturity
        );
        if (absPayoff < minPayoffToCloseBeforeMaturity) {
            //verify if sender is an owner of swap if not then check if maturity - if not then reject,
            //if yes then close even if not an owner
            if (liquidator != swap.buyer) {
                require(
                    closingTimestamp >=
                        swap.endTimestamp - cfgSecondsBeforeMaturityWhenPositionCanBeClosed,
                    MiltonErrors.CANNOT_CLOSE_SWAP_SENDER_IS_NOT_BUYER_AND_NO_MATURITY
                );
            }
        }

        uint256 incomeFee = IporMath.division(absPayoff * cfgIncomeFeeRate, Constants.D18);

        _balances.treasury = _balances.treasury + incomeFee.toUint128();

        if (payoff > 0) {
            require(
                _balances.liquidityPool >= absPayoff,
                MiltonErrors.CANNOT_CLOSE_SWAP_LP_IS_TOO_LOW
            );

            _balances.liquidityPool = _balances.liquidityPool - absPayoff.toUint128();
        } else {
            _balances.liquidityPool = _balances.liquidityPool + (absPayoff - incomeFee).toUint128();
        }
    }

    function _updateSwapsWhenOpenPayFixed(AmmTypes.NewSwap memory newSwap)
        internal
        returns (uint256)
    {
        _lastSwapId++;
        uint32 id = _lastSwapId;

        AmmMiltonStorageTypes.IporSwap storage swap = _swapsPayFixed.swaps[id];

        swap.id = id;
        swap.buyer = newSwap.buyer;
        swap.openTimestamp = newSwap.openTimestamp.toUint32();
        swap.idsIndex = _swapsPayFixed.ids[newSwap.buyer].length.toUint32();
        swap.collateral = newSwap.collateral.toUint128();
        swap.notional = newSwap.notional.toUint128();
        swap.ibtQuantity = newSwap.ibtQuantity.toUint128();
        swap.fixedInterestRate = newSwap.fixedInterestRate.toUint64();
        swap.liquidationDepositAmount = newSwap.liquidationDepositAmount.toUint32();
        swap.state = AmmTypes.SwapState.ACTIVE;

        _swapsPayFixed.ids[newSwap.buyer].push(id);
        _lastSwapId = id;

        return id;
    }

    function _updateSwapsWhenOpenReceiveFixed(AmmTypes.NewSwap memory newSwap)
        internal
        returns (uint256)
    {
        _lastSwapId++;
        uint32 id = _lastSwapId;

        AmmMiltonStorageTypes.IporSwap storage swap = _swapsReceiveFixed.swaps[id];

        swap.id = id;
        swap.buyer = newSwap.buyer;
        swap.openTimestamp = newSwap.openTimestamp.toUint32();
        swap.idsIndex = _swapsReceiveFixed.ids[newSwap.buyer].length.toUint32();
        swap.collateral = newSwap.collateral.toUint128();
        swap.notional = newSwap.notional.toUint128();
        swap.ibtQuantity = newSwap.ibtQuantity.toUint128();
        swap.fixedInterestRate = newSwap.fixedInterestRate.toUint64();
        swap.liquidationDepositAmount = newSwap.liquidationDepositAmount.toUint32();
        swap.state = AmmTypes.SwapState.ACTIVE;

        _swapsReceiveFixed.ids[newSwap.buyer].push(id);
        _lastSwapId = id;

        return id;
    }

    function _updateSwapsWhenClosePayFixed(IporTypes.IporSwapMemory memory iporSwap) internal {
        require(iporSwap.id != 0, MiltonErrors.INCORRECT_SWAP_ID);
        require(
            iporSwap.state != uint256(AmmTypes.SwapState.INACTIVE),
            MiltonErrors.INCORRECT_SWAP_STATUS
        );

        uint32 idsIndexToDelete = iporSwap.idsIndex.toUint32();
        address buyer = iporSwap.buyer;
        uint256 idsLength = _swapsPayFixed.ids[buyer].length - 1;
        if (idsIndexToDelete < idsLength) {
            uint32 accountDerivativeIdToMove = _swapsPayFixed.ids[buyer][idsLength];

            _swapsPayFixed.swaps[accountDerivativeIdToMove].idsIndex = idsIndexToDelete;

            _swapsPayFixed.ids[buyer][idsIndexToDelete] = accountDerivativeIdToMove;
        }

        _swapsPayFixed.swaps[iporSwap.id.toUint32()].state = AmmTypes.SwapState.INACTIVE;
        _swapsPayFixed.ids[buyer].pop();
    }

    function _updateSwapsWhenCloseReceiveFixed(IporTypes.IporSwapMemory memory iporSwap) internal {
        require(iporSwap.id != 0, MiltonErrors.INCORRECT_SWAP_ID);
        require(
            iporSwap.state != uint256(AmmTypes.SwapState.INACTIVE),
            MiltonErrors.INCORRECT_SWAP_STATUS
        );

        uint32 idsIndexToDelete = iporSwap.idsIndex.toUint32();
        address buyer = iporSwap.buyer;
        uint256 idsLength = _swapsReceiveFixed.ids[buyer].length - 1;

        if (idsIndexToDelete < idsLength) {
            uint32 accountDerivativeIdToMove = _swapsReceiveFixed.ids[buyer][idsLength];

            _swapsReceiveFixed.swaps[accountDerivativeIdToMove].idsIndex = idsIndexToDelete;

            _swapsReceiveFixed.ids[buyer][idsIndexToDelete] = accountDerivativeIdToMove;
        }

        _swapsReceiveFixed.swaps[iporSwap.id.toUint32()].state = AmmTypes.SwapState.INACTIVE;
        _swapsReceiveFixed.ids[buyer].pop();
    }

    function _updateSoapIndicatorsWhenOpenSwapPayFixed(
        uint256 openTimestamp,
        uint256 notional,
        uint256 fixedInterestRate,
        uint256 ibtQuantity
    ) internal {
        AmmMiltonStorageTypes.SoapIndicatorsMemory memory pf = AmmMiltonStorageTypes
            .SoapIndicatorsMemory(
                _soapIndicatorsPayFixed.quasiHypotheticalInterestCumulative,
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
        _soapIndicatorsPayFixed.quasiHypotheticalInterestCumulative = pf
            .quasiHypotheticalInterestCumulative;
    }

    function _updateSoapIndicatorsWhenOpenSwapReceiveFixed(
        uint256 openTimestamp,
        uint256 notional,
        uint256 fixedInterestRate,
        uint256 ibtQuantity
    ) internal {
        AmmMiltonStorageTypes.SoapIndicatorsMemory memory rf = AmmMiltonStorageTypes
            .SoapIndicatorsMemory(
                _soapIndicatorsReceiveFixed.quasiHypotheticalInterestCumulative,
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
        _soapIndicatorsReceiveFixed.quasiHypotheticalInterestCumulative = rf
            .quasiHypotheticalInterestCumulative;
    }

    function _updateSoapIndicatorsWhenCloseSwapPayFixed(
        IporTypes.IporSwapMemory memory swap,
        uint256 closingTimestamp
    ) internal {
        AmmMiltonStorageTypes.SoapIndicatorsMemory memory pf = AmmMiltonStorageTypes
            .SoapIndicatorsMemory(
                _soapIndicatorsPayFixed.quasiHypotheticalInterestCumulative,
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

        _soapIndicatorsPayFixed = AmmMiltonStorageTypes.SoapIndicators(
            pf.quasiHypotheticalInterestCumulative,
            pf.totalNotional.toUint128(),
            pf.totalIbtQuantity.toUint128(),
            pf.averageInterestRate.toUint64(),
            pf.rebalanceTimestamp.toUint32()
        );
    }

    function _updateSoapIndicatorsWhenCloseSwapReceiveFixed(
        IporTypes.IporSwapMemory memory swap,
        uint256 closingTimestamp
    ) internal {
        AmmMiltonStorageTypes.SoapIndicatorsMemory memory rf = AmmMiltonStorageTypes
            .SoapIndicatorsMemory(
                _soapIndicatorsReceiveFixed.quasiHypotheticalInterestCumulative,
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

        _soapIndicatorsReceiveFixed = AmmMiltonStorageTypes.SoapIndicators(
            rf.quasiHypotheticalInterestCumulative,
            rf.totalNotional.toUint128(),
            rf.totalIbtQuantity.toUint128(),
            rf.averageInterestRate.toUint64(),
            rf.rebalanceTimestamp.toUint32()
        );
    }

    //solhint-disable no-empty-blocks
    function _authorizeUpgrade(address) internal override onlyOwner {}
}

contract MiltonStorageUsdt is MiltonStorage {}

contract MiltonStorageUsdc is MiltonStorage {}

contract MiltonStorageDai is MiltonStorage {}

// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.9;

import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts/utils/math/SafeCast.sol";
import "../security/IporOwnableUpgradeable.sol";
import {DataTypes} from "../libraries/types/DataTypes.sol";
import "../libraries/IporSwapLogic.sol";
import "../libraries/SoapIndicatorLogic.sol";
import "../interfaces/IMiltonStorage.sol";
import "../libraries/Constants.sol";
import "hardhat/console.sol";

//@dev all stored valuse related with money are in 18 decimals.
contract MiltonStorage is UUPSUpgradeable, IporOwnableUpgradeable, IMiltonStorage {
    //TODO: if possible move out libraries from MiltonStorage to Milton, use storage as clean storage smart contract
    using SafeCast for uint256;
    using SoapIndicatorLogic for DataTypes.SoapIndicatorMemory;

    uint64 private _lastSwapId;
    address private _milton;
    address private _joseph;

    DataTypes.MiltonBalanceStorage internal _balances;
    DataTypes.SoapIndicatorStorage internal _soapIndicatorsPayFixed;
    DataTypes.SoapIndicatorStorage internal _soapIndicatorsReceiveFixed;
    DataTypes.IporSwapContainer internal _swapsPayFixed;
    DataTypes.IporSwapContainer internal _swapsReceiveFixed;

    modifier onlyMilton() {
        require(msg.sender == _milton, IporErrors.CALLER_NOT_MILTON);
        _;
    }

    modifier onlyJoseph() {
        require(msg.sender == _joseph, IporErrors.MILTON_CALLER_NOT_JOSEPH);
        _;
    }

    function initialize() public initializer {
        __Ownable_init();
    }

    function getVersion() external pure override returns (uint256) {
        return 1;
    }

    function getLastSwapId() external view override returns (uint256) {
        return _lastSwapId;
    }

    function getBalance() external view override returns (DataTypes.MiltonBalanceMemory memory) {
        return
            DataTypes.MiltonBalanceMemory(
                _balances.payFixedSwaps,
                _balances.receiveFixedSwaps,
                _balances.liquidityPool,
                _balances.vault
            );
    }

    function getExtendedBalance()
        external
        view
        override
        returns (DataTypes.MiltonExtendedBalanceMemory memory)
    {
        return
            DataTypes.MiltonExtendedBalanceMemory(
                _balances.payFixedSwaps,
                _balances.receiveFixedSwaps,
                _balances.liquidityPool,
                _balances.vault,
                _balances.openingFee,
                _balances.liquidationDeposit,
                _balances.iporPublicationFee,
                _balances.treasury
            );
    }

    function getTotalOutstandingNotional()
        external
        view
        override
        returns (uint256 payFixedTotalNotional, uint256 recFixedTotalNotional)
    {
        payFixedTotalNotional = _soapIndicatorsPayFixed.totalNotional;
        recFixedTotalNotional = _soapIndicatorsReceiveFixed.totalNotional;
    }

    function getSwapPayFixed(uint256 swapId)
        external
        view
        override
        returns (DataTypes.IporSwapMemory memory)
    {
        uint64 id = swapId.toUint64();
        DataTypes.IporSwap storage swap = _swapsPayFixed.swaps[id];
        return
            DataTypes.IporSwapMemory(
                uint256(swap.state),
                swap.buyer,
                swap.startingTimestamp,
                swap.startingTimestamp + Constants.SWAP_DEFAULT_PERIOD_IN_SECONDS,
                swap.id,
                swap.idsIndex,
                swap.collateral,
                swap.liquidationDepositAmount,
                swap.notionalAmount,
                swap.fixedInterestRate,
                swap.ibtQuantity
            );
    }

    function getSwapReceiveFixed(uint256 swapId)
        external
        view
        override
        returns (DataTypes.IporSwapMemory memory)
    {
        uint64 id = swapId.toUint64();
        DataTypes.IporSwap storage swap = _swapsReceiveFixed.swaps[id];
        return
            DataTypes.IporSwapMemory(
                uint256(swap.state),
                swap.buyer,
                swap.startingTimestamp,
                swap.startingTimestamp + Constants.SWAP_DEFAULT_PERIOD_IN_SECONDS,
                swap.id,
                swap.idsIndex,
                swap.collateral,
                swap.liquidationDepositAmount,
                swap.notionalAmount,
                swap.fixedInterestRate,
                swap.ibtQuantity
            );
    }

    function getSwapsPayFixed(address account)
        external
        view
        override
        returns (DataTypes.IporSwapMemory[] memory)
    {
        return _getPositions(_swapsPayFixed.swaps, _swapsPayFixed.ids[account]);
    }

    function getSwapsReceiveFixed(address account)
        external
        view
        override
        returns (DataTypes.IporSwapMemory[] memory)
    {
        return _getPositions(_swapsReceiveFixed.swaps, _swapsReceiveFixed.ids[account]);
    }

    function getSwapPayFixedIds(address account) external view override returns (uint128[] memory) {
        return _swapsPayFixed.ids[account];
    }

    function getSwapReceiveFixedIds(address account)
        external
        view
        override
        returns (uint128[] memory)
    {
        return _swapsReceiveFixed.ids[account];
    }

    //TODO: separate soap to MiltonSoapModel smart contract
    function calculateSoap(uint256 ibtPrice, uint256 calculateTimestamp)
        external
        view
        override
        returns (
            int256 soapPf,
            int256 soapRf,
            int256 soap
        )
    {
        (int256 qSoapPf, int256 qSoapRf, int256 qSoap) = _calculateQuasiSoap(
            ibtPrice,
            calculateTimestamp
        );

        return (
            soapPf = IporMath.divisionInt(qSoapPf, Constants.WAD_P2_YEAR_IN_SECONDS_INT),
            soapRf = IporMath.divisionInt(qSoapRf, Constants.WAD_P2_YEAR_IN_SECONDS_INT),
            soap = IporMath.divisionInt(qSoap, Constants.WAD_P2_YEAR_IN_SECONDS_INT)
        );
    }

    function calculateSoapPayFixed(uint256 ibtPrice, uint256 calculateTimestamp)
        external
        view
        override
        returns (int256 soapPf)
    {
        int256 qSoapPf = _calculateQuasiSoapPayFixed(ibtPrice, calculateTimestamp);

        soapPf = IporMath.divisionInt(qSoapPf, Constants.WAD_P2_YEAR_IN_SECONDS_INT);
    }

    function calculateSoapReceiveFixed(uint256 ibtPrice, uint256 calculateTimestamp)
        external
        view
        override
        returns (int256 soapRf)
    {
        int256 qSoapRf = _calculateQuasiSoapReceiveFixed(ibtPrice, calculateTimestamp);

        soapRf = IporMath.divisionInt(qSoapRf, Constants.WAD_P2_YEAR_IN_SECONDS_INT);
    }

    function addLiquidity(uint256 liquidityAmount) external override onlyJoseph {
        require(liquidityAmount != 0, IporErrors.MILTON_DEPOSIT_AMOUNT_TOO_LOW);
        _balances.liquidityPool = _balances.liquidityPool + liquidityAmount.toUint128();
    }

    function subtractLiquidity(uint256 liquidityAmount) external override onlyJoseph {
        _balances.liquidityPool = _balances.liquidityPool - liquidityAmount.toUint128();
    }

    function updateStorageWhenOpenSwapPayFixed(
        DataTypes.NewSwap memory newSwap,
        uint256 openingAmount,
        uint256 cfgLiquidationDepositAmount,
        uint256 cfgIporPublicationFeeAmount,
        uint256 cfgOpeningFeeForTreasuryPercentage
    ) external override onlyMilton returns (uint256) {
        uint256 id = _updateSwapsWhenOpenPayFixed(newSwap);
        _updateBalancesWhenOpenSwapPayFixed(
            newSwap.collateral,
            openingAmount,
            cfgLiquidationDepositAmount,
            cfgIporPublicationFeeAmount,
            cfgOpeningFeeForTreasuryPercentage
        );
        _updateSoapIndicatorsWhenOpenSwapPayFixed(newSwap);
        return id;
    }

    function updateStorageWhenOpenSwapReceiveFixed(
        DataTypes.NewSwap memory newSwap,
        uint256 openingAmount,
        uint256 cfgLiquidationDepositAmount,
        uint256 cfgIporPublicationFeeAmount,
        uint256 cfgOpeningFeeForTreasuryPercentage
    ) external override onlyMilton returns (uint256) {
        uint256 id = _updateSwapsWhenOpenReceiveFixed(newSwap);
        _updateBalancesWhenOpenSwapReceiveFixed(
            newSwap.collateral,
            openingAmount,
            cfgLiquidationDepositAmount,
            cfgIporPublicationFeeAmount,
            cfgOpeningFeeForTreasuryPercentage
        );
        _updateSoapIndicatorsWhenOpenSwapReceiveFixed(newSwap);
        return id;
    }

    function updateStorageWhenCloseSwapPayFixed(
        address account,
        DataTypes.IporSwapMemory memory iporSwap,
        int256 positionValue,
        uint256 closingTimestamp,
        uint256 cfgIncomeTaxPercentage
    ) external override onlyMilton {
        _updateSwapsWhenClosePayFixed(iporSwap);
        _updateBalancesWhenCloseSwapPayFixed(
            account,
            iporSwap,
            positionValue,
            closingTimestamp,
            cfgIncomeTaxPercentage
        );
        _updateSoapIndicatorsWhenCloseSwapPayFixed(iporSwap, closingTimestamp);
    }

    function updateStorageWhenCloseSwapReceiveFixed(
        address account,
        DataTypes.IporSwapMemory memory iporSwap,
        int256 positionValue,
        uint256 closingTimestamp,
        uint256 cfgIncomeTaxPercentage
    ) external override onlyMilton {
        _updateSwapsWhenCloseReceiveFixed(iporSwap);
        _updateBalancesWhenCloseSwapReceiveFixed(
            account,
            iporSwap,
            positionValue,
            closingTimestamp,
            cfgIncomeTaxPercentage
        );
        _updateSoapIndicatorsWhenCloseSwapReceiveFixed(iporSwap, closingTimestamp);
    }

    function updateStorageWhenWithdrawFromStanley(uint256 withdrawnValue, uint256 vaultBalance)
        external
        override
        onlyMilton
    {
        uint256 currentVaultBalance = _balances.vault;
        uint256 interest = vaultBalance + withdrawnValue - currentVaultBalance;
        uint256 liquidityPoolBalance = _balances.liquidityPool + interest;
        _balances.liquidityPool = liquidityPoolBalance.toUint128();
        _balances.vault = vaultBalance.toUint128();
    }

    function updateStorageWhenDepositToStanley(uint256 depositValue, uint256 vaultBalance)
        external
        override
        onlyMilton
    {
        uint256 currentVaultBalance = _balances.vault;
        require(
            currentVaultBalance <= (vaultBalance - depositValue),
            IporErrors.MILTON_IPOR_VAULT_BALANCE_TOO_LOW
        );
        uint256 interest = currentVaultBalance != 0
            ? (vaultBalance - currentVaultBalance - depositValue)
            : 0;
        _balances.vault = vaultBalance.toUint128();
        uint256 liquidityPoolBalance = _balances.liquidityPool + interest;
        _balances.liquidityPool = liquidityPoolBalance.toUint128();
    }

    function updateStorageWhenTransferPublicationFee(uint256 transferedValue)
        external
        override
        onlyJoseph
    {
        require(transferedValue != 0, IporErrors.NOT_ENOUGH_AMOUNT_TO_TRANSFER);

        uint256 balance = _balances.iporPublicationFee;

        require(transferedValue <= balance, IporErrors.MILTON_PUBLICATION_FEE_BALANCE_TOO_LOW);

        balance = balance - transferedValue;

        _balances.iporPublicationFee = balance.toUint128();
    }

    function updateStorageWhenTransferTreasure(uint256 transferedValue)
        external
        override
        onlyJoseph
    {
        require(transferedValue != 0, IporErrors.NOT_ENOUGH_AMOUNT_TO_TRANSFER);

        uint256 balance = _balances.treasury;

        require(transferedValue <= balance, IporErrors.MILTON_TREASURE_BALANCE_TOO_LOW);

        balance = balance - transferedValue;

        _balances.treasury = balance.toUint128();
    }

    function setMilton(address milton) external override onlyOwner {
        _milton = milton;
    }

    function setJoseph(address joseph) external override onlyOwner {
        _joseph = joseph;
    }

    function _getPositions(
        mapping(uint128 => DataTypes.IporSwap) storage swaps,
        uint128[] storage ids
    ) internal view returns (DataTypes.IporSwapMemory[] memory) {
        uint256 swapsIdsLength = ids.length;
        DataTypes.IporSwapMemory[] memory derivatives = new DataTypes.IporSwapMemory[](
            swapsIdsLength
        );
        uint256 i = 0;

        for (i; i != swapsIdsLength; i++) {
            uint128 id = ids[i];
            DataTypes.IporSwap storage swap = swaps[id];
            derivatives[i] = DataTypes.IporSwapMemory(
                uint256(swaps[id].state),
                swap.buyer,
                swap.startingTimestamp,
                swap.startingTimestamp + Constants.SWAP_DEFAULT_PERIOD_IN_SECONDS,
                swap.id,
                swap.idsIndex,
                swap.collateral,
                swap.liquidationDepositAmount,
                swap.notionalAmount,
                swap.fixedInterestRate,
                swap.ibtQuantity
            );
        }
        return derivatives;
    }

    function _calculateQuasiSoap(uint256 ibtPrice, uint256 calculateTimestamp)
        internal
        view
        returns (
            int256 soapPf,
            int256 soapRf,
            int256 soap
        )
    {
        DataTypes.SoapIndicatorMemory memory spf = DataTypes.SoapIndicatorMemory(
            _soapIndicatorsPayFixed.rebalanceTimestamp,
            _soapIndicatorsPayFixed.totalNotional,
            _soapIndicatorsPayFixed.averageInterestRate,
            _soapIndicatorsPayFixed.totalIbtQuantity,
            _soapIndicatorsPayFixed.quasiHypotheticalInterestCumulative
        );
        int256 _soapPf = spf.calculateQuasiSoapPayFixed(calculateTimestamp, ibtPrice);

        DataTypes.SoapIndicatorMemory memory srf = DataTypes.SoapIndicatorMemory(
            _soapIndicatorsReceiveFixed.rebalanceTimestamp,
            _soapIndicatorsReceiveFixed.totalNotional,
            _soapIndicatorsReceiveFixed.averageInterestRate,
            _soapIndicatorsReceiveFixed.totalIbtQuantity,
            _soapIndicatorsReceiveFixed.quasiHypotheticalInterestCumulative
        );
        int256 _soapRf = srf.calculateQuasiSoapReceiveFixed(calculateTimestamp, ibtPrice);
        return (soapPf = _soapPf, soapRf = _soapRf, soap = _soapPf + _soapRf);
    }

    function _calculateQuasiSoapPayFixed(uint256 ibtPrice, uint256 calculateTimestamp)
        internal
        view
        returns (int256 soapPf)
    {
        DataTypes.SoapIndicatorMemory memory spf = DataTypes.SoapIndicatorMemory(
            _soapIndicatorsPayFixed.rebalanceTimestamp,
            _soapIndicatorsPayFixed.totalNotional,
            _soapIndicatorsPayFixed.averageInterestRate,
            _soapIndicatorsPayFixed.totalIbtQuantity,
            _soapIndicatorsPayFixed.quasiHypotheticalInterestCumulative
        );
        soapPf = spf.calculateQuasiSoapPayFixed(calculateTimestamp, ibtPrice);
    }

    function _calculateQuasiSoapReceiveFixed(uint256 ibtPrice, uint256 calculateTimestamp)
        internal
        view
        returns (int256 soapRf)
    {
        DataTypes.SoapIndicatorMemory memory srf = DataTypes.SoapIndicatorMemory(
            _soapIndicatorsReceiveFixed.rebalanceTimestamp,
            _soapIndicatorsReceiveFixed.totalNotional,
            _soapIndicatorsReceiveFixed.averageInterestRate,
            _soapIndicatorsReceiveFixed.totalIbtQuantity,
            _soapIndicatorsReceiveFixed.quasiHypotheticalInterestCumulative
        );
        soapRf = srf.calculateQuasiSoapReceiveFixed(calculateTimestamp, ibtPrice);
    }

    function _updateBalancesWhenOpenSwapPayFixed(
        uint256 collateral,
        uint256 openingFeeAmount,
        uint256 cfgLiquidationDepositAmount,
        uint256 cfgIporPublicationFeeAmount,
        uint256 cfgOpeningFeeForTreasuryPercentage
    ) internal {
        _balances.payFixedSwaps = _balances.payFixedSwaps + collateral.toUint128();

        _balances.openingFee = _balances.openingFee + openingFeeAmount.toUint128();
        _balances.liquidationDeposit =
            _balances.liquidationDeposit +
            cfgLiquidationDepositAmount.toUint128();
        _balances.iporPublicationFee =
            _balances.iporPublicationFee +
            cfgIporPublicationFeeAmount.toUint128();

        (uint256 openingFeeLPValue, uint256 openingFeeTreasuryValue) = _splitOpeningFeeAmount(
            openingFeeAmount,
            cfgOpeningFeeForTreasuryPercentage
        );
        _balances.liquidityPool = _balances.liquidityPool + openingFeeLPValue.toUint128();
        _balances.treasury = _balances.treasury + openingFeeTreasuryValue.toUint128();
    }

    function _updateBalancesWhenOpenSwapReceiveFixed(
        uint256 collateral,
        uint256 openingFeeAmount,
        uint256 cfgLiquidationDepositAmount,
        uint256 cfgIporPublicationFeeAmount,
        uint256 cfgOpeningFeeForTreasuryPercentage
    ) internal {
        _balances.receiveFixedSwaps = _balances.receiveFixedSwaps + collateral.toUint128();

        _balances.openingFee = _balances.openingFee + openingFeeAmount.toUint128();
        _balances.liquidationDeposit =
            _balances.liquidationDeposit +
            cfgLiquidationDepositAmount.toUint128();
        _balances.iporPublicationFee =
            _balances.iporPublicationFee +
            cfgIporPublicationFeeAmount.toUint128();

        (uint256 openingFeeLPValue, uint256 openingFeeTreasuryValue) = _splitOpeningFeeAmount(
            openingFeeAmount,
            cfgOpeningFeeForTreasuryPercentage
        );
        _balances.liquidityPool = _balances.liquidityPool + openingFeeLPValue.toUint128();
        _balances.treasury = _balances.treasury + openingFeeTreasuryValue.toUint128();
    }

    function _splitOpeningFeeAmount(
        uint256 openingFeeAmount,
        uint256 openingFeeForTreasurePercentage
    ) internal pure returns (uint256 liquidityPoolValue, uint256 treasuryValue) {
        treasuryValue = IporMath.division(
            openingFeeAmount * openingFeeForTreasurePercentage,
            Constants.D18
        );
        liquidityPoolValue = openingFeeAmount - treasuryValue;
    }

    function _updateBalancesWhenCloseSwapPayFixed(
        address account,
        DataTypes.IporSwapMemory memory swap,
        int256 positionValue,
        uint256 closingTimestamp,
        uint256 cfgIncomeTaxPercentage
    ) internal {
        _updateBalancesWhenCloseSwap(
            account,
            swap,
            positionValue,
            closingTimestamp,
            cfgIncomeTaxPercentage
        );

        _balances.payFixedSwaps = _balances.payFixedSwaps - swap.collateral.toUint128();
    }

    function _updateBalancesWhenCloseSwapReceiveFixed(
        address account,
        DataTypes.IporSwapMemory memory swap,
        int256 positionValue,
        uint256 closingTimestamp,
        uint256 cfgIncomeTaxPercentage
    ) internal {
        _updateBalancesWhenCloseSwap(
            account,
            swap,
            positionValue,
            closingTimestamp,
            cfgIncomeTaxPercentage
        );

        _balances.receiveFixedSwaps = _balances.receiveFixedSwaps - swap.collateral.toUint128();
    }

    function _updateBalancesWhenCloseSwap(
        address account,
        DataTypes.IporSwapMemory memory swap,
        int256 positionValue,
        uint256 closingTimestamp,
        uint256 cfgIncomeTaxPercentage
    ) internal {
        //decrease from balances the liquidation deposit
        require(
            _balances.liquidationDeposit >= swap.liquidationDepositAmount,
            IporErrors.MILTON_CANNOT_CLOSE_SWAP_LIQUIDATION_DEPOSIT_BALANCE_IS_TOO_LOW
        );

        uint256 absPositionValue = IporMath.absoluteValue(positionValue);

        if (absPositionValue < swap.collateral) {
            //verify if sender is an owner of swap if not then check if maturity - if not then reject,
            //if yes then close even if not an owner
            if (account != swap.buyer) {
                require(
                    closingTimestamp >= swap.endingTimestamp,
                    IporErrors.MILTON_CANNOT_CLOSE_SWAP_SENDER_IS_NOT_BUYER_AND_NO_MATURITY
                );
            }
        }

        uint256 incomeTax = IporMath.division(
            absPositionValue * cfgIncomeTaxPercentage,
            Constants.D18
        );

        _balances.liquidationDeposit =
            _balances.liquidationDeposit -
            swap.liquidationDepositAmount.toUint128();

        _balances.treasury = _balances.treasury + incomeTax.toUint128();

        if (positionValue > 0) {
            require(
                _balances.liquidityPool >= absPositionValue,
                IporErrors.MILTON_CANNOT_CLOSE_SWAP_LP_IS_TOO_LOW
            );

            _balances.liquidityPool = _balances.liquidityPool - absPositionValue.toUint128();
        } else {
            _balances.liquidityPool =
                _balances.liquidityPool +
                (absPositionValue - incomeTax).toUint128();
        }
    }

    function _updateSwapsWhenOpenPayFixed(DataTypes.NewSwap memory newSwap)
        internal
        returns (uint256)
    {
        _lastSwapId++;
        uint64 id = _lastSwapId;

        DataTypes.IporSwap storage swap = _swapsPayFixed.swaps[id];

        swap.state = DataTypes.SwapState.ACTIVE;
        swap.buyer = newSwap.buyer;
        swap.startingTimestamp = newSwap.startingTimestamp.toUint32();

        swap.id = id;
        swap.collateral = newSwap.collateral.toUint128();
        swap.liquidationDepositAmount = newSwap.liquidationDepositAmount.toUint128();
        swap.notionalAmount = newSwap.notionalAmount.toUint128();
        swap.fixedInterestRate = newSwap.fixedInterestRate.toUint128();
        swap.ibtQuantity = newSwap.ibtQuantity.toUint128();

        swap.idsIndex = _swapsPayFixed.ids[newSwap.buyer].length.toUint64();
        _swapsPayFixed.ids[newSwap.buyer].push(id);
        _lastSwapId = id;

        return id;
    }

    function _updateSwapsWhenOpenReceiveFixed(DataTypes.NewSwap memory newSwap)
        internal
        returns (uint256)
    {
        _lastSwapId++;
        uint64 id = _lastSwapId;

        DataTypes.IporSwap storage swap = _swapsReceiveFixed.swaps[id];

        swap.state = DataTypes.SwapState.ACTIVE;
        swap.buyer = newSwap.buyer;
        swap.startingTimestamp = newSwap.startingTimestamp.toUint32();

        swap.id = id;
        swap.collateral = newSwap.collateral.toUint128();
        swap.liquidationDepositAmount = newSwap.liquidationDepositAmount.toUint128();
        swap.notionalAmount = newSwap.notionalAmount.toUint128();
        swap.fixedInterestRate = newSwap.fixedInterestRate.toUint128();
        swap.ibtQuantity = newSwap.ibtQuantity.toUint128();

        swap.idsIndex = _swapsReceiveFixed.ids[newSwap.buyer].length.toUint64();
        _swapsReceiveFixed.ids[newSwap.buyer].push(id);
        _lastSwapId = id;

        return id;
    }

    function _updateSwapsWhenClosePayFixed(DataTypes.IporSwapMemory memory iporSwap) internal {
        require(iporSwap.id != 0, IporErrors.MILTON_INCORRECT_SWAP_ID);
        require(
            iporSwap.state != uint256(DataTypes.SwapState.INACTIVE),
            IporErrors.MILTON_INCORRECT_SWAP_STATUS
        );

        uint64 idsIndexToDelete = iporSwap.idsIndex.toUint64();
        address buyer = iporSwap.buyer;
        uint256 idsLength = _swapsPayFixed.ids[buyer].length - 1;
        if (idsIndexToDelete < idsLength) {
            uint128 accountDerivativeIdToMove = _swapsPayFixed.ids[buyer][idsLength];

            _swapsPayFixed.swaps[accountDerivativeIdToMove].idsIndex = idsIndexToDelete;

            _swapsPayFixed.ids[buyer][idsIndexToDelete] = accountDerivativeIdToMove;
        }

        _swapsPayFixed.swaps[iporSwap.id.toUint64()].state = DataTypes.SwapState.INACTIVE;
        _swapsPayFixed.ids[buyer].pop();
    }

    function _updateSwapsWhenCloseReceiveFixed(DataTypes.IporSwapMemory memory iporSwap) internal {
        require(iporSwap.id != 0, IporErrors.MILTON_INCORRECT_SWAP_ID);
        require(
            iporSwap.state != uint256(DataTypes.SwapState.INACTIVE),
            IporErrors.MILTON_INCORRECT_SWAP_STATUS
        );

        uint64 idsIndexToDelete = iporSwap.idsIndex.toUint64();
        address buyer = iporSwap.buyer;
        uint256 idsLength = _swapsReceiveFixed.ids[buyer].length - 1;

        if (idsIndexToDelete < idsLength) {
            uint128 accountDerivativeIdToMove = _swapsReceiveFixed.ids[buyer][idsLength];

            _swapsReceiveFixed.swaps[accountDerivativeIdToMove].idsIndex = idsIndexToDelete;

            _swapsReceiveFixed.ids[buyer][idsIndexToDelete] = accountDerivativeIdToMove;
        }

        _swapsReceiveFixed.swaps[iporSwap.id.toUint64()].state = DataTypes.SwapState.INACTIVE;
        _swapsReceiveFixed.ids[buyer].pop();
    }

    function _updateSoapIndicatorsWhenOpenSwapPayFixed(DataTypes.NewSwap memory newSwap) internal {
        DataTypes.SoapIndicatorMemory memory pf = DataTypes.SoapIndicatorMemory(
            _soapIndicatorsPayFixed.rebalanceTimestamp,
            _soapIndicatorsPayFixed.totalNotional,
            _soapIndicatorsPayFixed.averageInterestRate,
            _soapIndicatorsPayFixed.totalIbtQuantity,
            _soapIndicatorsPayFixed.quasiHypotheticalInterestCumulative
        );
        pf.rebalanceWhenOpenSwap(
            newSwap.startingTimestamp,
            newSwap.notionalAmount,
            newSwap.fixedInterestRate,
            newSwap.ibtQuantity
        );
        _soapIndicatorsPayFixed.rebalanceTimestamp = pf.rebalanceTimestamp.toUint32();
        _soapIndicatorsPayFixed.totalNotional = pf.totalNotional.toUint128();
        _soapIndicatorsPayFixed.averageInterestRate = pf.averageInterestRate.toUint128();
        _soapIndicatorsPayFixed.totalIbtQuantity = pf.totalIbtQuantity.toUint128();
        _soapIndicatorsPayFixed.quasiHypotheticalInterestCumulative = pf
            .quasiHypotheticalInterestCumulative;
    }

    function _updateSoapIndicatorsWhenOpenSwapReceiveFixed(DataTypes.NewSwap memory newSwap)
        internal
    {
        DataTypes.SoapIndicatorMemory memory rf = DataTypes.SoapIndicatorMemory(
            _soapIndicatorsReceiveFixed.rebalanceTimestamp,
            _soapIndicatorsReceiveFixed.totalNotional,
            _soapIndicatorsReceiveFixed.averageInterestRate,
            _soapIndicatorsReceiveFixed.totalIbtQuantity,
            _soapIndicatorsReceiveFixed.quasiHypotheticalInterestCumulative
        );
        rf.rebalanceWhenOpenSwap(
            newSwap.startingTimestamp,
            newSwap.notionalAmount,
            newSwap.fixedInterestRate,
            newSwap.ibtQuantity
        );

        _soapIndicatorsReceiveFixed.rebalanceTimestamp = rf.rebalanceTimestamp.toUint32();
        _soapIndicatorsReceiveFixed.totalNotional = rf.totalNotional.toUint128();
        _soapIndicatorsReceiveFixed.averageInterestRate = rf.averageInterestRate.toUint128();
        _soapIndicatorsReceiveFixed.totalIbtQuantity = rf.totalIbtQuantity.toUint128();
        _soapIndicatorsReceiveFixed.quasiHypotheticalInterestCumulative = rf
            .quasiHypotheticalInterestCumulative;
    }

    function _updateSoapIndicatorsWhenCloseSwapPayFixed(
        DataTypes.IporSwapMemory memory swap,
        uint256 closingTimestamp
    ) internal {
        DataTypes.SoapIndicatorMemory memory pf = DataTypes.SoapIndicatorMemory(
            _soapIndicatorsPayFixed.rebalanceTimestamp,
            _soapIndicatorsPayFixed.totalNotional,
            _soapIndicatorsPayFixed.averageInterestRate,
            _soapIndicatorsPayFixed.totalIbtQuantity,
            _soapIndicatorsPayFixed.quasiHypotheticalInterestCumulative
        );

        pf.rebalanceWhenCloseSwap(
            closingTimestamp,
            swap.startingTimestamp,
            swap.notionalAmount,
            swap.fixedInterestRate,
            swap.ibtQuantity
        );

        _soapIndicatorsPayFixed = DataTypes.SoapIndicatorStorage(
            pf.rebalanceTimestamp.toUint32(),
            pf.totalNotional.toUint128(),
            pf.averageInterestRate.toUint128(),
            pf.totalIbtQuantity.toUint128(),
            pf.quasiHypotheticalInterestCumulative
        );
    }

    function _updateSoapIndicatorsWhenCloseSwapReceiveFixed(
        DataTypes.IporSwapMemory memory swap,
        uint256 closingTimestamp
    ) internal {
        DataTypes.SoapIndicatorMemory memory rf = DataTypes.SoapIndicatorMemory(
            _soapIndicatorsReceiveFixed.rebalanceTimestamp,
            _soapIndicatorsReceiveFixed.totalNotional,
            _soapIndicatorsReceiveFixed.averageInterestRate,
            _soapIndicatorsReceiveFixed.totalIbtQuantity,
            _soapIndicatorsReceiveFixed.quasiHypotheticalInterestCumulative
        );

        rf.rebalanceWhenCloseSwap(
            closingTimestamp,
            swap.startingTimestamp,
            swap.notionalAmount,
            swap.fixedInterestRate,
            swap.ibtQuantity
        );

        _soapIndicatorsReceiveFixed = DataTypes.SoapIndicatorStorage(
            rf.rebalanceTimestamp.toUint32(),
            rf.totalNotional.toUint128(),
            rf.averageInterestRate.toUint128(),
            rf.totalIbtQuantity.toUint128(),
            rf.quasiHypotheticalInterestCumulative
        );
    }

    function _authorizeUpgrade(address) internal override onlyOwner {}
}

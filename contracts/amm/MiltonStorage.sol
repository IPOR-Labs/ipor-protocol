// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";
import {DataTypes} from "../libraries/types/DataTypes.sol";
import "../libraries/IporSwapLogic.sol";
import "../libraries/SoapIndicatorLogic.sol";
import "../interfaces/IIporConfiguration.sol";
import "../libraries/types/DataTypes.sol";
import "../interfaces/IMiltonStorage.sol";
import "../interfaces/IIporAssetConfiguration.sol";
import "../libraries/Constants.sol";

contract MiltonStorage is Ownable, IMiltonStorage {
    //TODO: if possible move out libraries from MiltonStorage to Milton, use storage as clean storage smart contract
    using IporSwapLogic for DataTypes.IporSwapMemory;
    using SoapIndicatorLogic for DataTypes.SoapIndicatorMemory;

    uint64 private _lastSwapId;
    address private _asset;
    IIporConfiguration internal _iporConfiguration;
    IIporAssetConfiguration internal _iporAssetConfiguration;
    DataTypes.MiltonTotalBalanceStorage internal _balances;
    DataTypes.SoapIndicatorStorage internal _soapIndicatorsPayFixed;
    DataTypes.SoapIndicatorStorage internal _soapIndicatorsReceiveFixed;
    DataTypes.IporSwapContainer internal _swapsPayFixed;
    DataTypes.IporSwapContainer internal _swapsReceiveFixed;

    constructor(address asset, address initialIporConfiguration) {
        require(address(asset) != address(0), IporErrors.WRONG_ADDRESS);
        require(
            address(initialIporConfiguration) != address(0),
            IporErrors.INCORRECT_IPOR_CONFIGURATION_ADDRESS
        );
        _iporConfiguration = IIporConfiguration(initialIporConfiguration);

        require(
            _iporConfiguration.assetSupported(asset) == 1,
            IporErrors.MILTON_ASSET_ADDRESS_NOT_SUPPORTED
        );

        _asset = asset;

        _iporAssetConfiguration = IIporAssetConfiguration(
            _iporConfiguration.getIporAssetConfiguration(asset)
        );
    }

    function getBalance()
        external
        view
        override
        returns (DataTypes.MiltonTotalBalanceMemory memory)
    {
        return
            DataTypes.MiltonTotalBalanceMemory(
                uint256(_balances.payFixedDerivatives),
                uint256(_balances.recFixedDerivatives),
                uint256(_balances.openingFee),
                uint256(_balances.liquidationDeposit),
                uint256(_balances.iporPublicationFee),
                uint256(_balances.liquidityPool),
                uint256(_balances.treasury)
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

    function getLastSwapId() external view override returns (uint256) {
        return _lastSwapId;
    }

    function addLiquidity(uint256 liquidityAmount)
        external
        override
        onlyJoseph
    {
        require(liquidityAmount != 0, IporErrors.MILTON_DEPOSIT_AMOUNT_TOO_LOW);
        _balances.liquidityPool =
            _balances.liquidityPool +
            uint128(liquidityAmount);
    }

    function subtractLiquidity(uint256 liquidityAmount)
        external
        override
        onlyJoseph
    {
        _balances.liquidityPool =
            _balances.liquidityPool -
            uint128(liquidityAmount);
    }

    function getSwapPayFixedItem(uint256 swapId)
        external
        view
        override
        returns (DataTypes.IporSwapMemory memory)
    {
        uint64 id = uint64(swapId);
        return
            DataTypes.IporSwapMemory(
                uint256(_swapsPayFixed.swaps[id].state),
                _swapsPayFixed.swaps[id].buyer,
                _swapsPayFixed.swaps[id].startingTimestamp,
                _swapsPayFixed.swaps[id].startingTimestamp +
                    Constants.SWAP_DEFAULT_PERIOD_IN_SECONDS,
                _swapsPayFixed.swaps[id].id,
                _swapsPayFixed.swaps[id].idsIndex,
                _swapsPayFixed.swaps[id].collateral,
                _swapsPayFixed.swaps[id].liquidationDepositAmount,
                _swapsPayFixed.swaps[id].notionalAmount,
                _swapsPayFixed.swaps[id].fixedInterestRate,
                _swapsPayFixed.swaps[id].ibtQuantity
            );
    }

    function getSwapPayFixedState(uint256 swapId)
        external
        view
        override
        returns (uint256)
    {
        return uint256(_swapsPayFixed.swaps[uint64(swapId)].state);
    }

    function getSwapReceiveFixedState(uint256 swapId)
        external
        view
        override
        returns (uint256)
    {
        return uint256(_swapsReceiveFixed.swaps[uint64(swapId)].state);
    }

    function getSwapReceiveFixedItem(uint256 swapId)
        external
        view
        override
        returns (DataTypes.IporSwapMemory memory)
    {
        uint64 id = uint64(swapId);
        return
            DataTypes.IporSwapMemory(
                uint256(_swapsReceiveFixed.swaps[id].state),
                _swapsReceiveFixed.swaps[id].buyer,
                _swapsReceiveFixed.swaps[id].startingTimestamp,
                _swapsReceiveFixed.swaps[id].startingTimestamp +
                    Constants.SWAP_DEFAULT_PERIOD_IN_SECONDS,
                _swapsReceiveFixed.swaps[id].id,
                _swapsReceiveFixed.swaps[id].idsIndex,
                _swapsReceiveFixed.swaps[id].collateral,
                _swapsReceiveFixed.swaps[id].liquidationDepositAmount,
                _swapsReceiveFixed.swaps[id].notionalAmount,
                _swapsReceiveFixed.swaps[id].fixedInterestRate,
                _swapsReceiveFixed.swaps[id].ibtQuantity
            );
    }

    function updateStorageWhenTransferPublicationFee(uint256 transferedAmount)
        external
        override
        onlyMilton
    {
        _balances.iporPublicationFee =
            _balances.iporPublicationFee -
            uint128(transferedAmount);
    }

    function updateStorageWhenOpenSwapPayFixed(
        DataTypes.NewSwap memory newSwap,
        uint256 openingAmount
    ) external override onlyMilton returns (uint256) {
        uint256 id = _updateSwapsWhenOpenPayFixed(newSwap);
        _updateBalancesWhenOpenSwapPayFixed(newSwap.collateral, openingAmount);
        _updateSoapIndicatorsWhenOpenSwapPayFixed(newSwap);
        return id;
    }

    function updateStorageWhenOpenSwapReceiveFixed(
        DataTypes.NewSwap memory newSwap,
        uint256 openingAmount
    ) external override onlyMilton returns (uint256) {
        uint256 id = _updateSwapsWhenOpenReceiveFixed(newSwap);
        _updateBalancesWhenOpenSwapReceiveFixed(
            newSwap.collateral,
            openingAmount
        );
        _updateSoapIndicatorsWhenOpenSwapReceiveFixed(newSwap);
        return id;
    }

    function updateStorageWhenCloseSwapPayFixed(
        address user,
        DataTypes.IporSwapMemory memory iporSwap,
        int256 positionValue,
        uint256 closingTimestamp
    ) external override onlyMilton {
        _updateSwapsWhenClosePayFixed(iporSwap);
        _updateBalancesWhenCloseSwapPayFixed(
            user,
            iporSwap,
            positionValue,
            closingTimestamp
        );
        _updateSoapIndicatorsWhenCloseSwapPayFixed(iporSwap, closingTimestamp);
    }

    function updateStorageWhenCloseSwapReceiveFixed(
        address user,
        DataTypes.IporSwapMemory memory iporSwap,
        int256 positionValue,
        uint256 closingTimestamp
    ) external override onlyMilton {
        _updateSwapsWhenCloseReceiveFixed(iporSwap);
        _updateBalancesWhenCloseSwapReceiveFixed(
            user,
            iporSwap,
            positionValue,
            closingTimestamp
        );
        _updateSoapIndicatorsWhenCloseSwapReceiveFixed(
            iporSwap,
            closingTimestamp
        );
    }

    function getSwapsPayFixed(address user)
        external
        view
        override
        returns (DataTypes.IporSwapMemory[] memory)
    {
        return _getPositions(_swapsPayFixed.swaps, _swapsPayFixed.ids[user]);
    }

    function getSwapsReceiveFixed(address user)
        external
        view
        override
        returns (DataTypes.IporSwapMemory[] memory)
    {
        return
            _getPositions(
                _swapsReceiveFixed.swaps,
                _swapsReceiveFixed.ids[user]
            );
    }

    function _getPositions(
        mapping(uint128 => DataTypes.IporSwap) storage swaps,
        uint128[] storage ids
    ) internal view returns (DataTypes.IporSwapMemory[] memory) {
        uint256 swapsIdsLength = ids.length;
        DataTypes.IporSwapMemory[]
            memory derivatives = new DataTypes.IporSwapMemory[](swapsIdsLength);
        uint256 i = 0;

        for (i; i != swapsIdsLength; i++) {
            uint128 id = ids[i];
            derivatives[i] = DataTypes.IporSwapMemory(
                uint256(swaps[id].state),
                swaps[id].buyer,
                swaps[id].startingTimestamp,
                swaps[id].startingTimestamp +
                    Constants.SWAP_DEFAULT_PERIOD_IN_SECONDS,
                swaps[id].id,
                swaps[id].idsIndex,
                swaps[id].collateral,
                swaps[id].liquidationDepositAmount,
                swaps[id].notionalAmount,
                swaps[id].fixedInterestRate,
                swaps[id].ibtQuantity
            );
        }
        return derivatives;
    }

    function getUserSwapPayFixedIds(address userAddress)
        external
        view
        override
        returns (uint128[] memory)
    {
        return _swapsPayFixed.ids[userAddress];
    }

    function getUserSwapReceiveFixedIds(address userAddress)
        external
        view
        override
        returns (uint128[] memory)
    {
        return _swapsReceiveFixed.ids[userAddress];
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
            soapPf = IporMath.divisionInt(
                qSoapPf,
                Constants.WAD_P2_YEAR_IN_SECONDS_INT
            ),
            soapRf = IporMath.divisionInt(
                qSoapRf,
                Constants.WAD_P2_YEAR_IN_SECONDS_INT
            ),
            soap = IporMath.divisionInt(
                qSoap,
                Constants.WAD_P2_YEAR_IN_SECONDS_INT
            )
        );
    }

    function calculateSoapPayFixed(uint256 ibtPrice, uint256 calculateTimestamp)
        external
        view
        override
        returns (int256 soapPf)
    {
        int256 qSoapPf = _calculateQuasiSoapPayFixed(
            ibtPrice,
            calculateTimestamp
        );

        soapPf = IporMath.divisionInt(
            qSoapPf,
            Constants.WAD_P2_YEAR_IN_SECONDS_INT
        );
    }

    function calculateSoapReceiveFixed(
        uint256 ibtPrice,
        uint256 calculateTimestamp
    ) external view override returns (int256 soapRf) {
        int256 qSoapRf = _calculateQuasiSoapReceiveFixed(
            ibtPrice,
            calculateTimestamp
        );

        soapRf = IporMath.divisionInt(
            qSoapRf,
            Constants.WAD_P2_YEAR_IN_SECONDS_INT
        );
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
        DataTypes.SoapIndicatorMemory memory spf = DataTypes
            .SoapIndicatorMemory(
                _soapIndicatorsPayFixed.rebalanceTimestamp,
                _soapIndicatorsPayFixed.totalNotional,
                _soapIndicatorsPayFixed.averageInterestRate,
                _soapIndicatorsPayFixed.totalIbtQuantity,
                _soapIndicatorsPayFixed.quasiHypotheticalInterestCumulative
            );
        int256 _soapPf = spf.calculateQuasiSoapPayFixed(
            calculateTimestamp,
            ibtPrice
        );

        DataTypes.SoapIndicatorMemory memory srf = DataTypes
            .SoapIndicatorMemory(
                _soapIndicatorsReceiveFixed.rebalanceTimestamp,
                _soapIndicatorsReceiveFixed.totalNotional,
                _soapIndicatorsReceiveFixed.averageInterestRate,
                _soapIndicatorsReceiveFixed.totalIbtQuantity,
                _soapIndicatorsReceiveFixed.quasiHypotheticalInterestCumulative
            );
        int256 _soapRf = srf.calculateQuasiSoapReceiveFixed(
            calculateTimestamp,
            ibtPrice
        );
        return (soapPf = _soapPf, soapRf = _soapRf, soap = _soapPf + _soapRf);
    }

    function _calculateQuasiSoapPayFixed(
        uint256 ibtPrice,
        uint256 calculateTimestamp
    ) internal view returns (int256 soapPf) {
        DataTypes.SoapIndicatorMemory memory spf = DataTypes
            .SoapIndicatorMemory(
                _soapIndicatorsPayFixed.rebalanceTimestamp,
                _soapIndicatorsPayFixed.totalNotional,
                _soapIndicatorsPayFixed.averageInterestRate,
                _soapIndicatorsPayFixed.totalIbtQuantity,
                _soapIndicatorsPayFixed.quasiHypotheticalInterestCumulative
            );
        soapPf = spf.calculateQuasiSoapPayFixed(calculateTimestamp, ibtPrice);
    }

    function _calculateQuasiSoapReceiveFixed(
        uint256 ibtPrice,
        uint256 calculateTimestamp
    ) internal view returns (int256 soapRf) {
        DataTypes.SoapIndicatorMemory memory srf = DataTypes
            .SoapIndicatorMemory(
                _soapIndicatorsReceiveFixed.rebalanceTimestamp,
                _soapIndicatorsReceiveFixed.totalNotional,
                _soapIndicatorsReceiveFixed.averageInterestRate,
                _soapIndicatorsReceiveFixed.totalIbtQuantity,
                _soapIndicatorsReceiveFixed.quasiHypotheticalInterestCumulative
            );
        soapRf = srf.calculateQuasiSoapReceiveFixed(
            calculateTimestamp,
            ibtPrice
        );
    }

    function _updateBalancesWhenOpenSwapPayFixed(
        uint256 collateral,
        uint256 openingFeeAmount
    ) internal {
        _balances.payFixedDerivatives =
            _balances.payFixedDerivatives +
            uint128(collateral);

        _balances.openingFee = _balances.openingFee + uint128(openingFeeAmount);
        _balances.liquidationDeposit =
            _balances.liquidationDeposit +
            uint128(_iporAssetConfiguration.getLiquidationDepositAmount());
        _balances.iporPublicationFee =
            _balances.iporPublicationFee +
            uint128(_iporAssetConfiguration.getIporPublicationFeeAmount());

        uint256 openingFeeForTreasurePercentage = _iporAssetConfiguration
            .getOpeningFeeForTreasuryPercentage();
        (
            uint256 openingFeeLPValue,
            uint256 openingFeeTreasuryValue
        ) = _splitOpeningFeeAmount(
                openingFeeAmount,
                openingFeeForTreasurePercentage
            );
        _balances.liquidityPool =
            _balances.liquidityPool +
            uint128(openingFeeLPValue);
        _balances.treasury =
            _balances.treasury +
            uint128(openingFeeTreasuryValue);
    }

    function _updateBalancesWhenOpenSwapReceiveFixed(
        uint256 collateral,
        uint256 openingFeeAmount
    ) internal {
        _balances.recFixedDerivatives =
            _balances.recFixedDerivatives +
            uint128(collateral);

        _balances.openingFee = _balances.openingFee + uint128(openingFeeAmount);
        _balances.liquidationDeposit =
            _balances.liquidationDeposit +
            uint128(_iporAssetConfiguration.getLiquidationDepositAmount());
        _balances.iporPublicationFee =
            _balances.iporPublicationFee +
            uint128(_iporAssetConfiguration.getIporPublicationFeeAmount());

        uint256 openingFeeForTreasurePercentage = _iporAssetConfiguration
            .getOpeningFeeForTreasuryPercentage();
        (
            uint256 openingFeeLPValue,
            uint256 openingFeeTreasuryValue
        ) = _splitOpeningFeeAmount(
                openingFeeAmount,
                openingFeeForTreasurePercentage
            );
        _balances.liquidityPool =
            _balances.liquidityPool +
            uint128(openingFeeLPValue);
        _balances.treasury =
            _balances.treasury +
            uint128(openingFeeTreasuryValue);
    }

    function _splitOpeningFeeAmount(
        uint256 openingFeeAmount,
        uint256 openingFeeForTreasurePercentage
    )
        internal
        pure
        returns (uint256 liquidityPoolValue, uint256 treasuryValue)
    {
        treasuryValue = IporMath.division(
            openingFeeAmount * openingFeeForTreasurePercentage,
            Constants.D18
        );
        liquidityPoolValue = openingFeeAmount - treasuryValue;
    }

    function _updateBalancesWhenCloseSwapPayFixed(
        address user,
        DataTypes.IporSwapMemory memory swap,
        int256 positionValue,
        uint256 closingTimestamp
    ) internal {
        uint256 abspositionValue = IporMath.absoluteValue(positionValue);

        //decrease from balances the liquidation deposit
        require(
            _balances.liquidationDeposit >= swap.liquidationDepositAmount,
            IporErrors
                .MILTON_CANNOT_CLOSE_DERIVATE_LIQUIDATION_DEPOSIT_BALANCE_IS_TOO_LOW
        );
        _balances.liquidationDeposit =
            _balances.liquidationDeposit -
            uint128(swap.liquidationDepositAmount);

        _balances.payFixedDerivatives =
            _balances.payFixedDerivatives -
            uint128(swap.collateral);
        //TODO: remove duplication
        if (abspositionValue < swap.collateral) {
            //verify if sender is an owner of swap if not then check if maturity - if not then reject, if yes then close even if not an owner
            if (user != swap.buyer) {
                require(
                    closingTimestamp >= swap.endingTimestamp,
                    IporErrors
                        .MILTON_CANNOT_CLOSE_DERIVATE_SENDER_IS_NOT_BUYER_AND_NO_DERIVATIVE_MATURITY
                );
            }
        }

        uint256 incomeTax = IporMath.division(
            abspositionValue * _iporAssetConfiguration.getIncomeTaxPercentage(),
            Constants.D18
        );

        _balances.treasury = _balances.treasury + uint128(incomeTax);

        if (positionValue > 0) {
            require(
                _balances.liquidityPool >= abspositionValue,
                IporErrors
                    .MILTON_CANNOT_CLOSE_DERIVATE_LIQUIDITY_POOL_IS_TOO_LOW
            );

            _balances.liquidityPool =
                _balances.liquidityPool -
                uint128(abspositionValue);
        } else {
            _balances.liquidityPool =
                _balances.liquidityPool +
                uint128(abspositionValue - incomeTax);
        }
    }

    function _updateBalancesWhenCloseSwapReceiveFixed(
        address user,
        DataTypes.IporSwapMemory memory swap,
        int256 positionValue,
        uint256 closingTimestamp
    ) internal {
        uint256 abspositionValue = IporMath.absoluteValue(positionValue);

        //decrease from balances the liquidation deposit
        require(
            _balances.liquidationDeposit >= swap.liquidationDepositAmount,
            IporErrors
                .MILTON_CANNOT_CLOSE_DERIVATE_LIQUIDATION_DEPOSIT_BALANCE_IS_TOO_LOW
        );
        _balances.liquidationDeposit =
            _balances.liquidationDeposit -
            uint128(swap.liquidationDepositAmount);

        _balances.recFixedDerivatives =
            _balances.recFixedDerivatives -
            uint128(swap.collateral);

        //TODO: remove duplication

        if (abspositionValue < swap.collateral) {
            //verify if sender is an owner of swap if not then check if maturity - if not then reject, if yes then close even if not an owner
            if (user != swap.buyer) {
                require(
                    closingTimestamp >= swap.endingTimestamp,
                    IporErrors
                        .MILTON_CANNOT_CLOSE_DERIVATE_SENDER_IS_NOT_BUYER_AND_NO_DERIVATIVE_MATURITY
                );
            }
        }

        uint256 incomeTax = IporMath.division(
            abspositionValue * _iporAssetConfiguration.getIncomeTaxPercentage(),
            Constants.D18
        );

        _balances.treasury = _balances.treasury + uint128(incomeTax);

        if (positionValue > 0) {
            require(
                _balances.liquidityPool >= abspositionValue,
                IporErrors
                    .MILTON_CANNOT_CLOSE_DERIVATE_LIQUIDITY_POOL_IS_TOO_LOW
            );

            _balances.liquidityPool =
                _balances.liquidityPool -
                uint128(abspositionValue);
        } else {
            _balances.liquidityPool =
                _balances.liquidityPool +
                uint128(abspositionValue - incomeTax);
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
        swap.startingTimestamp = uint32(newSwap.startingTimestamp);

        swap.id = id;
        swap.collateral = uint128(newSwap.collateral);
        swap.liquidationDepositAmount = uint128(
            newSwap.liquidationDepositAmount
        );
        swap.notionalAmount = uint128(newSwap.notionalAmount);
        swap.fixedInterestRate = uint128(newSwap.fixedInterestRate);
        swap.ibtQuantity = uint128(newSwap.ibtQuantity);

        swap.idsIndex = uint64(_swapsPayFixed.ids[newSwap.buyer].length);
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
        swap.startingTimestamp = uint32(newSwap.startingTimestamp);

        swap.id = id;
        swap.collateral = uint128(newSwap.collateral);
        swap.liquidationDepositAmount = uint128(
            newSwap.liquidationDepositAmount
        );
        swap.notionalAmount = uint128(newSwap.notionalAmount);
        swap.fixedInterestRate = uint128(newSwap.fixedInterestRate);
        swap.ibtQuantity = uint128(newSwap.ibtQuantity);

        swap.idsIndex = uint64(_swapsReceiveFixed.ids[newSwap.buyer].length);
        _swapsReceiveFixed.ids[newSwap.buyer].push(id);
        _lastSwapId = id;

        return id;
    }

    function _updateSwapsWhenClosePayFixed(
        DataTypes.IporSwapMemory memory iporSwap
    ) internal {
        require(
            iporSwap.id != 0,
            IporErrors.MILTON_CLOSE_POSITION_INCORRECT_SWAP_ID
        );
        require(
            iporSwap.state != uint256(DataTypes.SwapState.INACTIVE),
            IporErrors.MILTON_CLOSE_POSITION_INCORRECT_DERIVATIVE_STATUS
        );

        uint64 idsIndexToDelete = uint64(iporSwap.idsIndex);
        address buyer = iporSwap.buyer;
        uint256 idsLength = _swapsPayFixed.ids[buyer].length - 1;
        if (idsIndexToDelete < idsLength) {
            uint128 userDerivativeIdToMove = _swapsPayFixed.ids[buyer][
                idsLength
            ];

            _swapsPayFixed
                .swaps[userDerivativeIdToMove]
                .idsIndex = idsIndexToDelete;

            _swapsPayFixed.ids[buyer][
                idsIndexToDelete
            ] = userDerivativeIdToMove;
        }

        _swapsPayFixed.swaps[uint64(iporSwap.id)].state = DataTypes
            .SwapState
            .INACTIVE;
        _swapsPayFixed.ids[buyer].pop();
    }

    function _updateSwapsWhenCloseReceiveFixed(
        DataTypes.IporSwapMemory memory iporSwap
    ) internal {
        require(
            iporSwap.id != 0,
            IporErrors.MILTON_CLOSE_POSITION_INCORRECT_SWAP_ID
        );
        require(
            iporSwap.state != uint256(DataTypes.SwapState.INACTIVE),
            IporErrors.MILTON_CLOSE_POSITION_INCORRECT_DERIVATIVE_STATUS
        );

        uint64 idsIndexToDelete = uint64(iporSwap.idsIndex);
        address buyer = iporSwap.buyer;
        uint256 idsLength = _swapsReceiveFixed.ids[buyer].length - 1;

        if (idsIndexToDelete < idsLength) {
            uint128 userDerivativeIdToMove = _swapsReceiveFixed.ids[buyer][
                idsLength
            ];

            _swapsReceiveFixed
                .swaps[userDerivativeIdToMove]
                .idsIndex = idsIndexToDelete;

            _swapsReceiveFixed.ids[buyer][
                idsIndexToDelete
            ] = userDerivativeIdToMove;
        }

        _swapsReceiveFixed.swaps[uint64(iporSwap.id)].state = DataTypes
            .SwapState
            .INACTIVE;
        _swapsReceiveFixed.ids[buyer].pop();
    }

    function _updateSoapIndicatorsWhenOpenSwapPayFixed(
        DataTypes.NewSwap memory newSwap
    ) internal {
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
        _soapIndicatorsPayFixed.rebalanceTimestamp = uint32(
            pf.rebalanceTimestamp
        );
        _soapIndicatorsPayFixed.totalNotional = uint128(pf.totalNotional);
        _soapIndicatorsPayFixed.averageInterestRate = uint128(
            pf.averageInterestRate
        );
        _soapIndicatorsPayFixed.totalIbtQuantity = uint128(pf.totalIbtQuantity);
        _soapIndicatorsPayFixed.quasiHypotheticalInterestCumulative = uint256(
            pf.quasiHypotheticalInterestCumulative
        );
    }

    function _updateSoapIndicatorsWhenOpenSwapReceiveFixed(
        DataTypes.NewSwap memory newSwap
    ) internal {
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

        _soapIndicatorsReceiveFixed.rebalanceTimestamp = uint32(
            rf.rebalanceTimestamp
        );
        _soapIndicatorsReceiveFixed.totalNotional = uint128(rf.totalNotional);
        _soapIndicatorsReceiveFixed.averageInterestRate = uint128(
            rf.averageInterestRate
        );
        _soapIndicatorsReceiveFixed.totalIbtQuantity = uint128(
            rf.totalIbtQuantity
        );
        _soapIndicatorsReceiveFixed
            .quasiHypotheticalInterestCumulative = uint256(
            rf.quasiHypotheticalInterestCumulative
        );
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
            uint32(pf.rebalanceTimestamp),
            uint128(pf.totalNotional),
            uint128(pf.averageInterestRate),
            uint128(pf.totalIbtQuantity),
            uint256(pf.quasiHypotheticalInterestCumulative)
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
            uint32(rf.rebalanceTimestamp),
            uint128(rf.totalNotional),
            uint128(rf.averageInterestRate),
            uint128(rf.totalIbtQuantity),
            uint256(rf.quasiHypotheticalInterestCumulative)
        );
    }

    modifier onlyMilton() {
        require(
            msg.sender == _iporAssetConfiguration.getMilton(),
            IporErrors.MILTON_CALLER_NOT_MILTON
        );
        _;
    }

    modifier onlyJoseph() {
        require(
            msg.sender == _iporAssetConfiguration.getJoseph(),
            IporErrors.MILTON_CALLER_NOT_JOSEPH
        );
        _;
    }
}

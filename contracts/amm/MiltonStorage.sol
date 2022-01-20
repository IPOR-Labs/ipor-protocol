// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";
import {DataTypes} from "../libraries/types/DataTypes.sol";
import "../libraries/DerivativeLogic.sol";
import "../libraries/SoapIndicatorLogic.sol";
import "../libraries/DerivativesView.sol";
import "../interfaces/IIporConfiguration.sol";
import "../libraries/types/DataTypes.sol";
import "../interfaces/IMiltonStorage.sol";
import "../interfaces/IIporAssetConfiguration.sol";
import "../libraries/Constants.sol";

contract MiltonStorage is Ownable, IMiltonStorage {
    //TODO: if possible move out libraries from MiltonStorage to Milton, use storage as clean storage smart contract
    using DerivativeLogic for DataTypes.IporDerivativeMemory;
    using SoapIndicatorLogic for DataTypes.SoapIndicatorMemory;
    using DerivativesView for MiltonDerivativesStorage;

    address private _asset;
    IIporConfiguration internal _iporConfiguration;
    IIporAssetConfiguration internal _iporAssetConfiguration;

    // uint128 internal _balancePayFixedSwaps;
    // uint128 internal _balanceReceiveFixedSwaps;

    DataTypes.MiltonTotalBalanceStorage public balances;

    // ---

    DataTypes.SoapIndicatorStorage internal _soapIndicatorsPayFixed;
    DataTypes.SoapIndicatorStorage internal _soapIndicatorsReceiveFixed;

    MiltonDerivativesStorage internal _swapsPayFixed;
    MiltonDerivativesStorage internal _swapsReceiveFixed;

    uint64 private _lastSwapId;

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
                uint256(balances.payFixedDerivatives),
                uint256(balances.recFixedDerivatives),
                uint256(balances.openingFee),
                uint256(balances.liquidationDeposit),
                uint256(balances.iporPublicationFee),
                uint256(balances.liquidityPool),
                uint256(balances.treasury)
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
        balances.liquidityPool =
            balances.liquidityPool +
            uint128(liquidityAmount);
    }

    function subtractLiquidity(uint256 liquidityAmount)
        external
        override
        onlyJoseph
    {
        balances.liquidityPool =
            balances.liquidityPool -
            uint128(liquidityAmount);
    }

    function getSwapPayFixedItem(uint256 swapId)
        external
        view
        override
        returns (DataTypes.MiltonDerivativeItemMemory memory)
    {
        uint64 id = uint64(swapId);
        return
            DataTypes.MiltonDerivativeItemMemory(
                _swapsPayFixed.items[id].idsIndex,
                _swapsPayFixed.items[id].userDerivativeIdsIndex,
                DataTypes.IporDerivativeMemory(
                    uint256(_swapsPayFixed.items[id].item.state),
                    _swapsPayFixed.items[id].item.buyer,
                    _swapsPayFixed.items[id].item.startingTimestamp,
                    _swapsPayFixed.items[id].item.startingTimestamp +
                        Constants.DERIVATIVE_DEFAULT_PERIOD_IN_SECONDS,
                    _swapsPayFixed.items[id].item.id,
                    _swapsPayFixed.items[id].item.collateral,
                    _swapsPayFixed.items[id].item.liquidationDepositAmount,
                    _swapsPayFixed.items[id].item.notionalAmount,
                    _swapsPayFixed.items[id].item.fixedInterestRate,
                    _swapsPayFixed.items[id].item.ibtQuantity
                )
            );
    }

    function getSwapPayFixedState(uint256 swapId)
        external
        view
        override
        returns (uint256)
    {
        return uint256(_swapsPayFixed.items[uint64(swapId)].item.state);
    }

    function getSwapReceiveFixedState(uint256 swapId)
        external
        view
        override
        returns (uint256)
    {
        return uint256(_swapsReceiveFixed.items[uint64(swapId)].item.state);
    }

    function getSwapReceiveFixedItem(uint256 swapId)
        external
        view
        override
        returns (DataTypes.MiltonDerivativeItemMemory memory)
    {
        uint64 id = uint64(swapId);
        return
            DataTypes.MiltonDerivativeItemMemory(
                _swapsReceiveFixed.items[id].idsIndex,
                _swapsReceiveFixed.items[id].userDerivativeIdsIndex,
                DataTypes.IporDerivativeMemory(
                    uint256(_swapsReceiveFixed.items[id].item.state),
                    _swapsReceiveFixed.items[id].item.buyer,
                    _swapsReceiveFixed.items[id].item.startingTimestamp,
                    _swapsReceiveFixed.items[id].item.startingTimestamp +
                        Constants.DERIVATIVE_DEFAULT_PERIOD_IN_SECONDS,
                    _swapsReceiveFixed.items[id].item.id,
                    _swapsReceiveFixed.items[id].item.collateral,
                    _swapsReceiveFixed.items[id].item.liquidationDepositAmount,
                    _swapsReceiveFixed.items[id].item.notionalAmount,
                    _swapsReceiveFixed.items[id].item.fixedInterestRate,
                    _swapsReceiveFixed.items[id].item.ibtQuantity
                )
            );
    }

    function updateStorageWhenTransferPublicationFee(uint256 transferedAmount)
        external
        override
        onlyMilton
    {
        balances.iporPublicationFee =
            balances.iporPublicationFee -
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
        DataTypes.MiltonDerivativeItemMemory memory derivativeItem,
        int256 positionValue,
        uint256 closingTimestamp
    ) external override onlyMilton {
        _updateSwapsWhenClosePayFixed(derivativeItem);
        _updateBalancesWhenCloseSwapPayFixed(
            user,
            derivativeItem.item,
            positionValue,
            closingTimestamp
        );
        _updateSoapIndicatorsWhenCloseSwapPayFixed(
            derivativeItem.item,
            closingTimestamp
        );
    }

    function updateStorageWhenCloseSwapReceiveFixed(
        address user,
        DataTypes.MiltonDerivativeItemMemory memory derivativeItem,
        int256 positionValue,
        uint256 closingTimestamp
    ) external override onlyMilton {
        _updateSwapsWhenCloseReceiveFixed(derivativeItem);
        _updateBalancesWhenCloseSwapReceiveFixed(
            user,
            derivativeItem.item,
            positionValue,
            closingTimestamp
        );
        _updateSoapIndicatorsWhenCloseSwapReceiveFixed(
            derivativeItem.item,
            closingTimestamp
        );
    }

    function getSwapsPayFixed()
        external
        view
        override
        returns (DataTypes.IporDerivativeMemory[] memory)
    {
        return _swapsPayFixed.getPositions();
    }

    function getSwapsReceiveFixed()
        external
        view
        override
        returns (DataTypes.IporDerivativeMemory[] memory)
    {
        return _swapsReceiveFixed.getPositions();
    }

    function getUserSwapsPayFixed(address user)
        external
        view
        override
        returns (DataTypes.IporDerivativeMemory[] memory)
    {
        return _swapsPayFixed.getUserPositions(user);
    }

    function getUserSwapsReceiveFixed(address user)
        external
        view
        override
        returns (DataTypes.IporDerivativeMemory[] memory)
    {
        return _swapsReceiveFixed.getUserPositions(user);
    }

    function getSwapPayFixedIds()
        external
        view
        override
        returns (uint256[] memory)
    {
        return _swapsPayFixed.ids;
    }

    function getSwapReceiveFixedIds()
        external
        view
        override
        returns (uint256[] memory)
    {
        return _swapsReceiveFixed.ids;
    }

    function getUserSwapPayFixedIds(address userAddress)
        external
        view
        override
        returns (uint256[] memory)
    {
        return _swapsPayFixed.userDerivativeIds[userAddress];
    }

    function getUserSwapReceiveFixedIds(address userAddress)
        external
        view
        override
        returns (uint256[] memory)
    {
        return _swapsReceiveFixed.userDerivativeIds[userAddress];
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
        balances.payFixedDerivatives =
            balances.payFixedDerivatives +
            uint128(collateral);

        balances.openingFee = balances.openingFee + uint128(openingFeeAmount);
        balances.liquidationDeposit =
            balances.liquidationDeposit +
            uint128(_iporAssetConfiguration.getLiquidationDepositAmount());
        balances.iporPublicationFee =
            balances.iporPublicationFee +
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
        balances.liquidityPool =
            balances.liquidityPool +
            uint128(openingFeeLPValue);
        balances.treasury =
            balances.treasury +
            uint128(openingFeeTreasuryValue);
    }

    function _updateBalancesWhenOpenSwapReceiveFixed(
        uint256 collateral,
        uint256 openingFeeAmount
    ) internal {
        balances.recFixedDerivatives =
            balances.recFixedDerivatives +
            uint128(collateral);

        balances.openingFee = balances.openingFee + uint128(openingFeeAmount);
        balances.liquidationDeposit =
            balances.liquidationDeposit +
            uint128(_iporAssetConfiguration.getLiquidationDepositAmount());
        balances.iporPublicationFee =
            balances.iporPublicationFee +
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
        balances.liquidityPool =
            balances.liquidityPool +
            uint128(openingFeeLPValue);
        balances.treasury =
            balances.treasury +
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
        DataTypes.IporDerivativeMemory memory swap,
        int256 positionValue,
        uint256 closingTimestamp
    ) internal {
        uint256 abspositionValue = IporMath.absoluteValue(positionValue);

        //decrease from balances the liquidation deposit
        require(
            balances.liquidationDeposit >= swap.liquidationDepositAmount,
            IporErrors
                .MILTON_CANNOT_CLOSE_DERIVATE_LIQUIDATION_DEPOSIT_BALANCE_IS_TOO_LOW
        );
        balances.liquidationDeposit =
            balances.liquidationDeposit -
            uint128(swap.liquidationDepositAmount);

        balances.payFixedDerivatives =
            balances.payFixedDerivatives -
            uint128(swap.collateral);
        //TODO: remove duplication
        if (abspositionValue < swap.collateral) {
            //verify if sender is an owner of derivative if not then check if maturity - if not then reject, if yes then close even if not an owner
            if (user != swap.buyer) {
                require(
                    closingTimestamp >= swap.endingTimestamp,
                    IporErrors
                        .MILTON_CANNOT_CLOSE_DERIVATE_SENDER_IS_NOT_BUYER_AND_NO_DERIVATIVE_MATURITY
                );
            }
        }

        uint256 incomeTax = IporMath.calculateIncomeTax(
            abspositionValue,
            _iporAssetConfiguration.getIncomeTaxPercentage()
        );

        balances.treasury = balances.treasury + uint128(incomeTax);

        if (positionValue > 0) {
            require(
                balances.liquidityPool >= abspositionValue,
                IporErrors
                    .MILTON_CANNOT_CLOSE_DERIVATE_LIQUIDITY_POOL_IS_TOO_LOW
            );

            balances.liquidityPool =
                balances.liquidityPool -
                uint128(abspositionValue);
        } else {
            balances.liquidityPool =
                balances.liquidityPool +
                uint128(abspositionValue - incomeTax);
        }
    }

    function _updateBalancesWhenCloseSwapReceiveFixed(
        address user,
        DataTypes.IporDerivativeMemory memory swap,
        int256 positionValue,
        uint256 closingTimestamp
    ) internal {
        uint256 abspositionValue = IporMath.absoluteValue(positionValue);

        //decrease from balances the liquidation deposit
        require(
            balances.liquidationDeposit >= swap.liquidationDepositAmount,
            IporErrors
                .MILTON_CANNOT_CLOSE_DERIVATE_LIQUIDATION_DEPOSIT_BALANCE_IS_TOO_LOW
        );
        balances.liquidationDeposit =
            balances.liquidationDeposit -
            uint128(swap.liquidationDepositAmount);

        balances.recFixedDerivatives =
            balances.recFixedDerivatives -
            uint128(swap.collateral);

        //TODO: remove duplication

        if (abspositionValue < swap.collateral) {
            //verify if sender is an owner of derivative if not then check if maturity - if not then reject, if yes then close even if not an owner
            if (user != swap.buyer) {
                require(
                    closingTimestamp >= swap.endingTimestamp,
                    IporErrors
                        .MILTON_CANNOT_CLOSE_DERIVATE_SENDER_IS_NOT_BUYER_AND_NO_DERIVATIVE_MATURITY
                );
            }
        }

        uint256 incomeTax = IporMath.calculateIncomeTax(
            abspositionValue,
            _iporAssetConfiguration.getIncomeTaxPercentage()
        );

        balances.treasury = balances.treasury + uint128(incomeTax);

        if (positionValue > 0) {
            require(
                balances.liquidityPool >= abspositionValue,
                IporErrors
                    .MILTON_CANNOT_CLOSE_DERIVATE_LIQUIDITY_POOL_IS_TOO_LOW
            );

            balances.liquidityPool =
                balances.liquidityPool -
                uint128(abspositionValue);
        } else {
            balances.liquidityPool =
                balances.liquidityPool +
                uint128(abspositionValue - incomeTax);
        }
    }

    function _updateSwapsWhenOpenPayFixed(DataTypes.NewSwap memory newSwap)
        internal
        returns (uint256)
    {
        _lastSwapId++;
        uint64 id = _lastSwapId;

        _swapsPayFixed.items[id].item.state = DerivativeState.ACTIVE;
        _swapsPayFixed.items[id].item.buyer = newSwap.buyer;
        _swapsPayFixed.items[id].item.startingTimestamp = uint32(
            newSwap.startingTimestamp
        );
        // _swapsPayFixed.items[id].item.endingTimestamp = uint32(
        //     newSwap.startingTimestamp +
        //         Constants.DERIVATIVE_DEFAULT_PERIOD_IN_SECONDS
        // );
        _swapsPayFixed.items[id].item.id = id;
        _swapsPayFixed.items[id].item.collateral = uint128(newSwap.collateral);
        _swapsPayFixed.items[id].item.liquidationDepositAmount = uint128(
            newSwap.liquidationDepositAmount
        );
        _swapsPayFixed.items[id].item.notionalAmount = uint128(
            newSwap.notionalAmount
        );
        _swapsPayFixed.items[id].item.fixedInterestRate = uint128(
            newSwap.fixedInterestRate
        );
        _swapsPayFixed.items[id].item.ibtQuantity = uint128(
            newSwap.ibtQuantity
        );

        _swapsPayFixed.items[id].idsIndex = uint64(_swapsPayFixed.ids.length);
        _swapsPayFixed.items[id].userDerivativeIdsIndex = uint64(
            _swapsPayFixed.userDerivativeIds[newSwap.buyer].length
        );
        _swapsPayFixed.ids.push(id);
        _swapsPayFixed.userDerivativeIds[newSwap.buyer].push(id);
        _lastSwapId = id;

        return id;
    }

    function _updateSwapsWhenOpenReceiveFixed(DataTypes.NewSwap memory newSwap)
        internal
        returns (uint256)
    {
        _lastSwapId++;
        uint64 id = _lastSwapId;

        _swapsReceiveFixed.items[id].item.state = DerivativeState.ACTIVE;
        _swapsReceiveFixed.items[id].item.buyer = newSwap.buyer;
        _swapsReceiveFixed.items[id].item.startingTimestamp = uint32(
            newSwap.startingTimestamp
        );

        _swapsReceiveFixed.items[id].item.id = id;
        _swapsReceiveFixed.items[id].item.collateral = uint128(
            newSwap.collateral
        );
        _swapsReceiveFixed.items[id].item.liquidationDepositAmount = uint128(
            newSwap.liquidationDepositAmount
        );
        _swapsReceiveFixed.items[id].item.notionalAmount = uint128(
            newSwap.notionalAmount
        );
        _swapsReceiveFixed.items[id].item.fixedInterestRate = uint128(
            newSwap.fixedInterestRate
        );
        _swapsReceiveFixed.items[id].item.ibtQuantity = uint128(
            newSwap.ibtQuantity
        );

        _swapsReceiveFixed.items[id].idsIndex = uint64(
            _swapsReceiveFixed.ids.length
        );
        _swapsReceiveFixed.items[id].userDerivativeIdsIndex = uint64(
            _swapsReceiveFixed.userDerivativeIds[newSwap.buyer].length
        );
        _swapsReceiveFixed.ids.push(id);
        _swapsReceiveFixed.userDerivativeIds[newSwap.buyer].push(id);
        _lastSwapId = id;

        return id;
    }

    function _updateSwapsWhenClosePayFixed(
        DataTypes.MiltonDerivativeItemMemory memory derivativeItem
    ) internal {
        require(
            derivativeItem.item.id != 0,
            IporErrors.MILTON_CLOSE_POSITION_INCORRECT_DERIVATIVE_ID
        );
        require(
            derivativeItem.item.state != uint256(DerivativeState.INACTIVE),
            IporErrors.MILTON_CLOSE_POSITION_INCORRECT_DERIVATIVE_STATUS
        );
        uint64 idsIndexToDelete = uint64(derivativeItem.idsIndex);

        if (idsIndexToDelete < _swapsPayFixed.ids.length - 1) {
            uint64 idsDerivativeIdToMove = uint64(
                _swapsPayFixed.ids[_swapsPayFixed.ids.length - 1]
            );
            _swapsPayFixed
                .items[idsDerivativeIdToMove]
                .idsIndex = idsIndexToDelete;
            _swapsPayFixed.ids[idsIndexToDelete] = idsDerivativeIdToMove;
        }

        uint64 userDerivativeIdsIndexToDelete = uint64(
            derivativeItem.userDerivativeIdsIndex
        );
        address buyer = derivativeItem.item.buyer;

        if (
            userDerivativeIdsIndexToDelete <
            _swapsPayFixed.userDerivativeIds[buyer].length - 1
        ) {
            uint256 userDerivativeIdToMove = _swapsPayFixed.userDerivativeIds[
                buyer
            ][_swapsPayFixed.userDerivativeIds[buyer].length - 1];

            _swapsPayFixed
                .items[userDerivativeIdToMove]
                .userDerivativeIdsIndex = userDerivativeIdsIndexToDelete;

            _swapsPayFixed.userDerivativeIds[buyer][
                userDerivativeIdsIndexToDelete
            ] = userDerivativeIdToMove;
        }

        _swapsPayFixed
            .items[uint64(derivativeItem.item.id)]
            .item
            .state = DerivativeState.INACTIVE;
        _swapsPayFixed.ids.pop();
        _swapsPayFixed.userDerivativeIds[buyer].pop();
    }

    function _updateSwapsWhenCloseReceiveFixed(
        DataTypes.MiltonDerivativeItemMemory memory derivativeItem
    ) internal {
        require(
            derivativeItem.item.id != 0,
            IporErrors.MILTON_CLOSE_POSITION_INCORRECT_DERIVATIVE_ID
        );
        require(
            derivativeItem.item.state != uint256(DerivativeState.INACTIVE),
            IporErrors.MILTON_CLOSE_POSITION_INCORRECT_DERIVATIVE_STATUS
        );
        uint64 idsIndexToDelete = uint64(derivativeItem.idsIndex);

        if (idsIndexToDelete < _swapsReceiveFixed.ids.length - 1) {
            uint256 idsDerivativeIdToMove = _swapsReceiveFixed.ids[
                _swapsReceiveFixed.ids.length - 1
            ];
            _swapsReceiveFixed
                .items[idsDerivativeIdToMove]
                .idsIndex = idsIndexToDelete;
            _swapsReceiveFixed.ids[idsIndexToDelete] = idsDerivativeIdToMove;
        }

        uint64 userDerivativeIdsIndexToDelete = uint64(
            derivativeItem.userDerivativeIdsIndex
        );
        address buyer = derivativeItem.item.buyer;

        if (
            userDerivativeIdsIndexToDelete <
            _swapsReceiveFixed.userDerivativeIds[buyer].length - 1
        ) {
            uint256 userDerivativeIdToMove = _swapsReceiveFixed
                .userDerivativeIds[buyer][
                    _swapsReceiveFixed.userDerivativeIds[buyer].length - 1
                ];

            _swapsReceiveFixed
                .items[userDerivativeIdToMove]
                .userDerivativeIdsIndex = userDerivativeIdsIndexToDelete;

            _swapsReceiveFixed.userDerivativeIds[buyer][
                    userDerivativeIdsIndexToDelete
                ] = userDerivativeIdToMove;
        }

        _swapsReceiveFixed
            .items[uint64(derivativeItem.item.id)]
            .item
            .state = DerivativeState.INACTIVE;
        _swapsReceiveFixed.ids.pop();
        _swapsReceiveFixed.userDerivativeIds[buyer].pop();
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
        pf.rebalanceWhenOpenPosition(
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
        rf.rebalanceWhenOpenPosition(
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
        DataTypes.IporDerivativeMemory memory swap,
        uint256 closingTimestamp
    ) internal {
        DataTypes.SoapIndicatorMemory memory pf = DataTypes.SoapIndicatorMemory(
            _soapIndicatorsPayFixed.rebalanceTimestamp,
            _soapIndicatorsPayFixed.totalNotional,
            _soapIndicatorsPayFixed.averageInterestRate,
            _soapIndicatorsPayFixed.totalIbtQuantity,
            _soapIndicatorsPayFixed.quasiHypotheticalInterestCumulative
        );

        pf.rebalanceWhenClosePosition(
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
        DataTypes.IporDerivativeMemory memory swap,
        uint256 closingTimestamp
    ) internal {
        // DataTypes.TotalSoapIndicator memory tsiStorage = soapIndicators[derivativeItem.item.asset];
        DataTypes.SoapIndicatorMemory memory rf = DataTypes.SoapIndicatorMemory(
            _soapIndicatorsReceiveFixed.rebalanceTimestamp,
            _soapIndicatorsReceiveFixed.totalNotional,
            _soapIndicatorsReceiveFixed.averageInterestRate,
            _soapIndicatorsReceiveFixed.totalIbtQuantity,
            _soapIndicatorsReceiveFixed.quasiHypotheticalInterestCumulative
        );

        rf.rebalanceWhenClosePosition(
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

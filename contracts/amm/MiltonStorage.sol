// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";
import {DataTypes} from "../libraries/types/DataTypes.sol";
import "../libraries/DerivativeLogic.sol";
import "../libraries/SoapIndicatorLogic.sol";
import "../libraries/TotalSoapIndicatorLogic.sol";
import "../libraries/DerivativesView.sol";
import "../interfaces/IIporConfiguration.sol";
import "../libraries/types/DataTypes.sol";
import "../interfaces/IMiltonStorage.sol";
import "../interfaces/IIporAssetConfiguration.sol";
import "../libraries/Constants.sol";

contract MiltonStorage is Ownable, IMiltonStorage {
    //TODO: if possible move out libraries from MiltonStorage to Milton, use storage as clean storage smart contract
    using DerivativeLogic for DataTypes.IporDerivative;
    using SoapIndicatorLogic for DataTypes.SoapIndicator;
    using TotalSoapIndicatorLogic for DataTypes.TotalSoapIndicator;
    using DerivativesView for DataTypes.MiltonDerivatives;

    IIporConfiguration internal _iporConfiguration;

    mapping(address => DataTypes.MiltonTotalBalance) public balances;

    mapping(address => DataTypes.TotalSoapIndicator) public soapIndicators;

    DataTypes.MiltonDerivatives public derivatives;

    //TODO: initialization only once
    function initialize(IIporConfiguration initialIporConfiguration)
        external
        onlyOwner
    {
        _iporConfiguration = initialIporConfiguration;
    }

    //@notice add asset address to MiltonStorage structures
    function addAsset(address asset) external override onlyOwner {
        require(
            _iporConfiguration.assetSupported(asset) == 1,
            Errors.MILTON_ASSET_ADDRESS_NOT_SUPPORTED
        );

        soapIndicators[asset] = DataTypes.TotalSoapIndicator(
            DataTypes.SoapIndicator(
                0,
                DataTypes.DerivativeDirection.PayFixedReceiveFloating,
                0,
                0,
                0,
                0,
                0
            ),
            DataTypes.SoapIndicator(
                0,
                DataTypes.DerivativeDirection.PayFloatingReceiveFixed,
                0,
                0,
                0,
                0,
                0
            )
        );
    }

    function getBalance(address asset)
        external
        view
        override
        returns (DataTypes.MiltonTotalBalance memory)
    {
        return balances[asset];
    }

    function getTotalOutstandingNotional(address asset)
        external
        view
        override
        returns (uint256 payFixedTotalNotional, uint256 recFixedTotalNotional)
    {
        DataTypes.TotalSoapIndicator memory totalSoapIndicator = soapIndicators[
            asset
        ];
        payFixedTotalNotional = totalSoapIndicator.pf.totalNotional;
        recFixedTotalNotional = totalSoapIndicator.rf.totalNotional;
    }

    function getLastDerivativeId() external view override returns (uint256) {
        return derivatives.lastDerivativeId;
    }

    function addLiquidity(address asset, uint256 liquidityAmount)
        external
        override
        onlyJoseph
    {
        require(liquidityAmount > 0, Errors.MILTON_DEPOSIT_AMOUNT_TOO_LOW);
        balances[asset].liquidityPool =
            balances[asset].liquidityPool +
            liquidityAmount;
    }

    function subtractLiquidity(address asset, uint256 liquidityAmount)
        external
        override
        onlyJoseph
    {
        balances[asset].liquidityPool =
            balances[asset].liquidityPool -
            liquidityAmount;
    }

    function getDerivativeItem(uint256 derivativeId)
        external
        view
        override
        returns (DataTypes.MiltonDerivativeItem memory)
    {
        return derivatives.items[derivativeId];
    }

    function updateStorageWhenTransferPublicationFee(
        address asset,
        uint256 transferedAmount
    ) external override onlyMilton {
        balances[asset].iporPublicationFee =
            balances[asset].iporPublicationFee -
            transferedAmount;
    }

    function updateStorageWhenOpenPosition(
        DataTypes.IporDerivative memory iporDerivative
    ) external override onlyMilton {
        _updateMiltonDerivativesWhenOpenPosition(iporDerivative);
        _updateBalancesWhenOpenPosition(
            iporDerivative.asset,
            iporDerivative.direction,
            iporDerivative.collateral,
            iporDerivative.fee.openingAmount
        );
        _updateSoapIndicatorsWhenOpenPosition(iporDerivative);
    }

    function updateStorageWhenClosePosition(
        address user,
        DataTypes.MiltonDerivativeItem memory derivativeItem,
        int256 positionValue,
        uint256 closingTimestamp
    ) external override onlyMilton {
        _updateMiltonDerivativesWhenClosePosition(derivativeItem);
        _updateBalancesWhenClosePosition(
            user,
            derivativeItem,
            positionValue,
            closingTimestamp
        );
        _updateSoapIndicatorsWhenClosePosition(
            derivativeItem,
            closingTimestamp
        );
    }

    function getPositions()
        external
        view
        override
        returns (DataTypes.IporDerivative[] memory)
    {
        return derivatives.getPositions();
    }

    function getUserPositions(address user)
        external
        view
        override
        returns (DataTypes.IporDerivative[] memory)
    {
        return derivatives.getUserPositions(user);
    }

    function getDerivativeIds()
        external
        view
        override
        returns (uint256[] memory)
    {
        return derivatives.ids;
    }

    function getUserDerivativeIds(address userAddress)
        external
        view
        override
        returns (uint256[] memory)
    {
        return derivatives.userDerivativeIds[userAddress];
    }

    //TODO: separate soap to MiltonSoapModel smart contract
    function calculateSoap(
        address asset,
        uint256 ibtPrice,
        uint256 calculateTimestamp
    )
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
            asset,
            ibtPrice,
            calculateTimestamp
        );

        return (
            soapPf = AmmMath.divisionInt(
                qSoapPf,
                Constants.WAD_P2_YEAR_IN_SECONDS_INT
            ),
            soapRf = AmmMath.divisionInt(
                qSoapRf,
                Constants.WAD_P2_YEAR_IN_SECONDS_INT
            ),
            soap = AmmMath.divisionInt(
                qSoap,
                Constants.WAD_P2_YEAR_IN_SECONDS_INT
            )
        );
    }

    function _calculateQuasiSoap(
        address asset,
        uint256 ibtPrice,
        uint256 calculateTimestamp
    )
        internal
        view
        returns (
            int256 soapPf,
            int256 soapRf,
            int256 soap
        )
    {
        (int256 _soapPf, int256 _soapRf) = soapIndicators[asset]
            .calculateQuasiSoap(calculateTimestamp, ibtPrice);
        return (soapPf = _soapPf, soapRf = _soapRf, soap = _soapPf + _soapRf);
    }

    function _updateBalancesWhenOpenPosition(
        address asset,
        uint8 direction,
        uint256 collateral,
        uint256 openingFeeAmount
    ) internal {
        IIporAssetConfiguration iporAssetConfiguration = IIporAssetConfiguration(
                _iporConfiguration.getIporAssetConfiguration(asset)
            );

        if (
            direction ==
            uint8(DataTypes.DerivativeDirection.PayFixedReceiveFloating)
        ) {
            balances[asset].payFixedDerivatives =
                balances[asset].payFixedDerivatives +
                collateral;
        } else {
            balances[asset].recFixedDerivatives =
                balances[asset].recFixedDerivatives +
                collateral;
        }

        balances[asset].openingFee =
            balances[asset].openingFee +
            openingFeeAmount;
        balances[asset].liquidationDeposit =
            balances[asset].liquidationDeposit +
            iporAssetConfiguration.getLiquidationDepositAmount();
        balances[asset].iporPublicationFee =
            balances[asset].iporPublicationFee +
            iporAssetConfiguration.getIporPublicationFeeAmount();

        uint256 openingFeeForTreasurePercentage = iporAssetConfiguration
            .getOpeningFeeForTreasuryPercentage();
        (
            uint256 openingFeeLPValue,
            uint256 openingFeeTreasuryValue
        ) = _splitOpeningFeeAmount(
                openingFeeAmount,
                openingFeeForTreasurePercentage
            );
        balances[asset].liquidityPool =
            balances[asset].liquidityPool +
            openingFeeLPValue;
        balances[asset].treasury =
            balances[asset].treasury +
            openingFeeTreasuryValue;
    }

    function _splitOpeningFeeAmount(
        uint256 openingFeeAmount,
        uint256 openingFeeForTreasurePercentage
    )
        internal
        pure
        returns (uint256 liquidityPoolValue, uint256 treasuryValue)
    {
        treasuryValue = AmmMath.division(
            openingFeeAmount * openingFeeForTreasurePercentage,
            Constants.D18
        );
        liquidityPoolValue = openingFeeAmount - treasuryValue;
    }

    function _updateBalancesWhenClosePosition(
        address user,
        DataTypes.MiltonDerivativeItem memory derivativeItem,
        int256 positionValue,
        uint256 closingTimestamp
    ) internal {
        uint256 abspositionValue = AmmMath.absoluteValue(positionValue);

        //decrease from balances the liquidation deposit
        require(
            balances[derivativeItem.item.asset].liquidationDeposit >=
                derivativeItem.item.fee.liquidationDepositAmount,
            Errors
                .MILTON_CANNOT_CLOSE_DERIVATE_LIQUIDATION_DEPOSIT_BALANCE_IS_TOO_LOW
        );
        balances[derivativeItem.item.asset].liquidationDeposit =
            balances[derivativeItem.item.asset].liquidationDeposit -
            derivativeItem.item.fee.liquidationDepositAmount;

        if (
            derivativeItem.item.direction ==
            uint8(DataTypes.DerivativeDirection.PayFixedReceiveFloating)
        ) {
            balances[derivativeItem.item.asset].payFixedDerivatives =
                balances[derivativeItem.item.asset].payFixedDerivatives -
                derivativeItem.item.collateral;
        } else if (
            derivativeItem.item.direction ==
            uint8(DataTypes.DerivativeDirection.PayFloatingReceiveFixed)
        ) {
            balances[derivativeItem.item.asset].recFixedDerivatives =
                balances[derivativeItem.item.asset].recFixedDerivatives -
                derivativeItem.item.collateral;
        }

        if (abspositionValue < derivativeItem.item.collateral) {
            //verify if sender is an owner of derivative if not then check if maturity - if not then reject, if yes then close even if not an owner
            if (user != derivativeItem.item.buyer) {
                require(
                    closingTimestamp >= derivativeItem.item.endingTimestamp,
                    Errors
                        .MILTON_CANNOT_CLOSE_DERIVATE_SENDER_IS_NOT_BUYER_AND_NO_DERIVATIVE_MATURITY
                );
            }
        }

        uint256 incomeTax = AmmMath.calculateIncomeTax(
            abspositionValue,
            IIporAssetConfiguration(
                _iporConfiguration.getIporAssetConfiguration(
                    derivativeItem.item.asset
                )
            ).getIncomeTaxPercentage()
        );

        balances[derivativeItem.item.asset].treasury =
            balances[derivativeItem.item.asset].treasury +
            incomeTax;

        if (positionValue > 0) {
            require(
                balances[derivativeItem.item.asset].liquidityPool >=
                    abspositionValue,
                Errors.MILTON_CANNOT_CLOSE_DERIVATE_LIQUIDITY_POOL_IS_TOO_LOW
            );

            balances[derivativeItem.item.asset].liquidityPool =
                balances[derivativeItem.item.asset].liquidityPool -
                abspositionValue;
        } else {
            balances[derivativeItem.item.asset].liquidityPool =
                balances[derivativeItem.item.asset].liquidityPool +
                abspositionValue -
                incomeTax;
        }
    }

    function _updateMiltonDerivativesWhenOpenPosition(
        DataTypes.IporDerivative memory derivative
    ) internal {
        derivatives.items[derivative.id].item = derivative;
        derivatives.items[derivative.id].idsIndex = derivatives.ids.length;
        derivatives.items[derivative.id].userDerivativeIdsIndex = derivatives
            .userDerivativeIds[derivative.buyer]
            .length;
        derivatives.ids.push(derivative.id);
        derivatives.userDerivativeIds[derivative.buyer].push(derivative.id);
        derivatives.lastDerivativeId = derivative.id;
    }

    function _updateMiltonDerivativesWhenClosePosition(
        DataTypes.MiltonDerivativeItem memory derivativeItem
    ) internal {
        require(
            derivativeItem.item.id > 0,
            Errors.MILTON_CLOSE_POSITION_INCORRECT_DERIVATIVE_ID
        );
        require(
            derivativeItem.item.state != DataTypes.DerivativeState.INACTIVE,
            Errors.MILTON_CLOSE_POSITION_INCORRECT_DERIVATIVE_STATUS
        );
        uint256 idsIndexToDelete = derivativeItem.idsIndex;

        if (idsIndexToDelete < derivatives.ids.length - 1) {
            uint256 idsDerivativeIdToMove = derivatives.ids[
                derivatives.ids.length - 1
            ];
            derivatives
                .items[idsDerivativeIdToMove]
                .idsIndex = idsIndexToDelete;
            derivatives.ids[idsIndexToDelete] = idsDerivativeIdToMove;
        }

        uint256 userDerivativeIdsIndexToDelete = derivativeItem
            .userDerivativeIdsIndex;
        address buyer = derivativeItem.item.buyer;

        if (
            userDerivativeIdsIndexToDelete <
            derivatives.userDerivativeIds[buyer].length - 1
        ) {
            uint256 userDerivativeIdToMove = derivatives.userDerivativeIds[
                buyer
            ][derivatives.userDerivativeIds[buyer].length - 1];

            derivatives
                .items[userDerivativeIdToMove]
                .userDerivativeIdsIndex = userDerivativeIdsIndexToDelete;

            derivatives.userDerivativeIds[buyer][
                userDerivativeIdsIndexToDelete
            ] = userDerivativeIdToMove;
        }

        derivatives.items[derivativeItem.item.id].item.state = DataTypes
            .DerivativeState
            .INACTIVE;
        derivatives.ids.pop();
        derivatives.userDerivativeIds[buyer].pop();
    }

    function _updateSoapIndicatorsWhenOpenPosition(
        DataTypes.IporDerivative memory iporDerivative
    ) internal {
        DataTypes.SoapIndicator memory pf = DataTypes.SoapIndicator(
            soapIndicators[iporDerivative.asset].pf.rebalanceTimestamp,
            soapIndicators[iporDerivative.asset].pf.direction,
            soapIndicators[iporDerivative.asset]
                .pf
                .quasiHypotheticalInterestCumulative,
            soapIndicators[iporDerivative.asset].pf.totalNotional,
            soapIndicators[iporDerivative.asset].pf.averageInterestRate,
            soapIndicators[iporDerivative.asset].pf.totalIbtQuantity,
            soapIndicators[iporDerivative.asset].pf.soap
        );

        DataTypes.SoapIndicator memory rf = DataTypes.SoapIndicator(
            soapIndicators[iporDerivative.asset].rf.rebalanceTimestamp,
            soapIndicators[iporDerivative.asset].rf.direction,
            soapIndicators[iporDerivative.asset]
                .rf
                .quasiHypotheticalInterestCumulative,
            soapIndicators[iporDerivative.asset].rf.totalNotional,
            soapIndicators[iporDerivative.asset].rf.averageInterestRate,
            soapIndicators[iporDerivative.asset].rf.totalIbtQuantity,
            soapIndicators[iporDerivative.asset].rf.soap
        );

        DataTypes.TotalSoapIndicator memory tsiMem = DataTypes
            .TotalSoapIndicator(pf, rf);

        // DataTypes.TotalSoapIndicator memory tsi = soapIndicators[iporDerivative.asset];

        TotalSoapIndicatorLogic.rebalanceSoapWhenOpenPosition(
            tsiMem,
            iporDerivative.direction,
            iporDerivative.startingTimestamp,
            iporDerivative.notionalAmount,
            iporDerivative.indicator.fixedInterestRate,
            iporDerivative.indicator.ibtQuantity
        );
        //TODO: consider if it is required to rebalance both sides!
        soapIndicators[iporDerivative.asset].pf.rebalanceTimestamp = tsiMem
            .pf
            .rebalanceTimestamp;
        soapIndicators[iporDerivative.asset].pf.direction = tsiMem.pf.direction;
        soapIndicators[iporDerivative.asset]
            .pf
            .quasiHypotheticalInterestCumulative = tsiMem
            .pf
            .quasiHypotheticalInterestCumulative;
        soapIndicators[iporDerivative.asset].pf.totalNotional = tsiMem
            .pf
            .totalNotional;
        soapIndicators[iporDerivative.asset].pf.averageInterestRate = tsiMem
            .pf
            .averageInterestRate;
        soapIndicators[iporDerivative.asset].pf.totalIbtQuantity = tsiMem
            .pf
            .totalIbtQuantity;
        soapIndicators[iporDerivative.asset].pf.soap = tsiMem.pf.soap;

        soapIndicators[iporDerivative.asset].rf.rebalanceTimestamp = tsiMem
            .rf
            .rebalanceTimestamp;
        soapIndicators[iporDerivative.asset].rf.direction = tsiMem.rf.direction;
        soapIndicators[iporDerivative.asset]
            .rf
            .quasiHypotheticalInterestCumulative = tsiMem
            .rf
            .quasiHypotheticalInterestCumulative;
        soapIndicators[iporDerivative.asset].rf.totalNotional = tsiMem
            .rf
            .totalNotional;
        soapIndicators[iporDerivative.asset].rf.averageInterestRate = tsiMem
            .rf
            .averageInterestRate;
        soapIndicators[iporDerivative.asset].rf.totalIbtQuantity = tsiMem
            .rf
            .totalIbtQuantity;
        soapIndicators[iporDerivative.asset].rf.soap = tsiMem.rf.soap;
    }

    function _updateSoapIndicatorsWhenClosePosition(
        DataTypes.MiltonDerivativeItem memory derivativeItem,
        uint256 closingTimestamp
    ) internal {
        // DataTypes.TotalSoapIndicator memory tsiStorage = soapIndicators[derivativeItem.item.asset];

        DataTypes.SoapIndicator memory pf = DataTypes.SoapIndicator(
            soapIndicators[derivativeItem.item.asset].pf.rebalanceTimestamp,
            soapIndicators[derivativeItem.item.asset].pf.direction,
            soapIndicators[derivativeItem.item.asset]
                .pf
                .quasiHypotheticalInterestCumulative,
            soapIndicators[derivativeItem.item.asset].pf.totalNotional,
            soapIndicators[derivativeItem.item.asset].pf.averageInterestRate,
            soapIndicators[derivativeItem.item.asset].pf.totalIbtQuantity,
            soapIndicators[derivativeItem.item.asset].pf.soap
        );

        DataTypes.SoapIndicator memory rf = DataTypes.SoapIndicator(
            soapIndicators[derivativeItem.item.asset].rf.rebalanceTimestamp,
            soapIndicators[derivativeItem.item.asset].rf.direction,
            soapIndicators[derivativeItem.item.asset]
                .rf
                .quasiHypotheticalInterestCumulative,
            soapIndicators[derivativeItem.item.asset].rf.totalNotional,
            soapIndicators[derivativeItem.item.asset].rf.averageInterestRate,
            soapIndicators[derivativeItem.item.asset].rf.totalIbtQuantity,
            soapIndicators[derivativeItem.item.asset].rf.soap
        );

        DataTypes.TotalSoapIndicator memory tsiMem = DataTypes
            .TotalSoapIndicator(pf, rf);

        TotalSoapIndicatorLogic.rebalanceSoapWhenClosePosition(
            tsiMem,
            derivativeItem.item.direction,
            closingTimestamp,
            derivativeItem.item.startingTimestamp,
            derivativeItem.item.notionalAmount,
            derivativeItem.item.indicator.fixedInterestRate,
            derivativeItem.item.indicator.ibtQuantity
        );

        soapIndicators[derivativeItem.item.asset].pf.rebalanceTimestamp = tsiMem
            .pf
            .rebalanceTimestamp;
        soapIndicators[derivativeItem.item.asset].pf.direction = tsiMem
            .pf
            .direction;
        soapIndicators[derivativeItem.item.asset]
            .pf
            .quasiHypotheticalInterestCumulative = tsiMem
            .pf
            .quasiHypotheticalInterestCumulative;
        soapIndicators[derivativeItem.item.asset].pf.totalNotional = tsiMem
            .pf
            .totalNotional;
        soapIndicators[derivativeItem.item.asset]
            .pf
            .averageInterestRate = tsiMem.pf.averageInterestRate;
        soapIndicators[derivativeItem.item.asset].pf.totalIbtQuantity = tsiMem
            .pf
            .totalIbtQuantity;
        soapIndicators[derivativeItem.item.asset].pf.soap = tsiMem.pf.soap;

        soapIndicators[derivativeItem.item.asset].rf.rebalanceTimestamp = tsiMem
            .rf
            .rebalanceTimestamp;
        soapIndicators[derivativeItem.item.asset].rf.direction = tsiMem
            .rf
            .direction;
        soapIndicators[derivativeItem.item.asset]
            .rf
            .quasiHypotheticalInterestCumulative = tsiMem
            .rf
            .quasiHypotheticalInterestCumulative;
        soapIndicators[derivativeItem.item.asset].rf.totalNotional = tsiMem
            .rf
            .totalNotional;
        soapIndicators[derivativeItem.item.asset]
            .rf
            .averageInterestRate = tsiMem.rf.averageInterestRate;
        soapIndicators[derivativeItem.item.asset].rf.totalIbtQuantity = tsiMem
            .rf
            .totalIbtQuantity;
        soapIndicators[derivativeItem.item.asset].rf.soap = tsiMem.rf.soap;
    }

    modifier onlyMilton() {
        require(
            msg.sender == _iporConfiguration.getMilton(),
            Errors.MILTON_CALLER_NOT_MILTON
        );
        _;
    }

    modifier onlyJoseph() {
        require(
            msg.sender == _iporConfiguration.getJoseph(),
            Errors.MILTON_CALLER_NOT_JOSEPH
        );
        _;
    }
}

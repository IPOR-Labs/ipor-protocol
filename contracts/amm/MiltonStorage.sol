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
    // using TotalSoapIndicatorLogic for DataTypes.TotalSoapIndicator;
    using DerivativesView for DataTypes.MiltonDerivatives;

    uint64 private _lastSwapId;

    IIporConfiguration internal _iporConfiguration;

    mapping(address => DataTypes.MiltonTotalBalance) public balances;

    // ---
    mapping(address => DataTypes.SoapIndicator) public soapIndicatorsPayFixed;
    mapping(address => DataTypes.SoapIndicator)
        public soapIndicatorsReceiveFixed;

    DataTypes.MiltonDerivatives internal _swapsPayFixed;
    DataTypes.MiltonDerivatives internal _swapsReceiveFixed;

    constructor(address initialIporConfiguration) {
        require(
            address(initialIporConfiguration) != address(0),
            IporErrors.INCORRECT_IPOR_CONFIGURATION_ADDRESS
        );
        _iporConfiguration = IIporConfiguration(initialIporConfiguration);
    }

    //@notice add asset address to MiltonStorage structures
    function addAsset(address asset) external override onlyOwner {
        require(
            _iporConfiguration.assetSupported(asset) == 1,
            IporErrors.MILTON_ASSET_ADDRESS_NOT_SUPPORTED
        );

        soapIndicatorsPayFixed[asset] = DataTypes.SoapIndicator(0, 0, 0, 0, 0);
        soapIndicatorsReceiveFixed[asset] = DataTypes.SoapIndicator(
            0,
            0,
            0,
            0,
            0
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
        payFixedTotalNotional = soapIndicatorsPayFixed[asset].totalNotional;
        recFixedTotalNotional = soapIndicatorsReceiveFixed[asset].totalNotional;
    }

    function getLastSwapId() external view override returns (uint256) {
        return _lastSwapId;
    }

    function addLiquidity(address asset, uint256 liquidityAmount)
        external
        override
        onlyJoseph
    {
        require(liquidityAmount > 0, IporErrors.MILTON_DEPOSIT_AMOUNT_TOO_LOW);
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

    function getSwapPayFixedItem(uint256 swapId)
        external
        view
        override
        returns (DataTypes.MiltonDerivativeItem memory)
    {
        return _swapsPayFixed.items[swapId];
    }

    function getSwapReceiveFixedItem(uint256 swapId)
        external
        view
        override
        returns (DataTypes.MiltonDerivativeItem memory)
    {
        return _swapsReceiveFixed.items[swapId];
    }

    function updateStorageWhenTransferPublicationFee(
        address asset,
        uint256 transferedAmount
    ) external override onlyMilton {
        balances[asset].iporPublicationFee =
            balances[asset].iporPublicationFee -
            transferedAmount;
    }

    function updateStorageWhenOpenSwapPayFixed(
        DataTypes.IporDerivative memory iporDerivative,
        uint256 openingAmount
    ) external override onlyMilton {
        _updateSwapsWhenOpenPayFixed(iporDerivative);
        _updateBalancesWhenOpenSwapPayFixed(
            iporDerivative.asset,
            iporDerivative.collateral,
            openingAmount
        );
        _updateSoapIndicatorsWhenOpenSwapPayFixed(iporDerivative);
    }

    function updateStorageWhenOpenSwapReceiveFixed(
        DataTypes.IporDerivative memory iporDerivative,
        uint256 openingAmount
    ) external override onlyMilton {
        _updateSwapsWhenOpenReceiveFixed(iporDerivative);
        _updateBalancesWhenOpenSwapReceiveFixed(
            iporDerivative.asset,
            iporDerivative.collateral,
            openingAmount
        );
        _updateSoapIndicatorsWhenOpenSwapReceiveFixed(iporDerivative);
    }

    function updateStorageWhenCloseSwapPayFixed(
        address user,
        DataTypes.MiltonDerivativeItem memory derivativeItem,
        int256 positionValue,
        uint256 closingTimestamp
    ) external override onlyMilton {
        _updateSwapsWhenClosePayFixed(derivativeItem);
        _updateBalancesWhenCloseSwapPayFixed(
            user,
            derivativeItem,
            positionValue,
            closingTimestamp
        );
        _updateSoapIndicatorsWhenCloseSwapPayFixed(
            derivativeItem,
            closingTimestamp
        );
    }

    function updateStorageWhenCloseSwapReceiveFixed(
        address user,
        DataTypes.MiltonDerivativeItem memory derivativeItem,
        int256 positionValue,
        uint256 closingTimestamp
    ) external override onlyMilton {
        _updateSwapsWhenCloseReceiveFixed(derivativeItem);
        _updateBalancesWhenCloseSwapReceiveFixed(
            user,
            derivativeItem,
            positionValue,
            closingTimestamp
        );
        _updateSoapIndicatorsWhenCloseSwapReceiveFixed(
            derivativeItem,
            closingTimestamp
        );
    }

    function getSwapsPayFixed()
        external
        view
        override
        returns (DataTypes.IporDerivative[] memory)
    {
        return _swapsPayFixed.getPositions();
    }

    function getSwapsReceiveFixed()
        external
        view
        override
        returns (DataTypes.IporDerivative[] memory)
    {
        return _swapsReceiveFixed.getPositions();
    }

    function getUserSwapsPayFixed(address user)
        external
        view
        override
        returns (DataTypes.IporDerivative[] memory)
    {
        return _swapsPayFixed.getUserPositions(user);
    }

    function getUserSwapsReceiveFixed(address user)
        external
        view
        override
        returns (DataTypes.IporDerivative[] memory)
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
        int256 _soapPf = soapIndicatorsPayFixed[asset]
            .calculateQuasiSoapPayFixed(calculateTimestamp, ibtPrice);
        int256 _soapRf = soapIndicatorsReceiveFixed[asset]
            .calculateQuasiSoapReceiveFixed(calculateTimestamp, ibtPrice);
        return (soapPf = _soapPf, soapRf = _soapRf, soap = _soapPf + _soapRf);
    }

    function _updateBalancesWhenOpenSwapPayFixed(
        address asset,
        uint256 collateral,
        uint256 openingFeeAmount
    ) internal {
        IIporAssetConfiguration iporAssetConfiguration = IIporAssetConfiguration(
                _iporConfiguration.getIporAssetConfiguration(asset)
            );

        balances[asset].payFixedDerivatives =
            balances[asset].payFixedDerivatives +
            collateral;

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

    function _updateBalancesWhenOpenSwapReceiveFixed(
        address asset,
        uint256 collateral,
        uint256 openingFeeAmount
    ) internal {
        IIporAssetConfiguration iporAssetConfiguration = IIporAssetConfiguration(
                _iporConfiguration.getIporAssetConfiguration(asset)
            );

        balances[asset].recFixedDerivatives =
            balances[asset].recFixedDerivatives +
            collateral;

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
        treasuryValue = IporMath.division(
            openingFeeAmount * openingFeeForTreasurePercentage,
            Constants.D18
        );
        liquidityPoolValue = openingFeeAmount - treasuryValue;
    }

    function _updateBalancesWhenCloseSwapPayFixed(
        address user,
        DataTypes.MiltonDerivativeItem memory derivativeItem,
        int256 positionValue,
        uint256 closingTimestamp
    ) internal {
        uint256 abspositionValue = IporMath.absoluteValue(positionValue);

        //decrease from balances the liquidation deposit
        require(
            balances[derivativeItem.item.asset].liquidationDeposit >=
                derivativeItem.item.liquidationDepositAmount,
            IporErrors
                .MILTON_CANNOT_CLOSE_DERIVATE_LIQUIDATION_DEPOSIT_BALANCE_IS_TOO_LOW
        );
        balances[derivativeItem.item.asset].liquidationDeposit =
            balances[derivativeItem.item.asset].liquidationDeposit -
            derivativeItem.item.liquidationDepositAmount;

        balances[derivativeItem.item.asset].payFixedDerivatives =
            balances[derivativeItem.item.asset].payFixedDerivatives -
            derivativeItem.item.collateral;
        //TODO: remove duplication
        if (abspositionValue < derivativeItem.item.collateral) {
            //verify if sender is an owner of derivative if not then check if maturity - if not then reject, if yes then close even if not an owner
            if (user != derivativeItem.item.buyer) {
                require(
                    closingTimestamp >= derivativeItem.item.endingTimestamp,
                    IporErrors
                        .MILTON_CANNOT_CLOSE_DERIVATE_SENDER_IS_NOT_BUYER_AND_NO_DERIVATIVE_MATURITY
                );
            }
        }

        uint256 incomeTax = IporMath.calculateIncomeTax(
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
                IporErrors
                    .MILTON_CANNOT_CLOSE_DERIVATE_LIQUIDITY_POOL_IS_TOO_LOW
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

    function _updateBalancesWhenCloseSwapReceiveFixed(
        address user,
        DataTypes.MiltonDerivativeItem memory derivativeItem,
        int256 positionValue,
        uint256 closingTimestamp
    ) internal {
        uint256 abspositionValue = IporMath.absoluteValue(positionValue);

        //decrease from balances the liquidation deposit
        require(
            balances[derivativeItem.item.asset].liquidationDeposit >=
                derivativeItem.item.liquidationDepositAmount,
            IporErrors
                .MILTON_CANNOT_CLOSE_DERIVATE_LIQUIDATION_DEPOSIT_BALANCE_IS_TOO_LOW
        );
        balances[derivativeItem.item.asset].liquidationDeposit =
            balances[derivativeItem.item.asset].liquidationDeposit -
            derivativeItem.item.liquidationDepositAmount;

        balances[derivativeItem.item.asset].recFixedDerivatives =
            balances[derivativeItem.item.asset].recFixedDerivatives -
            derivativeItem.item.collateral;

        //TODO: remove duplication

        if (abspositionValue < derivativeItem.item.collateral) {
            //verify if sender is an owner of derivative if not then check if maturity - if not then reject, if yes then close even if not an owner
            if (user != derivativeItem.item.buyer) {
                require(
                    closingTimestamp >= derivativeItem.item.endingTimestamp,
                    IporErrors
                        .MILTON_CANNOT_CLOSE_DERIVATE_SENDER_IS_NOT_BUYER_AND_NO_DERIVATIVE_MATURITY
                );
            }
        }

        uint256 incomeTax = IporMath.calculateIncomeTax(
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
                IporErrors
                    .MILTON_CANNOT_CLOSE_DERIVATE_LIQUIDITY_POOL_IS_TOO_LOW
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

    function _updateSwapsWhenOpenPayFixed(
        DataTypes.IporDerivative memory derivative
    ) internal {
        _swapsPayFixed.items[derivative.id].item = derivative;
        _swapsPayFixed.items[derivative.id].idsIndex = _swapsPayFixed
            .ids
            .length;
        _swapsPayFixed
            .items[derivative.id]
            .userDerivativeIdsIndex = _swapsPayFixed
            .userDerivativeIds[derivative.buyer]
            .length;
        _swapsPayFixed.ids.push(derivative.id);
        _swapsPayFixed.userDerivativeIds[derivative.buyer].push(derivative.id);
        _lastSwapId = derivative.id;
    }

    function _updateSwapsWhenOpenReceiveFixed(
        DataTypes.IporDerivative memory derivative
    ) internal {
        _swapsReceiveFixed.items[derivative.id].item = derivative;
        _swapsReceiveFixed.items[derivative.id].idsIndex = _swapsReceiveFixed
            .ids
            .length;
        _swapsReceiveFixed
            .items[derivative.id]
            .userDerivativeIdsIndex = _swapsReceiveFixed
            .userDerivativeIds[derivative.buyer]
            .length;
        _swapsReceiveFixed.ids.push(derivative.id);
        _swapsReceiveFixed.userDerivativeIds[derivative.buyer].push(
            derivative.id
        );
        _lastSwapId = derivative.id;
    }

    function _updateSwapsWhenClosePayFixed(
        DataTypes.MiltonDerivativeItem memory derivativeItem
    ) internal {
        require(
            derivativeItem.item.id > 0,
            IporErrors.MILTON_CLOSE_POSITION_INCORRECT_DERIVATIVE_ID
        );
        require(
            derivativeItem.item.state != DataTypes.DerivativeState.INACTIVE,
            IporErrors.MILTON_CLOSE_POSITION_INCORRECT_DERIVATIVE_STATUS
        );
        uint256 idsIndexToDelete = derivativeItem.idsIndex;

        if (idsIndexToDelete < _swapsPayFixed.ids.length - 1) {
            uint256 idsDerivativeIdToMove = _swapsPayFixed.ids[
                _swapsPayFixed.ids.length - 1
            ];
            _swapsPayFixed
                .items[idsDerivativeIdToMove]
                .idsIndex = idsIndexToDelete;
            _swapsPayFixed.ids[idsIndexToDelete] = idsDerivativeIdToMove;
        }

        uint256 userDerivativeIdsIndexToDelete = derivativeItem
            .userDerivativeIdsIndex;
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

        _swapsPayFixed.items[derivativeItem.item.id].item.state = DataTypes
            .DerivativeState
            .INACTIVE;
        _swapsPayFixed.ids.pop();
        _swapsPayFixed.userDerivativeIds[buyer].pop();
    }

    function _updateSwapsWhenCloseReceiveFixed(
        DataTypes.MiltonDerivativeItem memory derivativeItem
    ) internal {
        require(
            derivativeItem.item.id > 0,
            IporErrors.MILTON_CLOSE_POSITION_INCORRECT_DERIVATIVE_ID
        );
        require(
            derivativeItem.item.state != DataTypes.DerivativeState.INACTIVE,
            IporErrors.MILTON_CLOSE_POSITION_INCORRECT_DERIVATIVE_STATUS
        );
        uint256 idsIndexToDelete = derivativeItem.idsIndex;

        if (idsIndexToDelete < _swapsReceiveFixed.ids.length - 1) {
            uint256 idsDerivativeIdToMove = _swapsReceiveFixed.ids[
                _swapsReceiveFixed.ids.length - 1
            ];
            _swapsReceiveFixed
                .items[idsDerivativeIdToMove]
                .idsIndex = idsIndexToDelete;
            _swapsReceiveFixed.ids[idsIndexToDelete] = idsDerivativeIdToMove;
        }

        uint256 userDerivativeIdsIndexToDelete = derivativeItem
            .userDerivativeIdsIndex;
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

        _swapsReceiveFixed.items[derivativeItem.item.id].item.state = DataTypes
            .DerivativeState
            .INACTIVE;
        _swapsReceiveFixed.ids.pop();
        _swapsReceiveFixed.userDerivativeIds[buyer].pop();
    }

    function _updateSoapIndicatorsWhenOpenSwapPayFixed(
        DataTypes.IporDerivative memory iporDerivative
    ) internal {
        DataTypes.SoapIndicator memory pf = DataTypes.SoapIndicator(
            soapIndicatorsPayFixed[iporDerivative.asset].rebalanceTimestamp,            
            soapIndicatorsPayFixed[iporDerivative.asset].totalNotional,
            soapIndicatorsPayFixed[iporDerivative.asset].averageInterestRate,
            soapIndicatorsPayFixed[iporDerivative.asset].totalIbtQuantity,
			soapIndicatorsPayFixed[iporDerivative.asset]
                .quasiHypotheticalInterestCumulative
        );
        pf.rebalanceWhenOpenPosition(
            iporDerivative.startingTimestamp,
            iporDerivative.notionalAmount,
            iporDerivative.fixedInterestRate,
            iporDerivative.ibtQuantity
        );
        soapIndicatorsPayFixed[iporDerivative.asset].rebalanceTimestamp = pf
            .rebalanceTimestamp;
        soapIndicatorsPayFixed[iporDerivative.asset]
            .quasiHypotheticalInterestCumulative = pf
            .quasiHypotheticalInterestCumulative;
        soapIndicatorsPayFixed[iporDerivative.asset].totalNotional = pf
            .totalNotional;
        soapIndicatorsPayFixed[iporDerivative.asset].averageInterestRate = pf
            .averageInterestRate;
        soapIndicatorsPayFixed[iporDerivative.asset].totalIbtQuantity = pf
            .totalIbtQuantity;
    }

    function _updateSoapIndicatorsWhenOpenSwapReceiveFixed(
        DataTypes.IporDerivative memory iporDerivative
    ) internal {
        DataTypes.SoapIndicator memory rf = DataTypes.SoapIndicator(
            soapIndicatorsReceiveFixed[iporDerivative.asset].rebalanceTimestamp,            
            soapIndicatorsReceiveFixed[iporDerivative.asset].totalNotional,
            soapIndicatorsReceiveFixed[iporDerivative.asset]
                .averageInterestRate,
            soapIndicatorsReceiveFixed[iporDerivative.asset].totalIbtQuantity,
			soapIndicatorsReceiveFixed[iporDerivative.asset]
                .quasiHypotheticalInterestCumulative
        );
        rf.rebalanceWhenOpenPosition(
            iporDerivative.startingTimestamp,
            iporDerivative.notionalAmount,
            iporDerivative.fixedInterestRate,
            iporDerivative.ibtQuantity
        );

        soapIndicatorsReceiveFixed[iporDerivative.asset].rebalanceTimestamp = rf
            .rebalanceTimestamp;
        soapIndicatorsReceiveFixed[iporDerivative.asset]
            .quasiHypotheticalInterestCumulative = rf
            .quasiHypotheticalInterestCumulative;
        soapIndicatorsReceiveFixed[iporDerivative.asset].totalNotional = rf
            .totalNotional;
        soapIndicatorsReceiveFixed[iporDerivative.asset]
            .averageInterestRate = rf.averageInterestRate;
        soapIndicatorsReceiveFixed[iporDerivative.asset].totalIbtQuantity = rf
            .totalIbtQuantity;
    }

    function _updateSoapIndicatorsWhenCloseSwapPayFixed(
        DataTypes.MiltonDerivativeItem memory derivativeItem,
        uint256 closingTimestamp
    ) internal {
		//TODO: add SoapIndicator with uint256 and without uint256
        DataTypes.SoapIndicator memory pf = DataTypes.SoapIndicator(
            soapIndicatorsPayFixed[derivativeItem.item.asset]
                .rebalanceTimestamp,            
            soapIndicatorsPayFixed[derivativeItem.item.asset].totalNotional,
            soapIndicatorsPayFixed[derivativeItem.item.asset]
                .averageInterestRate,
            soapIndicatorsPayFixed[derivativeItem.item.asset].totalIbtQuantity,
			soapIndicatorsPayFixed[derivativeItem.item.asset]
                .quasiHypotheticalInterestCumulative
        );

        pf.rebalanceWhenClosePosition(
            closingTimestamp,
            derivativeItem.item.startingTimestamp,
            derivativeItem.item.notionalAmount,
            derivativeItem.item.fixedInterestRate,
            derivativeItem.item.ibtQuantity
        );

        soapIndicatorsPayFixed[derivativeItem.item.asset]
            .rebalanceTimestamp = pf.rebalanceTimestamp;
        soapIndicatorsPayFixed[derivativeItem.item.asset]
            .quasiHypotheticalInterestCumulative = pf
            .quasiHypotheticalInterestCumulative;
        soapIndicatorsPayFixed[derivativeItem.item.asset].totalNotional = pf
            .totalNotional;
        soapIndicatorsPayFixed[derivativeItem.item.asset]
            .averageInterestRate = pf.averageInterestRate;
        soapIndicatorsPayFixed[derivativeItem.item.asset].totalIbtQuantity = pf
            .totalIbtQuantity;
    }

    function _updateSoapIndicatorsWhenCloseSwapReceiveFixed(
        DataTypes.MiltonDerivativeItem memory derivativeItem,
        uint256 closingTimestamp
    ) internal {
        // DataTypes.TotalSoapIndicator memory tsiStorage = soapIndicators[derivativeItem.item.asset];
		//TODO: add SoapIndicator with uint256 and without uint256
        DataTypes.SoapIndicator memory rf = DataTypes.SoapIndicator(
            soapIndicatorsReceiveFixed[derivativeItem.item.asset]
                .rebalanceTimestamp,            
            soapIndicatorsReceiveFixed[derivativeItem.item.asset].totalNotional,
            soapIndicatorsReceiveFixed[derivativeItem.item.asset]
                .averageInterestRate,
            soapIndicatorsReceiveFixed[derivativeItem.item.asset]
                .totalIbtQuantity,
			soapIndicatorsReceiveFixed[derivativeItem.item.asset]
                .quasiHypotheticalInterestCumulative
        );

        rf.rebalanceWhenClosePosition(
            closingTimestamp,
            derivativeItem.item.startingTimestamp,
            derivativeItem.item.notionalAmount,
            derivativeItem.item.fixedInterestRate,
            derivativeItem.item.ibtQuantity
        );

        soapIndicatorsReceiveFixed[derivativeItem.item.asset]
            .rebalanceTimestamp = rf.rebalanceTimestamp;

        soapIndicatorsReceiveFixed[derivativeItem.item.asset]
            .quasiHypotheticalInterestCumulative = rf
            .quasiHypotheticalInterestCumulative;
        soapIndicatorsReceiveFixed[derivativeItem.item.asset].totalNotional = rf
            .totalNotional;
        soapIndicatorsReceiveFixed[derivativeItem.item.asset]
            .averageInterestRate = rf.averageInterestRate;
        soapIndicatorsReceiveFixed[derivativeItem.item.asset]
            .totalIbtQuantity = rf.totalIbtQuantity;
    }

    modifier onlyMilton() {
        require(
            msg.sender == _iporConfiguration.getMilton(),
            IporErrors.MILTON_CALLER_NOT_MILTON
        );
        _;
    }

    modifier onlyJoseph() {
        require(
            msg.sender == _iporConfiguration.getJoseph(),
            IporErrors.MILTON_CALLER_NOT_JOSEPH
        );
        _;
    }
}

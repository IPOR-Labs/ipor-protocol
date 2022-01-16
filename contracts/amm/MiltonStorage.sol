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
    using DerivativeLogic for DataTypes.IporDerivativeMemory;
    using SoapIndicatorLogic for DataTypes.SoapIndicator;
    // using TotalSoapIndicatorLogic for DataTypes.TotalSoapIndicator;
    using DerivativesView for DataTypes.MiltonDerivativesStorage;

    uint64 private _lastSwapId;

    IIporConfiguration internal _iporConfiguration;

    mapping(address => DataTypes.MiltonTotalBalanceStorage) public balances;

    // ---
    mapping(address => DataTypes.SoapIndicator) public soapIndicatorsPayFixed;
    mapping(address => DataTypes.SoapIndicator)
        public soapIndicatorsReceiveFixed;

    DataTypes.MiltonDerivativesStorage internal _swapsPayFixed;
    DataTypes.MiltonDerivativesStorage internal _swapsReceiveFixed;

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
        returns (DataTypes.MiltonTotalBalanceMemory memory)
    {
		DataTypes.MiltonTotalBalanceStorage memory balancesStorage = balances[asset];
		return DataTypes.MiltonTotalBalanceMemory(		
			uint256(balancesStorage.payFixedDerivatives),        
			uint256(balancesStorage.recFixedDerivatives),
			uint256(balancesStorage.openingFee),
			uint256(balancesStorage.liquidationDeposit),
			uint256(balancesStorage.iporPublicationFee),        
			uint256(balancesStorage.liquidityPool),        
			uint256(balancesStorage.treasury)
		);

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
            uint128(liquidityAmount);
    }

    function subtractLiquidity(address asset, uint256 liquidityAmount)
        external
        override
        onlyJoseph
    {
        balances[asset].liquidityPool =
            balances[asset].liquidityPool -
            uint128(liquidityAmount);
    }

    function getSwapPayFixedItem(uint256 swapId)
        external
        view
        override
        returns (DataTypes.MiltonDerivativeItemMemory memory)
    {
        return DataTypes.MiltonDerivativeItemMemory(
			DataTypes.IporDerivativeMemory(
				uint256(_swapsPayFixed.items[swapId].item.state),
				_swapsPayFixed.items[swapId].item.buyer,
				_swapsPayFixed.items[swapId].item.asset,
				_swapsPayFixed.items[swapId].item.startingTimestamp,
				_swapsPayFixed.items[swapId].item.endingTimestamp,
				_swapsPayFixed.items[swapId].item.id,
				_swapsPayFixed.items[swapId].item.collateral,
				_swapsPayFixed.items[swapId].item.liquidationDepositAmount,
				_swapsPayFixed.items[swapId].item.notionalAmount,
				_swapsPayFixed.items[swapId].item.fixedInterestRate,
				_swapsPayFixed.items[swapId].item.ibtQuantity
			),
			_swapsPayFixed.items[swapId].idsIndex,
			_swapsPayFixed.items[swapId].userDerivativeIdsIndex
		);
    }

    function getSwapReceiveFixedItem(uint256 swapId)
        external
        view
        override
        returns (DataTypes.MiltonDerivativeItemMemory memory)
    {
		return DataTypes.MiltonDerivativeItemMemory(
			DataTypes.IporDerivativeMemory(
				uint256(_swapsReceiveFixed.items[swapId].item.state),
				_swapsReceiveFixed.items[swapId].item.buyer,
				_swapsReceiveFixed.items[swapId].item.asset,
				_swapsReceiveFixed.items[swapId].item.startingTimestamp,
				_swapsReceiveFixed.items[swapId].item.endingTimestamp,
				_swapsReceiveFixed.items[swapId].item.id,
				_swapsReceiveFixed.items[swapId].item.collateral,
				_swapsReceiveFixed.items[swapId].item.liquidationDepositAmount,
				_swapsReceiveFixed.items[swapId].item.notionalAmount,
				_swapsReceiveFixed.items[swapId].item.fixedInterestRate,
				_swapsReceiveFixed.items[swapId].item.ibtQuantity
			),
			_swapsReceiveFixed.items[swapId].idsIndex,
			_swapsReceiveFixed.items[swapId].userDerivativeIdsIndex
		);
    }

    function updateStorageWhenTransferPublicationFee(
        address asset,
        uint256 transferedAmount
    ) external override onlyMilton {
        balances[asset].iporPublicationFee =
            balances[asset].iporPublicationFee -
            uint128(transferedAmount);
    }

    function updateStorageWhenOpenSwapPayFixed(
        DataTypes.IporDerivativeMemory memory iporDerivative,
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
        DataTypes.IporDerivativeMemory memory iporDerivative,
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
            derivativeItem,
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
            derivativeItem,
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
            uint128(collateral);

        balances[asset].openingFee =
            balances[asset].openingFee +
            uint128(openingFeeAmount);
        balances[asset].liquidationDeposit =
            balances[asset].liquidationDeposit +
            uint128(iporAssetConfiguration.getLiquidationDepositAmount());
        balances[asset].iporPublicationFee =
            balances[asset].iporPublicationFee +
            uint128(iporAssetConfiguration.getIporPublicationFeeAmount());

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
            uint128(openingFeeLPValue);
        balances[asset].treasury =
            balances[asset].treasury +
            uint128(openingFeeTreasuryValue);
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
            uint128(collateral);

        balances[asset].openingFee =
            balances[asset].openingFee +
            uint128(openingFeeAmount);
        balances[asset].liquidationDeposit =
            balances[asset].liquidationDeposit +
			uint128( iporAssetConfiguration.getLiquidationDepositAmount());
        balances[asset].iporPublicationFee =
            balances[asset].iporPublicationFee +
            uint128(iporAssetConfiguration.getIporPublicationFeeAmount());

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
            uint128(openingFeeLPValue);
        balances[asset].treasury =
            balances[asset].treasury +
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
            balances[swap.asset].liquidationDeposit >=
			swap.liquidationDepositAmount,
            IporErrors
                .MILTON_CANNOT_CLOSE_DERIVATE_LIQUIDATION_DEPOSIT_BALANCE_IS_TOO_LOW
        );
        balances[swap.asset].liquidationDeposit =
            balances[swap.asset].liquidationDeposit -
            uint128(swap.liquidationDepositAmount);

        balances[swap.asset].payFixedDerivatives =
            balances[swap.asset].payFixedDerivatives -
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
            IIporAssetConfiguration(
                _iporConfiguration.getIporAssetConfiguration(
                    swap.asset
                )
            ).getIncomeTaxPercentage()
        );

        balances[swap.asset].treasury =
            balances[swap.asset].treasury +
            uint128(incomeTax);

        if (positionValue > 0) {
            require(
                balances[swap.asset].liquidityPool >=
                    abspositionValue,
                IporErrors
                    .MILTON_CANNOT_CLOSE_DERIVATE_LIQUIDITY_POOL_IS_TOO_LOW
            );

            balances[swap.asset].liquidityPool =
                balances[swap.asset].liquidityPool -
                uint128(abspositionValue);
        } else {
            balances[swap.asset].liquidityPool =
                balances[swap.asset].liquidityPool +
                uint128(abspositionValue -
                incomeTax);
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
            balances[swap.asset].liquidationDeposit >=
			swap.liquidationDepositAmount,
            IporErrors
                .MILTON_CANNOT_CLOSE_DERIVATE_LIQUIDATION_DEPOSIT_BALANCE_IS_TOO_LOW
        );
        balances[swap.asset].liquidationDeposit =
            balances[swap.asset].liquidationDeposit -
            uint128(swap.liquidationDepositAmount);

        balances[swap.asset].recFixedDerivatives =
            balances[swap.asset].recFixedDerivatives -
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
            IIporAssetConfiguration(
                _iporConfiguration.getIporAssetConfiguration(
                    swap.asset
                )
            ).getIncomeTaxPercentage()
        );

        balances[swap.asset].treasury =
            balances[swap.asset].treasury +
            uint128(incomeTax);

        if (positionValue > 0) {
            require(
                balances[swap.asset].liquidityPool >=
                    abspositionValue,
                IporErrors
                    .MILTON_CANNOT_CLOSE_DERIVATE_LIQUIDITY_POOL_IS_TOO_LOW
            );

            balances[swap.asset].liquidityPool =
                balances[swap.asset].liquidityPool -
                uint128(abspositionValue);
        } else {
            balances[swap.asset].liquidityPool =
                balances[swap.asset].liquidityPool +
                uint128(abspositionValue -
                incomeTax);
        }
    }

    function _updateSwapsWhenOpenPayFixed(
        DataTypes.IporDerivativeMemory memory derivative
    ) internal {
		_swapsPayFixed.items[derivative.id].item.state = DataTypes.DerivativeState(derivative.state);
		_swapsPayFixed.items[derivative.id].item.buyer = derivative.buyer;
		_swapsPayFixed.items[derivative.id].item.asset = derivative.asset;
		_swapsPayFixed.items[derivative.id].item.startingTimestamp = uint32(derivative.startingTimestamp);
		_swapsPayFixed.items[derivative.id].item.endingTimestamp = uint32(derivative.endingTimestamp);
		_swapsPayFixed.items[derivative.id].item.id = uint64(derivative.id);		
        _swapsPayFixed.items[derivative.id].item.collateral = uint128(derivative.collateral);
		_swapsPayFixed.items[derivative.id].item.liquidationDepositAmount = uint128(derivative.liquidationDepositAmount);
		_swapsPayFixed.items[derivative.id].item.notionalAmount = uint128(derivative.notionalAmount);
		_swapsPayFixed.items[derivative.id].item.fixedInterestRate = uint128(derivative.fixedInterestRate);
		_swapsPayFixed.items[derivative.id].item.ibtQuantity = uint128(derivative.ibtQuantity);



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
        _lastSwapId = uint64(derivative.id);
    }

    function _updateSwapsWhenOpenReceiveFixed(
        DataTypes.IporDerivativeMemory memory derivative
    ) internal {
		_swapsReceiveFixed.items[derivative.id].item.state = DataTypes.DerivativeState(derivative.state);
		_swapsReceiveFixed.items[derivative.id].item.buyer = derivative.buyer;
		_swapsReceiveFixed.items[derivative.id].item.asset = derivative.asset;
		_swapsReceiveFixed.items[derivative.id].item.startingTimestamp = uint32(derivative.startingTimestamp);
		_swapsReceiveFixed.items[derivative.id].item.endingTimestamp = uint32(derivative.endingTimestamp);
		_swapsReceiveFixed.items[derivative.id].item.id = uint64(derivative.id);		
        _swapsReceiveFixed.items[derivative.id].item.collateral = uint128(derivative.collateral);
		_swapsReceiveFixed.items[derivative.id].item.liquidationDepositAmount = uint128(derivative.liquidationDepositAmount);
		_swapsReceiveFixed.items[derivative.id].item.notionalAmount = uint128(derivative.notionalAmount);
		_swapsReceiveFixed.items[derivative.id].item.fixedInterestRate = uint128(derivative.fixedInterestRate);
		_swapsReceiveFixed.items[derivative.id].item.ibtQuantity = uint128(derivative.ibtQuantity);

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
        _lastSwapId = uint64(derivative.id);
    }

    function _updateSwapsWhenClosePayFixed(
        DataTypes.MiltonDerivativeItemMemory memory derivativeItem
    ) internal {
        require(
            derivativeItem.item.id > 0,
            IporErrors.MILTON_CLOSE_POSITION_INCORRECT_DERIVATIVE_ID
        );
        require(
            derivativeItem.item.state != uint256(DataTypes.DerivativeState.INACTIVE),
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
        DataTypes.MiltonDerivativeItemMemory memory derivativeItem
    ) internal {
        require(
            derivativeItem.item.id > 0,
            IporErrors.MILTON_CLOSE_POSITION_INCORRECT_DERIVATIVE_ID
        );
        require(
            derivativeItem.item.state != uint256(DataTypes.DerivativeState.INACTIVE),
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
        DataTypes.IporDerivativeMemory memory iporDerivative
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
        DataTypes.IporDerivativeMemory memory iporDerivative
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
        DataTypes.MiltonDerivativeItemMemory memory derivativeItem,
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
        DataTypes.MiltonDerivativeItemMemory memory derivativeItem,
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

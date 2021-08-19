// SPDX-License-Identifier: agpl-3.0
pragma solidity >=0.8.4 <0.9.0;

import "../libraries/types/DataTypes.sol";
import "../libraries/DerivativeLogic.sol";
import "../libraries/AmmMath.sol";
import '@openzeppelin/contracts/token/ERC20/IERC20.sol';
//TODO: clarify if better is to have external libraries in local folder - pros for local folder - can execute Mythril and Karl static analisys
import '@openzeppelin/contracts/access/Ownable.sol';
import {Errors} from '../Errors.sol';
import {DataTypes} from '../libraries/types/DataTypes.sol';
import "../interfaces/IWarren.sol";
import './MiltonStorage.sol';
import './MiltonEvents.sol';
import "../libraries/SoapIndicatorLogic.sol";
import "../libraries/TotalSoapIndicatorLogic.sol";
import "../libraries/DerivativesView.sol";
import "../libraries/SpreadIndicatorLogic.sol";
import "../interfaces/IMiltonConfiguration.sol";

//TODO: Ownable here - consider add admin address to MiltonAddressesManager and here use custom modifier onlyOwner which checks if sender is an admin
contract MiltonConfiguration is Ownable, IMiltonConfiguration {

    uint256 incomeTaxPercentage;
    uint256 maxIncomeTaxPercentage;

    uint256 liquidationDepositFeeAmount;
    uint256 maxLiquidationDepositFeeAmount;

    uint256 openingFeePercentage;
    uint256 maxOpeningFeePercentage;

    uint256 iporPublicationFeeAmount;
    uint256 maxIporPublicationFeeAmount;

    uint256 liquidityPoolMaxUtilizationPercentage;

    //this treasurer manage ipor publication fee balance, key is an asset
    mapping(string => address) charlieTreasurers;

    //this treasurer manage opening fee balance, key is an asset
    mapping(string => address) treasureTreasurers;

    constructor() {
        incomeTaxPercentage = 0;
        maxIncomeTaxPercentage = 2e17;

        liquidationDepositFeeAmount = 20 * 1e18;
        //TODO: clarify this value:
        maxLiquidationDepositFeeAmount = 100 * 1e18;

        openingFeePercentage = 1e16;
        maxOpeningFeePercentage = 1e18;

        iporPublicationFeeAmount = 10 * 1e18;
        maxIporPublicationFeeAmount = 1000 * 1e18;

        liquidityPoolMaxUtilizationPercentage = 8 * 1e17;

    }

    function getIncomeTaxPercentage() external override view returns (uint256) {
        return incomeTaxPercentage;
    }

    function setIncomeTaxPercentage(uint256 _incomeTaxPercentage) external override onlyOwner {
        require(_incomeTaxPercentage <= maxIncomeTaxPercentage, Errors.AMM_CONFIG_MAX_VALUE_EXCEEDED);
        incomeTaxPercentage = _incomeTaxPercentage;
        emit IncomeTaxPercentageSet(_incomeTaxPercentage);
    }

    function getMaxIncomeTaxPercentage() external override view returns (uint256) {
        return maxIncomeTaxPercentage;
    }

    function setMaxIncomeTaxPercentage(uint256 _maxIncomeTaxPercentage) external override onlyOwner {
        require(_maxIncomeTaxPercentage <= 1e18, Errors.AMM_CONFIG_MAX_VALUE_EXCEEDED);
        maxIncomeTaxPercentage = _maxIncomeTaxPercentage;
        emit MaxIncomeTaxPercentageSet(_maxIncomeTaxPercentage);
    }

    function getLiquidationDepositFeeAmount() external override view returns (uint256) {
        return liquidationDepositFeeAmount;
    }

    function setLiquidationDepositFeeAmount(uint256 _liquidationDepositFeeAmount) external override onlyOwner {
        require(_liquidationDepositFeeAmount <= maxLiquidationDepositFeeAmount, Errors.AMM_CONFIG_MAX_VALUE_EXCEEDED);
        liquidationDepositFeeAmount = _liquidationDepositFeeAmount;
        emit LiquidationDepositFeeAmountSet(_liquidationDepositFeeAmount);
    }

    function getMaxLiquidationDepositFeeAmount() external override view returns (uint256) {
        return maxLiquidationDepositFeeAmount;
    }

    function setMaxLiquidationDepositFeeAmount(uint256 _maxLiquidationDepositFeeAmount) external override onlyOwner {
        maxLiquidationDepositFeeAmount = _maxLiquidationDepositFeeAmount;
        emit MaxLiquidationDepositFeeAmountSet(_maxLiquidationDepositFeeAmount);
    }

    function getOpeningFeePercentage() external override view returns (uint256) {
        return openingFeePercentage;
    }

    function setOpeningFeePercentage(uint256 _openingFeePercentage) external override onlyOwner {
        require(_openingFeePercentage <= maxOpeningFeePercentage, Errors.AMM_CONFIG_MAX_VALUE_EXCEEDED);
        openingFeePercentage = _openingFeePercentage;
        emit OpeningFeePercentageSet(_openingFeePercentage);
    }

    function getMaxOpeningFeePercentage() external override view returns (uint256) {
        return maxOpeningFeePercentage;
    }

    function setMaxOpeningFeePercentage(uint256 _maxOpeningFeePercentage) external override onlyOwner {
        require(_maxOpeningFeePercentage <= 1e18, Errors.AMM_CONFIG_MAX_VALUE_EXCEEDED);
        maxOpeningFeePercentage = _maxOpeningFeePercentage;
        emit MaxOpeningFeePercentageSet(_maxOpeningFeePercentage);
    }

    function getIporPublicationFeeAmount() external override view returns (uint256) {
        return iporPublicationFeeAmount;
    }

    function setIporPublicationFeeAmount(uint256 _iporPublicationFeeAmount) external override onlyOwner {
        require(_iporPublicationFeeAmount <= maxIporPublicationFeeAmount, Errors.AMM_CONFIG_MAX_VALUE_EXCEEDED);
        iporPublicationFeeAmount = _iporPublicationFeeAmount;
        emit IporPublicationFeeAmountSet(_iporPublicationFeeAmount);
    }

    function getMaxIporPublicationFeeAmount() external override view returns (uint256) {
        return maxIporPublicationFeeAmount;
    }

    function setMaxIporPublicationFeeAmount(uint256 _maxIporPublicationFeeAmount) external override onlyOwner {
        maxIporPublicationFeeAmount = _maxIporPublicationFeeAmount;
        emit MaxIporPublicationFeeAmountSet(_maxIporPublicationFeeAmount);
    }

    function getCharlieTreasurer(string memory asset) external override view returns (address) {
        return charlieTreasurers[asset];
    }

    function setCharlieTreasurer(string memory asset, address _charlieTreasurer) external override onlyOwner {
        charlieTreasurers[asset] = _charlieTreasurer;
        emit CharlieTreasurerSet(asset, _charlieTreasurer);
    }

    function getTreasureTreasurer(string memory asset) external override view returns (address) {
        return treasureTreasurers[asset];
    }

    function setTreasureTreasurer(string memory asset, address _treasureTreasurer) external override onlyOwner {
        treasureTreasurers[asset] = _treasureTreasurer;
        emit TreasureTreasurerSet(asset, _treasureTreasurer);
    }

    function getLiquidityPoolMaxUtilizationPercentage() external override view returns (uint256) {
        return liquidityPoolMaxUtilizationPercentage;
    }

    function setLiquidityPoolMaxUtilizationPercentage(uint256 _liquidityPoolMaxUtilizationPercentage) external override onlyOwner {
        require(_liquidityPoolMaxUtilizationPercentage <= 1e18, Errors.AMM_CONFIG_MAX_VALUE_EXCEEDED);
        liquidityPoolMaxUtilizationPercentage = _liquidityPoolMaxUtilizationPercentage;
        emit LiquidityPoolMaxUtilizationPercentageSet(_liquidityPoolMaxUtilizationPercentage);
    }
}
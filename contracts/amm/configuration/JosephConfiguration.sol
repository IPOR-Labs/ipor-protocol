// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.9;

import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "../../libraries/errors/JosephErrors.sol";
import "../../interfaces/IIpToken.sol";
import "../../interfaces/IJosephConfiguration.sol";
import "../../interfaces/IMilton.sol";
import "../../interfaces/IMiltonStorage.sol";
import "../../interfaces/IStanley.sol";
import "../../security/IporOwnableUpgradeable.sol";

abstract contract JosephConfiguration is
    PausableUpgradeable,
    IporOwnableUpgradeable,
    IJosephConfiguration
{
    uint256 internal constant _REDEEM_FEE_PERCENTAGE = 5e15;
    uint256 internal constant _REDEEM_LP_MAX_UTILIZATION_PERCENTAGE = 1e18;
    uint256 internal constant _MILTON_STANLEY_BALANCE_PERCENTAGE = 85e15;

    address internal _asset;
    IIpToken internal _ipToken;
    IMilton internal _milton;
    IMiltonStorage internal _miltonStorage;
    IStanley internal _stanley;

    address internal _charlieTreasurer;
    address internal _treasureTreasurer;
    address internal _publicationFeeTransferer;
    address internal _treasureTransferer;

    function getCharlieTreasurer() external view override returns (address) {
        return _charlieTreasurer;
    }

    function setCharlieTreasurer(address newCharlieTreasurer)
        external
        override
        onlyOwner
        whenNotPaused
    {
        require(newCharlieTreasurer != address(0), JosephErrors.INCORRECT_CHARLIE_TREASURER);
        _charlieTreasurer = newCharlieTreasurer;
        emit CharlieTreasurerUpdated(_asset, newCharlieTreasurer);
    }

    function getTreasureTreasurer() external view override returns (address) {
        return _treasureTreasurer;
    }

    function setTreasureTreasurer(address newTreasureTreasurer)
        external
        override
        onlyOwner
        whenNotPaused
    {
        require(newTreasureTreasurer != address(0), IporErrors.WRONG_ADDRESS);
        _treasureTreasurer = newTreasureTreasurer;
        emit TreasureTreasurerUpdated(_asset, newTreasureTreasurer);
    }

    function getPublicationFeeTransferer() external view override returns (address) {
        return _publicationFeeTransferer;
    }

    function setPublicationFeeTransferer(address publicationFeeTransferer)
        external
        override
        onlyOwner
        whenNotPaused
    {
        require(address(0) != publicationFeeTransferer, IporErrors.WRONG_ADDRESS);
        _publicationFeeTransferer = publicationFeeTransferer;
        emit PublicationFeeTransfererUpdated(publicationFeeTransferer);
    }

    function getTreasureTransferer() external view override returns (address) {
        return _treasureTransferer;
    }

    function setTreasureTransferer(address treasureTransferer)
        external
        override
        onlyOwner
        whenNotPaused
    {
        require(address(0) != treasureTransferer, IporErrors.WRONG_ADDRESS);
        _treasureTransferer = treasureTransferer;
        emit TreasureTransfererUpdated(treasureTransferer);
    }

    function getRedeemFeePercentage() external pure override returns (uint256) {
        return _getRedeemFeePercentage();
    }

    function getRedeemLpMaxUtilizationPercentage() external pure override returns (uint256) {
        return _getRedeemLpMaxUtilizationPercentage();
    }

    function getMiltonStanleyBalancePercentage() external pure override returns (uint256) {
        return _getMiltonStanleyBalancePercentage();
    }

    function _getDecimals() internal pure virtual returns (uint256);

    function asset() external view override returns (address) {
        return _asset;
    }

    function _getRedeemFeePercentage() internal pure virtual returns (uint256) {
        return _REDEEM_FEE_PERCENTAGE;
    }

    function _getRedeemLpMaxUtilizationPercentage() internal pure virtual returns (uint256) {
        return _REDEEM_LP_MAX_UTILIZATION_PERCENTAGE;
    }

    function _getMiltonStanleyBalancePercentage() internal pure virtual returns (uint256) {
        return _MILTON_STANLEY_BALANCE_PERCENTAGE;
    }
}

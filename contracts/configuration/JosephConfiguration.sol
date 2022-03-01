// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.9;

import "../interfaces/IJosephConfiguration.sol";
import "../interfaces/IIpToken.sol";
import "../interfaces/IMilton.sol";
import "../interfaces/IMiltonStorage.sol";
import "../interfaces/IIporVault.sol";
import "../security/IporOwnableUpgradeable.sol";

contract JosephConfiguration is IporOwnableUpgradeable, IJosephConfiguration {
    uint256 internal constant _REDEEM_LP_MAX_UTILIZATION_PERCENTAGE = 1e18;
    uint256 internal constant _MILTON_STANLEY_BALANCE_PERCENTAGE = 85e15;

    uint8 internal _decimals;
    address internal _asset;
    IIpToken internal _ipToken;
    IMilton internal _milton;
    IMiltonStorage internal _miltonStorage;
    IIporVault internal _iporVault;

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
    {
        require(
            newCharlieTreasurer != address(0),
            IporErrors.INCORRECT_CHARLIE_TREASURER_ADDRESS
        );
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
    {
        require(newTreasureTreasurer != address(0), IporErrors.WRONG_ADDRESS);
        _treasureTreasurer = newTreasureTreasurer;
        emit TreasureTreasurerUpdated(_asset, newTreasureTreasurer);
    }

    function getPublicationFeeTransferer()
        external
        view
        override
        returns (address)
    {
        return _publicationFeeTransferer;
    }

    function setPublicationFeeTransferer(address publicationFeeTransferer)
        external
        override
        onlyOwner
    {
        require(
            address(0) != publicationFeeTransferer,
            IporErrors.WRONG_ADDRESS
        );
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
    {
        require(address(0) != treasureTransferer, IporErrors.WRONG_ADDRESS);
        _treasureTransferer = treasureTransferer;
        emit TreasureTransfererUpdated(treasureTransferer);
    }

    function getRedeemLpMaxUtilizationPercentage()
        external
        view
        override
        returns (uint256)
    {
        return _getRedeemLpMaxUtilizationPercentage();
    }

    function getMiltonStanleyBalancePercentage()
        external
        view
        override
        returns (uint256)
    {
        return _getMiltonStanleyBalancePercentage();
    }

    function decimals() external view override returns (uint8) {
        return _decimals;
    }

    function asset() external view override returns (address) {
        return _asset;
    }

    function _getRedeemLpMaxUtilizationPercentage()
        internal
        view
        virtual
        returns (uint256)
    {
        return _REDEEM_LP_MAX_UTILIZATION_PERCENTAGE;
    }

    function _getMiltonStanleyBalancePercentage()
        internal
        view
        virtual
        returns (uint256)
    {
        return _MILTON_STANLEY_BALANCE_PERCENTAGE;
    }
}

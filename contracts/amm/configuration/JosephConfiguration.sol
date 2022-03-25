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

    address internal _treasury;
    address internal _treasuryManager;
    address internal _charlieTreasury;
    address internal _charlieTreasuryManager;

    function getCharlieTreasury() external view override returns (address) {
        return _charlieTreasury;
    }

    function setCharlieTreasury(address newCharlieTreasury)
        external
        override
        onlyOwner
        whenNotPaused
    {
        require(newCharlieTreasury != address(0), JosephErrors.INCORRECT_CHARLIE_TREASURER);
        _charlieTreasury = newCharlieTreasury;
        emit CharlieTreasuryUpdated(_asset, newCharlieTreasury);
    }

    function getTreasury() external view override returns (address) {
        return _treasury;
    }

    function setTreasury(address newTreasury) external override onlyOwner whenNotPaused {
        require(newTreasury != address(0), IporErrors.WRONG_ADDRESS);
        _treasury = newTreasury;
        emit TreasuryUpdated(_asset, newTreasury);
    }

    function getCharlieTreasuryManager() external view override returns (address) {
        return _charlieTreasuryManager;
    }

    function setCharlieTreasuryManager(address charlieTreasuryManager)
        external
        override
        onlyOwner
        whenNotPaused
    {
        require(address(0) != charlieTreasuryManager, IporErrors.WRONG_ADDRESS);
        _charlieTreasuryManager = charlieTreasuryManager;
        emit CharlieTreasuryManagerUpdated(charlieTreasuryManager);
    }

    function getTreasuryManager() external view override returns (address) {
        return _treasuryManager;
    }

    function setTreasuryManager(address treasuryManager) external override onlyOwner whenNotPaused {
        require(address(0) != treasuryManager, IporErrors.WRONG_ADDRESS);
        _treasuryManager = treasuryManager;
        emit TreasuryManagerUpdated(treasuryManager);
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

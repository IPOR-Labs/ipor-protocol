// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.9;

import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/math/SafeCast.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "../../libraries/errors/JosephErrors.sol";
import "../../libraries/Constants.sol";
import "../../libraries/math/IporMath.sol";
import "../../interfaces/IIpToken.sol";
import "../../interfaces/IJosephInternal.sol";
import "../../interfaces/IMiltonInternal.sol";
import "../../interfaces/IMiltonStorage.sol";
import "../../interfaces/IStanley.sol";
import "../../security/IporOwnableUpgradeable.sol";

abstract contract JosephInternal is
    UUPSUpgradeable,
    ReentrancyGuardUpgradeable,
    PausableUpgradeable,
    IporOwnableUpgradeable,
    IJosephInternal
{
    using SafeERC20Upgradeable for IERC20Upgradeable;

    uint256 internal constant _REDEEM_FEE_RATE = 5e15;
    uint256 internal constant _REDEEM_LP_MAX_UTILIZATION_RATE = 1e18;
    uint256 internal constant _MILTON_STANLEY_BALANCE_RATIO = 85e15;

    address internal _asset;
    IIpToken internal _ipToken;
    IMiltonInternal internal _milton;
    IMiltonStorage internal _miltonStorage;
    IStanley internal _stanley;

    address internal _treasury;
    address internal _treasuryManager;
    address internal _charlieTreasury;
    address internal _charlieTreasuryManager;

    modifier onlyCharlieTreasuryManager() {
        require(
            msg.sender == _getCharlieTreasuryManager(),
            JosephErrors.CALLER_NOT_PUBLICATION_FEE_TRANSFERER
        );
        _;
    }

    modifier onlyTreasuryManager() {
        require(msg.sender == _getTreasuryManager(), JosephErrors.CALLER_NOT_TREASURE_TRANSFERER);
        _;
    }

    function getVersion() external pure virtual override returns (uint256) {
        return 1;
    }

    function getAsset() external view override returns (address) {
        return _asset;
    }

    function _getRedeemFeeRate() internal pure virtual returns (uint256) {
        return _REDEEM_FEE_RATE;
    }

    function _getRedeemLpMaxUtilizationRate() internal pure virtual returns (uint256) {
        return _REDEEM_LP_MAX_UTILIZATION_RATE;
    }

    function _getMiltonStanleyBalanceRatio() internal pure virtual returns (uint256) {
        return _MILTON_STANLEY_BALANCE_RATIO;
    }

    function _getStanley() internal view virtual returns (IStanley) {
        return _stanley;
    }

    function _getMiltonStorage() internal view virtual returns (IMiltonStorage) {
        return _miltonStorage;
    }

    function _getMilton() internal view virtual returns (IMiltonInternal) {
        return _milton;
    }

    function _getIpToken() internal view virtual returns (IIpToken) {
        return _ipToken;
    }

    function _getTreasury() internal view virtual returns (address) {
        return _treasury;
    }

    function _getTreasuryManager() internal view virtual returns (address) {
        return _treasuryManager;
    }

    function _getCharlieTreasury() internal view virtual returns (address) {
        return _charlieTreasury;
    }

    function _getCharlieTreasuryManager() internal view virtual returns (address) {
        return _charlieTreasuryManager;
    }

    function rebalance() external override onlyOwner whenNotPaused {
        (uint256 totalBalance, uint256 wadMiltonAssetBalance) = _getIporTotalBalance();

        require(totalBalance != 0, JosephErrors.STANLEY_BALANCE_IS_EMPTY);

        uint256 ratio = IporMath.division(wadMiltonAssetBalance * Constants.D18, totalBalance);

        if (ratio > _getMiltonStanleyBalanceRatio()) {
            uint256 assetAmount = wadMiltonAssetBalance -
                IporMath.division(_getMiltonStanleyBalanceRatio() * totalBalance, Constants.D18);
            _milton.depositToStanley(assetAmount);
        } else {
            uint256 assetAmount = IporMath.division(
                _getMiltonStanleyBalanceRatio() * totalBalance,
                Constants.D18
            ) - wadMiltonAssetBalance;
            _getMilton().withdrawFromStanley(assetAmount);
        }
    }

    //@param assetAmount underlying token amount represented in 18 decimals
    function depositToStanley(uint256 assetAmount) external override onlyOwner whenNotPaused {
        _getMilton().depositToStanley(assetAmount);
    }

    //@param assetAmount underlying token amount represented in 18 decimals
    function withdrawFromStanley(uint256 assetAmount) external override onlyOwner whenNotPaused {
        _getMilton().withdrawFromStanley(assetAmount);
    }

    //@param assetAmount underlying token amount represented in 18 decimals
    function withdrawAllFromStanley() external override onlyOwner whenNotPaused {
        _getMilton().withdrawAllFromStanley();
    }

    //@param assetAmount underlying token amount represented in 18 decimals
    function transferToTreasury(uint256 assetAmount)
        external
        override
        nonReentrant
        whenNotPaused
        onlyTreasuryManager
    {
        require(address(0) != _getTreasury(), JosephErrors.INCORRECT_TREASURE_TREASURER);

        _getMiltonStorage().updateStorageWhenTransferToTreasury(assetAmount);

        uint256 assetAmountAssetDecimals = IporMath.convertWadToAssetDecimals(
            assetAmount,
            _getDecimals()
        );

        IERC20Upgradeable(_asset).safeTransferFrom(
            address(_getMilton()),
            _getTreasury(),
            assetAmountAssetDecimals
        );
    }

    //@param assetAmount underlying token amount represented in 18 decimals
    function transferToCharlieTreasury(uint256 assetAmount)
        external
        override
        nonReentrant
        whenNotPaused
        onlyCharlieTreasuryManager
    {
        require(address(0) != _getCharlieTreasury(), JosephErrors.INCORRECT_CHARLIE_TREASURER);

        _getMiltonStorage().updateStorageWhenTransferToCharlieTreasury(assetAmount);

        uint256 assetAmountAssetDecimals = IporMath.convertWadToAssetDecimals(
            assetAmount,
            _getDecimals()
        );

        IERC20Upgradeable(_asset).safeTransferFrom(
            address(_getMilton()),
            _getCharlieTreasury(),
            assetAmountAssetDecimals
        );
    }

    function pause() external override onlyOwner {
        _pause();
    }

    function unpause() external override onlyOwner {
        _unpause();
    }

    function getCharlieTreasury() external view override returns (address) {
        return _getCharlieTreasury();
    }

    function setCharlieTreasury(address newCharlieTreasury)
        external
        override
        onlyOwner
        whenNotPaused
    {
        require(newCharlieTreasury != address(0), JosephErrors.INCORRECT_CHARLIE_TREASURER);
        address oldCharlieTreasury = _getCharlieTreasury();
        _charlieTreasury = newCharlieTreasury;
        emit CharlieTreasuryChanged(msg.sender, oldCharlieTreasury, newCharlieTreasury);
    }

    function getTreasury() external view override returns (address) {
        return _getTreasury();
    }

    function setTreasury(address newTreasury) external override onlyOwner whenNotPaused {
        require(newTreasury != address(0), IporErrors.WRONG_ADDRESS);
        address oldTreasury = _getTreasury();
        _treasury = newTreasury;
        emit TreasuryChanged(msg.sender, oldTreasury, newTreasury);
    }

    function getCharlieTreasuryManager() external view override returns (address) {
        return _getCharlieTreasuryManager();
    }

    function setCharlieTreasuryManager(address newCharlieTreasuryManager)
        external
        override
        onlyOwner
        whenNotPaused
    {
        require(address(0) != newCharlieTreasuryManager, IporErrors.WRONG_ADDRESS);
        address oldCharlieTreasuryManager = _getCharlieTreasuryManager();
        _charlieTreasuryManager = newCharlieTreasuryManager;
        emit CharlieTreasuryManagerChanged(
            msg.sender,
            oldCharlieTreasuryManager,
            newCharlieTreasuryManager
        );
    }

    function getTreasuryManager() external view override returns (address) {
        return _getTreasuryManager();
    }

    function setTreasuryManager(address newTreasuryManager)
        external
        override
        onlyOwner
        whenNotPaused
    {
        require(address(0) != newTreasuryManager, IporErrors.WRONG_ADDRESS);
        address oldTreasuryManager = _getTreasuryManager();
        _treasuryManager = newTreasuryManager;
        emit TreasuryManagerChanged(msg.sender, oldTreasuryManager, newTreasuryManager);
    }

    function getRedeemFeeRate() external pure override returns (uint256) {
        return _getRedeemFeeRate();
    }

    function getRedeemLpMaxUtilizationRate() external pure override returns (uint256) {
        return _getRedeemLpMaxUtilizationRate();
    }

    function getMiltonStanleyBalanceRatio() external pure override returns (uint256) {
        return _getMiltonStanleyBalanceRatio();
    }

    function _getDecimals() internal pure virtual returns (uint256);

    function _getIporTotalBalance()
        internal
        view
        returns (uint256 totalBalance, uint256 wadMiltonAssetBalance)
    {
        address miltonAddr = address(_getMilton());

        wadMiltonAssetBalance = IporMath.convertToWad(
            IERC20Upgradeable(_asset).balanceOf(miltonAddr),
            _getDecimals()
        );

        totalBalance = wadMiltonAssetBalance + _getStanley().totalBalance(miltonAddr);
    }

    //solhint-disable no-empty-blocks
    function _authorizeUpgrade(address) internal override onlyOwner {}
}

// SPDX-License-Identifier: BUSL-1.1
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
            msg.sender == _charlieTreasuryManager,
            JosephErrors.CALLER_NOT_PUBLICATION_FEE_TRANSFERER
        );
        _;
    }

    modifier onlyTreasuryManager() {
        require(msg.sender == _treasuryManager, JosephErrors.CALLER_NOT_TREASURE_TRANSFERER);
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

    function rebalance() external override onlyOwner whenNotPaused {
        (uint256 totalBalance, uint256 wadMiltonAssetBalance) = _getIporTotalBalance();

        require(totalBalance != 0, JosephErrors.STANLEY_BALANCE_IS_EMPTY);

        uint256 ratio = IporMath.division(wadMiltonAssetBalance * Constants.D18, totalBalance);

        if (ratio > _MILTON_STANLEY_BALANCE_RATIO) {
            uint256 assetAmount = wadMiltonAssetBalance -
                IporMath.division(_MILTON_STANLEY_BALANCE_RATIO * totalBalance, Constants.D18);
            _milton.depositToStanley(assetAmount);
        } else {
            uint256 assetAmount = IporMath.division(
                _MILTON_STANLEY_BALANCE_RATIO * totalBalance,
                Constants.D18
            ) - wadMiltonAssetBalance;
            _milton.withdrawFromStanley(assetAmount);
        }
    }

    //@param assetAmount underlying token amount represented in 18 decimals
    function depositToStanley(uint256 assetAmount) external override onlyOwner whenNotPaused {
        _milton.depositToStanley(assetAmount);
    }

    //@param assetAmount underlying token amount represented in 18 decimals
    function withdrawFromStanley(uint256 assetAmount) external override onlyOwner whenNotPaused {
        _milton.withdrawFromStanley(assetAmount);
    }

    //@param assetAmount underlying token amount represented in 18 decimals
    function transferToTreasury(uint256 assetAmount)
        external
        override
        nonReentrant
        whenNotPaused
        onlyTreasuryManager
    {
        require(address(0) != _treasury, JosephErrors.INCORRECT_TREASURE_TREASURER);

        _miltonStorage.updateStorageWhenTransferToTreasury(assetAmount);

        uint256 assetAmountAssetDecimals = IporMath.convertWadToAssetDecimals(
            assetAmount,
            _getDecimals()
        );

        IERC20Upgradeable(_asset).safeTransferFrom(
            address(_milton),
            _treasury,
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
        require(address(0) != _charlieTreasury, JosephErrors.INCORRECT_CHARLIE_TREASURER);

        _miltonStorage.updateStorageWhenTransferToCharlieTreasury(assetAmount);

        uint256 assetAmountAssetDecimals = IporMath.convertWadToAssetDecimals(
            assetAmount,
            _getDecimals()
        );

        IERC20Upgradeable(_asset).safeTransferFrom(
            address(_milton),
            _charlieTreasury,
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
        return _charlieTreasury;
    }

    function setCharlieTreasury(address newCharlieTreasury)
        external
        override
        onlyOwner
        whenNotPaused
    {
        require(newCharlieTreasury != address(0), JosephErrors.INCORRECT_CHARLIE_TREASURER);
        address oldCharlieTreasury = _charlieTreasury;
        _charlieTreasury = newCharlieTreasury;
        emit CharlieTreasuryChanged(msg.sender, oldCharlieTreasury, newCharlieTreasury);
    }

    function getTreasury() external view override returns (address) {
        return _treasury;
    }

    function setTreasury(address newTreasury) external override onlyOwner whenNotPaused {
        require(newTreasury != address(0), IporErrors.WRONG_ADDRESS);
        address oldTreasury = _treasury;
        _treasury = newTreasury;
        emit TreasuryChanged(msg.sender, oldTreasury, newTreasury);
    }

    function getCharlieTreasuryManager() external view override returns (address) {
        return _charlieTreasuryManager;
    }

    function setCharlieTreasuryManager(address newCharlieTreasuryManager)
        external
        override
        onlyOwner
        whenNotPaused
    {
        require(address(0) != newCharlieTreasuryManager, IporErrors.WRONG_ADDRESS);
        address oldCharlieTreasuryManager = _charlieTreasuryManager;
        _charlieTreasuryManager = newCharlieTreasuryManager;
        emit CharlieTreasuryManagerChanged(
            msg.sender,
            oldCharlieTreasuryManager,
            newCharlieTreasuryManager
        );
    }

    function getTreasuryManager() external view override returns (address) {
        return _treasuryManager;
    }

    function setTreasuryManager(address newTreasuryManager)
        external
        override
        onlyOwner
        whenNotPaused
    {
        require(address(0) != newTreasuryManager, IporErrors.WRONG_ADDRESS);
        address oldTreasuryManager = _treasuryManager;
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
        address miltonAddr = address(_milton);

        wadMiltonAssetBalance = IporMath.convertToWad(
            IERC20Upgradeable(_asset).balanceOf(miltonAddr),
            _getDecimals()
        );

        totalBalance = wadMiltonAssetBalance + _stanley.totalBalance(miltonAddr);
    }

    //solhint-disable no-empty-blocks
    function _authorizeUpgrade(address) internal override onlyOwner {}
}

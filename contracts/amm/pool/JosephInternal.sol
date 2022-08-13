// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.15;

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
    using SafeCast for uint256;

    uint256 internal constant _REDEEM_FEE_RATE = 5e15;
    uint256 internal constant _REDEEM_LP_MAX_UTILIZATION_RATE = 1e18;

    address internal _asset;
    IIpToken internal _ipToken;
    IMiltonInternal internal _milton;
    IMiltonStorage internal _miltonStorage;
    IStanley internal _stanley;

    address internal _treasury;
    address internal _treasuryManager;
    address internal _charlieTreasury;
    address internal _charlieTreasuryManager;

    uint256 internal _miltonStanleyBalanceRatio;
    uint32 internal _maxLiquidityPoolBalance;
    uint32 internal _maxLpAccountContribution;

    modifier onlyCharlieTreasuryManager() {
        require(
            _msgSender() == _charlieTreasuryManager,
            JosephErrors.CALLER_NOT_PUBLICATION_FEE_TRANSFERER
        );
        _;
    }

    modifier onlyTreasuryManager() {
        require(_msgSender() == _treasuryManager, JosephErrors.CALLER_NOT_TREASURE_TRANSFERER);
        _;
    }

    function initialize(
        bool paused,
        address initAsset,
        address ipToken,
        address milton,
        address miltonStorage,
        address stanley
    ) public initializer {
        __Ownable_init();
        __UUPSUpgradeable_init();

        require(initAsset != address(0), IporErrors.WRONG_ADDRESS);
        require(ipToken != address(0), IporErrors.WRONG_ADDRESS);
        require(milton != address(0), IporErrors.WRONG_ADDRESS);
        require(miltonStorage != address(0), IporErrors.WRONG_ADDRESS);
        require(stanley != address(0), IporErrors.WRONG_ADDRESS);
        require(
            _getDecimals() == ERC20Upgradeable(initAsset).decimals(),
            IporErrors.WRONG_DECIMALS
        );

        if (paused) {
            _pause();
        }

        IIpToken iipToken = IIpToken(ipToken);
        require(initAsset == iipToken.getAsset(), IporErrors.ADDRESSES_MISMATCH);

        _asset = initAsset;
        _ipToken = iipToken;
        _milton = IMiltonInternal(milton);
        _miltonStorage = IMiltonStorage(miltonStorage);
        _stanley = IStanley(stanley);
        _miltonStanleyBalanceRatio = 85e16;
        _maxLiquidityPoolBalance = 3_000_000;
        _maxLpAccountContribution = 50_000;
    }

    function getVersion() external pure virtual override returns (uint256) {
        return 1;
    }

    function getAsset() external view override returns (address) {
        return _asset;
    }

    function setMiltonStanleyBalanceRatio(uint256 newRatio) external onlyOwner {
        require(newRatio > 0, JosephErrors.MILTON_STANLEY_RATIO);
        require(newRatio < 1e18, JosephErrors.MILTON_STANLEY_RATIO);
        _miltonStanleyBalanceRatio = newRatio;
    }

    function _getRedeemFeeRate() internal pure virtual returns (uint256) {
        return _REDEEM_FEE_RATE;
    }

    function _getRedeemLpMaxUtilizationRate() internal pure virtual returns (uint256) {
        return _REDEEM_LP_MAX_UTILIZATION_RATE;
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

    function rebalance() external override onlyOwner whenNotPaused {
        (uint256 totalBalance, uint256 wadMiltonAssetBalance) = _getIporTotalBalance();

        require(totalBalance > 0, JosephErrors.STANLEY_BALANCE_IS_EMPTY);

        uint256 ratio = IporMath.division(wadMiltonAssetBalance * Constants.D18, totalBalance);

        uint256 miltonStanleyBalanceRatio = _miltonStanleyBalanceRatio;

        if (ratio > miltonStanleyBalanceRatio) {
            uint256 assetAmount = wadMiltonAssetBalance -
                IporMath.division(miltonStanleyBalanceRatio * totalBalance, Constants.D18);
            _milton.depositToStanley(assetAmount);
        } else {
            uint256 assetAmount = IporMath.division(
                miltonStanleyBalanceRatio * totalBalance,
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
        address treasury = _treasury;
        require(address(0) != treasury, JosephErrors.INCORRECT_TREASURE_TREASURER);

        uint256 assetAmountAssetDecimals = IporMath.convertWadToAssetDecimals(
            assetAmount,
            _getDecimals()
        );

        uint256 wadAssetAmount = IporMath.convertToWad(assetAmountAssetDecimals, _getDecimals());

        _getMiltonStorage().updateStorageWhenTransferToTreasury(wadAssetAmount);

        IERC20Upgradeable(_asset).safeTransferFrom(
            address(_getMilton()),
            treasury,
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
        address charlieTreasury = _charlieTreasury;

        require(address(0) != charlieTreasury, JosephErrors.INCORRECT_CHARLIE_TREASURER);

        uint256 assetAmountAssetDecimals = IporMath.convertWadToAssetDecimals(
            assetAmount,
            _getDecimals()
        );

        uint256 wadAssetAmount = IporMath.convertToWad(assetAmountAssetDecimals, _getDecimals());

        _getMiltonStorage().updateStorageWhenTransferToCharlieTreasury(wadAssetAmount);

        IERC20Upgradeable(_asset).safeTransferFrom(
            address(_getMilton()),
            charlieTreasury,
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
        emit CharlieTreasuryChanged(_msgSender(), oldCharlieTreasury, newCharlieTreasury);
    }

    function getTreasury() external view override returns (address) {
        return _treasury;
    }

    function setTreasury(address newTreasury) external override onlyOwner whenNotPaused {
        require(newTreasury != address(0), IporErrors.WRONG_ADDRESS);
        address oldTreasury = _treasury;
        _treasury = newTreasury;
        emit TreasuryChanged(_msgSender(), oldTreasury, newTreasury);
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
            _msgSender(),
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
        emit TreasuryManagerChanged(_msgSender(), oldTreasuryManager, newTreasuryManager);
    }

    function getMaxLiquidityPoolBalance() external view override returns (uint256) {
        return _maxLiquidityPoolBalance;
    }

    function setMaxLiquidityPoolBalance(uint256 newMaxLiquidityPoolBalance)
        external
        override
        onlyOwner
        whenNotPaused
    {
        uint256 oldMaxLiquidityPoolBalance = _maxLiquidityPoolBalance;
        _maxLiquidityPoolBalance = newMaxLiquidityPoolBalance.toUint32();
        emit MaxLiquidityPoolBalanceChanged(
            _msgSender(),
            oldMaxLiquidityPoolBalance * Constants.D18,
            newMaxLiquidityPoolBalance * Constants.D18
        );
    }

    function getMaxLpAccountContribution() external view override returns (uint256) {
        return _maxLpAccountContribution;
    }

    function setMaxLpAccountContribution(uint256 newMaxLpAccountContribution)
        external
        override
        onlyOwner
        whenNotPaused
    {
        uint256 oldMaxLpAccountContribution = _maxLpAccountContribution;
        _maxLpAccountContribution = newMaxLpAccountContribution.toUint32();
        emit MaxLpAccountContributionChanged(
            _msgSender(),
            oldMaxLpAccountContribution * Constants.D18,
            newMaxLpAccountContribution * Constants.D18
        );
    }

    function getRedeemFeeRate() external pure override returns (uint256) {
        return _getRedeemFeeRate();
    }

    function getRedeemLpMaxUtilizationRate() external pure override returns (uint256) {
        return _getRedeemLpMaxUtilizationRate();
    }

    function getMiltonStanleyBalanceRatio() external view override returns (uint256) {
        return _miltonStanleyBalanceRatio;
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

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.16;

import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "@openzeppelin/contracts/utils/math/SafeCast.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "../../libraries/errors/StanleyErrors.sol";
import "../../libraries/math/IporMath.sol";
import "../../interfaces/IStrategyAave.sol";
import "../../security/IporOwnableUpgradeable.sol";
import "../interfaces/aave/AaveLendingPoolV2.sol";
import "../interfaces/aave/AaveLendingPoolProviderV2.sol";
import "../interfaces/aave/AaveIncentivesInterface.sol";
import "../interfaces/aave/StakedAaveInterface.sol";
import "./StrategyCore.sol";

contract StrategyDsr is
    Initializable,
    PausableUpgradeable,
    ReentrancyGuardUpgradeable,
    UUPSUpgradeable,
    IporOwnableUpgradeable,
    IStrategy
{
    using SafeCast for uint256;
    using SafeERC20Upgradeable for IERC20Upgradeable;

    address internal immutable _asset;
    uint256 internal immutable _assetDecimals;
    address internal immutable _shareToken;
    address internal immutable _stanley;
    address internal immutable _dsrManager;
    address internal _treasury;
    address internal _treasuryManager;

    modifier onlyStanley() {
        require(_msgSender() == _stanley, StanleyErrors.CALLER_NOT_STANLEY);
        _;
    }

    modifier onlyTreasuryManager() {
        require(_msgSender() == _treasuryManager, StanleyErrors.CALLER_NOT_TREASURY_MANAGER);
        _;
    }

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor(
        address asset,
        address assetDecimals,
        address shareToken,
        address stanley,
        address dsrManager
    ) {
        _asset = asset;
        _assetDecimals = assetDecimals;
        _shareToken = shareToken;
        _stanley = stanley;
        _dsrManager = dsrManager;

        _disableInitializers();
    }

    function initialize(address treasury, address treasuryManager) public initializer nonReentrant {
        __Pausable_init();
        __Ownable_init();
        __UUPSUpgradeable_init();

        _treasury = treasury;
        _treasuryManager = treasuryManager;

        //        IERC20Upgradeable(_asset).safeApprove(lendingPoolAddress, type(uint256).max);
    }

    function getVersion() external pure override returns (uint256) {
        return 1;
    }

    function getAsset() external view override returns (address) {
        return _asset;
    }

    function getShareToken() external view override returns (address) {
        return _shareToken;
    }

    function getStanley() external view override returns (address) {
        return _stanley;
    }

    function getTreasuryManager() external view override returns (address) {
        return _treasuryManager;
    }

    function getTreasury() external view override returns (address) {
        return _treasury;
    }

    function getApr() external view override returns (uint256 apr) {
        address lendingPoolAddress = _provider.getLendingPool();
        require(lendingPoolAddress != address(0), IporErrors.WRONG_ADDRESS);
        AaveLendingPoolV2 lendingPool = AaveLendingPoolV2(lendingPoolAddress);

        DataTypesContract.ReserveData memory reserveData = lendingPool.getReserveData(_asset);
        apr = IporMath.division(reserveData.currentLiquidityRate, (10**9));
    }

    /**
     * @dev Total Balance = Principal Amount + Interest Amount.
     * returns amount of stable based on aToken volume in ration 1:1 with stable in 18 decimals
     */
    function balanceOf() external view override returns (uint256) {
        IERC20Metadata shareToken = IERC20Metadata(_shareToken);
        uint256 balance = shareToken.balanceOf(address(this));
        return IporMath.convertToWad(balance, shareToken.decimals());
    }

    /**
     * @dev Deposit into _aave lending.
     * @notice deposit can only done by owner.
     * @param wadAmount amount to deposit in _aave lending.
     */
    function deposit(uint256 wadAmount)
        external
        override
        whenNotPaused
        onlyStanley
        returns (uint256 depositedAmount)
    {
        address asset = _asset;
        uint256 assetDecimals = IERC20Metadata(asset).decimals();

        uint256 amount = IporMath.convertWadToAssetDecimals(wadAmount, assetDecimals);
        IERC20Upgradeable(asset).safeTransferFrom(_msgSender(), address(this), amount);

        address lendingPoolAddress = _provider.getLendingPool();
        require(lendingPoolAddress != address(0), IporErrors.WRONG_ADDRESS);

        AaveLendingPoolV2 lendingPool = AaveLendingPoolV2(lendingPoolAddress);
        lendingPool.deposit(asset, amount, address(this), 0);
        depositedAmount = IporMath.convertToWad(amount, assetDecimals);
    }

    /**
     * @dev withdraw from _aave lending.
     * @notice withdraw can only done by Stanley.
     * @param wadAmount amount to withdraw from _aave lending.
     */
    function withdraw(uint256 wadAmount)
        external
        override
        whenNotPaused
        onlyStanley
        returns (uint256 withdrawnAmount)
    {
        uint256 amount = IporMath.convertWadToAssetDecimals(wadAmount, _assetDecimals);

        //        require(lendingPoolAddress != address(0), IporErrors.WRONG_ADDRESS);

        //Transfer assets from Aave directly to msgSender which is Stanley
        uint256 withdrawnAmountAave = AaveLendingPoolV2(lendingPoolAddress).withdraw(
            asset,
            amount,
            _msgSender()
        );

        withdrawnAmount = IporMath.convertToWad(withdrawnAmountAave, assetDecimals);
    }

    function setTreasury(address newTreasury) external whenNotPaused onlyTreasuryManager {
        require(newTreasury != address(0), StanleyErrors.INCORRECT_TREASURY_ADDRESS);
        address oldTreasury = _treasury;
        _treasury = newTreasury;
        emit TreasuryChanged(_msgSender(), oldTreasury, newTreasury);
    }

    function setTreasuryManager(address manager) external whenNotPaused onlyOwner {
        require(manager != address(0), IporErrors.WRONG_ADDRESS);
        address oldTreasuryManager = _treasuryManager;
        _treasuryManager = manager;
        emit TreasuryManagerChanged(_msgSender(), oldTreasuryManager, manager);
    }

    function pause() external override onlyOwner {
        _pause();
    }

    function unpause() external override onlyOwner {
        _unpause();
    }

    //solhint-disable no-empty-blocks
    function _authorizeUpgrade(address) internal override onlyOwner {}
}

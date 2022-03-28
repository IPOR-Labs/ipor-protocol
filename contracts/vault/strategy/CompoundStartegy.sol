// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.9;

import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "../../libraries/errors/IporErrors.sol";
import "../../libraries/errors/StanleyErrors.sol";
import "../../libraries/Constants.sol";
import "../../libraries/math/IporMath.sol";
import "../../interfaces/IStrategy.sol";
import "../../security/IporOwnableUpgradeable.sol";
import "../interfaces/compound/CErc20.sol";
import "../interfaces/compound/ComptrollerInterface.sol";
import "hardhat/console.sol";

contract CompoundStrategy is
    UUPSUpgradeable,
    ReentrancyGuardUpgradeable,
    IporOwnableUpgradeable,
    PausableUpgradeable,
    IStrategy
{
    using SafeERC20Upgradeable for IERC20Upgradeable;

    address private _asset;
    CErc20 private _shareToken;
    uint256 private _blocksPerYear;
    address private _treasury;
    address private _treasuryManager;

    ComptrollerInterface private _comptroller;
    IERC20Upgradeable private _compToken;

    address private _stanley;

    /**
     * @dev Deploy CompoundStrategy.
     * @notice Deploy CompoundStrategy.
     * @param asset underlying token like DAI, USDT etc.
     * @param shareToken share token like cDAI
     * @param comptroller _comptroller to claim comp
     * @param compToken comp token.
     */
    function initialize(
        address asset,
        address shareToken,
        address comptroller,
        address compToken
    ) public initializer nonReentrant {
        __Ownable_init();

        require(asset != address(0), IporErrors.WRONG_ADDRESS);
        require(shareToken != address(0), IporErrors.WRONG_ADDRESS);
        require(comptroller != address(0), IporErrors.WRONG_ADDRESS);
        require(compToken != address(0), IporErrors.WRONG_ADDRESS);

        _asset = asset;
        _shareToken = CErc20(shareToken);
        _comptroller = ComptrollerInterface(comptroller);
        _compToken = IERC20Upgradeable(compToken);
        IERC20Upgradeable(_asset).safeApprove(shareToken, type(uint256).max);
        _blocksPerYear = 2102400;
        _treasuryManager = msg.sender;
    }

    modifier onlyStanley() {
        require(msg.sender == _stanley, StanleyErrors.CALLER_NOT_STANLEY);
        _;
    }

    modifier onlyTreasuryManager() {
        require(msg.sender == _treasuryManager, StanleyErrors.CALLER_NOT_TREASURY_MANAGER);
        _;
    }

    function pause() external override onlyOwner {
        _pause();
    }

    function unpause() external override onlyOwner {
        _unpause();
    }

    /**
     * @dev _asset return
     */
    function getAsset() external view override returns (address) {
        return _asset;
    }

    /**
     * @dev Share token to track _asset (DAI -> cDAI)
     */
    function getShareToken() external view override returns (address) {
        return address(_shareToken);
    }

    /**
     * @dev get current APY.
     */
    function getApr() external view override returns (uint256 apr) {
        uint256 cRate = _shareToken.supplyRatePerBlock(); // interest % per block
        apr = cRate * _blocksPerYear;
    }

    /**
     * @dev Total Balance = Principal Amount + Interest Amount.
     * returns uint256 with 18 Decimals
     */
    function balanceOf() external view override returns (uint256) {
        return (
            IporMath.division(
                (_shareToken.exchangeRateStored() * _shareToken.balanceOf(address(this))),
                (10**IERC20Metadata(_asset).decimals())
            )
        );
    }

    /**
     * @dev Deposit into compound lending.
     * @notice deposit can only done by Stanley .
     * @param wadAmount amount to deposit in compound lending, amount represented in 18 decimals
     */
    function deposit(uint256 wadAmount) external override whenNotPaused onlyStanley {
        address asset = _asset;
        uint256 amount = IporMath.convertWadToAssetDecimals(
            wadAmount,
            IERC20Metadata(asset).decimals()
        );
        IERC20Upgradeable(asset).safeTransferFrom(msg.sender, address(this), amount);
        _shareToken.mint(amount);
    }

    /**
     * @dev withdraw from compound lending.
     * @notice withdraw can only done by owner.
     * @param wadAmount amount to withdraw from compound lending, amount represented in 18 decimals
     */
    function withdraw(uint256 wadAmount) external override whenNotPaused onlyStanley {
        address asset = _asset;

        uint256 amount = IporMath.convertWadToAssetDecimals(
            wadAmount,
            IERC20Metadata(asset).decimals()
        );
        _shareToken.redeem(
            IporMath.divisionWithoutRound(amount * Constants.D18, _shareToken.exchangeRateStored())
        );

        IERC20Upgradeable(address(asset)).safeTransfer(
            msg.sender,
            IERC20Upgradeable(asset).balanceOf(address(this))
        );
    }

    /**
     * @dev beforeClaim is not needed to implement
     */
    //solhint-disable no-empty-blocks
    function beforeClaim() external whenNotPaused {
        // No implementation
    }

    /**
     * @dev Claim extra reward of Governace token(COMP).
     * @notice claim can only done by owner.
     */
    function doClaim() external override whenNotPaused nonReentrant {
        require(_treasury != address(0), IporErrors.WRONG_ADDRESS);
        address[] memory assets = new address[](1);
        assets[0] = address(_shareToken);
        _comptroller.claimComp(address(this), assets);
        uint256 compBal = _compToken.balanceOf(address(this));
        _compToken.safeTransfer(_treasury, compBal);
        emit DoClaim(address(this), assets, _treasury, compBal);
    }

    function setStanley(address stanley) external whenNotPaused onlyOwner {
        require(stanley != address(0), IporErrors.WRONG_ADDRESS);
        _stanley = stanley;
        emit StanleyChanged(msg.sender, stanley, address(this));
    }

    function setTreasuryManager(address manager) external whenNotPaused onlyOwner {
        require(manager != address(0), IporErrors.WRONG_ADDRESS);
        _treasuryManager = manager;
        emit TreasuryManagerChanged(address(this), manager);
    }

    function setTreasury(address treasury) external whenNotPaused onlyTreasuryManager {
        require(treasury != address(0), IporErrors.WRONG_ADDRESS);
        _treasury = treasury;
        emit TreasuryChanged(address(this), treasury);
    }

    /**
     * @dev set blocks per year.
     * @param blocksPerYear amount to deposit in aave lending.
     */
    function setBlocksPerYear(uint256 blocksPerYear) external whenNotPaused onlyOwner {
        require(blocksPerYear != 0, IporErrors.VALUE_NOT_GREATER_THAN_ZERO);
        _blocksPerYear = blocksPerYear;
    }

    //solhint-disable no-empty-blocks
    function _authorizeUpgrade(address) internal override onlyOwner {}
}

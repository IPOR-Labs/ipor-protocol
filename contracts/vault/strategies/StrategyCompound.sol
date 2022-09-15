// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.16;

import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";

import "../../libraries/Constants.sol";
import "../../libraries/math/IporMath.sol";
import "../../interfaces/IStrategyCompound.sol";
import "../interfaces/compound/CErc20.sol";
import "../interfaces/compound/ComptrollerInterface.sol";
import "./StrategyCore.sol";

contract StrategyCompound is StrategyCore, IStrategyCompound {
    using SafeERC20Upgradeable for IERC20Upgradeable;

    uint256 private _blocksPerYear;
    ComptrollerInterface private _comptroller;
    IERC20Upgradeable private _compToken;

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    /**
     * @dev Deploy StrategyCompound.
     * @notice Deploy StrategyCompound.
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
        __Pausable_init();
        __Ownable_init();
        __UUPSUpgradeable_init();

        require(asset != address(0), IporErrors.WRONG_ADDRESS);
        require(shareToken != address(0), IporErrors.WRONG_ADDRESS);
        require(comptroller != address(0), IporErrors.WRONG_ADDRESS);
        require(compToken != address(0), IporErrors.WRONG_ADDRESS);

        _asset = asset;
        _shareToken = shareToken;
        _comptroller = ComptrollerInterface(comptroller);
        _compToken = IERC20Upgradeable(compToken);
        IERC20Upgradeable(_asset).safeApprove(shareToken, type(uint256).max);
        _blocksPerYear = 2102400;
        _treasuryManager = _msgSender();
    }

    /**
     * @notice gets current APR in Compound Protocol.
     */
    function getApr() external view override returns (uint256 apr) {
        uint256 cRate = CErc20(_shareToken).supplyRatePerBlock(); // interest % per block
        apr = cRate * _blocksPerYear;
    }

    /// @notice Gets Stanley Compound Strategy's asset amount in Compound Protocol.
    /// @dev Explanation decimals inside implementation
    /// In Compound exchangeRateStored is calculated in following way:
    /// uint exchangeRate = cashPlusBorrowsMinusReserves * expScale / _totalSupply;
    /// When:
    /// Asset decimals = 18, then exchangeRate decimals := 18 + 18 - 8 = 28 and balanceOf decimals := 28 + 8 - 18 = 18 decimals.
    /// Asset decimals = 6, then exchangeRate decimals := 6 + 18 - 8 = 16 and balanceOf decimals := 16 + 8 - 6 = 18 decimals.
    /// In both cases we have 18 decimals which is number of decimals supported in IPOR Protocol.
    /// @return uint256 Stanley Strategy's asset amount in Compound represented in 18 decimals
    function balanceOf() external view override returns (uint256) {
        CErc20 shareToken = CErc20(_shareToken);

        return (
            IporMath.division(
                (shareToken.exchangeRateStored() * shareToken.balanceOf(address(this))),
                (10**IERC20Metadata(_asset).decimals())
            )
        );
    }

    /**
     * @dev Deposit into compound lending.
     * @notice deposit can only done by Stanley .
     * @param wadAmount amount to deposit in compound lending, amount represented in 18 decimals
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
        CErc20(_shareToken).mint(amount);
        depositedAmount = IporMath.convertToWad(amount, assetDecimals);
    }

    /**
     * @dev withdraw from compound lending.
     * @notice withdraw can only done by Stanley.
     * @param wadAmount candidate amount to withdraw from compound lending, amount represented in 18 decimals
     */
    function withdraw(uint256 wadAmount)
        external
        override
        whenNotPaused
        onlyStanley
        returns (uint256 withdrawnAmount)
    {
        address asset = _asset;
        uint256 assetDecimals = IERC20Metadata(asset).decimals();
        uint256 amount = IporMath.convertWadToAssetDecimals(wadAmount, assetDecimals);

        CErc20 shareToken = CErc20(_shareToken);

        // Transfer assets from Compound to Strategy
        uint256 redeemStatus = shareToken.redeem(
            IporMath.division(amount * Constants.D18, shareToken.exchangeRateStored())
        );

        require(redeemStatus == 0, StanleyErrors.SHARED_TOKEN_REDEEM_ERROR);

        uint256 withdrawnAmountCompound = IERC20Upgradeable(asset).balanceOf(address(this));

        // Transfer all assets from Strategy to Stanley
        IERC20Upgradeable(asset).safeTransfer(_msgSender(), withdrawnAmountCompound);

        withdrawnAmount = IporMath.convertToWad(withdrawnAmountCompound, assetDecimals);
    }

    /**
     * @dev Claim extra reward of Governace token(COMP).
     */
    function doClaim() external override whenNotPaused nonReentrant onlyOwner {
        address treasury = _treasury;
        IERC20Upgradeable compToken = _compToken;

        require(treasury != address(0), IporErrors.WRONG_ADDRESS);

        address[] memory assets = new address[](1);
        assets[0] = _shareToken;

        _comptroller.claimComp(address(this), assets);

        uint256 balance = compToken.balanceOf(address(this));

        compToken.safeTransfer(treasury, balance);

        emit DoClaim(_msgSender(), assets[0], treasury, balance);
    }

    function setBlocksPerYear(uint256 newBlocksPerYear) external whenNotPaused onlyOwner {
        require(newBlocksPerYear > 0, IporErrors.VALUE_NOT_GREATER_THAN_ZERO);
        uint256 oldBlocksPerYear = _blocksPerYear;
        _blocksPerYear = newBlocksPerYear;
        emit BlocksPerYearChanged(_msgSender(), oldBlocksPerYear, newBlocksPerYear);
    }
}

contract StrategyCompoundUsdt is StrategyCompound {}

contract StrategyCompoundUsdc is StrategyCompound {}

contract StrategyCompoundDai is StrategyCompound {}

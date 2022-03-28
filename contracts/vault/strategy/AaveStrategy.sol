// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.9;

import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "@openzeppelin/contracts/utils/math/SafeCast.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "../../libraries/errors/StanleyErrors.sol";
import "../../libraries/math/IporMath.sol";
import "../../interfaces/IStrategy.sol";
import "../../security/IporOwnableUpgradeable.sol";
import "../interfaces/aave/AaveLendingPoolV2.sol";
import "../interfaces/aave/AaveLendingPoolProviderV2.sol";
import "../interfaces/aave/AaveIncentivesInterface.sol";
import "../interfaces/aave/StakedAaveInterface.sol";
import "hardhat/console.sol";

contract AaveStrategy is
    UUPSUpgradeable,
    ReentrancyGuardUpgradeable,
    PausableUpgradeable,
    IporOwnableUpgradeable,
    IStrategy
{
    using SafeCast for uint256;
    using SafeERC20Upgradeable for IERC20Upgradeable;

    address private _asset;
    address private _shareToken;
    address private _aave;
    address private _stkAave;
    address private _stanley;
    address private _treasury;
    address private _treasuryManager;

    AaveLendingPoolProviderV2 private _provider;
    StakedAaveInterface private _stakedAaveInterface;
    AaveIncentivesInterface private _aaveIncentive;

    /**
     * @param asset underlying token like DAI, USDT etc.
     * @param aToken share token like aDAI etc.
     * @param addressesProvider AAVE address _provider.
     * @param stkAave stakedAAVE token.
     * @param aaveIncentive AAVE incentive to claim AAVE token.
     * @param aaveToken AAVE ERC20 token address.
     */
    function initialize(
        address asset,
        address aToken,
        address addressesProvider,
        address stkAave,
        address aaveIncentive,
        address aaveToken
    ) public initializer nonReentrant {
        __Ownable_init();

        require(asset != address(0), IporErrors.WRONG_ADDRESS);
        require(aToken != address(0), IporErrors.WRONG_ADDRESS);
        require(addressesProvider != address(0), IporErrors.WRONG_ADDRESS);
        require(stkAave != address(0), IporErrors.WRONG_ADDRESS);
        require(aaveIncentive != address(0), IporErrors.WRONG_ADDRESS);
        require(aaveToken != address(0), IporErrors.WRONG_ADDRESS);

        _asset = asset;
        _shareToken = aToken;
        _provider = AaveLendingPoolProviderV2(addressesProvider);
        IERC20Upgradeable(_asset).safeApprove(_provider.getLendingPool(), type(uint256).max);
        _stakedAaveInterface = StakedAaveInterface(stkAave);
        _aaveIncentive = AaveIncentivesInterface(aaveIncentive);
        _stkAave = stkAave;
        _aave = aaveToken;
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
     * @dev Share token to track _asset (DAI -> aDAI)
     */
    function getShareToken() external view override returns (address) {
        return _shareToken;
    }

    /**
     * @dev get current APY, represented in 18 decimals
     */
    function getApr() external view override returns (uint256 apr) {
        AaveLendingPoolV2 lendingPool = AaveLendingPoolV2(_provider.getLendingPool());
        DataTypesContract.ReserveData memory reserveData = lendingPool.getReserveData(_asset);
        apr = IporMath.division(uint256(reserveData.currentLiquidityRate), (10**9));
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
    function deposit(uint256 wadAmount) external override whenNotPaused onlyStanley {
        address asset = _asset;

        uint256 amount = IporMath.convertWadToAssetDecimals(
            wadAmount,
            IERC20Metadata(asset).decimals()
        );
        IERC20Upgradeable(asset).safeTransferFrom(msg.sender, address(this), amount);

        AaveLendingPoolV2 lendingPool = AaveLendingPoolV2(_provider.getLendingPool());

        lendingPool.deposit(asset, amount, address(this), 0); // 29 -> referral
    }

    /**
     * @dev withdraw from _aave lending.
     * @notice withdraw can only done by owner.
     * @param wadAmount amount to withdraw from _aave lending.
     */
    function withdraw(uint256 wadAmount) external override whenNotPaused onlyStanley {
        address asset = _asset;
        uint256 amount = IporMath.convertWadToAssetDecimals(
            wadAmount,
            IERC20Metadata(asset).decimals()
        );
        AaveLendingPoolV2(_provider.getLendingPool()).withdraw(asset, amount, msg.sender);
    }

    /**
     * @dev Claim stakedAAVE token first.
     * @notice Internal method.

     */
    function beforeClaim() external override whenNotPaused nonReentrant {
        require(_treasury != address(0), StanleyErrors.INCORRECT_TREASURY_ADDRESS);
        address[] memory assets = new address[](1);
        assets[0] = _shareToken;
        _aaveIncentive.claimRewards(assets, type(uint256).max, address(this));
        _stakedAaveInterface.cooldown();
        emit DoBeforeClaim(address(this), assets);
    }

    /**
     * @dev Claim extra reward of Governace token(AAVE).
     * @notice claim can only done by owner.
     * @notice you have to claim first staked _aave then _aave token. 
        so you have to claim beforeClaim function. 
        when window is open you can call this function to claim _aave
     */
    function doClaim() external override whenNotPaused nonReentrant {
        address treasury = _treasury;
        require(treasury != address(0), StanleyErrors.INCORRECT_TREASURY_ADDRESS);
        uint256 cooldownStartTimestamp = _stakedAaveInterface.stakersCooldowns(address(this));
        uint256 cooldownSeconds = _stakedAaveInterface.COOLDOWN_SECONDS();
        uint256 unstakeWindow = _stakedAaveInterface.UNSTAKE_WINDOW();
        if (
            block.timestamp > cooldownStartTimestamp + cooldownSeconds &&
            (block.timestamp - (cooldownStartTimestamp + cooldownSeconds)) <= unstakeWindow
        ) {
            address aave = _aave;
            // claim AAVE governace token second after claim stakedAave token
            _stakedAaveInterface.redeem(
                address(this),
                IERC20Upgradeable(_stkAave).balanceOf(address(this))
            );
            uint256 balance = IERC20Upgradeable(aave).balanceOf(address(this));
            IERC20Upgradeable(aave).safeTransfer(treasury, balance);
            address[] memory assets = new address[](1);
            assets[0] = _shareToken;
            emit DoClaim(address(this), assets, treasury, balance);
        }
    }

    function setStanley(address stanley) external override whenNotPaused onlyOwner {
        require(stanley != address(0), IporErrors.WRONG_ADDRESS);
        _stanley = stanley;
        //TODO: old new stanley
        emit StanleyChanged(msg.sender, stanley, address(this));
    }

    function setTreasuryManager(address manager) external whenNotPaused onlyOwner {
        require(manager != address(0), IporErrors.WRONG_ADDRESS);
        _treasuryManager = manager;
        emit TreasuryManagerChanged(address(this), manager);
    }

    function setTreasury(address treasury) external whenNotPaused onlyTreasuryManager {
        require(treasury != address(0), StanleyErrors.INCORRECT_TREASURY_ADDRESS);
        _treasury = treasury;
        emit TreasuryChanged(address(this), treasury);
    }

    /**
     * @dev Change staked AAVE token address.
     * @notice Change can only done by current governance.
     * @param stkAave stakedAAVE token
     */
    function setStkAave(address stkAave) external whenNotPaused onlyOwner {
        require(stkAave != address(0), IporErrors.WRONG_ADDRESS);
        _stkAave = stkAave;
        emit StkAaveChanged(msg.sender, stkAave);
    }

    //solhint-disable no-empty-blocks
    function _authorizeUpgrade(address) internal override onlyOwner {}
}

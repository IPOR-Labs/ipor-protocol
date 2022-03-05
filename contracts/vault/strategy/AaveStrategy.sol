pragma solidity 0.8.9;

import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "../interfaces/aave/AaveLendingPoolV2.sol";
import "../interfaces/aave/AaveLendingPoolProviderV2.sol";
import "../interfaces/aave/AaveIncentivesInterface.sol";
import "../interfaces/aave/StakedAaveInterface.sol";
import "../interfaces/IPOR/IStrategy.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "../../IporErrors.sol";
import "../../security/IporOwnableUpgradeable.sol";
import {IporMath} from "../../libraries/IporMath.sol";

contract AaveStrategy is UUPSUpgradeable, IporOwnableUpgradeable, IStrategy {
    using SafeERC20Upgradeable for IERC20Upgradeable;

    address private _asset;
    address private _shareToken; // shareToken
    address private _aave;
    address private _stkAave;
    address private _stanley;

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
    ) public initializer {
        __Ownable_init();
        _asset = asset;
        _shareToken = aToken;
        _provider = AaveLendingPoolProviderV2(addressesProvider);
        IERC20Upgradeable(_asset).safeApprove(
            _provider.getLendingPool(),
            type(uint256).max
        );
        _stakedAaveInterface = StakedAaveInterface(stkAave);
        _aaveIncentive = AaveIncentivesInterface(aaveIncentive);
        _stkAave = stkAave;
        _aave = aaveToken;
    }

    modifier onlyStanley() {
        require(msg.sender == _stanley, IporErrors.CALLER_NOT_STANLEY);
        _;
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
     * @dev get current APY.
     */
    function getApy() external view override returns (uint256) {
        AaveLendingPoolV2 lendingPool = AaveLendingPoolV2(
            _provider.getLendingPool()
        );
        DataTypes.ReserveData memory reserveData = lendingPool.getReserveData(
            _asset
        );
        return
            IporMath.division(
                uint256(reserveData.currentLiquidityRate),
                (10**7)
            );
    }

    /**
     * @dev Total Balance = Principal Amount + Interest Amount.
     * returns amount of stable based on aToken volume in ration 1:1 with stable
     */
    function balanceOf() external view override returns (uint256) {
        return IERC20Upgradeable(_shareToken).balanceOf(address(this));
    }

    /**
     * @dev Deposit into _aave lending.
     * @notice deposit can only done by owner.
     * @param amount amount to deposit in _aave lending.
     */
    function deposit(uint256 amount) external override onlyStanley {
        address asset = _asset;

        IERC20Upgradeable(asset).safeTransferFrom(
            msg.sender,
            address(this),
            amount
        );

        AaveLendingPoolV2 lendingPool = AaveLendingPoolV2(
            _provider.getLendingPool()
        );

        lendingPool.deposit(asset, amount, address(this), 0); // 29 -> referral
    }

    /**
     * @dev withdraw from _aave lending.
     * @notice withdraw can only done by owner.
     * @param amount amount to withdraw from _aave lending.
     */
    function withdraw(uint256 amount) external override onlyStanley {
        AaveLendingPoolV2(_provider.getLendingPool()).withdraw(
            _asset,
            amount,
            msg.sender
        );
    }

    /**
     * @dev Claim stakedAAVE token first.
     * @notice Internal method.
     * @param assets assets for claim _aave gov token.
     * @param amount amount to claim staked _aave token from _aave incentive.
     */
    function beforeClaim(address[] memory assets, uint256 amount)
        external        
        override
        onlyStanley
    {
        _aaveIncentive.claimRewards(assets, amount, address(this));
        _stakedAaveInterface.cooldown();
    }

    /**
     * @dev Claim extra reward of Governace token(AAVE).
     * @notice claim can only done by owner.
     * @notice you have to claim first staked _aave then _aave token. 
        so you have to claim beforeClaim function. 
        when window is open you can call this function to claim _aave
     * @param vault vault address where send to claimed AAVE token.
     * @param assets assets for claim _aave gov token.
     */
    function doClaim(address vault, address[] memory assets)
        external        
        override
        onlyStanley
    {
        uint256 cooldownStartTimestamp = _stakedAaveInterface.stakersCooldowns(
            address(this)
        );
        uint256 cooldownSeconds = _stakedAaveInterface.COOLDOWN_SECONDS();
        uint256 unstakeWindow = _stakedAaveInterface.UNSTAKE_WINDOW();
        if (
            block.timestamp > cooldownStartTimestamp + cooldownSeconds &&
            (block.timestamp - (cooldownStartTimestamp + cooldownSeconds)) <=
            unstakeWindow
        ) {
            // claim AAVE governace token second after claim stakedAave token
            _stakedAaveInterface.redeem(
                address(this),
                IERC20Upgradeable(_stkAave).balanceOf(address(this))
            );
            IERC20Upgradeable(_aave).safeTransfer(
                vault,
                IERC20Upgradeable(_aave).balanceOf(address(this))
            );
        }
    }

    function setStanley(address stanley) external override onlyOwner {
        _stanley = stanley;
        emit SetStanley(msg.sender, stanley, address(this));
    }

    /**
     * @dev Change staked AAVE token address.
     * @notice Change can only done by current governance.
     * @param stkAave stakedAAVE token
     */
    function setStkAave(address stkAave) external onlyOwner {
        _stkAave = stkAave;
    }

    function _authorizeUpgrade(address) internal override onlyOwner {}
}

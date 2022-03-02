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
import "../errors/Errors.sol";
import "../libraries/AmMath.sol";
import "../../security/IporOwnableUpgradeable.sol";
import "hardhat/console.sol";

contract AaveStrategy is UUPSUpgradeable, IporOwnableUpgradeable, IStrategy {
    using SafeERC20Upgradeable for IERC20Upgradeable;

    AaveLendingPoolProviderV2 public provider;
    StakedAaveInterface public stakedAaveInterface;
    AaveIncentivesInterface public aaveIncentive;

    address public underlyingToken; // underlyingToken
    address public aToken; // shareToken

    address public aave;
    address public stkAave;

    /**
     * @param _underlyingToken underlying token like DAI, USDT etc.
     * @param _aToken share token like aDAI etc.
     * @param _addressesProvider AAVE address provider.
     * @param _stkAave stakedAAVE token.
     * @param _aaveIncentive AAVE incentive to claim AAVE token.
     * @param _aaveToken AAVE ERC20 token address.
     */
    function initialize(
        address _underlyingToken,
        address _aToken,
        address _addressesProvider,
        address _stkAave,
        address _aaveIncentive,
        address _aaveToken
    ) public initializer {
        __Ownable_init();
        underlyingToken = _underlyingToken;
        aToken = _aToken;

        provider = AaveLendingPoolProviderV2(_addressesProvider);
        IERC20Upgradeable(underlyingToken).safeApprove(
            provider.getLendingPool(),
            type(uint256).max
        );
        stakedAaveInterface = StakedAaveInterface(_stkAave);
        aaveIncentive = AaveIncentivesInterface(_aaveIncentive);
        stkAave = _stkAave;
        aave = _aaveToken;
    }

    // TODO: this empty ????
    function _authorizeUpgrade(address) internal override onlyOwner {}

    /**
     * @dev underlyingToken return
     */
    function getUnderlyingToken() public view override returns (address) {
        return underlyingToken;
    }

    /**
     * @dev Share token to track underlyingToken (DAI -> aDAI)
     */
    function shareToken() external view override returns (address) {
        return aToken;
    }

    /**
     * @dev get current APY.
     */
    function getApy() public view override returns (uint256) {
        AaveLendingPoolV2 lendingPool = AaveLendingPoolV2(
            provider.getLendingPool()
        );
        DataTypes.ReserveData memory reserveData = lendingPool.getReserveData(
            underlyingToken
        );
        return
            AmMath.division(uint256(reserveData.currentLiquidityRate), (10**7));
    }

    /**
     * @dev Total Balance = Principal Amount + Interest Amount.
     * returns uint with 18 Decimals
     */
    function balanceOf() public view override returns (uint256) {
        return IERC20Upgradeable(aToken).balanceOf(address(this));
    }

    /**
     * @dev Change owner address.
     * @notice Change can only done by current owner.
     * @param _newOwner New owner address.
     */
    function changeOwnership(address _newOwner) public override {
        require(_newOwner != address(0), Errors.ZERO_ADDRESS);
        transferOwnership(_newOwner);
    }

    /**
     * @dev Change staked AAVE token address.
     * @notice Change can only done by current governance.
     * @param _stkAave stakedAAVE token
     */
    function setStkAave(address _stkAave) public onlyOwner {
        stkAave = _stkAave;
    }

    /**
     * @dev Deposit into aave lending.
     * @notice deposit can only done by owner.
     * @param _amount amount to deposit in aave lending.
     */
    function deposit(uint256 _amount) external override onlyOwner {
        IERC20Upgradeable(underlyingToken).safeTransferFrom(
            msg.sender,
            address(this),
            _amount
        );
        AaveLendingPoolV2 lendingPool = AaveLendingPoolV2(
            provider.getLendingPool()
        );
        lendingPool.deposit(underlyingToken, _amount, address(this), 0); // 29 -> referral
    }

    /**
     * @dev withdraw from aave lending.
     * @notice withdraw can only done by owner.
     * @param _amount amount to withdraw from aave lending.
     */
    function withdraw(uint256 _amount) external override onlyOwner {
        AaveLendingPoolV2(provider.getLendingPool()).withdraw(
            underlyingToken,
            _amount,
            msg.sender
        );
    }

    /**
     * @dev Claim extra reward of Governace token(AAVE).
     * @notice claim can only done by owner.
     * @notice you have to claim first staked aave then aave token. 
        so you have to claim beforeClaim function. 
        when window is open you can call this function to claim aave
     * @param vault vault address where send to claimed AAVE token.
     * @param assets assets for claim aave gov token.
     */
    function doClaim(address vault, address[] memory assets)
        external
        payable
        override
        onlyOwner
    {
        uint256 cooldownStartTimestamp = stakedAaveInterface.stakersCooldowns(
            address(this)
        );
        uint256 cooldownSeconds = stakedAaveInterface.COOLDOWN_SECONDS();
        uint256 unstakeWindow = stakedAaveInterface.UNSTAKE_WINDOW();
        if (
            block.timestamp > cooldownStartTimestamp + cooldownSeconds &&
            (block.timestamp - (cooldownStartTimestamp + cooldownSeconds)) <=
            unstakeWindow
        ) {
            // claim AAVE governace token second after claim stakedAave token
            stakedAaveInterface.redeem(
                address(this),
                IERC20Upgradeable(stkAave).balanceOf(address(this))
            );
            IERC20Upgradeable(aave).safeTransfer(
                vault,
                IERC20Upgradeable(aave).balanceOf(address(this))
            );
        }
    }

    /**
     * @dev Claim stakedAAVE token first.
     * @notice Internal method.
     * @param assets assets for claim aave gov token.
     * @param _amount amount to claim staked aave token from aave incentive.
     */
    function beforeClaim(address[] memory assets, uint256 _amount)
        public
        payable
        onlyOwner
    {
        aaveIncentive.claimRewards(assets, _amount, address(this));
        stakedAaveInterface.cooldown();
    }
}

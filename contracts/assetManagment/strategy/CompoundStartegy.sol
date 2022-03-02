pragma solidity 0.8.9;

import "../interfaces/compound/CErc20.sol";
import "../interfaces/IPOR/IStrategy.sol";
import "../interfaces/compound/ComptrollerInterface.sol";
import "../interfaces/compound/COMPInterface.sol";
import "../interfaces/IERC20Decimal.sol";
import "../interfaces/IPOR/IStrategy.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "../../security/IporOwnableUpgradeable.sol";

import "hardhat/console.sol";
import "../errors/Errors.sol";
import "../libraries/AmMath.sol";

contract CompoundStrategy is
    UUPSUpgradeable,
    IporOwnableUpgradeable,
    IStrategy
{
    using SafeERC20Upgradeable for IERC20Upgradeable;

    uint256 public blocksPerYear;
    address public underlyingToken;

    ComptrollerInterface public comptroller;
    IERC20Upgradeable public compToken;
    CErc20 public cToken;

    /**
     * @dev Deploy CompoundStrategy.
     * @notice Deploy CompoundStrategy.
     * @param _underlyingToken underlying token like DAI, USDT etc.
     * @param _cErc20Contract share token like cDAI
     * @param _comptroller _comptroller to claim comp
     * @param _compToken comp token.
     */
    function initialize(
        address _underlyingToken,
        address _cErc20Contract,
        address _comptroller,
        address _compToken
    ) public initializer {
        __Ownable_init();
        underlyingToken = _underlyingToken;
        cToken = CErc20(_cErc20Contract);
        comptroller = ComptrollerInterface(_comptroller);
        compToken = IERC20Upgradeable(_compToken);
        IERC20Upgradeable(underlyingToken).safeApprove(
            _cErc20Contract,
            type(uint256).max
        );
        blocksPerYear = 2102400;
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
     * @dev Share token to track underlyingToken (DAI -> cDAI)
     */
    function shareToken() external view override returns (address) {
        return address(cToken);
    }

    /**
     * @dev get current APY.
     */
    function getApy() external view override returns (uint256 apr) {
        uint256 cRate = cToken.supplyRatePerBlock(); // interest % per block
        apr = (cRate * blocksPerYear) * 100;
    }

    /**
     * @dev set blocks per year.
     * @param _blocksPerYear amount to deposit in aave lending.
     */
    function setBlocksPerYear(uint256 _blocksPerYear) external onlyOwner {
        require(_blocksPerYear != 0, Errors.UINT_SHOULD_BE_GRATER_THEN_ZERO);
        blocksPerYear = _blocksPerYear;
    }

    /**
     * @dev Total Balance = Principal Amount + Interest Amount.
     * returns uint256 with 18 Decimals
     */
    //  TODO: [Pete] use AmMath to div without round
    function balanceOf() public view override returns (uint256) {
        return (
            AmMath.division(
                (cToken.exchangeRateStored() * cToken.balanceOf(address(this))),
                (10**IERC20Decimal(underlyingToken).decimals())
            )
        );
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
     * @dev Deposit into compound lending.
     * @notice deposit can only done by owner.
     * @param _amount amount to deposit in compound lending.
     */
    function deposit(uint256 _amount) external override onlyOwner {
        IERC20Upgradeable(underlyingToken).safeTransferFrom(
            msg.sender,
            address(this),
            _amount
        );
        cToken.mint(_amount);
    }

    /**
     * @dev withdraw from compound lending.
     * @notice withdraw can only done by owner.
     * @param _amount amount to withdraw from compound lending.
     */
    function withdraw(uint256 _amount) external override onlyOwner {
        cToken.redeem(
            AmMath.division(_amount * 1e18, cToken.exchangeRateStored())
        );
        IERC20Upgradeable(address(underlyingToken)).safeTransfer(
            msg.sender,
            IERC20Upgradeable(underlyingToken).balanceOf(address(this))
        );
    }

    /**
     * @dev Claim extra reward of Governace token(COMP).
     * @notice claim can only done by owner.
     * @param vault vault address where send to claimed COMP token.
     * @param assets assets for claim COMP gov token.
     */
    function doClaim(address vault, address[] memory assets)
        external
        payable
        override
        onlyOwner
    {
        require(vault != address(0), Errors.ZERO_ADDRESS);
        comptroller.claimComp(address(this), assets);
        uint256 compBal = compToken.balanceOf(address(this));
        compToken.safeTransfer(vault, compBal);
    }

    /**
     * @dev beforeClaim is not needed to implement
     */
    function beforeClaim(address[] memory assets, uint256 _amount)
        public
        payable
        onlyOwner
    {
        // No implementation
    }
}

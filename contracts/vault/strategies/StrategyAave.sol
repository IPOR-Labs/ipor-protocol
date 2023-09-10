// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.20;

import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "@openzeppelin/contracts/utils/math/SafeCast.sol";
import "../../interfaces/IStrategyAave.sol";
import "../../libraries/IporContractValidator.sol";
import "../interfaces/aave/AaveLendingPoolV2.sol";
import "../interfaces/aave/AaveLendingPoolProviderV2.sol";
import "../interfaces/aave/AaveIncentivesInterface.sol";
import "../interfaces/aave/StakedAaveInterface.sol";
import "../../libraries/math/IporMath.sol";
import "../../libraries/errors/AssetManagementErrors.sol";
import "./StrategyCore.sol";

contract StrategyAave is StrategyCore, IStrategyAave {
    using IporContractValidator for address;
    using SafeCast for uint256;
    using SafeERC20Upgradeable for IERC20Upgradeable;

    uint256 public constant override getVersion = 2_000;

    address public immutable aave;
    address public immutable stkAave;
    AaveLendingPoolProviderV2 public immutable provider;
    StakedAaveInterface public immutable stakedAaveInterface;
    AaveIncentivesInterface public immutable aaveIncentive;

    /// @dev deprecated
    address private _aaveDeprecated;
    /// @dev deprecated
    address private _stkAaveDeprecated;
    /// @dev deprecated
    AaveLendingPoolProviderV2 private _providerDeprecated;
    /// @dev deprecated
    StakedAaveInterface private _stakedAaveInterfaceDeprecated;
    /// @dev deprecated
    AaveIncentivesInterface private _aaveIncentiveDeprecated;

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor(
        address assetInput,
        uint256 assetDecimalsInput,
        address shareTokenInput,
        address assetManagementInput,
        address aaveInput,
        address stkAaveInput,
        address providerInput,
        address stakedAaveInterfaceInput,
        address aaaveIncentiveInput
    ) StrategyCore(assetInput, assetDecimalsInput, shareTokenInput, assetManagementInput) {
        aave = aaveInput.checkAddress();
        stkAave = stkAaveInput.checkAddress();
        provider = AaveLendingPoolProviderV2(providerInput.checkAddress());
        stakedAaveInterface = StakedAaveInterface(stakedAaveInterfaceInput.checkAddress());
        aaveIncentive = AaveIncentivesInterface(aaaveIncentiveInput.checkAddress());

        _disableInitializers();
    }

    function initialize() public initializer nonReentrant {
        __Pausable_init();
        __Ownable_init();
        __UUPSUpgradeable_init();

        address lendingPoolAddress = provider.getLendingPool();
        require(lendingPoolAddress != address(0), IporErrors.WRONG_ADDRESS);

        _treasuryManager = _msgSender();
    }

    /**
     * @dev get current APY, represented in 18 decimals
     */
    function getApy() external view override returns (uint256 apy) {
        address lendingPoolAddress = provider.getLendingPool();
        require(lendingPoolAddress != address(0), IporErrors.WRONG_ADDRESS);

        AaveLendingPoolV2 lendingPoolContract = AaveLendingPoolV2(lendingPoolAddress);
        DataTypesContract.ReserveData memory reserveData = lendingPoolContract.getReserveData(asset);
        uint256 apr = IporMath.division(reserveData.currentLiquidityRate, (10 ** 9));

        apy = aprToApy(apr);
    }

    function aprToApy(uint256 apr) internal pure returns (uint256) {
        uint256 rate = IporMath.division(apr, 31536000) + 1e18;
        return ratePerSecondToApy(rate) - 1e18;
    }

    /// @dev 1e54 it is a 1e18 * 1e18 * 1e18, to achieve number in 18 decimals when there is multiplication of 3 numbers in 18 decimals, we need to divide by 1e54.
    function ratePerSecondToApy(uint256 rate) internal pure returns (uint256) {
        uint256 rate4 = IporMath.division(rate * rate * rate * rate, 1e54);
        uint256 rate16 = IporMath.division(rate4 * rate4 * rate4 * rate4, 1e54);
        uint256 rate64 = IporMath.division(rate16 * rate16 * rate16 * rate16, 1e54);
        uint256 rate256 = IporMath.division(rate64 * rate64 * rate64 * rate64, 1e54);
        uint256 rate1024 = IporMath.division(rate256 * rate256 * rate256 * rate256, 1e54);
        uint256 rate4096 = IporMath.division(rate1024 * rate1024 * rate1024 * rate1024, 1e54);
        uint256 rate16384 = IporMath.division(rate4096 * rate4096 * rate4096 * rate4096, 1e54);
        uint256 rate65536 = IporMath.division(rate16384 * rate16384 * rate16384 * rate16384, 1e54);
        uint256 rate262144 = IporMath.division(rate65536 * rate65536 * rate65536 * rate65536, 1e54);
        uint256 rate1048576 = IporMath.division(rate262144 * rate262144 * rate262144 * rate262144, 1e54);
        uint256 rate4194304 = IporMath.division(rate1048576 * rate1048576 * rate1048576 * rate1048576, 1e54);
        uint256 rate16777216 = IporMath.division(rate4194304 * rate4194304 * rate4194304 * rate4194304, 1e54);

        return poweredRatePerSecondToApy(rate64, rate256, rate4096, rate65536, rate1048576, rate4194304, rate16777216);
    }

    /// @dev 1e54 it is a 1e18 * 1e18 * 1e18, to achieve number in 18 decimals when there is multiplication of 3 numbers in 18 decimals, we need to divide by 1e54.
    /// @dev 1e36 it is a 1e18 * 1e18, to achieve number in 18 decimals when there is multiplication of 2 numbers in 18 decimals, we need to divide by 1e36.
    function poweredRatePerSecondToApy(
        uint256 rate64,
        uint256 rate256,
        uint256 rate4096,
        uint256 rate65536,
        uint256 rate1048576,
        uint256 rate4194304,
        uint256 rate16777216
    ) internal pure returns (uint256) {
        uint256 rate640 = IporMath.division(rate256 * rate256 * rate64 * rate64, 1e54);
        uint256 rate12544 = IporMath.division(rate4096 * rate4096 * rate4096 * rate256, 1e54);
        uint256 rate2162688 = IporMath.division(rate1048576 * rate1048576 * rate65536, 1e36);
        uint256 rate29360128 = IporMath.division(rate16777216 * rate4194304 * rate4194304 * rate4194304, 1e54);

        return IporMath.division(rate29360128 * rate2162688 * rate12544 * rate640, 1e54);
    }

    /**
     * @dev Total Balance = Principal Amount + Interest Amount.
     * returns amount of stable based on aToken volume in ration 1:1 with stable in 18 decimals
     */
    function balanceOf() external view override returns (uint256) {
        IERC20Metadata shareTokenContract = IERC20Metadata(shareToken);
        uint256 balance = shareTokenContract.balanceOf(address(this));
        return IporMath.convertToWad(balance, shareTokenContract.decimals());
    }

    /**
     * @dev Deposit into _aave lending.
     * @notice deposit can only done by owner.
     * @param wadAmount amount to deposit in _aave lending.
     */
    function deposit(
        uint256 wadAmount
    ) external override whenNotPaused onlyAssetManagement returns (uint256 depositedAmount) {
        uint256 amount = IporMath.convertWadToAssetDecimals(wadAmount, assetDecimals);
        IERC20Upgradeable(asset).safeTransferFrom(_msgSender(), address(this), amount);

        address lendingPoolAddress = provider.getLendingPool();
        require(lendingPoolAddress != address(0), IporErrors.WRONG_ADDRESS);

        IERC20Upgradeable(asset).forceApprove(lendingPoolAddress, amount);

        AaveLendingPoolV2(lendingPoolAddress).deposit(asset, amount, address(this), 0);
        depositedAmount = IporMath.convertToWad(amount, assetDecimals);
    }

    /**
     * @dev withdraw from _aave lending.
     * @notice withdraw can only done by AssetManagement.
     * @param wadAmount amount to withdraw from _aave lending.
     */
    function withdraw(
        uint256 wadAmount
    ) external override whenNotPaused onlyAssetManagement returns (uint256 withdrawnAmount) {
        uint256 amount = IporMath.convertWadToAssetDecimals(wadAmount, assetDecimals);

        address lendingPoolAddress = provider.getLendingPool();

        require(lendingPoolAddress != address(0), IporErrors.WRONG_ADDRESS);

        /// @dev Transfer assets from Aave directly to msgSender which is AssetManagement
        uint256 withdrawnAmountAave = AaveLendingPoolV2(lendingPoolAddress).withdraw(asset, amount, _msgSender());

        withdrawnAmount = IporMath.convertToWad(withdrawnAmountAave, assetDecimals);
    }

    /**
     * @dev Claim stakedAAVE token first.
     * @notice Internal method.

     */
    function beforeClaim() external whenNotPaused nonReentrant onlyOwner {
        require(_treasury != address(0), AssetManagementErrors.INCORRECT_TREASURY_ADDRESS);
        address[] memory shareTokens = new address[](1);
        shareTokens[0] = shareToken;
        aaveIncentive.claimRewards(shareTokens, type(uint256).max, address(this));
        stakedAaveInterface.cooldown();
        emit DoBeforeClaim(_msgSender(), shareTokens);
    }

    /**
     * @dev Claim extra reward of Governace token(AAVE).
     * @notice you have to claim first staked _aave then _aave token.
        so you have to claim beforeClaim function.
        when window is open you can call this function to claim _aave
     */
    function doClaim() external whenNotPaused nonReentrant onlyOwner {
        address treasuryAddress = _treasury;

        require(treasuryAddress != address(0), AssetManagementErrors.INCORRECT_TREASURY_ADDRESS);

        uint256 cooldownStartTimestamp = stakedAaveInterface.stakersCooldowns(address(this));
        uint256 cooldownSeconds = stakedAaveInterface.COOLDOWN_SECONDS();
        uint256 unstakeWindow = stakedAaveInterface.UNSTAKE_WINDOW();

        if (
            block.timestamp > cooldownStartTimestamp + cooldownSeconds &&
            (block.timestamp - (cooldownStartTimestamp + cooldownSeconds)) <= unstakeWindow
        ) {
            /// @dev claim AAVE governance token second after claim stakedAave token
            stakedAaveInterface.redeem(address(this), IERC20Upgradeable(stkAave).balanceOf(address(this)));

            uint256 balance = IERC20Upgradeable(aave).balanceOf(address(this));

            IERC20Upgradeable(aave).safeTransfer(treasuryAddress, balance);

            emit DoClaim(_msgSender(), shareToken, treasuryAddress, balance);
        }
    }
}

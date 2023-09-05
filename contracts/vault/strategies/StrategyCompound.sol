// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.20;

import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";

import "../../interfaces/IStrategyCompound.sol";
import "../interfaces/compound/CErc20.sol";
import "../interfaces/compound/ComptrollerInterface.sol";
import "../../libraries/math/IporMath.sol";
import "./StrategyCore.sol";
import "../../libraries/IporContractValidator.sol";

contract StrategyCompound is StrategyCore, IStrategyCompound {
    using IporContractValidator for address;
    using SafeERC20Upgradeable for IERC20Upgradeable;

    uint256 public immutable blocksPerDay;
    ComptrollerInterface public immutable comptroller;
    IERC20Upgradeable public immutable compToken;

    /// @dev deprecated
    uint256 private _blocksPerDayDeprecated;
    /// @dev deprecated
    ComptrollerInterface private _comptrollerDeprecated;
    /// @dev deprecated
    IERC20Upgradeable private _compTokenDeprecated;

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor(
        address assetInput,
        uint256 assetDecimalsInput,
        address shareTokenInput,
        address assetManagementInput,
        uint256 blocksPerDayInput,
        address comptrollerInput,
        address compTokenInput
    ) StrategyCore(assetInput, assetDecimalsInput, shareTokenInput, assetManagementInput) {
        blocksPerDay = blocksPerDayInput;
        comptroller = ComptrollerInterface(comptrollerInput.checkAddress());
        compToken = IERC20Upgradeable(compTokenInput.checkAddress());

        _disableInitializers();
    }

    function initialize() public initializer nonReentrant {
        __Pausable_init();
        __Ownable_init();
        __UUPSUpgradeable_init();

        IERC20Upgradeable(asset).safeApprove(shareToken, type(uint256).max);

        _treasuryManager = _msgSender();
    }

    /**
     * @notice gets current APY in Compound Protocol.
     */
    function getApy() external view override returns (uint256 apy) {
        uint256 cRate = CErc20(shareToken).supplyRatePerBlock(); // interest % per block
        uint256 ratePerDay = cRate * blocksPerDay + 1e18;

        uint256 ratePerDay4 = IporMath.division(ratePerDay * ratePerDay * ratePerDay * ratePerDay, 1e54);
        uint256 ratePerDay8 = IporMath.division(ratePerDay4 * ratePerDay4, 1e18);
        uint256 ratePerDay32 = IporMath.division(ratePerDay8 * ratePerDay8 * ratePerDay8 * ratePerDay8, 1e54);
        uint256 ratePerDay64 = IporMath.division(ratePerDay32 * ratePerDay32, 1e18);
        uint256 ratePerDay256 = IporMath.division(ratePerDay64 * ratePerDay64 * ratePerDay64 * ratePerDay64, 1e54);
        uint256 ratePerDay360 = IporMath.division(ratePerDay256 * ratePerDay64 * ratePerDay32 * ratePerDay8, 1e54);
        uint256 ratePerDay365 = IporMath.division(ratePerDay360 * ratePerDay4 * ratePerDay, 1e36);

        apy = ratePerDay365 - 1e18;
    }

    /// @notice Gets AssetManagement Compound Strategy's asset amount in Compound Protocol.
    /// @dev Explanation decimals inside implementation
    /// In Compound exchangeRateStored is calculated in following way:
    /// uint exchangeRate = cashPlusBorrowsMinusReserves * expScale / _totalSupply;
    /// When:
    /// Asset decimals = 18, then exchangeRate decimals := 18 + 18 - 8 = 28 and balanceOf decimals := 28 + 8 - 18 = 18 decimals.
    /// Asset decimals = 6, then exchangeRate decimals := 6 + 18 - 8 = 16 and balanceOf decimals := 16 + 8 - 6 = 18 decimals.
    /// In both cases we have 18 decimals which is number of decimals supported in IPOR Protocol.
    /// @return uint256 AssetManagement Strategy's asset amount in Compound represented in 18 decimals
    function balanceOf() external view override returns (uint256) {
        CErc20 shareToken = CErc20(shareToken);

        return (
            IporMath.division(
                (shareToken.exchangeRateStored() * shareToken.balanceOf(address(this))),
                (10 ** IERC20Metadata(asset).decimals())
            )
        );
    }

    /**
     * @dev Deposit into compound lending.
     * @notice deposit can only done by AssetManagement .
     * @param wadAmount amount to deposit in compound lending, amount represented in 18 decimals
     */
    function deposit(
        uint256 wadAmount
    ) external override whenNotPaused onlyAssetManagement returns (uint256 depositedAmount) {
        uint256 amount = IporMath.convertWadToAssetDecimals(wadAmount, assetDecimals);
        IERC20Upgradeable(asset).safeTransferFrom(_msgSender(), address(this), amount);
        CErc20(shareToken).mint(amount);
        depositedAmount = IporMath.convertToWad(amount, assetDecimals);
    }

    /**
     * @dev withdraw from compound lending.
     * @notice withdraw can only done by AssetManagement.
     * @param wadAmount candidate amount to withdraw from compound lending, amount represented in 18 decimals
     */
    function withdraw(
        uint256 wadAmount
    ) external override whenNotPaused onlyAssetManagement returns (uint256 withdrawnAmount) {
        uint256 amount = IporMath.convertWadToAssetDecimalsWithoutRound(wadAmount, assetDecimals);

        CErc20 shareToken = CErc20(shareToken);

        // Transfer assets from Compound to Strategy
        uint256 redeemStatus = shareToken.redeem(IporMath.division(amount * 1e18, shareToken.exchangeRateStored()));

        require(redeemStatus == 0, AssetManagementErrors.SHARED_TOKEN_REDEEM_ERROR);

        uint256 withdrawnAmountCompound = IERC20Upgradeable(asset).balanceOf(address(this));

        // Transfer all assets from Strategy to AssetManagement
        IERC20Upgradeable(asset).safeTransfer(_msgSender(), withdrawnAmountCompound);

        withdrawnAmount = IporMath.convertToWad(withdrawnAmountCompound, assetDecimals);
    }

    /**
     * @dev Claim extra reward of Governace token(COMP).
     */
    function doClaim() external override whenNotPaused nonReentrant onlyOwner {
        address treasury = _treasury;

        require(treasury != address(0), IporErrors.WRONG_ADDRESS);

        address[] memory assets = new address[](1);
        assets[0] = shareToken;

        comptroller.claimComp(address(this), assets);

        uint256 balance = compToken.balanceOf(address(this));

        compToken.safeTransfer(treasury, balance);

        emit DoClaim(_msgSender(), assets[0], treasury, balance);
    }
}

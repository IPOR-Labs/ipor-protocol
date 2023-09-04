//solhint-disable no-empty-blocks
// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.20;
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";

import "../../../contracts/libraries/Constants.sol";
import "../../../contracts/libraries/math/IporMath.sol";
import "../../../contracts/vault/strategies/StrategyCore.sol";

// simple mock for total _balance tests
contract MockTestnetStrategy is StrategyCore {
    using SafeERC20Upgradeable for IERC20Upgradeable;

    // in wad
    uint256 private constant _APY = 35000000000000000;
    uint256 private _depositsBalance;
    uint256 private _lastUpdateBalance;

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor(
        address assetInput,
        uint256 assetDecimalsInput,
        address shareTokenInput,
        address assetManagementInput
    ) StrategyCore(assetInput, assetDecimalsInput, shareTokenInput, assetManagementInput) {
        _disableInitializers();
    }

    function initialize() public initializer nonReentrant {
        __Pausable_init();
        __Ownable_init();
        __UUPSUpgradeable_init();

        _treasuryManager = _msgSender();
    }

    function getApy() external pure override returns (uint256) {
        return _APY;
    }

    function balanceOf() external view returns (uint256 newDepositsBalance) {
        return _calculateNewBalance();
    }

    function deposit(uint256 wadAmount) external override onlyAssetManagement returns (uint256 depositedAmount) {
        uint256 assetDecimals = IERC20Metadata(asset).decimals();

        uint256 amount = IporMath.convertWadToAssetDecimals(wadAmount, assetDecimals);

        uint256 newDepositsBalance = _calculateNewBalance() +
            IporMath.convertToWad(amount, IERC20Metadata(asset).decimals());
        _depositsBalance = newDepositsBalance;
        _lastUpdateBalance = block.timestamp;
        IERC20Upgradeable(asset).safeTransferFrom(_msgSender(), address(this), amount);
        return IporMath.convertToWad(amount, assetDecimals);
    }

    function withdraw(uint256 wadAmount) external override onlyAssetManagement returns (uint256) {
        uint256 amount = IporMath.convertWadToAssetDecimals(wadAmount, IERC20Metadata(asset).decimals());
        uint256 newDepositsBalance = _calculateNewBalance() -
            IporMath.convertToWad(amount, IERC20Metadata(asset).decimals());
        _depositsBalance = newDepositsBalance;
        _lastUpdateBalance = block.timestamp;
        IERC20Upgradeable(asset).safeTransfer(_msgSender(), amount);

        return wadAmount;
    }

    function updateDepositsBalance(uint256 newDepositsBalance) external onlyOwner {
        _depositsBalance = newDepositsBalance;
    }

    function getDepositsBalance() external view returns (uint256) {
        return _depositsBalance;
    }

    function doClaim() external override onlyOwner {}

    function beforeClaim() external onlyOwner {}

    function _calculateNewBalance() internal view returns (uint256 newDepositsBalance) {
        uint256 depositsBalance = _depositsBalance;
        uint256 percent = IporMath.division(_APY, Constants.YEAR_IN_SECONDS) * (block.timestamp - _lastUpdateBalance);
        newDepositsBalance = depositsBalance + IporMath.percentOf(depositsBalance, percent);
    }
}

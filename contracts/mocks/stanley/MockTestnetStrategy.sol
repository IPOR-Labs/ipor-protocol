//solhint-disable no-empty-blocks
// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.15;
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";

import "../../security/IporOwnableUpgradeable.sol";
import "../../vault/strategies/StrategyCore.sol";
import "../../libraries/math/IporMath.sol";
import "../../libraries/Constants.sol";

// simple mock for total _balance tests
contract MockTestnetStrategy is StrategyCore {
    using SafeERC20Upgradeable for IERC20Upgradeable;

    // in wad
    uint256 private constant _APR = 35000000000000000;
    uint256 private _depositsBalance;
    uint256 private _lastUpdateBalance;

    function initialize(address asset, address shareToken) public initializer nonReentrant {
        __Ownable_init();

        require(asset != address(0), IporErrors.WRONG_ADDRESS);
        require(shareToken != address(0), IporErrors.WRONG_ADDRESS);

        _asset = asset;
        _treasuryManager = _msgSender();
        _shareToken = shareToken;
    }

    function getApr() external pure override returns (uint256) {
        return _APR;
    }

    function balanceOf() external view returns (uint256 newDepositsBalance) {
        return _calculateNewBalance();
    }

    function deposit(uint256 wadAmount) external override onlyStanley {
        address asset = _asset;

        uint256 amount = IporMath.convertWadToAssetDecimals(
            wadAmount,
            IERC20Metadata(asset).decimals()
        );
        uint256 newDepositsBalance = _calculateNewBalance() +
            IporMath.convertToWad(amount, IERC20Metadata(asset).decimals());
        _depositsBalance = newDepositsBalance;
        _lastUpdateBalance = block.timestamp;
        IERC20Upgradeable(asset).safeTransferFrom(_msgSender(), address(this), amount);
    }

    function withdraw(uint256 wadAmount) external override onlyStanley {
        address asset = _asset;
        uint256 amount = IporMath.convertWadToAssetDecimals(
            wadAmount,
            IERC20Metadata(asset).decimals()
        );
        uint256 newDepositsBalance = _calculateNewBalance() -
            IporMath.convertToWad(amount, IERC20Metadata(asset).decimals());
        _depositsBalance = newDepositsBalance;
        _lastUpdateBalance = block.timestamp;
        IERC20Upgradeable(asset).safeTransfer(_msgSender(), amount);
    }

    function doClaim() external override onlyOwner {}

    function beforeClaim() external onlyOwner {}

    function _calculateNewBalance() internal view returns (uint256 newDepositsBalance) {
        uint256 depositsBalance = _depositsBalance;
        uint256 percent = IporMath.division(_APR, Constants.YEAR_IN_SECONDS) *
            (block.timestamp - _lastUpdateBalance);
        newDepositsBalance = depositsBalance + IporMath.percentOf(depositsBalance, percent);
    }
}

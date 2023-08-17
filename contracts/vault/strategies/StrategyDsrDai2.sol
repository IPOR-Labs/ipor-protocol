// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.16;

import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "@openzeppelin/contracts/utils/math/SafeCast.sol";
import "../../libraries/errors/AssetManagementErrors.sol";
import "../../libraries/math/IporMath.sol";
import "../../security/IporOwnableUpgradeable.sol";
import "../interfaces/dsr/IPot.sol";
import "../interfaces/dsr/ISavingsDai.sol";
import "../../interfaces/IStrategyDsr.sol";

contract StrategyDsrDai is
    Initializable,
    PausableUpgradeable,
    ReentrancyGuardUpgradeable,
    UUPSUpgradeable,
    IporOwnableUpgradeable,
    IStrategyDsr
{
    using SafeCast for uint256;
    using SafeERC20Upgradeable for IERC20Upgradeable;

    address internal immutable _asset;
    address internal immutable _shareToken;
    address internal immutable _stanley;
    address internal immutable _pot;

    modifier onlyStanley() {
        require(_msgSender() == _stanley, StanleyErrors.CALLER_NOT_STANLEY);
        _;
    }

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor(
        address asset,
        address shareToken,
        address stanley
    ) {
        require(asset != address(0), IporErrors.WRONG_ADDRESS);
        require(shareToken != address(0), IporErrors.WRONG_ADDRESS);
        require(stanley != address(0), IporErrors.WRONG_ADDRESS);

        _asset = asset;
        _shareToken = shareToken;
        _stanley = stanley;
        _pot = ISavingsDai(shareToken).pot();

        _disableInitializers();
    }

    function initialize() public initializer nonReentrant {
        __Pausable_init();
        __Ownable_init();
        __UUPSUpgradeable_init();

        IERC20Upgradeable(_asset).safeApprove(_shareToken, type(uint256).max);
    }

    function getVersion() external pure override returns (uint256) {
        return 1;
    }

    function getAsset() external view override returns (address) {
        return _asset;
    }

    function getShareToken() external view override returns (address) {
        return _shareToken;
    }

    function getStanley() external view override returns (address) {
        return _stanley;
    }

    function getApr() external view override returns (uint256 apy) {
        return IporMath.convertToWad(IporMath.rayPow(IPot(_pot).dsr(), 365 days) - 1e27, 27);
    }

    function balanceOf() external view override returns (uint256) {
        uint256 shares = ISavingsDai(_shareToken).balanceOf(address(this));
        return ISavingsDai(_shareToken).convertToAssets(shares);
    }

    function deposit(uint256 wadAmount)
        external
        override
        whenNotPaused
        onlyStanley
        returns (uint256 depositedAmount)
    {
        IERC20Upgradeable(_asset).safeTransferFrom(_msgSender(), address(this), wadAmount);
        ISavingsDai(_shareToken).deposit(wadAmount, address(this));
        depositedAmount = wadAmount;
    }

    function withdraw(uint256 wadAmount)
        external
        override
        whenNotPaused
        onlyStanley
        returns (uint256 withdrawnAmount)
    {
        ISavingsDai(_shareToken).withdraw(wadAmount, _msgSender(), address(this));
        withdrawnAmount = wadAmount;
    }

    function pause() external override onlyOwner {
        _pause();
    }

    function unpause() external override onlyOwner {
        _unpause();
    }

    //solhint-disable no-empty-blocks
    function _authorizeUpgrade(address) internal override onlyOwner {}
}

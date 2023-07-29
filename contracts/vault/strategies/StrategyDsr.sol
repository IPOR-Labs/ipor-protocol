// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.16;

import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "@openzeppelin/contracts/utils/math/SafeCast.sol";
//import "@openzeppelin/contracts/access/Ownable.sol";
import "../../libraries/errors/StanleyErrors.sol";
import "../../libraries/math/IporMath.sol";
import "../../security/IporOwnableUpgradeable.sol";
import "../interfaces/dsr/IDsrManager.sol";
import "../interfaces/dsr/IPot.sol";
import "../../interfaces/IStrategyDsr.sol";
import "forge-std/console2.sol";

contract StrategyDsr is
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
    address internal immutable _dsrManager;
    address internal immutable _pot;

    modifier onlyStanley() {
        require(_msgSender() == _stanley, StanleyErrors.CALLER_NOT_STANLEY);
        _;
    }

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor(
        address asset,
        address shareToken,
        address stanley,
        address dsrManager,
        address pot
    ) {
        require(asset != address(0), IporErrors.WRONG_ADDRESS);
        require(shareToken != address(0), IporErrors.WRONG_ADDRESS);
        require(stanley != address(0), IporErrors.WRONG_ADDRESS);
        require(dsrManager != address(0), IporErrors.WRONG_ADDRESS);
        require(pot != address(0), IporErrors.WRONG_ADDRESS);

        _asset = asset;
        _shareToken = shareToken;
        _stanley = stanley;
        _dsrManager = dsrManager;
        _pot = pot;

        _disableInitializers();
    }

    function initialize() public initializer nonReentrant {
        __Pausable_init();
        __Ownable_init();
        __UUPSUpgradeable_init();
        IERC20Upgradeable(_asset).safeApprove(dsrManager, type(uint256).max);
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

    /// @notice Returns current APY from Dai Savings Rate
    /// @dev APY = dsr^(365*24*60*60), dsr represented in 27 decimals
    /// @return apy Current APY, represented in 18 decimals
    function getApr() external view override returns (uint256 apy) {
        uint256 aproxRatePerDay = (IPot(_pot).dsr() - 1e27) * 1 days + 1e27;

        uint256 ratePerDay2 = IporMath.division(aproxRatePerDay * aproxRatePerDay, 1e27);
        uint256 ratePerDay4 = IporMath.division(ratePerDay2 * ratePerDay2, 1e27);
        uint256 ratePerDay8 = IporMath.division(ratePerDay4 * ratePerDay4, 1e27);
        uint256 ratePerDay16 = IporMath.division(ratePerDay8 * ratePerDay8, 1e27);
        uint256 ratePerDay32 = IporMath.division(ratePerDay16 * ratePerDay16, 1e27);
        uint256 ratePerDay64 = IporMath.division(ratePerDay32 * ratePerDay32, 1e27);
        uint256 ratePerDay128 = IporMath.division(ratePerDay64 * ratePerDay64, 1e27);
        uint256 ratePerDay256 = IporMath.division(ratePerDay128 * ratePerDay128, 1e27);
        uint256 ratePerDay40 = IporMath.division(ratePerDay32 * ratePerDay8, 1e27);
        uint256 ratePerDay104 = IporMath.division(ratePerDay64 * ratePerDay40, 1e27);
        uint256 ratePerDay360 = IporMath.division(ratePerDay256 * ratePerDay104, 1e27);
        apy = IporMath.convertToWad(
            IporMath.division(
                ratePerDay360 * IporMath.division(ratePerDay4 * aproxRatePerDay, 1e27),
                1e27
            ) - 1e27,
            27
        );
    }

    function balanceOf() external override returns (uint256) {
        uint256 balance = IDsrManager(_dsrManager).daiBalance(_asset);
        return balance;
    }

    function deposit(uint256 wadAmount)
        external
        override
        whenNotPaused
        onlyStanley
        returns (uint256 depositedAmount)
    {
        console2.log("Approve 1");
        IERC20Upgradeable(_asset).safeTransferFrom(_msgSender(), address(this), wadAmount);
        console2.log("Approve 2");
        IDsrManager(_dsrManager).join(address(this), wadAmount);
        depositedAmount = wadAmount;
    }

    function withdraw(uint256 wadAmount)
        external
        override
        whenNotPaused
        onlyStanley
        returns (uint256 withdrawnAmount)
    {
        IDsrManager(_dsrManager).exit(_msgSender(), wadAmount);
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

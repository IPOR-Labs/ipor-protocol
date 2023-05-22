// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.16;

import "@openzeppelin/contracts/utils/math/SafeCast.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/IERC20MetadataUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "../libraries/errors/IporErrors.sol";
import "../libraries/Constants.sol";
import "../interfaces/IMiltonInternal.sol";
import "../interfaces/IMiltonStorage.sol";
import "../interfaces/IStanley.sol";
import "../security/IporOwnableUpgradeable.sol";

abstract contract MiltonInternal is
    Initializable,
    PausableUpgradeable,
    ReentrancyGuardUpgradeable,
    UUPSUpgradeable,
    IporOwnableUpgradeable,
    IMiltonInternal
{
    using SafeERC20Upgradeable for IERC20Upgradeable;

    address internal immutable _asset;
    uint256 internal immutable _decimals;
    address internal immutable _ammStorage;
    address internal immutable _assetManagement;
    address internal immutable _iporProtocolRouter;

    /// @dev DEPRECATED, can be renamed and reused in future for other purposes
    address public assetDeprecated;

    /// @dev DEPRECATED, can be renamed and reused in future for other purposes
    address public josephDeprecated;

    /// @dev DEPRECATED, can be renamed and reused in future for other purposes
    address public stanleyDeprecated;

    /// @dev DEPRECATED, can be renamed and reused in future for other purposes
    address public iporOracleDeprecated;

    /// @dev DEPRECATED, can be renamed and reused in future for other purposes
    address public miltonStorageDeprecated;

    /// @dev DEPRECATED, can be renamed and reused in future for other purposes
    address public miltonSpreadModelDeprecated;

    /// DEPRECATED, can be renamed and reused in future for other purposes
    uint32 public autoUpdateIporIndexThresholdDeprecated;

    /// DEPRECATED, can be renamed and reused in future for other purposes
    mapping(address => bool) public swapLiquidatorsDeprecated;

    constructor(
        address assetAddress,
        uint256 decimals,
        address ammStorage,
        address assetManagement,
        address iporProtocolRouter
    ) {
        _disableInitializers();

        _asset = assetAddress;
        _decimals = decimals;
        _ammStorage = ammStorage;
        _assetManagement = assetManagement;
        _iporProtocolRouter = iporProtocolRouter;

    }

    //TODO: onlyRouter()
    modifier onlyIporProtocolRouter() {
        require(_msgSender() == _iporProtocolRouter, IporErrors.CALLER_NOT_IPOR_PROTOCOL_ROUTER);
        _;
    }

    /// @notice Joseph deposits to Stanley asset amount from Milton.
    /// @param assetAmount underlying token amount represented in 18 decimals
    function depositToStanley(uint256 assetAmount) external onlyIporProtocolRouter nonReentrant whenNotPaused {
        (uint256 vaultBalance, uint256 depositedAmount) = IStanley(_assetManagement).deposit(assetAmount);
        IMiltonStorage(_ammStorage).updateStorageWhenDepositToStanley(depositedAmount, vaultBalance);
    }

    //@param assetAmount underlying token amount represented in 18 decimals
    function withdrawFromStanley(uint256 assetAmount) external nonReentrant onlyIporProtocolRouter whenNotPaused {
        (uint256 withdrawnAmount, uint256 vaultBalance) = IStanley(_assetManagement).withdraw(assetAmount);
        IMiltonStorage(_ammStorage).updateStorageWhenWithdrawFromStanley(withdrawnAmount, vaultBalance);
    }

    function withdrawAllFromStanley() external nonReentrant onlyIporProtocolRouter whenNotPaused {
        (uint256 withdrawnAmount, uint256 vaultBalance) = IStanley(_assetManagement).withdrawAll();
        IMiltonStorage(_ammStorage).updateStorageWhenWithdrawFromStanley(withdrawnAmount, vaultBalance);
    }

    function pause() external override onlyOwner {
        _pause();
    }

    function unpause() external override onlyOwner {
        _unpause();
    }

    function setupMaxAllowanceForAsset(address spender) external override onlyOwner whenNotPaused {
        IERC20Upgradeable(_asset).safeIncreaseAllowance(spender, Constants.MAX_VALUE);
    }
}

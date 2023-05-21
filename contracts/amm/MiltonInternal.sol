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
import "../libraries/errors/MiltonErrors.sol";
import "../libraries/Constants.sol";
import "../interfaces/types/IporTypes.sol";
import "../interfaces/IIpToken.sol";
import "../interfaces/IIporOracle.sol";
import "../interfaces/IIporRiskManagementOracle.sol";
import "../interfaces/IMiltonInternal.sol";
import "../interfaces/IMiltonStorage.sol";
import "../interfaces/IMiltonSpreadModel.sol";
import "../interfaces/IStanley.sol";
import "./libraries/IporSwapLogic.sol";
import "../security/IporOwnableUpgradeable.sol";
import "./libraries/types/AmmMiltonTypes.sol";

abstract contract MiltonInternal is
    Initializable,
    PausableUpgradeable,
    ReentrancyGuardUpgradeable,
    UUPSUpgradeable,
    IporOwnableUpgradeable,
    IMiltonInternal
{
    using SafeERC20Upgradeable for IERC20Upgradeable;
    using IporSwapLogic for IporTypes.IporSwapMemory;

    address internal immutable _router;
    address internal immutable _asset;
    uint256 internal immutable _decimals;
    address internal immutable _ammStorage;
    address internal immutable _assetManagement;

    /// @dev DEPRECATED, can be renamed and reused in future for other purposes
    address public asset;

    /// @dev DEPRECATED, can be renamed and reused in future for other purposes
    address public joseph;

    /// @dev DEPRECATED, can be renamed and reused in future for other purposes
    address public stanley;

    /// @dev DEPRECATED, can be renamed and reused in future for other purposes
    address public iporOracle;

    /// @dev DEPRECATED, can be renamed and reused in future for other purposes
    address public miltonStorage;

    /// @dev DEPRECATED, can be renamed and reused in future for other purposes
    address public miltonSpreadModel;

    /// DEPRECATED, can be renamed and reused in future for other purposes
    uint32 public autoUpdateIporIndexThreshold;

    /// DEPRECATED, can be renamed and reused in future for other purposes
    mapping(address => bool) public swapLiquidators;

    constructor(
        address routerAddress,
        address assetAddress,
        uint256 decimals,
        address ammStorage,
        address assetManagement
    ) {
        _disableInitializers();
        _router = routerAddress;
        _asset = assetAddress;
        _decimals = decimals;
        _ammStorage = ammStorage;
        _assetManagement = assetManagement;
    }

    modifier onlyIporProtocolRouter() {
        require(_msgSender() == _router, IporErrors.CALLER_NOT_IPOR_PROTOCOL_ROUTER);
        _;
    }

    function calculateSoapAtTimestamp(uint256 calculateTimestamp)
        external
        view
        override
        returns (
            int256 soapPayFixed,
            int256 soapReceiveFixed,
            int256 soap
        )
    {
        (int256 _soapPayFixed, int256 _soapReceiveFixed, int256 _soap) = _calculateSoap(calculateTimestamp);
        return (soapPayFixed = _soapPayFixed, soapReceiveFixed = _soapReceiveFixed, soap = _soap);
    }

    function calculatePayoffPayFixed(IporTypes.IporSwapMemory memory swap) external view override returns (int256) {
        uint256 accruedIbtPrice = IIporOracle(iporOracle).calculateAccruedIbtPrice(_asset, block.timestamp);
        return swap.calculatePayoffPayFixed(block.timestamp, accruedIbtPrice);
    }

    function calculatePayoffReceiveFixed(IporTypes.IporSwapMemory memory swap) external view override returns (int256) {
        uint256 accruedIbtPrice = IIporOracle(iporOracle).calculateAccruedIbtPrice(_asset, block.timestamp);
        return swap.calculatePayoffReceiveFixed(block.timestamp, accruedIbtPrice);
    }

    /// @notice Joseph deposits to Stanley asset amount from Milton.
    /// @param assetAmount underlying token amount represented in 18 decimals
    function depositToStanley(uint256 assetAmount) external onlyIporProtocolRouter nonReentrant whenNotPaused {
        (uint256 vaultBalance, uint256 depositedAmount) = IStanley(_assetManagement).deposit(assetAmount);
        IMiltonStorage(_ammStorage).updateStorageWhenDepositToStanley(depositedAmount, vaultBalance);
    }

    //@param assetAmount underlying token amount represented in 18 decimals
    function withdrawFromStanley(uint256 assetAmount) external nonReentrant onlyIporProtocolRouter whenNotPaused {
        _withdrawFromStanley(assetAmount);
    }

    //@param assetAmount underlying token amount represented in 18 decimals
    function _withdrawFromStanley(uint256 assetAmount) internal {
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

    function _getDecimals() internal view returns (uint256) {
        return _decimals;
    }

    function _calculateSoap(uint256 calculateTimestamp)
        internal
        view
        returns (
            int256 soapPayFixed,
            int256 soapReceiveFixed,
            int256 soap
        )
    {
        uint256 accruedIbtPrice = IIporOracle(iporOracle).calculateAccruedIbtPrice(_asset, calculateTimestamp);
        (int256 _soapPayFixed, int256 _soapReceiveFixed, int256 _soap) = IMiltonStorage(_ammStorage).calculateSoap(
            accruedIbtPrice,
            calculateTimestamp
        );
        return (soapPayFixed = _soapPayFixed, soapReceiveFixed = _soapReceiveFixed, soap = _soap);
    }
}

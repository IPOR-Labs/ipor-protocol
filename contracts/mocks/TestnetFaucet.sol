// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.9;

import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "../security/IporOwnableUpgradeable.sol";
import "../libraries/errors/MocksErrors.sol";
import "../interfaces/ITestnetFaucet.sol";
import "hardhat/console.sol";

contract TestnetFaucet is
    UUPSUpgradeable,
    IporOwnableUpgradeable,
    ReentrancyGuardUpgradeable,
    ITestnetFaucet
{
    using SafeERC20Upgradeable for IERC20Upgradeable;

    uint256 constant _SECUND_IN_DAY = 60 * 60 * 24;

    mapping(address => uint256) internal _lastClaim;
    address internal _dai;
    address internal _usdc;
    address internal _usdt;

    function initialize(
        address dai,
        address usdc,
        address usdt
    ) public initializer {
        __Ownable_init();
        require(dai != address(0), IporErrors.WRONG_ADDRESS);
        require(usdc != address(0), IporErrors.WRONG_ADDRESS);
        require(usdt != address(0), IporErrors.WRONG_ADDRESS);
        _dai = dai;
        _usdc = usdc;
        _usdt = usdt;
    }

    function getVersion() external pure virtual returns (uint256) {
        return 1;
    }

    function claim() external override nonReentrant {
        uint256 secondsToNextClaim = _couldClaimInSeconds();
        require(
            secondsToNextClaim == 0,
            string(
                abi.encodePacked(
                    MocksErrors.CAN_CLAIM_ONCE_EVERY_24H,
                    ": ",
                    Strings.toString(secondsToNextClaim)
                )
            )
        );
        _transfer(_dai);
        _transfer(_usdc);
        _transfer(_usdt);
        _lastClaim[_msgSender()] = block.timestamp;
    }

    function couldClaimInSeconds() external view override returns (uint256) {
        return _couldClaimInSeconds();
    }

    function balanceOf(address asset) external view override returns (uint256) {
        return IERC20Upgradeable(asset).balanceOf(address(this));
    }

    function _transfer(address asset) internal {
        ERC20Upgradeable token = ERC20Upgradeable(asset);
        uint256 value;
        if (_lastClaim[_msgSender()] == 0) {
            value = 100_000 * 10**token.decimals();
        } else {
            value = 10_000 * 10**token.decimals();
        }
        IERC20Upgradeable(asset).safeTransfer(msg.sender, value);
        emit Claim(_msgSender(), address(asset), value);
    }

    function _couldClaimInSeconds() internal view returns (uint256) {
        uint256 lastDraw = _lastClaim[_msgSender()];
        uint256 blockTimestamp = block.timestamp;
        if (blockTimestamp - lastDraw > _SECUND_IN_DAY) {
            return 0;
        }
        return _SECUND_IN_DAY - (blockTimestamp - lastDraw);
    }

    //solhint-disable no-empty-blocks
    function _authorizeUpgrade(address) internal override onlyOwner {}
}

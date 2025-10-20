// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {UUPSUpgradeable} from "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import {CountersUpgradeable} from "@openzeppelin/contracts-upgradeable/utils/CountersUpgradeable.sol";
import {PausableUpgradeable} from "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import {ECDSAUpgradeable} from "@openzeppelin/contracts-upgradeable/utils/cryptography/ECDSAUpgradeable.sol";
import {EIP712Upgradeable} from "@openzeppelin/contracts-upgradeable/utils/cryptography/EIP712Upgradeable.sol";
import {AccessControlUpgradeable} from "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import {ERC4626Upgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/ERC4626Upgradeable.sol";
import {IERC20MetadataUpgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/ERC4626Upgradeable.sol";
import {IERC20PermitUpgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/IERC20PermitUpgradeable.sol";

/**
 * @dev USDM Interface.
 */
interface IUSDM is IERC20MetadataUpgradeable {
    /**
     * @dev Checks if the specified address is blocked.
     */
    function isBlocked(address) external view returns (bool);

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() external view returns (bool);

    /**
  * @notice Creates new tokens to the specified address.
     * @dev See {_mint}.
     * @param to The address to mint the tokens to.
     * @param amount The amount of tokens to mint.
     */
    function mint(address to, uint256 amount) external;

}

/**
 * @title Wrapped Mountain Protocol USDM
 * @custom:security-contact security@mountainprotocol.com
 */
contract WUsdmMock is
    ERC4626Upgradeable,
    AccessControlUpgradeable,
    PausableUpgradeable,
    UUPSUpgradeable,
    IERC20PermitUpgradeable,
    EIP712Upgradeable
{
    using CountersUpgradeable for CountersUpgradeable.Counter;

    IUSDM public USDM;

    // Mapping of nonces per address
    mapping(address account => CountersUpgradeable.Counter counter) private _nonces;
    // solhint-disable-next-line var-name-mixedcase
    bytes32 private constant _PERMIT_TYPEHASH =
        keccak256("Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)");

    // Access control roles
    bytes32 public constant PAUSE_ROLE = keccak256("PAUSE_ROLE");
    bytes32 public constant UPGRADE_ROLE = keccak256("UPGRADE_ROLE");

    // ERC2612 Errors
    error ERC2612ExpiredDeadline(uint256 deadline, uint256 blockTimestamp);
    error ERC2612InvalidSignature(address owner, address spender);

    // wUSDM Errors
    error wUSDMBlockedSender(address sender);
    error wUSDMPausedTransfers();

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    /**
     * @notice Initializes the ERC-4626 USDM Wrapper.
     * @param _USDM The address of the USDM token to wrap.
     * @param owner The owner address.
     */
    function initialize(IUSDM _USDM, address owner) external initializer {
        USDM = _USDM;

        __ERC20_init("Wrapped Mountain Protocol USD", "wUSDM");
        __ERC4626_init(_USDM);
        __AccessControl_init();
        __Pausable_init();
        __UUPSUpgradeable_init();
        __EIP712_init("Wrapped Mountain Protocol USD", "1");

        _grantRole(DEFAULT_ADMIN_ROLE, owner);
    }

    /**
     * @notice We override paused to use the underlying paused state as well.
     * @return Returns true if USDM or wUSDM is paused, and false otherwise.
     */
    function paused() public view override returns (bool) {
        return USDM.paused() || super.paused();
    }

    /**
     * @notice Pauses token transfers and other operations.
     * @dev This function can only be called by an account with PAUSE_ROLE.
     * @dev Inherits the _pause function from @openzeppelin/PausableUpgradeable contract.
     */
    function pause() external onlyRole(PAUSE_ROLE) {
        super._pause();
    }

    /**
     * @notice Unpauses token transfers and other operations.
     * @dev This function can only be called by an account with PAUSE_ROLE.
     * @dev Inherits the _unpause function from @openzeppelin/PausableUpgradeable contract.
     */
    function unpause() external onlyRole(PAUSE_ROLE) {
        super._unpause();
    }

    /**
     * @dev Private function of a hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * @param from The address from which tokens are being transferred.
     * @param to The address to which tokens are being transferred.
     * @param amount The amount of tokens being transferred.
     *
     * Note: If either `from` or `to` are blocked, or the contract is paused, it reverts the transaction.
     */
    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual override {
        // Each blocklist check is an SLOAD, which is gas intensive.
        // We only block sender not receiver, so we don't tax every user
        if (USDM.isBlocked(from)) {
            revert wUSDMBlockedSender(from);
        }

        // Useful for scenarios such as preventing trades until the end of an evaluation
        // period, or having an emergency switch for freezing all token transfers in the
        // event of a large bug.
        if (paused()) {
            revert wUSDMPausedTransfers();
        }

        super._beforeTokenTransfer(from, to, amount);
    }

    /**
     * @dev Ensures that only accounts with UPGRADE_ROLE can upgrade the contract.
     */
    function _authorizeUpgrade(address) internal override onlyRole(UPGRADE_ROLE) {}

    /**
     * @dev See {IERC20PermitUpgradeable-permit}.
     */
    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external {
        if (block.timestamp > deadline) {
            revert ERC2612ExpiredDeadline(deadline, block.timestamp);
        }

        bytes32 structHash = keccak256(abi.encode(_PERMIT_TYPEHASH, owner, spender, value, _useNonce(owner), deadline));
        bytes32 hash = _hashTypedDataV4(structHash);
        address signer = ECDSAUpgradeable.recover(hash, v, r, s);

        if (signer != owner) {
            revert ERC2612InvalidSignature(owner, spender);
        }

        _approve(owner, spender, value);
    }

    /**
     * @dev See {IERC20PermitUpgradeable-nonces}.
     */
    function nonces(address owner) external view returns (uint256) {
        return _nonces[owner].current();
    }

    /**
     * @dev See {IERC20PermitUpgradeable-DOMAIN_SEPARATOR}.
     */
    function DOMAIN_SEPARATOR() external view returns (bytes32) {
        return _domainSeparatorV4();
    }

    /**
     * @dev "Consume a nonce": return the current value and increment.
     * @param owner The owner address.
     *
     * _Available since v4.1._
     */
    function _useNonce(address owner) private returns (uint256 current) {
        CountersUpgradeable.Counter storage nonce = _nonces[owner];
        current = nonce.current();

        nonce.increment();
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[48] private __gap;
}

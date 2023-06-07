// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.20;
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "../libraries/errors/IporErrors.sol";

/// @title IPOR Token in standard ERC20.
contract IporToken is ERC20 {
    /**
     * @dev Contract id.
     * This is the keccak-256 hash of "io.ipor.IporToken" subtracted by 1
     */
    function getContractId() external pure returns (bytes32) {
        return 0xdba05ed67d0251facfcab8345f27ccd3e72b5a1da8cebfabbcccf4316e6d053c;
    }

    uint8 private immutable _decimals;

    constructor(
        string memory name,
        string memory symbol,
        address daoWalletAddress
    ) ERC20(name, symbol) {
        require(daoWalletAddress != address(0), string.concat(IporErrors.WRONG_ADDRESS, " DAO wallet address cannot be 0"));

        _decimals = 18;
        _mint(daoWalletAddress, 100_000_000 * 1e18);
    }

    function decimals() public view override returns (uint8) {
        return _decimals;
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.20;

import "./errors/IporErrors.sol";

library IporContractValidator {
    function checkAddress(address addr) internal pure returns (address) {
        require(addr != address(0), IporErrors.WRONG_ADDRESS);
        return addr;
    }

    function checkAddress(address addr, string memory code) internal pure returns (address) {
        if (addr == address(0)) {
            revert IporErrors.WrongAddress(code, addr, "checkAddress");
        }
        return addr;
    }
}

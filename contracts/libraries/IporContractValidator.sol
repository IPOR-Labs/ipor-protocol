// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.26;

import "./errors/IporErrors.sol";

library IporContractValidator {
    function checkAddress(address addr) internal pure returns (address) {
        require(addr != address(0), IporErrors.WRONG_ADDRESS);
        return addr;
    }
}

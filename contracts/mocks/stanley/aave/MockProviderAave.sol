// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.16;

// interfaces
import "../../../libraries/errors/IporErrors.sol";

contract MockProviderAave {
    address private _lendingPool;

    constructor(address lendingPool) {
        require(lendingPool != address(0), string.concat(IporErrors.WRONG_ADDRESS, " lending pool address cannot be 0"));

        _lendingPool = lendingPool;
    }

    function getLendingPool() external view returns (address) {
        return _lendingPool;
    }
}

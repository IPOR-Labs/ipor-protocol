// SPDX-License-Identifier: agpl-3.0
pragma solidity >=0.8.4 <0.9.0;

import "../interfaces/IIporOracle.sol";

/**
 * @title Automated Market Maker for derivatives based on IPOR Index.
 *
 * @author IPOR Labs
 */
contract Amm {
    IIporOracle public iporOracle;

    constructor(address _iporOracle) {
        iporOracle = IIporOracle(_iporOracle);
    }

    function readIndex(string memory _ticker) external view returns (uint256 value, uint256 interestBearingToken, uint256 date)  {
        (uint256 value, uint256 interestBearingToken, uint256 date) = iporOracle.getIndex(_ticker);
        return (value, interestBearingToken, date);
    }
}
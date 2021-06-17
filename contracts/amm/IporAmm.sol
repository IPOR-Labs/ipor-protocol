// SPDX-License-Identifier: agpl-3.0
pragma solidity >=0.8.4 <0.9.0;

import {Errors} from '../Errors.sol';
import "../interfaces/IIporOracle.sol";
import './IporAmmStorage.sol';

/**
 * @title Automated Market Maker for derivatives based on IPOR Index.
 *
 * @author IPOR Labs
 */
contract IporAmm is IporAmmV1Storage {

    IIporOracle public iporOracle;

    constructor(address _iporOracle) {
        admin = msg.sender;
        iporOracle = IIporOracle(_iporOracle);
    }

    function readIndex(string memory _ticker) external view returns (uint256 value, uint256 interestBearingToken, uint256 date)  {
        (uint256 _value, uint256 _interestBearingToken, uint256 _date) = iporOracle.getIndex(_ticker);
        return (_value, _interestBearingToken, _date);
    }

    /**
     * @notice Modifier which checks if caller is admin for this contract
     */
    modifier onlyAdmin() {
        require(msg.sender == admin, Errors.CALLER_NOT_IPOR_ORACLE_ADMIN);
        _;
    }
}
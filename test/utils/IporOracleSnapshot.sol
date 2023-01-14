// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.16;

import "../../contracts/interfaces/IIporOracle.sol";
import "../../contracts/interfaces/IIporOracleFacadeDataProvider.sol";

contract IporOracleSnapshot {
    address private _iporOracle;
    address iporOracleOwner;
    address iporOracleFacadeDataProviderOwner;

    uint256 public iporOracleVersion;
    uint256 public iporOracleFacadeDataProviderVersion;

    bool public iporOracleIsPaused;

    uint256 public blockNumber;

    constructor(address iporOracle) {
        _iporOracle = iporOracle;
    }

    function snapshot() public {
        IIporOracle iporOracle = IIporOracle(_iporOracle);
        IIporOracleFacadeDataProvider iporOracleFacadeDataProvider = IIporOracleFacadeDataProvider(
                _iporOracle
            );

        iporOracleOwner = iporOracle.owner();
        iporOracleFacadeDataProviderOwner = iporOracleFacadeDataProvider.owner();

        iporOracleVersion = iporOracle.getVersion();
        iporOracleFacadeDataProviderVersion = iporOracleFacadeDataProvider
            .getVersion();
        iporOracleIsPaused = iporOracle.paused();

        blockNumber = block.number;
    }
}

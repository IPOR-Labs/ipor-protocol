// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.16;
import "forge-std/Test.sol";

import "../builder/IporOracleBuilder.sol";

contract IporOracleFactory is Test {
    address internal _owner;

    IporOracleBuilder internal iporOracleBuilder;

    constructor(address owner) {
        _owner = owner;
        iporOracleBuilder = new IporOracleBuilder(owner);
    }

    function getInstance(
        address[] memory assets,
        address updater,
        BuilderUtils.IporOracleInitialParamsTestCase initialParamsTestCase
    ) public returns (ItfIporOracle) {
        iporOracleBuilder.withAssets(assets);

        (
            uint32[] memory lastUpdateTimestamps
        ) = _constructIndicatorsBasedOnInitialParamTestCase(assets, initialParamsTestCase);

        iporOracleBuilder.withLastUpdateTimestamps(lastUpdateTimestamps);

        ItfIporOracle iporOracle = iporOracleBuilder.build();

        vm.prank(_owner);
        iporOracle.addUpdater(updater);

        return iporOracle;
    }

    function _constructIndicatorsBasedOnInitialParamTestCase(
        address[] memory assets,
        BuilderUtils.IporOracleInitialParamsTestCase initialParamsTestCase
    )
        internal
        view
        returns (
            uint32[] memory lastUpdateTimestamps
        )
    {
        lastUpdateTimestamps = new uint32[](assets.length);

        uint32 lastUpdateTimestamp = uint32(block.timestamp);

        if (initialParamsTestCase == BuilderUtils.IporOracleInitialParamsTestCase.CASE1) {
            lastUpdateTimestamp = 1;
        }

        for (uint256 i = 0; i < assets.length; i++) {
            lastUpdateTimestamps[i] = lastUpdateTimestamp;
        }
    }
}

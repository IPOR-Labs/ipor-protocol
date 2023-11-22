// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.20;
import "forge-std/Test.sol";

import "../builder/IporOracleBuilder.sol";
import "../builder/BuilderUtils.sol";

contract IporOracleFactory is Test {
    address internal _owner;

    IporOracleBuilder internal iporOracleBuilder;

    struct IporOracleConstructorParams {
        address usdc;
        uint256 usdcInitialIbtPrice;
        address usdt;
        uint256 usdtInitialIbtPrice;
        address dai;
        uint256 daiInitialIbtPrice;
    }

    constructor(address owner) {
        _owner = owner;
        iporOracleBuilder = new IporOracleBuilder(owner);
    }

    function getInstance(
        address[] memory assets,
        address updater,
        BuilderUtils.IporOracleInitialParamsTestCase initialParamsTestCase,
        IporOracleConstructorParams memory constructorParams
    ) public returns (IporOracle) {
        iporOracleBuilder.withAssets(assets);

        uint32[] memory lastUpdateTimestamps = _constructIndicatorsBasedOnInitialParamTestCase(
            assets,
            initialParamsTestCase
        );

        iporOracleBuilder.withLastUpdateTimestamps(lastUpdateTimestamps);

        IporOracle iporOracleImpl = new IporOracle(
            constructorParams.usdt,
            constructorParams.usdtInitialIbtPrice,
            constructorParams.usdc,
            constructorParams.usdcInitialIbtPrice,
            constructorParams.dai,
            constructorParams.daiInitialIbtPrice,
            address(0x123)// random address for stETH
        );

        iporOracleBuilder.withIporOracleImplementation(address(iporOracleImpl));

        IporOracle iporOracle = iporOracleBuilder.build();

        vm.prank(_owner);
        iporOracle.addUpdater(updater);

        return iporOracle;
    }

    function getEmptyInstance(
        address[] memory assets,
        BuilderUtils.IporOracleInitialParamsTestCase initialParamsTestCase
    ) public returns (IporOracle) {
        iporOracleBuilder.withAssets(assets);
        uint32[] memory lastUpdateTimestamps = _constructIndicatorsBasedOnInitialParamTestCase(
            assets,
            initialParamsTestCase
        );
        iporOracleBuilder.withLastUpdateTimestamps(lastUpdateTimestamps);

        return iporOracleBuilder.buildEmptyProxy();
    }

    function upgrade(
        address iporOracleProxyAddress,
        address updater,
        IporOracleConstructorParams memory constructorParams
    ) public {
        IporOracle iporOracleImpl = new IporOracle(
            constructorParams.usdt,
            constructorParams.usdtInitialIbtPrice,
            constructorParams.usdc,
            constructorParams.usdcInitialIbtPrice,
            constructorParams.dai,
            constructorParams.daiInitialIbtPrice,
            address(0x123)// random address for stETH
        );

        iporOracleBuilder.withIporOracleImplementation(address(iporOracleImpl));

        iporOracleBuilder.upgrade(iporOracleProxyAddress);

        vm.prank(_owner);
        IporOracle(iporOracleProxyAddress).addUpdater(updater);
    }

    function _constructIndicatorsBasedOnInitialParamTestCase(
        address[] memory assets,
        BuilderUtils.IporOracleInitialParamsTestCase initialParamsTestCase
    ) internal view returns (uint32[] memory lastUpdateTimestamps) {
        lastUpdateTimestamps = new uint32[](assets.length);

        uint32 lastUpdateTimestamp = uint32(block.timestamp);

        if (initialParamsTestCase == BuilderUtils.IporOracleInitialParamsTestCase.CASE1) {
            lastUpdateTimestamp = 1;
        }

        for (uint256 i; i < assets.length; i++) {
            lastUpdateTimestamps[i] = lastUpdateTimestamp;
        }
    }
}

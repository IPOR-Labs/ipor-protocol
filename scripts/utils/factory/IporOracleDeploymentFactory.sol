// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.16;

import "../deployer/IporOracleDeployer.sol";

contract IporOracleDeploymentFactory {
    IporOracleDeployer internal iporOracleDeployer;

    struct IporOracleConstructorParams {
        address iporAlgorithmFacade;
        address usdc;
        uint256 usdcInitialIbtPrice;
        address usdt;
        uint256 usdtInitialIbtPrice;
        address dai;
        uint256 daiInitialIbtPrice;
    }

    constructor() {
        iporOracleDeployer = new IporOracleDeployer();
    }

    function getInstance(
        address[] memory assets,
        address updater,
        IporOracleConstructorParams memory constructorParams
    ) public returns (ItfIporOracle) {
        iporOracleDeployer.withAssets(assets);

        uint32[] memory lastUpdateTimestamps = getCurrentTimestamps(assets);

        iporOracleDeployer.withLastUpdateTimestamps(lastUpdateTimestamps);

        IporOracle iporOracleImpl = new IporOracle(
            constructorParams.iporAlgorithmFacade,
            constructorParams.usdt,
            constructorParams.usdtInitialIbtPrice,
            constructorParams.usdc,
            constructorParams.usdcInitialIbtPrice,
            constructorParams.dai,
            constructorParams.daiInitialIbtPrice
        );

        iporOracleDeployer.withIporOracleImplementation(address(iporOracleImpl));

        ItfIporOracle iporOracle = iporOracleDeployer.build();

        iporOracle.addUpdater(updater);

        return iporOracle;
    }

    function getEmptyInstance(address[] memory assets) public returns (ItfIporOracle) {
        iporOracleDeployer.withAssets(assets);
        uint32[] memory lastUpdateTimestamps = getCurrentTimestamps(assets);
        iporOracleDeployer.withLastUpdateTimestamps(lastUpdateTimestamps);
        return iporOracleDeployer.buildEmptyProxy();
    }

    function upgrade(
        address iporOracleProxyAddress,
        address updater,
        IporOracleConstructorParams memory constructorParams
    ) public {
        IporOracle iporOracleImpl = new IporOracle(
            constructorParams.iporAlgorithmFacade,
            constructorParams.usdt,
            constructorParams.usdtInitialIbtPrice,
            constructorParams.usdc,
            constructorParams.usdcInitialIbtPrice,
            constructorParams.dai,
            constructorParams.daiInitialIbtPrice
        );

        iporOracleDeployer.withIporOracleImplementation(address(iporOracleImpl));

        iporOracleDeployer.upgrade(iporOracleProxyAddress);

        IporOracle(iporOracleProxyAddress).addUpdater(updater);
    }

    function getCurrentTimestamps(address[] memory assets)
        internal
        view
        returns (uint32[] memory lastUpdateTimestamps)
    {
        lastUpdateTimestamps = new uint32[](assets.length);

        uint32 lastUpdateTimestamp = uint32(block.timestamp);

        for (uint256 i = 0; i < assets.length; i++) {
            lastUpdateTimestamps[i] = lastUpdateTimestamp;
        }
    }
}

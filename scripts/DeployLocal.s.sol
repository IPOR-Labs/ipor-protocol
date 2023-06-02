pragma solidity 0.8.16;

import "forge-std/Script.sol";
import "../contracts/router/IporProtocolRouter.sol";
import "../contracts/amm/AmmPoolsLens.sol";
import "../contracts/amm/AmmOpenSwapService.sol";
import "../contracts/amm/AmmGovernanceService.sol";
import "../contracts/amm/AmmSwapsLens.sol";
import "../contracts/amm/AssetManagementLens.sol";
import "../contracts/amm/AmmCloseSwapService.sol";
import "../contracts/amm/AmmPoolsService.sol";

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.16;

//import "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/IERC20MetadataUpgradeable.sol";
//import "forge-std/Test.sol";
//import "forge-std/console2.sol";
//import "contracts/mocks/tokens/MockTestnetToken.sol";
//import "contracts/tokens/IpToken.sol";
//import "contracts/tokens/IvToken.sol";
//
//import "../test/utils/Deployer/AssetDeployer.sol";
//import "../test/utils/Deployer/IpTokenDeployer.sol";
//import "../test/utils/Deployer/IvTokenDeployer.sol";
//import "../test/utils/Deployer/AmmStorageDeployer.sol";
//import "../test/utils/Deployer/AssetManagementDeployer.sol";
//import "../test/utils/Deployer/SpreadRouterDeployer.sol";
//import "../test/utils/Deployer/AmmTreasuryDeployer.sol";
//import "./utils/Deployer/IporProtocolRouterDeployer.sol";
//import "../test/utils/factory/IporOracleDeploymentFactory.sol";
//import "../test/utils/factory/IporRiskManagementOracleDeploymentFactory.sol";
//import "contracts/interfaces/IAmmSwapsLens.sol";
//import "contracts/interfaces/IAmmPoolsLens.sol";
//import "contracts/interfaces/IAssetManagementLens.sol";
//import "contracts/interfaces/IPowerTokenLens.sol";
//import "contracts/interfaces/ILiquidityMiningLens.sol";
//import "contracts/interfaces/IPowerTokenFlowsService.sol";
import "contracts/interfaces/IIporOracle.sol";
import "../contracts/oracles/IporOracle.sol";
import "../contracts/amm/spread/SpreadRouter.sol";
import "../contracts/oracles/IporRiskManagementOracle.sol";
import "./utils/deployer/DeployerUtils.sol";
import "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import "./mocks/EmptyAmmTreasuryImplementation.sol";
import "./mocks/EmptyRouterImplementation.sol";
import "../test/utils/TestConstants.sol";

//import "contracts/amm/AmmSwapsLens.sol";
//import "contracts/amm/AmmPoolsLens.sol";
//import "contracts/amm/AssetManagementLens.sol";
//import "contracts/amm/AmmOpenSwapService.sol";
//import "contracts/amm/AmmCloseSwapService.sol";
//import "contracts/amm/AmmPoolsService.sol";
//import "contracts/amm/AmmGovernanceService.sol";
//import "../test/utils/../mocks/EmptyImplementation.sol";
//import "../test/utils/Deployer/PowerTokenLensDeployer.sol";
//import "../test/utils/Deployer/LiquidityMiningLensDeployer.sol";
//import "../test/utils/Deployer/PowerTokenFlowsServiceDeployer.sol";
//import "../test/utils/Deployer/PowerTokenStakeServiceDeployer.sol";

// run:
// $ anvil
// get private key from anvil then set SC_ADMIN_PRIV_KEY variable in .env file
// then run:
// $ forge script scripts/DeployLocal.s.sol --fork-url http://127.0.0.1:8545 --broadcast
contract DeployLocal is Script {
    uint256 _private_key;
    AmmConfig ammConfig;

    function setUp() public {
        _private_key = vm.envUint("SC_ADMIN_PRIV_KEY");
        ammConfig.iporOracleUpdater = vm.envAddress("SC_MIGRATION_IPOR_INDEX_UPDATER_ADDRESS");
    }

    function run() public {
        vm.startBroadcast(_private_key);
        _getFullInstance(ammConfig);
        vm.stopBroadcast();
    }

    struct Amm {
        IporProtocolRouter router;
        SpreadRouter spreadRouter;
        IIporOracle iporOracle;
        IporRiskManagementOracle iporRiskManagementOracle;
        DeployerUtils.IporProtocol usdt;
        DeployerUtils.IporProtocol usdc;
        DeployerUtils.IporProtocol dai;
    }

    struct AmmConfig {
        address iporOracleUpdater;
        address iporRiskManagementOracleUpdater;
        address usdtAssetManagementImplementation;
        address usdcAssetManagementImplementation;
        address daiAssetManagementImplementation;
    }

    struct IporProtocolConfig {
        address iporOracleUpdater;
        address iporRiskManagementOracleUpdater;
        address[] approvalsForUsers;
        address josephImplementation;
        address spreadImplementation;
        address assetManagementImplementation;
    }

    function _getFullInstance(AmmConfig memory cfg) internal returns (Amm memory amm) {
        deployEmptyRouter(amm);
        deployEmptyTreasury(amm);
        deployAssets(amm);
        deployOracle(amm);
        deployRiskOracle(amm);
        deployIpTokens(amm);
        deployIvTokens(amm);
        deployStorage(amm);

        //
        //        _spreadRouterDeployer.withIporRouter(address(amm.router));
        //        _spreadRouterDeployer.withUsdt(address(amm.usdt.asset));
        //
        //        _spreadRouterDeployer.withUsdc(address(amm.usdc.asset));
        //        _spreadRouterDeployer.withDai(address(amm.dai.asset));
        //
        //        amm.spreadRouter = _spreadRouterDeployer.build();
        //        amm.usdt.spreadRouter = amm.spreadRouter;
        //        amm.usdc.spreadRouter = amm.spreadRouter;
        //        amm.dai.spreadRouter = amm.spreadRouter;
        //
        //        amm.usdt.assetManagement = _assetManagementDeployer
        //            .withAssetType(DeployerUtils.AssetType.USDT)
        //            .withAsset(address(amm.usdt.asset))
        //            .withIvToken(address(amm.usdt.ivToken))
        //            .withAssetManagementImplementation(cfg.usdtAssetManagementImplementation)
        //            .build();
        //
        //        amm.usdc.assetManagement = _assetManagementDeployer
        //            .withAssetType(DeployerUtils.AssetType.USDC)
        //            .withAsset(address(amm.usdc.asset))
        //            .withIvToken(address(amm.usdc.ivToken))
        //            .withAssetManagementImplementation(cfg.usdcAssetManagementImplementation)
        //            .build();
        //
        //        amm.dai.assetManagement = _assetManagementDeployer
        //            .withAssetType(DeployerUtils.AssetType.DAI)
        //            .withAsset(address(amm.dai.asset))
        //            .withIvToken(address(amm.dai.ivToken))
        //            .withAssetManagementImplementation(cfg.daiAssetManagementImplementation)
        //            .build();
        //
        //        _ammTreasuryDeployer
        //            .withAsset(address(amm.usdt.asset))
        //            .withAmmStorage(address(amm.usdt.ammStorage))
        //            .withAssetManagement(address(amm.usdt.assetManagement))
        //            .withIporProtocolRouter(address(amm.router))
        //            .withAmmTreasuryProxyAddress(address(amm.usdt.ammTreasury))
        //            .upgrade();
        //
        //        _ammTreasuryDeployer
        //            .withAsset(address(amm.usdc.asset))
        //            .withAmmStorage(address(amm.usdc.ammStorage))
        //            .withAssetManagement(address(amm.usdc.assetManagement))
        //            .withIporProtocolRouter(address(amm.router))
        //            .withAmmTreasuryProxyAddress(address(amm.usdc.ammTreasury))
        //            .upgrade();
        //
        //        _ammTreasuryDeployer
        //            .withAsset(address(amm.dai.asset))
        //            .withAmmStorage(address(amm.dai.ammStorage))
        //            .withAssetManagement(address(amm.dai.assetManagement))
        //            .withIporProtocolRouter(address(amm.router))
        //            .withAmmTreasuryProxyAddress(address(amm.dai.ammTreasury))
        //            .upgrade();
        //
        //        amm.router = _getFullIporProtocolRouterInstance(amm);
        //
        //        amm.usdt.ivToken.setAssetManagement(address(amm.usdt.assetManagement));
        //        amm.usdc.ivToken.setAssetManagement(address(amm.usdc.assetManagement));
        //        amm.dai.ivToken.setAssetManagement(address(amm.dai.assetManagement));
        //
        //        amm.usdt.ipToken.setRouter(address(amm.router));
        //        amm.usdc.ipToken.setRouter(address(amm.router));
        //        amm.dai.ipToken.setRouter(address(amm.router));
        //
        //        amm.usdt.assetManagement.setAmmTreasury((address(amm.usdt.ammTreasury)));
        //        amm.usdc.assetManagement.setAmmTreasury((address(amm.usdc.ammTreasury)));
        //        amm.dai.assetManagement.setAmmTreasury((address(amm.dai.ammTreasury)));
        //
        //        amm.usdt.ammTreasury.setupMaxAllowanceForAsset(address(amm.usdt.assetManagement));
        //        amm.usdc.ammTreasury.setupMaxAllowanceForAsset(address(amm.usdc.assetManagement));
        //        amm.dai.ammTreasury.setupMaxAllowanceForAsset(address(amm.dai.assetManagement));
        //
        //        amm.usdt.ammTreasury.setupMaxAllowanceForAsset(address(amm.router));
        //        amm.usdc.ammTreasury.setupMaxAllowanceForAsset(address(amm.router));
        //        amm.dai.ammTreasury.setupMaxAllowanceForAsset(address(amm.router));
        //
        //        IAmmGovernanceService(address(amm.router)).setAmmMaxLiquidityPoolBalance(address(amm.usdt.asset), 1000000000);
        //        IAmmGovernanceService(address(amm.router)).setAmmMaxLiquidityPoolBalance(address(amm.usdc.asset), 1000000000);
        //        IAmmGovernanceService(address(amm.router)).setAmmMaxLiquidityPoolBalance(address(amm.dai.asset), 1000000000);
        //
        //        IAmmGovernanceService(address(amm.router)).setAmmMaxLpAccountContribution(address(amm.usdt.asset), 1000000000);
        //        IAmmGovernanceService(address(amm.router)).setAmmMaxLpAccountContribution(address(amm.usdc.asset), 1000000000);
        //        IAmmGovernanceService(address(amm.router)).setAmmMaxLpAccountContribution(address(amm.dai.asset), 1000000000);
    }

    //    function _getFullIporProtocolRouterInstance(Amm memory amm) public returns (IporProtocolRouter) {
    //        if (address(amm.router) == address(0)) {
    //            amm.router = _iporProtocolRouterDeployer.buildEmptyProxy();
    //        }
    //
    //        IporProtocolRouter.DeployedContracts memory deployerContracts;
    //
    //        deployerContracts.ammSwapsLens = address(
    //            new AmmSwapsLens(
    //                IAmmSwapsLens.SwapLensConfiguration({
    //                    asset: address(amm.usdt.asset),
    //                    ammStorage: address(amm.usdt.ammStorage),
    //                    ammTreasury: address(amm.usdt.ammTreasury)
    //                }),
    //                IAmmSwapsLens.SwapLensConfiguration({
    //                    asset: address(amm.usdc.asset),
    //                    ammStorage: address(amm.usdc.ammStorage),
    //                    ammTreasury: address(amm.usdc.ammTreasury)
    //                }),
    //                IAmmSwapsLens.SwapLensConfiguration({
    //                    asset: address(amm.dai.asset),
    //                    ammStorage: address(amm.dai.ammStorage),
    //                    ammTreasury: address(amm.dai.ammTreasury)
    //                }),
    //                amm.iporOracle,
    //                address(amm.iporRiskManagementOracle),
    //                address(amm.router)
    //            )
    //        );
    //
    //        deployerContracts.ammPoolsLens = address(
    //            new AmmPoolsLens(
    //                IAmmPoolsLens.PoolConfiguration({
    //                    asset: address(amm.usdt.asset),
    //                    decimals: amm.usdt.asset.decimals(),
    //                    ipToken: address(amm.usdt.ipToken),
    //                    ammStorage: address(amm.usdt.ammStorage),
    //                    ammTreasury: address(amm.usdt.ammTreasury),
    //                    assetManagement: address(amm.usdt.assetManagement)
    //                }),
    //                IAmmPoolsLens.PoolConfiguration({
    //                    asset: address(amm.usdc.asset),
    //                    decimals: amm.usdc.asset.decimals(),
    //                    ipToken: address(amm.usdc.ipToken),
    //                    ammStorage: address(amm.usdc.ammStorage),
    //                    ammTreasury: address(amm.usdc.ammTreasury),
    //                    assetManagement: address(amm.usdc.assetManagement)
    //                }),
    //                IAmmPoolsLens.PoolConfiguration({
    //                    asset: address(amm.dai.asset),
    //                    decimals: amm.dai.asset.decimals(),
    //                    ipToken: address(amm.dai.ipToken),
    //                    ammStorage: address(amm.dai.ammStorage),
    //                    ammTreasury: address(amm.dai.ammTreasury),
    //                    assetManagement: address(amm.dai.assetManagement)
    //                }),
    //                address(amm.iporOracle)
    //            )
    //        );
    //
    //        deployerContracts.assetManagementLens = address(
    //            new AssetManagementLens(
    //                IAssetManagementLens.AssetManagementConfiguration({
    //                    asset: address(amm.usdt.asset),
    //                    decimals: amm.usdt.asset.decimals(),
    //                    assetManagement: address(amm.usdt.assetManagement),
    //                    ammTreasury: address(amm.usdt.ammTreasury)
    //                }),
    //                IAssetManagementLens.AssetManagementConfiguration({
    //                    asset: address(amm.usdc.asset),
    //                    decimals: amm.usdc.asset.decimals(),
    //                    assetManagement: address(amm.usdc.assetManagement),
    //                    ammTreasury: address(amm.usdc.ammTreasury)
    //                }),
    //                IAssetManagementLens.AssetManagementConfiguration({
    //                    asset: address(amm.dai.asset),
    //                    decimals: amm.dai.asset.decimals(),
    //                    assetManagement: address(amm.dai.assetManagement),
    //                    ammTreasury: address(amm.dai.ammTreasury)
    //                })
    //            )
    //        );
    //
    //        deployerContracts.ammOpenSwapService = address(
    //            new AmmOpenSwapService({
    //                usdtPoolCfg: _preparePoolCfgForOpenSwapService(
    //                    address(amm.usdt.asset),
    //                    address(amm.usdt.ammTreasury),
    //                    address(amm.usdt.ammStorage)
    //                ),
    //                usdcPoolCfg: _preparePoolCfgForOpenSwapService(
    //                    address(amm.usdc.asset),
    //                    address(amm.usdc.ammTreasury),
    //                    address(amm.usdc.ammStorage)
    //                ),
    //                daiPoolCfg: _preparePoolCfgForOpenSwapService(
    //                    address(amm.dai.asset),
    //                    address(amm.dai.ammTreasury),
    //                    address(amm.dai.ammStorage)
    //                ),
    //                iporOracle: address(amm.iporOracle),
    //                iporRiskManagementOracle: address(amm.iporRiskManagementOracle),
    //                spreadRouter: address(amm.spreadRouter)
    //            })
    //        );
    //
    //        deployerContracts.ammCloseSwapService = address(
    //            new AmmCloseSwapService({
    //                usdtPoolCfg: _preparePoolCfgForCloseSwapService(
    //                    address(amm.usdt.asset),
    //                    address(amm.usdt.ammTreasury),
    //                    address(amm.usdt.ammStorage),
    //                    address(amm.usdt.assetManagement)
    //                ),
    //                usdcPoolCfg: _preparePoolCfgForCloseSwapService(
    //                    address(amm.usdc.asset),
    //                    address(amm.usdc.ammTreasury),
    //                    address(amm.usdc.ammStorage),
    //                    address(amm.usdc.assetManagement)
    //                ),
    //                daiPoolCfg: _preparePoolCfgForCloseSwapService(
    //                    address(amm.dai.asset),
    //                    address(amm.dai.ammTreasury),
    //                    address(amm.dai.ammStorage),
    //                    address(amm.dai.assetManagement)
    //                ),
    //                iporOracle: address(amm.iporOracle),
    //                iporRiskManagementOracle: address(amm.iporRiskManagementOracle),
    //                spreadRouter: address(amm.spreadRouter)
    //            })
    //        );
    //
    //        deployerContracts.ammPoolsService = address(
    //            new AmmPoolsService({
    //                usdtPoolCfg: _preparePoolCfgForPoolsService(
    //                    address(amm.usdt.asset),
    //                    address(amm.usdt.ipToken),
    //                    address(amm.usdt.ammTreasury),
    //                    address(amm.usdt.ammStorage),
    //                    address(amm.usdt.assetManagement)
    //                ),
    //                usdcPoolCfg: _preparePoolCfgForPoolsService(
    //                    address(amm.usdc.asset),
    //                    address(amm.usdc.ipToken),
    //                    address(amm.usdc.ammTreasury),
    //                    address(amm.usdc.ammStorage),
    //                    address(amm.usdc.assetManagement)
    //                ),
    //                daiPoolCfg: _preparePoolCfgForPoolsService(
    //                    address(amm.dai.asset),
    //                    address(amm.dai.ipToken),
    //                    address(amm.dai.ammTreasury),
    //                    address(amm.dai.ammStorage),
    //                    address(amm.dai.assetManagement)
    //                ),
    //                iporOracle: address(amm.iporOracle)
    //            })
    //        );
    //
    //        deployerContracts.ammGovernanceService = address(
    //            new AmmGovernanceService({
    //                usdtPoolCfg: _preparePoolCfgForGovernanceService(
    //                    address(amm.usdt.asset),
    //                    address(amm.usdt.ammTreasury),
    //                    address(amm.usdt.ammStorage)
    //                ),
    //                usdcPoolCfg: _preparePoolCfgForGovernanceService(
    //                    address(amm.usdc.asset),
    //                    address(amm.usdc.ammTreasury),
    //                    address(amm.usdc.ammStorage)
    //                ),
    //                daiPoolCfg: _preparePoolCfgForGovernanceService(
    //                    address(amm.dai.asset),
    //                    address(amm.dai.ammTreasury),
    //                    address(amm.dai.ammStorage)
    //                )
    //            })
    //        );
    //
    //        //        deployerContracts.powerTokenLens = address(_powerTokenLensDeployer.build());
    //        //        deployerContracts.liquidityMiningLens = address(_liquidityMiningLensDeployer.build());
    //        //        deployerContracts.flowService = address(_powerTokenFlowsServiceDeployer.build());
    //        //        deployerContracts.stakeService = address(_powerTokenStakeServiceDeployer.build());
    //
    //        IporProtocolRouter(amm.router).upgradeTo(address(new IporProtocolRouter(deployerContracts)));
    //
    //        amm.usdt.ammSwapsLens = IAmmSwapsLens(address(amm.router));
    //        amm.usdt.ammPoolsService = IAmmPoolsService(address(amm.router));
    //        amm.usdt.ammPoolsLens = IAmmPoolsLens(address(amm.router));
    //        amm.usdt.ammOpenSwapService = IAmmOpenSwapService(address(amm.router));
    //        amm.usdt.ammCloseSwapService = IAmmCloseSwapService(address(amm.router));
    //        amm.usdt.ammGovernanceService = IAmmGovernanceService(address(amm.router));
    //        amm.usdt.powerTokenLens = IPowerTokenLens(address(amm.router));
    //        amm.usdt.liquidityMiningLens = ILiquidityMiningLens(address(amm.router));
    //        amm.usdt.flowService = IPowerTokenFlowsService(address(amm.router));
    //        amm.usdt.stakeService = IPowerTokenStakeService(address(amm.router));
    //
    //        amm.usdc.ammSwapsLens = IAmmSwapsLens(address(amm.router));
    //        amm.usdc.ammPoolsService = IAmmPoolsService(address(amm.router));
    //        amm.usdc.ammPoolsLens = IAmmPoolsLens(address(amm.router));
    //        amm.usdc.ammOpenSwapService = IAmmOpenSwapService(address(amm.router));
    //        amm.usdc.ammCloseSwapService = IAmmCloseSwapService(address(amm.router));
    //        amm.usdc.ammGovernanceService = IAmmGovernanceService(address(amm.router));
    //        amm.usdc.powerTokenLens = IPowerTokenLens(address(amm.router));
    //        amm.usdc.liquidityMiningLens = ILiquidityMiningLens(address(amm.router));
    //        amm.usdc.flowService = IPowerTokenFlowsService(address(amm.router));
    //        amm.usdc.stakeService = IPowerTokenStakeService(address(amm.router));
    //
    //        amm.dai.ammSwapsLens = IAmmSwapsLens(address(amm.router));
    //        amm.dai.ammPoolsService = IAmmPoolsService(address(amm.router));
    //        amm.dai.ammPoolsLens = IAmmPoolsLens(address(amm.router));
    //        amm.dai.ammOpenSwapService = IAmmOpenSwapService(address(amm.router));
    //        amm.dai.ammCloseSwapService = IAmmCloseSwapService(address(amm.router));
    //        amm.dai.ammGovernanceService = IAmmGovernanceService(address(amm.router));
    //        amm.dai.powerTokenLens = IPowerTokenLens(address(amm.router));
    //        amm.dai.liquidityMiningLens = ILiquidityMiningLens(address(amm.router));
    //        amm.dai.flowService = IPowerTokenFlowsService(address(amm.router));
    //        amm.dai.stakeService = IPowerTokenStakeService(address(amm.router));
    //
    //        return IporProtocolRouter(amm.router);
    //    }

    function _preparePoolCfgForGovernanceService(
        address asset,
        address ammTreasury,
        address ammStorage
    ) internal returns (IAmmGovernanceService.PoolConfiguration memory poolCfg) {
        poolCfg = IAmmGovernanceService.PoolConfiguration({
            asset: asset,
            assetDecimals: IERC20MetadataUpgradeable(asset).decimals(),
            ammStorage: ammStorage,
            ammTreasury: ammTreasury
        });
    }

    function _preparePoolCfgForPoolsService(
        address asset,
        address ipToken,
        address ammTreasury,
        address ammStorage,
        address assetManagement
    ) internal returns (IAmmPoolsService.PoolConfiguration memory poolCfg) {
        poolCfg = IAmmPoolsService.PoolConfiguration({
            asset: asset,
            decimals: IERC20MetadataUpgradeable(asset).decimals(),
            ipToken: ipToken,
            ammStorage: ammStorage,
            ammTreasury: ammTreasury,
            assetManagement: assetManagement,
            redeemFeeRate: 5 * 1e15,
            redeemLpMaxUtilizationRate: 1e18
        });
    }

    function _preparePoolCfgForCloseSwapService(
        address asset,
        address ammTreasury,
        address ammStorage,
        address assetManagement
    ) internal returns (IAmmCloseSwapService.PoolConfiguration memory poolCfg) {
        poolCfg = IAmmCloseSwapService.PoolConfiguration({
            asset: address(asset),
            decimals: IERC20MetadataUpgradeable(asset).decimals(),
            ammStorage: ammStorage,
            ammTreasury: ammTreasury,
            assetManagement: assetManagement,
            openingFeeRate: 1e16,
            openingFeeRateForSwapUnwind: 5 * 1e18, //TODO: suspicious value
            liquidationLegLimit: 10,
            timeBeforeMaturityAllowedToCloseSwapByCommunity: 1 hours,
            timeBeforeMaturityAllowedToCloseSwapByBuyer: 1 days,
            minLiquidationThresholdToCloseBeforeMaturityByCommunity: 995 * 1e15,
            minLiquidationThresholdToCloseBeforeMaturityByBuyer: 99 * 1e16,
            minLeverage: 0
        });
    }

    function _preparePoolCfgForOpenSwapService(
        address asset,
        address ammTreasury,
        address ammStorage
    ) internal returns (IAmmOpenSwapService.PoolConfiguration memory poolCfg) {
        poolCfg = IAmmOpenSwapService.PoolConfiguration({
            asset: asset,
            decimals: IERC20MetadataUpgradeable(asset).decimals(),
            ammStorage: ammStorage,
            ammTreasury: ammTreasury,
            iporPublicationFee: 10 * 1e18,
            maxSwapCollateralAmount: 100_000 * 1e18,
            liquidationDepositAmount: 25,
            minLeverage: 10 * 1e18,
            openingFeeRate: 1e16,
            openingFeeTreasuryPortionRate: 0
        });
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

    function deployOracle(Amm memory amm) internal {
        address[] memory assets = new address[](3);
        assets[0] = address(amm.dai.asset);
        assets[1] = address(amm.usdt.asset);
        assets[2] = address(amm.usdc.asset);

        IporOracle iporOracleImplementation = new IporOracle(
            address(0),
            address(amm.usdt.asset),
            1e18,
            address(amm.usdc.asset),
            1e18,
            address(amm.dai.asset),
            1e18
        );

        uint32[] memory lastUpdateTimestamps = getCurrentTimestamps(assets);

        amm.iporOracle = IIporOracle(
            address(
                new ERC1967Proxy(
                    address(iporOracleImplementation),
                    abi.encodeWithSignature("initialize(address[],uint32[])", assets, lastUpdateTimestamps)
                )
            )
        );

        amm.usdt.iporOracle = amm.iporOracle;
        amm.usdc.iporOracle = amm.iporOracle;
        amm.dai.iporOracle = amm.iporOracle;

        amm.iporOracle.addUpdater(ammConfig.iporOracleUpdater);
    }

    function deployRiskOracle(Amm memory amm) internal {
        address[] memory assets = new address[](3);
        assets[0] = address(amm.dai.asset);
        assets[1] = address(amm.usdt.asset);
        assets[2] = address(amm.usdc.asset);

        IporRiskManagementOracleTypes.RiskIndicators[]
            memory riskIndicators = new IporRiskManagementOracleTypes.RiskIndicators[](assets.length);
        IporRiskManagementOracleTypes.BaseSpreadsAndFixedRateCaps[]
            memory baseSpreadsAndFixedRateCaps = new IporRiskManagementOracleTypes.BaseSpreadsAndFixedRateCaps[](
                assets.length
            );

        for (uint256 i = 0; i < assets.length; i++) {
            riskIndicators[i] = IporRiskManagementOracleTypes.RiskIndicators({
                maxNotionalPayFixed: TestConstants.RMO_NOTIONAL_1B,
                maxNotionalReceiveFixed: TestConstants.RMO_NOTIONAL_1B,
                maxUtilizationRatePayFixed: TestConstants.RMO_UTILIZATION_RATE_48_PER,
                maxUtilizationRateReceiveFixed: TestConstants.RMO_UTILIZATION_RATE_48_PER,
                maxUtilizationRate: TestConstants.RMO_UTILIZATION_RATE_90_PER
            });
            baseSpreadsAndFixedRateCaps[i] = IporRiskManagementOracleTypes.BaseSpreadsAndFixedRateCaps({
                spread28dPayFixed: TestConstants.RMO_SPREAD_0_1_PER,
                spread28dReceiveFixed: TestConstants.RMO_SPREAD_0_1_PER,
                spread60dPayFixed: TestConstants.RMO_SPREAD_0_1_PER,
                spread60dReceiveFixed: TestConstants.RMO_SPREAD_0_1_PER,
                spread90dPayFixed: TestConstants.RMO_SPREAD_0_1_PER,
                spread90dReceiveFixed: TestConstants.RMO_SPREAD_0_1_PER,
                fixedRateCap28dPayFixed: TestConstants.RMO_FIXED_RATE_CAP_2_0_PER,
                fixedRateCap28dReceiveFixed: TestConstants.RMO_FIXED_RATE_CAP_3_5_PER,
                fixedRateCap60dPayFixed: TestConstants.RMO_FIXED_RATE_CAP_2_0_PER,
                fixedRateCap60dReceiveFixed: TestConstants.RMO_FIXED_RATE_CAP_3_5_PER,
                fixedRateCap90dPayFixed: TestConstants.RMO_FIXED_RATE_CAP_2_0_PER,
                fixedRateCap90dReceiveFixed: TestConstants.RMO_FIXED_RATE_CAP_3_5_PER
            });
        }

        IporRiskManagementOracle riskOracleProxy = IporRiskManagementOracle(
            address(
                new ERC1967Proxy(
                    address(new IporRiskManagementOracle()),
                    abi.encodeWithSignature(
                        "initialize(address[],(uint256,uint256,uint256,uint256,uint256)[],(int256,int256,int256,int256,int256,int256,uint256,uint256,uint256,uint256,uint256,uint256)[])",
                        assets,
                        riskIndicators,
                        baseSpreadsAndFixedRateCaps
                    )
                )
            )
        );

        riskOracleProxy.addUpdater(ammConfig.iporOracleUpdater);

        amm.iporRiskManagementOracle = IporRiskManagementOracle(address(riskOracleProxy));
    }

    function deployEmptyRouter(Amm memory amm) internal {
        amm.router = IporProtocolRouter(
            address(
                new ERC1967Proxy(
                    address(new EmptyRouterImplementation()),
                    abi.encodeWithSignature("initialize(bool)", false)
                )
            )
        );
    }

    function deployIpTokens(Amm memory amm) internal {
        amm.usdt.ipToken = new IpToken("IP USDT", "ipUSDT", address(amm.usdt.asset));
        amm.usdc.ipToken = new IpToken("IP USDC", "ipUSDC", address(amm.usdc.asset));
        amm.dai.ipToken = new IpToken("IP DAI", "ipDAI", address(amm.dai.asset));
    }

    function deployIvTokens(Amm memory amm) internal {
        amm.usdt.ivToken = new IvToken("IV USDT", "ivUSDT", address(amm.usdt.asset));
        amm.usdc.ivToken = new IvToken("IV USDC", "ivUSDC", address(amm.usdc.asset));
        amm.dai.ivToken = new IvToken("IV DAI", "ivDAI", address(amm.dai.asset));
    }

    function deployAssets(Amm memory amm) internal {
        amm.usdt.asset = new MockTestnetToken("Mocked USDT", "USDT", TestConstants.TOTAL_SUPPLY_6_DECIMALS, 6);
        amm.usdc.asset = new MockTestnetToken("Mocked USDC", "USDC", TestConstants.TOTAL_SUPPLY_6_DECIMALS, 6);
        amm.dai.asset = new MockTestnetToken("Mocked DAI", "DAI", TestConstants.TOTAL_SUPPLY_18_DECIMALS, 18);
    }

    function deployEmptyTreasury(Amm memory amm) internal {
        amm.usdt.ammTreasury = AmmTreasury(
            address(
                new ERC1967Proxy(
                    address(new EmptyAmmTreasuryImplementation()),
                    abi.encodeWithSignature("initialize(bool)", false)
                )
            )
        );

        amm.usdc.ammTreasury = AmmTreasury(
            address(
                new ERC1967Proxy(
                    address(new EmptyAmmTreasuryImplementation()),
                    abi.encodeWithSignature("initialize(bool)", false)
                )
            )
        );

        amm.dai.ammTreasury = AmmTreasury(
            address(
                new ERC1967Proxy(
                    address(new EmptyAmmTreasuryImplementation()),
                    abi.encodeWithSignature("initialize(bool)", false)
                )
            )
        );
    }

    function deployStorage(Amm memory amm) internal {
        amm.usdt.ammStorage = AmmStorage(
            address(
                new ERC1967Proxy(
                    address(new AmmStorage(address(amm.router), address(amm.usdt.ammTreasury))),
                    abi.encodeWithSignature("initialize()", "")
                )
            )
        );

        amm.usdc.ammStorage = AmmStorage(
            address(
                new ERC1967Proxy(
                    address(new AmmStorage(address(amm.router), address(amm.usdc.ammTreasury))),
                    abi.encodeWithSignature("initialize()", "")
                )
            )
        );

        amm.dai.ammStorage = AmmStorage(
            address(
                new ERC1967Proxy(
                    address(new AmmStorage(address(amm.router), address(amm.dai.ammTreasury))),
                    abi.encodeWithSignature("initialize()", "")
                )
            )
        );
    }
}

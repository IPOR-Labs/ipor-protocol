pragma solidity 0.8.16;

import "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import "forge-std/Script.sol";
import "contracts/router/IporProtocolRouter.sol";
import "contracts/amm/AmmPoolsLens.sol";
import "contracts/amm/AmmOpenSwapService.sol";
import "contracts/amm/AmmGovernanceService.sol";
import "contracts/amm/AmmSwapsLens.sol";
import "contracts/amm/AssetManagementLens.sol";
import "contracts/amm/AmmCloseSwapService.sol";
import "contracts/amm/AmmPoolsService.sol";
import "contracts/interfaces/IIporOracle.sol";
import "contracts/oracles/IporOracle.sol";
import "contracts/amm/spread/SpreadRouter.sol";
import "contracts/oracles/IporRiskManagementOracle.sol";
import "./mocks/EmptyAmmTreasuryImplementation.sol";
import "./mocks/EmptyRouterImplementation.sol";
import "../test/utils/TestConstants.sol";
import "contracts/amm/spread/SpreadStorageLens.sol";
import "contracts/amm/spread/Spread28Days.sol";
import "contracts/amm/spread/Spread60Days.sol";
import "contracts/amm/spread/Spread90Days.sol";
import "contracts/mocks/stanley/MockTestnetStrategy.sol";
import "contracts/vault/AssetManagementUsdt.sol";
import "contracts/vault/AssetManagementUsdc.sol";
import "contracts/vault/AssetManagementDai.sol";
import "contracts/tokens/IpToken.sol";
import "contracts/tokens/IvToken.sol";
import "contracts/mocks/tokens/MockTestnetToken.sol";
import "contracts/amm/AmmStorage.sol";
import "contracts/amm/AmmTreasury.sol";

// run:
// $ anvil
// get private key from anvil then set SC_ADMIN_PRIV_KEY variable in .env file
// then run:
// $ forge script scripts/DeployLocal.s.sol --fork-url http://127.0.0.1:8545 --broadcast
contract DevDeployment is Script {
    struct IporProtocol {
        address asset;
        address ipToken;
        address ivToken;
        address ammStorage;
        address assetManagement;
        address strategyAave;
        address strategyCompound;
        address aToken;
        address cToken;
        address ammTreasury;
    }

    struct Amm {
        address router;
        address spreadRouter;
        address iporOracle;
        address ammSwapsLens;
        address ammPoolsLens;
        address assetManagementLens;
        address ammOpenSwapService;
        address ammCloseSwapService;
        address iporRiskManagementOracle;
        address ammPoolsService;
        address ammGovernanceService;
        IporProtocol usdt;
        IporProtocol usdc;
        IporProtocol dai;
    }

    struct AmmConfig {
        address iporOracleUpdater;
        address iporRiskManagementOracleUpdater;
        address powerTokenLens;
        address liquidityMiningLens;
        address flowService;
        address stakeService;
    }

    uint256 _private_key;
    AmmConfig ammConfig;

    function setUp() public {
        _private_key = vm.envUint("SC_ADMIN_PRIV_KEY");
        ammConfig.iporOracleUpdater = vm.envAddress("SC_MIGRATION_IPOR_INDEX_UPDATER_ADDRESS");
        ammConfig.iporRiskManagementOracleUpdater = vm.envAddress("SC_MIGRATION_IPOR_INDEX_UPDATER_ADDRESS");
        ammConfig.powerTokenLens = vm.envAddress("SC_POWER_TOKEN_LENS_ADDRESS");
        ammConfig.liquidityMiningLens = vm.envAddress("SC_LIQUIDITY_MINING_LENS_ADDRESS");
        ammConfig.flowService = vm.envAddress("SC_POWER_TOKEN_FLOW_SERVICE_ADDRESS");
        ammConfig.stakeService = vm.envAddress("SC_POWER_TOKEN_STAKE_SERVICE_ADDRESS");
    }

    function run() public {
        Amm memory amm;
        vm.startBroadcast(_private_key);
        _getFullInstance(ammConfig, amm);
        vm.stopBroadcast();
        _toAddressesJson(amm);
    }

    function _getFullInstance(AmmConfig memory cfg, Amm memory amm) internal {
        deployEmptyRouter(amm);
        deployEmptyTreasury(amm);
        deployAssets(amm);
        deployOracle(amm);
        deployRiskOracle(amm);
        deployIpTokens(amm);
        deployIvTokens(amm);
        deployStorage(amm);
        deploySpreadRouter(amm);
        deployAssetManagement(amm);
        deployFullTreasury(amm);
        deployFullRouter(amm);
    }

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

        amm.iporOracle = address(
            new ERC1967Proxy(
                address(iporOracleImplementation),
                abi.encodeWithSignature("initialize(address[],uint32[])", assets, lastUpdateTimestamps)
            )
        );

        IIporOracle(amm.iporOracle).addUpdater(ammConfig.iporOracleUpdater);
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

        riskOracleProxy.addUpdater(ammConfig.iporRiskManagementOracleUpdater);

        amm.iporRiskManagementOracle = address(riskOracleProxy);
    }

    function deployEmptyRouter(Amm memory amm) internal {
        amm.router = address(
            new ERC1967Proxy(
                address(new EmptyRouterImplementation()),
                abi.encodeWithSignature("initialize(bool)", false)
            )
        );
    }

    function deployIpTokens(Amm memory amm) internal {
        amm.usdt.ipToken = address(new IpToken("IP USDT", "ipUSDT", address(amm.usdt.asset)));
        amm.usdc.ipToken = address(new IpToken("IP USDC", "ipUSDC", address(amm.usdc.asset)));
        amm.dai.ipToken = address(new IpToken("IP DAI", "ipDAI", address(amm.dai.asset)));
    }

    function deployIvTokens(Amm memory amm) internal {
        amm.usdt.ivToken = address(new IvToken("IV USDT", "ivUSDT", amm.usdt.asset));
        amm.usdc.ivToken = address(new IvToken("IV USDC", "ivUSDC", amm.usdc.asset));
        amm.dai.ivToken = address(new IvToken("IV DAI", "ivDAI", amm.dai.asset));
    }

    function deployAssets(Amm memory amm) internal {
        amm.usdt.asset = address(new MockTestnetToken("Mocked USDT", "USDT", TestConstants.TOTAL_SUPPLY_6_DECIMALS, 6));
        amm.usdc.asset = address(new MockTestnetToken("Mocked USDC", "USDC", TestConstants.TOTAL_SUPPLY_6_DECIMALS, 6));
        amm.dai.asset = address(new MockTestnetToken("Mocked DAI", "DAI", TestConstants.TOTAL_SUPPLY_18_DECIMALS, 18));
    }

    function deployEmptyTreasury(Amm memory amm) internal {
        amm.usdt.ammTreasury = address(
            new ERC1967Proxy(
                address(new EmptyAmmTreasuryImplementation()),
                abi.encodeWithSignature("initialize(bool)", false)
            )
        );

        amm.usdc.ammTreasury = address(
            new ERC1967Proxy(
                address(new EmptyAmmTreasuryImplementation()),
                abi.encodeWithSignature("initialize(bool)", false)
            )
        );

        amm.dai.ammTreasury = address(
            new ERC1967Proxy(
                address(new EmptyAmmTreasuryImplementation()),
                abi.encodeWithSignature("initialize(bool)", false)
            )
        );
    }

    function deployStorage(Amm memory amm) internal {
        amm.usdt.ammStorage = address(
            new ERC1967Proxy(
                address(new AmmStorage(address(amm.router), address(amm.usdt.ammTreasury))),
                abi.encodeWithSignature("initialize()", "")
            )
        );

        amm.usdc.ammStorage = address(
            new ERC1967Proxy(
                address(new AmmStorage(address(amm.router), address(amm.usdc.ammTreasury))),
                abi.encodeWithSignature("initialize()", "")
            )
        );

        amm.dai.ammStorage = address(
            new ERC1967Proxy(
                address(new AmmStorage(address(amm.router), address(amm.dai.ammTreasury))),
                abi.encodeWithSignature("initialize()", "")
            )
        );
    }

    function deploySpreadRouter(Amm memory amm) internal {
        SpreadRouter.DeployedContracts memory deployedContracts;
        deployedContracts.ammAddress = address(amm.router);
        deployedContracts.storageLens = address(new SpreadStorageLens());
        deployedContracts.spread28Days = address(
            new Spread28Days(address(amm.dai.asset), address(amm.usdc.asset), address(amm.usdt.asset))
        );
        deployedContracts.spread60Days = address(
            new Spread60Days(address(amm.dai.asset), address(amm.usdc.asset), address(amm.usdt.asset))
        );
        deployedContracts.spread90Days = address(
            new Spread90Days(address(amm.dai.asset), address(amm.usdc.asset), address(amm.usdt.asset))
        );

        amm.spreadRouter = address(
            new ERC1967Proxy(
                address(new SpreadRouter(deployedContracts)),
                abi.encodeWithSignature("initialize(bool)", false)
            )
        );
    }

    function deployAssetManagement(Amm memory amm) internal {
        amm.usdt.aToken = address(new MockTestnetToken("Mocked Share aUSDT", "aUSDT", 0, 6));
        amm.usdc.aToken = address(new MockTestnetToken("Mocked Share aUSDC", "aUSDC", 0, 6));
        amm.dai.aToken = address(new MockTestnetToken("Mocked Share aDAI", "aDAI", 0, 18));

        amm.usdt.cToken = address(new MockTestnetToken("Mocked Share cUSDT", "cUSDT", 0, 6));
        amm.usdc.cToken = address(new MockTestnetToken("Mocked Share cUSDC", "cUSDC", 0, 6));
        amm.dai.cToken = address(new MockTestnetToken("Mocked Share cDAI", "cDAI", 0, 18));

        amm.usdt.strategyAave = address(
            new ERC1967Proxy(
                address(new MockTestnetStrategy()),
                abi.encodeWithSignature("initialize(address,address)", amm.usdt.asset, amm.usdt.aToken)
            )
        );

        amm.usdt.strategyCompound = address(
            new ERC1967Proxy(
                address(new MockTestnetStrategy()),
                abi.encodeWithSignature("initialize(address,address)", amm.usdt.asset, amm.usdt.cToken)
            )
        );

        amm.usdc.strategyAave = address(
            new ERC1967Proxy(
                address(new MockTestnetStrategy()),
                abi.encodeWithSignature("initialize(address,address)", amm.usdc.asset, amm.usdc.aToken)
            )
        );

        amm.usdc.strategyCompound = address(
            new ERC1967Proxy(
                address(new MockTestnetStrategy()),
                abi.encodeWithSignature("initialize(address,address)", amm.usdc.asset, amm.usdc.cToken)
            )
        );

        amm.dai.strategyAave = address(
            new ERC1967Proxy(
                address(new MockTestnetStrategy()),
                abi.encodeWithSignature("initialize(address,address)", amm.dai.asset, amm.dai.aToken)
            )
        );

        amm.dai.strategyCompound = address(
            new ERC1967Proxy(
                address(new MockTestnetStrategy()),
                abi.encodeWithSignature("initialize(address,address)", amm.dai.asset, amm.dai.cToken)
            )
        );

        amm.usdt.assetManagement = address(
            new ERC1967Proxy(
                address(new AssetManagementUsdt()),
                abi.encodeWithSignature(
                    "initialize(address,address,address,address)",
                    amm.usdt.asset,
                    amm.usdt.ivToken,
                    amm.usdt.strategyAave,
                    amm.usdt.strategyCompound
                )
            )
        );

        amm.usdc.assetManagement = address(
            new ERC1967Proxy(
                address(new AssetManagementUsdc()),
                abi.encodeWithSignature(
                    "initialize(address,address,address,address)",
                    amm.usdc.asset,
                    amm.usdc.ivToken,
                    amm.usdc.strategyAave,
                    amm.usdc.strategyCompound
                )
            )
        );

        amm.dai.assetManagement = address(
            new ERC1967Proxy(
                address(new AssetManagementDai()),
                abi.encodeWithSignature(
                    "initialize(address,address,address,address)",
                    amm.dai.asset,
                    amm.dai.ivToken,
                    amm.dai.strategyAave,
                    amm.dai.strategyCompound
                )
            )
        );

        IStrategy(amm.usdt.strategyAave).setAssetManagement(amm.usdt.assetManagement);
        IStrategy(amm.usdc.strategyAave).setAssetManagement(amm.usdc.assetManagement);
        IStrategy(amm.dai.strategyAave).setAssetManagement(amm.dai.assetManagement);

        IStrategy(amm.usdt.strategyCompound).setAssetManagement(amm.usdt.assetManagement);
        IStrategy(amm.usdc.strategyCompound).setAssetManagement(amm.usdc.assetManagement);
        IStrategy(amm.dai.strategyCompound).setAssetManagement(amm.dai.assetManagement);
    }

    function deployFullTreasury(Amm memory amm) internal {
        AmmTreasury(amm.usdt.ammTreasury).upgradeTo(
            address(new AmmTreasury(amm.usdt.asset, 6, amm.usdt.ammStorage, amm.usdt.assetManagement, amm.router))
        );

        AmmTreasury(amm.usdc.ammTreasury).upgradeTo(
            address(new AmmTreasury(amm.usdc.asset, 6, amm.usdc.ammStorage, amm.usdc.assetManagement, amm.router))
        );

        AmmTreasury(amm.dai.ammTreasury).upgradeTo(
            address(new AmmTreasury(amm.dai.asset, 18, amm.dai.ammStorage, amm.dai.assetManagement, amm.router))
        );
    }

    function deployFullRouter(Amm memory amm) internal {
        amm.ammSwapsLens = address(
            new AmmSwapsLens(
                IAmmSwapsLens.SwapLensConfiguration({
                    asset: address(amm.usdt.asset),
                    ammStorage: address(amm.usdt.ammStorage),
                    ammTreasury: address(amm.usdt.ammTreasury)
                }),
                IAmmSwapsLens.SwapLensConfiguration({
                    asset: address(amm.usdc.asset),
                    ammStorage: address(amm.usdc.ammStorage),
                    ammTreasury: address(amm.usdc.ammTreasury)
                }),
                IAmmSwapsLens.SwapLensConfiguration({
                    asset: address(amm.dai.asset),
                    ammStorage: address(amm.dai.ammStorage),
                    ammTreasury: address(amm.dai.ammTreasury)
                }),
                IIporOracle(amm.iporOracle),
                amm.iporRiskManagementOracle,
                amm.router
            )
        );

        amm.ammPoolsLens = address(
            new AmmPoolsLens(
                IAmmPoolsLens.PoolConfiguration({
                    asset: address(amm.usdt.asset),
                    decimals: 6,
                    ipToken: address(amm.usdt.ipToken),
                    ammStorage: address(amm.usdt.ammStorage),
                    ammTreasury: address(amm.usdt.ammTreasury),
                    assetManagement: address(amm.usdt.assetManagement)
                }),
                IAmmPoolsLens.PoolConfiguration({
                    asset: address(amm.usdc.asset),
                    decimals: 6,
                    ipToken: address(amm.usdc.ipToken),
                    ammStorage: address(amm.usdc.ammStorage),
                    ammTreasury: address(amm.usdc.ammTreasury),
                    assetManagement: address(amm.usdc.assetManagement)
                }),
                IAmmPoolsLens.PoolConfiguration({
                    asset: address(amm.dai.asset),
                    decimals: 18,
                    ipToken: address(amm.dai.ipToken),
                    ammStorage: address(amm.dai.ammStorage),
                    ammTreasury: address(amm.dai.ammTreasury),
                    assetManagement: address(amm.dai.assetManagement)
                }),
                address(amm.iporOracle)
            )
        );

        amm.assetManagementLens = address(
            new AssetManagementLens(
                IAssetManagementLens.AssetManagementConfiguration({
                    asset: amm.usdt.asset,
                    decimals: 6,
                    assetManagement: amm.usdt.assetManagement,
                    ammTreasury: amm.usdt.ammTreasury
                }),
                IAssetManagementLens.AssetManagementConfiguration({
                    asset: amm.usdc.asset,
                    decimals: 6,
                    assetManagement: amm.usdc.assetManagement,
                    ammTreasury: amm.usdc.ammTreasury
                }),
                IAssetManagementLens.AssetManagementConfiguration({
                    asset: amm.dai.asset,
                    decimals: 18,
                    assetManagement: amm.dai.assetManagement,
                    ammTreasury: amm.dai.ammTreasury
                })
            )
        );

        amm.ammOpenSwapService = address(
            new AmmOpenSwapService({
                usdtPoolCfg: _preparePoolCfgForOpenSwapService(
                    address(amm.usdt.asset),
                    address(amm.usdt.ammTreasury),
                    address(amm.usdt.ammStorage)
                ),
                usdcPoolCfg: _preparePoolCfgForOpenSwapService(
                    address(amm.usdc.asset),
                    address(amm.usdc.ammTreasury),
                    address(amm.usdc.ammStorage)
                ),
                daiPoolCfg: _preparePoolCfgForOpenSwapService(
                    address(amm.dai.asset),
                    address(amm.dai.ammTreasury),
                    address(amm.dai.ammStorage)
                ),
                iporOracle: amm.iporOracle,
                iporRiskManagementOracle: amm.iporRiskManagementOracle,
                spreadRouter: amm.spreadRouter
            })
        );

        amm.ammCloseSwapService = address(
            new AmmCloseSwapService({
                usdtPoolCfg: _preparePoolCfgForCloseSwapService(
                    address(amm.usdt.asset),
                    address(amm.usdt.ammTreasury),
                    address(amm.usdt.ammStorage),
                    address(amm.usdt.assetManagement)
                ),
                usdcPoolCfg: _preparePoolCfgForCloseSwapService(
                    address(amm.usdc.asset),
                    address(amm.usdc.ammTreasury),
                    address(amm.usdc.ammStorage),
                    address(amm.usdc.assetManagement)
                ),
                daiPoolCfg: _preparePoolCfgForCloseSwapService(
                    address(amm.dai.asset),
                    address(amm.dai.ammTreasury),
                    address(amm.dai.ammStorage),
                    address(amm.dai.assetManagement)
                ),
                iporOracle: address(amm.iporOracle),
                iporRiskManagementOracle: address(amm.iporRiskManagementOracle),
                spreadRouter: address(amm.spreadRouter)
            })
        );

        amm.ammPoolsService = address(
            new AmmPoolsService({
                usdtPoolCfg: _preparePoolCfgForPoolsService(
                    address(amm.usdt.asset),
                    address(amm.usdt.ipToken),
                    address(amm.usdt.ammTreasury),
                    address(amm.usdt.ammStorage),
                    address(amm.usdt.assetManagement)
                ),
                usdcPoolCfg: _preparePoolCfgForPoolsService(
                    address(amm.usdc.asset),
                    address(amm.usdc.ipToken),
                    address(amm.usdc.ammTreasury),
                    address(amm.usdc.ammStorage),
                    address(amm.usdc.assetManagement)
                ),
                daiPoolCfg: _preparePoolCfgForPoolsService(
                    address(amm.dai.asset),
                    address(amm.dai.ipToken),
                    address(amm.dai.ammTreasury),
                    address(amm.dai.ammStorage),
                    address(amm.dai.assetManagement)
                ),
                iporOracle: address(amm.iporOracle)
            })
        );

        amm.ammGovernanceService = address(
            new AmmGovernanceService({
                usdtPoolCfg: _preparePoolCfgForGovernanceService(
                    address(amm.usdt.asset),
                    address(amm.usdt.ammTreasury),
                    address(amm.usdt.ammStorage)
                ),
                usdcPoolCfg: _preparePoolCfgForGovernanceService(
                    address(amm.usdc.asset),
                    address(amm.usdc.ammTreasury),
                    address(amm.usdc.ammStorage)
                ),
                daiPoolCfg: _preparePoolCfgForGovernanceService(
                    address(amm.dai.asset),
                    address(amm.dai.ammTreasury),
                    address(amm.dai.ammStorage)
                )
            })
        );

        IporProtocolRouter.DeployedContracts memory deployedContracts = IporProtocolRouter.DeployedContracts({
            ammSwapsLens: amm.ammSwapsLens,
            ammPoolsLens: amm.ammPoolsLens,
            assetManagementLens: amm.assetManagementLens,
            ammOpenSwapService: amm.ammOpenSwapService,
            ammCloseSwapService: amm.ammCloseSwapService,
            ammPoolsService: amm.ammPoolsService,
            ammGovernanceService: amm.ammGovernanceService,
            liquidityMiningLens: ammConfig.liquidityMiningLens,
            powerTokenLens: ammConfig.powerTokenLens,
            flowService: ammConfig.flowService,
            stakeService: ammConfig.stakeService
        });

        IporProtocolRouter(amm.router).upgradeTo(address(new IporProtocolRouter(deployedContracts)));
    }

    function _toAddressesJson(Amm memory amm) internal {
        string memory path = vm.projectRoot();
        string memory addressesJson = "";

        vm.serializeAddress(addressesJson, "USDT", amm.usdt.asset);
        vm.serializeAddress(addressesJson, "USDC", amm.usdc.asset);
        vm.serializeAddress(addressesJson, "DAI", amm.dai.asset);

        vm.serializeAddress(addressesJson, "ipUSDT", amm.usdt.ipToken);
        vm.serializeAddress(addressesJson, "ipUSDC", amm.usdc.ipToken);
        vm.serializeAddress(addressesJson, "ipDAI", amm.dai.ipToken);

        vm.serializeAddress(addressesJson, "ivUSDT", amm.usdt.ivToken);
        vm.serializeAddress(addressesJson, "ivUSDC", amm.usdc.ivToken);
        vm.serializeAddress(addressesJson, "ivDAI", amm.dai.ivToken);

        vm.serializeAddress(addressesJson, "aUSDT", amm.usdt.aToken);
        vm.serializeAddress(addressesJson, "aUSDC", amm.usdc.aToken);
        vm.serializeAddress(addressesJson, "aDAI", amm.dai.aToken);

        vm.serializeAddress(addressesJson, "cUSDT", amm.usdt.cToken);
        vm.serializeAddress(addressesJson, "cUSDC", amm.usdc.cToken);
        vm.serializeAddress(addressesJson, "cDAI", amm.dai.cToken);

        vm.serializeAddress(addressesJson, "StrategyCompoundUsdt", amm.usdt.strategyCompound);
        vm.serializeAddress(addressesJson, "StrategyCompoundUsdc", amm.usdc.strategyCompound);
        vm.serializeAddress(addressesJson, "StrategyCompoundDai", amm.dai.strategyCompound);

        vm.serializeAddress(addressesJson, "StrategyAaveUsdt", amm.usdt.strategyAave);
        vm.serializeAddress(addressesJson, "StrategyAaveUsdc", amm.usdc.strategyAave);
        vm.serializeAddress(addressesJson, "StrategyAaveDai", amm.dai.strategyAave);

        vm.serializeAddress(addressesJson, "AmmStorageUsdt", amm.usdt.ammStorage);
        vm.serializeAddress(addressesJson, "AmmStorageUsdc", amm.usdc.ammStorage);
        vm.serializeAddress(addressesJson, "AmmStorageDai", amm.dai.ammStorage);

        vm.serializeAddress(addressesJson, "AssetManagementUsdt", amm.usdt.assetManagement);
        vm.serializeAddress(addressesJson, "AssetManagementUsdc", amm.usdc.assetManagement);
        vm.serializeAddress(addressesJson, "AssetManagementDai", amm.dai.assetManagement);

        vm.serializeAddress(addressesJson, "AmmTreasuryUsdt", amm.usdt.ammTreasury);
        vm.serializeAddress(addressesJson, "AmmTreasuryUsdc", amm.usdc.ammTreasury);
        vm.serializeAddress(addressesJson, "AmmTreasuryDai", amm.dai.ammTreasury);

        vm.serializeAddress(addressesJson, "SpreadRouter", amm.spreadRouter);
        vm.serializeAddress(addressesJson, "IporOracle", amm.iporOracle);
        vm.serializeAddress(addressesJson, "IporRiskManagementOracle", amm.iporRiskManagementOracle);

        string memory finalJson = vm.serializeAddress(addressesJson, "IporProtocolRouter", amm.router);

        vm.writeJson(finalJson, string.concat(path, "/addresses.json"));
    }
}

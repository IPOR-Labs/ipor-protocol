pragma solidity 0.8.20;

import "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import "forge-std/Script.sol";
import "@ipor-protocol/contracts/router/IporProtocolRouter.sol";
import "@ipor-protocol/contracts/amm/AmmPoolsLens.sol";
import "@ipor-protocol/contracts/amm/AmmOpenSwapService.sol";
import "@ipor-protocol/contracts/amm/AmmGovernanceService.sol";
import "@ipor-protocol/contracts/amm/AmmSwapsLens.sol";
import "@ipor-protocol/contracts/amm/AssetManagementLens.sol";
import "@ipor-protocol/contracts/amm/AmmCloseSwapService.sol";
import "@ipor-protocol/contracts/amm/AmmPoolsService.sol";
import "@ipor-protocol/contracts/interfaces/IIporOracle.sol";
import "@ipor-protocol/contracts/oracles/IporOracle.sol";
import "@ipor-protocol/contracts/amm/spread/SpreadRouter.sol";
import "@ipor-protocol/contracts/oracles/IporRiskManagementOracle.sol";
import "@ipor-protocol/test/utils/TestConstants.sol";
import "@ipor-protocol/contracts/amm/spread/SpreadStorageLens.sol";
import "@ipor-protocol/contracts/amm/spread/Spread28Days.sol";
import "@ipor-protocol/contracts/amm/spread/Spread60Days.sol";
import "@ipor-protocol/contracts/amm/spread/Spread90Days.sol";
import "@ipor-protocol/contracts/mocks/stanley/MockTestnetStrategy.sol";
import "@ipor-protocol/contracts/vault/AssetManagementUsdt.sol";
import "@ipor-protocol/contracts/vault/AssetManagementUsdc.sol";
import "@ipor-protocol/contracts/vault/AssetManagementDai.sol";
import "@ipor-protocol/contracts/tokens/IpToken.sol";
import "@ipor-protocol/contracts/tokens/IvToken.sol";
import "@ipor-protocol/contracts/mocks/tokens/MockTestnetToken.sol";
import "@ipor-protocol/contracts/amm/AmmStorage.sol";
import "@ipor-protocol/contracts/amm/AmmTreasury.sol";
import "@ipor-protocol/contracts/amm/spread/SpreadCloseSwapService.sol";
import "@ipor-protocol/contracts/mocks/TestnetFaucet.sol";
import "@ipor-protocol/contracts/tokens/IporToken.sol";

// run:
// $ anvil
// get private key from anvil then set SC_ADMIN_PRIV_KEY variable in .env file
// then run:
// $ forge script scripts/DeployLocal.s.sol --fork-url http://127.0.0.1:8545 --broadcast
contract LocalDeployment is Script {
    struct IporProtocol {
        address asset;
        address ipToken;
        address ivToken;
        address ammStorageProxy;
        address ammStorageImpl;
        address assetManagementProxy;
        address assetManagementImpl;
        address strategyAaveProxy;
        address strategyAaveImpl;
        address strategyCompoundProxy;
        address strategyCompoundImpl;
        address aToken;
        address cToken;
        address ammTreasuryProxy;
        address ammTreasuryImpl;
    }

    struct System {
        address iporToken;
        address routerProxy;
        address routerImpl;
        address spreadRouterProxy;
        address spreadRouterImpl;
        address iporOracleProxy;
        address iporOracleImpl;
        address ammSwapsLens;
        address ammPoolsLens;
        address assetManagementLens;
        address ammOpenSwapService;
        address ammCloseSwapService;
        address riskOracleProxy;
        address riskOracleImpl;
        address ammPoolsService;
        address ammGovernanceService;
        address faucetProxy;
        address faucetImpl;
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

    address defaultAnvilAddress = 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266;
    uint256 _private_key;
    string _env_profile;
    AmmConfig ammConfig;

    function setUp() public {
        _private_key = vm.envUint("SC_ADMIN_PRIV_KEY");
        _env_profile = vm.envString("ENV_PROFILE");
        ammConfig.iporOracleUpdater = vm.envAddress("SC_MIGRATION_IPOR_INDEX_UPDATER_ADDRESS");
        ammConfig.iporRiskManagementOracleUpdater = vm.envAddress("SC_MIGRATION_IPOR_INDEX_UPDATER_ADDRESS");
        ammConfig.powerTokenLens = vm.envAddress("SC_POWER_TOKEN_LENS_ADDRESS");
        ammConfig.liquidityMiningLens = vm.envAddress("SC_LIQUIDITY_MINING_LENS_ADDRESS");
        ammConfig.flowService = vm.envAddress("SC_POWER_TOKEN_FLOW_SERVICE_ADDRESS");
        ammConfig.stakeService = vm.envAddress("SC_POWER_TOKEN_STAKE_SERVICE_ADDRESS");
    }

    function run() public {
        System memory amm;
        vm.startBroadcast(_private_key);
        _getFullInstance(ammConfig, amm);
        vm.stopBroadcast();
        _toAddressesJson(amm);
    }

    function _getFullInstance(AmmConfig memory cfg, System memory system) public {
        deployDummyIporProtocolRouter(system);
        deployDummyAmmTreasury(system);
        deployIporToken(system);
        deployAssets(system);
        deployOracle(system);
        deployRiskOracle(system);
        deployIpTokens(system);
        deployIvTokens(system);
        deployStorage(system);
        deploySpreadRouter(system);
        deployAssetManagement(system);
        upgradeAmmTreasury(system);
        upgradeIporProtocolRouter(system);
    }

    function _preparePoolCfgForGovernanceService(
        address asset,
        address ammTreasury,
        address ammStorage
    ) internal view returns (IAmmGovernanceLens.PoolConfiguration memory poolCfg) {
        poolCfg = IAmmGovernanceLens.PoolConfiguration({
            asset: asset,
            assetDecimals: IERC20MetadataUpgradeable(asset).decimals(),
            ammStorage: ammStorage,
            ammTreasury: ammTreasury,
            ammPoolsTreasury: asset, //TODO: fixit
            ammPoolsTreasuryManager: asset, //TODO: fixit
            ammCharlieTreasury: asset, //TODO: fixit
            ammCharlieTreasuryManager: asset //TODO: fixit
        });
    }

    function _preparePoolCfgForPoolsService(
        address asset,
        address ipToken,
        address ammTreasury,
        address ammStorage,
        address assetManagement
    ) internal view returns (IAmmPoolsService.AmmPoolsServicePoolConfiguration memory poolCfg) {
        poolCfg = IAmmPoolsService.AmmPoolsServicePoolConfiguration({
            asset: asset,
            decimals: IERC20MetadataUpgradeable(asset).decimals(),
            ipToken: ipToken,
            ammStorage: ammStorage,
            ammTreasury: ammTreasury,
            assetManagement: assetManagement,
            redeemFeeRate: 5 * 1e15,
            redeemLpMaxCollateralRatio: 1e18
        });
    }

    function _preparePoolCfgForCloseSwapService(
        address asset,
        address ammTreasury,
        address ammStorage,
        address assetManagement
    ) internal view returns (IAmmCloseSwapService.AmmCloseSwapServicePoolConfiguration memory poolCfg) {
        poolCfg = IAmmCloseSwapService.AmmCloseSwapServicePoolConfiguration({
            asset: address(asset),
            decimals: IERC20MetadataUpgradeable(asset).decimals(),
            ammStorage: ammStorage,
            ammTreasury: ammTreasury,
            assetManagement: assetManagement,
            openingFeeRate: 5e14,
            openingFeeRateForSwapUnwind: 5e14,
            liquidationLegLimit: 10,
            timeBeforeMaturityAllowedToCloseSwapByCommunity: 1 hours,
            timeBeforeMaturityAllowedToCloseSwapByBuyer: 1 days,
            minLiquidationThresholdToCloseBeforeMaturityByCommunity: 995 * 1e15,
            minLiquidationThresholdToCloseBeforeMaturityByBuyer: 99 * 1e16,
            minLeverage: 10 * 1e18
        });
    }

    function _preparePoolCfgForOpenSwapService(
        address asset,
        address ammTreasury,
        address ammStorage
    ) internal view returns (IAmmOpenSwapService.AmmOpenSwapServicePoolConfiguration memory poolCfg) {
        poolCfg = IAmmOpenSwapService.AmmOpenSwapServicePoolConfiguration({
            asset: asset,
            decimals: IERC20MetadataUpgradeable(asset).decimals(),
            ammStorage: ammStorage,
            ammTreasury: ammTreasury,
            iporPublicationFee: 10 * 1e18,
            maxSwapCollateralAmount: 100_000 * 1e18,
            liquidationDepositAmount: 25,
            minLeverage: 10 * 1e18,
            openingFeeRate: 5e14,
            openingFeeTreasuryPortionRate: 5e17
        });
    }

    function _getCurrentTimestamps(
        address[] memory assets
    ) internal view returns (uint32[] memory lastUpdateTimestamps) {
        lastUpdateTimestamps = new uint32[](assets.length);

        uint32 lastUpdateTimestamp = uint32(block.timestamp);

        for (uint256 i = 0; i < assets.length; i++) {
            lastUpdateTimestamps[i] = lastUpdateTimestamp;
        }
    }

    function deployOracle(System memory system) public {
        address[] memory assets = new address[](3);
        assets[0] = address(system.dai.asset);
        assets[1] = address(system.usdt.asset);
        assets[2] = address(system.usdc.asset);

        system.iporOracleImpl = address(
            new IporOracle(
                address(system.usdt.asset),
                1e18,
                address(system.usdc.asset),
                1e18,
                address(system.dai.asset),
                1e18
            )
        );

        uint32[] memory lastUpdateTimestamps = _getCurrentTimestamps(assets);

        system.iporOracleProxy = address(
            new ERC1967Proxy(
                system.iporOracleImpl,
                abi.encodeWithSignature("initialize(address[],uint32[])", assets, lastUpdateTimestamps)
            )
        );

        IIporOracle(system.iporOracleProxy).addUpdater(ammConfig.iporOracleUpdater);
    }

    function deployRiskOracle(System memory system) public {
        address[] memory assets = new address[](3);
        assets[0] = address(system.dai.asset);
        assets[1] = address(system.usdt.asset);
        assets[2] = address(system.usdc.asset);

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
                maxCollateralRatioPayFixed: TestConstants.RMO_COLLATERAL_RATIO_48_PER,
                maxCollateralRatioReceiveFixed: TestConstants.RMO_COLLATERAL_RATIO_48_PER,
                maxCollateralRatio: TestConstants.RMO_COLLATERAL_RATIO_90_PER
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

        system.riskOracleImpl = address(new IporRiskManagementOracle());

        system.riskOracleProxy = address(
            address(
                new ERC1967Proxy(
                    system.riskOracleImpl,
                    abi.encodeWithSignature(
                        "initialize(address[],(uint256,uint256,uint256,uint256,uint256)[],(int256,int256,int256,int256,int256,int256,uint256,uint256,uint256,uint256,uint256,uint256)[])",
                        assets,
                        riskIndicators,
                        baseSpreadsAndFixedRateCaps
                    )
                )
            )
        );

        IporRiskManagementOracle(system.riskOracleProxy).addUpdater(ammConfig.iporRiskManagementOracleUpdater);
    }

    function deployDummyIporProtocolRouter(System memory system) public {
        IporProtocolRouter.DeployedContracts memory deployedContracts = IporProtocolRouter.DeployedContracts({
            ammSwapsLens: defaultAnvilAddress,
            ammPoolsLens: defaultAnvilAddress,
            assetManagementLens: defaultAnvilAddress,
            ammOpenSwapService: defaultAnvilAddress,
            ammCloseSwapService: defaultAnvilAddress,
            ammPoolsService: defaultAnvilAddress,
            ammGovernanceService: defaultAnvilAddress,
            liquidityMiningLens: defaultAnvilAddress,
            powerTokenLens: defaultAnvilAddress,
            flowService: defaultAnvilAddress,
            stakeService: defaultAnvilAddress
        });

        system.routerImpl = address(new IporProtocolRouter(deployedContracts));

        system.routerProxy = address(
            new ERC1967Proxy(system.routerImpl, abi.encodeWithSignature("initialize(bool)", false))
        );
    }

    function deployIpTokens(System memory system) public {
        system.usdt.ipToken = address(new IpToken("IP USDT", "ipUSDT", address(system.usdt.asset)));
        system.usdc.ipToken = address(new IpToken("IP USDC", "ipUSDC", address(system.usdc.asset)));
        system.dai.ipToken = address(new IpToken("IP DAI", "ipDAI", address(system.dai.asset)));

        IpToken(system.usdt.ipToken).setRouter(system.routerProxy);
        IpToken(system.usdc.ipToken).setRouter(system.routerProxy);
        IpToken(system.dai.ipToken).setRouter(system.routerProxy);
    }

    function deployIvTokens(System memory system) public {
        system.usdt.ivToken = address(new IvToken("IV USDT", "ivUSDT", system.usdt.asset));
        system.usdc.ivToken = address(new IvToken("IV USDC", "ivUSDC", system.usdc.asset));
        system.dai.ivToken = address(new IvToken("IV DAI", "ivDAI", system.dai.asset));
    }

    function deployAssets(System memory system) public {
        system.usdt.asset = address(
            new MockTestnetToken("Mocked USDT", "USDT", TestConstants.TOTAL_SUPPLY_6_DECIMALS, 6)
        );
        system.usdc.asset = address(
            new MockTestnetToken("Mocked USDC", "USDC", TestConstants.TOTAL_SUPPLY_6_DECIMALS, 6)
        );
        system.dai.asset = address(
            new MockTestnetToken("Mocked DAI", "DAI", TestConstants.TOTAL_SUPPLY_18_DECIMALS, 18)
        );
    }

    function deployDummyAmmTreasury(System memory system) public {
        AmmTreasury emptyImpl = new AmmTreasury(
            defaultAnvilAddress,
            0,
            defaultAnvilAddress,
            defaultAnvilAddress,
            defaultAnvilAddress
        );

        system.usdt.ammTreasuryProxy = address(
            new ERC1967Proxy(address(emptyImpl), abi.encodeWithSignature("initialize(bool)", false))
        );

        system.usdc.ammTreasuryProxy = address(
            new ERC1967Proxy(address(emptyImpl), abi.encodeWithSignature("initialize(bool)", false))
        );

        system.dai.ammTreasuryProxy = address(
            new ERC1967Proxy(address(emptyImpl), abi.encodeWithSignature("initialize(bool)", false))
        );
    }

    function deployStorage(System memory system) public {
        system.usdt.ammStorageImpl = address(
            new AmmStorage(address(system.routerProxy), address(system.usdt.ammTreasuryProxy))
        );
        system.usdt.ammStorageProxy = address(
            new ERC1967Proxy(system.usdt.ammStorageImpl, abi.encodeWithSignature("initialize()", ""))
        );

        system.usdc.ammStorageImpl = address(
            new AmmStorage(address(system.routerProxy), address(system.usdc.ammTreasuryProxy))
        );
        system.usdc.ammStorageProxy = address(
            new ERC1967Proxy(system.usdc.ammStorageImpl, abi.encodeWithSignature("initialize()", ""))
        );

        system.dai.ammStorageImpl = address(
            new AmmStorage(address(system.routerProxy), address(system.dai.ammTreasuryProxy))
        );
        system.dai.ammStorageProxy = address(
            new ERC1967Proxy(system.dai.ammStorageImpl, abi.encodeWithSignature("initialize()", ""))
        );
    }

    function deploySpreadRouter(System memory system) public {
        SpreadRouter.DeployedContracts memory deployedContracts;
        deployedContracts.iporProtocolRouter = address(system.routerProxy);
        deployedContracts.storageLens = address(new SpreadStorageLens());
        deployedContracts.spread28Days = address(
            new Spread28Days(address(system.dai.asset), address(system.usdc.asset), address(system.usdt.asset))
        );
        deployedContracts.spread60Days = address(
            new Spread60Days(address(system.dai.asset), address(system.usdc.asset), address(system.usdt.asset))
        );
        deployedContracts.spread90Days = address(
            new Spread90Days(address(system.dai.asset), address(system.usdc.asset), address(system.usdt.asset))
        );

        deployedContracts.closeSwapService = address(
            new SpreadCloseSwapService(
                address(system.dai.asset),
                address(system.usdc.asset),
                address(system.usdt.asset)
            )
        );

        system.spreadRouterImpl = address(new SpreadRouter(deployedContracts));
        system.spreadRouterProxy = address(
            new ERC1967Proxy(system.spreadRouterImpl, abi.encodeWithSignature("initialize(bool)", false))
        );
    }

    function deployAssetManagement(System memory system) internal {
        system.usdt.aToken = address(new MockTestnetToken("Mocked Share aUSDT", "aUSDT", 0, 6));
        system.usdc.aToken = address(new MockTestnetToken("Mocked Share aUSDC", "aUSDC", 0, 6));
        system.dai.aToken = address(new MockTestnetToken("Mocked Share aDAI", "aDAI", 0, 18));

        system.usdt.cToken = address(new MockTestnetToken("Mocked Share cUSDT", "cUSDT", 0, 6));
        system.usdc.cToken = address(new MockTestnetToken("Mocked Share cUSDC", "cUSDC", 0, 6));
        system.dai.cToken = address(new MockTestnetToken("Mocked Share cDAI", "cDAI", 0, 18));

        system.usdt.strategyAaveImpl = address(new MockTestnetStrategy());
        system.usdt.strategyAaveProxy = address(
            new ERC1967Proxy(
                system.usdt.strategyAaveImpl,
                abi.encodeWithSignature("initialize(address,address)", system.usdt.asset, system.usdt.aToken)
            )
        );

        system.usdt.strategyCompoundImpl = address(new MockTestnetStrategy());
        system.usdt.strategyCompoundProxy = address(
            new ERC1967Proxy(
                system.usdt.strategyCompoundImpl,
                abi.encodeWithSignature("initialize(address,address)", system.usdt.asset, system.usdt.cToken)
            )
        );

        system.usdc.strategyAaveImpl = address(new MockTestnetStrategy());
        system.usdc.strategyAaveProxy = address(
            new ERC1967Proxy(
                system.usdc.strategyAaveImpl,
                abi.encodeWithSignature("initialize(address,address)", system.usdc.asset, system.usdc.aToken)
            )
        );

        system.usdc.strategyCompoundImpl = address(new MockTestnetStrategy());
        system.usdc.strategyCompoundProxy = address(
            new ERC1967Proxy(
                system.usdc.strategyCompoundImpl,
                abi.encodeWithSignature("initialize(address,address)", system.usdc.asset, system.usdc.cToken)
            )
        );

        system.dai.strategyAaveImpl = address(new MockTestnetStrategy());
        system.dai.strategyAaveProxy = address(
            new ERC1967Proxy(
                system.dai.strategyAaveImpl,
                abi.encodeWithSignature("initialize(address,address)", system.dai.asset, system.dai.aToken)
            )
        );

        system.dai.strategyCompoundImpl = address(new MockTestnetStrategy());
        system.dai.strategyCompoundProxy = address(
            new ERC1967Proxy(
                system.dai.strategyCompoundImpl,
                abi.encodeWithSignature("initialize(address,address)", system.dai.asset, system.dai.cToken)
            )
        );

        system.usdt.assetManagementImpl = address(new AssetManagementUsdt());
        system.usdt.assetManagementProxy = address(
            new ERC1967Proxy(
                system.usdt.assetManagementImpl,
                abi.encodeWithSignature(
                    "initialize(address,address,address,address)",
                    system.usdt.asset,
                    system.usdt.ivToken,
                    system.usdt.strategyAaveProxy,
                    system.usdt.strategyCompoundProxy
                )
            )
        );

        system.usdc.assetManagementImpl = address(new AssetManagementUsdc());
        system.usdc.assetManagementProxy = address(
            new ERC1967Proxy(
                system.usdc.assetManagementImpl,
                abi.encodeWithSignature(
                    "initialize(address,address,address,address)",
                    system.usdc.asset,
                    system.usdc.ivToken,
                    system.usdc.strategyAaveProxy,
                    system.usdc.strategyCompoundProxy
                )
            )
        );

        system.dai.assetManagementImpl = address(new AssetManagementDai());
        system.dai.assetManagementProxy = address(
            new ERC1967Proxy(
                system.dai.assetManagementImpl,
                abi.encodeWithSignature(
                    "initialize(address,address,address,address)",
                    system.dai.asset,
                    system.dai.ivToken,
                    system.dai.strategyAaveProxy,
                    system.dai.strategyCompoundProxy
                )
            )
        );

        IStrategy(system.usdt.strategyAaveProxy).setAssetManagement(system.usdt.assetManagementProxy);
        IStrategy(system.usdc.strategyAaveProxy).setAssetManagement(system.usdc.assetManagementProxy);
        IStrategy(system.dai.strategyAaveProxy).setAssetManagement(system.dai.assetManagementProxy);

        IStrategy(system.usdt.strategyCompoundProxy).setAssetManagement(system.usdt.assetManagementProxy);
        IStrategy(system.usdc.strategyCompoundProxy).setAssetManagement(system.usdc.assetManagementProxy);
        IStrategy(system.dai.strategyCompoundProxy).setAssetManagement(system.dai.assetManagementProxy);
    }

    function upgradeAmmTreasury(System memory system) internal {
        system.usdt.ammTreasuryImpl = address(
            new AmmTreasury(
                system.usdt.asset,
                6,
                system.usdt.ammStorageProxy,
                system.usdt.assetManagementProxy,
                system.routerProxy
            )
        );
        AmmTreasury(system.usdt.ammTreasuryProxy).upgradeTo(system.usdt.ammTreasuryImpl);

        system.usdc.ammTreasuryImpl = address(
            new AmmTreasury(
                system.usdc.asset,
                6,
                system.usdc.ammStorageProxy,
                system.usdc.assetManagementProxy,
                system.routerProxy
            )
        );
        AmmTreasury(system.usdc.ammTreasuryProxy).upgradeTo(system.usdc.ammTreasuryImpl);

        system.dai.ammTreasuryImpl = address(
            new AmmTreasury(
                system.dai.asset,
                18,
                system.dai.ammStorageProxy,
                system.dai.assetManagementProxy,
                system.routerProxy
            )
        );
        AmmTreasury(system.dai.ammTreasuryProxy).upgradeTo(system.dai.ammTreasuryImpl);
    }

    function upgradeIporProtocolRouter(System memory system) internal {
        system.ammSwapsLens = address(
            new AmmSwapsLens(
                IAmmSwapsLens.SwapLensConfiguration({
                    asset: address(system.usdt.asset),
                    ammStorage: address(system.usdt.ammStorageProxy),
                    ammTreasury: address(system.usdt.ammTreasuryProxy)
                }),
                IAmmSwapsLens.SwapLensConfiguration({
                    asset: address(system.usdc.asset),
                    ammStorage: address(system.usdc.ammStorageProxy),
                    ammTreasury: address(system.usdc.ammTreasuryProxy)
                }),
                IAmmSwapsLens.SwapLensConfiguration({
                    asset: address(system.dai.asset),
                    ammStorage: address(system.dai.ammStorageProxy),
                    ammTreasury: address(system.dai.ammTreasuryProxy)
                }),
                IIporOracle(system.iporOracleProxy),
                system.riskOracleProxy,
                system.routerProxy
            )
        );

        system.ammPoolsLens = address(
            new AmmPoolsLens(
                IAmmPoolsLens.AmmPoolsLensPoolConfiguration({
                    asset: address(system.usdt.asset),
                    decimals: 6,
                    ipToken: address(system.usdt.ipToken),
                    ammStorage: address(system.usdt.ammStorageProxy),
                    ammTreasury: address(system.usdt.ammTreasuryProxy),
                    assetManagement: address(system.usdt.assetManagementProxy)
                }),
                IAmmPoolsLens.AmmPoolsLensPoolConfiguration({
                    asset: address(system.usdc.asset),
                    decimals: 6,
                    ipToken: address(system.usdc.ipToken),
                    ammStorage: address(system.usdc.ammStorageProxy),
                    ammTreasury: address(system.usdc.ammTreasuryProxy),
                    assetManagement: address(system.usdc.assetManagementProxy)
                }),
                IAmmPoolsLens.AmmPoolsLensPoolConfiguration({
                    asset: address(system.dai.asset),
                    decimals: 18,
                    ipToken: address(system.dai.ipToken),
                    ammStorage: address(system.dai.ammStorageProxy),
                    ammTreasury: address(system.dai.ammTreasuryProxy),
                    assetManagement: address(system.dai.assetManagementProxy)
                }),
                address(system.iporOracleProxy)
            )
        );

        system.assetManagementLens = address(
            new AssetManagementLens(
                IAssetManagementLens.AssetManagementConfiguration({
                    asset: system.usdt.asset,
                    decimals: 6,
                    assetManagement: system.usdt.assetManagementProxy,
                    ammTreasury: system.usdt.ammTreasuryProxy
                }),
                IAssetManagementLens.AssetManagementConfiguration({
                    asset: system.usdc.asset,
                    decimals: 6,
                    assetManagement: system.usdc.assetManagementProxy,
                    ammTreasury: system.usdc.ammTreasuryProxy
                }),
                IAssetManagementLens.AssetManagementConfiguration({
                    asset: system.dai.asset,
                    decimals: 18,
                    assetManagement: system.dai.assetManagementProxy,
                    ammTreasury: system.dai.ammTreasuryProxy
                })
            )
        );

        system.ammOpenSwapService = address(
            new AmmOpenSwapService({
                usdtPoolCfg: _preparePoolCfgForOpenSwapService(
                    address(system.usdt.asset),
                    address(system.usdt.ammTreasuryProxy),
                    address(system.usdt.ammStorageProxy)
                ),
                usdcPoolCfg: _preparePoolCfgForOpenSwapService(
                    address(system.usdc.asset),
                    address(system.usdc.ammTreasuryProxy),
                    address(system.usdc.ammStorageProxy)
                ),
                daiPoolCfg: _preparePoolCfgForOpenSwapService(
                    address(system.dai.asset),
                    address(system.dai.ammTreasuryProxy),
                    address(system.dai.ammStorageProxy)
                ),
                iporOracle: system.iporOracleProxy,
                iporRiskManagementOracle: system.riskOracleProxy,
                spreadRouter: system.spreadRouterProxy
            })
        );

        system.ammCloseSwapService = address(
            new AmmCloseSwapService({
                usdtPoolCfg: _preparePoolCfgForCloseSwapService(
                    address(system.usdt.asset),
                    address(system.usdt.ammTreasuryProxy),
                    address(system.usdt.ammStorageProxy),
                    address(system.usdt.assetManagementProxy)
                ),
                usdcPoolCfg: _preparePoolCfgForCloseSwapService(
                    address(system.usdc.asset),
                    address(system.usdc.ammTreasuryProxy),
                    address(system.usdc.ammStorageProxy),
                    address(system.usdc.assetManagementProxy)
                ),
                daiPoolCfg: _preparePoolCfgForCloseSwapService(
                    address(system.dai.asset),
                    address(system.dai.ammTreasuryProxy),
                    address(system.dai.ammStorageProxy),
                    address(system.dai.assetManagementProxy)
                ),
                iporOracle: address(system.iporOracleProxy),
                iporRiskManagementOracle: address(system.riskOracleProxy),
                spreadRouter: address(system.spreadRouterProxy)
            })
        );

        system.ammPoolsService = address(
            new AmmPoolsService({
                usdtPoolCfg: _preparePoolCfgForPoolsService(
                    address(system.usdt.asset),
                    address(system.usdt.ipToken),
                    address(system.usdt.ammTreasuryProxy),
                    address(system.usdt.ammStorageProxy),
                    address(system.usdt.assetManagementProxy)
                ),
                usdcPoolCfg: _preparePoolCfgForPoolsService(
                    address(system.usdc.asset),
                    address(system.usdc.ipToken),
                    address(system.usdc.ammTreasuryProxy),
                    address(system.usdc.ammStorageProxy),
                    address(system.usdc.assetManagementProxy)
                ),
                daiPoolCfg: _preparePoolCfgForPoolsService(
                    address(system.dai.asset),
                    address(system.dai.ipToken),
                    address(system.dai.ammTreasuryProxy),
                    address(system.dai.ammStorageProxy),
                    address(system.dai.assetManagementProxy)
                ),
                iporOracle: address(system.iporOracleProxy)
            })
        );

        system.ammGovernanceService = address(
            new AmmGovernanceService({
                usdtPoolCfg: _preparePoolCfgForGovernanceService(
                    address(system.usdt.asset),
                    address(system.usdt.ammTreasuryProxy),
                    address(system.usdt.ammStorageProxy)
                ),
                usdcPoolCfg: _preparePoolCfgForGovernanceService(
                    address(system.usdc.asset),
                    address(system.usdc.ammTreasuryProxy),
                    address(system.usdc.ammStorageProxy)
                ),
                daiPoolCfg: _preparePoolCfgForGovernanceService(
                    address(system.dai.asset),
                    address(system.dai.ammTreasuryProxy),
                    address(system.dai.ammStorageProxy)
                )
            })
        );

        IporProtocolRouter.DeployedContracts memory deployedContracts = IporProtocolRouter.DeployedContracts({
            ammSwapsLens: system.ammSwapsLens,
            ammPoolsLens: system.ammPoolsLens,
            assetManagementLens: system.assetManagementLens,
            ammOpenSwapService: system.ammOpenSwapService,
            ammCloseSwapService: system.ammCloseSwapService,
            ammPoolsService: system.ammPoolsService,
            ammGovernanceService: system.ammGovernanceService,
            liquidityMiningLens: ammConfig.liquidityMiningLens,
            powerTokenLens: ammConfig.powerTokenLens,
            flowService: ammConfig.flowService,
            stakeService: ammConfig.stakeService
        });

        system.routerImpl = address(new IporProtocolRouter(deployedContracts));
        IporProtocolRouter(system.routerProxy).upgradeTo(system.routerImpl);
    }

    function deployFaucet(System memory system) internal {
        system.faucetImpl = address(new TestnetFaucet());
        system.faucetProxy = address(
            new ERC1967Proxy(
                system.faucetImpl,
                abi.encodeWithSignature(
                    "initialize(address,address,address,address)",
                    system.dai.asset,
                    system.usdc.asset,
                    system.usdt.asset,
                    system.iporToken
                )
            )
        );
    }

    function deployIporToken(System memory system) internal {
        system.iporToken = address(new IporToken("Ipor Token", "IPOR", defaultAnvilAddress));
    }

    function _toAddressesJson(System memory system) internal {
        string memory path = vm.projectRoot();
        string memory addressesJson = "";

        vm.serializeAddress(addressesJson, "USDT", system.usdt.asset);
        vm.serializeAddress(addressesJson, "USDC", system.usdc.asset);
        vm.serializeAddress(addressesJson, "DAI", system.dai.asset);

        vm.serializeAddress(addressesJson, "ipUSDT", system.usdt.ipToken);
        vm.serializeAddress(addressesJson, "ipUSDC", system.usdc.ipToken);
        vm.serializeAddress(addressesJson, "ipDAI", system.dai.ipToken);

        vm.serializeAddress(addressesJson, "ivUSDT", system.usdt.ivToken);
        vm.serializeAddress(addressesJson, "ivUSDC", system.usdc.ivToken);
        vm.serializeAddress(addressesJson, "ivDAI", system.dai.ivToken);

        vm.serializeAddress(addressesJson, "aUSDT", system.usdt.aToken);
        vm.serializeAddress(addressesJson, "aUSDC", system.usdc.aToken);
        vm.serializeAddress(addressesJson, "aDAI", system.dai.aToken);

        vm.serializeAddress(addressesJson, "cUSDT", system.usdt.cToken);
        vm.serializeAddress(addressesJson, "cUSDC", system.usdc.cToken);
        vm.serializeAddress(addressesJson, "cDAI", system.dai.cToken);

        vm.serializeAddress(addressesJson, "StrategyCompoundUsdtProxy", system.usdt.strategyCompoundProxy);
        vm.serializeAddress(addressesJson, "StrategyCompoundUsdcProxy", system.usdc.strategyCompoundProxy);
        vm.serializeAddress(addressesJson, "StrategyCompoundDaiProxy", system.dai.strategyCompoundProxy);

        vm.serializeAddress(addressesJson, "StrategyCompoundUsdtImpl", system.usdt.strategyCompoundImpl);
        vm.serializeAddress(addressesJson, "StrategyCompoundUsdcImpl", system.usdc.strategyCompoundImpl);
        vm.serializeAddress(addressesJson, "StrategyCompoundDaiImpl", system.dai.strategyCompoundImpl);

        vm.serializeAddress(addressesJson, "StrategyAaveUsdt", system.usdt.strategyAaveProxy);
        vm.serializeAddress(addressesJson, "StrategyAaveUsdc", system.usdc.strategyAaveProxy);
        vm.serializeAddress(addressesJson, "StrategyAaveDai", system.dai.strategyAaveProxy);

        vm.serializeAddress(addressesJson, "StrategyAaveUsdtImpl", system.usdt.strategyAaveImpl);
        vm.serializeAddress(addressesJson, "StrategyAaveUsdcImpl", system.usdc.strategyAaveImpl);
        vm.serializeAddress(addressesJson, "StrategyAaveDaiImpl", system.dai.strategyAaveImpl);

        vm.serializeAddress(addressesJson, "AmmStorageUsdtProxy", system.usdt.ammStorageProxy);
        vm.serializeAddress(addressesJson, "AmmStorageUsdcProxy", system.usdc.ammStorageProxy);
        vm.serializeAddress(addressesJson, "AmmStorageDaiProxy", system.dai.ammStorageProxy);

        vm.serializeAddress(addressesJson, "AmmStorageUsdtImpl", system.usdt.ammStorageImpl);
        vm.serializeAddress(addressesJson, "AmmStorageUsdcImpl", system.usdc.ammStorageImpl);
        vm.serializeAddress(addressesJson, "AmmStorageDaiImpl", system.dai.ammStorageImpl);

        vm.serializeAddress(addressesJson, "AssetManagementUsdtProxy", system.usdt.assetManagementProxy);
        vm.serializeAddress(addressesJson, "AssetManagementUsdcProxy", system.usdc.assetManagementProxy);
        vm.serializeAddress(addressesJson, "AssetManagementDaiProxy", system.dai.assetManagementProxy);

        vm.serializeAddress(addressesJson, "AssetManagementUsdtImpl", system.usdt.assetManagementImpl);
        vm.serializeAddress(addressesJson, "AssetManagementUsdcImpl", system.usdc.assetManagementImpl);
        vm.serializeAddress(addressesJson, "AssetManagementDaiImpl", system.dai.assetManagementImpl);

        vm.serializeAddress(addressesJson, "AmmTreasuryUsdtProxy", system.usdt.ammTreasuryProxy);
        vm.serializeAddress(addressesJson, "AmmTreasuryUsdcProxy", system.usdc.ammTreasuryProxy);
        vm.serializeAddress(addressesJson, "AmmTreasuryDaiProxy", system.dai.ammTreasuryProxy);

        vm.serializeAddress(addressesJson, "AmmTreasuryUsdtImpl", system.usdt.ammTreasuryImpl);
        vm.serializeAddress(addressesJson, "AmmTreasuryUsdcImpl", system.usdc.ammTreasuryImpl);
        vm.serializeAddress(addressesJson, "AmmTreasuryDaiImpl", system.dai.ammTreasuryImpl);

        vm.serializeAddress(addressesJson, "SpreadRouterProxy", system.spreadRouterProxy);
        vm.serializeAddress(addressesJson, "IporOracleProxy", system.iporOracleProxy);
        vm.serializeAddress(addressesJson, "IporRiskManagementOracleProxy", system.riskOracleProxy);

        vm.serializeAddress(addressesJson, "SpreadRouterImpl", system.spreadRouterImpl);
        vm.serializeAddress(addressesJson, "IporOracleImpl", system.iporOracleImpl);
        vm.serializeAddress(addressesJson, "IporRiskManagementOracleImpl", system.riskOracleImpl);

        vm.serializeAddress(addressesJson, "IporProtocolRouterProxy", system.routerProxy);
        vm.serializeAddress(addressesJson, "IporProtocolRouterImpl", system.routerImpl);

        vm.serializeAddress(addressesJson, "IporToken", system.iporToken);
        vm.serializeAddress(addressesJson, "FaucetImpl", system.faucetImpl);
        vm.serializeAddress(addressesJson, "FaucetProxy", system.faucetProxy);

        string memory finalJson = vm.serializeAddress(addressesJson, "IporProtocolRouterProxy", system.routerProxy);

        vm.writeJson(finalJson, string.concat(path, "/.ipor/", _env_profile, "-ipor-protocol-addresses.json"));
    }
}

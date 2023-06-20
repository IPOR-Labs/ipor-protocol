// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.20;

import "forge-std/Test.sol";
import "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import "contracts/oracles/IporOracle.sol";
import "contracts/oracles/IporRiskManagementOracle.sol";
import "contracts/oracles/libraries/IporRiskManagementOracleStorageTypes.sol";
import "../mocks/EmptyRouterImplementation.sol";
import "contracts/router/IporProtocolRouter.sol";
import "contracts/interfaces/IAmmSwapsLens.sol";
import "../../contracts/amm/AmmSwapsLens.sol";
import "../../contracts/amm/AmmPoolsLens.sol";
import "../../contracts/amm/AssetManagementLens.sol";
import "../../contracts/amm/spread/Spread28Days.sol";
import "../../contracts/amm/spread/Spread60Days.sol";
import "../../contracts/amm/spread/Spread90Days.sol";
import "../../contracts/amm/spread/SpreadCloseSwapService.sol";
import "../../contracts/amm/spread/SpreadStorageLens.sol";
import "../../contracts/amm/spread/SpreadRouter.sol";
import "../../contracts/amm/AmmOpenSwapService.sol";
import "../../contracts/amm/AmmCloseSwapService.sol";
import "../../contracts/amm/AmmPoolsService.sol";
import "../../contracts/amm/AmmGovernanceService.sol";
import "../../contracts/amm/AmmStorage.sol";
import "../../contracts/amm/AmmTreasury.sol";

contract TestForkCommons is Test {
    address public constant owner = 0xD92E9F039E4189c342b4067CC61f5d063960D248;
    address public constant IPOR = 0x1e4746dC744503b53b4A082cB3607B169a289090;

    address public constant DAI = 0x6B175474E89094C44Da98b954EedeAC495271d0F;
    address public constant USDC = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;
    address public constant USDT = 0xdAC17F958D2ee523a2206206994597C13D831ec7;

    address public constant aDAI = 0x028171bCA77440897B824Ca71D1c56caC55b68A3;
    address public constant aUSDC = 0xBcca60bB61934080951369a648Fb03DF4F96263C;
    address public constant aUSDT = 0x3Ed3B47Dd13EC9a98b44e6204A523E766B225811;

    address public constant ipDAI = 0x8537b194BFf354c4738E9F3C81d67E3371DaDAf8;
    address public constant ipUSDC = 0x7c0e72f431FD69560D951e4C04A4de3657621a88;
    address public constant ipUSDT = 0x9Bd2177027edEE300DC9F1fb88F24DB6e5e1edC6;

    address public constant iporOracleProxy = 0x421C69EAa54646294Db30026aeE80D01988a6876;

    address public constant miltonStorageProxyDai = 0xb99f2a02c0851efdD417bd6935d2eFcd23c56e61;
    address public constant miltonStorageProxyUsdc = 0xB3d1c1aB4D30800162da40eb18B3024154924ba5;
    address public constant miltonStorageProxyUsdt = 0x364f116352EB95033D73822bA81257B8c1f5B1CE;

    address public constant miltonProxyDai = 0xEd7d74AA7eB1f12F83dA36DFaC1de2257b4e7523;
    address public constant miltonProxyUsdc = 0x137000352B4ed784e8fa8815d225c713AB2e7Dc9;
    address public constant miltonProxyUsdt = 0x28BC58e600eF718B9E97d294098abecb8c96b687;

    address public constant josephProxyDai = 0x086d4daab14741b195deE65aFF050ba184B65045;
    address public constant josephProxyUsdc = 0xC52569b5A349A7055E9192dBdd271F1Bd8133277;
    address public constant josephProxyUsdt = 0x33C5A44fd6E76Fc2b50a9187CfeaC336A74324AC;

    address public constant stanleyProxyDai = 0xA6aC8B6AF789319A1Db994E25760Eb86F796e2B0;
    address public constant stanleyProxyUsdc = 0x7aa7b0B738C2570C2f9F892cB7cA5bB89b9BF260;
    address public constant stanleyProxyUsdt = 0x8e679C1d67Af0CD4b314896856f09ece9E64D6B5;

    address public constant oracleUpdater = 0xC3A53976E9855d815A08f577C2BEef2a799470b7;

    address public constant AAVE = 0x7Fc66500c84A76Ad7e9c93437bFc5Ac33E2DDaE9;
    address public constant stakedAAVE = 0x4da27a545c0c5B758a6BA100e3a049001de870f5;
    address public constant aaveLendingPoolAddressProvider = 0xB53C1a33016B2DC2fF3653530bfF1848a515c8c5;
    address public constant aaveIncentivesController = 0xd784927Ff2f95ba542BfC824c8a8a98F3495f6b5;

    // new contracts for v2
    address public iporRiskManagementOracleProxy;
    address public iporProtocolRouterProxy;
    address public ammSwapsLens;
    address public ammPoolsLens;
    address public assetManagementLens;

    address public spread28Days;
    address public spread60Days;
    address public spread90Days;
    address public spreadCloseSwapService;
    address public spreadStorageLens;
    address public spreadRouter;

    address public ammOpenSwapService;
    address public ammCloseSwapService;
    address public ammPoolsService;
    address public ammGovernanceService;

    function _init() internal {
        (uint IporOracleVersionBefore, uint IporOracleVersionAfter) = _switchImplementationOfIporOracle();
        uint iporRiskManagementOracleVersion = _createIporRiskManagementOracle();
        _createEmptyRouterImplementation();

        _createAmmPoolsLens();
        _createAssetManagementLens();

        _creatSpreadModule();

        _createAmmSwapsLens();
        _createAmmOpenSwapService();
        _createAmmCloseSwapService();
        _createAmmPoolsService();
        _createAmmGovernanceService();
        _updateIporRouterImplementation();
        _switchMiltonStorageToAmmStorage();
        _switchMiltonToAmmTreasury();
        _setUpIpTokens();
        _setAmmPoolsParams();
    }

    function _updateIporRouterImplementation() internal {
        IporProtocolRouter newImplementation = new IporProtocolRouter(
            IporProtocolRouter.DeployedContracts(
                ammSwapsLens,
                ammPoolsLens,
                assetManagementLens,
                ammOpenSwapService,
                ammCloseSwapService,
                ammPoolsService,
                ammGovernanceService,
                _getUserAddress(123),
                _getUserAddress(123),
                _getUserAddress(123),
                _getUserAddress(123)
            )
        );
        console2.log("owner", owner);
        console2.log(
            "IporProtocolRouter(iporProtocolRouterProxy)",
            IporProtocolRouter(iporProtocolRouterProxy).owner()
        );
        vm.prank(owner);
        IporProtocolRouter(iporProtocolRouterProxy).upgradeTo(address(newImplementation));
    }

    function _getUserAddress(uint256 number) internal returns (address) {
        return vm.rememberKey(number);
    }

    function _switchImplementationOfIporOracle() private returns (uint256 versionBefore, uint256 versionAfter) {
        versionBefore = IporOracle(iporOracleProxy).getVersion();
        // todo fix złe wartości
        IporTypes.AccruedIpor memory daiAccruedIpor = IporOracle(iporOracleProxy).getAccruedIndex(block.timestamp, DAI);
        IporTypes.AccruedIpor memory usdcAccruedIpor = IporOracle(iporOracleProxy).getAccruedIndex(
            block.timestamp,
            USDC
        );
        IporTypes.AccruedIpor memory usdtAccruedIpor = IporOracle(iporOracleProxy).getAccruedIndex(
            block.timestamp,
            USDT
        );

        console2.log("daiInitialIbtPrice", daiAccruedIpor.ibtPrice);

        IporOracle iporOracleImplementation = new IporOracle(
            USDT,
            usdtAccruedIpor.ibtPrice,
            USDC,
            usdcAccruedIpor.ibtPrice,
            DAI,
            daiAccruedIpor.ibtPrice
        );

        vm.prank(owner);
        IporOracle(iporOracleProxy).upgradeTo(address(iporOracleImplementation));

        address[] memory assets = new address[](3);
        assets[2] = DAI;
        assets[1] = USDC;
        assets[0] = USDT;

        vm.prank(owner);
        IporOracle(iporOracleProxy).postUpgrade(assets);

        versionAfter = IporOracle(iporOracleProxy).getVersion();
    }

    function _createIporRiskManagementOracle() private returns (uint256 version) {
        IporRiskManagementOracle iporRiskManagementOracleImplementation = new IporRiskManagementOracle();

        IporRiskManagementOracleTypes.RiskIndicators memory riskIndicator = IporRiskManagementOracleTypes
            .RiskIndicators({
                maxNotionalPayFixed: 100, // 1_000_000
                maxNotionalReceiveFixed: 100, // 1_000_000
                maxCollateralRatioPayFixed: 500, // 5%
                maxCollateralRatioReceiveFixed: 500, // 5%
                maxCollateralRatio: 500 // 5%
            });

        IporRiskManagementOracleTypes.RiskIndicators[]
            memory riskIndicators = new IporRiskManagementOracleTypes.RiskIndicators[](3);
        riskIndicators[0] = riskIndicator;
        riskIndicators[1] = riskIndicator;
        riskIndicators[2] = riskIndicator;

        IporRiskManagementOracleTypes.BaseSpreadsAndFixedRateCaps
            memory baseSpreadsAndFixedRateCap = IporRiskManagementOracleTypes.BaseSpreadsAndFixedRateCaps(
                1000, // 0.1%
                -1000, // -0.1%
                1000, // 0.1%
                -1000, // -0.1%
                1000, // 0.1%
                -1000, // -0.1%
                200, // 2%
                350, // 3.5%
                200, // 2%
                350, // 3.5%
                200, // 2%
                350 // 3.5%
            );

        IporRiskManagementOracleTypes.BaseSpreadsAndFixedRateCaps[]
            memory baseSpreadsAndFixedRateCaps = new IporRiskManagementOracleTypes.BaseSpreadsAndFixedRateCaps[](3);
        baseSpreadsAndFixedRateCaps[0] = baseSpreadsAndFixedRateCap;
        baseSpreadsAndFixedRateCaps[1] = baseSpreadsAndFixedRateCap;
        baseSpreadsAndFixedRateCaps[2] = baseSpreadsAndFixedRateCap;

        ERC1967Proxy proxy = new ERC1967Proxy(
            address(iporRiskManagementOracleImplementation),
            abi.encodeWithSignature(
                "initialize(address[],(uint256,uint256,uint256,uint256,uint256)[],(int256,int256,int256,int256,int256,int256,uint256,uint256,uint256,uint256,uint256,uint256)[])",
                _getAssets(),
                riskIndicators,
                baseSpreadsAndFixedRateCaps
            )
        );

        iporRiskManagementOracleProxy = address(proxy);
        version = IporRiskManagementOracle(iporRiskManagementOracleProxy).getVersion();
    }

    function _createEmptyRouterImplementation() private {
        vm.prank(owner);
        address implementation = address(new EmptyRouterImplementation());
        ERC1967Proxy proxy = _constructProxy(implementation);
        iporProtocolRouterProxy = address(proxy);
    }

    function _createAmmSwapsLens() private {
        IAmmSwapsLens.SwapLensPoolConfiguration memory daiConfig = IAmmSwapsLens.SwapLensPoolConfiguration(
            DAI,
            miltonStorageProxyDai,
            miltonProxyDai,
            10 * 1e18
        );
        IAmmSwapsLens.SwapLensPoolConfiguration memory usdcConfig = IAmmSwapsLens.SwapLensPoolConfiguration(
            USDC,
            miltonStorageProxyUsdc,
            miltonProxyUsdc,
            10 * 1e18
        );
        IAmmSwapsLens.SwapLensPoolConfiguration memory usdtConfig = IAmmSwapsLens.SwapLensPoolConfiguration(
            USDT,
            miltonStorageProxyUsdt,
            miltonProxyUsdt,
            10 * 1e18
        );

        ammSwapsLens = address(
            new AmmSwapsLens(
                usdtConfig,
                usdcConfig,
                daiConfig,
                iporOracleProxy,
                iporRiskManagementOracleProxy,
                iporProtocolRouterProxy,
                spreadRouter
            )
        );
        console2.log("ammSwapsLens: ", ammSwapsLens);
    }

    function _createAmmPoolsLens() private {
        IAmmPoolsLens.AmmPoolsLensPoolConfiguration memory daiConfig = IAmmPoolsLens.AmmPoolsLensPoolConfiguration(
            DAI,
            18,
            ipDAI,
            miltonStorageProxyDai,
            miltonProxyDai,
            stanleyProxyDai
        );

        IAmmPoolsLens.AmmPoolsLensPoolConfiguration memory usdcConfig = IAmmPoolsLens.AmmPoolsLensPoolConfiguration(
            USDC,
            6,
            ipUSDC,
            miltonStorageProxyUsdc,
            miltonProxyUsdc,
            stanleyProxyUsdc
        );

        IAmmPoolsLens.AmmPoolsLensPoolConfiguration memory usdtConfig = IAmmPoolsLens.AmmPoolsLensPoolConfiguration(
            USDT,
            6,
            ipUSDT,
            miltonStorageProxyUsdt,
            miltonProxyUsdt,
            stanleyProxyUsdt
        );

        ammPoolsLens = address(new AmmPoolsLens(usdtConfig, usdcConfig, daiConfig, iporOracleProxy));
        console2.log("ammPoolsLens: ", ammPoolsLens);
    }

    function _createAssetManagementLens() private {
        IAssetManagementLens.AssetManagementConfiguration memory daiConfig = IAssetManagementLens
            .AssetManagementConfiguration(DAI, 18, stanleyProxyDai, miltonProxyDai);

        IAssetManagementLens.AssetManagementConfiguration memory usdcConfig = IAssetManagementLens
            .AssetManagementConfiguration(USDC, 6, stanleyProxyUsdc, miltonProxyUsdc);

        IAssetManagementLens.AssetManagementConfiguration memory usdtConfig = IAssetManagementLens
            .AssetManagementConfiguration(USDT, 6, stanleyProxyUsdt, miltonProxyUsdt);

        assetManagementLens = address(new AssetManagementLens(usdtConfig, usdcConfig, daiConfig));

        console2.log("assetManagementLens: ", assetManagementLens);
    }

    function _creatSpreadModule() private {
        spread28Days = address(new Spread28Days(DAI, USDC, USDT));
        spread60Days = address(new Spread60Days(DAI, USDC, USDT));
        spread90Days = address(new Spread90Days(DAI, USDC, USDT));
        spreadCloseSwapService = address(new SpreadCloseSwapService(DAI, USDC, USDT));
        spreadStorageLens = address(new SpreadStorageLens());

        SpreadRouter routerImplementation = new SpreadRouter(
            SpreadRouter.DeployedContracts(
                iporProtocolRouterProxy,
                spread28Days,
                spread60Days,
                spread90Days,
                spreadStorageLens,
                spreadCloseSwapService
            )
        );
        ERC1967Proxy proxy = new ERC1967Proxy(
            address(routerImplementation),
            abi.encodeWithSignature("initialize(bool)", false)
        );
        spreadRouter = address(proxy);
        console2.log("spreadRouter: ", spreadRouter);
    }

    function _createAmmOpenSwapService() private {
        IAmmOpenSwapService.AmmOpenSwapServicePoolConfiguration memory daiConfig = IAmmOpenSwapService
            .AmmOpenSwapServicePoolConfiguration(
                DAI,
                18,
                miltonStorageProxyDai,
                miltonProxyDai,
                10 * 1e18,
                100_000 * 1e18,
                25,
                10 * 1e18,
                5e14,
                5e17
            );

        IAmmOpenSwapService.AmmOpenSwapServicePoolConfiguration memory usdcConfig = IAmmOpenSwapService
            .AmmOpenSwapServicePoolConfiguration(
                USDC,
                6,
                miltonStorageProxyUsdc,
                miltonProxyUsdc,
                10 * 1e18,
                100_000 * 1e18,
                25,
                10 * 1e18,
                5e11,
                5e14
            );

        IAmmOpenSwapService.AmmOpenSwapServicePoolConfiguration memory usdtConfig = IAmmOpenSwapService
            .AmmOpenSwapServicePoolConfiguration(
                USDT,
                6,
                miltonStorageProxyUsdt,
                miltonProxyUsdt,
                10 * 1e18,
                100_000 * 1e18,
                25,
                10 * 1e18,
                5e11,
                5e14
            );

        ammOpenSwapService = address(
            new AmmOpenSwapService(
                usdtConfig,
                usdcConfig,
                daiConfig,
                iporOracleProxy,
                iporRiskManagementOracleProxy,
                spreadRouter
            )
        );

        console2.log("ammOpenSwapService: ", ammOpenSwapService);
    }

    function _createAmmCloseSwapService() private {
        IAmmCloseSwapService.AmmCloseSwapServicePoolConfiguration memory daiConfig = IAmmCloseSwapService
            .AmmCloseSwapServicePoolConfiguration(
                DAI,
                18,
                miltonStorageProxyDai,
                miltonProxyDai,
                stanleyProxyDai,
                5e14,
                5e14,
                10,
                1 hours,
                1 days,
                995 * 1e15,
                99 * 1e16,
                10 * 1e18
            );

        IAmmCloseSwapService.AmmCloseSwapServicePoolConfiguration memory usdcConfig = IAmmCloseSwapService
            .AmmCloseSwapServicePoolConfiguration(
                USDC,
                6,
                miltonStorageProxyUsdc,
                miltonProxyUsdc,
                stanleyProxyUsdc,
                5e11,
                5e11,
                10,
                1 hours,
                1 days,
                995 * 1e15,
                99 * 1e16,
                10 * 1e6
            );

        IAmmCloseSwapService.AmmCloseSwapServicePoolConfiguration memory usdtConfig = IAmmCloseSwapService
            .AmmCloseSwapServicePoolConfiguration(
                USDT,
                6,
                miltonStorageProxyUsdt,
                miltonProxyUsdt,
                stanleyProxyUsdt,
                5e11,
                5e11,
                10,
                1 hours,
                1 days,
                995 * 1e15,
                99 * 1e16,
                10 * 1e6
            );
        ammCloseSwapService = address(
            new AmmCloseSwapService(
                usdtConfig,
                usdcConfig,
                daiConfig,
                iporOracleProxy,
                iporRiskManagementOracleProxy,
                spreadRouter
            )
        );
        console2.log("ammCloseSwapService: ", ammCloseSwapService);
    }

    function _createAmmPoolsService() private {
        IAmmPoolsService.AmmPoolsServicePoolConfiguration memory daiConfig = IAmmPoolsService
            .AmmPoolsServicePoolConfiguration(
                DAI,
                18,
                ipDAI,
                miltonStorageProxyDai,
                miltonProxyDai,
                stanleyProxyDai,
                5e15,
                1e18
            );

        IAmmPoolsService.AmmPoolsServicePoolConfiguration memory usdcConfig = IAmmPoolsService
            .AmmPoolsServicePoolConfiguration(
                USDC,
                6,
                ipUSDC,
                miltonStorageProxyUsdc,
                miltonProxyUsdc,
                stanleyProxyUsdc,
                5e15,
                1e18
            );

        IAmmPoolsService.AmmPoolsServicePoolConfiguration memory usdtConfig = IAmmPoolsService
            .AmmPoolsServicePoolConfiguration(
                USDT,
                6,
                ipUSDT,
                miltonStorageProxyUsdt,
                miltonProxyUsdt,
                stanleyProxyUsdt,
                5e15,
                1e18
            );

        ammPoolsService = address(new AmmPoolsService(usdtConfig, usdcConfig, daiConfig, iporOracleProxy));
        console2.log("ammPoolsService: ", ammPoolsService);
    }

    function _createAmmGovernanceService() private {
        IAmmGovernanceLens.AmmGovernancePoolConfiguration memory daiConfig = IAmmGovernanceLens
            .AmmGovernancePoolConfiguration(
                DAI,
                18,
                miltonStorageProxyDai,
                miltonProxyDai,
                _getUserAddress(123),
                _getUserAddress(123),
                _getUserAddress(123),
                _getUserAddress(123)
            );

        IAmmGovernanceLens.AmmGovernancePoolConfiguration memory usdcConfig = IAmmGovernanceLens
            .AmmGovernancePoolConfiguration(
                USDC,
                6,
                miltonStorageProxyUsdc,
                miltonProxyUsdc,
                _getUserAddress(123),
                _getUserAddress(123),
                _getUserAddress(123),
                _getUserAddress(123)
            );

        IAmmGovernanceLens.AmmGovernancePoolConfiguration memory usdtConfig = IAmmGovernanceLens
            .AmmGovernancePoolConfiguration(
                USDT,
                6,
                miltonStorageProxyUsdt,
                miltonProxyUsdt,
                _getUserAddress(123),
                _getUserAddress(123),
                _getUserAddress(123),
                _getUserAddress(123)
            );

        ammGovernanceService = address(new AmmGovernanceService(usdtConfig, usdcConfig, daiConfig));

        console2.log("ammGovernanceService: ", ammGovernanceService);
    }

    function _switchMiltonStorageToAmmStorage() private {
        AmmStorage daiStorageImplementation = new AmmStorage(iporProtocolRouterProxy, miltonProxyDai);
        AmmStorage usdcStorageImplementation = new AmmStorage(iporProtocolRouterProxy, miltonProxyUsdc);
        AmmStorage usdtStorageImplementation = new AmmStorage(iporProtocolRouterProxy, miltonProxyUsdt);
        vm.startPrank(owner);
        AmmStorage(miltonStorageProxyDai).upgradeTo(address(daiStorageImplementation));
        AmmStorage(miltonStorageProxyUsdc).upgradeTo(address(usdcStorageImplementation));
        AmmStorage(miltonStorageProxyUsdt).upgradeTo(address(usdtStorageImplementation));
        AmmStorage(miltonStorageProxyDai).postUpgrade();
        AmmStorage(miltonStorageProxyUsdc).postUpgrade();
        AmmStorage(miltonStorageProxyUsdt).postUpgrade();
        vm.stopPrank();
    }

    function _switchMiltonToAmmTreasury() private {
        AmmTreasury daiTreasuryImplementation = new AmmTreasury(
            DAI,
            18,
            miltonStorageProxyDai,
            stanleyProxyDai,
            iporProtocolRouterProxy
        );

        AmmTreasury usdcTreasuryImplementation = new AmmTreasury(
            USDC,
            6,
            miltonStorageProxyUsdc,
            stanleyProxyUsdc,
            iporProtocolRouterProxy
        );

        AmmTreasury usdtTreasuryImplementation = new AmmTreasury(
            USDT,
            6,
            miltonStorageProxyUsdt,
            stanleyProxyUsdt,
            iporProtocolRouterProxy
        );

        console2.log("AmmTreasury(miltonProxyDai)", AmmTreasury(miltonProxyDai).owner());
        console2.log("AmmTreasury(miltonProxyUsdc)", AmmTreasury(miltonProxyUsdc).owner());
        console2.log("AmmTreasury(miltonProxyUsdt)", AmmTreasury(miltonProxyUsdt).owner());
        console2.log("IporOwnableUpgradeable(miltonProxyDai)", IporOwnableUpgradeable(miltonProxyDai).owner());
        console2.log("owner", owner);
        vm.startPrank(owner);
        AmmTreasury(miltonProxyDai).upgradeTo(address(daiTreasuryImplementation));
        AmmTreasury(miltonProxyUsdc).upgradeTo(address(usdcTreasuryImplementation));
        AmmTreasury(miltonProxyUsdt).upgradeTo(address(usdtTreasuryImplementation));
        AmmTreasury(miltonProxyDai).setupMaxAllowanceForAsset(iporProtocolRouterProxy);
        AmmTreasury(miltonProxyUsdc).setupMaxAllowanceForAsset(iporProtocolRouterProxy);
        AmmTreasury(miltonProxyUsdt).setupMaxAllowanceForAsset(iporProtocolRouterProxy);
        vm.stopPrank();
    }

    function _setUpIpTokens() private {
        vm.startPrank(owner);
        IIpToken(ipDAI).setJoseph(iporProtocolRouterProxy);
        IIpToken(ipUSDC).setJoseph(iporProtocolRouterProxy);
        IIpToken(ipUSDT).setJoseph(iporProtocolRouterProxy);
        vm.stopPrank();
    }

    function _setAmmPoolsParams() private {
        vm.startPrank(owner);
        IAmmGovernanceService(iporProtocolRouterProxy).setAmmPoolsParams(
            DAI,
            type(uint32).max,
            type(uint32).max,
            0,
            5000
        );
        IAmmGovernanceService(iporProtocolRouterProxy).setAmmPoolsParams(
            USDC,
            type(uint32).max,
            type(uint32).max,
            0,
            5000
        );
        IAmmGovernanceService(iporProtocolRouterProxy).setAmmPoolsParams(
            USDT,
            type(uint32).max,
            type(uint32).max,
            0,
            5000
        );
        vm.stopPrank();
    }

    function _getAssets() internal returns (address[] memory) {
        address[] memory assets = new address[](3);
        assets[0] = DAI;
        assets[1] = USDC;
        assets[2] = USDT;
        return assets;
    }

    function _constructProxy(address impl) private returns (ERC1967Proxy proxy) {
        vm.prank(owner);
        proxy = new ERC1967Proxy(address(impl), abi.encodeWithSignature("initialize(bool)", false));
    }
}

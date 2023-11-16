// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.20;

import "forge-std/Test.sol";
import "forge-std/console2.sol";
import "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import "../../contracts/oracles/IporOracle.sol";
import "../mocks/EmptyRouterImplementation.sol";
import "../../contracts/router/IporProtocolRouter.sol";
import "../../contracts/interfaces/IAmmSwapsLens.sol";
import "../../contracts/interfaces/IAmmOpenSwapLens.sol";
import "../../contracts/interfaces/IAmmCloseSwapLens.sol";
import "../../contracts/amm-common/AmmSwapsLens.sol";
import "../../contracts/amm/AmmPoolsLens.sol";
import "../../contracts/amm/AssetManagementLens.sol";
import "../../contracts/amm/spread/Spread28Days.sol";
import "../../contracts/amm/spread/Spread60Days.sol";
import "../../contracts/amm/spread/Spread90Days.sol";
import "../../contracts/amm/spread/SpreadCloseSwapService.sol";
import "../../contracts/amm/spread/SpreadStorageLens.sol";
import "../../contracts/amm/spread/SpreadRouter.sol";
import "../../contracts/amm/AmmOpenSwapService.sol";
import "../../contracts/amm-eth/AmmOpenSwapServiceStEth.sol";
import "../../contracts/amm/AmmCloseSwapService.sol";
import "../../contracts/amm-eth/AmmCloseSwapServiceStEth.sol";
import "../../contracts/amm/AmmPoolsService.sol";
import "../../contracts/amm-common/AmmGovernanceService.sol";
import "../../contracts/amm/AmmStorage.sol";
import "../../contracts/basic/amm/AmmStorageGenOne.sol";
import "../../contracts/amm/AmmTreasury.sol";
import "../../contracts/amm-eth/AmmTreasuryEth.sol";
import "../../contracts/vault/strategies/StrategyDsrDai.sol";
import "../../contracts/vault/AssetManagementDai.sol";
import "../../contracts/vault/AssetManagementUsdt.sol";
import "../../contracts/vault/AssetManagementUsdc.sol";
import "../../contracts/vault/strategies/StrategyAave.sol";
import "../../contracts/vault/strategies/StrategyCompound.sol";
import "../../contracts/interfaces/IIpTokenV1.sol";
import "../../contracts/amm-eth/interfaces/IWETH9.sol";
import "../../contracts/amm-eth/interfaces/IStETH.sol";
import "../../contracts/basic/spread/SpreadGenOne.sol";

contract TestForkCommons is Test {
    address public constant owner = 0xD92E9F039E4189c342b4067CC61f5d063960D248;
    address public constant IPOR = 0x1e4746dC744503b53b4A082cB3607B169a289090;

    address public constant DAI = 0x6B175474E89094C44Da98b954EedeAC495271d0F;
    address public constant USDC = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;
    address public constant USDT = 0xdAC17F958D2ee523a2206206994597C13D831ec7;

    address public constant aDAI = 0x028171bCA77440897B824Ca71D1c56caC55b68A3;
    address public constant aUSDC = 0xBcca60bB61934080951369a648Fb03DF4F96263C;
    address public constant aUSDT = 0x3Ed3B47Dd13EC9a98b44e6204A523E766B225811;

    address public constant cDAI = 0x5d3a536E4D6DbD6114cc1Ead35777bAB948E3643;
    address public constant cUSDC = 0x39AA39c021dfbaE8faC545936693aC917d5E7563;
    address public constant cUSDT = 0xf650C3d88D12dB855b8bf7D11Be6C55A4e07dCC9;

    address public constant sDai = 0x83F20F44975D03b1b09e64809B757c47f942BEeA;

    address public constant ipDAI = 0x8537b194BFf354c4738E9F3C81d67E3371DaDAf8;
    address public constant ipUSDC = 0x7c0e72f431FD69560D951e4C04A4de3657621a88;
    address public constant ipUSDT = 0x9Bd2177027edEE300DC9F1fb88F24DB6e5e1edC6;

    address public constant ETH = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;
    address public constant stETH = 0xae7ab96520DE3A18E5e111B5EaAb095312D7fE84;
    address public constant wETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    address public constant wstETH = 0x7f39C581F595B53c5cb19bD0b3f8dA6c935E2Ca0;

    address public constant iporOracleProxy = 0x421C69EAa54646294Db30026aeE80D01988a6876;

    address public constant ammStorageProxyDai = 0xb99f2a02c0851efdD417bd6935d2eFcd23c56e61;
    address public constant ammStorageProxyUsdc = 0xB3d1c1aB4D30800162da40eb18B3024154924ba5;
    address public constant ammStorageProxyUsdt = 0x364f116352EB95033D73822bA81257B8c1f5B1CE;

    address public constant ammTreasuryDai = 0xEd7d74AA7eB1f12F83dA36DFaC1de2257b4e7523;
    address public constant ammTreasuryUsdc = 0x137000352B4ed784e8fa8815d225c713AB2e7Dc9;
    address public constant ammTreasuryUsdt = 0x28BC58e600eF718B9E97d294098abecb8c96b687;

    address public constant josephProxyDai = 0x086d4daab14741b195deE65aFF050ba184B65045;
    address public constant josephProxyUsdc = 0xC52569b5A349A7055E9192dBdd271F1Bd8133277;
    address public constant josephProxyUsdt = 0x33C5A44fd6E76Fc2b50a9187CfeaC336A74324AC;

    address public constant stanleyProxyDai = 0xA6aC8B6AF789319A1Db994E25760Eb86F796e2B0;
    address public constant stanleyProxyUsdc = 0x7aa7b0B738C2570C2f9F892cB7cA5bB89b9BF260;
    address public constant stanleyProxyUsdt = 0x8e679C1d67Af0CD4b314896856f09ece9E64D6B5;

    address public constant strategyAaveProxyUsdt = 0x58703DA5295794ed4E82323fcce7371272c5127D;
    address public constant strategyAaveProxyUsdc = 0x77fCaE921e3df22810c5a1aC1D33f2586BbA028f;
    address public constant strategyAaveProxyDai = 0x526d0047725D48BBc6e24C7B82A3e47C1AF1f62f;

    address public constant strategyCompoundProxyUsdt = 0xE4cD9AA68Be5b5276573E24FA7A0007da29aB5B1;
    address public constant strategyCompoundProxyUsdc = 0xe5257cf3Bd0eFD397227981fe7bbd55c7582f526;
    address public constant strategyCompoundProxyDai = 0x87CEF19aCa214d12082E201e6130432Df39fc774;

    address public constant strategyDsrProxyDai = 0xc26be51E50a358eC6d366147d78Ab94E9597239C;

    address public constant oracleUpdater = 0xC3A53976E9855d815A08f577C2BEef2a799470b7;

    address public constant AAVE = 0x7Fc66500c84A76Ad7e9c93437bFc5Ac33E2DDaE9;
    address public constant stakedAAVE = 0x4da27a545c0c5B758a6BA100e3a049001de870f5;
    address public constant aaveLendingPoolAddressProvider = 0xB53C1a33016B2DC2fF3653530bfF1848a515c8c5;
    address public constant aaveIncentivesController = 0xd784927Ff2f95ba542BfC824c8a8a98F3495f6b5;

    address public constant COMP = 0xc00e94Cb662C3520282E6f5717214004A7f26888;
    address public constant comptroller = 0x3d9819210A31b4961b30EF54bE2aeD79B9c9Cd3B;

    address payable public iporProtocolRouterProxy = payable(0x16d104009964e694761C0bf09d7Be49B7E3C26fd);
    address public ammSwapsLens = 0x41e34756a7772A4ca1115AFbE2e2aFbd1B0172CF;
    address public ammPoolsLens = 0xb653ED2bBd28DF9dde734FBe85f9312151940D01;
    address public assetManagementLens = 0xB8dbDecBaF552e765619B2677f724a8415192389;

    address public spread28Days = 0xb8d531ea16CAF1CF7B7cBC333E8963dB59E8dAD5;
    address public spread60Days = 0x36618cE1615305f3b99eeB9dF8d4272E729A81aB;
    address public spread90Days = 0x22C1CF8FCDE74A373791863953B8C9aB417795D5;
    address public spreadStorageLens = 0xB50c618d63806Ec1594547ECDB3E97737d6C12C6;
    address public spreadRouter = 0xAc1C86CEacf03d5AFC8b08A22fc38Ec7c72338ed;

    address public ammPoolsService = 0x9bcde34F504A1a9BC3496Ba9f1AEA4c5FC400517;
    address public ammGovernanceService = 0x8Ec9AEF0241A19Ffb278b3963d0EaaE7De52158d;

    address public strategyDsrDaiProxy = 0xc26be51E50a358eC6d366147d78Ab94E9597239C;
    address public strategyAaveDaiProxy = 0x526d0047725D48BBc6e24C7B82A3e47C1AF1f62f;
    address public strategyAaveUsdtProxy = 0x58703DA5295794ed4E82323fcce7371272c5127D;
    address public strategyCompoundDaiProxy = 0x87CEF19aCa214d12082E201e6130432Df39fc774;
    address public strategyCompoundUsdtProxy = 0xE4cD9AA68Be5b5276573E24FA7A0007da29aB5B1;

    // new Implementations
    address public spreadCloseSwapService = 0x948548414A364C7D6f379ED73aeDDb3C795Dcacd;
    address public ammOpenSwapService = 0x78034b17f80c6209400B26AB7B217C31F87AE119;
    address public ammCloseSwapService = 0x6650DE6837839DFCb05D188C50b927b008825ee3;

    address public ammTreasuryProxyStEth = 0x63395EDAF74a80aa1155dB7Cd9BBA976a88DeE4E;

    uint256 public messageSignerPrivateKey;
    address public messageSignerAddress;

    address public ammStorageProxyStEth;
    address public ammOpenSwapServiceStEth;
    address public ammCloseSwapServiceStEth;

    address public newSpread28Days;
    address public newSpread60Days;
    address public newSpread90Days;
    address public newSpreadCloseSwapService;

    address public spreadProxyStEth;

    function _init() internal {
        messageSignerPrivateKey = 0x12341234;
        messageSignerAddress = vm.addr(messageSignerPrivateKey);

        _createAmmStorageStEth();

        _createAmmSwapsLens();
        _createAmmOpenSwapService();
        _createAmmCloseSwapService();

        _upgradeAmmTreasuryStEth();

        _createNewSpreadForStEth();
        _createAmmOpenSwapServiceStEth();
        _createAmmCloseSwapServiceStEth();

        //        _upgradeSpreadRouter();
        _setupIporOracleStEth();
        _updateIporRouterImplementation();
    }

    function _setupUser(address user, uint256 value) internal {
        deal(user, 1_000_000e18);
        vm.startPrank(user);

        IStETH(stETH).submit{value: value}(address(0));
        IStETH(stETH).approve(iporProtocolRouterProxy, type(uint256).max);

        IWETH9(wETH).deposit{value: value}();
        IWETH9(wETH).approve(iporProtocolRouterProxy, type(uint256).max);

        IStETH(stETH).submit{value: value}(address(0));

        IWETH9(stETH).approve(wstETH, type(uint256).max);
        IwstEth(wstETH).wrap(value);

        IWETH9(wstETH).approve(iporProtocolRouterProxy, type(uint256).max);

        vm.stopPrank();
    }

    function _updateIporRouterImplementation() internal {
        IporProtocolRouter newImplementation = new IporProtocolRouter(
            IporProtocolRouter.DeployedContracts(
                ammSwapsLens,
                ammPoolsLens,
                assetManagementLens,
                ammOpenSwapService,
                ammOpenSwapServiceStEth,
                ammCloseSwapService,
                ammCloseSwapServiceStEth,
                ammPoolsService,
                ammGovernanceService,
                _getUserAddress(123),
                _getUserAddress(123),
                _getUserAddress(123),
                _getUserAddress(123),
                _getUserAddress(123),
                _getUserAddress(123)
            )
        );
        vm.prank(owner);
        IporProtocolRouter(iporProtocolRouterProxy).upgradeTo(address(newImplementation));
    }

    function _getUserAddress(uint256 number) internal returns (address) {
        return vm.rememberKey(number);
    }

    function _createNewStrategyDsrDai() internal {
        StrategyDsrDai strategyDsrDaiImpl = new StrategyDsrDai(DAI, sDai, stanleyProxyDai);

        vm.startPrank(owner);
        ERC1967Proxy proxy = new ERC1967Proxy(address(strategyDsrDaiImpl), abi.encodeWithSignature("initialize()"));
        vm.stopPrank();

        strategyDsrDaiProxy = address(proxy);
    }

    function _createNewStrategyAaveDai() internal {
        StrategyAave strategyAaveImpl = new StrategyAave(
            DAI,
            18,
            aDAI,
            stanleyProxyDai,
            AAVE,
            stakedAAVE,
            aaveLendingPoolAddressProvider,
            aaveIncentivesController
        );

        vm.startPrank(owner);
        ERC1967Proxy proxy = new ERC1967Proxy(address(strategyAaveImpl), abi.encodeWithSignature("initialize()"));
        vm.stopPrank();

        strategyAaveDaiProxy = address(proxy);
    }

    function _createNewStrategyAaveUsdt() internal {
        StrategyAave strategyAaveImpl = new StrategyAave(
            USDT,
            6,
            aUSDT,
            stanleyProxyUsdt,
            AAVE,
            stakedAAVE,
            aaveLendingPoolAddressProvider,
            aaveIncentivesController
        );

        vm.startPrank(owner);
        ERC1967Proxy proxy = new ERC1967Proxy(address(strategyAaveImpl), abi.encodeWithSignature("initialize()"));
        vm.stopPrank();

        strategyAaveUsdtProxy = address(proxy);
    }

    function _createNewStrategyCompoundDai() internal {
        StrategyCompound strategyCompoundImpl = new StrategyCompound(
            DAI,
            18,
            cDAI,
            stanleyProxyDai,
            7200,
            comptroller,
            COMP
        );

        vm.startPrank(owner);
        ERC1967Proxy proxy = new ERC1967Proxy(address(strategyCompoundImpl), abi.encodeWithSignature("initialize()"));
        vm.stopPrank();

        strategyCompoundDaiProxy = address(proxy);
    }

    function _createNewStrategyCompoundUsdt() internal {
        StrategyCompound strategyCompoundImpl = new StrategyCompound(
            USDT,
            6,
            cUSDT,
            stanleyProxyUsdt,
            7200,
            comptroller,
            COMP
        );

        vm.startPrank(owner);
        ERC1967Proxy proxy = new ERC1967Proxy(address(strategyCompoundImpl), abi.encodeWithSignature("initialize()"));
        vm.stopPrank();

        strategyCompoundUsdtProxy = address(proxy);
    }

    function _upgradeSpreadRouter() internal {
        newSpread28Days = address(new Spread28Days(DAI, USDC, USDT));
        newSpread60Days = address(new Spread60Days(DAI, USDC, USDT));
        newSpread90Days = address(new Spread90Days(DAI, USDC, USDT));
        newSpreadCloseSwapService = address(new SpreadCloseSwapService(DAI, USDC, USDT));

        SpreadRouter newImplementation = new SpreadRouter(
            SpreadRouter.DeployedContracts(
                iporProtocolRouterProxy,
                newSpread28Days,
                newSpread60Days,
                newSpread90Days,
                spreadStorageLens,
                newSpreadCloseSwapService
            )
        );

        vm.prank(owner);
        SpreadRouter(spreadRouter).upgradeTo(address(newImplementation));
    }

    function _createAmmSwapsLens() private {
        IAmmSwapsLens.SwapLensPoolConfiguration memory daiConfig = IAmmSwapsLens.SwapLensPoolConfiguration(
            DAI,
            ammStorageProxyDai,
            ammTreasuryDai
        );
        IAmmSwapsLens.SwapLensPoolConfiguration memory usdcConfig = IAmmSwapsLens.SwapLensPoolConfiguration(
            USDC,
            ammStorageProxyUsdc,
            ammTreasuryUsdc
        );
        IAmmSwapsLens.SwapLensPoolConfiguration memory usdtConfig = IAmmSwapsLens.SwapLensPoolConfiguration(
            USDT,
            ammStorageProxyUsdt,
            ammTreasuryUsdt
        );

        IAmmSwapsLens.SwapLensPoolConfiguration memory stEthConfig = IAmmSwapsLens.SwapLensPoolConfiguration(
            stETH,
            ammStorageProxyStEth,
            ammTreasuryProxyStEth
        );

        ammSwapsLens = address(
            new AmmSwapsLens(
                usdtConfig,
                usdcConfig,
                daiConfig,
                stEthConfig,
                iporOracleProxy,
                messageSignerAddress,
                spreadRouter
            )
        );
    }

    function _upgradeAmmTreasuryStEth() private {
        AmmTreasuryEth newImplementation = new AmmTreasuryEth(stETH, iporProtocolRouterProxy);

        vm.prank(owner);
        AmmTreasuryEth(ammTreasuryProxyStEth).upgradeTo(address(newImplementation));
    }

    function _createAmmStorageStEth() private {
        AmmStorageGenOne ammStorageImpl = new AmmStorageGenOne(stETH, iporProtocolRouterProxy, ammTreasuryProxyStEth);

        vm.startPrank(owner);
        ERC1967Proxy proxy = new ERC1967Proxy(address(ammStorageImpl), abi.encodeWithSignature("initialize()"));
        vm.stopPrank();

        ammStorageProxyStEth = address(proxy);
    }

    function _createAmmOpenSwapServiceStEth() private {
        AmmTypesGenOne.AmmOpenSwapServicePoolConfiguration memory cfg = AmmTypesGenOne
            .AmmOpenSwapServicePoolConfiguration({
                asset: stETH,
                decimals: 18,
                ammStorage: ammStorageProxyStEth,
                ammTreasury: ammTreasuryProxyStEth,
                iporPublicationFee: 10 * 1e15,
                maxSwapCollateralAmount: 100_000 * 1e18,
                wadLiquidationDepositAmount: 25,
                minLeverage: 10 * 1e18,
                openingFeeRate: 5e14,
                openingFeeTreasuryPortionRate: 5e17
            });

        ammOpenSwapServiceStEth = address(
            new AmmOpenSwapServiceStEth(
                cfg,
                iporOracleProxy,
                messageSignerAddress,
                spreadProxyStEth,
                iporProtocolRouterProxy,
                wETH,
                wstETH
            )
        );
    }

    function _createAmmOpenSwapService() private {
        IAmmOpenSwapLens.AmmOpenSwapServicePoolConfiguration memory daiConfig = IAmmOpenSwapLens
            .AmmOpenSwapServicePoolConfiguration(
                DAI,
                18,
                ammStorageProxyDai,
                ammTreasuryDai,
                10 * 1e18,
                100_000 * 1e18,
                25,
                10 * 1e18,
                5e14,
                5e17
            );

        IAmmOpenSwapLens.AmmOpenSwapServicePoolConfiguration memory usdcConfig = IAmmOpenSwapLens
            .AmmOpenSwapServicePoolConfiguration(
                USDC,
                6,
                ammStorageProxyUsdc,
                ammTreasuryUsdc,
                10 * 1e18,
                100_000 * 1e18,
                25,
                10 * 1e18,
                5e11,
                5e14
            );

        IAmmOpenSwapLens.AmmOpenSwapServicePoolConfiguration memory usdtConfig = IAmmOpenSwapLens
            .AmmOpenSwapServicePoolConfiguration(
                USDT,
                6,
                ammStorageProxyUsdt,
                ammTreasuryUsdt,
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
                messageSignerAddress,
                spreadRouter
            )
        );
    }

    function _createAmmCloseSwapService() private {
        IAmmCloseSwapLens.AmmCloseSwapServicePoolConfiguration memory daiConfig = IAmmCloseSwapLens
            .AmmCloseSwapServicePoolConfiguration(
                DAI,
                18,
                ammStorageProxyDai,
                ammTreasuryDai,
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

        IAmmCloseSwapLens.AmmCloseSwapServicePoolConfiguration memory usdcConfig = IAmmCloseSwapLens
            .AmmCloseSwapServicePoolConfiguration(
                USDC,
                6,
                ammStorageProxyUsdc,
                ammTreasuryUsdc,
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

        IAmmCloseSwapLens.AmmCloseSwapServicePoolConfiguration memory usdtConfig = IAmmCloseSwapLens
            .AmmCloseSwapServicePoolConfiguration(
                USDT,
                6,
                ammStorageProxyUsdt,
                ammTreasuryUsdt,
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
                messageSignerAddress,
                spreadRouter
            )
        );
    }

    function _createAmmCloseSwapServiceStEth() private {
        AmmTypesGenOne.AmmCloseSwapServicePoolConfiguration memory stEthConfig = AmmTypesGenOne
            .AmmCloseSwapServicePoolConfiguration({
                spread: spreadProxyStEth,
                asset: stETH,
                decimals: 18,
                ammStorage: ammStorageProxyStEth,
                ammTreasury: ammTreasuryProxyStEth,
                assetManagement: address(0),
                unwindingFeeRate: 5e11,
                unwindingFeeTreasuryPortionRate: 5e11,
                maxLengthOfLiquidatedSwapsPerLeg: 10,
                timeBeforeMaturityAllowedToCloseSwapByCommunity: 1 hours,
                timeBeforeMaturityAllowedToCloseSwapByBuyer: 1 days,
                minLiquidationThresholdToCloseBeforeMaturityByCommunity: 995 * 1e15,
                minLiquidationThresholdToCloseBeforeMaturityByBuyer: 99 * 1e16,
                minLeverage: 10 * 1e18
            });

        ammCloseSwapServiceStEth = address(
            new AmmCloseSwapServiceStEth(stEthConfig, iporOracleProxy, messageSignerAddress, spreadProxyStEth)
        );
    }

    function _createNewSpreadForStEth() private {
        SpreadGenOne spreadImpl = new SpreadGenOne(iporProtocolRouterProxy, stETH);

        vm.startPrank(owner);
        ERC1967Proxy proxy = new ERC1967Proxy(address(spreadImpl), abi.encodeWithSignature("initialize()"));
        vm.stopPrank();

        spreadProxyStEth = address(proxy);
    }

    function _setupIporOracleStEth() private {
        IporOracle iporOracle = IporOracle(iporOracleProxy);
        vm.startPrank(owner);
        iporOracle.addAsset(stETH, block.timestamp);
        vm.stopPrank();
    }

    function signRiskParams(
        AmmTypes.RiskIndicatorsInputs memory riskParamsInput,
        address asset,
        uint256 tenor,
        uint256 direction,
        uint256 privateKey
    ) internal view returns (bytes memory) {
        // create digest: keccak256 gives us the first 32bytes after doing the hash
        // so this is always 32 bytes.
        bytes32 digest = keccak256(
            abi.encodePacked(
                riskParamsInput.maxCollateralRatio,
                riskParamsInput.maxCollateralRatioPerLeg,
                riskParamsInput.maxLeveragePerLeg,
                riskParamsInput.baseSpreadPerLeg,
                riskParamsInput.fixedRateCapPerLeg,
                riskParamsInput.demandSpreadFactor,
                riskParamsInput.expiration,
                asset,
                tenor,
                direction
            )
        );
        // r and s are the outputs of the ECDSA signature
        // r,s and v are packed into the signature. It should be 65 bytes: 32 + 32 + 1
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(privateKey, digest);

        // pack v, r, s into 65bytes signature
        // bytes memory signature = abi.encodePacked(r, s, v);
        return abi.encodePacked(r, s, v);
    }
}

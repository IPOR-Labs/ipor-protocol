// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.20;

import "forge-std/Test.sol";
import "forge-std/console2.sol";
import "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import "../../contracts/oracles/IporOracle.sol";
import "../mocks/EmptyRouterImplementation.sol";
import "../../contracts/chains/ethereum/router/IporProtocolRouter.sol";
import "../../contracts/interfaces/IAmmSwapsLens.sol";
import "../../contracts/interfaces/IAmmOpenSwapLens.sol";
import "../../contracts/interfaces/IAmmCloseSwapLens.sol";
import "../../contracts/chains/ethereum/amm-commons/AmmSwapsLens.sol";
import "../../contracts/amm/AmmPoolsLens.sol";
import "../../contracts/amm-eth/AmmPoolsLensStEth.sol";
import "../../contracts/amm/AssetManagementLens.sol";
import "../../contracts/amm/spread/Spread28Days.sol";
import "../../contracts/amm/spread/Spread60Days.sol";
import "../../contracts/amm/spread/Spread90Days.sol";
import "../../contracts/amm/spread/SpreadCloseSwapService.sol";
import "../../contracts/amm/spread/SpreadStorageLens.sol";
import "../../contracts/amm/spread/SpreadRouter.sol";
import "../../contracts/amm/AmmOpenSwapService.sol";
import "../../contracts/amm-eth/AmmOpenSwapServiceStEth.sol";
import "../../contracts/amm/AmmCloseSwapServiceUsdt.sol";
import "../../contracts/amm/AmmCloseSwapServiceUsdc.sol";
import "../../contracts/amm/AmmCloseSwapServiceDai.sol";
import "../../contracts/amm-eth/AmmCloseSwapServiceStEth.sol";
import "../../contracts/chains/ethereum/amm-commons/AmmCloseSwapLens.sol";
import "../../contracts/amm/AmmPoolsService.sol";
import "../../contracts/chains/ethereum/amm-commons/AmmGovernanceService.sol";
import "../../contracts/amm/AmmStorage.sol";
import "../../contracts/amm/AmmTreasury.sol";

import "../../contracts/amm-eth/AmmPoolsServiceStEth.sol";
import "../../contracts/vault/strategies/StrategyDsrDai.sol";
import "../../contracts/vault/AssetManagementDai.sol";
import "../../contracts/vault/AssetManagementUsdt.sol";
import "../../contracts/vault/AssetManagementUsdc.sol";
import "../../contracts/vault/strategies/StrategyAave.sol";
import "../../contracts/vault/strategies/StrategyCompound.sol";
import "../../contracts/interfaces/IIpTokenV1.sol";
import "../../contracts/amm-eth/interfaces/IWETH9.sol";
import "../../contracts/amm-eth/interfaces/IStETH.sol";
import "../../contracts/base/amm/AmmStorageBaseV1.sol";
import "../../contracts/base/amm/AmmTreasuryBaseV1.sol";
import "../../contracts/base/spread/SpreadBaseV1.sol";
import "../../contracts/amm/spread/SpreadStorageService.sol";

contract ArbitrumTestForkCommons is Test {
    address public constant owner = 0xD92E9F039E4189c342b4067CC61f5d063960D248;
    address public treasurer = _getUserAddress(555);

    address public constant IPOR = 0x1e4746dC744503b53b4A082cB3607B169a289090;

    address public constant DAI = 0x6B175474E89094C44Da98b954EedeAC495271d0F;
    address public constant USDC = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;
    address public constant USDT = 0xdAC17F958D2ee523a2206206994597C13D831ec7;

    address public constant ipwstETH = 0xc40431b6C510AeB45Fbb5e21E40D49F12b0c1F0c;

    address public constant wstETH = 0x7f39C581F595B53c5cb19bD0b3f8dA6c935E2Ca0;

    uint256 public messageSignerPrivateKey;
    address public messageSignerAddress;

    address public ammStorageProxyWstEth;
    address public ammOpenSwapServiceWstEth;
    address public ammCloseSwapServiceWstEth;
    address public ammPoolsLensWstEth;
    address public ammPoolsServiceWstEth;

    address public newAmmGovernanceService;

    address public spreadWstEth;

    function _init() internal {
        messageSignerPrivateKey = 0x12341234;
        messageSignerAddress = vm.addr(messageSignerPrivateKey);

        _createAmmStorageStEth();
        _createNewSpreadForStEth();

        _createAmmSwapsLens();
        _createAmmOpenSwapService();
        _createAmmCloseSwapService();

        _upgradeAmmTreasuryStEth();

        _createAmmOpenSwapServiceStEth();
        _createAmmCloseSwapServiceStEth();
        _createNewAmmPoolsServiceStEth();
        _createAmmPoolsLensStEth();

        _createAmmCloseSwapLens();

        _createNewAmmGovernanceService();
        _createIporOracle();

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
                newAmmCloseSwapServiceUsdt,
                newAmmCloseSwapServiceUsdc,
                newAmmCloseSwapServiceDai,
                ammCloseSwapServiceStEth,
                newAmmCloseSwapLens,
                ammPoolsService,
                newAmmGovernanceService,
                _getUserAddress(123),
                _getUserAddress(123),
                _getUserAddress(123),
                _getUserAddress(123),
                ammPoolsServiceStEth,
                ammPoolsLensStEth
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
        newSpreadStorageService = address(new SpreadStorageService());

        SpreadRouter newImplementation = new SpreadRouter(
            SpreadRouter.DeployedContracts(
                iporProtocolRouterProxy,
                newSpread28Days,
                newSpread60Days,
                newSpread90Days,
                spreadStorageLens,
                newSpreadCloseSwapService,
                newSpreadStorageService
            )
        );

        vm.prank(owner);
        SpreadRouter(spreadRouter).upgradeTo(address(newImplementation));
    }

    function _createAmmSwapsLens() private {
        IAmmSwapsLens.SwapLensPoolConfiguration memory daiConfig = IAmmSwapsLens.SwapLensPoolConfiguration(
            DAI,
            ammStorageProxyDai,
            ammTreasuryDai,
            spreadRouter
        );
        IAmmSwapsLens.SwapLensPoolConfiguration memory usdcConfig = IAmmSwapsLens.SwapLensPoolConfiguration(
            USDC,
            ammStorageProxyUsdc,
            ammTreasuryUsdc,
            spreadRouter
        );
        IAmmSwapsLens.SwapLensPoolConfiguration memory usdtConfig = IAmmSwapsLens.SwapLensPoolConfiguration(
            USDT,
            ammStorageProxyUsdt,
            ammTreasuryUsdt,
            spreadRouter
        );

        IAmmSwapsLens.SwapLensPoolConfiguration memory stEthConfig = IAmmSwapsLens.SwapLensPoolConfiguration(
            stETH,
            ammStorageProxyStEth,
            ammTreasuryProxyStEth,
            spreadStEth
        );

        ammSwapsLens = address(
            new AmmSwapsLens(usdtConfig, usdcConfig, daiConfig, stEthConfig, iporOracleProxy, messageSignerAddress)
        );
    }

    function _createAmmPoolsLensStEth() private {
        ammPoolsLensStEth = address(
            new AmmPoolsLensStEth(stETH, ipstETH, ammTreasuryProxyStEth, ammStorageProxyStEth, iporOracleProxy)
        );
    }

    function _createNewAmmPoolsServiceStEth() private {
        ammPoolsServiceStEth = address(
            new AmmPoolsServiceStEth(
                stETH,
                wETH,
                ipstETH,
                ammTreasuryProxyStEth,
                ammStorageProxyStEth,
                iporOracleProxy,
                iporProtocolRouterProxy,
                5000000000000000
            )
        );
    }

    function _createNewAmmPoolsServiceStEthWithZEROFee() internal {
        ammPoolsServiceStEth = address(
            new AmmPoolsServiceStEth(
                stETH,
                wETH,
                ipstETH,
                ammTreasuryProxyStEth,
                ammStorageProxyStEth,
                iporOracleProxy,
                iporProtocolRouterProxy,
                0
            )
        );
    }

    function _createNewAmmGovernanceService() private {
        IAmmGovernanceLens.AmmGovernancePoolConfiguration memory usdtPoolCfg = IAmmGovernanceLens
            .AmmGovernancePoolConfiguration({
                asset: USDT,
                decimals: 6,
                ammStorage: ammStorageProxyUsdt,
                ammTreasury: ammTreasuryUsdt,
                ammPoolsTreasury: treasurer,
                ammPoolsTreasuryManager: treasurer,
                ammCharlieTreasury: treasurer,
                ammCharlieTreasuryManager: treasurer
            });
        IAmmGovernanceLens.AmmGovernancePoolConfiguration memory usdcPoolCfg = IAmmGovernanceLens
            .AmmGovernancePoolConfiguration({
                asset: USDC,
                decimals: 6,
                ammStorage: ammStorageProxyUsdc,
                ammTreasury: ammTreasuryUsdc,
                ammPoolsTreasury: treasurer,
                ammPoolsTreasuryManager: treasurer,
                ammCharlieTreasury: treasurer,
                ammCharlieTreasuryManager: treasurer
            });
        IAmmGovernanceLens.AmmGovernancePoolConfiguration memory daiPoolCfg = IAmmGovernanceLens
            .AmmGovernancePoolConfiguration({
                asset: DAI,
                decimals: 18,
                ammStorage: ammStorageProxyDai,
                ammTreasury: ammTreasuryDai,
                ammPoolsTreasury: treasurer,
                ammPoolsTreasuryManager: treasurer,
                ammCharlieTreasury: treasurer,
                ammCharlieTreasuryManager: treasurer
            });

        IAmmGovernanceLens.AmmGovernancePoolConfiguration memory stEthPoolCfg = IAmmGovernanceLens
            .AmmGovernancePoolConfiguration({
                asset: stETH,
                decimals: 18,
                ammStorage: ammStorageProxyStEth,
                ammTreasury: ammTreasuryProxyStEth,
                ammPoolsTreasury: treasurer,
                ammPoolsTreasuryManager: treasurer,
                ammCharlieTreasury: treasurer,
                ammCharlieTreasuryManager: treasurer
            });

        newAmmGovernanceService = address(new AmmGovernanceService(usdtPoolCfg, usdcPoolCfg, daiPoolCfg, stEthPoolCfg));
    }

    function _upgradeAmmTreasuryStEth() private {
        AmmTreasuryBaseV1 newImplementation = new AmmTreasuryBaseV1(
            stETH,
            iporProtocolRouterProxy,
            ammStorageProxyStEth
        );

        vm.prank(owner);
        AmmTreasuryBaseV1(ammTreasuryProxyStEth).upgradeTo(address(newImplementation));
    }

    function _createAmmStorageStEth() private {
        AmmStorageBaseV1 ammStorageImpl = new AmmStorageBaseV1(iporProtocolRouterProxy);

        vm.startPrank(owner);
        ERC1967Proxy proxy = new ERC1967Proxy(address(ammStorageImpl), abi.encodeWithSignature("initialize()"));
        vm.stopPrank();

        ammStorageProxyStEth = address(proxy);
    }

    function _createAmmOpenSwapServiceStEth() private {
        AmmTypesBaseV1.AmmOpenSwapServicePoolConfiguration memory cfg = AmmTypesBaseV1
            .AmmOpenSwapServicePoolConfiguration({
                asset: stETH,
                decimals: 18,
                ammStorage: ammStorageProxyStEth,
                ammTreasury: ammTreasuryProxyStEth,
                spread: spreadStEth,
                iporPublicationFee: 10 * 1e15,
                maxSwapCollateralAmount: 100_000 * 1e18,
                liquidationDepositAmount: 1000, /// @dev 0.001 ETH
                minLeverage: 10 * 1e18,
                openingFeeRate: 5e14,
                openingFeeTreasuryPortionRate: 5e17
            });

        ammOpenSwapServiceStEth = address(
            new AmmOpenSwapServiceStEth(cfg, iporOracleProxy, messageSignerAddress, wETH, wstETH)
        );
    }

    /// @dev case where liquidationDepositAmount is 0 and openingFeeRate is 0
    function _createAmmOpenSwapServiceStEthCase2() internal {
        AmmTypesBaseV1.AmmOpenSwapServicePoolConfiguration memory cfg = AmmTypesBaseV1
            .AmmOpenSwapServicePoolConfiguration({
                asset: stETH,
                decimals: 18,
                ammStorage: ammStorageProxyStEth,
                ammTreasury: ammTreasuryProxyStEth,
                spread: spreadStEth,
                iporPublicationFee: 9 * 1e15,
                maxSwapCollateralAmount: 100_000 * 1e18,
                liquidationDepositAmount: 0,
                minLeverage: 10 * 1e18,
                openingFeeRate: 0,
                openingFeeTreasuryPortionRate: 5e17
            });

        ammOpenSwapServiceStEth = address(
            new AmmOpenSwapServiceStEth(cfg, iporOracleProxy, messageSignerAddress, wETH, wstETH)
        );
    }

    /// @dev case where liquidationDepositAmount openingFeeRate is 0
    function _createAmmOpenSwapServiceStEthCase3() internal {
        AmmTypesBaseV1.AmmOpenSwapServicePoolConfiguration memory cfg = AmmTypesBaseV1
            .AmmOpenSwapServicePoolConfiguration({
                asset: stETH,
                decimals: 18,
                ammStorage: ammStorageProxyStEth,
                ammTreasury: ammTreasuryProxyStEth,
                spread: spreadStEth,
                iporPublicationFee: 9 * 1e15,
                maxSwapCollateralAmount: 100_000 * 1e18,
                liquidationDepositAmount: 1000,
                minLeverage: 10 * 1e18,
                openingFeeRate: 0,
                openingFeeTreasuryPortionRate: 5e17
            });

        ammOpenSwapServiceStEth = address(
            new AmmOpenSwapServiceStEth(cfg, iporOracleProxy, messageSignerAddress, wETH, wstETH)
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
            .AmmCloseSwapServicePoolConfiguration({
                asset: DAI,
                decimals: 18,
                ammStorage: ammStorageProxyDai,
                ammTreasury: ammTreasuryDai,
                assetManagement: stanleyProxyDai,
                spread: spreadRouter,
                unwindingFeeRate: 5e14,
                unwindingFeeTreasuryPortionRate: 5e14,
                maxLengthOfLiquidatedSwapsPerLeg: 10,
                timeBeforeMaturityAllowedToCloseSwapByCommunity: 1 hours,
                timeBeforeMaturityAllowedToCloseSwapByBuyerTenor28days: 1 days,
                timeBeforeMaturityAllowedToCloseSwapByBuyerTenor60days: 1 days,
                timeBeforeMaturityAllowedToCloseSwapByBuyerTenor90days: 1 days,
                minLiquidationThresholdToCloseBeforeMaturityByCommunity: 995 * 1e15,
                minLiquidationThresholdToCloseBeforeMaturityByBuyer: 99 * 1e16,
                minLeverage: 10 * 1e18,
                timeAfterOpenAllowedToCloseSwapWithUnwindingTenor28days: 1 days,
                timeAfterOpenAllowedToCloseSwapWithUnwindingTenor60days: 1 days,
                timeAfterOpenAllowedToCloseSwapWithUnwindingTenor90days: 1 days
            });

        IAmmCloseSwapLens.AmmCloseSwapServicePoolConfiguration memory usdcConfig = IAmmCloseSwapLens
            .AmmCloseSwapServicePoolConfiguration({
                asset: USDC,
                decimals: 6,
                ammStorage: ammStorageProxyUsdc,
                ammTreasury: ammTreasuryUsdc,
                assetManagement: stanleyProxyUsdc,
                spread: spreadRouter,
                unwindingFeeRate: 5e14,
                unwindingFeeTreasuryPortionRate: 5e14,
                maxLengthOfLiquidatedSwapsPerLeg: 10,
                timeBeforeMaturityAllowedToCloseSwapByCommunity: 1 hours,
                timeBeforeMaturityAllowedToCloseSwapByBuyerTenor28days: 1 days,
                timeBeforeMaturityAllowedToCloseSwapByBuyerTenor60days: 1 days,
                timeBeforeMaturityAllowedToCloseSwapByBuyerTenor90days: 1 days,
                minLiquidationThresholdToCloseBeforeMaturityByCommunity: 995 * 1e15,
                minLiquidationThresholdToCloseBeforeMaturityByBuyer: 99 * 1e16,
                minLeverage: 10 * 1e18,
                timeAfterOpenAllowedToCloseSwapWithUnwindingTenor28days: 1 days,
                timeAfterOpenAllowedToCloseSwapWithUnwindingTenor60days: 1 days,
                timeAfterOpenAllowedToCloseSwapWithUnwindingTenor90days: 1 days
            });

        IAmmCloseSwapLens.AmmCloseSwapServicePoolConfiguration memory usdtConfig = IAmmCloseSwapLens
            .AmmCloseSwapServicePoolConfiguration({
                asset: USDT,
                decimals: 6,
                ammStorage: ammStorageProxyUsdt,
                ammTreasury: ammTreasuryUsdt,
                assetManagement: stanleyProxyUsdt,
                spread: spreadRouter,
                unwindingFeeRate: 5e14,
                unwindingFeeTreasuryPortionRate: 5e14,
                maxLengthOfLiquidatedSwapsPerLeg: 10,
                timeBeforeMaturityAllowedToCloseSwapByCommunity: 1 hours,
                timeBeforeMaturityAllowedToCloseSwapByBuyerTenor28days: 1 days,
                timeBeforeMaturityAllowedToCloseSwapByBuyerTenor60days: 1 days,
                timeBeforeMaturityAllowedToCloseSwapByBuyerTenor90days: 1 days,
                minLiquidationThresholdToCloseBeforeMaturityByCommunity: 995 * 1e15,
                minLiquidationThresholdToCloseBeforeMaturityByBuyer: 99 * 1e16,
                minLeverage: 10 * 1e18,
                timeAfterOpenAllowedToCloseSwapWithUnwindingTenor28days: 1 days,
                timeAfterOpenAllowedToCloseSwapWithUnwindingTenor60days: 1 days,
                timeAfterOpenAllowedToCloseSwapWithUnwindingTenor90days: 1 days
            });

        newAmmCloseSwapServiceUsdt = address(
            new AmmCloseSwapServiceUsdt(usdtConfig, iporOracleProxy, messageSignerAddress)
        );

        newAmmCloseSwapServiceUsdc = address(
            new AmmCloseSwapServiceUsdc(usdcConfig, iporOracleProxy, messageSignerAddress)
        );

        newAmmCloseSwapServiceDai = address(
            new AmmCloseSwapServiceDai(daiConfig, iporOracleProxy, messageSignerAddress)
        );
    }

    function _createAmmCloseSwapLens() private {
        newAmmCloseSwapLens = address(
            new AmmCloseSwapLens({
                usdtInput: USDT,
                usdcInput: USDC,
                daiInput: DAI,
                stETHInput: stETH,
                iporOracleInput: iporOracleProxy,
                messageSignerInput: messageSignerAddress,
                spreadRouterInput: spreadRouter,
                closeSwapServiceUsdtInput: newAmmCloseSwapServiceUsdt,
                closeSwapServiceUsdcInput: newAmmCloseSwapServiceUsdc,
                closeSwapServiceDaiInput: newAmmCloseSwapServiceDai,
                closeSwapServiceStEthInput: ammCloseSwapServiceStEth
            })
        );
    }

    function _createAmmCloseSwapServiceStEth() private {
        IAmmCloseSwapLens.AmmCloseSwapServicePoolConfiguration memory stEthConfig = IAmmCloseSwapLens
            .AmmCloseSwapServicePoolConfiguration({
                asset: stETH,
                decimals: 18,
                ammStorage: ammStorageProxyStEth,
                ammTreasury: ammTreasuryProxyStEth,
                assetManagement: address(0),
                spread: spreadStEth,
                unwindingFeeRate: 5e11,
                unwindingFeeTreasuryPortionRate: 25e16,
                maxLengthOfLiquidatedSwapsPerLeg: 10,
                timeBeforeMaturityAllowedToCloseSwapByCommunity: 1 hours,
                timeBeforeMaturityAllowedToCloseSwapByBuyerTenor28days: 1 days,
                timeBeforeMaturityAllowedToCloseSwapByBuyerTenor60days: 2 days,
                timeBeforeMaturityAllowedToCloseSwapByBuyerTenor90days: 3 days,
                minLiquidationThresholdToCloseBeforeMaturityByCommunity: 995 * 1e15,
                minLiquidationThresholdToCloseBeforeMaturityByBuyer: 99 * 1e16,
                minLeverage: 10 * 1e18,
                timeAfterOpenAllowedToCloseSwapWithUnwindingTenor28days: 1 days,
                timeAfterOpenAllowedToCloseSwapWithUnwindingTenor60days: 2 days,
                timeAfterOpenAllowedToCloseSwapWithUnwindingTenor90days: 3 days
            });

        ammCloseSwapServiceStEth = address(
            new AmmCloseSwapServiceStEth(stEthConfig, iporOracleProxy, messageSignerAddress)
        );
    }

    function _createAmmCloseSwapServiceStEthUnwindCase1() internal {
        IAmmCloseSwapLens.AmmCloseSwapServicePoolConfiguration memory stEthConfig = IAmmCloseSwapLens
            .AmmCloseSwapServicePoolConfiguration({
            asset: stETH,
            decimals: 18,
            ammStorage: ammStorageProxyStEth,
            ammTreasury: ammTreasuryProxyStEth,
            assetManagement: address(0),
            spread: spreadStEth,
            unwindingFeeRate: 5e11,
            unwindingFeeTreasuryPortionRate: 25e16,
            maxLengthOfLiquidatedSwapsPerLeg: 10,
            timeBeforeMaturityAllowedToCloseSwapByCommunity: 1 hours,
            timeBeforeMaturityAllowedToCloseSwapByBuyerTenor28days: 1 days,
            timeBeforeMaturityAllowedToCloseSwapByBuyerTenor60days: 2 days,
            timeBeforeMaturityAllowedToCloseSwapByBuyerTenor90days: 3 days,
            minLiquidationThresholdToCloseBeforeMaturityByCommunity: 995 * 1e15,
            minLiquidationThresholdToCloseBeforeMaturityByBuyer: 99 * 1e16,
            minLeverage: 10 * 1e18,
            timeAfterOpenAllowedToCloseSwapWithUnwindingTenor28days: 1 days,
            timeAfterOpenAllowedToCloseSwapWithUnwindingTenor60days: 60 days,
            timeAfterOpenAllowedToCloseSwapWithUnwindingTenor90days: 90 days
        });

        ammCloseSwapServiceStEth = address(
            new AmmCloseSwapServiceStEth(stEthConfig, iporOracleProxy, messageSignerAddress)
        );
    }

    function _createNewSpreadForStEth() private {
        vm.startPrank(owner);
        SpreadBaseV1 spread = new SpreadBaseV1(
            iporProtocolRouterProxy,
            stETH,
            new SpreadTypesBaseV1.TimeWeightedNotionalMemory[](0)
        );
        vm.stopPrank();

        spreadStEth = address(spread);
    }

    function _createIporOracle() private {
        vm.startPrank(owner);
        address[] memory assets = new address[](3);
        assets[0] = address(DAI);
        assets[1] = address(USDT);
        assets[2] = address(USDC);

        address iporOracleImpl = address(
            new IporOracle(
                address(USDT),
                1042679339957585866,
                address(USDC),
                1031576042312020683,
                address(DAI),
                1030077612745992745
            )
        );
        IporOracle(iporOracleProxy).upgradeTo(iporOracleImpl);
        vm.stopPrank();
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
    ) internal pure returns (bytes memory) {
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

    function _prepareCloseSwapRiskIndicators(
        IporTypes.SwapTenor tenor
    ) internal view returns (AmmTypes.CloseSwapRiskIndicatorsInput memory closeRiskIndicatorsInputs) {
        AmmTypes.RiskIndicatorsInputs memory riskIndicatorsInputsPayFixed = AmmTypes.RiskIndicatorsInputs({
            maxCollateralRatio: 50000000000000000,
            maxCollateralRatioPerLeg: 25000000000000000,
            maxLeveragePerLeg: 1000000000000000000000,
            baseSpreadPerLeg: 3695000000000000,
            fixedRateCapPerLeg: 20000000000000000,
            demandSpreadFactor: 20,
            expiration: block.timestamp + 1000,
            signature: bytes("0x00")
        });

        AmmTypes.RiskIndicatorsInputs memory riskIndicatorsInputsReceiveFixed = AmmTypes.RiskIndicatorsInputs({
            maxCollateralRatio: 50000000000000000,
            maxCollateralRatioPerLeg: 25000000000000000,
            maxLeveragePerLeg: 1000000000000000000000,
            baseSpreadPerLeg: 3695000000000000,
            fixedRateCapPerLeg: 20000000000000000,
            demandSpreadFactor: 20,
            expiration: block.timestamp + 1000,
            signature: bytes("0x00")
        });

        riskIndicatorsInputsPayFixed.signature = signRiskParams(
            riskIndicatorsInputsPayFixed,
            address(stETH),
            uint256(tenor),
            0,
            messageSignerPrivateKey
        );
        riskIndicatorsInputsReceiveFixed.signature = signRiskParams(
            riskIndicatorsInputsReceiveFixed,
            address(stETH),
            uint256(tenor),
            1,
            messageSignerPrivateKey
        );

        closeRiskIndicatorsInputs = AmmTypes.CloseSwapRiskIndicatorsInput({
            payFixed: riskIndicatorsInputsPayFixed,
            receiveFixed: riskIndicatorsInputsReceiveFixed
        });
    }

    function _prepareCloseSwapRiskIndicatorsHighFixedRateCaps(
        IporTypes.SwapTenor tenor
    ) internal view returns (AmmTypes.CloseSwapRiskIndicatorsInput memory closeRiskIndicatorsInputs) {
        AmmTypes.RiskIndicatorsInputs memory riskIndicatorsInputsPayFixed = AmmTypes.RiskIndicatorsInputs({
            maxCollateralRatio: 50000000000000000,
            maxCollateralRatioPerLeg: 25000000000000000,
            maxLeveragePerLeg: 1000000000000000000000,
            baseSpreadPerLeg: 3695000000000000,
            fixedRateCapPerLeg: 300000000000000000, /// @dev 30%
            demandSpreadFactor: 20,
            expiration: block.timestamp + 1000,
            signature: bytes("0x00")
        });

        AmmTypes.RiskIndicatorsInputs memory riskIndicatorsInputsReceiveFixed = AmmTypes.RiskIndicatorsInputs({
            maxCollateralRatio: 50000000000000000,
            maxCollateralRatioPerLeg: 25000000000000000,
            maxLeveragePerLeg: 1000000000000000000000,
            baseSpreadPerLeg: 3695000000000000,
            fixedRateCapPerLeg: 300000000000000000, /// @dev 30%
            demandSpreadFactor: 20,
            expiration: block.timestamp + 1000,
            signature: bytes("0x00")
        });

        riskIndicatorsInputsPayFixed.signature = signRiskParams(
            riskIndicatorsInputsPayFixed,
            address(stETH),
            uint256(tenor),
            0,
            messageSignerPrivateKey
        );
        riskIndicatorsInputsReceiveFixed.signature = signRiskParams(
            riskIndicatorsInputsReceiveFixed,
            address(stETH),
            uint256(tenor),
            1,
            messageSignerPrivateKey
        );

        closeRiskIndicatorsInputs = AmmTypes.CloseSwapRiskIndicatorsInput({
            payFixed: riskIndicatorsInputsPayFixed,
            receiveFixed: riskIndicatorsInputsReceiveFixed
        });
    }

    function getIndexToUpdate(
        address asset,
        uint indexValue
    ) internal pure returns (IIporOracle.UpdateIndexParams[] memory) {
        IIporOracle.UpdateIndexParams[] memory updateIndexParams = new IIporOracle.UpdateIndexParams[](1);
        updateIndexParams[0] = IIporOracle.UpdateIndexParams({
            asset: asset,
            indexValue: indexValue,
            updateTimestamp: 0,
            quasiIbtPrice: 0
        });
        return updateIndexParams;
    }


}

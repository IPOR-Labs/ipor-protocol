// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.26;

import "forge-std/Test.sol";

import "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/ERC4626Upgradeable.sol";

import "../../../contracts/tokens/IpToken.sol";
import "../../../contracts/base/amm/AmmTreasuryBaseV1.sol";
import "../../../contracts/base/amm/AmmStorageBaseV1.sol";
import "../../../contracts/amm-usdm/AmmPoolsServiceUsdm.sol";
import "../../../contracts/amm-usdm/AmmPoolsLensUsdm.sol";
import "../../../contracts/chains/ethereum/router/IporProtocolRouter.sol";
import "../../../contracts/chains/ethereum/amm-commons/AmmGovernanceService.sol";
import "../../arbitrum/usdm/WUsdmMock.sol";

contract UsdmTestForkCommonEthereum is Test {
    address constant USDT = 0xdAC17F958D2ee523a2206206994597C13D831ec7;
    address constant USDC = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;
    address constant DAI = 0x6B175474E89094C44Da98b954EedeAC495271d0F;
    address constant weETH = 0xCd5fE23C85820F7B72D0926FC9b05b43E359b7ee;
    address constant stETH = 0xae7ab96520DE3A18E5e111B5EaAb095312D7fE84;

    address constant USDM = 0x59D9356E565Ab3A36dD77763Fc0d87fEaf85508C;
    address constant USDM_MINT_ROLE = 0x48AEB395FB0E4ff8433e9f2fa6E0579838d33B62;

    address constant IporProtocolOwner = 0xD92E9F039E4189c342b4067CC61f5d063960D248;
    address payable constant IporProtocolRouterProxy = payable(0x16d104009964e694761C0bf09d7Be49B7E3C26fd);
    address constant IporOracleProxy = 0x421C69EAa54646294Db30026aeE80D01988a6876;
    address constant AmmSwapsLens = 0x476C44E60a377C1D23877E9Dd2955C384b2DCD8c;
    address constant AmmPoolsLens = 0xb653ED2bBd28DF9dde734FBe85f9312151940D01;
    address constant AssetManagementLens = 0xB8dbDecBaF552e765619B2677f724a8415192389;
    address constant AmmOpenSwapService = 0x4EF45ECcc64E4Bb36b9C46B9AD353855A48016d1;
    address constant AmmOpenSwapServiceStEth = 0x042eC3f075C48CD644797e0af12Ba6257c59cD2c;
    address constant AmmCloseSwapServiceUsdt = 0x8FE90f739ea8e25Cf9655c8f8a5aD4f50f743Ed2;
    address constant AmmCloseSwapServiceUsdc = 0x623750823F8Cf4fa1B804723Be024D56E1673D95;
    address constant AmmCloseSwapServiceDai = 0x072467B69354FD3274123C908adBC75f9F1dD183;
    address constant AmmCloseSwapServiceStEth = 0x578BA09C35532e878764c54e879308DBF82973c2;
    address constant AmmCloseSwapLens = 0x17bF30c41606404dc4FBe0a1dbd8c6fDb994095D;
    address constant AmmPoolsService = 0x9bcde34F504A1a9BC3496Ba9f1AEA4c5FC400517;
    address constant LiquidityMiningLens = 0x769d54D25DD9da2159Fa690e67B27484eeB39e98;
    address constant PowerTokenLens = 0x5a4fc8F98CA356B7E957d18c155bc62E32D21EC3;
    address constant FlowsService = 0xD3486D81D52B52125B9fb1AE9d674645ECe665Ac;
    address constant StakeService = 0x3790383f8685b439391dC1BC56F7B3F82236f6c7;
    address constant AmmPoolsServiceEth = 0x406812AC6f106f7d53b4181d42342e2565428Be1;
    address constant AmmPoolsLensEth = 0xb0a4855134F63Bf81F3dC6DA38De8894FB24904a;
    address constant AmmPoolsServiceWeEth = 0x7b071c5A3b43B2D6624df1A649Fe78EAD2E475AC;
    address constant AmmPoolsLensWeEth = 0xB0d64c0375201911E09B0f8c4D38c5A286E165a6;

    address constant AmmStorageUsdtProxy = 0x364f116352EB95033D73822bA81257B8c1f5B1CE;
    address constant AmmTreasuryUsdtProxy = 0x28BC58e600eF718B9E97d294098abecb8c96b687;
    address constant AssetManagementUsdtProxy = 0x8e679C1d67Af0CD4b314896856f09ece9E64D6B5;

    address constant AmmStorageUsdcProxy = 0xB3d1c1aB4D30800162da40eb18B3024154924ba5;
    address constant AmmTreasuryUsdcProxy = 0x137000352B4ed784e8fa8815d225c713AB2e7Dc9;
    address constant AssetManagementUsdcProxy = 0x7aa7b0B738C2570C2f9F892cB7cA5bB89b9BF260;

    address constant AmmStorageDaiProxy = 0xb99f2a02c0851efdD417bd6935d2eFcd23c56e61;
    address constant AmmTreasuryDaiProxy = 0xEd7d74AA7eB1f12F83dA36DFaC1de2257b4e7523;
    address constant AssetManagementDaiProxy = 0xA6aC8B6AF789319A1Db994E25760Eb86F796e2B0;

    address constant AmmStorageStEthProxy = 0x08a8Ec037DF2e54194B397cd7c761631440197c6;
    address constant AmmTreasuryStEthProxy = 0x63395EDAF74a80aa1155dB7Cd9BBA976a88DeE4E;
    address constant AmmStorageWeEthProxy = 0x77Fe3a8E8d1d73Df54Ca07674Bf1bD6C5841e3b5;
    address constant AmmTreasuryWeEthProxy = 0xcC2fF2D38666723ea56c122097F6215B90d74196;

    address ipUsdm;
    address ammTreasuryUsdmProxy;
    address ammStorageUsdmProxy;

    address ammPoolsServiceUsdm;
    address ammPoolsLensUsdm;

    address ammGovernanceService;

    function _init() internal {
        vm.createSelectFork(vm.envString("ETHEREUM_PROVIDER_URL"), 19520045);

        vm.startPrank(IporProtocolOwner);
        _createIpUsdm();
        _createAmmStorageUsdm();
        _createTreasuryUsdm();
        _createAmmPoolsServiceUsdm(5 * 1e15);
        _createAmmPoolsLensUsdm();
        _createAmmGovernanceService();
        _updateIporRouterImplementation();
        _setupPools();
        vm.stopPrank();
        _provideInitialLiquidity();
    }

    function _createIpUsdm() private {
        ipUsdm = address(new IpToken("IP USDM", "ipUSDM", USDM));
        IpToken(ipUsdm).setTokenManager(IporProtocolRouterProxy);
    }

    function _createTreasuryUsdm() private {
        AmmTreasuryBaseV1 emptyImpl = new AmmTreasuryBaseV1(USDM, IporProtocolRouterProxy, ammStorageUsdmProxy);

        ammTreasuryUsdmProxy = address(
            new ERC1967Proxy(address(emptyImpl), abi.encodeWithSignature("initialize(bool)", false))
        );
    }

    function _createAmmStorageUsdm() private {
        address ammStorageUsdmImpl = address(new AmmStorageBaseV1(IporProtocolRouterProxy));

        ammStorageUsdmProxy = address(
            new ERC1967Proxy(ammStorageUsdmImpl, abi.encodeWithSignature("initialize()", ""))
        );
    }

    function _createAmmPoolsServiceUsdm(uint redeemFeeRateUsdmInput) internal {
        ammPoolsServiceUsdm = address(
            new AmmPoolsServiceUsdm(
                USDM,
                ipUsdm,
                ammTreasuryUsdmProxy,
                ammStorageUsdmProxy,
                IporOracleProxy,
                IporProtocolRouterProxy,
                redeemFeeRateUsdmInput
            )
        );
    }

    function _createAmmPoolsLensUsdm() private {
        ammPoolsLensUsdm = address(
            new AmmPoolsLensUsdm(USDM, ipUsdm, ammTreasuryUsdmProxy, ammStorageUsdmProxy, IporOracleProxy)
        );
    }

    function _createAmmGovernanceService() internal {
        ammGovernanceService = address(
            new AmmGovernanceService({
                usdtPoolCfg: IAmmGovernanceLens.AmmGovernancePoolConfiguration({
                    asset: USDT,
                    decimals: IERC20MetadataUpgradeable(USDT).decimals(),
                    ammStorage: AmmStorageUsdtProxy,
                    ammTreasury: AmmTreasuryUsdtProxy,
                ammVault: AssetManagementUsdtProxy,
                    ammPoolsTreasury: IporProtocolOwner,
                    ammPoolsTreasuryManager: IporProtocolOwner,
                    ammCharlieTreasury: IporProtocolOwner,
                    ammCharlieTreasuryManager: IporProtocolOwner
                }),
                    usdcPoolCfg: IAmmGovernanceLens.AmmGovernancePoolConfiguration({
                    asset: USDC,
                    decimals: IERC20MetadataUpgradeable(USDC).decimals(),
                    ammStorage: AmmStorageUsdcProxy,
                    ammTreasury: AmmTreasuryUsdcProxy,
                ammVault: AssetManagementUsdcProxy,
                    ammPoolsTreasury: IporProtocolOwner,
                    ammPoolsTreasuryManager: IporProtocolOwner,
                    ammCharlieTreasury: IporProtocolOwner,
                    ammCharlieTreasuryManager: IporProtocolOwner
                }),
                    daiPoolCfg: IAmmGovernanceLens.AmmGovernancePoolConfiguration({
                    asset: DAI,
                    decimals: IERC20MetadataUpgradeable(DAI).decimals(),
                    ammStorage: AmmStorageDaiProxy,
                    ammTreasury: AmmTreasuryDaiProxy,
                ammVault: AssetManagementDaiProxy,
                    ammPoolsTreasury: IporProtocolOwner,
                    ammPoolsTreasuryManager: IporProtocolOwner,
                    ammCharlieTreasury: IporProtocolOwner,
                    ammCharlieTreasuryManager: IporProtocolOwner
                }),
                    stEthPoolCfg: IAmmGovernanceLens.AmmGovernancePoolConfiguration({
                    asset: stETH,
                    decimals: IERC20MetadataUpgradeable(stETH).decimals(),
                    ammStorage: AmmStorageStEthProxy,
                    ammTreasury: AmmTreasuryStEthProxy,
                ammVault: address(0),
                    ammPoolsTreasury: IporProtocolOwner,
                    ammPoolsTreasuryManager: IporProtocolOwner,
                    ammCharlieTreasury: IporProtocolOwner,
                    ammCharlieTreasuryManager: IporProtocolOwner
                }),
                    weEthPoolCfg: IAmmGovernanceLens.AmmGovernancePoolConfiguration({
                    asset: weETH,
                    decimals: IERC20MetadataUpgradeable(weETH).decimals(),
                    ammStorage: AmmStorageWeEthProxy,
                    ammTreasury: AmmTreasuryWeEthProxy,
                ammVault: address(0),
                    ammPoolsTreasury: IporProtocolOwner,
                    ammPoolsTreasuryManager: IporProtocolOwner,
                    ammCharlieTreasury: IporProtocolOwner,
                    ammCharlieTreasuryManager: IporProtocolOwner
                }),
                    usdmPoolCfg: IAmmGovernanceLens.AmmGovernancePoolConfiguration({
                    asset: USDM,
                    decimals: IERC20MetadataUpgradeable(USDM).decimals(),
                    ammStorage: ammStorageUsdmProxy,
                    ammTreasury: ammTreasuryUsdmProxy,
                ammVault: address(0),
                    ammPoolsTreasury: IporProtocolOwner,
                    ammPoolsTreasuryManager: IporProtocolOwner,
                    ammCharlieTreasury: IporProtocolOwner,
                    ammCharlieTreasuryManager: IporProtocolOwner
                })
            })
        );
    }

    function _updateIporRouterImplementation() internal {

        IporProtocolRouter.DeployedContracts memory deployedContracts = IporProtocolRouter
            .DeployedContracts({
            ammSwapsLens: AmmSwapsLens,
            ammPoolsLens: AmmPoolsLens,
            assetManagementLens: AssetManagementLens,
            ammOpenSwapService: AmmOpenSwapService,
            ammOpenSwapServiceStEth: AmmOpenSwapServiceStEth,
            ammCloseSwapServiceUsdt: AmmCloseSwapServiceUsdt,
            ammCloseSwapServiceUsdc: AmmCloseSwapServiceUsdc,
            ammCloseSwapServiceDai: AmmCloseSwapServiceDai,
            ammCloseSwapServiceStEth: AmmCloseSwapServiceStEth,
            ammCloseSwapLens: AmmCloseSwapLens,
            ammPoolsService: AmmPoolsService,
            ammGovernanceService: ammGovernanceService,
            liquidityMiningLens: LiquidityMiningLens,
            powerTokenLens: PowerTokenLens,
            flowService: FlowsService,
            stakeService: StakeService,
            ammPoolsServiceStEth: AmmPoolsServiceEth,
            ammPoolsLensStEth: AmmPoolsLensEth,
            ammPoolsServiceWeEth: AmmPoolsServiceWeEth,
            ammPoolsLensWeEth: AmmPoolsLensWeEth,
            ammPoolsServiceUsdm: ammPoolsServiceUsdm,
            ammPoolsLensUsdm: ammPoolsLensUsdm
        });

        address iporProtocolRouterImpl = address(new IporProtocolRouter(deployedContracts));
        IporProtocolRouter(IporProtocolRouterProxy).upgradeTo(iporProtocolRouterImpl);
    }

    function _setupPools() internal {
        IAmmGovernanceService(IporProtocolRouterProxy).setAmmPoolsParams(USDM, type(uint32).max, 0, 5000);
    }

    function _setupUser(address user, uint256 value) internal {
        deal(user, 1_000_000e18);

        vm.prank(USDM_MINT_ROLE);
        IUSDM(USDM).mint(user, value);

        vm.prank(user);
        IUSDM(USDM).approve(IporProtocolRouterProxy, value);
    }

    function _getUserAddress(uint256 number) internal returns (address) {
        return vm.rememberKey(number);
    }

    function _provideInitialLiquidity() private {
        address user = _getUserAddress(1223456789);

        vm.prank(USDM_MINT_ROLE);
        IUSDM(USDM).mint(user, 1000e18);

        vm.prank(user);
        IUSDM(USDM).approve(IporProtocolRouterProxy, 10e18);

        vm.prank(user);
        IAmmPoolsServiceUsdm(IporProtocolRouterProxy).provideLiquidityUsdmToAmmPoolUsdm(user, 10e18);
    }
}

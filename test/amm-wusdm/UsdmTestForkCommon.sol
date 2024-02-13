// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.20;

import "forge-std/Test.sol";

import "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/ERC4626Upgradeable.sol";

import "../../contracts/tokens/IpToken.sol";
import "../../contracts/base/amm/AmmTreasuryBaseV1.sol";
import "../../contracts/base/amm/AmmStorageBaseV1.sol";
import "../../contracts/amm-wusdm/AmmPoolsServiceWusdm.sol";
import "../../contracts/amm-wusdm/AmmPoolsLensWusdm.sol";
import "../../contracts/chains/ethereum/router/IporProtocolRouter.sol";
import "./IUSDM.sol";

contract UsdmTestForkCommon is Test {
    address constant USDM = 0x59D9356E565Ab3A36dD77763Fc0d87fEaf85508C;
    address constant WUSDM = 0x57F5E098CaD7A3D1Eed53991D4d66C45C9AF7812;
    address constant HolderUsdm = 0xDBF5E9c5206d0dB70a90108bf936DA60221dC080;

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
    address constant AmmGovernanceService = 0xbF0a6e96Bd2C7d4DB0D19b7479c2b107ED03f4bc;
    address constant LiquidityMiningLens = 0x769d54D25DD9da2159Fa690e67B27484eeB39e98;
    address constant PowerTokenLens = 0x5a4fc8F98CA356B7E957d18c155bc62E32D21EC3;
    address constant FlowsService = 0xD3486D81D52B52125B9fb1AE9d674645ECe665Ac;
    address constant StakeService = 0x3790383f8685b439391dC1BC56F7B3F82236f6c7;
    address constant AmmPoolsServiceEth = 0x406812AC6f106f7d53b4181d42342e2565428Be1;
    address constant AmmPoolsLensEth = 0xb0a4855134F63Bf81F3dC6DA38De8894FB24904a;

    address ipWusdm;
    address ammTreasuryWusdmProxy;
    address ammStorageWusdmProxy;

    address ammPoolsServiceWusdm;
    address ammPoolsLensWusdm;

    function _init() internal {
        vm.createSelectFork(vm.envString("ETHEREUM_PROVIDER_URL"), 19132375);

        vm.startPrank(IporProtocolOwner);
        _createIpWusdm();
        _createAmmStorageWusdm();
        _createTreasuryWusdm();
        _createAmmPoolsServiceWusdm(5 * 1e15);
        _createAmmPoolsLensWusdm();
        _updateIporRouterImplementation();
        _setupPools();
        vm.stopPrank();
        _provideInitialLiquidity();
    }

    function _createIpWusdm() private {
        ipWusdm = address(new IpToken("IP USDM", "ipUSDM", WUSDM));
        IpToken(ipWusdm).setTokenManager(IporProtocolRouterProxy);
    }

    function _createTreasuryWusdm() private {
        AmmTreasuryBaseV1 emptyImpl = new AmmTreasuryBaseV1(WUSDM, IporProtocolRouterProxy, ammStorageWusdmProxy);

        ammTreasuryWusdmProxy = address(
            new ERC1967Proxy(address(emptyImpl), abi.encodeWithSignature("initialize(bool)", false))
        );
    }

    function _createAmmStorageWusdm() private {
        address ammStorageWusdmImpl = address(new AmmStorageBaseV1(IporProtocolRouterProxy));

        ammStorageWusdmProxy = address(
            new ERC1967Proxy(ammStorageWusdmImpl, abi.encodeWithSignature("initialize()", ""))
        );
    }

    function _createAmmPoolsServiceWusdm(uint redeemFeeRateWusdmInput) internal {
        ammPoolsServiceWusdm = address(
            new AmmPoolsServiceWusdm(
                WUSDM,
                ipWusdm,
                ammTreasuryWusdmProxy,
                ammStorageWusdmProxy,
                IporOracleProxy,
                IporProtocolRouterProxy,
                redeemFeeRateWusdmInput
            )
        );
    }

    function _createAmmPoolsLensWusdm() private {
        ammPoolsLensWusdm = address(
            new AmmPoolsLensWusdm(WUSDM, ipWusdm, ammTreasuryWusdmProxy, ammStorageWusdmProxy, IporOracleProxy)
        );
    }

    function _updateIporRouterImplementation() internal {
        IporProtocolRouter newImplementation = new IporProtocolRouter(
            IporProtocolRouter.DeployedContracts({
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
                ammGovernanceService: AmmGovernanceService,
                liquidityMiningLens: LiquidityMiningLens,
                powerTokenLens: PowerTokenLens,
                flowService: FlowsService,
                stakeService: StakeService,
                ammPoolsServiceStEth: AmmPoolsServiceEth,
                ammPoolsLensStEth: AmmPoolsLensEth,
                ammPoolsServiceWusdm: ammPoolsServiceWusdm,
                ammPoolsLensWusdm: ammPoolsLensWusdm
            })
        );

        IporProtocolRouter(IporProtocolRouterProxy).upgradeTo(address(newImplementation));
    }

    function _setupPools() internal {
        IAmmGovernanceService(IporProtocolRouterProxy).setAmmPoolsParams(WUSDM, type(uint32).max, 0, 5000);
    }

    function _setupUser(address user, uint256 value) internal {
        deal(user, 1_000_000e18);

        vm.prank(HolderUsdm);
        IUSDM(USDM).transfer(user, value);

        vm.prank(user);
        IUSDM(USDM).approve(WUSDM, value);

        vm.prank(user);
        ERC4626Upgradeable(WUSDM).deposit(value, user);

        vm.prank(user);
        IUSDM(WUSDM).approve(IporProtocolRouterProxy, value);
    }

    function _getUserAddress(uint256 number) internal returns (address) {
        return vm.rememberKey(number);
    }

    function _provideInitialLiquidity() private {
        vm.prank(HolderUsdm);
        IUSDM(WUSDM).approve(IporProtocolRouterProxy, 10e18);

        vm.prank(HolderUsdm);
        IUSDM(USDM).approve(WUSDM, 100e18);

        vm.prank(HolderUsdm);
        ERC4626Upgradeable(WUSDM).deposit(100e18, HolderUsdm);

        vm.prank(HolderUsdm);
        IAmmPoolsServiceWusdm(IporProtocolRouterProxy).provideLiquidityWusdmToAmmPoolWusdm(HolderUsdm, 10e18);
    }
}

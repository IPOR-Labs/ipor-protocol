// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.20;

import "forge-std/Test.sol";

import "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";

import "../../contracts/tokens/IpToken.sol";
import "../../contracts/base/amm/AmmTreasuryBaseV1.sol";
import "../../contracts/base/amm/AmmStorageBaseV1.sol";
import "../../contracts/amm-weEth/AmmPoolsServiceWeEth.sol";
import "../../contracts/amm-weEth/AmmPoolsLensWeEth.sol";
import "../../contracts/chains/ethereum/router/IporProtocolRouter.sol";

contract WeEthTestForkCommon is Test {


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

    address constant ammTreasuryUsdmProxy = IporProtocolRouterProxy;
    address constant ammStorageUsdmProxy = IporProtocolRouterProxy;

    address constant ammPoolsServiceUsdm = IporProtocolRouterProxy;
    address constant ammPoolsLensUsdm = IporProtocolRouterProxy;


    address constant eETH = 0x35fA164735182de50811E8e2E824cFb9B6118ac2;
    address constant weETH = 0xCd5fE23C85820F7B72D0926FC9b05b43E359b7ee;
    address constant wETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    address constant ETH = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;
    address constant eEthLiquidityPool = 0x308861A430be4cce5502d0A12724771Fc6DaF216;
    address constant referral = 0x558c8eb91F6fd83FC5C995572c3515E2DAF7b7e0;

    address ipWeEth;
    address ammTreasuryWeEthProxy;
    address ammStorageWeEthProxy;
    address ammPoolsLensWeEth;
    address ammPoolsServiceWeEth;


    function _init() internal {
        vm.createSelectFork(vm.envString("ETHEREUM_PROVIDER_URL"), 19132375);

        vm.startPrank(IporProtocolOwner);
        _createIpWeEth();
        _createAmmStorageWeEth();
        _createTreasuryWeEth();
        _createAmmPoolsServiceWeEth(5 * 1e15);
        _createAmmPoolsLensWeEth();
        _updateIporRouterImplementation();
        _setupPools();
        vm.stopPrank();
    }

    function _createIpWeEth() private {
        ipWeEth = address(new IpToken("IP ", "ipWeEth", weETH));
        IpToken(ipWeEth).setTokenManager(IporProtocolRouterProxy);
    }

    function _createTreasuryWeEth() private {
        AmmTreasuryBaseV1 emptyImpl = new AmmTreasuryBaseV1(weETH, IporProtocolRouterProxy, ammStorageWeEthProxy);

        ammTreasuryWeEthProxy = address(
            new ERC1967Proxy(address(emptyImpl), abi.encodeWithSignature("initialize(bool)", false))
        );
    }

    function _createAmmStorageWeEth() private {
        address ammStorageWeEthImpl = address(new AmmStorageBaseV1(IporProtocolRouterProxy));

        ammStorageWeEthProxy = address(
            new ERC1967Proxy(ammStorageWeEthImpl, abi.encodeWithSignature("initialize()", ""))
        );
    }

    function _createAmmPoolsServiceWeEth(uint redeemFeeRateWeEthInput) internal {
        ammPoolsServiceWeEth = address(
            new AmmPoolsServiceWeEth(
                AmmPoolsServiceWeEth.DeployedContracts({
                    ethInput: ETH,
                    wEthInput: wETH,
                    eEthInput: eETH,
                    weEthInput: weETH,
                    ipWeEthInput: ipWeEth,
                    ammTreasuryWeEthInput: ammTreasuryWeEthProxy,
                    ammStorageWeEthInput: ammStorageWeEthProxy,
                    iporOracleInput: IporOracleProxy,
                    iporProtocolRouterInput: IporProtocolRouterProxy,
                    redeemFeeRateWeEthInput: redeemFeeRateWeEthInput,
                    eEthLiquidityPoolInput: eEthLiquidityPool,
                    referralInput: referral
                })
            )
        );
    }

    function _createAmmPoolsLensWeEth() private {
        ammPoolsLensWeEth = address(
            new AmmPoolsLensWeEth(weETH, ipWeEth, ammTreasuryWeEthProxy, ammStorageWeEthProxy, IporOracleProxy)
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
                ammPoolsServiceUsdm: ammPoolsServiceUsdm,
                ammPoolsLensUsdm: ammPoolsLensUsdm,
                ammPoolsServiceWeEth: ammPoolsServiceWeEth,
                ammPoolsLensWeEth: ammPoolsLensWeEth
            })
        );

        IporProtocolRouter(IporProtocolRouterProxy).upgradeTo(address(newImplementation));
    }

    function _setupPools() internal {
        IAmmGovernanceService(IporProtocolRouterProxy).setAmmPoolsParams(weETH, type(uint32).max, 0, 5000);
    }

    function _setupUser(address user, uint256 value) internal {
        deal(user, 1_000_000e18);
        vm.startPrank(user);
        IWETH(wETH).deposit{value: 100_000e18}();
        IEEthLiquidityPool(eEthLiquidityPool).deposit{value: 200_000e18}(referral);
        IERC20(eETH).approve(weETH, 1_000_000e18);
        IWeEth(weETH).wrap(100_000e18);

        IWeEth(weETH).approve(IporProtocolRouterProxy, 10_000_000e18);
        IERC20(eETH).approve(IporProtocolRouterProxy, 10_000_000e18);
        IERC20(wETH).approve(IporProtocolRouterProxy, 10_000_000e18);
        vm.stopPrank();
    }

    function _getUserAddress(uint256 number) internal returns (address) {
        return vm.rememberKey(number);
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.20;

import "forge-std/Test.sol";

import "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/ERC4626Upgradeable.sol";

import "../../../contracts/tokens/IpToken.sol";
import "../../../contracts/base/amm/AmmTreasuryBaseV1.sol";
import "../../../contracts/base/amm/AmmStorageBaseV1.sol";
import "../../../contracts/amm-wusdm/AmmPoolsServiceWusdm.sol";
import "../../../contracts/amm-wusdm/AmmPoolsLensWusdm.sol";
import "../../../contracts/chains/arbitrum/router/IporProtocolRouterArbitrum.sol";
import "./WUsdmMock.sol";

contract WusdmTestForkCommonArbitrum is Test {
    address constant USDM = 0x59D9356E565Ab3A36dD77763Fc0d87fEaf85508C;
    address constant USDM_MINT_ROLE = 0x48AEB395FB0E4ff8433e9f2fa6E0579838d33B62;

    address constant IporProtocolOwner = 0xD92E9F039E4189c342b4067CC61f5d063960D248;
    address payable constant IporProtocolRouterProxy = payable(0x760Fa0aB719c4067D3A8d4727Cf07E8f3Bf118db);
    address constant IporOracleProxy = 0x70DdDE503edf4816B5991Ca5E2f9DE79e295F2D0;
    address constant AmmSwapsLens = 0x8F98636d8c70Fc8aeBfA46c7E62d63A90Fea65DD;
    address constant AmmCloseSwapLens = 0x3eAe3bb63a504D9Dae664233d5389Ab7B3201Ac6;
    address constant AmmGovernanceService = 0xD07bcA51Eb945eC2652Ad149a0046835C692cDBc;
    address constant LiquidityMiningLens = 0xaD2a3CbFa2Bd5DFe1382491414e8A28c13ff4fc7;
    address constant PowerTokenLens = 0x8C8a41f7c02D6828941ae7E8B689FC16e9630517;
    address constant FlowsService = 0xE56DC533EC51662DF5F96BD1e0e4dE8d8AC95FFC;
    address constant StakeService = 0x4cBAcB8F649483506a697e6C8ACD184cbFD5aE3F;
    address constant AmmOpenSwapServiceWstEth = 0x221A9A6A40A932816a56ABFEF1a8384dFF98d856;
    address constant AmmCloseSwapServiceWstEth = 0x32365802690Ebc1E1db767f1e16974358ec3f5eC;
    address constant AmmPoolsServiceWstEth = 0x8cD6db83D972Da3289efFb2D02a866584a719A7f;
    address constant AmmPoolsLensWstEth = 0x7Bb6CbD3C2Ffb7ef31a55f98B7b3D11416AB9954;

    address wUSDM;
    address ipWusdm;
    address ammTreasuryWusdmProxy;
    address ammStorageWusdmProxy;

    address ammPoolsServiceWusdm;
    address ammPoolsLensWusdm;

    function _init() internal {
        vm.createSelectFork(vm.envString("ARBITRUM_PROVIDER_URL"), 182272749);

        vm.startPrank(IporProtocolOwner);
        _createWUsdm();
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

    function _createWUsdm() private {
        WUsdmMock emptyImpl = new WUsdmMock();
        wUSDM = address(
            new ERC1967Proxy(
                address(emptyImpl),
                abi.encodeWithSignature("initialize(address,address)", USDM, IporProtocolOwner)
            )
        );
    }

    function _createIpWusdm() private {
        ipWusdm = address(new IpToken("IP USDM", "ipUSDM", wUSDM));
        IpToken(ipWusdm).setTokenManager(IporProtocolRouterProxy);
    }

    function _createTreasuryWusdm() private {
        AmmTreasuryBaseV1 emptyImpl = new AmmTreasuryBaseV1(wUSDM, IporProtocolRouterProxy, ammStorageWusdmProxy);

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
                wUSDM,
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
            new AmmPoolsLensWusdm(wUSDM, ipWusdm, ammTreasuryWusdmProxy, ammStorageWusdmProxy, IporOracleProxy)
        );
    }

    function _updateIporRouterImplementation() internal {
        IporProtocolRouterArbitrum.DeployedContractsArbitrum memory deployedContracts = IporProtocolRouterArbitrum
            .DeployedContractsArbitrum({
                ammSwapsLens: AmmSwapsLens,
                ammOpenSwapServiceWstEth: AmmOpenSwapServiceWstEth,
                ammCloseSwapServiceWstEth: AmmCloseSwapServiceWstEth,
                ammCloseSwapLens: AmmCloseSwapLens,
                ammGovernanceService: AmmGovernanceService,
                liquidityMiningLens: LiquidityMiningLens,
                powerTokenLens: PowerTokenLens,
                flowService: FlowsService,
                stakeService: StakeService,
                ammPoolsServiceWstEth: AmmPoolsServiceWstEth,
                ammPoolsLensWstEth: AmmPoolsLensWstEth,
                ammPoolsServiceWusdm: ammPoolsServiceWusdm,
                ammPoolsLensWusdm: ammPoolsLensWusdm
            });

        address payable iporProtocolRouterImpl = payable(address(new IporProtocolRouterArbitrum(deployedContracts)));
        IporProtocolRouterArbitrum(IporProtocolRouterProxy).upgradeTo(iporProtocolRouterImpl);
    }

    function _setupPools() internal {
        IAmmGovernanceService(IporProtocolRouterProxy).setAmmPoolsParams(wUSDM, type(uint32).max, 0, 5000);
    }

    function _setupUser(address user, uint256 value) internal {
        deal(user, 1_000_000e18);

        vm.prank(USDM_MINT_ROLE);
        IUSDM(USDM).mint(user, value);

        vm.prank(user);
        IUSDM(USDM).approve(wUSDM, value);

        vm.prank(user);
        ERC4626Upgradeable(wUSDM).deposit(value, user);

        vm.prank(user);
        IUSDM(wUSDM).approve(IporProtocolRouterProxy, value);
    }

    function _getUserAddress(uint256 number) internal returns (address) {
        return vm.rememberKey(number);
    }

    function _provideInitialLiquidity() private {
        address user = _getUserAddress(1223456789);

        vm.prank(USDM_MINT_ROLE);
        IUSDM(USDM).mint(user, 1000e18);

        vm.prank(user);
        IUSDM(wUSDM).approve(IporProtocolRouterProxy, 10e18);

        vm.prank(user);
        IUSDM(USDM).approve(wUSDM, 100e18);

        vm.prank(user);
        ERC4626Upgradeable(wUSDM).deposit(100e18, user);

        vm.prank(user);
        IAmmPoolsServiceWusdm(IporProtocolRouterProxy).provideLiquidityWusdmToAmmPoolWusdm(user, 10e18);
    }
}

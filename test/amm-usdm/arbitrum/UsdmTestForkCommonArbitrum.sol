// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.20;

import "forge-std/Test.sol";
import "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import "../../../contracts/oracles/IporOracle.sol";
import "../../../contracts/chains/arbitrum/router/IporProtocolRouterArbitrum.sol";
import "../../../contracts/interfaces/IAmmSwapsLens.sol";
import "../../../contracts/interfaces/IAmmOpenSwapLens.sol";
import "../../../contracts/interfaces/IAmmCloseSwapLens.sol";
import "../../../contracts/chains/ethereum/amm-commons/AmmSwapsLens.sol";
import "../../../contracts/amm/AmmPoolsLens.sol";
import "../../../contracts/amm-eth/AmmPoolsLensWstEth.sol";
import "../../../contracts/amm/AssetManagementLens.sol";
import "../../../contracts/amm-eth/AmmOpenSwapServiceWstEth.sol";
import "../../../contracts/amm-eth/AmmCloseSwapServiceWstEth.sol";
import "../../../contracts/amm/AmmPoolsService.sol";
import "../../../contracts/chains/arbitrum/amm-commons/AmmCloseSwapLensArbitrum.sol";
import "../../../contracts/chains/arbitrum/amm-commons/AmmGovernanceServiceArbitrum.sol";
import "../../../contracts/chains/arbitrum/amm-commons/AmmSwapsLensArbitrum.sol";

import "../../../contracts/amm-eth/AmmPoolsServiceWstEth.sol";
import "../../../contracts/base/amm/AmmStorageBaseV1.sol";
import "../../../contracts/base/amm/AmmTreasuryBaseV1.sol";
import "../../../contracts/base/spread/SpreadBaseV1.sol";

import "../../../contracts/tokens/IpToken.sol";
import "../../arbitrum/interfaces/IERC20Bridged.sol";
import "../../../contracts/amm-usdm/AmmPoolsLensUsdm.sol";
import "../../../contracts/amm-usdm/AmmPoolsServiceUsdm.sol";
import "./WUsdmMock.sol";

contract UsdmTestForkCommonArbitrum is Test {
    address internal constant WST_ETH_BRIDGE = 0x07D4692291B9E30E326fd31706f686f83f331B82;
    address constant USDM_MINT_ROLE = 0x48AEB395FB0E4ff8433e9f2fa6E0579838d33B62;

    address private _defaultAddress = 0xa0Ee7A142d267C1f36714E4a8F75612F20a79720;

    address public constant IporProtocolOwner = 0xD92E9F039E4189c342b4067CC61f5d063960D248;
    address public treasurer = _getUserAddress(555);

    address public constant IPOR = 0x34229B3f16fBCDfA8d8d9d17C0852F9496f4C7BB;

    address public constant DAI = 0xDA10009cBd5D07dd0CeCc66161FC93D7c9000da1;
    address public constant USDC = 0xaf88d065e77c8cC2239327C5EDb3A432268e5831;
    address public constant USDT = 0xFd086bC7CD5C481DCC9C85ebE478A1C0b69FCbb9;

    address public constant wstETH = 0x5979D7b546E38E414F7E9822514be443A4800529;
    address public constant USDM = 0x59D9356E565Ab3A36dD77763Fc0d87fEaf85508C;

    address public ammTreasuryWstEthImpl = 0x4B174FA825c935a656B9c6a84dEfC73F130598aD;
    address public ammTreasuryWstEthProxy = 0xBd013Ea2E01C2Ab3462dd67e9C83aa3834882A5D;
    address public ammStorageWstEthImpl = 0xDfE43014932974Bc4504a2d903Cc25D1ACb35CAC;
    address public ammStorageWstEthProxy = 0x326804339eC2a210e5f9246F4959aE50961c5C28;

    address public ammTreasuryUsdmImpl;
    address public ammTreasuryUsdmProxy;
    address public ammStorageUsdmImpl;
    address public ammStorageUsdmProxy;

    address public iporProtocolRouterImpl = 0xC9357414F910247bF3E0540ecaA8C641960Cdc03;
    address public IporProtocolRouterProxy = 0x760Fa0aB719c4067D3A8d4727Cf07E8f3Bf118db;

    address public ipwstETH = 0xbDa4b3e17a9B0ecb811E68c6f08907156CBa503C;
    address public spreadWstEth = 0x42444C388BEAC2D1685eBfaFaED1e86B9e7A1b3d;

    address public ipUsdm;

    address public ammGovernanceService = 0xD07bcA51Eb945eC2652Ad149a0046835C692cDBc;
    address public ammSwapsLens = 0x8F98636d8c70Fc8aeBfA46c7E62d63A90Fea65DD;
    address public ammPoolsLensWstEth = 0x7Bb6CbD3C2Ffb7ef31a55f98B7b3D11416AB9954;
    address public ammPoolsServiceWstEth = 0x8cD6db83D972Da3289efFb2D02a866584a719A7f;
    address public ammOpenSwapServiceWstEth = 0x221A9A6A40A932816a56ABFEF1a8384dFF98d856;
    address public ammCloseSwapServiceWstEth = 0x32365802690Ebc1E1db767f1e16974358ec3f5eC;
    address public ammCloseSwapLens = 0x3eAe3bb63a504D9Dae664233d5389Ab7B3201Ac6;

    address public ammPoolsLensUsdm;
    address public ammPoolsServiceUsdm;
    address public ammOpenSwapServiceUsdm = _defaultAddress;
    address public ammCloseSwapServiceUsdm = _defaultAddress;

    address public iporOracleImpl = 0x4d05f3d755f7996df0EF9c89Baeb328990068Ee5;
    address public iporOracleProxy = 0x70DdDE503edf4816B5991Ca5E2f9DE79e295F2D0;

    function _init() internal {
        vm.createSelectFork(vm.envString("ARBITRUM_PROVIDER_URL"), 209413278);

        vm.startPrank(IporProtocolOwner);
        _createDummyContracts();
        _createIpToken();
        _createAmmStorage();
        _upgradeAmmTreasury();
        _createGovernanceService();
        _createAmmPoolsService();
        _createAmmPoolsLens();

        _updateIporRouterImplementation();

        _setupIporProtocol();
        _setupUser(IporProtocolOwner, 1_000_000e18);

        vm.stopPrank();
        _provideInitialLiquidity();
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

    function _setupIporProtocol() internal {
        address[] memory guardians = new address[](1);

        guardians[0] = IporProtocolOwner;
        AmmTreasuryBaseV1(ammTreasuryWstEthProxy).addPauseGuardians(guardians);

        IAmmGovernanceService(IporProtocolRouterProxy).setAmmPoolsParams(wstETH, 1000000000, 0, 0);

        AmmTreasuryBaseV1(ammTreasuryUsdmProxy).addPauseGuardians(guardians);
        AmmTreasuryBaseV1(ammTreasuryUsdmProxy).unpause();

        IAmmGovernanceService(IporProtocolRouterProxy).setAmmPoolsParams(USDM, 1000000000, 0, 0);
    }

    function _createGovernanceService() internal {
        ammGovernanceService = address(
            new AmmGovernanceServiceArbitrum({
                wstEthPoolCfg: IAmmGovernanceLens.AmmGovernancePoolConfiguration({
                    asset: wstETH,
                    decimals: IERC20MetadataUpgradeable(wstETH).decimals(),
                    ammStorage: ammStorageWstEthProxy,
                    ammTreasury: ammTreasuryWstEthProxy,
                    ammPoolsTreasury: treasurer,
                    ammPoolsTreasuryManager: treasurer,
                    ammCharlieTreasury: treasurer,
                    ammCharlieTreasuryManager: treasurer
                }),
                usdmPoolCfg: IAmmGovernanceLens.AmmGovernancePoolConfiguration({
                    asset: USDM,
                    decimals: IERC20MetadataUpgradeable(USDM).decimals(),
                    ammStorage: ammStorageUsdmProxy,
                    ammTreasury: ammTreasuryUsdmProxy,
                    ammPoolsTreasury: treasurer,
                    ammPoolsTreasuryManager: treasurer,
                    ammCharlieTreasury: treasurer,
                    ammCharlieTreasuryManager: treasurer
                })
            })
        );
    }

    function _createDummyContracts() internal {
        AmmTreasuryBaseV1 emptyImpl = new AmmTreasuryBaseV1(_defaultAddress, _defaultAddress, _defaultAddress);

        ammTreasuryUsdmProxy = address(
            new ERC1967Proxy(address(emptyImpl), abi.encodeWithSignature("initialize(bool)", true))
        );
    }

    function _createIpToken() internal {
        ipUsdm = address(new IpToken("IP Usdm", "ipUsdm", USDM));
        IpToken(ipUsdm).setTokenManager(IporProtocolRouterProxy);
    }

    function _setupUser(address user, uint256 value) internal {
        deal(user, 1_000_000e18);

        vm.startPrank(user);
        IWETH9(wstETH).approve(IporProtocolRouterProxy, type(uint256).max);
        vm.stopPrank();

        vm.prank(WST_ETH_BRIDGE);
        IERC20Bridged(wstETH).bridgeMint(user, value);

        vm.prank(USDM_MINT_ROLE);
        IUSDM(USDM).mint(user, value);

        vm.prank(user);
        IUSDM(USDM).approve(IporProtocolRouterProxy, value);
    }

    function _updateIporRouterImplementation() internal {
        IporProtocolRouterArbitrum.DeployedContractsArbitrum memory deployedContracts = IporProtocolRouterArbitrum
            .DeployedContractsArbitrum({
                ammSwapsLens: ammSwapsLens,
                ammOpenSwapServiceWstEth: ammOpenSwapServiceWstEth,
                ammCloseSwapServiceWstEth: ammCloseSwapServiceWstEth,
                ammCloseSwapLens: ammCloseSwapLens,
                ammGovernanceService: ammGovernanceService,
                liquidityMiningLens: _defaultAddress,
                powerTokenLens: _defaultAddress,
                flowService: _defaultAddress,
                stakeService: _defaultAddress,
                ammPoolsServiceWstEth: ammPoolsServiceWstEth,
                ammPoolsLensWstEth: ammPoolsLensWstEth,
                ammPoolsServiceUsdm: ammPoolsServiceUsdm,
                ammPoolsLensUsdm: ammPoolsLensUsdm
            });

        iporProtocolRouterImpl = address(new IporProtocolRouterArbitrum(deployedContracts));

        IporProtocolRouterArbitrum(payable(IporProtocolRouterProxy)).upgradeTo(iporProtocolRouterImpl);
    }

    function _getUserAddress(uint256 number) internal returns (address) {
        return vm.rememberKey(number);
    }

    function _createAmmPoolsLens() private {
        ammPoolsLensWstEth = address(
            new AmmPoolsLensWstEth({
                wstEthInput: wstETH,
                ipwstEthInput: ipwstETH,
                ammTreasuryWstEthInput: ammTreasuryWstEthProxy,
                ammStorageWstEthInput: ammStorageWstEthProxy,
                iporOracleInput: iporOracleProxy
            })
        );

        ammPoolsLensUsdm = address(
            new AmmPoolsLensUsdm({
                usdmInput: USDM,
                ipUsdmInput: ipUsdm,
                ammTreasuryUsdmInput: ammTreasuryUsdmProxy,
                ammStorageUsdmInput: ammStorageUsdmProxy,
                iporOracleInput: iporOracleProxy
            })
        );
    }

    function _createAmmPoolsService() private {
        ammPoolsServiceWstEth = address(
            new AmmPoolsServiceWstEth({
                wstEthInput: wstETH,
                ipwstEthInput: ipwstETH,
                ammTreasuryWstEthInput: ammTreasuryWstEthProxy,
                ammStorageWstEthInput: ammStorageWstEthProxy,
                iporOracleInput: iporOracleProxy,
                iporProtocolRouterInput: IporProtocolRouterProxy,
                redeemFeeRateWstEthInput: 5 * 1e15
            })
        );

        ammPoolsServiceUsdm = address(
            new AmmPoolsServiceUsdm({
                usdmInput: USDM,
                ipUsdmInput: ipUsdm,
                ammTreasuryUsdmInput: ammTreasuryUsdmProxy,
                ammStorageUsdmInput: ammStorageUsdmProxy,
                iporOracleInput: iporOracleProxy,
                iporProtocolRouterInput: IporProtocolRouterProxy,
                redeemFeeRateUsdmInput: 5 * 1e15
            })
        );
    }

    function _createNewAmmPoolsServiceWstEthWithZEROFee() internal {
        ammPoolsServiceWstEth = address(
            new AmmPoolsServiceWstEth({
                wstEthInput: wstETH,
                ipwstEthInput: ipwstETH,
                ammTreasuryWstEthInput: ammTreasuryWstEthProxy,
                ammStorageWstEthInput: ammStorageWstEthProxy,
                iporOracleInput: iporOracleProxy,
                iporProtocolRouterInput: IporProtocolRouterProxy,
                redeemFeeRateWstEthInput: 0
            })
        );
    }

    function _upgradeAmmTreasury() private {
        ammTreasuryUsdmImpl = address(new AmmTreasuryBaseV1(USDM, IporProtocolRouterProxy, ammStorageUsdmProxy));
        AmmTreasuryBaseV1(ammTreasuryUsdmProxy).upgradeTo(ammTreasuryUsdmImpl);
    }

    function _createAmmStorage() private {
        ammStorageUsdmImpl = address(new AmmStorageBaseV1(IporProtocolRouterProxy));

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
                iporOracleProxy,
                IporProtocolRouterProxy,
                redeemFeeRateUsdmInput
            )
        );
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
}

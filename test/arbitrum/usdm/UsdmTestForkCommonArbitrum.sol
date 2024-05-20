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

import "../../../contracts/amm/AmmPoolsService.sol";
import "../../../contracts/chains/arbitrum/amm-commons/AmmCloseSwapLensArbitrum.sol";
import "../../../contracts/chains/arbitrum/amm-commons/AmmGovernanceServiceArbitrum.sol";
import "../../../contracts/chains/arbitrum/amm-commons/AmmSwapsLensArbitrum.sol";

import "../../../contracts/base/amm/AmmStorageBaseV1.sol";
import "../../../contracts/base/amm/AmmTreasuryBaseV1.sol";

import "../../../contracts/tokens/IpToken.sol";
import "../../arbitrum/interfaces/IERC20Bridged.sol";
import {AmmPoolsLensArbitrum} from "../../../contracts/chains/arbitrum/amm-commons/AmmPoolsLensArbitrum.sol";
import "../../../contracts/amm-usdm/AmmPoolsServiceUsdm.sol";
import "./WUsdmMock.sol";

contract UsdmTestForkCommonArbitrum is Test {
    uint256 public constant PROTOCOL_DECIMALS = 1e18;
    address public constant PROTOCOL_OWNER = 0xD92E9F039E4189c342b4067CC61f5d063960D248;
    
    address internal constant WST_ETH_BRIDGE = 0x07D4692291B9E30E326fd31706f686f83f331B82;
    address constant USDM_MINT_ROLE = 0x48AEB395FB0E4ff8433e9f2fa6E0579838d33B62;

    address private _defaultAddress = 0xa0Ee7A142d267C1f36714E4a8F75612F20a79720;

    address public treasurer = _getUserAddress(555);

    address public constant IPOR = 0x34229B3f16fBCDfA8d8d9d17C0852F9496f4C7BB;

    address public constant DAI = 0xDA10009cBd5D07dd0CeCc66161FC93D7c9000da1;
    address public constant USDC = 0xaf88d065e77c8cC2239327C5EDb3A432268e5831;
    address public constant USDT = 0xFd086bC7CD5C481DCC9C85ebE478A1C0b69FCbb9;

    address public constant wstETH = 0x5979D7b546E38E414F7E9822514be443A4800529;
    address public constant USDM = 0x59D9356E565Ab3A36dD77763Fc0d87fEaf85508C;

    address public iporOracleImpl = 0x4d05f3d755f7996df0EF9c89Baeb328990068Ee5;
    address public iporOracleProxy = 0x70DdDE503edf4816B5991Ca5E2f9DE79e295F2D0;

    address public iporProtocolRouterImpl = 0xC9357414F910247bF3E0540ecaA8C641960Cdc03;
    address public IporProtocolRouterProxy = 0x760Fa0aB719c4067D3A8d4727Cf07E8f3Bf118db;

    uint256 public messageSignerPrivateKey;
    address public messageSignerAddress;

    address public ipUsdm;
    address public ammTreasuryUsdmImpl;
    address public ammTreasuryUsdmProxy;
    address public ammStorageUsdmImpl;
    address public ammStorageUsdmProxy;

    address public ammSwapsLens;
    address public ammPoolsLens;
    address public ammCloseSwapLens;
    address public ammGovernanceService;
    
    address public ammPoolsServiceUsdm;
    address public ammOpenSwapServiceUsdm = _defaultAddress;
    address public ammCloseSwapServiceUsdm = _defaultAddress;

    
    function _init() internal {
        messageSignerPrivateKey = 0x12341234;
        messageSignerAddress = vm.addr(messageSignerPrivateKey);
        
        vm.createSelectFork(vm.envString("ARBITRUM_PROVIDER_URL"), 211080762);

        vm.startPrank(PROTOCOL_OWNER);
        
        _createDummyContracts();
        _createIpToken();
        _createAmmStorage();
        _upgradeAmmTreasury();

        _createAmmPoolsServiceUsdm();

        _createAmmPoolsLens();
        _createGovernanceService();
        _createAmmSwapsLens();
        _createAmmCloseSwapLens();

        _updateIporRouterImplementation();

        _setupIporProtocol();

        vm.stopPrank();

        _setupUser(PROTOCOL_OWNER, 1_000_000e18);
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

        guardians[0] = PROTOCOL_OWNER;

        AmmTreasuryBaseV1(ammTreasuryUsdmProxy).addPauseGuardians(guardians);
        AmmTreasuryBaseV1(ammTreasuryUsdmProxy).unpause();

        IAmmGovernanceService(IporProtocolRouterProxy).setAmmPoolsParams(USDM, 1000000000, 0, 0);

        IAmmGovernanceServiceArbitrum(IporProtocolRouterProxy).setMessageSigner(messageSignerAddress);

        IAmmGovernanceServiceArbitrum(IporProtocolRouterProxy).setAmmGovernancePoolConfiguration(USDM, StorageLibArbitrum.AssetGovernancePoolConfigValue({
            decimals: IERC20MetadataUpgradeable(USDM).decimals(),
            ammStorage: ammStorageUsdmProxy,
            ammTreasury: ammTreasuryUsdmProxy,
            ammVault: address(0),
            ammPoolsTreasury: treasurer,
            ammPoolsTreasuryManager: treasurer,
            ammCharlieTreasury: treasurer,
            ammCharlieTreasuryManager: treasurer
        }
        ));

        IAmmGovernanceServiceArbitrum(IporProtocolRouterProxy).setAssetLensData(USDM, StorageLibArbitrum.AssetLensDataValue({
            decimals: IERC20MetadataUpgradeable(USDM).decimals(),
            ipToken: ipUsdm,
            ammStorage: ammStorageUsdmProxy,
            ammTreasury: ammTreasuryUsdmProxy,
            ammVault: address(0),
            spread: address(0)
        }));

        IAmmGovernanceServiceArbitrum(IporProtocolRouterProxy).setAssetServices(USDM, StorageLibArbitrum.AssetServicesValue({
            ammPoolsService: ammPoolsServiceUsdm,
            ammOpenSwapService: ammOpenSwapServiceUsdm,
            ammCloseSwapService: ammCloseSwapServiceUsdm
        }));
    }

    function _setupAssetServices() internal {
        IAmmGovernanceServiceArbitrum(IporProtocolRouterProxy).setAssetServices(USDM, StorageLibArbitrum.AssetServicesValue({
            ammPoolsService: ammPoolsServiceUsdm,
            ammOpenSwapService: ammOpenSwapServiceUsdm,
            ammCloseSwapService: ammCloseSwapServiceUsdm
        }));
    }

    function _createGovernanceService() internal {
        ammGovernanceService = address(
            new AmmGovernanceServiceArbitrum()
        );
    }

    function _createAmmSwapsLens() private {
        ammSwapsLens = address(
            new AmmSwapsLensArbitrum(iporOracleProxy)
        );
    }

    function _createAmmCloseSwapLens() private {
        ammCloseSwapLens = address(
            new AmmCloseSwapLensArbitrum(iporOracleProxy)
        );
    }

    function _createDummyContracts() internal {
        AmmTreasuryBaseV1 emptyImpl = new AmmTreasuryBaseV1(USDM, _defaultAddress, _defaultAddress);

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

        vm.prank(USDM_MINT_ROLE);
        IUSDM(USDM).mint(user, value);

        vm.prank(user);
        IUSDM(USDM).approve(IporProtocolRouterProxy, value);
    }

    function _updateIporRouterImplementation() internal {
        IporProtocolRouterArbitrum.DeployedContractsArbitrum memory deployedContracts = IporProtocolRouterArbitrum
            .DeployedContractsArbitrum({
            ammSwapsLens: ammSwapsLens,
            ammPoolsLens: ammPoolsLens,
            ammCloseSwapLens: ammCloseSwapLens,
            ammGovernanceService: ammGovernanceService,
            liquidityMiningLens: _defaultAddress,
            powerTokenLens: _defaultAddress,
            flowService: _defaultAddress,
            stakeService: _defaultAddress,
            wstEth: wstETH,
            usdc: USDC,
            usdm: USDM
        });

        iporProtocolRouterImpl = address(new IporProtocolRouterArbitrum(deployedContracts));

        IporProtocolRouterArbitrum(payable(IporProtocolRouterProxy)).upgradeTo(iporProtocolRouterImpl);
    }

    function _getUserAddress(uint256 number) internal returns (address) {
        return vm.rememberKey(number);
    }

    function _createAmmPoolsLens() private {
        ammPoolsLens = address(
            new AmmPoolsLensArbitrum(iporOracleProxy)
        );
    }

    function _createAmmPoolsServiceUsdm() private {

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

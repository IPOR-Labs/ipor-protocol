// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.26;

import "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "forge-std/Test.sol";
import "../mocks/EmptyRouterImplementation.sol";
import "../../contracts/tokens/IpToken.sol";
import "../../contracts/amm-eth/interfaces/IStETH.sol";
import "../../contracts/amm-eth/interfaces/IWETH9.sol";
import "../../contracts/amm-eth/interfaces/IAmmPoolsServiceStEth.sol";
import "../../contracts/interfaces/IAmmGovernanceLens.sol";
import "../../contracts/interfaces/IAmmGovernanceService.sol";
import "../../contracts/chains/ethereum/router/IporProtocolRouterEthereum.sol";
import "../../contracts/base/amm/AmmStorageBaseV1.sol";
import "../../contracts/base/amm/AmmTreasuryBaseV1.sol";
import "../../contracts/base/amm/services/AmmGovernanceServiceBaseV1.sol";
import "../../contracts/base/amm/services/AmmPoolsLensBaseV1.sol";
import {IAmmGovernanceServiceBaseV1} from "../../contracts/base/interfaces/IAmmGovernanceServiceBaseV1.sol";
import {StorageLibBaseV1} from "../../contracts/base/libraries/StorageLibBaseV1.sol";
import {AmmPoolsServiceStEth} from "../../contracts/chains/ethereum/amm-stEth/AmmPoolsServiceStEth.sol";
import {MockPlasmaVault} from "../mocks/tokens/MockPlasmaVault.sol";

contract TestEthMarketCommons is Test {
    address internal defaultAnvilAddress = 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266;

    address public constant owner = 0xD92E9F039E4189c342b4067CC61f5d063960D248;
    address public constant DAI = 0x6B175474E89094C44Da98b954EedeAC495271d0F;
    address public constant USDC = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;
    address public constant USDT = 0xdAC17F958D2ee523a2206206994597C13D831ec7;
    address public constant USDM = 0x59D9356E565Ab3A36dD77763Fc0d87fEaf85508C;
    address public constant IPOR = 0x1e4746dC744503b53b4A082cB3607B169a289090;
    address public constant stEth = 0xae7ab96520DE3A18E5e111B5EaAb095312D7fE84;
    address public constant wEth = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    address public constant weETH = 0xCd5fE23C85820F7B72D0926FC9b05b43E359b7ee;
    address public constant iporOracle = 0x421C69EAa54646294Db30026aeE80D01988a6876;

    // new contracts for v2 ethMarket
    // todo: change when implement redeem
    uint256 public redeemFeeRateEth = 5e15;

    address public ipstEth;
    address payable public iporProtocolRouter;
    address public ammTreasuryStEth;
    address public ammStorageStEth;
    address public newPlasmaVaultStEth;
    address public ammGovernanceService;
    address public ammPoolsServiceStEth;
    address public ammPoolsLensStEth;
    address public ammPoolsLensBaseV1;

    // tests data
    address public userOne = address(11);
    address public userTwo = address(22);
    address public userThree = address(33);

    function _init() internal {
        _createEmptyRouterImplementation();

        _createIpstEth();
        _createDummyAmmTreasuryStEth();
        _createAmmStorageStEth();
        _createPlasmaVaults();
        _upgradeAmmTreasuryStEth();
        _createAmmPoolServiceStEth();
        _createAmmPoolsLensBaseV1();
        _createAmmGovernanceService();
        _updateIporRouterImplementation();

        _setupAmmGovernancePoolConfiguration();
        _setupAssetServices();
        _setupAssetLensData();
        _setupPools();

        _setupUser(userOne, 50_000e18);
        _setupUser(userTwo, 50_000e18);
        _setupUser(userThree, 10_000e18);
    }

    function _createPlasmaVaults() internal {
        newPlasmaVaultStEth = address(new MockPlasmaVault(IERC20(stEth), "ipstETHfusion", "ipstETHfusion"));
    }

    function _createEmptyRouterImplementation() private {
        vm.prank(owner);
        address implementation = address(new EmptyRouterImplementation());
        ERC1967Proxy proxy = _constructProxy(implementation);
        iporProtocolRouter = payable(address(proxy));
    }

    function _createIpstEth() private {
        vm.startPrank(owner);
        IpToken token = new IpToken("IP stETH", "ipstEth", stEth);
        token.setTokenManager(iporProtocolRouter);
        ipstEth = address(token);
        vm.stopPrank();
    }

    function _createDummyAmmTreasuryStEth() private {
        vm.prank(owner);
        AmmTreasuryBaseV1 impl = new AmmTreasuryBaseV1(stEth, iporProtocolRouter, defaultAnvilAddress);
        ERC1967Proxy proxy = _constructProxy(address(impl));
        ammTreasuryStEth = address(proxy);
    }

    function _createAmmStorageStEth() private {
        vm.startPrank(owner);
        AmmStorageBaseV1 impl = new AmmStorageBaseV1(iporProtocolRouter);
        ERC1967Proxy proxy = new ERC1967Proxy(address(impl), abi.encodeWithSignature("initialize()"));
        ammStorageStEth = address(proxy);
    }

    function _upgradeAmmTreasuryStEth() private {
        address impl = address(new AmmTreasuryBaseV1(stEth, iporProtocolRouter, ammStorageStEth));
        AmmTreasuryBaseV1(ammTreasuryStEth).upgradeTo(impl);
    }

    function _createAmmTreasuryStEth() private {
        vm.prank(owner);
        AmmTreasuryBaseV1 impl = new AmmTreasuryBaseV1(stEth, iporProtocolRouter, userOne);
        ERC1967Proxy proxy = _constructProxy(address(impl));
        ammTreasuryStEth = address(proxy);
    }

    function _createAmmPoolServiceStEth() private {
        vm.startPrank(owner);
        AmmPoolsServiceStEth pool = new AmmPoolsServiceStEth(
            stEth,
            wEth,
            ipstEth,
            ammTreasuryStEth,
            ammStorageStEth,
            newPlasmaVaultStEth,
            iporOracle,
            iporProtocolRouter,
            redeemFeeRateEth,
            1
        );
        ammPoolsServiceStEth = address(pool);
        vm.stopPrank();
    }

    function _createAmmPoolsLensBaseV1() private {
        vm.startPrank(owner);
        ammPoolsLensBaseV1 = address(new AmmPoolsLensBaseV1({iporOracle_: iporOracle}));
        vm.stopPrank();
    }

    function _createAmmGovernanceService() private {
        vm.startPrank(owner);
        ammGovernanceService = address(new AmmGovernanceServiceBaseV1());
        vm.stopPrank();
    }

    function _updateIporRouterImplementation() internal {
        vm.startPrank(owner);
        IporProtocolRouterEthereum newImplementation = new IporProtocolRouterEthereum(
            IporProtocolRouterEthereum.DeployedContracts({
                ammSwapsLens: _getUserAddress(123),
                ammPoolsLens: _getUserAddress(123),
                ammPoolsLensBaseV1: ammPoolsLensBaseV1,
                assetManagementLens: _getUserAddress(123),
                ammOpenSwapService: _getUserAddress(123),
                ammCloseSwapServiceUsdt: _getUserAddress(123),
                ammCloseSwapServiceUsdc: _getUserAddress(123),
                ammCloseSwapServiceDai: _getUserAddress(123),
                ammCloseSwapLens: _getUserAddress(123),
                ammPoolsService: _getUserAddress(123),
                ammGovernanceService: ammGovernanceService,
                liquidityMiningLens: _getUserAddress(123),
                powerTokenLens: _getUserAddress(123),
                flowService: _getUserAddress(123),
                stakeService: _getUserAddress(123),
                stEth: stEth,
                weEth: weETH,
                usdm: USDM
            })
        );

        IporProtocolRouterEthereum(iporProtocolRouter).upgradeTo(address(newImplementation));
        vm.stopPrank();
    }

    function _setupAmmGovernancePoolConfiguration() private {
        vm.startPrank(owner);
        // Setup pool configuration for stEth
        IAmmGovernanceServiceBaseV1(iporProtocolRouter).setAmmGovernancePoolConfiguration(
            stEth,
            StorageLibBaseV1.AssetGovernancePoolConfigValue({
                decimals: 18,
                ammStorage: ammStorageStEth,
                ammTreasury: ammTreasuryStEth,
                ammVault: address(0),
                ammPoolsTreasury: _getUserAddress(123),
                ammPoolsTreasuryManager: _getUserAddress(123),
                ammCharlieTreasury: _getUserAddress(123),
                ammCharlieTreasuryManager: _getUserAddress(123)
            })
        );
        vm.stopPrank();
    }

    function _setupAssetServices() private {
        vm.startPrank(owner);
        // Setup AssetServices for stEth
        IAmmGovernanceServiceBaseV1(iporProtocolRouter).setAssetServices(
            stEth,
            StorageLibBaseV1.AssetServicesValue({
                ammPoolsService: ammPoolsServiceStEth,
                ammOpenSwapService: address(0),
                ammCloseSwapService: address(0)
            })
        );
        vm.stopPrank();
    }

    function _setupAssetLensData() private {
        vm.startPrank(owner);
        // Setup AssetLensData for stEth
        IAmmGovernanceServiceBaseV1(iporProtocolRouter).setAssetLensData(
            stEth,
            StorageLibBaseV1.AssetLensDataValue({
                decimals: 18,
                ipToken: ipstEth,
                ammStorage: ammStorageStEth,
                ammTreasury: ammTreasuryStEth,
                ammVault: address(0),
                spread: address(0)
            })
        );
        vm.stopPrank();
    }

    function _setupPools() internal {
        vm.startPrank(owner);
        IAmmGovernanceService(iporProtocolRouter).setAmmPoolsParams(stEth, type(uint32).max, 0, 5000);
        vm.stopPrank();
    }

    function _setupUser(address user, uint256 value) internal {
        deal(user, 1_000_000e18);
        vm.startPrank(user);

        IStETH(stEth).submit{value: value}(address(0));
        IStETH(stEth).approve(iporProtocolRouter, type(uint256).max);

        IWETH9(wEth).deposit{value: value}();
        IWETH9(wEth).approve(iporProtocolRouter, type(uint256).max);

        vm.stopPrank();
    }

    function _constructProxy(address impl) private returns (ERC1967Proxy proxy) {
        vm.prank(owner);
        proxy = new ERC1967Proxy(address(impl), abi.encodeWithSignature("initialize(bool)", false));
    }

    function _getUserAddress(uint256 number) internal returns (address) {
        return vm.rememberKey(number);
    }
}

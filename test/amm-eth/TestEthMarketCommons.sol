// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.20;

import "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import "forge-std/Test.sol";
import "../mocks/EmptyRouterImplementation.sol";
import "../../contracts/tokens/IpToken.sol";
import "../../contracts/amm-eth/AmmTreasuryEth.sol";
import "../../contracts/amm-eth/AmmPoolsServiceEth.sol";
import "../../contracts/amm-eth/AmmPoolsLensEth.sol";
import "../../contracts/interfaces/IAmmGovernanceLens.sol";
import "../../contracts/amm-common/AmmGovernanceService.sol";
import "../../contracts/router/IporProtocolRouter.sol";
import "../../contracts/basic/amm/AmmStorageGenOne.sol";

contract TestEthMarketCommons is Test {
    address internal defaultAnvilAddress = 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266;

    address public constant owner = 0xD92E9F039E4189c342b4067CC61f5d063960D248;
    address public constant DAI = 0x6B175474E89094C44Da98b954EedeAC495271d0F;
    address public constant USDC = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;
    address public constant USDT = 0xdAC17F958D2ee523a2206206994597C13D831ec7;
    address public constant IPOR = 0x1e4746dC744503b53b4A082cB3607B169a289090;
    address public constant stEth = 0xae7ab96520DE3A18E5e111B5EaAb095312D7fE84;
    address public constant wEth = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    address public constant iporOracle = 0x421C69EAa54646294Db30026aeE80D01988a6876;

    // new contracts for v2 ethMarket
    // todo: change when implement redeem
    uint256 public redeemFeeRateEth = 5e15;

    address public ipstEth;
    address payable public iporProtocolRouter;
    address public ammTreasuryEth;
    address public ammStorageStEth;
    address public ammGovernanceService;
    address public ammPoolsServiceEth;
    address public ammPoolsLensEth;

    // tests data
    address public userOne = address(11);
    address public userTwo = address(22);
    address public userThree = address(33);

    function _init() internal {
        _createEmptyRouterImplementation();

        _createIpstEth();
        _createDummyAmmTreasuryStEth();
        _createAmmStorageStEth();
        _upgradeAmmTreasuryStEth();
        _createAmmPoolServiceEth();
        _createAmmPoolsLensEth();
        _createAmmGovernanceService();
        _updateIporRouterImplementation();

        _setupPools();

        _setupUser(userOne, 50_000e18);
        _setupUser(userTwo, 50_000e18);
        _setupUser(userThree, 10_000e18);
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
        AmmTreasuryEth impl = new AmmTreasuryEth(stEth, iporProtocolRouter, defaultAnvilAddress);
        ERC1967Proxy proxy = _constructProxy(address(impl));
        ammTreasuryEth = address(proxy);
    }

    function _createAmmStorageStEth() private {
        vm.startPrank(owner);
        AmmStorageGenOne impl = new AmmStorageGenOne(iporProtocolRouter, ammTreasuryEth);
        ERC1967Proxy proxy = new ERC1967Proxy(address(impl), abi.encodeWithSignature("initialize()"));
        ammStorageStEth = address(proxy);
    }

    function _upgradeAmmTreasuryStEth() private {
        address impl = address(new AmmTreasuryEth(stEth, iporProtocolRouter, ammStorageStEth));
        AmmTreasuryEth(ammTreasuryEth).upgradeTo(impl);
    }

    function _createAmmTreasuryEth() private {
        vm.prank(owner);
        AmmTreasuryEth impl = new AmmTreasuryEth(stEth, iporProtocolRouter, userOne);
        ERC1967Proxy proxy = _constructProxy(address(impl));
        ammTreasuryEth = address(proxy);
    }

    function _createAmmPoolServiceEth() private {
        vm.startPrank(owner);
        AmmPoolsServiceEth pool = new AmmPoolsServiceEth(
            stEth,
            wEth,
            ipstEth,
            ammTreasuryEth,
            ammStorageStEth,
            iporOracle,
            iporProtocolRouter,
            redeemFeeRateEth
        );
        ammPoolsServiceEth = address(pool);
        vm.stopPrank();
    }

    function _createAmmPoolsLensEth() private {
        vm.startPrank(owner);
        AmmPoolsLensEth lens = new AmmPoolsLensEth(stEth, ipstEth, ammTreasuryEth, ammStorageStEth, iporOracle);
        ammPoolsLensEth = address(lens);
        vm.stopPrank();
    }

    function _createAmmGovernanceService() private {
        vm.startPrank(owner);
        IAmmGovernanceLens.AmmGovernancePoolConfiguration memory daiConfig = IAmmGovernanceLens
            .AmmGovernancePoolConfiguration(
                DAI,
                18,
                _getUserAddress(123),
                _getUserAddress(123),
                _getUserAddress(123),
                _getUserAddress(123),
                _getUserAddress(123),
                _getUserAddress(123)
            );

        IAmmGovernanceLens.AmmGovernancePoolConfiguration memory usdcConfig = IAmmGovernanceLens
            .AmmGovernancePoolConfiguration(
                USDC,
                6,
                _getUserAddress(123),
                _getUserAddress(123),
                _getUserAddress(123),
                _getUserAddress(123),
                _getUserAddress(123),
                _getUserAddress(123)
            );

        IAmmGovernanceLens.AmmGovernancePoolConfiguration memory usdtConfig = IAmmGovernanceLens
            .AmmGovernancePoolConfiguration(
                USDT,
                6,
                _getUserAddress(123),
                _getUserAddress(123),
                _getUserAddress(123),
                _getUserAddress(123),
                _getUserAddress(123),
                _getUserAddress(123)
            );

        IAmmGovernanceLens.AmmGovernancePoolConfiguration memory stEthConfig = IAmmGovernanceLens
            .AmmGovernancePoolConfiguration(
                stEth,
                18,
                _getUserAddress(123),
                _getUserAddress(123),
                _getUserAddress(123),
                _getUserAddress(123),
                _getUserAddress(123),
                _getUserAddress(123)
            );

        ammGovernanceService = address(new AmmGovernanceService(usdtConfig, usdcConfig, daiConfig, stEthConfig));
        vm.stopPrank();
    }

    function _updateIporRouterImplementation() internal {
        vm.startPrank(owner);
        IporProtocolRouter newImplementation = new IporProtocolRouter(
            IporProtocolRouter.DeployedContracts({
                ammSwapsLens: _getUserAddress(123),
                ammPoolsLens: _getUserAddress(123),
                assetManagementLens: _getUserAddress(123),
                ammOpenSwapService: _getUserAddress(123),
                ammOpenSwapServiceStEth: _getUserAddress(123),
                ammCloseSwapService: _getUserAddress(123),
                ammCloseSwapServiceStEth: _getUserAddress(123),
                ammPoolsService: _getUserAddress(123),
                ammGovernanceService: ammGovernanceService,
                liquidityMiningLens: _getUserAddress(123),
                powerTokenLens: _getUserAddress(123),
                flowService: _getUserAddress(123),
                stakeService: _getUserAddress(123),
                ammPoolsServiceEth: ammPoolsServiceEth,
                ammPoolsLensEth: ammPoolsLensEth
            })
        );

        IporProtocolRouter(iporProtocolRouter).upgradeTo(address(newImplementation));
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

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.20;

import "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import "forge-std/Test.sol";
import "../../mocks/EmptyRouterImplementation.sol";
import "../../../contracts/chains/ethereum/router/IporProtocolRouter.sol";

contract IporProtocolRouterBuilder is Test {
    struct BuilderData {
        address ammSwapsLens;
        address ammPoolsLens;
        address ammPoolsLensStEth;
        address assetManagementLens;
        address ammOpenSwapService;
        address ammOpenSwapServiceStEth;
        address ammCloseSwapServiceUsdt;
        address ammCloseSwapServiceUsdc;
        address ammCloseSwapServiceDai;
        address ammCloseSwapServiceStEth;
        address ammCloseSwapLens;
        address ammCloseSwapLensStEth;
        address ammPoolsService;
        address ammPoolsServiceStEth;
        address ammGovernanceService;
        address liquidityMiningLens;
        address powerTokenLens;
        address flowService;
        address stakeService;
    }

    BuilderData private builderData;

    address private _owner;

    constructor(address owner) {
        _owner = owner;
    }

    function withAmmSwapsLens(address ammSwapsLens) public returns (IporProtocolRouterBuilder) {
        builderData.ammSwapsLens = ammSwapsLens;
        return this;
    }

    function withAmmPoolsLens(address ammPoolsLens) public returns (IporProtocolRouterBuilder) {
        builderData.ammPoolsLens = ammPoolsLens;
        return this;
    }

    function withAssetManagementLens(address assetManagementLens) public returns (IporProtocolRouterBuilder) {
        builderData.assetManagementLens = assetManagementLens;
        return this;
    }

    function withAmmOpenSwapService(address ammOpenSwapService) public returns (IporProtocolRouterBuilder) {
        builderData.ammOpenSwapService = ammOpenSwapService;
        return this;
    }

    function withAmmOpenSwapServiceStEth(address ammOpenSwapServiceStEth) public returns (IporProtocolRouterBuilder) {
        builderData.ammOpenSwapServiceStEth = ammOpenSwapServiceStEth;
        return this;
    }

    function withAmmCloseSwapServiceUsdt(address ammCloseSwapService) public returns (IporProtocolRouterBuilder) {
        builderData.ammCloseSwapServiceUsdt = ammCloseSwapService;
        return this;
    }

    function withAmmCloseSwapServiceUsdc(address ammCloseSwapService) public returns (IporProtocolRouterBuilder) {
        builderData.ammCloseSwapServiceUsdc = ammCloseSwapService;
        return this;
    }

    function withAmmCloseSwapServiceDai(address ammCloseSwapService) public returns (IporProtocolRouterBuilder) {
        builderData.ammCloseSwapServiceDai = ammCloseSwapService;
        return this;
    }

    function withAmmCloseSwapLens(address ammCloseSwapLens) public returns (IporProtocolRouterBuilder) {
        builderData.ammCloseSwapLens = ammCloseSwapLens;
        return this;
    }

    function withAmmPoolsService(address ammPoolsService) public returns (IporProtocolRouterBuilder) {
        builderData.ammPoolsService = ammPoolsService;
        return this;
    }

    function withAmmGovernanceService(address ammGovernanceService) public returns (IporProtocolRouterBuilder) {
        builderData.ammGovernanceService = ammGovernanceService;
        return this;
    }

    function buildEmptyProxy() public returns (IporProtocolRouter) {
        vm.startPrank(_owner);

        address payable proxy = _constructProxy(new EmptyRouterImplementation());
        IporProtocolRouter iporProtocolRouter = IporProtocolRouter(proxy);
        vm.stopPrank();
        delete builderData;
        return iporProtocolRouter;
    }

    function build() public returns (IporProtocolRouter) {
        vm.startPrank(_owner);

        IporProtocolRouter.DeployedContracts memory deployedContracts = IporProtocolRouter.DeployedContracts({
            ammSwapsLens: builderData.ammSwapsLens,
            ammPoolsLens: builderData.ammPoolsLens,
            assetManagementLens: builderData.assetManagementLens,
            ammOpenSwapService: builderData.ammOpenSwapService,
            ammOpenSwapServiceStEth: builderData.ammOpenSwapServiceStEth,
            ammCloseSwapServiceUsdt: builderData.ammCloseSwapServiceUsdt,
            ammCloseSwapServiceUsdc: builderData.ammCloseSwapServiceUsdc,
            ammCloseSwapServiceDai: builderData.ammCloseSwapServiceDai,
            ammCloseSwapLens: builderData.ammCloseSwapLens,
            ammCloseSwapServiceStEth: builderData.ammCloseSwapServiceStEth,
            ammPoolsService: builderData.ammPoolsService,
            ammGovernanceService: builderData.ammGovernanceService,
            liquidityMiningLens: builderData.liquidityMiningLens,
            powerTokenLens: builderData.powerTokenLens,
            flowService: builderData.flowService,
            stakeService: builderData.stakeService,
            ammPoolsServiceStEth: builderData.ammPoolsServiceStEth,
            ammPoolsLensStEth: builderData.ammPoolsLensStEth,
            ammPoolsServiceUsdm: 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266, // TODO: fix address if needed
            ammPoolsLensUsdm: 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266, // TODO: fix address if needed
            ammPoolsServiceWeEth: 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266, // TODO: fix address if needed
            ammPoolsLensWeEth: 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266 // TODO: fix address if needed

        });

        address payable proxy = _constructProxy(new IporProtocolRouter(deployedContracts));
        IporProtocolRouter iporProtocolRouter = IporProtocolRouter(proxy);

        vm.stopPrank();
        delete builderData;
        return iporProtocolRouter;
    }

    function upgrade(address payable routerAddress) public {
        vm.startPrank(_owner);

        IporProtocolRouter.DeployedContracts memory deployedContracts = IporProtocolRouter.DeployedContracts({
            ammSwapsLens: builderData.ammSwapsLens,
            ammPoolsLens: builderData.ammPoolsLens,
            ammPoolsLensStEth: builderData.ammPoolsLensStEth,
            assetManagementLens: builderData.assetManagementLens,
            ammOpenSwapService: builderData.ammOpenSwapService,
            ammOpenSwapServiceStEth: builderData.ammOpenSwapServiceStEth,
            ammCloseSwapServiceUsdt: builderData.ammCloseSwapServiceUsdt,
            ammCloseSwapServiceUsdc: builderData.ammCloseSwapServiceUsdc,
            ammCloseSwapServiceDai: builderData.ammCloseSwapServiceDai,
            ammCloseSwapLens: builderData.ammCloseSwapLens,
            ammCloseSwapServiceStEth: builderData.ammCloseSwapServiceStEth,
            ammPoolsService: builderData.ammPoolsService,
            ammPoolsServiceStEth: builderData.ammPoolsServiceStEth,
            ammGovernanceService: builderData.ammGovernanceService,
            liquidityMiningLens: builderData.liquidityMiningLens,
            powerTokenLens: builderData.powerTokenLens,
            flowService: builderData.flowService,
            stakeService: builderData.stakeService,
            ammPoolsServiceUsdm: 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266, // TODO: fix address if needed
            ammPoolsLensUsdm: 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266, // TODO: fix address if needed
            ammPoolsServiceWeEth: 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266, // TODO: fix address if needed
            ammPoolsLensWeEth: 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266 // TODO: fix address if needed
        });

        IporProtocolRouter router = IporProtocolRouter(routerAddress);
        router.upgradeTo(address(new IporProtocolRouter(deployedContracts)));

        vm.stopPrank();
    }

    function _constructProxy(EmptyRouterImplementation impl) internal returns (address payable proxy) {
        proxy = payable(address(new ERC1967Proxy(address(impl), abi.encodeWithSignature("initialize(bool)", false))));
    }

    function _constructProxy(IporProtocolRouter impl) internal returns (address payable proxy) {
        proxy = payable(address(new ERC1967Proxy(address(impl), abi.encodeWithSignature("initialize(bool)", false))));
    }
}

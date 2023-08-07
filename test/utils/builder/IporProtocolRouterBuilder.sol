// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.20;

import "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import "forge-std/Test.sol";
import "../../mocks/EmptyRouterImplementation.sol";
import "../../../contracts/router/IporProtocolRouter.sol";

contract IporProtocolRouterBuilder is Test {
    struct BuilderData {
        address ammSwapsLens;
        address ammPoolsLens;
        address ammPoolsLensEth;
        address assetManagementLens;
        address ammOpenSwapService;
        address ammCloseSwapService;
        address ammPoolsService;
        address ammPoolsServiceEth;
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

    function withAmmCloseSwapService(address ammCloseSwapService) public returns (IporProtocolRouterBuilder) {
        builderData.ammCloseSwapService = ammCloseSwapService;
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

        ERC1967Proxy proxy = _constructProxy(address(new EmptyRouterImplementation()));
        IporProtocolRouter iporProtocolRouter = IporProtocolRouter(address(proxy));
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
            ammCloseSwapService: builderData.ammCloseSwapService,
            ammPoolsService: builderData.ammPoolsService,
            ammGovernanceService: builderData.ammGovernanceService,
            liquidityMiningLens: builderData.liquidityMiningLens,
            powerTokenLens: builderData.powerTokenLens,
            flowService: builderData.flowService,
            stakeService: builderData.stakeService,
            ammPoolsServiceEth: builderData.ammPoolsServiceEth,
            ammPoolsLensEth: builderData.ammPoolsLensEth
        });

        ERC1967Proxy proxy = _constructProxy(address(new IporProtocolRouter(deployedContracts)));
        IporProtocolRouter iporProtocolRouter = IporProtocolRouter(address(proxy));

        vm.stopPrank();
        delete builderData;
        return iporProtocolRouter;
    }

    function upgrade(address routerAddress) public {
        vm.startPrank(_owner);

        IporProtocolRouter.DeployedContracts memory deployedContracts = IporProtocolRouter.DeployedContracts({
            ammSwapsLens: builderData.ammSwapsLens,
            ammPoolsLens: builderData.ammPoolsLens,
            ammPoolsLensEth: builderData.ammPoolsLensEth,
            assetManagementLens: builderData.assetManagementLens,
            ammOpenSwapService: builderData.ammOpenSwapService,
            ammCloseSwapService: builderData.ammCloseSwapService,
            ammPoolsService: builderData.ammPoolsService,
            ammPoolsServiceEth: builderData.ammPoolsServiceEth,
            ammGovernanceService: builderData.ammGovernanceService,
            liquidityMiningLens: builderData.liquidityMiningLens,
            powerTokenLens: builderData.powerTokenLens,
            flowService: builderData.flowService,
            stakeService: builderData.stakeService
        });

        IporProtocolRouter router = IporProtocolRouter(routerAddress);
        router.upgradeTo(address(new IporProtocolRouter(deployedContracts)));

        vm.stopPrank();
    }

    function _constructProxy(address impl) internal returns (ERC1967Proxy proxy) {
        proxy = new ERC1967Proxy(address(impl), abi.encodeWithSignature("initialize(bool)", false));
    }
}

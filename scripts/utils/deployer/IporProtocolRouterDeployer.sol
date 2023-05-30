// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.16;

import "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import "./DeployerUtils.sol";
import "scripts/mocks/EmptyRouterImplementation.sol";

contract IporProtocolRouterDeployer {
    struct DeployerData {
        address ammSwapsLens;
        address ammPoolsLens;
        address assetManagementLens;
        address ammOpenSwapService;
        address ammCloseSwapService;
        address ammPoolsService;
        address ammGovernanceService;
        address liquidityMiningLens;
        address powerTokenLens;
        address flowService;
        address stakeService;
    }

    DeployerData private deployerData;

    function withAmmSwapsLens(address ammSwapsLens) public returns (IporProtocolRouterDeployer) {
        deployerData.ammSwapsLens = ammSwapsLens;
        return this;
    }

    function withAmmPoolsLens(address ammPoolsLens) public returns (IporProtocolRouterDeployer) {
        deployerData.ammPoolsLens = ammPoolsLens;
        return this;
    }

    function withAssetManagementLens(address assetManagementLens) public returns (IporProtocolRouterDeployer) {
        deployerData.assetManagementLens = assetManagementLens;
        return this;
    }

    function withAmmOpenSwapService(address ammOpenSwapService) public returns (IporProtocolRouterDeployer) {
        deployerData.ammOpenSwapService = ammOpenSwapService;
        return this;
    }

    function withAmmCloseSwapService(address ammCloseSwapService) public returns (IporProtocolRouterDeployer) {
        deployerData.ammCloseSwapService = ammCloseSwapService;
        return this;
    }

    function withAmmPoolsService(address ammPoolsService) public returns (IporProtocolRouterDeployer) {
        deployerData.ammPoolsService = ammPoolsService;
        return this;
    }

    function withAmmGovernanceService(address ammGovernanceService) public returns (IporProtocolRouterDeployer) {
        deployerData.ammGovernanceService = ammGovernanceService;
        return this;
    }

    function buildEmptyProxy() public returns (IporProtocolRouter) {
//        ERC1967Proxy proxy = _constructProxy(address(new EmptyRouterImplementation()));
//        IporProtocolRouter iporProtocolRouter = IporProtocolRouter(address(proxy));
        return IporProtocolRouter(0x129589472F6F11EB57720Ef1793f8b2994D0EE55);
    }

//    function build() public returns (IporProtocolRouter) {
//        IporProtocolRouter.DeployedContracts memory deployedContracts = IporProtocolRouter.DeployedContracts({
//            ammSwapsLens: deployerData.ammSwapsLens,
//            ammPoolsLens: deployerData.ammPoolsLens,
//            assetManagementLens: deployerData.assetManagementLens,
//            ammOpenSwapService: deployerData.ammOpenSwapService,
//            ammCloseSwapService: deployerData.ammCloseSwapService,
//            ammPoolsService: deployerData.ammPoolsService,
//            ammGovernanceService: deployerData.ammGovernanceService,
//            liquidityMiningLens: deployerData.liquidityMiningLens,
//            powerTokenLens: deployerData.powerTokenLens,
//            flowService: deployerData.flowService,
//            stakeService: deployerData.stakeService
//        });
//
//        ERC1967Proxy proxy = _constructProxy(address(new IporProtocolRouter(deployedContracts)));
//        IporProtocolRouter iporProtocolRouter = IporProtocolRouter(address(proxy));
//
//        delete deployerData;
//        return iporProtocolRouter;
//    }
//
//    function upgrade(address routerAddress) public {
//
//        IporProtocolRouter.DeployedContracts memory deployedContracts = IporProtocolRouter.DeployedContracts({
//            ammSwapsLens: deployerData.ammSwapsLens,
//            ammPoolsLens: deployerData.ammPoolsLens,
//            assetManagementLens: deployerData.assetManagementLens,
//            ammOpenSwapService: deployerData.ammOpenSwapService,
//            ammCloseSwapService: deployerData.ammCloseSwapService,
//            ammPoolsService: deployerData.ammPoolsService,
//            ammGovernanceService: deployerData.ammGovernanceService,
//            liquidityMiningLens: deployerData.liquidityMiningLens,
//            powerTokenLens: deployerData.powerTokenLens,
//            flowService: deployerData.flowService,
//            stakeService: deployerData.stakeService
//        });
//
//        IporProtocolRouter router = IporProtocolRouter(routerAddress);
//        router.upgradeTo(address(new IporProtocolRouter(deployedContracts)));
//
//    }
//
    function _constructProxy(address impl) internal returns (ERC1967Proxy proxy) {
        proxy = new ERC1967Proxy(address(impl), abi.encodeWithSignature("initialize(bool)", false));
    }
}

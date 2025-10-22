// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.26;

import "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import "forge-std/Test.sol";
import "../../mocks/EmptyRouterImplementation.sol";
import "../../../contracts/chains/ethereum/router/IporProtocolRouterEthereum.sol";

contract IporProtocolRouterBuilder is Test {
    struct BuilderData {
        address ammSwapsLens;
        address ammPoolsLens;
        address ammPoolsLensBaseV1;
        address assetManagementLens;
        address ammOpenSwapService;
        address ammCloseSwapServiceUsdt;
        address ammCloseSwapServiceUsdc;
        address ammCloseSwapServiceDai;
        address ammCloseSwapLens;
        address ammPoolsService;
        address ammGovernanceService;
        address liquidityMiningLens;
        address powerTokenLens;
        address flowService;
        address stakeService;
        address stEth;
        address weEth;
        address usdm;
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

    function withUsdm(address usdm) public returns (IporProtocolRouterBuilder) {
        builderData.usdm = usdm;
        return this;
    }

    function buildEmptyProxy() public returns (IporProtocolRouterEthereum) {
        vm.startPrank(_owner);

        address payable proxy = _constructProxy(new EmptyRouterImplementation());
        IporProtocolRouterEthereum iporProtocolRouter = IporProtocolRouterEthereum(proxy);
        vm.stopPrank();
        delete builderData;
        return iporProtocolRouter;
    }

    function build() public returns (IporProtocolRouterEthereum) {
        vm.startPrank(_owner);

        IporProtocolRouterEthereum.DeployedContracts memory deployedContracts = IporProtocolRouterEthereum
            .DeployedContracts({
                ammSwapsLens: builderData.ammSwapsLens,
                ammPoolsLens: builderData.ammPoolsLens,
                ammPoolsLensBaseV1: builderData.ammPoolsLensBaseV1 != address(0)
                    ? builderData.ammPoolsLensBaseV1
                    : 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266,
                assetManagementLens: builderData.assetManagementLens,
                ammOpenSwapService: builderData.ammOpenSwapService,
                ammCloseSwapServiceUsdt: builderData.ammCloseSwapServiceUsdt,
                ammCloseSwapServiceUsdc: builderData.ammCloseSwapServiceUsdc,
                ammCloseSwapServiceDai: builderData.ammCloseSwapServiceDai,
                ammCloseSwapLens: builderData.ammCloseSwapLens,
                ammPoolsService: builderData.ammPoolsService,
                ammGovernanceService: builderData.ammGovernanceService,
                liquidityMiningLens: builderData.liquidityMiningLens,
                powerTokenLens: builderData.powerTokenLens,
                flowService: builderData.flowService,
                stakeService: builderData.stakeService,
                stEth: builderData.stEth != address(0) ? builderData.stEth : 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266,
                weEth: builderData.weEth != address(0) ? builderData.weEth : 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266,
                usdm: builderData.usdm != address(0) ? builderData.usdm : 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266
            });

        address payable proxy = _constructProxy(new IporProtocolRouterEthereum(deployedContracts));
        IporProtocolRouterEthereum iporProtocolRouter = IporProtocolRouterEthereum(proxy);

        vm.stopPrank();
        delete builderData;
        return iporProtocolRouter;
    }

    function upgrade(address payable routerAddress) public {
        vm.startPrank(_owner);

        IporProtocolRouterEthereum.DeployedContracts memory deployedContracts = IporProtocolRouterEthereum
            .DeployedContracts({
                ammSwapsLens: builderData.ammSwapsLens,
                ammPoolsLens: builderData.ammPoolsLens,
                ammPoolsLensBaseV1: builderData.ammPoolsLensBaseV1 != address(0)
                    ? builderData.ammPoolsLensBaseV1
                    : 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266,
                assetManagementLens: builderData.assetManagementLens,
                ammOpenSwapService: builderData.ammOpenSwapService,
                ammCloseSwapServiceUsdt: builderData.ammCloseSwapServiceUsdt,
                ammCloseSwapServiceUsdc: builderData.ammCloseSwapServiceUsdc,
                ammCloseSwapServiceDai: builderData.ammCloseSwapServiceDai,
                ammCloseSwapLens: builderData.ammCloseSwapLens,
                ammPoolsService: builderData.ammPoolsService,
                ammGovernanceService: builderData.ammGovernanceService,
                liquidityMiningLens: builderData.liquidityMiningLens,
                powerTokenLens: builderData.powerTokenLens,
                flowService: builderData.flowService,
                stakeService: builderData.stakeService,
                stEth: builderData.stEth != address(0) ? builderData.stEth : 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266,
                weEth: builderData.weEth != address(0) ? builderData.weEth : 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266,
                usdm: builderData.usdm != address(0) ? builderData.usdm : 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266
            });

        IporProtocolRouterEthereum router = IporProtocolRouterEthereum(routerAddress);
        router.upgradeTo(address(new IporProtocolRouterEthereum(deployedContracts)));

        vm.stopPrank();
    }

    function _constructProxy(EmptyRouterImplementation impl) internal returns (address payable proxy) {
        proxy = payable(address(new ERC1967Proxy(address(impl), abi.encodeWithSignature("initialize(bool)", false))));
    }

    function _constructProxy(IporProtocolRouterEthereum impl) internal returns (address payable proxy) {
        proxy = payable(address(new ERC1967Proxy(address(impl), abi.encodeWithSignature("initialize(bool)", false))));
    }
}

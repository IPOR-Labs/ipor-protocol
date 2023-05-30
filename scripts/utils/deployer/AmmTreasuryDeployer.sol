// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.16;

import "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import "./DeployerUtils.sol";
import "scripts/mocks/EmptyAmmTreasuryImplementation.sol";

contract AmmTreasuryDeployer {
    struct DeployerData {
        address asset;
        uint256 assetDecimals;
        address ammStorage;
        address assetManagement;
        address iporProtocolRouter;
        address ammTreasuryImplementation;
        address ammTreasuryProxyAddress;
    }

    DeployerData private deployerData;

    function withAsset(address asset) public returns (AmmTreasuryDeployer) {
        deployerData.asset = asset;
        deployerData.assetDecimals = IERC20Metadata(asset).decimals();
        return this;
    }

    function withAmmStorage(address ammStorage) public returns (AmmTreasuryDeployer) {
        deployerData.ammStorage = ammStorage;
        return this;
    }

    function withAssetManagement(address assetManagement) public returns (AmmTreasuryDeployer) {
        deployerData.assetManagement = assetManagement;
        return this;
    }

    function withIporProtocolRouter(address iporProtocolRouter) public returns (AmmTreasuryDeployer) {
        deployerData.iporProtocolRouter = iporProtocolRouter;
        return this;
    }

    function withAmmTreasuryImplementation(address ammTreasuryImplementation) public returns (AmmTreasuryDeployer) {
        deployerData.ammTreasuryImplementation = ammTreasuryImplementation;
        return this;
    }

    function withAmmTreasuryProxyAddress(address ammTreasuryProxyAddress) public returns (AmmTreasuryDeployer) {
        deployerData.ammTreasuryProxyAddress = ammTreasuryProxyAddress;
        return this;
    }

    function build() public returns (AmmTreasury) {
        ERC1967Proxy miltonProxy = _constructProxy(_buildMiltonImplementation());
        AmmTreasury milton = AmmTreasury(address(miltonProxy));
        return milton;
    }

    function buildEmptyProxy() public returns (AmmTreasury) {

        ERC1967Proxy proxy = _constructProxy(address(new EmptyAmmTreasuryImplementation()));
        AmmTreasury ammTreasury = AmmTreasury(address(proxy));
        return ammTreasury;
    }

    function upgrade() public {
        require(deployerData.ammTreasuryProxyAddress != address(0), "ammTreasuryProxyAddress is required");

        AmmTreasury ammTreasury = AmmTreasury(deployerData.ammTreasuryProxyAddress);

        address implementation;

        if (address(deployerData.ammTreasuryImplementation) == address(0)) {
            implementation = address(_buildMiltonImplementation());
        }

        ammTreasury.upgradeTo(implementation);
    }

    function _buildMiltonImplementation() internal returns (address miltonImpl) {
        require(deployerData.asset != address(0), "asset is required");
        require(deployerData.assetDecimals != 0, "assetDecimals is required");
        require(deployerData.ammStorage != address(0), "ammStorage is required");
        require(deployerData.assetManagement != address(0), "assetManagement is required");
        require(deployerData.iporProtocolRouter != address(0), "iporProtocolRouter is required");

        miltonImpl = address(
            new AmmTreasury(
                deployerData.asset,
                deployerData.assetDecimals,
                deployerData.ammStorage,
                deployerData.assetManagement,
                deployerData.iporProtocolRouter
            )
        );
    }

    function _constructProxy(address impl) internal returns (ERC1967Proxy proxy) {
        proxy = new ERC1967Proxy(impl, abi.encodeWithSignature("initialize(bool)", false));
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.20;

import "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import "./BuilderUtils.sol";
import "forge-std/Test.sol";
import "test/mocks/EmptyAmmTreasuryImplementation.sol";

contract AmmTreasuryBuilder is Test {
    struct BuilderData {
        address asset;
        uint256 assetDecimals;
        address ammStorage;
        address assetManagement;
        address iporProtocolRouter;
        address ammTreasuryImplementation;
        address ammTreasuryProxyAddress;
    }

    BuilderData private builderData;

    address private _owner;

    constructor(address owner) {
        _owner = owner;
    }

    function withAsset(address asset) public returns (AmmTreasuryBuilder) {
        builderData.asset = asset;
        builderData.assetDecimals = IERC20Metadata(asset).decimals();
        return this;
    }

    function withAmmStorage(address ammStorage) public returns (AmmTreasuryBuilder) {
        builderData.ammStorage = ammStorage;
        return this;
    }

    function withAssetManagement(address assetManagement) public returns (AmmTreasuryBuilder) {
        builderData.assetManagement = assetManagement;
        return this;
    }

    function withIporProtocolRouter(address iporProtocolRouter) public returns (AmmTreasuryBuilder) {
        builderData.iporProtocolRouter = iporProtocolRouter;
        return this;
    }

    function withAmmTreasuryImplementation(address ammTreasuryImplementation) public returns (AmmTreasuryBuilder) {
        builderData.ammTreasuryImplementation = ammTreasuryImplementation;
        return this;
    }

    function withAmmTreasuryProxyAddress(address ammTreasuryProxyAddress) public returns (AmmTreasuryBuilder) {
        builderData.ammTreasuryProxyAddress = ammTreasuryProxyAddress;
        return this;
    }

    function build() public returns (AmmTreasury) {
        vm.startPrank(_owner);
        ERC1967Proxy miltonProxy = _constructProxy(_buildMiltonImplementation());
        AmmTreasury milton = AmmTreasury(address(miltonProxy));
        vm.stopPrank();
        delete builderData;
        return milton;
    }

    function buildEmptyProxy() public returns (AmmTreasury) {
        vm.startPrank(_owner);

        ERC1967Proxy proxy = _constructProxy(address(new EmptyAmmTreasuryImplementation()));
        AmmTreasury ammTreasury = AmmTreasury(address(proxy));
        vm.stopPrank();
        delete builderData;
        return ammTreasury;
    }

    function upgrade() public {
        require(builderData.ammTreasuryProxyAddress != address(0), "ammTreasuryProxyAddress is required");
        vm.startPrank(_owner);

        AmmTreasury ammTreasury = AmmTreasury(builderData.ammTreasuryProxyAddress);

        address implementation;

        if (address(builderData.ammTreasuryImplementation) == address(0)) {
            implementation = address(_buildMiltonImplementation());
        }

        ammTreasury.upgradeTo(implementation);

        vm.stopPrank();
    }

    function _buildMiltonImplementation() internal returns (address miltonImpl) {
        require(builderData.asset != address(0), "asset is required");
        require(builderData.assetDecimals != 0, "assetDecimals is required");
        require(builderData.ammStorage != address(0), "ammStorage is required");
        require(builderData.assetManagement != address(0), "assetManagement is required");
        require(builderData.iporProtocolRouter != address(0), "iporProtocolRouter is required");

        miltonImpl = address(
            new AmmTreasury(
                builderData.asset,
                builderData.assetDecimals,
                builderData.ammStorage,
                builderData.assetManagement,
                builderData.iporProtocolRouter
            )
        );
    }

    function _constructProxy(address impl) internal returns (ERC1967Proxy proxy) {
        proxy = new ERC1967Proxy(impl, abi.encodeWithSignature("initialize(bool)", false));
    }
}

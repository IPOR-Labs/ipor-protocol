// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.16;

import "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import "./BuilderUtils.sol";
import "forge-std/Test.sol";

contract AmmTreasuryBuilder is Test {
    struct BuilderData {
        address asset;
        uint256 assetDecimals;
        address ammStorage;
        address assetManagement;
        address iporProtocolRouter;
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

    function build() public returns (AmmTreasury) {
        vm.startPrank(_owner);
        ERC1967Proxy miltonProxy = _constructProxy(_buildMiltonImplementation());
        AmmTreasury milton = AmmTreasury(address(miltonProxy));
        vm.stopPrank();
        delete builderData;
        return milton;
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

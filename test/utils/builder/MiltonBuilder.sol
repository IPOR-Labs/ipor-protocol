// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.16;

import "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import "./BuilderUtils.sol";
import "forge-std/Test.sol";

contract MiltonBuilder is Test {
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

    function withAsset(address asset) public returns (MiltonBuilder) {
        builderData.asset = asset;
        return this;
    }

    function withAssetDecimals(uint256 assetDecimals) public returns (MiltonBuilder) {
        builderData.assetDecimals = assetDecimals;
        return this;
    }

    function withAmmStorage(address ammStorage) public returns (MiltonBuilder) {
        builderData.ammStorage = ammStorage;
        return this;
    }

    function withAssetManagement(address assetManagement) public returns (MiltonBuilder) {
        builderData.assetManagement = assetManagement;
        return this;
    }

    function build() public returns (ItfMilton) {
        vm.startPrank(_owner);
        ERC1967Proxy miltonProxy = _constructProxy(_buildMiltonImplementation());
        ItfMilton milton = ItfMilton(address(miltonProxy));
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
            new Milton(
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

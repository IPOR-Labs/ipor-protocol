// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.16;

import "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import "contracts/itf/ItfJoseph.sol";

import "./BuilderUtils.sol";
import "forge-std/Test.sol";

contract JosephBuilder is Test {
    struct BuilderData {
        BuilderUtils.AssetType assetType;
        bool paused;
        address asset;
        address ipToken;
        address milton;
        address miltonStorage;
        address stanley;
        address josephImplementation;
    }

    BuilderData private builderData;

    address private _owner;

    constructor(address owner) {
        _owner = owner;
    }

    function withAssetType(BuilderUtils.AssetType assetType) public returns (JosephBuilder) {
        builderData.assetType = assetType;
        return this;
    }

    function withPaused(bool paused) public returns (JosephBuilder) {
        builderData.paused = paused;
        return this;
    }

    function withAsset(address asset) public returns (JosephBuilder) {
        builderData.asset = asset;
        return this;
    }

    function withIpToken(address ipToken) public returns (JosephBuilder) {
        builderData.ipToken = ipToken;
        return this;
    }

    function withMilton(address milton) public returns (JosephBuilder) {
        builderData.milton = milton;
        return this;
    }

    function withMiltonStorage(address miltonStorage) public returns (JosephBuilder) {
        builderData.miltonStorage = miltonStorage;
        return this;
    }

    function withStanley(address stanley) public returns (JosephBuilder) {
        builderData.stanley = stanley;
        return this;
    }

    function withJosephImplementation(address josephImplementation) public returns (JosephBuilder) {
        builderData.josephImplementation = josephImplementation;
        return this;
    }

    function isSetAsset() public view returns (bool) {
        return builderData.asset != address(0);
    }

    function isSetIpToken() public view returns (bool) {
        return builderData.ipToken != address(0);
    }

    function isSetMiltonStorage() public view returns (bool) {
        return builderData.miltonStorage != address(0);
    }

    function isSetMilton() public view returns (bool) {
        return builderData.milton != address(0);
    }

    function isSetStanley() public view returns (bool) {
        return builderData.stanley != address(0);
    }

    function build() public returns (ItfJoseph) {
        vm.startPrank(_owner);
        ERC1967Proxy proxy = _constructProxy(_buildJosephImplementation());
        ItfJoseph joseph = ItfJoseph(address(proxy));
        vm.stopPrank();
        delete builderData;
        return joseph;
    }

    function _buildJosephImplementation() internal returns (address josephImpl) {
        if (builderData.josephImplementation != address(0)) {
            josephImpl = builderData.josephImplementation;
        } else {
            if (builderData.assetType == BuilderUtils.AssetType.DAI) {
                josephImpl = address(new ItfJoseph(18, false));
            } else if (builderData.assetType == BuilderUtils.AssetType.USDT) {
                josephImpl = address(new ItfJoseph(6, false));
            } else if (builderData.assetType == BuilderUtils.AssetType.USDC) {
                josephImpl = address(new ItfJoseph(6, false));
            } else {
                revert("Asset type not supported");
            }
        }
    }

    function _constructProxy(address impl) internal returns (ERC1967Proxy proxy) {
        proxy = new ERC1967Proxy(
            address(impl),
            abi.encodeWithSignature(
                "initialize(bool,address,address,address,address,address)",
                builderData.paused,
                builderData.asset,
                builderData.ipToken,
                builderData.milton,
                builderData.miltonStorage,
                builderData.stanley
            )
        );
    }
}

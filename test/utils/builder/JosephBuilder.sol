import "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import "../../../contracts/itf/ItfJoseph.sol";
import "../../../contracts/itf/ItfJosephDai.sol";
import "../../../contracts/itf/ItfJosephUsdc.sol";
import "../../../contracts/itf/ItfJosephUsdt.sol";

import "./BuilderUtils.sol";
import "forge-std/Test.sol";
import "./IporProtocolBuilder.sol";

contract JosephBuilder is Test{
    struct BuilderData {
        BuilderUtils.AssetType assetType;
        bool paused;
        address asset;
        address ipToken;
        address milton;
        address miltonStorage;
        address stanley;
    }

    BuilderData private builderData;

    address private _owner;
    IporProtocolBuilder private _iporProtocolBuilder;

    constructor(address owner, IporProtocolBuilder iporProtocolBuilder) {
        _owner = owner;
        _iporProtocolBuilder = iporProtocolBuilder;
    }

    function and() public view returns (IporProtocolBuilder) {
        return _iporProtocolBuilder;
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

    function build() public returns (ItfJoseph) {
        if (builderData.assetType == BuilderUtils.AssetType.DAI) {
            return _buildDAI();
        } else if (builderData.assetType == BuilderUtils.AssetType.USDC) {
            return _buildUSDC();
        } else if (builderData.assetType == BuilderUtils.AssetType.USDT) {
            return _buildUSDT();
        } else {
            revert("Unsupported asset type");
        }
    }

    function _buildDAI() internal returns (ItfJoseph) {
        vm.startPrank(_owner);
        ERC1967Proxy proxy = _constructProxy(address(new ItfJosephDai()));
        ItfJoseph joseph = ItfJoseph(address(proxy));
        vm.stopPrank();
        return joseph;
    }

    function _buildUSDC() internal returns (ItfJoseph) {
        vm.startPrank(_owner);
        ERC1967Proxy proxy = _constructProxy(address(new ItfJosephUsdc()));
        ItfJoseph joseph =  ItfJoseph(address(proxy));
        vm.stopPrank();
        return joseph;
    }

    function _buildUSDT() internal returns (ItfJoseph) {
        vm.startPrank(_owner);
        ERC1967Proxy proxy = _constructProxy(address(new ItfJosephUsdt()));
        ItfJoseph joseph =  ItfJoseph(address(proxy));
        vm.stopPrank();
        return joseph;
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

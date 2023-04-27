import "../../../contracts/itf/ItfMilton.sol";
import "../../../contracts/itf/ItfMiltonUsdt.sol";
import "../../../contracts/itf/ItfMiltonUsdc.sol";
import "../../../contracts/itf/ItfMiltonDai.sol";
import "../../../contracts/mocks/tokens/MockTestnetToken.sol";
import "./AssetBuilder.sol";
import "./BuilderUtils.sol";
import "ipor-protocol/contracts/itf/ItfMiltonDai.sol";
import "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";

contract MiltonBuilder {
    struct BuilderData {
        BuilderUtils.AssetType assetType;
        address asset;
        address iporOracle;
        address miltonStorage;
        address miltonSpreadModel;
        address stanley;
    }

    BuilderData private builderData;

    constructor() {
        AssetBuilder assetBuilder = new AssetBuilder();
        MockTestnetToken assetDAI = assetBuilder.build();

        builderData = BuilderData(
            AssetType.DAI,
            address(assetDAI),
            address(0),
            address(0),
            address(0),
            address(0)
        );
    }

    function build() public returns (ItfMilton) {
        if (builderData.assetType == AssetType.DAI) {
            return _buildMiltonDAI();
        } else if (builderData.assetType == AssetType.USDT) {
            return _buildMiltonUSDT();
        } else if (builderData.assetType == AssetType.USDC) {
            return _buildMiltonUSDC();
        } else {
            revert("Asset type not supported");
        }
    }

    function _buildMiltonDAI() internal returns (ItfMiltonDai) {
        ERC1967Proxy miltonProxy = _constructProxy(address(new ItfMiltonDai()));
        return ItfMiltonDai(address(miltonProxy));
    }

    function _buildMiltonUSDT() internal returns (ItfMiltonUsdt) {
        ERC1967Proxy miltonProxy = _constructProxy(address(new ItfMiltonUsdt()));
        return ItfMiltonUsdt(address(miltonProxy));
    }

    function _buildMiltonUSDC() internal returns (ItfMiltonUsdc) {
        ERC1967Proxy miltonProxy = _constructProxy(address(new ItfMiltonUsdc()));
        return ItfMiltonUsdc(address(miltonProxy));
    }

    function _constructProxy(address impl) internal returns (ERC1967Proxy proxy) {
        proxy = new ERC1967Proxy(
            impl,
            abi.encodeWithSignature(
                "initialize(bool,address,address,address,address,address)",
                false,
                builderData.asset,
                builderData.iporOracle,
                builderData.miltonStorage,
                builderData.miltonSpreadModel,
                builderData.stanley
            )
        );
    }
}

import "../../../contracts/itf/ItfMilton.sol";
import "../../../contracts/itf/ItfMiltonUsdt.sol";
import "../../../contracts/itf/ItfMiltonUsdc.sol";
import "../../../contracts/itf/ItfMiltonDai.sol";
import "../../../contracts/itf/ItfStanley.sol";
import "../../../contracts/mocks/tokens/MockTestnetToken.sol";
import "../../../contracts/mocks/MockIporWeighted.sol";
import "../../../contracts/mocks/spread/MockSpreadModel.sol";
import "../../../contracts/mocks/milton/MockCase0MiltonDai.sol";
import "../../../contracts/mocks/milton/MockCase0MiltonUsdc.sol";
import "../../../contracts/mocks/milton/MockCase0MiltonUsdt.sol";
import "../../../contracts/mocks/milton/MockCase6MiltonDai.sol";
import "../../../contracts/mocks/milton/MockCase6MiltonUsdc.sol";
import "../../../contracts/mocks/milton/MockCase6MiltonUsdt.sol";

import "./AssetBuilder.sol";
import "./BuilderUtils.sol";
import "./IporOracleBuilder.sol";
import "./IporWeightedBuilder.sol";
import "./MockSpreadBuilder.sol";
import "./MiltonStorageBuilder.sol";
import "../../../contracts/itf/ItfIporOracle.sol";
import "../../../contracts/itf/ItfMiltonDai.sol";
import "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import "forge-std/Test.sol";
import "./IporProtocolBuilder.sol";

contract MiltonBuilder is Test {
    struct BuilderData {
        BuilderUtils.AssetType assetType;
        address asset;
        address iporOracle;
        address miltonStorage;
        address spreadModel;
        address stanley;
        address miltonImplementation;
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

    function withAssetType(BuilderUtils.AssetType assetType) public returns (MiltonBuilder) {
        builderData.assetType = assetType;
        return this;
    }

    function withMiltonImplementation(address miltonImplementation) public returns (MiltonBuilder) {
        builderData.miltonImplementation = miltonImplementation;
        return this;
    }

    function withAsset(address asset) public returns (MiltonBuilder) {
        builderData.asset = asset;
        return this;
    }

    function withIporOracle(address iporOracle) public returns (MiltonBuilder) {
        builderData.iporOracle = iporOracle;
        return this;
    }

    function withMiltonStorage(address miltonStorage) public returns (MiltonBuilder) {
        builderData.miltonStorage = miltonStorage;
        return this;
    }

    function withSpreadModel(address spreadModel) public returns (MiltonBuilder) {
        builderData.spreadModel = spreadModel;
        return this;
    }

    function withStanley(address stanley) public returns (MiltonBuilder) {
        builderData.stanley = stanley;
        return this;
    }

    function build() public returns (ItfMilton) {
        vm.startPrank(_owner);
        ERC1967Proxy miltonProxy = _constructProxy(_buildMiltonImplementation());
        ItfMilton milton = ItfMilton(address(miltonProxy));
        vm.stopPrank();
        return milton;
    }

    function _buildMiltonImplementation() internal returns (address miltonImpl) {
        if (builderData.miltonImplementation != address(0)) {
            miltonImpl = builderData.miltonImplementation;
        } else {
            if (builderData.assetType == BuilderUtils.AssetType.DAI) {
                miltonImpl = address(new ItfMiltonDai());
            } else if (builderData.assetType == BuilderUtils.AssetType.USDT) {
                miltonImpl = address(new ItfMiltonUsdt());
            } else if (builderData.assetType == BuilderUtils.AssetType.USDC) {
                miltonImpl = address(new ItfMiltonUsdc());
            } else {
                revert("Asset type not supported");
            }
        }
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
                builderData.spreadModel,
                builderData.stanley
            )
        );
    }
}

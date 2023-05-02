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

contract MiltonBuilder is Test {
    struct BuilderData {
        BuilderUtils.AssetType assetType;
        BuilderUtils.MiltonTestCase miltonTestCase;
        address asset;
        address iporOracle;
        address miltonStorage;
        address spreadModel;
        address stanley;
    }

    BuilderData private builderData;
    address private _owner;

    constructor(address owner) {
        _owner = owner;
    }

    function withAssetType(BuilderUtils.AssetType assetType) public returns (MiltonBuilder) {
        builderData.assetType = assetType;
        return this;
    }

    function withMiltonTestCase(BuilderUtils.MiltonTestCase miltonTestCase)
        public
        returns (MiltonBuilder)
    {
        builderData.miltonTestCase = miltonTestCase;
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
        if (builderData.assetType == BuilderUtils.AssetType.DAI) {
            return _buildMiltonDAI();
        } else if (builderData.assetType == BuilderUtils.AssetType.USDT) {
            return _buildMiltonUSDT();
        } else if (builderData.assetType == BuilderUtils.AssetType.USDC) {
            return _buildMiltonUSDC();
        } else {
            revert("Asset type not supported");
        }
    }

    function _buildMiltonDAI() internal returns (ItfMiltonDai) {
        vm.startPrank(_owner);
        ERC1967Proxy miltonProxy = _constructProxy(address(_buildMiltonDaiImplementation()));
        ItfMiltonDai milton = ItfMiltonDai(address(miltonProxy));
        vm.stopPrank();
        return milton;
    }

    function _buildMiltonUSDT() internal returns (ItfMiltonUsdt) {
        vm.startPrank(_owner);
        ERC1967Proxy miltonProxy = _constructProxy(address(_buildMiltonUsdtImplementation()));
        ItfMiltonUsdt milton = ItfMiltonUsdt(address(miltonProxy));
        vm.stopPrank();
        return milton;
    }

    function _buildMiltonUSDC() internal returns (ItfMiltonUsdc) {
        vm.startPrank(_owner);
        ERC1967Proxy miltonProxy = _constructProxy(address(_buildMiltonUsdcImplementation()));
        ItfMiltonUsdc milton = ItfMiltonUsdc(address(miltonProxy));
        vm.stopPrank();
        return milton;
    }

    function _buildMiltonUsdtImplementation() internal returns (ItfMilton) {
        ItfMilton milton;

        if (builderData.miltonTestCase == BuilderUtils.MiltonTestCase.DEFAULT) {
            milton = new ItfMiltonUsdt();
        } else if (builderData.miltonTestCase == BuilderUtils.MiltonTestCase.CASE0) {
            milton = new MockCase0MiltonUsdt();
        } else if (builderData.miltonTestCase == BuilderUtils.MiltonTestCase.CASE6) {
            milton = new MockCase6MiltonUsdt();
        } else {
            milton = new ItfMiltonUsdt();
        }
        return milton;
    }

    function _buildMiltonUsdcImplementation() internal returns (ItfMilton) {
        ItfMilton milton;

        if (builderData.miltonTestCase == BuilderUtils.MiltonTestCase.DEFAULT) {
            milton = new ItfMiltonUsdc();
        } else if (builderData.miltonTestCase == BuilderUtils.MiltonTestCase.CASE0) {
            milton = new MockCase0MiltonUsdc();
        } else if (builderData.miltonTestCase == BuilderUtils.MiltonTestCase.CASE6) {
            milton = new MockCase6MiltonUsdc();
        } else {
            milton = new ItfMiltonUsdc();
        }
        return milton;
    }

    function _buildMiltonDaiImplementation() internal returns (ItfMilton) {
        ItfMilton milton;

        if (builderData.miltonTestCase == BuilderUtils.MiltonTestCase.DEFAULT) {
            milton = new ItfMiltonDai();
        } else if (builderData.miltonTestCase == BuilderUtils.MiltonTestCase.CASE0) {
            milton = new MockCase0MiltonDai();
        } else if (builderData.miltonTestCase == BuilderUtils.MiltonTestCase.CASE6) {
            milton = new MockCase6MiltonDai();
        } else {
            milton = new ItfMiltonDai();
        }
        return milton;
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

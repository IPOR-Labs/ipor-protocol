import "../../../contracts/mocks/tokens/MockTestnetToken.sol";
import "../../../contracts/mocks/spread/MockSpreadModel.sol";
import "../../../contracts/tokens/IpToken.sol";
import "../../../contracts/itf/ItfIporOracle.sol";
import "../../../contracts/itf/ItfStanley.sol";
import "../../../contracts/itf/ItfMilton.sol";
import "../../../contracts/itf/ItfJoseph.sol";
import "../../../contracts/amm/MiltonStorage.sol";
import "./AssetBuilder.sol";
import "./IpTokenBuilder.sol";
import "./IporOracleBuilder.sol";
import "./MiltonStorageBuilder.sol";
import "./MockSpreadBuilder.sol";
import "./StanleyBuilder.sol";
import "./MiltonBuilder.sol";
import "./JosephBuilder.sol";
import "forge-std/Test.sol";

contract IporProtocolBuilder is Test {
    struct IporProtocol {
        MockTestnetToken asset;
        IpToken ipToken;
        IvToken ivToken;
        ItfIporOracle iporOracle;
        MockIporWeighted iporWeighted;
        MiltonStorage miltonStorage;
        MockSpreadModel spreadModel;
        ItfStanley stanley;
        ItfMilton milton;
        ItfJoseph joseph;
    }

    AssetBuilder public assetBuilder;
    IpTokenBuilder public ipTokenBuilder;
    IvTokenBuilder public ivTokenBuilder;
    IporOracleBuilder public iporOracleBuilder;
    IporWeightedBuilder public iporWeightedBuilder;
    MiltonStorageBuilder public miltonStorageBuilder;
    MockSpreadBuilder public spreadBuilder;
    StanleyBuilder public stanleyBuilder;
    MiltonBuilder public miltonBuilder;
    JosephBuilder public josephBuilder;

    address private _owner;

    constructor(address owner) {
        _owner = owner;
        assetBuilder = new AssetBuilder(owner, this);
        ipTokenBuilder = new IpTokenBuilder(owner, this);
        ivTokenBuilder = new IvTokenBuilder(owner, this);
        iporOracleBuilder = new IporOracleBuilder(owner, this);
        iporWeightedBuilder = new IporWeightedBuilder(owner, this);
        miltonStorageBuilder = new MiltonStorageBuilder(owner, this);
        spreadBuilder = new MockSpreadBuilder(owner, this);
        stanleyBuilder = new StanleyBuilder(owner, this);
        miltonBuilder = new MiltonBuilder(owner, this);
        josephBuilder = new JosephBuilder(owner, this);
    }

    function daiBuilder() public returns (IporProtocolBuilder) {
        assetBuilder.withAssetType(BuilderUtils.AssetType.DAI);
        miltonBuilder.withAssetType(BuilderUtils.AssetType.DAI);
        josephBuilder.withAssetType(BuilderUtils.AssetType.DAI);
        stanleyBuilder.withAssetType(BuilderUtils.AssetType.DAI);

        assetBuilder.withDAI();

        return this;
    }

    function usdtBuilder() public returns (IporProtocolBuilder) {
        assetBuilder.withAssetType(BuilderUtils.AssetType.USDT);
        miltonBuilder.withAssetType(BuilderUtils.AssetType.USDT);
        josephBuilder.withAssetType(BuilderUtils.AssetType.USDT);
        stanleyBuilder.withAssetType(BuilderUtils.AssetType.USDT);

        assetBuilder.withUSDT();

        return this;
    }

    function usdcBuilder() public returns (IporProtocolBuilder) {
        assetBuilder.withAssetType(BuilderUtils.AssetType.USDC);
        miltonBuilder.withAssetType(BuilderUtils.AssetType.USDC);
        josephBuilder.withAssetType(BuilderUtils.AssetType.USDC);
        stanleyBuilder.withAssetType(BuilderUtils.AssetType.USDC);

        assetBuilder.withUSDC();

        return this;
    }

    function asset() public view returns (AssetBuilder) {
        return assetBuilder;
    }

    function ipToken() public view returns (IpTokenBuilder) {
        return ipTokenBuilder;
    }

    function ivToken() public view returns (IvTokenBuilder) {
        return ivTokenBuilder;
    }

    function iporOracle() public view returns (IporOracleBuilder) {
        return iporOracleBuilder;
    }

    function spread() public view returns (MockSpreadBuilder) {
        return spreadBuilder;
    }

    function milton() public view returns (MiltonBuilder) {
        return miltonBuilder;
    }

    function joseph() public view returns (JosephBuilder) {
        return josephBuilder;
    }

    function stanley() public view returns (StanleyBuilder) {
        return stanleyBuilder;
    }

    function and() public view returns (IporProtocolBuilder) {
        return this;
    }

    function build() public returns (IporProtocol memory iporProtocol) {
        MockTestnetToken asset = assetBuilder.build();

        ipTokenBuilder.withAsset(address(asset));
        IpToken ipToken = ipTokenBuilder.build();

        ivTokenBuilder.withAsset(address(asset));
        IvToken ivToken = ivTokenBuilder.build();

        iporOracleBuilder.withAsset(address(asset));
        ItfIporOracle iporOracle = iporOracleBuilder.build();

        iporWeightedBuilder.withIporOracle(address(iporOracle));

        MockIporWeighted iporWeighted = iporWeightedBuilder.build();
        MiltonStorage miltonStorage = miltonStorageBuilder.build();
        MockSpreadModel spreadModel = spreadBuilder.build();

        stanleyBuilder.withAsset(address(asset));
        stanleyBuilder.withIvToken(address(ivToken));
        ItfStanley stanley = stanleyBuilder.build();

        miltonBuilder.withAsset(address(asset));
        miltonBuilder.withIporOracle(address(iporOracle));
        miltonBuilder.withMiltonStorage(address(miltonStorage));
        miltonBuilder.withStanley(address(stanley));
        miltonBuilder.withSpreadModel(address(spreadModel));
        ItfMilton milton = miltonBuilder.build();

        josephBuilder.withAsset(address(asset));
        josephBuilder.withIpToken(address(ipToken));
        josephBuilder.withMiltonStorage(address(miltonStorage));
        josephBuilder.withMilton(address(milton));
        josephBuilder.withStanley(address(stanley));
        ItfJoseph joseph = josephBuilder.build();

        vm.startPrank(address(_owner));
        iporOracle.setIporAlgorithmFacade(address(iporWeighted));

        ivToken.setStanley(address(stanley));

        miltonStorage.setMilton(address(milton));
        stanley.setMilton(address(milton));
        milton.setupMaxAllowanceForAsset(address(stanley));

        ipToken.setJoseph(address(joseph));
        miltonStorage.setJoseph(address(joseph));
        milton.setJoseph(address(joseph));
        milton.setupMaxAllowanceForAsset(address(joseph));

        joseph.setMaxLiquidityPoolBalance(1000000000);
        joseph.setMaxLpAccountContribution(1000000000);

        vm.stopPrank();

        iporProtocol = IporProtocol(
            asset,
            ipToken,
            ivToken,
            iporOracle,
            iporWeighted,
            miltonStorage,
            spreadModel,
            stanley,
            milton,
            joseph
        );
    }
}

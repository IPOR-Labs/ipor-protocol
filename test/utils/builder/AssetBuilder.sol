import "./BuilderUtils.sol";
import "./IporProtocolBuilder.sol";
import "../../../contracts/mocks/tokens/MockTestnetToken.sol";
import "../../utils/TestConstants.sol";
import "forge-std/Test.sol";

contract AssetBuilder is Test {
    struct BuilderData {
        BuilderUtils.AssetType assetType;
        string name;
        string symbol;
        uint256 initialSupply;
        uint8 decimals;
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

    function withAssetType(BuilderUtils.AssetType assetType) public returns (AssetBuilder) {
        builderData.assetType = assetType;
        return this;
    }

    function withName(string memory name) public returns (AssetBuilder) {
        builderData.name = name;
        return this;
    }

    function withSymbol(string memory symbol) public returns (AssetBuilder) {
        builderData.symbol = symbol;
        return this;
    }

    function withInitialSupply(uint256 initialSupply) public returns (AssetBuilder) {
        builderData.initialSupply = initialSupply;
        return this;
    }

    function withDecimals(uint8 decimals) public returns (AssetBuilder) {
        builderData.decimals = decimals;
        return this;
    }

    function withUSDT() public returns (AssetBuilder) {
        builderData.assetType = BuilderUtils.AssetType.USDT;
        builderData.name = "Mocked USDT";
        builderData.symbol = "USDT";
        builderData.decimals = 6;
        builderData.initialSupply = TestConstants.TOTAL_SUPPLY_6_DECIMALS;
        return this;
    }

    function withUSDC() public returns (AssetBuilder) {
        builderData.assetType = BuilderUtils.AssetType.USDC;
        builderData.name = "Mocked USDC";
        builderData.symbol = "USDC";
        builderData.decimals = 6;
        builderData.initialSupply = TestConstants.TOTAL_SUPPLY_6_DECIMALS;
        return this;
    }

    function withDAI() public returns (AssetBuilder) {
        builderData.assetType = BuilderUtils.AssetType.DAI;
        builderData.name = "Mocked DAI";
        builderData.symbol = "DAI";
        builderData.decimals = 18;
        builderData.initialSupply = TestConstants.TOTAL_SUPPLY_18_DECIMALS;
        return this;
    }

    function build() public returns (MockTestnetToken) {
        vm.startPrank(_owner);
        MockTestnetToken token = new MockTestnetToken(
            builderData.name,
            builderData.symbol,
            builderData.initialSupply,
            builderData.decimals
        );
        vm.stopPrank();
        return token;
    }
}

import "./BuilderUtils.sol";
import "../../../contracts/mocks/tokens/MockTestnetToken.sol";
import "../../utils/TestConstants.sol";

contract AssetBuilder {
    struct BuilderData {
        BuilderUtils.AssetType assetType;
        string memory name;
        string memory symbol;
        uint256 initialSupply;
        uint8 decimals;
    }

    BuilderData private builderData;

    constructor() {
        builderData = withDAI();
    }

    function withUSDT() public returns (AssetBuilder) {
        builderData.assetType = AssetType.USDT;
        builderData.name = "Mocked USDT";
        builderData.symbol = "USDT";
        builderData.decimals = 6;
        builderData.initialSupply = TestConstants.TOTAL_SUPPLY_6_DECIMALS;
        return this;
    }

    function withUSDC() public returns (AssetBuilder) {
        builderData.assetType = AssetType.USDC;
        builderData.name = "Mocked USDC";
        builderData.symbol = "USDC";
        builderData.decimals = 6;
        builderData.initialSupply = TestConstants.TOTAL_SUPPLY_6_DECIMALS;
        return this;
    }

    function withDAI() public returns (AssetBuilder) {
        builderData.assetType = AssetType.DAI;
        builderData.name = "Mocked DAI";
        builderData.symbol = "DAI";
        builderData.decimals = 18;
        builderData.initialSupply = TestConstants.TOTAL_SUPPLY_18_DECIMALS;
        return this;
    }

    function build() public returns (MockTestnetToken) {
        return
            new MockTestnetToken(
                builderData.name,
                builderData.symbol,
                builderData.initialSupply,
                builderData.decimals
            );
    }
}

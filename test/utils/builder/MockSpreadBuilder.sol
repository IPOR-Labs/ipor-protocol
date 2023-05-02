import "./BuilderUtils.sol";
import "../../../contracts/mocks/tokens/MockTestnetToken.sol";
import "../../../contracts/mocks/spread/MockSpreadModel.sol";
import "../../utils/TestConstants.sol";
import "forge-std/Test.sol";

contract MockSpreadBuilder is Test{
    struct BuilderData {
        uint256 quotePayFixedValue;
        uint256 quoteReceiveFixedValue;
        int256 spreadPayFixedValue;
        int256 spreadReceiveFixedValue;
    }

    BuilderData private builderData;
    address private _owner;

    constructor(address owner) {
        _owner = owner;
    }

    function withQuotePayFixedValue(uint256 quotePayFixedValue) public returns (MockSpreadBuilder) {
        builderData.quotePayFixedValue = quotePayFixedValue;
        return this;
    }

    function withQuoteReceiveFixedValue(uint256 quoteReceiveFixedValue)
        public
        returns (MockSpreadBuilder)
    {
        builderData.quoteReceiveFixedValue = quoteReceiveFixedValue;
        return this;
    }

    function withSpreadPayFixedValue(int256 spreadPayFixedValue)
        public
        returns (MockSpreadBuilder)
    {
        builderData.spreadPayFixedValue = spreadPayFixedValue;
        return this;
    }

    function withSpreadReceiveFixedValue(int256 spreadReceiveFixedValue)
        public
        returns (MockSpreadBuilder)
    {
        builderData.spreadReceiveFixedValue = spreadReceiveFixedValue;
        return this;
    }

    function withDefaultValues() public returns (MockSpreadBuilder) {
        builderData.quotePayFixedValue = 0;
        builderData.quoteReceiveFixedValue = 0;
        builderData.spreadPayFixedValue = 0;
        builderData.spreadReceiveFixedValue = 0;
        return this;
    }

    function build() public returns (MockSpreadModel) {
        vm.startPrank(_owner);
        MockSpreadModel mockSpreadModel =
            new MockSpreadModel(
                builderData.quotePayFixedValue,
                builderData.quoteReceiveFixedValue,
                builderData.spreadPayFixedValue,
                builderData.spreadReceiveFixedValue
            );
        vm.stopPrank();
        return mockSpreadModel;
    }
}

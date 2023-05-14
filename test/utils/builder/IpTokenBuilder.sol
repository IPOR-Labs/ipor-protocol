import "./BuilderUtils.sol";
import "./IporProtocolBuilder.sol";
import "../../../contracts/mocks/tokens/MockTestnetToken.sol";
import "../../utils/TestConstants.sol";
import "../../../contracts/tokens/IpToken.sol";
import "forge-std/Test.sol";

contract IpTokenBuilder is Test {
    struct BuilderData {
        string name;
        string symbol;
        address asset;
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

    function withName(string memory name) public returns (IpTokenBuilder) {
        builderData.name = name;
        return this;
    }

    function withSymbol(string memory symbol) public returns (IpTokenBuilder) {
        builderData.symbol = symbol;
        return this;
    }

    function withAsset(address asset) public returns (IpTokenBuilder) {
        builderData.asset = asset;
        return this;
    }

    function isSetAsset() public view returns (bool) {
        return builderData.asset != address(0);
    }

    function build() public returns (IpToken) {
        vm.startPrank(_owner);
        IpToken ipToken = new IpToken(builderData.name, builderData.symbol, builderData.asset);
        vm.stopPrank();
        delete builderData;
        return ipToken;
    }
}

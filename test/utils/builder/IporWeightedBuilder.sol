import "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import "../../../contracts/mocks/MockIporWeighted.sol";
import "forge-std/Test.sol";

contract IporWeightedBuilder is Test{
    struct BuilderData {
        address iporOracle;
    }

    BuilderData private builderData;
    address private _owner;

    constructor(address owner) {
        _owner = owner;
    }

    function withIporOracle(address iporOracle) public returns (IporWeightedBuilder) {
        builderData.iporOracle = iporOracle;
        return this;
    }

    function build() public returns (MockIporWeighted) {
        vm.startPrank(_owner);
        ERC1967Proxy proxy = _constructProxy(address(new MockIporWeighted()));
        MockIporWeighted iporWeighted =  MockIporWeighted(address(proxy));
        vm.stopPrank();
        return iporWeighted;
    }

    function _constructProxy(address impl) internal returns (ERC1967Proxy proxy) {
        proxy = new ERC1967Proxy(
            impl,
            abi.encodeWithSignature("initialize(address)", builderData.iporOracle)
        );
    }
}

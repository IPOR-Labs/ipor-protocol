import "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import "./BuilderUtils.sol";
import "../../../contracts/amm/MiltonStorage.sol";
import "../../../contracts/mocks/tokens/MockTestnetToken.sol";
import "../../utils/TestConstants.sol";
import "forge-std/Test.sol";
contract MiltonStorageBuilder is Test{
    address private _owner;

    constructor(address owner) {
        _owner = owner;
    }
    function build() public returns (MiltonStorage) {
        vm.startPrank(_owner);
        ERC1967Proxy proxy = _constructProxy(address(new MiltonStorage()));
        MiltonStorage miltonStorage = MiltonStorage(address(proxy));
        vm.stopPrank();
        return miltonStorage;
    }

    function _constructProxy(address impl) internal returns (ERC1967Proxy proxy) {
        proxy = new ERC1967Proxy(address(impl), abi.encodeWithSignature("initialize()", ""));
    }
}

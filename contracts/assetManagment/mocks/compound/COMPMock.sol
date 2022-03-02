pragma solidity 0.8.9;

// interfaces
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract COMPMock is ERC20 {
    constructor() ERC20("COMP", "COMP") {
        _mint(address(this), 10**25); // 10.000.000 COMP
        _mint(msg.sender, 10**22); // 10.000 COMP
    }

    function decimals() public view override returns (uint8) {
        return 18;
    }
}

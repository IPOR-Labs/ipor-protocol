pragma solidity 0.8.9;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract StakedAaveMock is ERC20 {
    address internal __aaveMock;
    uint256 internal __cooldownStartTimestamp;

    mapping(address => bool) public cooldownMapping;

    constructor(address _aaveMock) ERC20("stkAAVE", "stkAAVE") {
        __aaveMock = _aaveMock;
        _mint(msg.sender, 10**24); // 1.000.000 aDAI
    }

    function redeem(address to, uint256 amount) external {
        // require(cooldownMapping[msg.sender], "Not CoolDown");
        _burn(to, amount);
        IERC20(__aaveMock).transfer(to, amount);
    }

    function cooldown() external {
        cooldownMapping[msg.sender] = true;
    }

    function setCooldowns() public {
        __cooldownStartTimestamp = block.timestamp - (10 * 24 * 60 * 60);
    }

    function stakersCooldowns(address _addr) public view returns (uint256) {
        return __cooldownStartTimestamp;
    }
}

pragma solidity 0.8.9;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

//TODO: remove
contract MockDAI is ERC20 {
    constructor() ERC20("DAI", "DAI") {
        _mint(address(this), 10**24); // 1.000.000 DAI
        _mint(msg.sender, 10**22); // 10.000 DAI
    }
}

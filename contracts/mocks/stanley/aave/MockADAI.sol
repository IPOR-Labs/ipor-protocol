// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.9;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "../../../vault/interfaces/aave/AToken.sol";

contract MockADAI is ERC20, AToken {
    address private _dai;
    address private _controller;
    uint256 private _price = 10**18;

    constructor(address dai, address tokenOwner) ERC20("aDAI", "aDAI") {
        _dai = dai;
        _mint(address(this), 10**24); // 1.000.000 aDAI
        _mint(tokenOwner, 10**23); // 100.000 aDAI
    }

    function UNDERLYING_ASSET_ADDRESS() external view returns (address) {
        return _dai;
    }

    function redeem(uint256 amount) external {
        _burn(msg.sender, amount);
        require(IERC20(_dai).transfer(msg.sender, amount), "Error during transfer"); // 1 DAI
    }

    function setPriceForTest(uint256 price) external {
        _price = price;
    }

    function setController(address controller) external {
        _controller = controller;
    }

    function burn(
        address user,
        address receiverOfUnderlying,
        uint256 amount,
        uint256 index
    ) external override {
        _burn(user, amount);
        require(IERC20(_dai).transfer(receiverOfUnderlying, amount), "Error during transfer");
    }

    function getIncentivesController() external view returns (address) {
        return _controller;
    }

    function mint(address account, uint256 amount) external {
        _mint(account, amount);
    }
}

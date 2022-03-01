pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "../../interfaces/aave/AToken.sol";

contract aDAIMock is ERC20, AToken {
  address public dai;
  address public controller;
  uint256 public price = 10**18;

  constructor(address _dai, address tokenOwner)
    ERC20('aDAI', 'aDAI') public {
    dai = _dai;
    _mint(address(this), 10**24); // 1.000.000 aDAI
    _mint(tokenOwner, 10**23); // 100.000 aDAI
  }

  function UNDERLYING_ASSET_ADDRESS() external view returns(address) {
    return dai;
  }
  function redeem(uint256 amount) external override {
    _burn(msg.sender, amount);
    require(IERC20(dai).transfer(msg.sender, amount), "Error during transfer"); // 1 DAI
  }
  function setPriceForTest(uint256 _price) external {
    price = _price;
  }
  function setController(address _controller) external {
    controller = _controller;
  }

  function burn(address user, address receiverOfUnderlying, uint256 amount, uint256 index) external override {
    _burn(user, amount);
    require(IERC20(dai).transfer(receiverOfUnderlying, amount), "Error during transfer");
  }
  function getIncentivesController() external override view returns (address) {
    return controller;
  }
}

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "../../interfaces/compound/Comptroller.sol";

contract ComptrollerMock is Comptroller {
  address public compAddr;
  address public cTokenAddr;
  uint256 private amount;
  constructor(address _comp, address _cToken) public {
    compAddr = _comp;
    cTokenAddr = _cToken;
  }
  function setAmount(uint256 _amount) external {
    amount = _amount;
  }

  // This contract should have COMP inside
  function claimComp(address[] calldata, address[] calldata cTokens, bool borrowers, bool suppliers) external override {
    require(cTokenAddr == cTokens[0], 'Wrong cToken');
    require(!borrowers && suppliers, 'Only suppliers should be true');
    IERC20(compAddr).transfer(msg.sender, amount > IERC20(compAddr).balanceOf(address(this)) ? 0 : amount);
  }

  function claimComp(address _sender) external override{
    IERC20(compAddr).transfer(_sender, amount > IERC20(compAddr).balanceOf(address(this)) ? 0 : amount);
  }

  function claimComp(address _sender, address[] memory assets) external {
    IERC20(compAddr).transfer(_sender, amount > IERC20(compAddr).balanceOf(address(this)) ? 0 : amount);
  }

  function compSpeeds(address _cToken) external view override returns (uint256) {

  }
}

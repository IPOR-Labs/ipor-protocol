pragma solidity ^0.8.0;

contract AaveVariableDebtTokenMock {
  uint256 public _scaledTotalSupply;

  constructor(uint256 value) public {
    _scaledTotalSupply = value;
  }

  function scaledTotalSupply() external view returns (uint256) {
    return _scaledTotalSupply;
  }
}

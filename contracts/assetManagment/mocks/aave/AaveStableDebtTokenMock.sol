pragma solidity ^0.8.0;

contract AaveStableDebtTokenMock {
  uint256 public totalStableDebt;
  uint256 public avgStableRate;

  constructor(uint256 debt, uint256 rate) public {
    totalStableDebt = debt;
    avgStableRate = rate;
  }

  function getTotalSupplyAndAvgRate() external view returns (uint256, uint256) {
    return (totalStableDebt, avgStableRate);
  }
}

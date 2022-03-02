pragma solidity 0.8.9;

contract AaveStableDebtTokenMock {
    uint256 internal _totalStableDebt;
    uint256 internal _avgStableRate;

    constructor(uint256 debt, uint256 rate) public {
        _totalStableDebt = debt;
        _avgStableRate = rate;
    }

    function getTotalSupplyAndAvgRate()
        external
        view
        returns (uint256, uint256)
    {
        return (_totalStableDebt, _avgStableRate);
    }
}

pragma solidity 0.8.9;

contract MockAaveVariableDebtToken {
    uint256 private _scaledTotalSupply;

    constructor(uint256 value) {
        _scaledTotalSupply = value;
    }

    function scaledTotalSupply() external view returns (uint256) {
        return _scaledTotalSupply;
    }
}

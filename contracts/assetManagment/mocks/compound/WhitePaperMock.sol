pragma solidity ^0.8.0;

import "../../interfaces/compound/WhitePaperInterestRateModel.sol";

contract WhitePaperMock is WhitePaperInterestRateModel {
    uint256 internal _borrowRate;
    uint256 internal _supplyRate;
    uint256 public override baseRate;
    uint256 public override multiplier;
    uint256 public override blocksPerYear;

    constructor() {
        baseRate = 50000000000000000;
        multiplier = 120000000000000000;
        blocksPerYear = 2102400;
    }

    function getBorrowRate(
        uint256 cash,
        uint256 borrows,
        uint256 _reserves
    ) external view override returns (uint256, uint256) {}

    function setSupplyRate(uint256 rate) public {
        _supplyRate = rate;
    }

    function getSupplyRate(
        uint256,
        uint256,
        uint256,
        uint256
    ) external view override returns (uint256) {
        return _supplyRate;
    }

    function dsrPerBlock() external view override returns (uint256) {}
}

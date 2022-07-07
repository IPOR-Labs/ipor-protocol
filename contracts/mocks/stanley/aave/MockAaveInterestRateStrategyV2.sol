// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.15;

contract AaveInterestRateMockStrategyV2 {
    uint256 private _borrowRate;
    uint256 private _supplyRate;

    function getBaseVariableBorrowRate() external view returns (uint256) {
        return _borrowRate;
    }

    function calculateInterestRates(
        address,
        uint256,
        uint256,
        uint256,
        uint256,
        uint256
    )
        external
        view
        returns (
            uint256,
            uint256,
            uint256
        )
    {
        return (_supplyRate, _borrowRate, _borrowRate);
    }

    // mocked methods
    function setSupplyRate(uint256 supplyRate) external {
        _supplyRate = supplyRate;
    }

    function setBorrowRate(uint256 borrowRate) external {
        _borrowRate = borrowRate;
    }
}

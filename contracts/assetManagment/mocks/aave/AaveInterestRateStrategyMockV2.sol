pragma solidity 0.8.9;

// interfaces
//TODO: [mario] never used - what for it is?
import "../../interfaces/aave/AaveInterestRateStrategy.sol";

contract AaveInterestRateStrategyMockV2 {
    uint256 internal _borrowRate;
    uint256 internal _supplyRate;

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

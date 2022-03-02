pragma solidity 0.8.9;

//TODO: [mario] where is implementation of this? Where it is used?
// TODO: If not required please remove, double check if you can remove it
interface AaveInterestRateStrategy {
    function getBaseVariableBorrowRate() external view returns (uint256);

    function calculateInterestRates(
        address reserve,
        uint256 utilizationRate,
        uint256 totalBorrowsStable,
        uint256 totalBorrowsVariable,
        uint256 averageStableBorrowRate
    )
        external
        view
        returns (
            uint256 liquidityRate,
            uint256 stableBorrowRate,
            uint256 variableBorrowRate
        );
}

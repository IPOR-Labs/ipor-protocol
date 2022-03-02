pragma solidity ^0.8.0;

interface AToken {
    function getIncentivesController() external view returns (address);

    function redeem(uint256 amount) external;

    function burn(
        address user,
        address receiverOfUnderlying,
        uint256 amount,
        uint256 index
    ) external;
}

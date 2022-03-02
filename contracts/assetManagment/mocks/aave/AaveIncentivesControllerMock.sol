pragma solidity 0.8.9;

// interfaces
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "../../interfaces/aave/IAaveIncentivesController.sol";

contract AaveIncentivesControllerMock is IAaveIncentivesController {
    uint256 private _rewards;
    address private _stkAaveMock;

    constructor(address stkAaveMock) {
        _stkAaveMock = stkAaveMock;
    }

    function setRewards(uint256 rewards) external {
        _rewards = rewards;
    }

    function claimRewards(
        address[] calldata,
        uint256 amount,
        address to
    ) external override returns (uint256) {
        // require(amount == rewards, 'Rewards are different');
        IERC20(_stkAaveMock).transfer(to, 100e18);
        return amount;
    }

    function getUserUnclaimedRewards(address)
        external
        view
        override
        returns (uint256)
    {
        return _rewards;
    }
}

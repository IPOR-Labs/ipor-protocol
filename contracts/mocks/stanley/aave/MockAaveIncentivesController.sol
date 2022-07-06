// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.14;

// interfaces
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "../../../vault/interfaces/aave/IAaveIncentivesController.sol";

contract MockAaveIncentivesController is IAaveIncentivesController {
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
        // IERC20(_stkAaveMock).transfer(to, 100e18);
        return amount;
    }

    function getUserUnclaimedRewards(address) external view override returns (uint256) {
        return _rewards;
    }
}

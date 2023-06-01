// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.16;

// interfaces
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "../../../libraries/errors/IporErrors.sol";
import "../../../vault/interfaces/aave/IAaveIncentivesController.sol";

contract MockAaveIncentivesController is IAaveIncentivesController {
    uint256 private _rewards;
    address private _stkAaveMock;

    constructor(address stkAaveMock) {
        require(stkAaveMock != address(0), string.concat(IporErrors.WRONG_ADDRESS, " stkAAVE address cannot be 0"));

        _stkAaveMock = stkAaveMock;
    }

    function setRewards(uint256 rewards) external {
        _rewards = rewards;
    }

    function claimRewards(
        address[] calldata,
        uint256 amount,
        address to
    ) external pure override returns (uint256) {
        require(to != address(0));
        // require(amount == rewards, 'Rewards are different');
        // IERC20(_stkAaveMock).transfer(to, 100e18);
        return amount;
    }

    function getUserUnclaimedRewards(address) external view override returns (uint256) {
        return _rewards;
    }
}

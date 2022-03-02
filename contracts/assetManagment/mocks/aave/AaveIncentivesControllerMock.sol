pragma solidity ^0.8.0;

// interfaces
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "../../interfaces/aave/IAaveIncentivesController.sol";

contract AaveIncentivesControllerMock is IAaveIncentivesController {
  uint256 public rewards;
  address public stkAaveMock;

  constructor(address _stkAaveMock) public {
    stkAaveMock = _stkAaveMock;
  }

  function _setRewards(uint256 _rewards) external {
    rewards = _rewards;
  }

  function claimRewards(
    address[] calldata,
    uint256 amount,
    address to
  ) external override returns (uint256) {
    // require(amount == rewards, 'Rewards are different');
    IERC20(stkAaveMock).transfer(to, 100e18);
    return amount;
  }

  function getUserUnclaimedRewards(address) external override view returns (uint256) {
    return rewards;
  }

  function getAssetData(address asset) external override view returns (uint256, uint256, uint256) {

  }
  function getRewardsBalance(address[] calldata assets, address user) external override view returns(uint256) {
    
  }

}

//solhint-disable
// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@ipor-protocol/contracts/libraries/errors/IporErrors.sol";

contract MockStakedAave is ERC20 {
    address private _aaveMock;
    uint256 private _cooldownStartTimestamp;

    mapping(address => bool) public cooldownMapping;

    constructor(address aaveMock) ERC20("stkAAVE", "stkAAVE") {
        require(aaveMock != address(0), string.concat(IporErrors.WRONG_ADDRESS, " AAVE asset address cannot be 0"));

        _aaveMock = aaveMock;
        _mint(msg.sender, 10**24); // 1.000.000 aDAI
        _cooldownStartTimestamp = block.timestamp - (10 * 24 * 60 * 60);
    }

    function redeem(address to, uint256 amount) external {
        // require(cooldownMapping[msg.sender], "Not CoolDown");
        _burn(to, amount);
        IERC20(_aaveMock).transfer(to, amount);
    }

    function cooldown() external {
        cooldownMapping[msg.sender] = true;
    }

    function setCooldowns() external {
        _cooldownStartTimestamp = block.timestamp - (10 * 24 * 60 * 60);
    }

    function stakersCooldowns(address _addr) external view returns (uint256) {
        require(_addr != address(0));
        return _cooldownStartTimestamp;
    }

    function COOLDOWN_SECONDS() external pure returns (uint256) {
        return 0;
    }

    function UNSTAKE_WINDOW() external pure returns (uint256) {
        return 1e18;
    }
}

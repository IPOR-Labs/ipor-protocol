// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.20;

import "../../contracts/amm-eth/IStETH.sol";
import "../mocks/tokens/MockTestnetToken.sol";

contract MockStETH is IStETH, MockTestnetToken  {

    constructor(
        string memory name,
        string memory symbol,
        uint256 initialSupply,
        uint8 decimalsInput
    ) MockTestnetToken(name, symbol, initialSupply, 18) {
        _mint(msg.sender, initialSupply);
    }

    function submit(address _referral) external payable override returns (uint256) {
        return 1;
    }

}
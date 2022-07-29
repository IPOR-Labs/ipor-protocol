// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.15;

import "../../../vault/interfaces/compound/WhitePaperInterestRateModel.sol";
import "../../../security/IporOwnable.sol";

contract MockWhitePaper is WhitePaperInterestRateModel, IporOwnable {
    uint256 private _borrowRate;
    uint256 private _supplyRate;
    uint256 public blocksPerYear;

    constructor() {
        blocksPerYear = 2102400;
    }

    function setSupplyRate(uint256 rate) external onlyOwner {
        _supplyRate = rate;
    }

    function getSupplyRate(
        uint256,
        uint256,
        uint256,
        uint256
    ) external view override returns (uint256) {
        return _supplyRate;
    }
}

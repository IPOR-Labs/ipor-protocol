// SPDX-License-Identifier: agpl-3.0
pragma solidity >=0.8.4 <0.9.0;

import '../../contracts/amm/MiltonV1.sol';
import "truffle/Assert.sol";
import "truffle/DeployedAddresses.sol";

contract AmmMathTest {

    function testCalculateIbtQuantityCase1() public {

        //given
        uint256 notionalAmount = 98703000000000000000000;
        uint256 ibtPrice = 100000000000000000000;

        //when
        uint256 ibtQuantity = AmmMath.calculateIbtQuantity(notionalAmount, ibtPrice);

        //then
        Assert.equal(ibtQuantity, 987030000000000000000, "Wrong IBT Quantity");
    }

    function testCalculateIncomeTaxCase1() public {
        //given
        uint256 profit = 500 * Constants.MD;
        uint256 percentage = 6 * Constants.MD / 100;

        //when
        uint256 actualIncomeTaxValue = AmmMath.calculateIncomeTax(profit, percentage);

        //then
        Assert.equal(actualIncomeTaxValue, 30000000000000000000, "Wrong Income Tax");
    }

}
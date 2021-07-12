// SPDX-License-Identifier: agpl-3.0
pragma solidity >=0.8.4 <0.9.0;

import '../../contracts/amm/IporAmmV1.sol';
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
}
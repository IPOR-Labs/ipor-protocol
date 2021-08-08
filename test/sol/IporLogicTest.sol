// SPDX-License-Identifier: agpl-3.0
pragma solidity >=0.8.4 <0.9.0;

import '../../contracts/amm/MiltonV1.sol';
import "truffle/Assert.sol";
import "truffle/DeployedAddresses.sol";
import "../../contracts/libraries/IporLogic.sol";

contract IporLogicTest {

    using IporLogic for DataTypes.IPOR;

    function testAccrueIbtPrice() public {

        //given
        uint256 initialTimestamp = block.timestamp;
        DataTypes.IPOR memory ipor = DataTypes.IPOR("DAI", 30000000000000000, 1000000000000000000, initialTimestamp);

        uint256 days25 = 60 * 60 * 24 * 25;
        uint256 expectedIbtPrice = 1002054794520547945;
        //when
        uint256 actualIbtPrice = ipor.accrueIbtPrice(block.timestamp + days25);

        //then
        Assert.equal(actualIbtPrice, expectedIbtPrice, 'Incorrect IBT Price');

    }

    function testAccrueIbtPriceTwoCalculations() public {

        //given
        uint256 initialTimestamp = block.timestamp;
        DataTypes.IPOR memory ipor = DataTypes.IPOR("DAI", 30000000000000000, 1000000000000000000, initialTimestamp);

        uint256 days25 = 60 * 60 * 24 * 25;

        uint256 firstCalculationTimestamp = block.timestamp + days25;
        ipor.accrueIbtPrice(firstCalculationTimestamp);

        uint256 secondCalculationTimestamp = firstCalculationTimestamp + days25;

        uint256 expectedIbtPrice = 1004109589041095890;

        //when
        uint256 secondIbtPrice = ipor.accrueIbtPrice(secondCalculationTimestamp);


        //then
        Assert.equal(secondIbtPrice, expectedIbtPrice, 'Incorrect IBT Price');

    }
}
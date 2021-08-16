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
        uint256 initialQuasiIbtPrice = 1000000000000000000 * Constants.YEAR_IN_SECONDS;

        DataTypes.IPOR memory ipor = DataTypes.IPOR("DAI", 30000000000000000, initialQuasiIbtPrice, initialTimestamp);

        uint256 days25 = 60 * 60 * 24 * 25;
        uint256 expectedIbtPrice = 1002054794520547945;
        //when
        uint256 actualQuasiIbtPrice = ipor.accrueIbtPrice(initialTimestamp + days25);
        uint256 actualIbtPrice = AmmMath.division(actualQuasiIbtPrice, Constants.YEAR_IN_SECONDS);
        //then
        Assert.equal(actualIbtPrice, expectedIbtPrice, 'Incorrect IBT Price');

    }

    function testAccrueIbtPriceTwoCalculations() public {

        //given
        uint256 initialTimestamp = block.timestamp;
        uint256 initialQuasiIbtPrice = 1000000000000000000 * Constants.YEAR_IN_SECONDS;
        DataTypes.IPOR memory ipor = DataTypes.IPOR("DAI", 30000000000000000, initialQuasiIbtPrice, initialTimestamp);

        uint256 days25 = 60 * 60 * 24 * 25;

        uint256 firstCalculationTimestamp = initialTimestamp + days25;
        ipor.accrueIbtPrice(firstCalculationTimestamp);

        uint256 secondCalculationTimestamp = firstCalculationTimestamp + days25;

        uint256 expectedIbtPrice = 1004109589041095890;

        //when
        uint256 secondQuasiIbtPrice = ipor.accrueIbtPrice(secondCalculationTimestamp);
        uint256 actualIbtPrice = AmmMath.division(secondQuasiIbtPrice, Constants.YEAR_IN_SECONDS);


        //then
        Assert.equal(actualIbtPrice, expectedIbtPrice, 'Incorrect IBT Price');

    }
}
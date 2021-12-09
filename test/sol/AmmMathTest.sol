// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.9;

import "../../contracts/amm/Milton.sol";
import "truffle/Assert.sol";
import "truffle/DeployedAddresses.sol";

contract AmmMathTest {
    function testCalculateIbtQuantityCase1() public {
        //given
        uint256 notionalAmount = 98703 * Constants.D18;
        uint256 ibtPrice = 100 * Constants.D18;

        //when
        uint256 ibtQuantity = AmmMath.calculateIbtQuantity(
            notionalAmount,
            ibtPrice
        );

        //then
        Assert.equal(ibtQuantity, 987030000000000000000, "Wrong IBT Quantity");
    }

    function testCalculateIncomeTaxCase1() public {
        //given
        uint256 profit = 500 * Constants.D18;
        uint256 percentage = (6 * Constants.D18) / 100;

        //when
        uint256 actualIncomeTaxValue = AmmMath.calculateIncomeTax(
            profit,
            percentage
        );

        //then
        Assert.equal(
            actualIncomeTaxValue,
            30 * Constants.D18,
            "Wrong Income Tax"
        );
    }

    function testCalculateDerivativeAmountCase1() public {
        //given
        uint256 totalAmount = 10180 * Constants.D18;
        uint256 collateralizationFactor = 50 * Constants.D18;
        uint256 liquidationDepositAmount = 20 * Constants.D18;
        uint256 iporPublicationFeeAmount = 10 * Constants.D18;
        uint256 openingFeePercentage = 3 * 1e14;

        //when
        DataTypes.IporDerivativeAmount memory result = AmmMath
            .calculateDerivativeAmount(
                totalAmount,
                collateralizationFactor,
                liquidationDepositAmount,
                iporPublicationFeeAmount,
                openingFeePercentage
            );

        //then
        Assert.equal(result.notional, 500000 * Constants.D18, "Wrong Notional");
        Assert.equal(
            result.openingFee,
            150 * Constants.D18,
            "Wrong Opening Fee Amount"
        );
        Assert.equal(result.deposit, 10000 * Constants.D18, "Wrong Collateral");
    }
}

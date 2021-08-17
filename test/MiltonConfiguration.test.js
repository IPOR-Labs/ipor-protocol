const testUtils = require("./TestUtils.js");

const MiltonConfiguration = artifacts.require('MiltonConfiguration');

contract('MiltonConfiguration', (accounts) => {
    const [admin, userOne, userTwo, userThree, liquidityProvider, _] = accounts;

    let miltonConfiguration = null;

    before(async () => {
    });

    beforeEach(async () => {
        miltonConfiguration = await MiltonConfiguration.new();
    });

    it('should NOT set incomeTaxPercentage', async () => {
        //given
        let incomeTaxPercentage = BigInt("200000000000000001");

        await testUtils.assertError(
            //when
            miltonConfiguration.setIncomeTaxPercentage(incomeTaxPercentage),
            //then
            'IPOR_24'
        );
    });

    it('should NOT set maxIncomeTaxPercentage', async () => {
        //given
        let maxIncomeTaxPercentage = BigInt("1000000000000000001");

        await testUtils.assertError(
            //when
            miltonConfiguration.setMaxIncomeTaxPercentage(maxIncomeTaxPercentage),
            //then
            'IPOR_24'
        );
    });

    it('should set maxIncomeTaxPercentage', async () => {
        //given
        let maxIncomeTaxPercentage = BigInt("800000000000000000");

        //when
        await miltonConfiguration.setMaxIncomeTaxPercentage(maxIncomeTaxPercentage);

        //then
        let actualMaxIncomeTaxPercentage = await miltonConfiguration.getMaxIncomeTaxPercentage();

        assert(maxIncomeTaxPercentage === BigInt(actualMaxIncomeTaxPercentage),
            `Incorrect maxIncomeTaxPercentage actual: ${actualMaxIncomeTaxPercentage}, expected: ${maxIncomeTaxPercentage}`)

    });

    it('should set incomeTaxPercentage - case 1', async () => {
        //given

        let incomeTaxPercentage = BigInt("150000000000000000");

        //when
        await miltonConfiguration.setIncomeTaxPercentage(incomeTaxPercentage);

        //then
        let actualIncomeTaxPercentage = await miltonConfiguration.getIncomeTaxPercentage();

        assert(incomeTaxPercentage === BigInt(actualIncomeTaxPercentage),
            `Incorrect incomeTaxPercentage actual: ${actualIncomeTaxPercentage}, expected: ${incomeTaxPercentage}`)

    });


    it('should set incomeTaxPercentage - case 2', async () => {
        //given
        let maxIncomeTaxPercentage = BigInt("800000000000000000");
        let incomeTaxPercentage = BigInt("700000000000000000");

        await miltonConfiguration.setMaxIncomeTaxPercentage(maxIncomeTaxPercentage);

        //when
        await miltonConfiguration.setIncomeTaxPercentage(incomeTaxPercentage);

        //then
        let actualIncomeTaxPercentage = await miltonConfiguration.getIncomeTaxPercentage();

        assert(incomeTaxPercentage === BigInt(actualIncomeTaxPercentage),
            `Incorrect incomeTaxPercentage actual: ${actualIncomeTaxPercentage}, expected: ${incomeTaxPercentage}`)

    });


    it('should NOT set liquidationDepositFeeAmount', async () => {
        //given
        let liquidationDepositFeeAmount = BigInt("101000000000000000000");

        await testUtils.assertError(
            //when
            miltonConfiguration.setLiquidationDepositFeeAmount(liquidationDepositFeeAmount),
            //then
            'IPOR_24'
        );
    });


    it('should set maxLiquidationDepositFeeAmount', async () => {
        //given
        let maxLiquidationDepositFeeAmount = BigInt("800000000000000000");

        //when
        await miltonConfiguration.setMaxLiquidationDepositFeeAmount(maxLiquidationDepositFeeAmount);

        //then
        let actualMaxLiquidationDepositFeeAmount = await miltonConfiguration.getMaxLiquidationDepositFeeAmount();

        assert(maxLiquidationDepositFeeAmount === BigInt(actualMaxLiquidationDepositFeeAmount),
            `Incorrect maxLiquidationDepositFeeAmount actual: ${actualMaxLiquidationDepositFeeAmount}, expected: ${maxLiquidationDepositFeeAmount}`)

    });

    it('should set liquidationDepositFeeAmount - case 1', async () => {
        //given

        let liquidationDepositFeeAmount = BigInt("50000000000000000000");

        //when
        await miltonConfiguration.setLiquidationDepositFeeAmount(liquidationDepositFeeAmount);

        //then
        let actualLiquidationDepositFeeAmount = await miltonConfiguration.getLiquidationDepositFeeAmount();

        assert(liquidationDepositFeeAmount === BigInt(actualLiquidationDepositFeeAmount),
            `Incorrect liquidationDepositFeeAmount actual: ${actualLiquidationDepositFeeAmount}, expected: ${liquidationDepositFeeAmount}`)

    });


    it('should set liquidationDepositFeeAmount - case 2', async () => {
        //given
        let maxLiquidationDepositFeeAmount = BigInt("800000000000000000");
        let liquidationDepositFeeAmount = BigInt("700000000000000000");

        await miltonConfiguration.setMaxLiquidationDepositFeeAmount(maxLiquidationDepositFeeAmount);

        //when
        await miltonConfiguration.setLiquidationDepositFeeAmount(liquidationDepositFeeAmount);

        //then
        let actualLiquidationDepositFeeAmount = await miltonConfiguration.getLiquidationDepositFeeAmount();

        assert(liquidationDepositFeeAmount === BigInt(actualLiquidationDepositFeeAmount),
            `Incorrect liquidationDepositFeeAmount actual: ${actualLiquidationDepositFeeAmount}, expected: ${liquidationDepositFeeAmount}`)

    });

    it('should NOT set openingFeePercentage', async () => {
        //given
        let openingFeePercentage = BigInt("1000000000000000001");

        await testUtils.assertError(
            //when
            miltonConfiguration.setOpeningFeePercentage(openingFeePercentage),
            //then
            'IPOR_24'
        );
    });

    it('should NOT set maxOpeningFeePercentage', async () => {
        //given
        let maxOpeningFeePercentage = BigInt("1000000000000000001");

        await testUtils.assertError(
            //when
            miltonConfiguration.setMaxOpeningFeePercentage(maxOpeningFeePercentage),
            //then
            'IPOR_24'
        );
    });

    it('should set maxOpeningFeePercentage', async () => {
        //given
        let maxOpeningFeePercentage = BigInt("800000000000000000");

        //when
        await miltonConfiguration.setMaxOpeningFeePercentage(maxOpeningFeePercentage);

        //then
        let actualmaxOpeningFeePercentage = await miltonConfiguration.getMaxOpeningFeePercentage();

        assert(maxOpeningFeePercentage === BigInt(actualmaxOpeningFeePercentage),
            `Incorrect maxOpeningFeePercentage actual: ${actualmaxOpeningFeePercentage}, expected: ${maxOpeningFeePercentage}`)

    });

    it('should set openingFeePercentage - case 1', async () => {
        //given

        let openingFeePercentage = BigInt("150000000000000000");

        //when
        await miltonConfiguration.setOpeningFeePercentage(openingFeePercentage);

        //then
        let actualOpeningFeePercentage = await miltonConfiguration.getOpeningFeePercentage();

        assert(openingFeePercentage === BigInt(actualOpeningFeePercentage),
            `Incorrect openingFeePercentage actual: ${actualOpeningFeePercentage}, expected: ${openingFeePercentage}`)

    });


    it('should set openingFeePercentage - case 2', async () => {
        //given
        let maxOpeningFeePercentage = BigInt("800000000000000000");
        let openingFeePercentage = BigInt("700000000000000000");

        await miltonConfiguration.setMaxOpeningFeePercentage(maxOpeningFeePercentage);

        //when
        await miltonConfiguration.setOpeningFeePercentage(openingFeePercentage);

        //then
        let actualOpeningFeePercentage = await miltonConfiguration.getOpeningFeePercentage();

        assert(openingFeePercentage === BigInt(actualOpeningFeePercentage),
            `Incorrect openingFeePercentage actual: ${actualOpeningFeePercentage}, expected: ${openingFeePercentage}`)

    });

    it('should NOT set iporPublicationFeeAmount', async () => {
        //given
        let iporPublicationFeeAmount = BigInt("1001000000000000000000");

        await testUtils.assertError(
            //when
            miltonConfiguration.setIporPublicationFeeAmount(iporPublicationFeeAmount),
            //then
            'IPOR_24'
        );
    });


    it('should set maxIporPublicationFeeAmount', async () => {
        //given
        let maxIporPublicationFeeAmount = BigInt("800000000000000000");

        //when
        await miltonConfiguration.setMaxIporPublicationFeeAmount(maxIporPublicationFeeAmount);

        //then
        let actualMaxIporPublicationFeeAmount = await miltonConfiguration.getMaxIporPublicationFeeAmount();

        assert(maxIporPublicationFeeAmount === BigInt(actualMaxIporPublicationFeeAmount),
            `Incorrect maxIporPublicationFeeAmount actual: ${actualMaxIporPublicationFeeAmount}, expected: ${maxIporPublicationFeeAmount}`)

    });

    it('should set iporPublicationFeeAmount - case 1', async () => {
        //given

        let iporPublicationFeeAmount = BigInt("999000000000000000000");

        //when
        await miltonConfiguration.setIporPublicationFeeAmount(iporPublicationFeeAmount);

        //then
        let actualIporPublicationFeeAmount = await miltonConfiguration.getIporPublicationFeeAmount();

        assert(iporPublicationFeeAmount === BigInt(actualIporPublicationFeeAmount),
            `Incorrect iporPublicationFeeAmount actual: ${actualIporPublicationFeeAmount}, expected: ${iporPublicationFeeAmount}`)

    });


    it('should set iporPublicationFeeAmount - case 2', async () => {
        //given
        let maxIporPublicationFeeAmount = BigInt("2000000000000000000000");
        let iporPublicationFeeAmount = BigInt("1500000000000000000000");

        await miltonConfiguration.setMaxIporPublicationFeeAmount(maxIporPublicationFeeAmount);

        //when
        await miltonConfiguration.setIporPublicationFeeAmount(iporPublicationFeeAmount);

        //then
        let actualIporPublicationFeeAmount = await miltonConfiguration.getIporPublicationFeeAmount();

        assert(iporPublicationFeeAmount === BigInt(actualIporPublicationFeeAmount),
            `Incorrect iporPublicationFeeAmount actual: ${actualIporPublicationFeeAmount}, expected: ${iporPublicationFeeAmount}`)

    });

    it('should NOT set liquidityPoolMaxUtilizationPercentage', async () => {
        //given
        let liquidityPoolMaxUtilizationPercentage = BigInt("1000000000000000001");

        await testUtils.assertError(
            //when
            miltonConfiguration.setLiquidityPoolMaxUtilizationPercentage(liquidityPoolMaxUtilizationPercentage),
            //then
            'IPOR_24'
        );
    });


    it('should get initial liquidityPoolMaxUtilizationPercentage', async () => {
        //given
        let expectedLiquidityPoolMaxUtilizationPercentage = BigInt("800000000000000000");

        //when
        let actualLiquidityPoolMaxUtilizationPercentage = await miltonConfiguration.getLiquidityPoolMaxUtilizationPercentage();

        //then
        assert(expectedLiquidityPoolMaxUtilizationPercentage === BigInt(actualLiquidityPoolMaxUtilizationPercentage),
            `Incorrect initial liquidityPoolMaxUtilizationPercentage actual: ${actualLiquidityPoolMaxUtilizationPercentage}, expected: ${expectedLiquidityPoolMaxUtilizationPercentage}`)
    });


    it('should set liquidityPoolMaxUtilizationPercentage', async () => {
        //given

        let liquidityPoolMaxUtilizationPercentage = BigInt("90000000000000000");

        //when
        await miltonConfiguration.setLiquidityPoolMaxUtilizationPercentage(liquidityPoolMaxUtilizationPercentage);

        //then
        let actualLiquidityPoolMaxUtilizationPercentage = await miltonConfiguration.getLiquidityPoolMaxUtilizationPercentage();

        assert(liquidityPoolMaxUtilizationPercentage === BigInt(actualLiquidityPoolMaxUtilizationPercentage),
            `Incorrect liquidityPoolMaxUtilizationPercentage actual: ${actualLiquidityPoolMaxUtilizationPercentage}, expected: ${liquidityPoolMaxUtilizationPercentage}`)

    });

    it('should get initial incomeTaxPercentage', async () => {
        //given
        let expectedIncomeTaxPercentage = BigInt("0");

        //when
        let actualIncomeTaxPercentage = await miltonConfiguration.getIncomeTaxPercentage();

        //then
        assert(expectedIncomeTaxPercentage === BigInt(actualIncomeTaxPercentage),
            `Incorrect initial incomeTaxPercentage actual: ${actualIncomeTaxPercentage}, expected: ${expectedIncomeTaxPercentage}`)
    });

    it('should get initial liquidationDepositFeeAmount', async () => {
        //given
        let expectedLiquidationDepositFeeAmount = BigInt("20000000000000000000");

        //when
        let actualLiquidationDepositFeeAmount = await miltonConfiguration.getLiquidationDepositFeeAmount();

        //then
        assert(expectedLiquidationDepositFeeAmount === BigInt(actualLiquidationDepositFeeAmount),
            `Incorrect initial liquidationDepositFeeAmount actual: ${actualLiquidationDepositFeeAmount}, expected: ${expectedLiquidationDepositFeeAmount}`)
    });

    it('should get initial openingFeePercentage', async () => {
        //given
        let expectedOpeningFeePercentage = BigInt("10000000000000000");

        //when
        let actualOpeningFeePercentage = await miltonConfiguration.getOpeningFeePercentage();

        //then
        assert(expectedOpeningFeePercentage === BigInt(actualOpeningFeePercentage),
            `Incorrect initial openingFeePercentage actual: ${actualOpeningFeePercentage}, expected: ${expectedOpeningFeePercentage}`)
    });

    it('should get initial iporPublicationFeeAmount', async () => {
        //given
        let expectedIporPublicationFeeAmount = BigInt("10000000000000000000");

        //when
        let actualIporPublicationFeeAmount = await miltonConfiguration.getIporPublicationFeeAmount();

        //then
        assert(expectedIporPublicationFeeAmount === BigInt(actualIporPublicationFeeAmount),
            `Incorrect initial iporPublicationFeeAmount actual: ${actualIporPublicationFeeAmount}, expected: ${expectedIporPublicationFeeAmount}`)
    });


    it('should set charlieTreasurers', async () => {
        //given
        let charlieTreasurersDaiAddress = "0x17A6E00cc10CC183a79c109E4A0aef9Cf59c8984";
        let asset = "DAI";

        //when
        await miltonConfiguration.setCharlieTreasurer(asset, charlieTreasurersDaiAddress);

        //then
        let actualCharlieTreasurerDaiAddress = await miltonConfiguration.getCharlieTreasurer(asset);

        assert(charlieTreasurersDaiAddress === actualCharlieTreasurerDaiAddress,
            `Incorrect  Charlie Treasurer address for ${asset}, actual: ${actualCharlieTreasurerDaiAddress}, expected: ${charlieTreasurersDaiAddress}`)
    });

    it('should set treasureTreasurers', async () => {
        //given
        let treasureTreasurerDaiAddress = "0x17A6E00cc10CC183a79c109E4A0aef9Cf59c8984";
        let asset = "DAI";

        //when
        await miltonConfiguration.setTreasureTreasurer(asset, treasureTreasurerDaiAddress);

        //then
        let actualTreasureTreasurerDaiAddress = await miltonConfiguration.getTreasureTreasurer(asset);

        assert(treasureTreasurerDaiAddress === actualTreasureTreasurerDaiAddress,
            `Incorrect  Trasure Treasurer address for ${asset}, actual: ${actualTreasureTreasurerDaiAddress}, expected: ${treasureTreasurerDaiAddress}`)
    });

});

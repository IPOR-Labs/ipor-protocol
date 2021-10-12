const testUtils = require("./TestUtils.js");

const DaiMockedToken = artifacts.require('DaiMockedToken');
const UsdtMockedToken = artifacts.require('UsdtMockedToken');
const UsdcMockedToken = artifacts.require('UsdcMockedToken');
const IporConfiguration = artifacts.require('IporConfiguration');
const IporAddressesManager = artifacts.require('IporAddressesManager');

contract('IporConfiguration', (accounts) => {
    const [admin, userOne, userTwo, userThree, liquidityProvider, _] = accounts;

    let tokenDai = null;
    let tokenUsdt = null;
    let tokenUsdc = null;
    let iporConfiguration = null;
    let iporAddressesManager = null;

    before(async () => {
        iporAddressesManager = await IporAddressesManager.deployed();

        tokenUsdt = await UsdtMockedToken.new(testUtils.TOTAL_SUPPLY_6_DECIMALS, 6);
        tokenUsdc = await UsdcMockedToken.new(testUtils.TOTAL_SUPPLY_18_DECIMALS, 18);
        tokenDai = await DaiMockedToken.new(testUtils.TOTAL_SUPPLY_18_DECIMALS, 18);

        await iporAddressesManager.addAsset(tokenUsdt.address);
        await iporAddressesManager.addAsset(tokenUsdc.address);
        await iporAddressesManager.addAsset(tokenDai.address);
    });

    beforeEach(async () => {
        iporConfiguration = await iporConfiguration.new();
        await iporConfiguration.initialize(iporAddressesManager.address);
    });

    it('should set default openingFeeForTreasuryPercentage', async () => {
        //given
        let expectedOpeningFeeForTreasuryPercentage = BigInt("0");

        //when
        let actualOpeningFeeForTreasuryPercentage = await iporConfiguration.getOpeningFeeForTreasuryPercentage();

        //then
        assert(expectedOpeningFeeForTreasuryPercentage === BigInt(actualOpeningFeeForTreasuryPercentage),
            `Incorrect openingFeeForTreasuryPercentage actual: ${actualOpeningFeeForTreasuryPercentage}, expected: ${expectedOpeningFeeForTreasuryPercentage}`)
    });

    it('should set openingFeeForTreasuryPercentage', async () => {
        //given
        let expectedOpeningFeeForTreasuryPercentage = BigInt("1000000000000000000");
        await iporConfiguration.setOpeningFeeForTreasuryPercentage(expectedOpeningFeeForTreasuryPercentage);

        //when
        let actualOpeningFeeForTreasuryPercentage = await iporConfiguration.getOpeningFeeForTreasuryPercentage();

        //then
        assert(expectedOpeningFeeForTreasuryPercentage === BigInt(actualOpeningFeeForTreasuryPercentage),
            `Incorrect openingFeeForTreasuryPercentage actual: ${actualOpeningFeeForTreasuryPercentage}, expected: ${expectedOpeningFeeForTreasuryPercentage}`)
    });

    it('should NOT set openingFeeForTreasuryPercentage', async () => {
        //given
        let openingFeeForTreasuryPercentage = BigInt("1010000000000000000");

        await testUtils.assertError(
            //when
            iporConfiguration.setOpeningFeeForTreasuryPercentage(openingFeeForTreasuryPercentage),
            //then
            'IPOR_24'
        );
    });

    it('should NOT set incomeTaxPercentage', async () => {
        //given
        let incomeTaxPercentage = BigInt("1000000000000000001");

        await testUtils.assertError(
            //when
            iporConfiguration.setIncomeTaxPercentage(incomeTaxPercentage),
            //then
            'IPOR_24'
        );
    });

    it('should set incomeTaxPercentage - case 1', async () => {
        //given

        let incomeTaxPercentage = BigInt("150000000000000000");

        //when
        await iporConfiguration.setIncomeTaxPercentage(incomeTaxPercentage);

        //then
        let actualIncomeTaxPercentage = await iporConfiguration.getIncomeTaxPercentage();

        assert(incomeTaxPercentage === BigInt(actualIncomeTaxPercentage),
            `Incorrect incomeTaxPercentage actual: ${actualIncomeTaxPercentage}, expected: ${incomeTaxPercentage}`)

    });

    it('should set liquidationDepositAmount - case 1', async () => {
        //given

        let liquidationDepositAmount = BigInt("50000000000000000000");

        //when
        await iporConfiguration.setLiquidationDepositAmount(liquidationDepositAmount);

        //then
        let actualLiquidationDepositAmount = await iporConfiguration.getLiquidationDepositAmount();

        assert(liquidationDepositAmount === BigInt(actualLiquidationDepositAmount),
            `Incorrect liquidationDepositAmount actual: ${actualLiquidationDepositAmount}, expected: ${liquidationDepositAmount}`)

    });

    it('should NOT set openingFeePercentage', async () => {
        //given
        let openingFeePercentage = BigInt("1010000000000000000");

        await testUtils.assertError(
            //when
            iporConfiguration.setOpeningFeePercentage(openingFeePercentage),
            //then
            'IPOR_24'
        );
    });

    it('should set openingFeePercentage - case 1', async () => {
        //given

        let openingFeePercentage = BigInt("150000000000000000");

        //when
        await iporConfiguration.setOpeningFeePercentage(openingFeePercentage);

        //then
        let actualOpeningFeePercentage = await iporConfiguration.getOpeningFeePercentage();

        assert(openingFeePercentage === BigInt(actualOpeningFeePercentage),
            `Incorrect openingFeePercentage actual: ${actualOpeningFeePercentage}, expected: ${openingFeePercentage}`)

    });

    it('should set iporPublicationFeeAmount - case 1', async () => {
        //given

        let iporPublicationFeeAmount = BigInt("999000000000000000000");

        //when
        await iporConfiguration.setIporPublicationFeeAmount(iporPublicationFeeAmount);

        //then
        let actualIporPublicationFeeAmount = await iporConfiguration.getIporPublicationFeeAmount();

        assert(iporPublicationFeeAmount === BigInt(actualIporPublicationFeeAmount),
            `Incorrect iporPublicationFeeAmount actual: ${actualIporPublicationFeeAmount}, expected: ${iporPublicationFeeAmount}`)

    });

    it('should set liquidityPoolMaxUtilizationPercentage higher than 100%', async () => {
        //given
        let liquidityPoolMaxUtilizationPercentage = BigInt("99000000000000000000");

        //when
        await iporConfiguration.setLiquidityPoolMaxUtilizationPercentage(liquidityPoolMaxUtilizationPercentage);

        //then
        let actualLPMaxUtilizationPercentage = await iporConfiguration.getLiquidityPoolMaxUtilizationPercentage();

        assert(liquidityPoolMaxUtilizationPercentage === BigInt(actualLPMaxUtilizationPercentage),
            `Incorrect LiquidityPoolMaxUtilizationPercentage actual: ${actualLPMaxUtilizationPercentage}, expected: ${liquidityPoolMaxUtilizationPercentage}`)

    });


    it('should get initial liquidityPoolMaxUtilizationPercentage', async () => {
        //given
        let expectedLiquidityPoolMaxUtilizationPercentage = BigInt("800000000000000000");

        //when
        let actualLiquidityPoolMaxUtilizationPercentage = await iporConfiguration.getLiquidityPoolMaxUtilizationPercentage();

        //then
        assert(expectedLiquidityPoolMaxUtilizationPercentage === BigInt(actualLiquidityPoolMaxUtilizationPercentage),
            `Incorrect initial liquidityPoolMaxUtilizationPercentage actual: ${actualLiquidityPoolMaxUtilizationPercentage}, expected: ${expectedLiquidityPoolMaxUtilizationPercentage}`)
    });


    it('should set liquidityPoolMaxUtilizationPercentage', async () => {
        //given

        let liquidityPoolMaxUtilizationPercentage = BigInt("90000000000000000");

        //when
        await iporConfiguration.setLiquidityPoolMaxUtilizationPercentage(liquidityPoolMaxUtilizationPercentage);

        //then
        let actualLiquidityPoolMaxUtilizationPercentage = await iporConfiguration.getLiquidityPoolMaxUtilizationPercentage();

        assert(liquidityPoolMaxUtilizationPercentage === BigInt(actualLiquidityPoolMaxUtilizationPercentage),
            `Incorrect liquidityPoolMaxUtilizationPercentage actual: ${actualLiquidityPoolMaxUtilizationPercentage}, expected: ${liquidityPoolMaxUtilizationPercentage}`)

    });

    it('should get initial incomeTaxPercentage', async () => {
        //given
        let expectedIncomeTaxPercentage = BigInt("100000000000000000");

        //when
        let actualIncomeTaxPercentage = await iporConfiguration.getIncomeTaxPercentage();

        //then
        assert(expectedIncomeTaxPercentage === BigInt(actualIncomeTaxPercentage),
            `Incorrect initial incomeTaxPercentage actual: ${actualIncomeTaxPercentage}, expected: ${expectedIncomeTaxPercentage}`)
    });

    it('should get initial liquidationDepositAmount', async () => {
        //given
        let expectedLiquidationDepositAmount = BigInt("20000000000000000000");

        //when
        let actualLiquidationDepositAmount = await iporConfiguration.getLiquidationDepositAmount();

        //then
        assert(expectedLiquidationDepositAmount === BigInt(actualLiquidationDepositAmount),
            `Incorrect initial liquidationDepositAmount actual: ${actualLiquidationDepositAmount}, expected: ${expectedLiquidationDepositAmount}`)
    });

    it('should get initial openingFeePercentage', async () => {
        //given
        let expectedOpeningFeePercentage = BigInt("10000000000000000");

        //when
        let actualOpeningFeePercentage = await iporConfiguration.getOpeningFeePercentage();

        //then
        assert(expectedOpeningFeePercentage === BigInt(actualOpeningFeePercentage),
            `Incorrect initial openingFeePercentage actual: ${actualOpeningFeePercentage}, expected: ${expectedOpeningFeePercentage}`)
    });

    it('should get initial iporPublicationFeeAmount', async () => {
        //given
        let expectedIporPublicationFeeAmount = BigInt("10000000000000000000");

        //when
        let actualIporPublicationFeeAmount = await iporConfiguration.getIporPublicationFeeAmount();

        //then
        assert(expectedIporPublicationFeeAmount === BigInt(actualIporPublicationFeeAmount),
            `Incorrect initial iporPublicationFeeAmount actual: ${actualIporPublicationFeeAmount}, expected: ${expectedIporPublicationFeeAmount}`)
    });

    it('should get initial minCollateralizationFactorValue', async () => {
        //given
        let expectedMinCollateralizationFactorValue = BigInt("10000000000000000000");

        //when
        let actualMinCollateralizationFactorValue = await iporConfiguration.getMinCollateralizationFactorValue();

        //then
        assert(expectedMinCollateralizationFactorValue === BigInt(actualMinCollateralizationFactorValue),
            `Incorrect initial MinCollateralizationFactorValue actual: ${actualMinCollateralizationFactorValue}, expected: ${expectedMinCollateralizationFactorValue}`)
    });

    it('should get initial maxCollateralizationFactorValue', async () => {
        //given
        let expectedMaxCollateralizationFactorValue = BigInt("50000000000000000000");

        //when
        let actualMaxCollateralizationFactorValue = await iporConfiguration.getMaxCollateralizationFactorValue();

        //then
        assert(expectedMaxCollateralizationFactorValue === BigInt(actualMaxCollateralizationFactorValue),
            `Incorrect initial MaxCollateralizationFactorValue actual: ${actualMaxCollateralizationFactorValue}, expected: ${expectedMaxCollateralizationFactorValue}`)
    });

    //TODO: move to IporAddressesManager.test.js

    //TODO: test na max position total amount

    // it('should set charlieTreasurers', async () => {
    //     //given
    //     let charlieTreasurersDaiAddress = "0x17A6E00cc10CC183a79c109E4A0aef9Cf59c8984";
    //     let asset = "DAI";
    //
    //     //when
    //     await iporConfiguration.setCharlieTreasurer(asset, charlieTreasurersDaiAddress);
    //
    //     //then
    //     let actualCharlieTreasurerDaiAddress = await iporConfiguration.getCharlieTreasurer(asset);
    //
    //     assert(charlieTreasurersDaiAddress === actualCharlieTreasurerDaiAddress,
    //         `Incorrect  Charlie Treasurer address for ${asset}, actual: ${actualCharlieTreasurerDaiAddress}, expected: ${charlieTreasurersDaiAddress}`)
    // });
    //
    // it('should set treasureTreasurers', async () => {
    //     //given
    //     let treasureTreasurerDaiAddress = "0x17A6E00cc10CC183a79c109E4A0aef9Cf59c8984";
    //     let asset = "DAI";
    //
    //     //when
    //     await iporConfiguration.setTreasureTreasurer(asset, treasureTreasurerDaiAddress);
    //
    //     //then
    //     let actualTreasureTreasurerDaiAddress = await iporConfiguration.getTreasureTreasurer(asset);
    //
    //     assert(treasureTreasurerDaiAddress === actualTreasureTreasurerDaiAddress,
    //         `Incorrect  Trasure Treasurer address for ${asset}, actual: ${actualTreasureTreasurerDaiAddress}, expected: ${treasureTreasurerDaiAddress}`)
    // });

});

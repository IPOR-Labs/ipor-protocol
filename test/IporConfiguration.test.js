const testUtils = require("./TestUtils.js");
const {ZERO_BYTES32} = require("@openzeppelin/test-helpers/src/constants");
const {time} = require("@openzeppelin/test-helpers");

const DaiMockedToken = artifacts.require('DaiMockedToken');
const IporAssetConfigurationDai = artifacts.require('IporAssetConfigurationDai');
const IporConfiguration = artifacts.require('IporConfiguration');
const MockTimelockController = artifacts.require('MockTimelockController');
const MINDELAY = time.duration.days(1);

contract('IporAssetConfiguration', (accounts) => {
    const [admin, userOne, userTwo, userThree, liquidityProvider, _] = accounts;

    let tokenDai = null;
    let iporAssetConfigurationDAI = null;
    let iporConfiguration = null;
    let timelockController = null;

    before(async () => {
        iporConfiguration = await IporConfiguration.deployed();
        tokenDai = await DaiMockedToken.new(testUtils.TOTAL_SUPPLY_18_DECIMALS, 18);
        await iporConfiguration.addAsset(tokenDai.address);
        timelockController = await MockTimelockController.new(MINDELAY, [userOne], [userTwo]);
    });

    beforeEach(async () => {
        iporAssetConfigurationDAI = await IporAssetConfigurationDai.new(tokenDai.address);
        await iporAssetConfigurationDAI.initialize(iporConfiguration.address);
    });

    it('should set default openingFeeForTreasuryPercentage', async () => {
        //given
        let expectedOpeningFeeForTreasuryPercentage = BigInt("0");

        //when
        let actualOpeningFeeForTreasuryPercentage = await iporAssetConfigurationDAI.getOpeningFeeForTreasuryPercentage();

        //then
        assert(expectedOpeningFeeForTreasuryPercentage === BigInt(actualOpeningFeeForTreasuryPercentage),
            `Incorrect openingFeeForTreasuryPercentage actual: ${actualOpeningFeeForTreasuryPercentage}, expected: ${expectedOpeningFeeForTreasuryPercentage}`)
    });

    it('should set openingFeeForTreasuryPercentage', async () => {
        //given
        let expectedOpeningFeeForTreasuryPercentage = BigInt("1000000000000000000");
        await iporAssetConfigurationDAI.setOpeningFeeForTreasuryPercentage(expectedOpeningFeeForTreasuryPercentage);

        //when
        let actualOpeningFeeForTreasuryPercentage = await iporAssetConfigurationDAI.getOpeningFeeForTreasuryPercentage();

        //then
        assert(expectedOpeningFeeForTreasuryPercentage === BigInt(actualOpeningFeeForTreasuryPercentage),
            `Incorrect openingFeeForTreasuryPercentage actual: ${actualOpeningFeeForTreasuryPercentage}, expected: ${expectedOpeningFeeForTreasuryPercentage}`)
    });

    it('should NOT set openingFeeForTreasuryPercentage', async () => {
        //given
        let openingFeeForTreasuryPercentage = BigInt("1010000000000000000");

        await testUtils.assertError(
            //when
            iporAssetConfigurationDAI.setOpeningFeeForTreasuryPercentage(openingFeeForTreasuryPercentage),
            //then
            'IPOR_24'
        );
    });

    it('should NOT set incomeTaxPercentage', async () => {
        //given
        let incomeTaxPercentage = BigInt("1000000000000000001");

        await testUtils.assertError(
            //when
            iporAssetConfigurationDAI.setIncomeTaxPercentage(incomeTaxPercentage),
            //then
            'IPOR_24'
        );
    });

    it('should set incomeTaxPercentage - case 1', async () => {
        //given

        let incomeTaxPercentage = BigInt("150000000000000000");

        //when
        await iporAssetConfigurationDAI.setIncomeTaxPercentage(incomeTaxPercentage);

        //then
        let actualIncomeTaxPercentage = await iporAssetConfigurationDAI.getIncomeTaxPercentage();

        assert(incomeTaxPercentage === BigInt(actualIncomeTaxPercentage),
            `Incorrect incomeTaxPercentage actual: ${actualIncomeTaxPercentage}, expected: ${incomeTaxPercentage}`)

    });

    it('should set liquidationDepositAmount - case 1', async () => {
        //given

        let liquidationDepositAmount = BigInt("50000000000000000000");

        //when
        await iporAssetConfigurationDAI.setLiquidationDepositAmount(liquidationDepositAmount);

        //then
        let actualLiquidationDepositAmount = await iporAssetConfigurationDAI.getLiquidationDepositAmount();

        assert(liquidationDepositAmount === BigInt(actualLiquidationDepositAmount),
            `Incorrect liquidationDepositAmount actual: ${actualLiquidationDepositAmount}, expected: ${liquidationDepositAmount}`)

    });

    it('should NOT set openingFeePercentage', async () => {
        //given
        let openingFeePercentage = BigInt("1010000000000000000");

        await testUtils.assertError(
            //when
            iporAssetConfigurationDAI.setOpeningFeePercentage(openingFeePercentage),
            //then
            'IPOR_24'
        );
    });

    it('should set openingFeePercentage - case 1', async () => {
        //given

        let openingFeePercentage = BigInt("150000000000000000");

        //when
        await iporAssetConfigurationDAI.setOpeningFeePercentage(openingFeePercentage);

        //then
        let actualOpeningFeePercentage = await iporAssetConfigurationDAI.getOpeningFeePercentage();

        assert(openingFeePercentage === BigInt(actualOpeningFeePercentage),
            `Incorrect openingFeePercentage actual: ${actualOpeningFeePercentage}, expected: ${openingFeePercentage}`)

    });

    it('should set iporPublicationFeeAmount - case 1', async () => {
        //given

        let iporPublicationFeeAmount = BigInt("999000000000000000000");

        //when
        await iporAssetConfigurationDAI.setIporPublicationFeeAmount(iporPublicationFeeAmount);

        //then
        let actualIporPublicationFeeAmount = await iporAssetConfigurationDAI.getIporPublicationFeeAmount();

        assert(iporPublicationFeeAmount === BigInt(actualIporPublicationFeeAmount),
            `Incorrect iporPublicationFeeAmount actual: ${actualIporPublicationFeeAmount}, expected: ${iporPublicationFeeAmount}`)

    });

    it('should set liquidityPoolMaxUtilizationPercentage higher than 100%', async () => {
        //given
        let liquidityPoolMaxUtilizationPercentage = BigInt("99000000000000000000");

        //when
        await iporAssetConfigurationDAI.setLiquidityPoolMaxUtilizationPercentage(liquidityPoolMaxUtilizationPercentage);

        //then
        let actualLPMaxUtilizationPercentage = await iporAssetConfigurationDAI.getLiquidityPoolMaxUtilizationPercentage();

        assert(liquidityPoolMaxUtilizationPercentage === BigInt(actualLPMaxUtilizationPercentage),
            `Incorrect LiquidityPoolMaxUtilizationPercentage actual: ${actualLPMaxUtilizationPercentage}, expected: ${liquidityPoolMaxUtilizationPercentage}`)

    });


    it('should get initial liquidityPoolMaxUtilizationPercentage', async () => {
        //given
        let expectedLiquidityPoolMaxUtilizationPercentage = BigInt("800000000000000000");

        //when
        let actualLiquidityPoolMaxUtilizationPercentage = await iporAssetConfigurationDAI.getLiquidityPoolMaxUtilizationPercentage();

        //then
        assert(expectedLiquidityPoolMaxUtilizationPercentage === BigInt(actualLiquidityPoolMaxUtilizationPercentage),
            `Incorrect initial liquidityPoolMaxUtilizationPercentage actual: ${actualLiquidityPoolMaxUtilizationPercentage}, expected: ${expectedLiquidityPoolMaxUtilizationPercentage}`)
    });


    it('should set liquidityPoolMaxUtilizationPercentage', async () => {
        //given

        let liquidityPoolMaxUtilizationPercentage = BigInt("90000000000000000");

        //when
        await iporAssetConfigurationDAI.setLiquidityPoolMaxUtilizationPercentage(liquidityPoolMaxUtilizationPercentage);

        //then
        let actualLiquidityPoolMaxUtilizationPercentage = await iporAssetConfigurationDAI.getLiquidityPoolMaxUtilizationPercentage();

        assert(liquidityPoolMaxUtilizationPercentage === BigInt(actualLiquidityPoolMaxUtilizationPercentage),
            `Incorrect liquidityPoolMaxUtilizationPercentage actual: ${actualLiquidityPoolMaxUtilizationPercentage}, expected: ${liquidityPoolMaxUtilizationPercentage}`)

    });

    it('should get initial incomeTaxPercentage', async () => {
        //given
        let expectedIncomeTaxPercentage = BigInt("100000000000000000");

        //when
        let actualIncomeTaxPercentage = await iporAssetConfigurationDAI.getIncomeTaxPercentage();

        //then
        assert(expectedIncomeTaxPercentage === BigInt(actualIncomeTaxPercentage),
            `Incorrect initial incomeTaxPercentage actual: ${actualIncomeTaxPercentage}, expected: ${expectedIncomeTaxPercentage}`)
    });

    it('should get initial liquidationDepositAmount', async () => {
        //given
        let expectedLiquidationDepositAmount = BigInt("20000000000000000000");

        //when
        let actualLiquidationDepositAmount = await iporAssetConfigurationDAI.getLiquidationDepositAmount();

        //then
        assert(expectedLiquidationDepositAmount === BigInt(actualLiquidationDepositAmount),
            `Incorrect initial liquidationDepositAmount actual: ${actualLiquidationDepositAmount}, expected: ${expectedLiquidationDepositAmount}`)
    });

    it('should get initial openingFeePercentage', async () => {
        //given
        let expectedOpeningFeePercentage = BigInt("10000000000000000");

        //when
        let actualOpeningFeePercentage = await iporAssetConfigurationDAI.getOpeningFeePercentage();

        //then
        assert(expectedOpeningFeePercentage === BigInt(actualOpeningFeePercentage),
            `Incorrect initial openingFeePercentage actual: ${actualOpeningFeePercentage}, expected: ${expectedOpeningFeePercentage}`)
    });

    it('should get initial iporPublicationFeeAmount', async () => {
        //given
        let expectedIporPublicationFeeAmount = BigInt("10000000000000000000");

        //when
        let actualIporPublicationFeeAmount = await iporAssetConfigurationDAI.getIporPublicationFeeAmount();

        //then
        assert(expectedIporPublicationFeeAmount === BigInt(actualIporPublicationFeeAmount),
            `Incorrect initial iporPublicationFeeAmount actual: ${actualIporPublicationFeeAmount}, expected: ${expectedIporPublicationFeeAmount}`)
    });

    it('should get initial minCollateralizationFactorValue', async () => {
        //given
        let expectedMinCollateralizationFactorValue = BigInt("10000000000000000000");

        //when
        let actualMinCollateralizationFactorValue = await iporAssetConfigurationDAI.getMinCollateralizationFactorValue();

        //then
        assert(expectedMinCollateralizationFactorValue === BigInt(actualMinCollateralizationFactorValue),
            `Incorrect initial MinCollateralizationFactorValue actual: ${actualMinCollateralizationFactorValue}, expected: ${expectedMinCollateralizationFactorValue}`)
    });

    it('should get initial maxCollateralizationFactorValue', async () => {
        //given
        let expectedMaxCollateralizationFactorValue = BigInt("50000000000000000000");

        //when
        let actualMaxCollateralizationFactorValue = await iporAssetConfigurationDAI.getMaxCollateralizationFactorValue();

        //then
        assert(expectedMaxCollateralizationFactorValue === BigInt(actualMaxCollateralizationFactorValue),
            `Incorrect initial MaxCollateralizationFactorValue actual: ${actualMaxCollateralizationFactorValue}, expected: ${expectedMaxCollateralizationFactorValue}`)
    });

    it('should use Timelock Controller - simple case 1', async () => {
        //given
        await iporAssetConfigurationDAI.transferOwnership(timelockController.address);
        let iporPublicationFeeAmount = BigInt("999000000000000000000");
        let calldata = iporAssetConfigurationDAI.contract.methods.setIporPublicationFeeAmount(iporPublicationFeeAmount).encodeABI();

        //when
        await timelockController.schedule(
            iporAssetConfigurationDAI.address,
            "0x0",
            calldata,
            ZERO_BYTES32,
            "0x60d9109846ab510ed75c15f979ae366a8a2ace11d34ba9788c13ac296db50e6e",
            MINDELAY,
            {from: userOne}
        );

        await time.increase(MINDELAY);

        await timelockController.execute(
            iporAssetConfigurationDAI.address,
            "0x0",
            calldata,
            ZERO_BYTES32,
            "0x60d9109846ab510ed75c15f979ae366a8a2ace11d34ba9788c13ac296db50e6e",
            {from: userTwo}
        );

        //then
        let actualIporPublicationFeeAmount = await iporAssetConfigurationDAI.getIporPublicationFeeAmount();

        assert(iporPublicationFeeAmount === BigInt(actualIporPublicationFeeAmount),
            `Incorrect iporPublicationFeeAmount actual: ${actualIporPublicationFeeAmount}, expected: ${iporPublicationFeeAmount}`)

    });

    it('should FAIL when used Timelock Controller, because user not exists on list of proposers', async () => {
        //given
        await iporAssetConfigurationDAI.transferOwnership(timelockController.address);
        let iporPublicationFeeAmount = BigInt("999000000000000000000");
        let calldata = iporAssetConfigurationDAI.contract.methods.setIporPublicationFeeAmount(iporPublicationFeeAmount).encodeABI();

        //when
        await testUtils.assertError(
            //when
            timelockController.schedule(
                iporAssetConfigurationDAI.address,
                "0x0",
                calldata,
                ZERO_BYTES32,
                "0x60d9109846ab510ed75c15f979ae366a8a2ace11d34ba9788c13ac296db50e6e",
                MINDELAY,
                {from: userThree}
            ),
            //then
            'account 0x821aea9a577a9b44299b9c15c88cf3087f3b5544 is missing role 0xb09aa5aeb3702cfd50b6b62bc4532604938f21248a27a1d5ca736082b6819cc1'
        );

    });

    it('should FAIL when used Timelock Controller, because user not exists on list of executors', async () => {
        //given
        await iporAssetConfigurationDAI.transferOwnership(timelockController.address);
        let iporPublicationFeeAmount = BigInt("999000000000000000000");
        let calldata = iporAssetConfigurationDAI.contract.methods.setIporPublicationFeeAmount(iporPublicationFeeAmount).encodeABI();;

        await timelockController.schedule(
            iporAssetConfigurationDAI.address,
            "0x0",
            calldata,
            ZERO_BYTES32,
            "0x60d9109846ab510ed75c15f979ae366a8a2ace11d34ba9788c13ac296db50e6e",
            MINDELAY,
            {from: userOne}
        );

        await time.increase(MINDELAY);

        //when
        await testUtils.assertError(
            //when
            timelockController.execute(
                iporAssetConfigurationDAI.address,
                "0x0",
                calldata,
                ZERO_BYTES32,
                "0x60d9109846ab510ed75c15f979ae366a8a2ace11d34ba9788c13ac296db50e6e",
                {from: userThree}
            ),
            //then
            'account 0x821aea9a577a9b44299b9c15c88cf3087f3b5544 is missing role 0xd8aa0f3194971a2a116679f7c2090f6939c8d4e01a2a8d7e41d55e5351469e63'
        );

    });

    it('should FAIL when used Timelock Controller, because Timelock is not an Owner of IporAssetConfiguration smart contract', async () => {

        //given
        let iporPublicationFeeAmount = BigInt("999000000000000000000");
        let calldata = iporAssetConfigurationDAI.contract.methods.setIporPublicationFeeAmount(iporPublicationFeeAmount).encodeABI();

        await timelockController.schedule(
            iporAssetConfigurationDAI.address,
            "0x0",
            calldata,
            ZERO_BYTES32,
            "0x60d9109846ab510ed75c15f979ae366a8a2ace11d34ba9788c13ac296db50e6e",
            MINDELAY,
            {from: userOne}
        );

        await time.increase(MINDELAY);

        //when
        await testUtils.assertError(
            //when
            timelockController.execute(
                iporAssetConfigurationDAI.address,
                "0x0",
                calldata,
                ZERO_BYTES32,
                "0x60d9109846ab510ed75c15f979ae366a8a2ace11d34ba9788c13ac296db50e6e",
                {from: userTwo}
            ),
            //then
            'TimelockController: underlying transaction reverted'
        );

    });

    it('should use Timelock Controller to return ownership of IporAssetConfiguration smart contract', async () => {
        //given
        let iporAssetConfigurationOriginOwner = admin;
        await iporAssetConfigurationDAI.transferOwnership(timelockController.address);
        let iporPublicationFeeAmount = BigInt("999000000000000000000");

        let calldata = iporAssetConfigurationDAI.contract.methods.transferOwnership(iporAssetConfigurationOriginOwner).encodeABI();

        //First try cannot be done, because ownership is transfered to Timelock Controller
        await testUtils.assertError(
            iporAssetConfigurationDAI.setIporPublicationFeeAmount(iporPublicationFeeAmount, {from: iporAssetConfigurationOriginOwner}),
            'Ownable: caller is not the owner'
        );

        //when
        await timelockController.schedule(
            iporAssetConfigurationDAI.address,
            "0x0",
            calldata,
            ZERO_BYTES32,
            "0x60d9109846ab510ed75c15f979ae366a8a2ace11d34ba9788c13ac296db50e6e",
            MINDELAY,
            {from: userOne}
        );

        await time.increase(MINDELAY);

        await timelockController.execute(
            iporAssetConfigurationDAI.address,
            "0x0",
            calldata,
            ZERO_BYTES32,
            "0x60d9109846ab510ed75c15f979ae366a8a2ace11d34ba9788c13ac296db50e6e",
            {from: userTwo}
        );

        await iporAssetConfigurationDAI.setIporPublicationFeeAmount(iporPublicationFeeAmount, {from: iporAssetConfigurationOriginOwner});

        //then
        let actualIporPublicationFeeAmount = await iporAssetConfigurationDAI.getIporPublicationFeeAmount();

        assert(iporPublicationFeeAmount === BigInt(actualIporPublicationFeeAmount),
            `Incorrect iporPublicationFeeAmount actual: ${actualIporPublicationFeeAmount}, expected: ${iporPublicationFeeAmount}`)

    });



});

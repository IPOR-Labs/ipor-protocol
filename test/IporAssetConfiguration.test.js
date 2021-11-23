const testUtils = require("./TestUtils.js");
const {ZERO_BYTES32} = require("@openzeppelin/test-helpers/src/constants");
const {time} = require("@openzeppelin/test-helpers");
const keccak256 = require("keccak256");

const DaiMockedToken = artifacts.require('DaiMockedToken');
const IporAssetConfigurationDai = artifacts.require('IporAssetConfigurationDai');
const IpToken = artifacts.require('IpToken');
const MockTimelockController = artifacts.require('MockTimelockController');
const MINDELAY = time.duration.days(1);

contract('IporAssetConfiguration', (accounts) => {
    const [admin, userOne, userTwo, userThree, liquidityProvider, _] = accounts;

    let tokenDai = null;
    let ipTokenDai = null;
    let iporAssetConfigurationDAI = null;
    let timelockController = null;

    before(async () => {
        tokenDai = await DaiMockedToken.new(testUtils.TOTAL_SUPPLY_18_DECIMALS, 18);
        ipTokenDai = await IpToken.new(tokenDai.address, "IP DAI", "ipDAI");
        timelockController = await MockTimelockController.new(MINDELAY, [userOne], [userTwo]);
    });

    beforeEach(async () => {
        iporAssetConfigurationDAI = await IporAssetConfigurationDai.new(tokenDai.address, ipTokenDai.address);
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
        iporAssetConfigurationDAI.grantRole(keccak256("OPENING_FEE_FOR_TREASURY_PERCENTAGE_ROLE"), userOne);

        //when
        await iporAssetConfigurationDAI.setOpeningFeeForTreasuryPercentage(expectedOpeningFeeForTreasuryPercentage, {from: userOne});        
        let actualOpeningFeeForTreasuryPercentage = await iporAssetConfigurationDAI.getOpeningFeeForTreasuryPercentage();

        //then
        assert(expectedOpeningFeeForTreasuryPercentage === BigInt(actualOpeningFeeForTreasuryPercentage),
            `Incorrect openingFeeForTreasuryPercentage actual: ${actualOpeningFeeForTreasuryPercentage}, expected: ${expectedOpeningFeeForTreasuryPercentage}`)
    });

    it('should NOT set openingFeeForTreasuryPercentage', async () => {
        //given
        let openingFeeForTreasuryPercentage = BigInt("1010000000000000000");
        iporAssetConfigurationDAI.grantRole(keccak256("OPENING_FEE_FOR_TREASURY_PERCENTAGE_ROLE"), userOne);

        await testUtils.assertError(
            //when
            iporAssetConfigurationDAI.setOpeningFeeForTreasuryPercentage(openingFeeForTreasuryPercentage, {from: userOne}),
            //then
            'IPOR_24'
        );
    });

    it('should NOT set openingFeeForTreasuryPercentage when user does not have OPENING_FEE_FOR_TREASURY_PERCENTAGE_ROLE role', async () => {
        //given
        const openingFeeForTreasuryPercentage = BigInt("1010000000000000000");

        await testUtils.assertError(
            //when
            iporAssetConfigurationDAI.setOpeningFeeForTreasuryPercentage(openingFeeForTreasuryPercentage, {from: userOne}),
            //then
            `account 0xf17f52151ebef6c7334fad080c5704d77216b732 is missing role 0x6d0de9008651a921e7ec84f14cdce94213af6041f456fcfc8c7e6fa897beab0f`
        );
    });

    it('should NOT set incomeTaxPercentage', async () => {
        //given
        let incomeTaxPercentage = BigInt("1000000000000000001");
        iporAssetConfigurationDAI.grantRole(keccak256("INCOME_TAX_PERCENTAGE_ROLE"), userOne);

        await testUtils.assertError(
            //when
            iporAssetConfigurationDAI.setIncomeTaxPercentage(incomeTaxPercentage, {from: userOne}),
            //then
            'IPOR_24'
        );
    });

    

    it('should set incomeTaxPercentage - case 1', async () => {
        //given

        let incomeTaxPercentage = BigInt("150000000000000000");
        iporAssetConfigurationDAI.grantRole(keccak256("INCOME_TAX_PERCENTAGE_ROLE"), userOne);

        //when
        await iporAssetConfigurationDAI.setIncomeTaxPercentage(incomeTaxPercentage, {from: userOne});

        //then
        let actualIncomeTaxPercentage = await iporAssetConfigurationDAI.getIncomeTaxPercentage();

        assert(incomeTaxPercentage === BigInt(actualIncomeTaxPercentage),
            `Incorrect incomeTaxPercentage actual: ${actualIncomeTaxPercentage}, expected: ${incomeTaxPercentage}`)

    });

    it('should NOT set incomeTaxPercentage when user does not have INCOME_TAX_PERCENTAGE_ROLE role', async () => {
        //given
        let incomeTaxPercentage = BigInt("150000000000000000");

        await testUtils.assertError(
            //when
            iporAssetConfigurationDAI.setIncomeTaxPercentage(incomeTaxPercentage, {from: userOne})
            ,
            //then
            `account 0xf17f52151ebef6c7334fad080c5704d77216b732 is missing role 0x1d60df71b356d37d065129ba494c44450d203a323cc11390563281105e480394`
        );
    });

    it('should set liquidationDepositAmount - case 1', async () => {
        //given

        let liquidationDepositAmount = BigInt("50000000000000000000");
        iporAssetConfigurationDAI.grantRole(keccak256("LIQUIDATION_DEPOSIT_AMOUNT_ROLE"), userOne);

        //when
        await iporAssetConfigurationDAI.setLiquidationDepositAmount(liquidationDepositAmount, {from: userOne});

        //then
        let actualLiquidationDepositAmount = await iporAssetConfigurationDAI.getLiquidationDepositAmount();

        assert(liquidationDepositAmount === BigInt(actualLiquidationDepositAmount),
            `Incorrect liquidationDepositAmount actual: ${actualLiquidationDepositAmount}, expected: ${liquidationDepositAmount}`)

    });

    it('should NOT set liquidationDepositAmount when user does not have LIQUIDATION_DEPOSIT_AMOUNT_ROLE role', async () => {
        //given
        const liquidationDepositAmount = BigInt("50000000000000000000");

        await testUtils.assertError(
            //when
            iporAssetConfigurationDAI.setLiquidationDepositAmount(liquidationDepositAmount, {from: userOne})
            ,
            //then
            `account 0xf17f52151ebef6c7334fad080c5704d77216b732 is missing role 0xe5d97cc7ebc77e4491947e53b4b684cfaea4b3d5ec8734ba48d1fc4d2d54a42e`
        );
    });

    it('should NOT set openingFeePercentage', async () => {
        //given
        let openingFeePercentage = BigInt("1010000000000000000");
        iporAssetConfigurationDAI.grantRole(keccak256("OPENING_FEE_PERCENTAGE_ROLE"), userOne);


        await testUtils.assertError(
            //when
            iporAssetConfigurationDAI.setOpeningFeePercentage(openingFeePercentage, {from: userOne}),
            //then
            'IPOR_24'
        );
    });

    it('should set openingFeePercentage - case 1', async () => {
        //given

        let openingFeePercentage = BigInt("150000000000000000");
        iporAssetConfigurationDAI.grantRole(keccak256("OPENING_FEE_PERCENTAGE_ROLE"), userOne);

        //when
        await iporAssetConfigurationDAI.setOpeningFeePercentage(openingFeePercentage, {from: userOne});

        //then
        let actualOpeningFeePercentage = await iporAssetConfigurationDAI.getOpeningFeePercentage();

        assert(openingFeePercentage === BigInt(actualOpeningFeePercentage),
            `Incorrect openingFeePercentage actual: ${actualOpeningFeePercentage}, expected: ${openingFeePercentage}`)

    });

    it('should NOT set openingFeePercentage when user does not have OPENING_FEE_PERCENTAGE_ROLE role', async () => {
        //given
        let openingFeePercentage = BigInt("150000000000000000");

        await testUtils.assertError(
            //when
            iporAssetConfigurationDAI.setOpeningFeePercentage(openingFeePercentage, {from: userOne})
            ,
            //then
            `account 0xf17f52151ebef6c7334fad080c5704d77216b732 is missing role 0xe5f1f8ca5512a616c0bd4bc9709dc97b4fc337caf7a3c160e93904247bd8daab`
        );
    });

    it('should set iporPublicationFeeAmount - case 1', async () => {
        //given

        let iporPublicationFeeAmount = BigInt("999000000000000000000");
        iporAssetConfigurationDAI.grantRole(keccak256("IPOR_PUBLICATION_FEE_AMOUNT_ROLE"), userOne);

        //when
        await iporAssetConfigurationDAI.setIporPublicationFeeAmount(iporPublicationFeeAmount, {from: userOne});

        //then
        let actualIporPublicationFeeAmount = await iporAssetConfigurationDAI.getIporPublicationFeeAmount();

        assert(iporPublicationFeeAmount === BigInt(actualIporPublicationFeeAmount),
            `Incorrect iporPublicationFeeAmount actual: ${actualIporPublicationFeeAmount}, expected: ${iporPublicationFeeAmount}`)

    });

    it('should set liquidityPoolMaxUtilizationPercentage higher than 100%', async () => {
        //given
        let liquidityPoolMaxUtilizationPercentage = BigInt("99000000000000000000");
        await iporAssetConfigurationDAI.grantRole(keccak256("LIQUIDITY_POOLMAX_UTILIZATION_PERCENTAGE_ROLE"), userOne);


        //when
        await iporAssetConfigurationDAI.setLiquidityPoolMaxUtilizationPercentage(liquidityPoolMaxUtilizationPercentage, {from: userOne});

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
        await iporAssetConfigurationDAI.grantRole(keccak256("LIQUIDITY_POOLMAX_UTILIZATION_PERCENTAGE_ROLE"), userOne);


        //when
        await iporAssetConfigurationDAI.setLiquidityPoolMaxUtilizationPercentage(liquidityPoolMaxUtilizationPercentage, {from: userOne});

        //then
        let actualLiquidityPoolMaxUtilizationPercentage = await iporAssetConfigurationDAI.getLiquidityPoolMaxUtilizationPercentage();

        assert(liquidityPoolMaxUtilizationPercentage === BigInt(actualLiquidityPoolMaxUtilizationPercentage),
            `Incorrect liquidityPoolMaxUtilizationPercentage actual: ${actualLiquidityPoolMaxUtilizationPercentage}, expected: ${liquidityPoolMaxUtilizationPercentage}`)

    });

    it('should NOT set liquidityPoolMaxUtilizationPercentage when user does not have LIQUIDITY_POOLMAX_UTILIZATION_PERCENTAGE_ROLE role', async () => {
        //given
        const liquidityPoolMaxUtilizationPercentage = BigInt("90000000000000000");

        await testUtils.assertError(
            //when
            iporAssetConfigurationDAI.setLiquidityPoolMaxUtilizationPercentage(liquidityPoolMaxUtilizationPercentage, {from: userOne})
            ,
            //then
            `account 0xf17f52151ebef6c7334fad080c5704d77216b732 is missing role 0x53e7faacb3381a7b6b7185a9fc96bd9430da87ec709e6d3e0f009ed7c71e45ef`
        );
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
        let iporPublicationFeeAmount = BigInt("999000000000000000000");
        let calldata = await iporAssetConfigurationDAI.contract.methods.setIporPublicationFeeAmount(iporPublicationFeeAmount).encodeABI();
        iporAssetConfigurationDAI.grantRole(keccak256("IPOR_PUBLICATION_FEE_AMOUNT_ROLE"), timelockController.address);
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
        let calldata = await iporAssetConfigurationDAI.contract.methods.setIporPublicationFeeAmount(iporPublicationFeeAmount).encodeABI();

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
        let calldata = await iporAssetConfigurationDAI.contract.methods.setIporPublicationFeeAmount(iporPublicationFeeAmount).encodeABI();;

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
        let calldata = await iporAssetConfigurationDAI.contract.methods.setIporPublicationFeeAmount(iporPublicationFeeAmount).encodeABI();

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

    // it.only('should use Timelock Controller to return ownership of IporAssetConfiguration smart contract', async () => {
    //     //given
    //     let iporAssetConfigurationOriginOwner = admin;
    //     await iporAssetConfigurationDAI.transferOwnership(timelockController.address);
    //     let iporPublicationFeeAmount = BigInt("999000000000000000000");
    //     iporAssetConfigurationDAI.grantRole(keccak256("IPOR_PUBLICATION_FEE_AMOUNT_ROLE"), userOne);
    //     iporAssetConfigurationDAI.grantRole(keccak256("IPOR_PUBLICATION_FEE_AMOUNT_ROLE"), userTwo);


    //     let calldata = await iporAssetConfigurationDAI.contract.methods.transferOwnership(iporAssetConfigurationOriginOwner).encodeABI();

    //     //First try cannot be done, because user has no IPOR_PUBLICATION_FEE_AMOUNT_ROLE role
    //     await testUtils.assertError(
    //         iporAssetConfigurationDAI.setIporPublicationFeeAmount(iporPublicationFeeAmount, {from: iporAssetConfigurationOriginOwner}),
    //         'account 0x821aea9a577a9b44299b9c15c88cf3087f3b5544 is missing role 0xd8aa0f3194971a2a116679f7c2090f6939c8d4e01a2a8d7e41d55e5351469e63'
    //     );

    //     //when
    //     await timelockController.schedule(
    //         iporAssetConfigurationDAI.address,
    //         "0x0",
    //         calldata,
    //         ZERO_BYTES32,
    //         "0x60d9109846ab510ed75c15f979ae366a8a2ace11d34ba9788c13ac296db50e6e",
    //         MINDELAY,
    //         {from: userOne}
    //     );

    //     await time.increase(MINDELAY);

    //     await timelockController.execute(
    //         iporAssetConfigurationDAI.address,
    //         "0x0",
    //         calldata,
    //         ZERO_BYTES32,
    //         "0x60d9109846ab510ed75c15f979ae366a8a2ace11d34ba9788c13ac296db50e6e",
    //         {from: userTwo}
    //     );

    //     await iporAssetConfigurationDAI.setIporPublicationFeeAmount(iporPublicationFeeAmount, {from: iporAssetConfigurationOriginOwner});

    //     //then
    //     let actualIporPublicationFeeAmount = await iporAssetConfigurationDAI.getIporPublicationFeeAmount();

    //     assert(iporPublicationFeeAmount === BigInt(actualIporPublicationFeeAmount),
    //         `Incorrect iporPublicationFeeAmount actual: ${actualIporPublicationFeeAmount}, expected: ${iporPublicationFeeAmount}`)

    // });

    it('should set charlieTreasurer', async () => {
        //given
        let charlieTreasurersDaiAddress = "0x17A6E00cc10CC183a79c109E4A0aef9Cf59c8984";
        let asset = tokenDai.address;
        await iporAssetConfigurationDAI.grantRole(keccak256("CHARLIE_TREASURER_ROLE"), userOne);


        //when
        await iporAssetConfigurationDAI.setCharlieTreasurer(charlieTreasurersDaiAddress, {from: userOne});

        //then
        let actualCharlieTreasurerDaiAddress = await iporAssetConfigurationDAI.getCharlieTreasurer();

        assert(charlieTreasurersDaiAddress === actualCharlieTreasurerDaiAddress,
            `Incorrect  Charlie Treasurer address for asset ${asset}, actual: ${actualCharlieTreasurerDaiAddress}, expected: ${charlieTreasurersDaiAddress}`)
    });

    it('should NOT set CharlieTreasurer when user does not have CHARLIE_TREASURER_ROLE role', async () => {
        //given
        const charlieTreasurersDaiAddress = "0x17A6E00cc10CC183a79c109E4A0aef9Cf59c8984";

        await testUtils.assertError(
            //when
            iporAssetConfigurationDAI.setCharlieTreasurer(charlieTreasurersDaiAddress, {from: userOne})
            ,
            //then
            `account 0xf17f52151ebef6c7334fad080c5704d77216b732 is missing role 0x21b203ce7b3398e0ad35c938bc2c62a805ef17dc57de85e9d29052eac6d9d6f7`
        );
    });

    it('should set treasureTreasurers', async () => {
        //given
        const treasureTreasurerDaiAddress = "0x17A6E00cc10CC183a79c109E4A0aef9Cf59c8984";
        const asset = tokenDai.address;
        iporAssetConfigurationDAI.grantRole(keccak256("TREASURE_TREASURER_ROLE"), userOne);


        //when
        await iporAssetConfigurationDAI.setTreasureTreasurer(treasureTreasurerDaiAddress, {from: userOne});

        //then
        const actualTreasureTreasurerDaiAddress = await iporAssetConfigurationDAI.getTreasureTreasurer();

        assert(treasureTreasurerDaiAddress === actualTreasureTreasurerDaiAddress,
            `Incorrect  Trasure Treasurer address for asset ${asset}, actual: ${actualTreasureTreasurerDaiAddress}, expected: ${treasureTreasurerDaiAddress}`)
    });

    it('should NOT set TreasureTreasurer when user does not have TREASURE_TREASURER_ROLE role', async () => {
        //given
        const treasureTreasurerDaiAddress = "0x17A6E00cc10CC183a79c109E4A0aef9Cf59c8984";

        await testUtils.assertError(
            //when
            iporAssetConfigurationDAI.setTreasureTreasurer(treasureTreasurerDaiAddress, {from: userOne})
            ,
            //then
            `account 0xf17f52151ebef6c7334fad080c5704d77216b732 is missing role 0x9cdee4e06275597b667c73a5eb52ed89fe6acbbd36bd9fa38146b1316abfbbc4`
        );
    });

    it('should set asset management vault', async () => {
        //given
        const address = "0x17A6E00cc10CC183a79c109E4A0aef9Cf59c8984";
        const asset = tokenDai.address;
        iporAssetConfigurationDAI.grantRole(keccak256("ASSET_MANAGEMENT_VAULT_ROLE"), userOne);

        //when
        await iporAssetConfigurationDAI.setAssetManagementVault(address, {from: userOne});

        //then
        const actualAddress = await iporAssetConfigurationDAI.getAssetManagementVault();

        assert(address === actualAddress,
            `Incorrect  Asset Management Vault address for asset ${asset}, actual: ${actualAddress}, expected: ${address}`)
    });

    it('should NOT set AssetManagementVault when user does not have ASSET_MANAGEMENT_VAULT_ROLE role', async () => {
        //given
        const address = "0x17A6E00cc10CC183a79c109E4A0aef9Cf59c8984";

        await testUtils.assertError(
            //when
            iporAssetConfigurationDAI.setAssetManagementVault(address, {from: userOne})
            ,
            //then
            `account 0xf17f52151ebef6c7334fad080c5704d77216b732 is missing role 0x2a7b2b7d358f8b11f783d1505af660b492b725a034776176adc7c268915d5bd8`
        );
    });

    it('should set MaxPositionTotalAmount', async () => {
        //given
        const max = BigInt("999000000000000000000");
        const role = keccak256("MAX_POSITION_TOTAL_AMOUNT_ROLE");
        await iporAssetConfigurationDAI.grantRole(role, userOne);
        //when
        await iporAssetConfigurationDAI.setMaxPositionTotalAmount(max, {from: userOne});
        //then
        const result = await iporAssetConfigurationDAI.getMaxPositionTotalAmount();
        assert(max === BigInt(result));
    });

    it('should NOT set MaxPositionTotalAmount when user does not have MAX_POSITION_TOTAL_AMOUNT_ROLE role', async () => {
        //given
        const max = BigInt("999000000000000000000");

        await testUtils.assertError(
            //when
            iporAssetConfigurationDAI.setMaxPositionTotalAmount(max, {from: userOne})
            ,
            //then
            `account 0xf17f52151ebef6c7334fad080c5704d77216b732 is missing role 0xbd6e7260790b38b2aece87cbeb2f1d97be9c3b1eb157efb80e7b3c341450caf2`
        );
    });


    it('should set SpreadPayFixedValue', async () => {
        //given
        const max = BigInt("999000000000000000000");
        const role = keccak256("SPREAD_PAY_FIXED_VALUE_ROLE");
        await iporAssetConfigurationDAI.grantRole(role, userOne);
        //when
        await iporAssetConfigurationDAI.setSpreadPayFixedValue(max, {from: userOne});
        //then
        const result = await iporAssetConfigurationDAI.getSpreadPayFixedValue();
        assert(max === BigInt(result));
    });

    it('should NOT set SpreadPayFixedValue when user does not have SPREAD_PAY_FIXED_VALUE_ROLE role', async () => {
        //given
        const max = BigInt("999000000000000000000");

        await testUtils.assertError(
            //when
            iporAssetConfigurationDAI.setSpreadPayFixedValue(max, {from: userOne})
            ,
            //then
            `account 0xf17f52151ebef6c7334fad080c5704d77216b732 is missing role 0x83d7135b2dfb3276d590bad8848fb596869644b2f5a647ccbdba6f13e445fb46`
        );
    });


    it('should set SpreadRecFixedValue(', async () => {
        //given
        const max = BigInt("999000000000000000000");
        const role = keccak256("SPREAD_REC_FIXED_VALUE_ROLE");
        await iporAssetConfigurationDAI.grantRole(role, userOne);
        //when
        await iporAssetConfigurationDAI.setSpreadRecFixedValue(max, {from: userOne});
        //then
        const result = await iporAssetConfigurationDAI.getSpreadRecFixedValue();
        assert(max === BigInt(result));
    });

    it('should NOT set SpreadPayFixedValue when user does not have SPREAD_PAY_FIXED_VALUE_ROLE role', async () => {
        //given
        const max = BigInt("999000000000000000000");

        await testUtils.assertError(
            //when
            iporAssetConfigurationDAI.setSpreadRecFixedValue(max, {from: userOne})
            ,
            //then
            `account 0xf17f52151ebef6c7334fad080c5704d77216b732 is missing role 0xfabc2f0c8274a3b08bd6a559681dd3a447265796340f783fbb8b3476bbd4b17b`
        );
    });


    it('should set MaxCollateralizationFactorValue', async () => {
        //given
        const max = BigInt("999000000000000000000");
        const role = keccak256("COLLATERALIZATION_FACTOR_VALUE_ROLE");
        await iporAssetConfigurationDAI.grantRole(role, userOne);
        //when
        await iporAssetConfigurationDAI.setMaxCollateralizationFactorValue(max, {from: userOne});
        //then
        const result = await iporAssetConfigurationDAI.getMaxCollateralizationFactorValue();
        assert(max === BigInt(result));
    });

    it('should NOT set MaxCollateralizationFactorValue when user does not have COLLATERALIZATION_FACTOR_VALUE_ROLE role', async () => {
        //given
        const max = BigInt("999000000000000000000");

        await testUtils.assertError(
            //when
            iporAssetConfigurationDAI.setMaxCollateralizationFactorValue(max, {from: userOne})
            ,
            //then
            `account 0xf17f52151ebef6c7334fad080c5704d77216b732 is missing role 0xfa417488328f0d166e914b1aa9f0550c0823bf7e3a9e49d553e1ca6d505cc39e`
        );
    });

    it('should set MinCollateralizationFactorValue', async () => {
        //given
        const max = BigInt("999000000000000000000");
        const role = keccak256("COLLATERALIZATION_FACTOR_VALUE_ROLE");
        await iporAssetConfigurationDAI.grantRole(role, userOne);
        //when
        await iporAssetConfigurationDAI.setMinCollateralizationFactorValue(max, {from: userOne});
        //then
        const result = await iporAssetConfigurationDAI.getMinCollateralizationFactorValue();
        assert(max === BigInt(result));
    });

    it('should NOT set MinCollateralizationFactorValue when user does not have COLLATERALIZATION_FACTOR_VALUE_ROLE role', async () => {
        //given
        const max = BigInt("999000000000000000000");

        await testUtils.assertError(
            //when
            iporAssetConfigurationDAI.setMinCollateralizationFactorValue(max, {from: userOne})
            ,
            //then
            `account 0xf17f52151ebef6c7334fad080c5704d77216b732 is missing role 0xfa417488328f0d166e914b1aa9f0550c0823bf7e3a9e49d553e1ca6d505cc39e`
        );
    });

});

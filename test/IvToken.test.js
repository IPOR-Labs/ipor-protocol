const { expect } = require("chai");
const { ethers } = require("hardhat");

const { assertError } = require("./Utils");

const {
    TOTAL_SUPPLY_18_DECIMALS,
    TOTAL_SUPPLY_6_DECIMALS,
    TC_TOTAL_AMOUNT_10_000_18DEC,
} = require("./Const.js");

describe("IvToken", () => {
    let admin, userOne, userTwo, userThree, liquidityProvider;
    let tokenUsdt;
    let tokenDai;
    let ivTokenUsdt;
    let ivTokenDai;

    before(async () => {
        [admin, userOne, userTwo, userThree, liquidityProvider] = await ethers.getSigners();
        const UsdtMockedToken = await ethers.getContractFactory("UsdtMockedToken");
        const DaiMockedToken = await ethers.getContractFactory("DaiMockedToken");
        tokenUsdt = await UsdtMockedToken.deploy(TOTAL_SUPPLY_6_DECIMALS, 6);
        await tokenUsdt.deployed();
        tokenDai = await DaiMockedToken.deploy(TOTAL_SUPPLY_18_DECIMALS, 18);
        await tokenDai.deployed();
    });

    beforeEach(async () => {
        const IvToken = await ethers.getContractFactory("IvToken");
        ivTokenUsdt = await IvToken.deploy("IV USDT", "ivUSDT", tokenUsdt.address);
        await ivTokenUsdt.deployed();
        ivTokenDai = await IvToken.deploy("IV DAI", "ivDAI", tokenDai.address);
        await ivTokenDai.deployed();
    });

    it("should transfer ownership - simple case 1", async () => {
        //given
        const expectedNewOwner = userTwo;

        //when
        await ivTokenDai.connect(admin).transferOwnership(expectedNewOwner.address);

        await ivTokenDai.connect(expectedNewOwner).confirmTransferOwnership();

        //then
        const actualNewOwner = await ivTokenDai.connect(userOne).owner();
        expect(expectedNewOwner.address).to.be.eql(actualNewOwner);
    });

    it("should NOT transfer ownership - sender not current owner", async () => {
        //given
        const expectedNewOwner = userTwo;

        //when
        await assertError(
            ivTokenDai.connect(userThree).transferOwnership(expectedNewOwner.address),
            //then
            "Ownable: caller is not the owner"
        );
    });

    it("should NOT confirm transfer ownership - sender not appointed owner", async () => {
        //given
        const expectedNewOwner = userTwo;

        //when
        await ivTokenDai.connect(admin).transferOwnership(expectedNewOwner.address);

        await assertError(
            ivTokenDai.connect(userThree).confirmTransferOwnership(),
            //then
            "IPOR_007"
        );
    });

    it("should NOT confirm transfer ownership twice - sender not appointed owner", async () => {
        //given
        const expectedNewOwner = userTwo;

        //when
        await ivTokenDai.connect(admin).transferOwnership(expectedNewOwner.address);

        await ivTokenDai.connect(expectedNewOwner).confirmTransferOwnership();

        await assertError(
            ivTokenDai.connect(expectedNewOwner).confirmTransferOwnership(),
            "IPOR_007"
        );
    });

    it("should NOT transfer ownership - sender already lost ownership", async () => {
        //given
        const expectedNewOwner = userTwo;

        await ivTokenDai.connect(admin).transferOwnership(expectedNewOwner.address);

        await ivTokenDai.connect(expectedNewOwner).confirmTransferOwnership();

        //when
        await assertError(
            ivTokenDai.connect(admin).transferOwnership(expectedNewOwner.address),
            //then
            "Ownable: caller is not the owner"
        );
    });

    it("should have rights to transfer ownership - sender still have rights", async () => {
        //given
        const expectedNewOwner = userTwo;

        await ivTokenDai.connect(admin).transferOwnership(expectedNewOwner.address);

        //when
        await ivTokenDai.connect(admin).transferOwnership(expectedNewOwner.address);

        //then
        const actualNewOwner = await ivTokenDai.connect(userOne).owner();
        expect(admin.address).to.be.eql(actualNewOwner);
    });

    it("should NOT mint IvToken if not a Stanley", async () => {
        //when
        await assertError(
            //when
            ivTokenDai.connect(userTwo).mint(userOne.address, TC_TOTAL_AMOUNT_10_000_18DEC),
            //then
            "IPOR_501"
        );
    });

    it("should NOT burn IvToken if not a Stanley", async () => {
        //when
        await assertError(
            //when
            ivTokenDai.connect(userTwo).burn(userOne.address, TC_TOTAL_AMOUNT_10_000_18DEC),
            //then
            "IPOR_501"
        );
    });

    it("should emit event", async () => {
        //given
        await ivTokenDai.setStanley(admin.address);

        await expect(ivTokenDai.mint(userOne.address, TC_TOTAL_AMOUNT_10_000_18DEC))
            .to.emit(ivTokenDai, "Mint")
            .withArgs(userOne.address, TC_TOTAL_AMOUNT_10_000_18DEC);
    });

    it("should contain 18 decimals", async () => {
        //given
        await ivTokenDai.setStanley(admin.address);
        const expectedDecimals = BigInt("18");
        //when
        let actualDecimals = BigInt(await ivTokenDai.decimals());

        //then
        expect(
            expectedDecimals,
            `Incorrect decimals actual: ${actualDecimals}, expected: ${expectedDecimals}`
        ).to.be.eql(actualDecimals);
    });

    it("should contain correct underlying token address", async () => {
        //given
        const expectedUnderlyingTokenAddress = tokenDai.address;
        //when
        let actualUnderlyingTokenAddress = await ivTokenDai.getAsset();

        //then
        expect(
            expectedUnderlyingTokenAddress,
            `Incorrect underlying token address actual: ${actualUnderlyingTokenAddress}, expected: ${expectedUnderlyingTokenAddress}`
        ).to.be.eql(actualUnderlyingTokenAddress);
    });

    it("should not sent ETH to IvToken DAI", async () => {
        //given

        await assertError(
            //when
            admin.sendTransaction({
                to: ivTokenDai.address,
                value: ethers.utils.parseEther("1.0"),
            }),
            //then
            "Transaction reverted: function selector was not recognized and there's no fallback nor receive function"
        );
    });
});

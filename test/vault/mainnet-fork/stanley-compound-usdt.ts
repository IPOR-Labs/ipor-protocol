const { expect } = require("chai");
import { BigNumber, Signer } from "ethers";
const usdtAbi = require("../../../abis/usdtAbi.json");
const comptrollerAbi = require("../../../abis/comptroller.json");
import hre, { upgrades } from "hardhat";
const aaveIncentiveContractAbi = require("../../../abis/aaveIncentiveContract.json");

const zero = BigNumber.from("0");
const one = BigNumber.from("1000000000000000000");
const maxValue = BigNumber.from(
    "115792089237316195423570985008687907853269984665640564039457584007913129639935"
);

import { CompoundStrategy, StanleyUsdt, IvToken, ERC20, MockStrategy } from "../../../types";

// // Mainnet Fork and test case for mainnet with hardhat network by impersonate account from mainnet
// work for blockNumber: 14222087,
describe("Deposit -> deployed Contract on Mainnet fork", function () {
    let accounts: Signer[];
    let accountToImpersonate: string;
    let usdtAddress: string;
    let usdtContract: ERC20;
    let aaveStrategyContract_Instance: MockStrategy;
    let signer: Signer;
    let cUsdtAddress: string;
    let COMP: string;
    let compContract: ERC20;
    let cTokenContract: ERC20;
    let ComptrollerAddress: string;
    let compTrollerContract: any;
    let compoundStrategyContract_Instance: CompoundStrategy;
    let ivToken: IvToken;
    let stanley: StanleyUsdt;

    if (process.env.FORK_ENABLED != "true") {
        return;
    }

    before(async () => {
        accounts = await hre.ethers.getSigners();

        //  ********************************************************************************************
        //  **************                     GENERAL                                    **************
        //  ********************************************************************************************

        accountToImpersonate = "0xad41bd1cf3fd753017ef5c0da8df31a3074ea1ea"; // Usdt rich address
        usdtAddress = "0xdAC17F958D2ee523a2206206994597C13D831ec7"; // usdt

        await hre.network.provider.send("hardhat_setBalance", [
            accountToImpersonate,
            "0x100000000000000000000",
        ]);

        await hre.network.provider.request({
            method: "hardhat_impersonateAccount",
            params: [accountToImpersonate],
        });

        signer = await hre.ethers.provider.getSigner(accountToImpersonate);
        usdtContract = new hre.ethers.Contract(usdtAddress, usdtAbi, signer) as ERC20;
        const impersonateBalanceBefore = await usdtContract.balanceOf(accountToImpersonate);
        await usdtContract.transfer(await accounts[0].getAddress(), impersonateBalanceBefore);
        signer = await hre.ethers.provider.getSigner(await accounts[0].getAddress());
        usdtContract = new hre.ethers.Contract(usdtAddress, usdtAbi, signer) as ERC20;

        //  ********************************************************************************************
        //  **************                         AAVE                                   **************
        //  *******************************************************************************************

        // we mock aave bacoude we want compand APR > aave APR
        const AaveStrategy = await hre.ethers.getContractFactory("MockStrategy");
        aaveStrategyContract_Instance = (await AaveStrategy.deploy()) as MockStrategy;

        await aaveStrategyContract_Instance.setShareToken(usdtAddress);
        await aaveStrategyContract_Instance.setAsset(usdtAddress);

        //  ********************************************************************************************
        //  **************                       COMPOUND                                 **************
        //  ********************************************************************************************

        cUsdtAddress = "0xf650C3d88D12dB855b8bf7D11Be6C55A4e07dCC9";
        COMP = "0xc00e94Cb662C3520282E6f5717214004A7f26888";
        ComptrollerAddress = "0x3d9819210A31b4961b30EF54bE2aeD79B9c9Cd3B";

        signer = await hre.ethers.provider.getSigner(accountToImpersonate);
        compContract = new hre.ethers.Contract(COMP, usdtAbi, signer) as ERC20;
        cTokenContract = new hre.ethers.Contract(cUsdtAddress, usdtAbi, signer) as ERC20;
        signer = await hre.ethers.provider.getSigner(await accounts[0].getAddress());

        const compoundStrategyContract = await hre.ethers.getContractFactory(
            "CompoundStrategy",
            signer
        );

        compoundStrategyContract_Instance = (await upgrades.deployProxy(compoundStrategyContract, [
            usdtAddress,
            cUsdtAddress,
            ComptrollerAddress,
            COMP,
        ])) as CompoundStrategy;

        compTrollerContract = new hre.ethers.Contract(ComptrollerAddress, comptrollerAbi, signer);

        //  ********************************************************************************************
        //  **************                        IvToken                                 **************
        //  ********************************************************************************************

        const tokenFactoryIvToken = await hre.ethers.getContractFactory("IvToken", signer);
        ivToken = (await tokenFactoryIvToken.deploy("IvToken", "IVT", usdtAddress)) as IvToken;

        //  ********************************************************************************************
        //  **************                       Stanley                                **************
        //  ********************************************************************************************
        const StanleyFactory = await hre.ethers.getContractFactory("StanleyUsdt", signer);

        stanley = (await await upgrades.deployProxy(StanleyFactory, [
            usdtAddress,
            ivToken.address,
            aaveStrategyContract_Instance.address,
            compoundStrategyContract_Instance.address,
        ])) as StanleyUsdt;

        await stanley.setMilton(await signer.getAddress());
        await compoundStrategyContract_Instance.setStanley(stanley.address);
        await compoundStrategyContract_Instance.setTreasury(await signer.getAddress());

        await usdtContract.approve(await signer.getAddress(), maxValue);
        await usdtContract.approve(stanley.address, maxValue);
        await ivToken.setStanley(stanley.address);
    });

    it("Shoiuld compand APR > aave APR ", async () => {
        // when
        const aaveApy = await aaveStrategyContract_Instance.getApr();
        const compoundApy = await compoundStrategyContract_Instance.getApr();
        // then
        expect(compoundApy.gt(aaveApy)).to.be.true;
    });

    it("Should accept deposit and transfer tokens into COMPOUND", async () => {
        //given
        const depositAmound = one.mul(10);
        const userAddress = await signer.getAddress();
        const userIvTokenBefore = await ivToken.balanceOf(userAddress);
        const compoundStrategyBalanceBefore = await compoundStrategyContract_Instance.balanceOf();

        expect(userIvTokenBefore, "userIvTokenBefore = 0").to.be.equal(zero);
        expect(compoundStrategyBalanceBefore, "compoundStrategyBalanceBefore = 0").to.be.equal(
            zero
        );

        //When
        await stanley.connect(signer).deposit(depositAmound);
        //Then
        const userIvTokenAfter = await ivToken.balanceOf(userAddress);
        const compoundStrategyBalanceAfter = await compoundStrategyContract_Instance.balanceOf();
        const userUsdtBalanceAfter = await usdtContract.balanceOf(userAddress);
        const strategyCTokenContractAfter = await cTokenContract.balanceOf(
            compoundStrategyContract_Instance.address
        );

        expect(userIvTokenAfter, "userIvTokenAfter = depositAmound").to.be.equal(depositAmound);
        expect(
            compoundStrategyBalanceAfter.gt(BigNumber.from("9999999999000000000")),
            "compoundStrategyBalanceAfter > 9999999999000000000"
        ).to.be.true;
        expect(userUsdtBalanceAfter, "userUsdtBalanceAfter = 64435243342735").to.be.equal(
            BigNumber.from("64435243342735")
        );
        expect(
            strategyCTokenContractAfter.gt(BigNumber.from("44438800000")),
            "strategyATokenContractAfter > 44438800000"
        ).to.be.true;
    });

    it("Should accept deposit twice and transfer tokens into COMPOUND", async () => {
        //given
        const depositAmound = one.mul(10);
        const userAddress = await signer.getAddress();
        const userIvTokenBefore = await ivToken.balanceOf(userAddress);
        const compoundStrategyBalanceBefore = await compoundStrategyContract_Instance.balanceOf();

        expect(userIvTokenBefore, "userIvTokenBefore = depositAmound").to.be.equal(depositAmound);
        expect(
            compoundStrategyBalanceBefore.gt(BigNumber.from("9999999999000000000")),
            "compoundStrategyBalanceBefore = 9999999999000000000"
        ).to.be.true;

        //When
        await stanley.connect(signer).deposit(depositAmound);
        await stanley.connect(signer).deposit(depositAmound);

        //Then
        const userIvTokenAfter = await ivToken.balanceOf(userAddress);
        const compoundStrategyBalanceAfter = await compoundStrategyContract_Instance.balanceOf();
        const userUsdtBalanceAfter = await usdtContract.balanceOf(userAddress);
        const strategyCTokenContractAfter = await cTokenContract.balanceOf(
            compoundStrategyContract_Instance.address
        );

        expect(
            userIvTokenAfter.gt(BigNumber.from("29999999950000000000")),
            "ivToken > 29999999950000000000"
        ).to.be.true;
        expect(
            compoundStrategyBalanceAfter.gt(BigNumber.from("30000000000000000000")),
            "aaveStrategyBalanceAfter > 30 * 10^18"
        ).to.be.true;
        expect(userUsdtBalanceAfter, "userUsdtBalanceAfter = 64435223342735").to.be.equal(
            BigNumber.from("64435223342735")
        );
        expect(
            strategyCTokenContractAfter.gte(BigNumber.from("133316000000")),
            "strategyCTokenContractAfter > 133316000000"
        ).to.be.true;
    });

    it("Should withdraw 10000000000000000000 from COMPOUND", async () => {
        //given
        const withdrawAmmond = one.mul(10);
        const userAddress = await signer.getAddress();
        const userIvTokenBefore = await ivToken.balanceOf(userAddress);
        const compoundStrategyBalanceBefore = await compoundStrategyContract_Instance.balanceOf();
        const userUsdtBalanceBefore = await usdtContract.balanceOf(userAddress);

        expect(
            userIvTokenBefore.gt(BigNumber.from("29999999950000000000")),
            "userIvTokenBefore = 29999999950000000000"
        ).to.be.true;
        expect(
            compoundStrategyBalanceBefore.gt(BigNumber.from("30000000000000000000")),
            "compoundStrategyBalanceBefore > 30 * 10^18"
        ).to.be.true;

        //when
        await stanley.withdraw(withdrawAmmond);
        //then
        const userIvTokenAfter = await ivToken.balanceOf(userAddress);
        const compoundStrategyBalanceAfter = await compoundStrategyContract_Instance.balanceOf();
        const userUsdtBalanceAfter = await usdtContract.balanceOf(userAddress);
        const strategyCTokenContractAfter = await cTokenContract.balanceOf(
            compoundStrategyContract_Instance.address
        );

        expect(
            userIvTokenAfter.gt(BigNumber.from("19999999950000000000")),
            "ivToken = 19999999950000000000"
        ).to.be.true;
        expect(
            compoundStrategyBalanceAfter.gt(BigNumber.from("20000000000000000000")),
            "compoundStrategyBalanceAfter > 20 * 10 ^18"
        ).to.be.true;
        expect(
            compoundStrategyBalanceAfter.lt(BigNumber.from("30000000000000000000")),
            "compoundStrategyBalanceAfter < 30 * 10 ^18"
        ).to.be.true;
        expect(
            userUsdtBalanceAfter.gt(userUsdtBalanceBefore),
            "userUsdtBalanceAfter > userUsdtBalanceBefore"
        ).to.be.true;
        expect(
            strategyCTokenContractAfter.gt(BigNumber.from("88877600000")),
            "strategyCTokenContractAfter >  88877600000"
        ).to.be.true;
    });

    it("Should withdraw all user assset from COMPOUND", async () => {
        //given
        const userAddress = await signer.getAddress();
        const userIvTokenBefore = await ivToken.balanceOf(userAddress);
        const compoundStrategyBalanceBefore = await compoundStrategyContract_Instance.balanceOf();
        const userUsdtBalanceBefore = await usdtContract.balanceOf(userAddress);

        expect(
            userIvTokenBefore.gt(BigNumber.from("19999999950000000000")),
            "userIvTokenBefore > 19999999950000000000"
        ).to.be.true;
        expect(
            compoundStrategyBalanceBefore.gt(BigNumber.from("20000000000000000000")),
            "compomudStrategyBalanceBefore > 20000000000000000000"
        ).to.be.true;
        //when
        await stanley.withdraw(compoundStrategyBalanceBefore);
        //then
        const userIvTokenAfter = await ivToken.balanceOf(userAddress);
        const compoundStrategyBalanceAfter = await compoundStrategyContract_Instance.balanceOf();
        const userUsdtBalanceAfter = await usdtContract.balanceOf(userAddress);
        const strategyCTokenContractAfterWithdraw = await cTokenContract.balanceOf(
            aaveStrategyContract_Instance.address
        );

        expect(userIvTokenAfter.lt(BigNumber.from("1000")), "ivToken < 1000").to.be.true;
        expect(
            compoundStrategyBalanceAfter.lt(compoundStrategyBalanceBefore),
            "compoundStrategyBalanceAfter < compoundStrategyBalanceAfter"
        ).to.be.true;
        expect(
            userUsdtBalanceAfter.gt(userUsdtBalanceBefore),
            "userUsdtBalanceAfter > userUsdtBalanceBefore"
        ).to.be.true;
        expect(
            strategyCTokenContractAfterWithdraw,
            "strategyCTokenContractAfterWithdraw = 0"
        ).to.be.equal(zero);
    });
    it("Should Clame from COMPOUND", async () => {
        //given
        const treasurAddres = await accounts[0].getAddress();
        const userBalanceBefore = await compContract.balanceOf(treasurAddres);
        const timestamp = Math.floor(Date.now() / 1000) + 864000 * 2;
        await hre.network.provider.send("evm_setNextBlockTimestamp", [timestamp]);
        await hre.network.provider.send("evm_mine");

        const compoundBalanceBefore = await compContract.balanceOf(treasurAddres);
        expect(compoundBalanceBefore, "Cliamed Compound Balance Before = 0").to.be.equal(zero);

        // when
        await compoundStrategyContract_Instance.doClaim();

        // then
        const userBalanceAfter = await compContract.balanceOf(treasurAddres);
        expect(userBalanceAfter.gte(userBalanceBefore), "Cliamed compound Balance after > before")
            .to.be.true;
    });
});

import { getEnabledCategories } from "node:trace_events";
import { BigNumber, Signer } from "ethers";
import hre, { upgrades } from "hardhat";
const { expect } = require("chai");
const { formatEther, parseEther } = require("@ethersproject/units");
const daiAbi = require("../../../abis/daiAbi.json");
const comptrollerAbi = require("../../../abis/comptroller.json");
const aaveIncentiveContractAbi = require("../../../abis/aaveIncentiveContract.json");
const keccak256 = require("keccak256");

const zero = BigNumber.from("0");
const one = BigNumber.from("1000000000000000000");
const maxValue = BigNumber.from(
    "115792089237316195423570985008687907853269984665640564039457584007913129639935"
);

import {
    AaveStrategy,
    CompoundStrategy,
    Stanley,
    IvToken,
    ERC20,
    IAaveIncentivesController,
} from "../../../types";

// // Mainnet Fork and test case for mainnet with hardhat network by impersonate account from mainnet
// work for blockNumber: 14222087,
describe("Deposit -> deployed Contract on Mainnet fork", function () {
    let accounts: Signer[];
    let accountToImpersonate: string;
    let daiAddress: string;
    let daiContract: ERC20;
    let aaveStrategyContract_Instance: AaveStrategy;
    let signer: Signer;
    let aDaiAddress: string;
    let AAVE: string;
    let addressProvider: string;
    let cDaiAddress: string;
    let COMP: string;
    let compContract: ERC20;
    let cTokenContract: ERC20;
    let ComptrollerAddress: string;
    let compTrollerContract: any;
    let aaveContract: ERC20;
    let aTokenContract: ERC20;
    let aaveIncentiveAddress: string;
    let aaveIncentiveContract: IAaveIncentivesController;
    let stkAave: string;
    let stakeAaveContract: ERC20;
    let compoundStrategyContract_Instance: CompoundStrategy;
    let ivToken: IvToken;
    let stanley: Stanley;

    if (process.env.FORK_ENABLED != "true") {
        return;
    }

    before(async () => {
        accounts = await hre.ethers.getSigners();

        //  ********************************************************************************************
        //  **************                     GENERAL                                    **************
        //  ********************************************************************************************

        accountToImpersonate = "0x6b175474e89094c44da98b954eedeac495271d0f"; // Dai rich address
        daiAddress = "0x6b175474e89094c44da98b954eedeac495271d0f"; // DAI

        await hre.network.provider.send("hardhat_setBalance", [
            accountToImpersonate,
            "0x100000000000000000000",
        ]);

        await hre.network.provider.request({
            method: "hardhat_impersonateAccount",
            params: [accountToImpersonate],
        });

        signer = await hre.ethers.provider.getSigner(accountToImpersonate);
        daiContract = new hre.ethers.Contract(
            daiAddress,
            daiAbi,
            signer
        ) as ERC20;
        const impersonateBalanceBefore = await daiContract.balanceOf(
            accountToImpersonate
        );
        await daiContract.transfer(
            await accounts[0].getAddress(),
            impersonateBalanceBefore
        );
        signer = await hre.ethers.provider.getSigner(
            await accounts[0].getAddress()
        );
        daiContract = new hre.ethers.Contract(
            daiAddress,
            daiAbi,
            signer
        ) as ERC20;

        //  ********************************************************************************************
        //  **************                         AAVE                                   **************
        //  ********************************************************************************************

        aDaiAddress = "0x028171bCA77440897B824Ca71D1c56caC55b68A3";
        addressProvider = "0xB53C1a33016B2DC2fF3653530bfF1848a515c8c5"; // addressProvider mainnet
        AAVE = "0x7Fc66500c84A76Ad7e9c93437bFc5Ac33E2DDaE9";
        aaveIncentiveAddress = "0xd784927Ff2f95ba542BfC824c8a8a98F3495f6b5";
        stkAave = "0x4da27a545c0c5B758a6BA100e3a049001de870f5";

        aaveContract = new hre.ethers.Contract(AAVE, daiAbi, signer) as ERC20;
        stakeAaveContract = new hre.ethers.Contract(
            stkAave,
            daiAbi,
            signer
        ) as ERC20;
        aTokenContract = new hre.ethers.Contract(
            aDaiAddress,
            daiAbi,
            signer
        ) as ERC20;

        const aaveStrategyContract = await hre.ethers.getContractFactory(
            "AaveStrategy",
            signer
        );
        aaveStrategyContract_Instance = (await upgrades.deployProxy(
            aaveStrategyContract,
            [
                daiAddress,
                aDaiAddress,
                addressProvider,
                stkAave,
                aaveIncentiveAddress,
                AAVE,
            ]
        )) as AaveStrategy;
        // getUserUnclaimedRewards
        aaveIncentiveContract = new hre.ethers.Contract(
            aaveIncentiveAddress,
            aaveIncentiveContractAbi,
            signer
        ) as IAaveIncentivesController;

        //  ********************************************************************************************
        //  **************                       COMPOUND                                 **************
        //  ********************************************************************************************

        cDaiAddress = "0x5d3a536E4D6DbD6114cc1Ead35777bAB948E3643";
        COMP = "0xc00e94Cb662C3520282E6f5717214004A7f26888";
        ComptrollerAddress = "0x3d9819210A31b4961b30EF54bE2aeD79B9c9Cd3B";

        signer = await hre.ethers.provider.getSigner(accountToImpersonate);
        compContract = new hre.ethers.Contract(COMP, daiAbi, signer) as ERC20;
        cTokenContract = new hre.ethers.Contract(
            cDaiAddress,
            daiAbi,
            signer
        ) as ERC20;
        signer = await hre.ethers.provider.getSigner(
            await accounts[0].getAddress()
        );

        const compoundStrategyContract = await hre.ethers.getContractFactory(
            "CompoundStrategy",
            signer
        );

        compoundStrategyContract_Instance = (await upgrades.deployProxy(
            compoundStrategyContract,
            [daiAddress, cDaiAddress, ComptrollerAddress, COMP]
        )) as CompoundStrategy;

        compTrollerContract = new hre.ethers.Contract(
            ComptrollerAddress,
            comptrollerAbi,
            signer
        );

        //  ********************************************************************************************
        //  **************                        IvToken                                 **************
        //  ********************************************************************************************

        const tokenFactoryIvToken = await hre.ethers.getContractFactory(
            "IvToken",
            signer
        );
        ivToken = (await tokenFactoryIvToken.deploy(
            "IvToken",
            "IVT",
            daiAddress
        )) as IvToken;

        //  ********************************************************************************************
        //  **************                        Stanley                                 **************
        //  ********************************************************************************************
        const IPORVaultFactory = await hre.ethers.getContractFactory(
            "Stanley",
            signer
        );

        stanley = (await await upgrades.deployProxy(IPORVaultFactory, [
            daiAddress,
            ivToken.address,
            aaveStrategyContract_Instance.address,
            compoundStrategyContract_Instance.address,
        ])) as Stanley;

        await stanley.setMilton(await signer.getAddress());
        await aaveStrategyContract_Instance.setStanley(stanley.address);
        await compoundStrategyContract_Instance.setStanley(stanley.address);

        await daiContract.approve(await signer.getAddress(), maxValue);
        await daiContract.approve(stanley.address, maxValue);
        await ivToken.setStanley(stanley.address);
    });

    it("Should accept deposit and transfer tokens into AAVE", async () => {
        //given
        const depositAmound = one.mul(10);
        const userAddress = await signer.getAddress();
        const userIvTokenBefore = await ivToken.balanceOf(userAddress);
        expect(userIvTokenBefore, "userIvTokenBefore = 0").to.be.equal(zero);
        const aaveStrategyBalanceBefore =
            await aaveStrategyContract_Instance.balanceOf();
        expect(
            aaveStrategyBalanceBefore,
            "aaveStrategyBalanceBefore = 0"
        ).to.be.equal(zero);
        const userDaiBalanceBefore = await daiContract.balanceOf(userAddress);

        //When
        await stanley.connect(signer).deposit(depositAmound);
        //Then
        const userIvTokenAfter = await ivToken.balanceOf(userAddress);
        expect(userIvTokenAfter, "userIvTokenAfter = 10 * 10^18").to.be.equal(
            depositAmound
        );
        const aaveStrategyBalanceAfter =
            await aaveStrategyContract_Instance.balanceOf();
        expect(
            aaveStrategyBalanceAfter,
            "aaveStrategyBalanceAfter = 10 * 10^18"
        ).to.be.equal(depositAmound);
        const userDaiBalanceAfter = await daiContract.balanceOf(userAddress);
        expect(
            userDaiBalanceAfter,
            "userDaiBalanceAfter = userDaiBalanceBefore - depositAmount"
        ).to.be.equal(userDaiBalanceBefore.sub(depositAmound));
        const strategyATokenContractAfter = await aTokenContract.balanceOf(
            aaveStrategyContract_Instance.address
        );
        expect(
            strategyATokenContractAfter,
            "strategyATokenContractAfter = depositAmound"
        ).to.be.equal(depositAmound);
    });

    it("Should accept deposit twice and transfer tokens into AAVE", async () => {
        //given
        const depositAmound = one.mul(10);
        const userAddress = await signer.getAddress();
        const userIvTokenBefore = await ivToken.balanceOf(userAddress);
        expect(userIvTokenBefore, "userIvTokenBefore").to.be.equal(
            depositAmound
        );
        const aaveStrategyBalanceBefore =
            await aaveStrategyContract_Instance.balanceOf();
        expect(
            aaveStrategyBalanceBefore,
            "aaveStrategyBalanceBefore = 10 *10^18"
        ).to.be.equal(depositAmound);
        const userDaiBalanceBefore = await daiContract.balanceOf(userAddress);

        //When
        await stanley.connect(signer).deposit(depositAmound);
        await stanley.connect(signer).deposit(depositAmound);
        //Then
        const userIvTokenAfter = await ivToken.balanceOf(userAddress);
        expect(
            userIvTokenAfter.gte(BigNumber.from("29999999000000000000")),
            "ivToken = 29999999978664630715"
        ).to.be.true;
        const aaveStrategyBalanceAfter =
            await aaveStrategyContract_Instance.balanceOf();
        expect(
            aaveStrategyBalanceAfter.gt(BigNumber.from("30000000000000000000")),
            "aaveStrategyBalanceAfter"
        ).to.be.true;
        const userDaiBalanceAfter = await daiContract.balanceOf(userAddress);
        expect(
            userDaiBalanceAfter,
            "userDaiBalanceAfter = userDaiBalanceBefore - 2 * depositAmound"
        ).to.be.equal(
            userDaiBalanceBefore.sub(depositAmound).sub(depositAmound)
        );
        const strategyATokenContractAfter = await aTokenContract.balanceOf(
            aaveStrategyContract_Instance.address
        );
        expect(
            strategyATokenContractAfter.gt(
                BigNumber.from("30000000000000000000")
            ),
            "strategyATokenContractAfter > 30 * 10^18"
        ).to.be.true;
    });

    it("Should withdrow 10000000000000000000 from AAVE", async () => {
        //given
        const withdrawAmmond = one.mul(10);
        const userAddress = await signer.getAddress();
        const userIvTokenBefore = await ivToken.balanceOf(userAddress);
        expect(
            userIvTokenBefore.gt(BigNumber.from("29999999000000000000")),
            "userIvTokenBefore > 29999999000000000000"
        ).to.be.true;
        const aaveStrategyBalanceBefore =
            await aaveStrategyContract_Instance.balanceOf();
        expect(
            aaveStrategyBalanceBefore.gt(
                BigNumber.from("30000000000000000000")
            ),
            "aaveStrategyBalanceBefore > 30 * 10^18"
        ).to.be.true;
        const userDaiBalanceBefore = await daiContract.balanceOf(userAddress);

        //when
        await stanley.withdraw(withdrawAmmond);
        //then
        const userIvTokenAfter = await ivToken.balanceOf(userAddress);
        expect(
            userIvTokenAfter.gt(BigNumber.from("19999999000000000000")),
            "ivToken > 19999999000000000000"
        ).to.be.true;
        const aaveStrategyBalanceAfter =
            await aaveStrategyContract_Instance.balanceOf();
        expect(
            aaveStrategyBalanceAfter.gt(BigNumber.from("20000000000000000000")),
            "aaveStrategyBalanceAfter > 20 * 10^18"
        ).to.be.true;
        expect(
            aaveStrategyBalanceAfter.lt(BigNumber.from("30000000000000000000")),
            "aaveStrategyBalanceAfter < 30 * 10^18"
        ).to.be.true;
        const userDaiBalanceAfter = await daiContract.balanceOf(userAddress);
        expect(
            userDaiBalanceAfter.gt(userDaiBalanceBefore.add(withdrawAmmond)),
            "userDaiBalanceAfter > userDaiBalanceAfter + withdrawAmmond"
        ).to.be.true;
        const strategyATokenContractAfter = await aTokenContract.balanceOf(
            aaveStrategyContract_Instance.address
        );
        expect(
            strategyATokenContractAfter.gt(
                BigNumber.from("20000000000000000000")
            ),
            "strategyATokenContractAfter > 20 * 10^18"
        ).to.be.true;
        expect(
            strategyATokenContractAfter.lt(
                BigNumber.from("30000000000000000000")
            ),
            "strategyATokenContractAfter < 30 * 10^18"
        ).to.be.true;
    });

    it("Should withdrow all IvTokens from AAVE", async () => {
        //given
        const userAddress = await signer.getAddress();
        const withdrawAmmond = await ivToken.balanceOf(userAddress);
        const userIvTokenBefore = await ivToken.balanceOf(userAddress);
        expect(
            userIvTokenBefore.gt(BigNumber.from("19999999000000000000")),
            "userIvTokenBefore = 19999999978664630715"
        ).to.be.true;
        const aaveStrategyBalanceBefore =
            await aaveStrategyContract_Instance.balanceOf();
        expect(
            aaveStrategyBalanceBefore.gt(
                BigNumber.from("20000000000000000000")
            ),
            "aaveStrategyBalanceBefore > 20 * 10^18"
        ).to.be.true;
        const userDaiBalanceBefore = await daiContract.balanceOf(userAddress);

        //when
        await stanley.withdraw(withdrawAmmond);
        //then
        const userIvTokenAfter = await ivToken.balanceOf(userAddress);
        expect(userIvTokenAfter, "ivToken = 0").to.be.equal(zero);
        const aaveStrategyBalanceAfter =
            await aaveStrategyContract_Instance.balanceOf();
        expect(
            aaveStrategyBalanceAfter.gte(zero),
            "aaveStrategyBalanceAfter > 0"
        ).to.be.true;
        expect(
            aaveStrategyBalanceAfter.lt(BigNumber.from("20")),
            "aaveStrategyBalanceAfter < 20"
        ).to.be.true;
        const userDaiBalanceAfter = await daiContract.balanceOf(userAddress);
        expect(
            userDaiBalanceAfter.gt(
                userDaiBalanceBefore
                    .add(withdrawAmmond)
                    .sub(aaveStrategyBalanceAfter)
            ),
            "userDaiBalanceAfter > userDaiBalanceBefore + withdrawAmmond - aaveStrategyBalanceAfter"
        ).to.be.true;
        const strategyATokenContractAfter = await aTokenContract.balanceOf(
            aaveStrategyContract_Instance.address
        );
        expect(
            strategyATokenContractAfter.lt(BigNumber.from("100")),
            "strategyATokenContractAfter"
        ).to.be.true;
    });
    it("Should Claim from AAVE", async () => {
        //given
        const depositAmound = one.mul(10);
        const userAddress = await signer.getAddress();
        const userOne = await accounts[1];
        const userOneAddres = await accounts[1].getAddress();

        const timestamp = Math.floor(Date.now() / 1000) + 864000 * 2;

        await hre.network.provider.send("evm_setNextBlockTimestamp", [
            timestamp,
        ]);
        await hre.network.provider.send("evm_mine");

        const aDaiBalance = await aTokenContract.balanceOf(
            aaveStrategyContract_Instance.address
        );
        const claimable = await aaveIncentiveContract.getUserUnclaimedRewards(
            aaveStrategyContract_Instance.address
        );
        expect(claimable, "Aave Claimable Amount").to.be.equal(
            BigNumber.from("64932860")
        );

        const aaveBalanceBefore = await aaveContract.balanceOf(userOneAddres);
        expect(aaveBalanceBefore, "Cliamed Aave Balance Before").to.be.equal(
            zero
        );

        // when
        await stanley.aaveBeforeClaim([aDaiAddress], maxValue);

        await hre.network.provider.send("evm_setNextBlockTimestamp", [
            timestamp + 865000,
        ]);
        await hre.network.provider.send("evm_mine");
        await stanley.aaveDoClaim(userOneAddres);

        // then

        const userOneBalance = await aaveContract.balanceOf(userOneAddres);
        expect(userOneBalance, "Cliamed Aave Balance").to.be.equal(claimable);
    });
});

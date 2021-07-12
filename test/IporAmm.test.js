const {time} = require("@openzeppelin/test-helpers");
const IporAmmV1 = artifacts.require('IporAmmV1');
const IporOracle = artifacts.require('IporOracle');
const IporPool = artifacts.require("IporPool");
const SimpleToken = artifacts.require('SimpleToken');
const DerivativeLogic = artifacts.require('DerivativeLogic');



const assertError = async (promise, error) => {
    try {
        await promise;
    } catch (e) {
        assert(e.message.includes(error), `Expected exception with message ${error}`)
        return;
    }
    assert(false);
}

contract('IporAmm', (accounts) => {

    const [admin, userOne, userTwo, _] = accounts;

    //10 000 000 000 000 USD
    let totalSupply6Decimals = '1000000000000000000000';
    //10 000 000 000 000 USD
    let totalSupply18Decimals = '10000000000000000000000000000000000';

    //10 000 000 USD
    let userSupply6Decimals = '10000000000000';

    //10 000 000 USD
    let userSupply18Decimals = '10000000000000000000000000';

    let amm = null;
    let derivativeLogic = null;
    let tokenDai = null;
    let tokenUsdt = null;
    let tokenUsdc = null;
    let iporOracle = null;

    beforeEach(async () => {

        iporOracle = await IporOracle.new();

        //10 000 000 000 000 USD
        tokenUsdt = await SimpleToken.new('Mocked USDT', 'USDT', totalSupply6Decimals, 6);
        //10 000 000 000 000 USD
        tokenUsdc = await SimpleToken.new('Mocked USDC', 'USDC', totalSupply6Decimals, 6);
        //10 000 000 000 000 USD
        tokenDai = await SimpleToken.new('Mocked DAI', 'DAI', totalSupply18Decimals, 18);

        amm = await IporAmmV1.new(iporOracle.address, tokenUsdt.address, tokenUsdc.address, tokenDai.address);

        derivativeLogic = await DerivativeLogic.deployed();

        await iporOracle.addUpdater(userOne);

        for (let i = 1; i < accounts.length - 2; i++) {
            await tokenUsdt.transfer(accounts[i], userSupply6Decimals);
            await tokenUsdc.transfer(accounts[i], userSupply6Decimals);
            await tokenDai.transfer(accounts[i], userSupply18Decimals);

            //AMM has rights to spend money on behalf of user
            tokenUsdt.approve(amm.address, totalSupply6Decimals, {from: accounts[i]});
            tokenUsdc.approve(amm.address, totalSupply6Decimals, {from: accounts[i]});
            tokenDai.approve(amm.address, totalSupply18Decimals, {from: accounts[i]});
        }

    });

    // it('should NOT open position because deposit amount too low', async () => {
    //     //given
    //     let asset = "DAI";
    //     let depositAmount = 0;
    //     let slippageValue = 3;
    //     let direction = 0;
    //     let leverage = 10;
    //
    //     await assertError(
    //         //when
    //         amm.openPosition(asset, depositAmount, slippageValue, leverage, direction),
    //         //then
    //         'Reason given: 4'
    //     );
    // });
    //
    // it('should NOT open position because slippage too low', async () => {
    //     //given
    //     let asset = "DAI";
    //     let depositAmount = BigInt("30000000000000000001");
    //     let slippageValue = 0;
    //     let direction = 0;
    //     let leverage = 10;
    //
    //     await assertError(
    //         //when
    //         amm.openPosition(asset, depositAmount, slippageValue, leverage, direction),
    //         //then
    //         'Reason given: 5'
    //     );
    // });
    //
    // it('should NOT open position because slippage too high', async () => {
    //     //given
    //     let asset = "DAI";
    //     let depositAmount = BigInt("30000000000000000001");
    //     let slippageValue = web3.utils.toBN(1e20);
    //     let theOne = web3.utils.toBN(1);
    //     slippageValue = slippageValue.add(theOne);
    //     let direction = 0;
    //     let leverage = 10;
    //
    //     await assertError(
    //         //when
    //         amm.openPosition(asset, depositAmount, slippageValue, leverage, direction),
    //         //then
    //         'Reason given: 9'
    //     );
    // });
    //
    // it('should NOT open position because deposit amount too high', async () => {
    //     //given
    //     let asset = "DAI";
    //     let depositAmount = BigInt("1000000000000000000000001")
    //     let slippageValue = 3;
    //     let direction = 0;
    //     let leverage = 10;
    //
    //     await assertError(
    //         //when
    //         amm.openPosition(asset, depositAmount, slippageValue, leverage, direction),
    //         //then
    //         'Reason given: 10'
    //     );
    // });
    //
    // it('should NOT open position because Liquidity Pool is to low', async () => {
    //     //TODO: implement
    // });
    //
    // it('should open pay fixed position - simple case DAI', async () => {
    //     //given
    //     let asset = "DAI";
    //     let depositAmount = BigInt("100000000000000000000")
    //     let slippageValue = 3;
    //     let direction = 0;
    //     let leverage = 10;
    //     iporOracle.updateIndex(asset, BigInt("30000000000000000"), {from: userOne});
    //
    //     //when
    //     await amm.openPosition(asset, depositAmount, slippageValue, leverage, direction, {from: userTwo});
    //
    //     //then
    //     const expectedDerivativesTotalBalance = BigInt("69300000000000000000");
    //     const expectedOpeningFee = BigInt("700000000000000000");
    //     const expectedLiquidationDepositFee = BigInt("20000000000000000000");
    //     const expectedIporPublicationFee = BigInt("10000000000000000000");
    //     const expectedLiquidityPoolTotalBalance = expectedOpeningFee;
    //
    //     const actualDerivativesTotalBalance = BigInt(await amm.derivativesTotalBalances(asset));
    //     const actualOpeningFeeTotalBalance = BigInt(await amm.openingFeeTotalBalances(asset));
    //     const actualLiquidationDepositFeeTotalBalance = BigInt(await amm.liquidationDepositFeeTotalBalances(asset));
    //     const actualPublicationFeeTotalBalance = BigInt(await amm.iporPublicationFeeTotalBalances(asset));
    //     const actualLiquidityPoolTotalBalance = BigInt(await amm.liquidityPoolTotalBalances(asset));
    //
    //     assert(expectedDerivativesTotalBalance === actualDerivativesTotalBalance,
    //         `Incorrect derivatives total balance for ${asset} ${actualDerivativesTotalBalance}, expected ${expectedDerivativesTotalBalance}`)
    //     assert(expectedOpeningFee === actualOpeningFeeTotalBalance,
    //         `Incorrect opening fee total balance for ${asset} ${actualOpeningFeeTotalBalance}, expected ${expectedOpeningFee}`)
    //     assert(expectedLiquidationDepositFee === actualLiquidationDepositFeeTotalBalance,
    //         `Incorrect liquidation deposit fee total balance for ${asset} ${actualLiquidationDepositFeeTotalBalance}, expected ${expectedLiquidationDepositFee}`)
    //     assert(expectedIporPublicationFee === actualPublicationFeeTotalBalance,
    //         `Incorrect ipor publication fee total balance for ${asset} ${actualPublicationFeeTotalBalance}, expected ${expectedIporPublicationFee}`)
    //
    //     assert(expectedLiquidityPoolTotalBalance === actualLiquidityPoolTotalBalance,
    //         `Incorrect Liquidity Pool total balance for ${asset} ${actualLiquidityPoolTotalBalance}, expected ${expectedLiquidityPoolTotalBalance}`)
    //
    //     let actualAmmTotalSupplyForDai = BigInt(await amm.getTotalSupply(asset));
    //
    //     assert(depositAmount === actualAmmTotalSupplyForDai,
    //         `Incorrect total supply of ${asset} tokens in AMM address ${actualAmmTotalSupplyForDai}, expected ${depositAmount}`);
    //
    //
    //     let actualUserTwoDAITokenBalance = await tokenDai.balanceOf(userTwo);
    //     const expectedUserTwoDAITokenBalance = BigInt("9999900000000000000000000");
    //
    //     assert(expectedUserTwoDAITokenBalance.toString() === actualUserTwoDAITokenBalance.toString(),
    //         `Incorrect ${asset} token balance in user wallet ${actualUserTwoDAITokenBalance}, expected ${expectedUserTwoDAITokenBalance}`);
    //
    // });

    // it('should close position, DAI, owner, pay fixed, IPOR not changed, IBT price not changed, before maturity', async () => {
    //     //given
    //     const params = {
    //         asset: "DAI",
    //         depositAmount: BigInt("10000000000000000000000"),
    //         slippageValue: 3,
    //         leverage: 10,
    //         direction: 0,
    //         from: userTwo
    //     }
    //
    //     await iporOracle.updateIndex(params.asset, BigInt("30000000000000000"), {from: userOne});
    //     await openPositionFunc(params);
    //
    //     //when
    //     await amm.closePosition(0, {from: userTwo});
    //
    //     //then
    //     let actualDerivatives = await amm.getPositions();
    //     let actualOpenPositionsVol = countOpenPositions(actualDerivatives);
    //
    //     //Number of opened derivatives
    //     assert(0 === actualOpenPositionsVol, `Incorrect number of opened derivatives ${actualOpenPositionsVol}, expected 0`)
    //
    //     let expectedOpenerUserTokenBalance = BigInt("9999890300000000000000000");
    //
    //     //opening fee + ipor publication fee
    //     let expectedAMMTokenBalance = BigInt("109700000000000000000");
    //     let expectedDerivativesTotalBalance = BigInt(0);
    //     let expectedOpeningFeeTotalBalance = BigInt("99700000000000000000");
    //     let expectedLiquidationDepositFeeTotalBalance = BigInt(0);
    //     let expectedPublicationFeeTotalBalance = BigInt("10000000000000000000");
    //     let expectedLiquidityPoolTotalBalance = BigInt("99700000000000000000");
    //
    //     await assertBalances(
    //         params.asset,
    //         userTwo,
    //         expectedOpenerUserTokenBalance,
    //         expectedAMMTokenBalance,
    //         expectedDerivativesTotalBalance,
    //         expectedOpeningFeeTotalBalance,
    //         expectedLiquidationDepositFeeTotalBalance,
    //         expectedPublicationFeeTotalBalance,
    //         expectedLiquidityPoolTotalBalance
    //     );
    // });


    it('should close position, DAI, owner, pay fixed, IPOR not changed, IBT price increased 25%, before maturity', async () => {

        //given
        const params = {
            asset: "DAI",
            depositAmount: BigInt("10000000000000000000000"), //10 000 USD
            slippageValue: 3,
            leverage: 10,
            direction: 0,
            from: userTwo
        }

        //IPOR has 365% (3,65 * 1e18)
        await iporOracle.updateIndex(params.asset, BigInt("3650000000000000000"), {from: userOne});
        await openPositionFunc(params);

        //25 days left
        await time.increase(60 * 60 * 24 * 25);
        //If IPOR is 365% then when 25 days left IBT price should increase 25%
        await iporOracle.updateIndex(params.asset, BigInt("3650000000000000000"), {from: userOne});

        const iporIndex = await iporOracle.getIndex(params.asset);
        console.log(iporIndex.ibtPrice.toString());
        //when
        await amm.closePosition(0, {from: userTwo});

        //then
        let actualDerivatives = await amm.getPositions();
        let actualOpenPositionsVol = countOpenPositions(actualDerivatives);

        //Number of opened derivatives
        assert(0 === actualOpenPositionsVol, `Incorrect number of opened derivatives ${actualOpenPositionsVol}, expected 0`)

        let expectedOpenerUserTokenBalance = BigInt("9999890300000000000000000");

        let expectedAMMTokenBalance = BigInt("109700000000000000000");
        let expectedDerivativesTotalBalance = BigInt(0);
        let expectedOpeningFeeTotalBalance = BigInt("99700000000000000000");
        let expectedLiquidationDepositFeeTotalBalance = BigInt(0);
        let expectedPublicationFeeTotalBalance = BigInt("10000000000000000000");
        let expectedLiquidityPoolTotalBalance = BigInt("99700000000000000000");

        await assertBalances(
            params.asset,
            userTwo,
            expectedOpenerUserTokenBalance,
            expectedAMMTokenBalance,
            expectedDerivativesTotalBalance,
            expectedOpeningFeeTotalBalance,
            expectedLiquidationDepositFeeTotalBalance,
            expectedPublicationFeeTotalBalance,
            expectedLiquidityPoolTotalBalance
        );

        // let expectedCloserUserTokenBalance = BigInt("");
        // let actualCloserUserTokenBalance = await tokenDai.balanceOf(closerUserAddress);
        // assert(actualCloserUserTokenBalance === expectedCloserUserTokenBalance,
        //     `Incorrect total supply of ${asset} tokens in Closer User address ${actualUserTokenBalance}, expected ${expectedUserTokenBalance}`);

    });


    // it('should calculate correct derivative interest when close pay fixed position - DAI', async () => {
    //     //given
    //     const params = {
    //         asset: "DAI",
    //         depositAmount: BigInt("10000000000000000000000"),
    //         slippageValue: 3,
    //         leverage: 10,
    //         direction: 0,
    //         from: userTwo
    //     }
    //
    //     await iporOracle.updateIndex(params.asset, BigInt("30000000000000000"), {from: userOne});
    //     await openPositionFunc(params);
    //     let iporIndex = await iporOracle.getIndex(params.asset);
    //     let openPosition = await amm.getOpenPosition(0);
    //
    //     //when
    //
    //
    //     //then
    //
    //     const expectedDerivative = {
    //         id: '0',
    //         state: '0',
    //         buyer: '0xC5fdf4076b8F3A5357c5E395ab970B5B54098Fef',
    //         asset: 'DAI',
    //         direction: '0',
    //         depositAmount: '9870300000000000000000',
    //         fee: {
    //             liquidationDepositAmount: '20000000000000000000',
    //             openingAmount: '99700000000000000000',
    //             iporPublicationAmount: '10000000000000000000',
    //             spreadPercentage: '10000000000000000'
    //         },
    //         leverage: '10',
    //         notionalAmount: '98703000000000000000000',
    //         startingTimestamp: '1625907631',
    //         endingTimestamp: '1628326831',
    //         indicator: {
    //             iporIndexValue: '30000000000000000',
    //             ibtPrice: '100000000000000000000',
    //             ibtQuantity: '987030000000000000000',
    //             fixedInterestRate: '40000000000000000',
    //             soap: '0'
    //         }
    //     }
    //
    //     await assertDerivative(0, expectedDerivative);
    //
    // });


    // 10100000000000000000000
    // 10000000000000000000000000000000
    // 10000000000000000000000

    //Every user has 10 000 000 USD DAI = 10000000000000000000000000
    //AMM has 10 000 000 000 000 DAI = 10000000000000000000000000000000
    //10 000 USD = 10000000000000000000000

    // it('should close pay fixed position - simple case DAI', async () => {
    //     //given
    //     let asset = "DAI";
    //     // 10100000000000000000000
    //     // 10000000000000000000000000000000
    //     // 10000000000000000000000
    //
    //     //Every user has 10 000 000 USD DAI = 10000000000000000000000000
    //     //AMM has 10 000 000 000 000 DAI = 10000000000000000000000000000000
    //     //10 000 USD = 10000000000000000000000
    //     let depositAmount = BigInt("10000000000000000000000")
    //
    //     let slippageValue = 3;
    //     let direction = 0;
    //     let leverage = 10;
    //     iporOracle.updateIndex(asset, BigInt("30000000000000000"), {from: userOne});
    //     await amm.openPosition(asset, depositAmount, slippageValue, leverage, direction, {from: userTwo});
    //
    //     //when
    //     await amm.closePosition(1, {from: userTwo});
    //
    //     //then
    //     const expectedUserTwoDAITokenBalance = BigInt("100");
    //     const expectedAMMDAITokenBalance = BigInt("100");
    //
    //     const expectedDerivativesTotalBalance = BigInt("0");
    //     const expectedOpeningFeeTotalBalance = BigInt("99700000000000000000");
    //
    //     const expectedLiquidationDepositFeeTotalBalance = BigInt("20000000000000000000");
    //     const expectedPublicationFeeTotalBalance = BigInt("10000000000000000000");
    //     const expectedLiquidityPoolTotalBalance = expectedOpeningFeeTotalBalance;
    //
    //     const r = await assertBalances(
    //         asset,
    //         expectedUserTwoDAITokenBalance,
    //         expectedAMMDAITokenBalance,
    //         expectedDerivativesTotalBalance,
    //         expectedOpeningFeeTotalBalance,
    //         expectedLiquidationDepositFeeTotalBalance,
    //         expectedPublicationFeeTotalBalance,
    //         expectedLiquidityPoolTotalBalance
    //     );
    //     //Wallet of AMM - DAI token balance
    //     //Wallet of Derivative Opener - DAI token balance
    //     //Wallet of Derivative Closer - DAI token balance
    //     //Derivatives balance
    //     //Liquidity Pool balance
    //     //Opening Fee Balance
    //     //Liquidation Deposit Fee Balance
    //     //Ipor Publication Fee Balance
    //     //Number of opened derivatives
    //
    // });
    //


    // it('should close position, DAI, owner, pay fixed, IPOR not changed, IBT price changed 50%, before maturity,', async () => {
    //
    // });
    //
    // it('should close position, DAI, owner, pay fixed, Liquidity Pool lost, User earned > Deposit, before maturity,', async () => {
    //
    // });
    //
    // it('should close position, DAI, owner, pay fixed, Liquidity Pool lost, User earned < Deposit, before maturity,', async () => {
    //
    // });
    //
    // it('should close position, DAI, owner, pay fixed, Liquidity Pool earned, User lost > Deposit, before maturity,', async () => {
    //
    // });
    //
    // it('should close position, DAI, owner, pay fixed, Liquidity Pool earned, User lost < Deposit, before maturity,', async () => {
    //
    // });
    //
    // //-------
    //
    // it('should close position, DAI, owner, pay fixed, Liquidity Pool lost, User earned > Deposit, after maturity,', async () => {
    //
    // });
    //
    // it('should close position, DAI, owner, pay fixed, Liquidity Pool lost, User earned < Deposit, after maturity,', async () => {
    //
    // });
    //
    // it('should close position, DAI, owner, pay fixed, Liquidity Pool earned, User lost > Deposit, after maturity,', async () => {
    //
    // });
    //
    // it('should close position, DAI, owner, pay fixed, Liquidity Pool earned, User lost < Deposit, after maturity,', async () => {
    //
    // });
    //
    // //---
    //
    // it('should close position, DAI, not owner, pay fixed, Liquidity Pool lost, User earned > Deposit, before maturity,', async () => {
    //
    // });
    //
    // it('should close position, DAI, not owner, pay fixed, Liquidity Pool lost, User earned < Deposit, before maturity,', async () => {
    //
    // });
    //
    // it('should close position, DAI, not owner, pay fixed, Liquidity Pool earned, User lost > Deposit, before maturity,', async () => {
    //
    // });
    //
    // it('should close position, DAI, not owner, pay fixed, Liquidity Pool earned, User lost < Deposit, before maturity,', async () => {
    //
    // });
    //
    // //----
    // it('should close position, DAI, not owner, pay fixed, Liquidity Pool lost, User earned > Deposit, after maturity,', async () => {
    //
    // });
    //
    // it('should close position, DAI, not owner, pay fixed, Liquidity Pool lost, User earned < Deposit, after maturity,', async () => {
    //
    // });
    //
    // it('should close position, DAI, not owner, pay fixed, Liquidity Pool earned, User lost > Deposit, after maturity,', async () => {
    //
    // });
    //
    // it('should close position, DAI, not owner, pay fixed, Liquidity Pool earned, User lost < Deposit, after maturity,', async () => {
    //
    // });
    //
    // //-------
    // //-------
    //
    //
    // it('should close position, DAI, owner, receive fixed, IPOR not changed, IBT price not changed, before maturity', async () => {
    //
    // });
    //
    // it('should close position, DAI, owner, receive fixed, IPOR not changed, IBT price changed 25%, before maturity', async () => {
    //
    // });
    //
    // it('should close position, DAI, owner, receive fixed, IPOR not changed, IBT price changed 50%, before maturity,', async () => {
    //
    // });
    //
    // it('should close position, DAI, owner, receive fixed, Liquidity Pool lost, User earned > Deposit, before maturity,', async () => {
    //
    // });
    //
    // it('should close position, DAI, owner, receive fixed, Liquidity Pool lost, User earned < Deposit, before maturity,', async () => {
    //
    // });
    //
    // it('should close position, DAI, owner, receive fixed, Liquidity Pool earned, User lost > Deposit, before maturity,', async () => {
    //
    // });
    //
    // it('should close position, DAI, owner, receive fixed, Liquidity Pool earned, User lost < Deposit, before maturity,', async () => {
    //
    // });
    //
    // //-------
    //
    // it('should close position, DAI, owner, receive fixed, Liquidity Pool lost, User earned > Deposit, after maturity,', async () => {
    //
    // });
    //
    // it('should close position, DAI, owner, receive fixed, Liquidity Pool lost, User earned < Deposit, after maturity,', async () => {
    //
    // });
    //
    // it('should close position, DAI, owner, receive fixed, Liquidity Pool earned, User lost > Deposit, after maturity,', async () => {
    //
    // });
    //
    // it('should close position, DAI, owner, receive fixed, Liquidity Pool earned, User lost < Deposit, after maturity,', async () => {
    //
    // });
    //
    // //---
    //
    // it('should close position, DAI, not owner, receive fixed, Liquidity Pool lost, User earned > Deposit, before maturity,', async () => {
    //
    // });
    //
    // it('should close position, DAI, not owner, receive fixed, Liquidity Pool lost, User earned < Deposit, before maturity,', async () => {
    //
    // });
    //
    // it('should close position, DAI, not owner, receive fixed, Liquidity Pool earned, User lost > Deposit, before maturity,', async () => {
    //
    // });
    //
    // it('should close position, DAI, not owner, receive fixed, Liquidity Pool earned, User lost < Deposit, before maturity,', async () => {
    //
    // });
    //
    // //----
    // it('should close position, DAI, not owner, receive fixed, Liquidity Pool lost, User earned > Deposit, after maturity,', async () => {
    //
    // });
    //
    // it('should close position, DAI, not owner, receive fixed, Liquidity Pool lost, User earned < Deposit, after maturity,', async () => {
    //
    // });
    //
    // it('should close position, DAI, not owner, receive fixed, Liquidity Pool earned, User lost > Deposit, after maturity,', async () => {
    //
    // });
    //
    // it('should close position, DAI, not owner, receive fixed, Liquidity Pool earned, User lost < Deposit, after maturity,', async () => {
    //
    // });


    //TODO: test when ipor not ready yet

    //TODO: check initial IBT
    //TODO: check open short position every parameter
    //TODO: create test when ipor index not yet created for specific asset

    //TODO: test if opening fee is part of liquidity pool

    //TODO: test na 1 sprwdzenie czy totalAmount wiekszy od fee
    //TODO: test na 2 sprwdzenie czy totalAmount wiekszy od fee (po przeliczeniu openingFeeAmount)
    //TODO: test na wysłanie USDT które ma 6 miejsc po przecinku i weryfikacja liczb

    //TODO: test close position - I greater than D and I minus for long derivative, check every balance
    //TODO: test close position - I greater than D and I plus for long derivative, check every balance
    //TODO: test close position - I greater than D and I minus for short derivative, check every balance
    //TODO: test close position - I greater than D and I plus for short derivative, check every balance

    //TODO: test close position - check if derivative is closed in list of derivatives
    //TODO: test close position - check if sender who closed has liquidation deposit in DAI token.
    //
    //TODO: verify if sender can close derivative
    //TODO: owner moze zamknąc zawsze, ktokolwiek moze zamknąc gdy: minęło 28 dni (maturity), gdy jest poza zakresem +- 100%
    //TODO: liquidation deposit trafia do osoby która wykona zamknięcie depozytu

    const openPositionFunc = async (params) => {
        await amm.openPosition(params.asset, params.depositAmount, params.slippageValue, params.leverage, params.direction, {from: params.from});
    }

    const countOpenPositions = (derivatives) => {
        let count = 0;
        for (let i = 0; i < derivatives.length; i++) {
            if (derivatives[i].state == 0) {
                count++;
            }
        }
        return count;
    }

    const assertDerivative = async (
        derivativeId,
        expectedDerivative
    ) => {

        let actualDerivative = await amm.getOpenPosition(derivativeId);

        assertDerivativeItem('ID', expectedDerivative.id, actualDerivative.id);
        assertDerivativeItem('State', expectedDerivative.state, actualDerivative.state);
        assertDerivativeItem('Buyer', expectedDerivative.buyer, actualDerivative.buyer);
        assertDerivativeItem('Asset', expectedDerivative.asset, actualDerivative.asset);
        assertDerivativeItem('Direction', expectedDerivative.direction, actualDerivative.direction);
        assertDerivativeItem('Deposit Amount', expectedDerivative.depositAmount, actualDerivative.depositAmount);
        assertDerivativeItem('Liquidation Deposit Amount', expectedDerivative.fee.liquidationDepositAmount, actualDerivative.fee.liquidationDepositAmount);
        assertDerivativeItem('Opening Amount Fee', expectedDerivative.fee.openingAmount, actualDerivative.fee.openingAmount);
        assertDerivativeItem('IPOR Publication Amount Fee', expectedDerivative.fee.iporPublicationAmount, actualDerivative.fee.iporPublicationAmount);
        assertDerivativeItem('Spread Percentage Fee', expectedDerivative.fee.spreadPercentage, actualDerivative.fee.spreadPercentage);
        assertDerivativeItem('Leverage', expectedDerivative.leverage, actualDerivative.leverage);
        assertDerivativeItem('Notional Amount', expectedDerivative.notionalAmount, actualDerivative.notionalAmount);
        // assertDerivativeItem('Derivative starting timestamp', expectedDerivative.startingTimestamp, actualDerivative.startingTimestamp);
        // assertDerivativeItem('Derivative ending timestamp', expectedDerivative.endingTimestamp, actualDerivative.endingTimestamp);
        assertDerivativeItem('IPOR Index Value', expectedDerivative.indicator.iporIndexValue, actualDerivative.indicator.iporIndexValue);
        assertDerivativeItem('IBT Price', expectedDerivative.indicator.ibtPrice, actualDerivative.indicator.ibtPrice);
        assertDerivativeItem('IBT Quantity', expectedDerivative.indicator.ibtQuantity, actualDerivative.indicator.ibtQuantity);
        assertDerivativeItem('Fixed Interest Rate', expectedDerivative.indicator.fixedInterestRate, actualDerivative.indicator.fixedInterestRate);
        assertDerivativeItem('SOAP', expectedDerivative.indicator.soap, actualDerivative.indicator.soap);

    }
    const assertDerivativeItem = function (itemName, expected, actual) {
        assert(actual === expected, `Incorrect ${itemName} ${actual}, expected ${expected}`);
    }
    const assertBalances = async (
        asset,
        userAddress,
        expectedUserTokenBalance,
        expectedAMMTokenBalance,
        expectedDerivativesTotalBalance,
        expectedOpeningFeeTotalBalance,
        expectedLiquidationDepositFeeTotalBalance,
        expectedPublicationFeeTotalBalance,
        expectedLiquidityPoolTotalBalance
    ) => {

        let actualUserTokenBalance = null;
        if (asset === "DAI") {
            actualUserTokenBalance = BigInt(await tokenDai.balanceOf(userAddress));
        }

        const actualAMMTokenBalance = BigInt(await amm.getTotalSupply(asset));
        const actualDerivativesTotalBalance = BigInt(await amm.derivativesTotalBalances(asset));
        const actualOpeningFeeTotalBalance = BigInt(await amm.openingFeeTotalBalances(asset));
        const actualLiquidationDepositFeeTotalBalance = BigInt(await amm.liquidationDepositFeeTotalBalances(asset));
        const actualPublicationFeeTotalBalance = BigInt(await amm.iporPublicationFeeTotalBalances(asset));
        const actualLiquidityPoolTotalBalance = BigInt(await amm.liquidityPoolTotalBalances(asset));

        if (expectedUserTokenBalance !== null) {
            assert(actualAMMTokenBalance === expectedAMMTokenBalance,
                `Incorrect total supply of ${asset} tokens in AMM address ${actualAMMTokenBalance}, expected ${expectedAMMTokenBalance}`);
        }

        if (expectedUserTokenBalance != null) {
            assert(actualUserTokenBalance === expectedUserTokenBalance,
                `Incorrect total supply of ${asset} tokens in User address ${actualUserTokenBalance}, expected ${expectedUserTokenBalance}`);
        }
        if (expectedDerivativesTotalBalance != null) {
            assert(expectedDerivativesTotalBalance === actualDerivativesTotalBalance,
                `Incorrect derivatives total balance for ${asset} ${actualDerivativesTotalBalance}, expected ${expectedDerivativesTotalBalance}`)
        }

        if (expectedOpeningFeeTotalBalance != null) {
            assert(expectedOpeningFeeTotalBalance === actualOpeningFeeTotalBalance,
                `Incorrect opening fee total balance for ${asset} ${actualOpeningFeeTotalBalance}, expected ${expectedOpeningFeeTotalBalance}`)
        }

        if (expectedLiquidationDepositFeeTotalBalance !== null) {
            assert(expectedLiquidationDepositFeeTotalBalance === actualLiquidationDepositFeeTotalBalance,
                `Incorrect liquidation deposit fee total balance for ${asset} ${actualLiquidationDepositFeeTotalBalance}, expected ${expectedLiquidationDepositFeeTotalBalance}`)
        }

        if (expectedPublicationFeeTotalBalance != null) {
            assert(expectedPublicationFeeTotalBalance === actualPublicationFeeTotalBalance,
                `Incorrect ipor publication fee total balance for ${asset} ${actualPublicationFeeTotalBalance}, expected ${expectedPublicationFeeTotalBalance}`)
        }

        if (expectedLiquidityPoolTotalBalance != null) {
            assert(expectedLiquidityPoolTotalBalance === actualLiquidityPoolTotalBalance,
                `Incorrect Liquidity Pool total balance for ${asset} ${actualLiquidityPoolTotalBalance}, expected ${expectedLiquidityPoolTotalBalance}`)
        }
    }
});
# ipor-protocol

The IPOR protocol is a decentralized marketplace that serves as the credit hub of DeFi. It brings markets together to connect liquidity and offer the best interest rates in DeFi. The protocol is a set of smart contacts that provide a benchmark interest rate, Interest Rate Derivatives and composable structured products that allow users to tap into yield generating opportunities across DeFi and TradFi.

## Job statuses

-   [![CI](https://github.com/IPOR-Labs/ipor-protocol/actions/workflows/ci.yml/badge.svg)](https://github.com/IPOR-Labs/ipor-protocol/actions/workflows/ci.yml)
-   [![CD](https://github.com/IPOR-Labs/ipor-protocol/actions/workflows/cd.yml/badge.svg)](https://github.com/IPOR-Labs/ipor-protocol/actions/workflows/cd.yml)

### Pre-run steps

-   `npm install`
-   `forge build`

### Analyse the contracts with slither
- Install [remixd](https://remix-ide.readthedocs.io/fr/latest/remixd.html)
- Install [Slither](https://remix-ide.readthedocs.io/fr/latest/slither.html),  `remixd -i slither`
- Run `slither .` to verify contract

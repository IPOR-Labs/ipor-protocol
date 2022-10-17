import React from "react";
import { newContextComponents } from "@drizzle/react-components";

const { ContractData, ContractForm } = newContextComponents;

export default ({ drizzle, drizzleState }) => (
    <div align="left">
        <hr />
        <table className="table" align="center">
            <tr>
                <th scope="col"></th>
                <th scope="col">ETH</th>
                <th scope="col">
                    USDT
                    <br />
                    <small>{drizzle.contracts.DrizzleUsdt.address}</small>
                </th>
                <th scope="col">
                    USDC
                    <br />
                    <small>{drizzle.contracts.DrizzleUsdc.address}</small>
                </th>
                <th scope="col">
                    DAI
                    <br />
                    <small>{drizzle.contracts.DrizzleDai.address}</small>
                </th>
                <th scope="col">
                    WETH
                    <br />
                    <small>{drizzle.contracts.DrizzleWeth.address}</small>
                </th>
            </tr>
            <tr>
                <td>
                    <strong>Available Faucet balance</strong>
                    <br />
                    <small>Represented in decimals specific for asset</small>
                </td>
                <td>
                    <ContractData
                        drizzle={drizzle}
                        drizzleState={drizzleState}
                        contract="TestnetFaucet"
                        method="balanceOfEth"
                        render={(value) => (
                            <div>
                                {value / 1000000000000000000}
                                <br />
                                <small>{value}</small>
                            </div>
                        )}
                    />
                </td>
                <td>
                    <ContractData
                        drizzle={drizzle}
                        drizzleState={drizzleState}
                        contract="TestnetFaucet"
                        method="balanceOf"
                        methodArgs={[drizzle.contracts.DrizzleUsdt.address]}
                        render={(value) => (
                            <div>
                                {value / 1000000}
                                <br />
                                <small>{value}</small>
                            </div>
                        )}
                    />
                </td>
                <td>
                    <ContractData
                        drizzle={drizzle}
                        drizzleState={drizzleState}
                        contract="TestnetFaucet"
                        method="balanceOf"
                        methodArgs={[drizzle.contracts.DrizzleUsdc.address]}
                        render={(value) => (
                            <div>
                                {value / 1000000}
                                <br />
                                <small>{value}</small>
                            </div>
                        )}
                    />
                </td>
                <td>
                    <ContractData
                        drizzle={drizzle}
                        drizzleState={drizzleState}
                        contract="TestnetFaucet"
                        method="balanceOf"
                        methodArgs={[drizzle.contracts.DrizzleDai.address]}
                        render={(value) => (
                            <div>
                                {value / 1000000000000000000}
                                <br />
                                <small>{value}</small>
                            </div>
                        )}
                    />
                </td>
                <td>
                    <ContractData
                        drizzle={drizzle}
                        drizzleState={drizzleState}
                        contract="TestnetFaucet"
                        method="balanceOf"
                        methodArgs={[drizzle.contracts.DrizzleWeth.address]}
                        render={(value) => (
                            <div>
                                {value / 1000000000000000000}
                                <br />
                                <small>{value}</small>
                            </div>
                        )}
                    />
                </td>
            </tr>
            <tr>
                <td>
                    <strong>My Total Balance</strong>
                    <br />
                    <small>Represented in decimals specific for asset</small>
                </td>
                <td>Check your wallet :)</td>
                <td>
                    <ContractData
                        drizzle={drizzle}
                        drizzleState={drizzleState}
                        contract="CockpitDataProvider"
                        method="getMyTotalSupply"
                        methodArgs={[drizzle.contracts.DrizzleUsdt.address]}
                        render={(value) => (
                            <div>
                                {value / 1000000}
                                <br />
                                <small>{value}</small>
                            </div>
                        )}
                    />
                </td>
                <td>
                    <ContractData
                        drizzle={drizzle}
                        drizzleState={drizzleState}
                        contract="CockpitDataProvider"
                        method="getMyTotalSupply"
                        methodArgs={[drizzle.contracts.DrizzleUsdc.address]}
                        render={(value) => (
                            <div>
                                {value / 1000000}
                                <br />
                                <small>{value}</small>
                            </div>
                        )}
                    />
                </td>
                <td>
                    <ContractData
                        drizzle={drizzle}
                        drizzleState={drizzleState}
                        contract="CockpitDataProvider"
                        method="getMyTotalSupply"
                        methodArgs={[drizzle.contracts.DrizzleDai.address]}
                        render={(value) => (
                            <div>
                                {value / 1000000000000000000}
                                <br />
                                <small>{value}</small>
                            </div>
                        )}
                    />
                </td>
                <td>
                    <ContractData
                        drizzle={drizzle}
                        drizzleState={drizzleState}
                        contract="CockpitDataProvider"
                        method="getMyTotalSupply"
                        methodArgs={[drizzle.contracts.DrizzleWeth.address]}
                        render={(value) => (
                            <div>
                                {value / 1000000000000000000}
                                <br />
                                <small>{value}</small>
                            </div>
                        )}
                    />
                </td>
            </tr>
        </table>
        <hr />
        <div className="row">
            <div className="col-md-4">
                <strong>Transfer ETH to specific address</strong>
                <br />
                <small>Value represented in WEI</small>
                <ContractForm drizzle={drizzle} contract="TestnetFaucet" method="transferEth" />
            </div>
            <div className="col-md-4">
                <strong>Transfer TOKENS to your wallet</strong>
                <br />
                <label>Max allowed value $1 000 000 USD</label>
                <br />
                <small>Max in 6 decimals: 1000000000000</small>
                <br />
                <small>Max in 18 decimals: 1000000000000000000000000</small>
                <ContractForm drizzle={drizzle} contract="TestnetFaucet" method="transfer" />
            </div>
            <div className="col-md-4">
                <strong>Claim all stables at once (USDT, USDC, DAI)</strong>
                <br />
                <label>First time $10 000 USD</label>
                <br />
                <small>Next $10 000 USD</small>
                <br />
                <ContractForm drizzle={drizzle} contract="TestnetFaucet" method="claim" />
            </div>
        </div>
    </div>
);

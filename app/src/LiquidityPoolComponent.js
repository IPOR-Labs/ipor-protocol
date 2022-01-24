import React from "react";
import { newContextComponents } from "@drizzle/react-components";

const { ContractData } = newContextComponents;

export default ({ drizzle, drizzleState }) => (
    <div className="section">
        <table className="table" align="center">
            <tr>
                <th scope="col">Exchange Rate</th>
                <th scope="col">USDT</th>
                <th scope="col">USDC</th>
                <th scope="col">DAI</th>
            </tr>
            <tr>
                <td></td>
                <td>
                    {process.env.REACT_APP_PRIV_TEST_NETWORK_USE_TEST_JOSEPH ===
                    "true" ? (
                        <ContractData
                            drizzle={drizzle}
                            drizzleState={drizzleState}
                            contract="ItfMiltonUsdt"
                            method="calculateExchangeRate"
                            methodArgs={[Math.floor(Date.now() / 1000)]}
                            render={(value) => (
                                <div>
                                    {value / 1000000000000000000}
                                    <br />
                                    <small>{value}</small>
                                </div>
                            )}
                        />
                    ) : (
                        <ContractData
                            drizzle={drizzle}
                            drizzleState={drizzleState}
                            contract="MiltonUsdt"
                            method="calculateExchangeRate"
                            methodArgs={[Math.floor(Date.now() / 1000)]}
                            render={(value) => (
                                <div>
                                    {value / 1000000000000000000}
                                    <br />
                                    <small>{value}</small>
                                </div>
                            )}
                        />
                    )}
                </td>
                <td>
                    {process.env.REACT_APP_PRIV_TEST_NETWORK_USE_TEST_JOSEPH ===
                    "true" ? (
                        <ContractData
                            drizzle={drizzle}
                            drizzleState={drizzleState}
                            contract="ItfMiltonUsdc"
                            method="calculateExchangeRate"
                            methodArgs={[Math.floor(Date.now() / 1000)]}
                            render={(value) => (
                                <div>
                                    {value / 1000000000000000000}
                                    <br />
                                    <small>{value}</small>
                                </div>
                            )}
                        />
                    ) : (
                        <ContractData
                            drizzle={drizzle}
                            drizzleState={drizzleState}
                            contract="MiltonUsdc"
                            method="calculateExchangeRate"
                            methodArgs={[Math.floor(Date.now() / 1000)]}
                            render={(value) => (
                                <div>
                                    {value / 1000000000000000000}
                                    <br />
                                    <small>{value}</small>
                                </div>
                            )}
                        />
                    )}
                </td>
                <td>
                    {process.env.REACT_APP_PRIV_TEST_NETWORK_USE_TEST_JOSEPH ===
                    "true" ? (
                        <ContractData
                            drizzle={drizzle}
                            drizzleState={drizzleState}
                            contract="ItfMiltonDai"
                            method="calculateExchangeRate"
                            methodArgs={[Math.floor(Date.now() / 1000)]}
                            render={(value) => (
                                <div>
                                    {value / 1000000000000000000}
                                    <br />
                                    <small>{value}</small>
                                </div>
                            )}
                        />
                    ) : (
                        <ContractData
                            drizzle={drizzle}
                            drizzleState={drizzleState}
                            contract="ItfMiltonDai"
                            method="calculateExchangeRate"
                            methodArgs={[Math.floor(Date.now() / 1000)]}
                            render={(value) => (
                                <div>
                                    {value / 1000000000000000000}
                                    <br />
                                    <small>{value}</small>
                                </div>
                            )}
                        />
                    )}
                </td>
            </tr>
        </table>
    </div>
);

import React from "react";
import { newContextComponents } from "@drizzle/react-components";

const { ContractData } = newContextComponents;

export default ({ drizzle, drizzleState }) => (
    <div>
        <table className="table" align="center">
            <tr>
                <th scope="col">SPREAD</th>
                <th scope="col">USDT</th>
                <th scope="col">USDC</th>
                <th scope="col">DAI</th>
            </tr>
            <tr>
                <td>SPREAD Pay Fixed</td>
                <td>
                    {process.env.REACT_APP_PRIV_TEST_NETWORK_USE_TEST_MILTON ===
                    "true" ? (
                        <ContractData
                            drizzle={drizzle}
                            drizzleState={drizzleState}
                            contract="ItfMilton"
                            method="calculateSpread"
                            methodArgs={[
                                drizzle.contracts.UsdtMockedToken.address,
                            ]}
                            render={(item) => (
                                <div>
                                    {item.spreadPayFixedValue /
                                        1000000000000000000}
                                    <br />
                                    <small>{item.spreadPayFixedValue}</small>
                                </div>
                            )}
                        />
                    ) : (
                        <ContractData
                            drizzle={drizzle}
                            drizzleState={drizzleState}
                            contract="Milton"
                            method="calculateSpread"
                            methodArgs={[
                                drizzle.contracts.UsdtMockedToken.address,
                            ]}
                            render={(item) => (
                                <div>
                                    {item.spreadPayFixedValue /
                                        1000000000000000000}
                                    <br />
                                    <small>{item.spreadPayFixedValue}</small>
                                </div>
                            )}
                        />
                    )}
                </td>
                <td>
                    {process.env.REACT_APP_PRIV_TEST_NETWORK_USE_TEST_MILTON ===
                    "true" ? (
                        <ContractData
                            drizzle={drizzle}
                            drizzleState={drizzleState}
                            contract="ItfMilton"
                            method="calculateSpread"
                            methodArgs={[
                                drizzle.contracts.UsdcMockedToken.address,
                            ]}
                            render={(item) => (
                                <div>
                                    {item.spreadPayFixedValue /
                                        1000000000000000000}
                                    <br />
                                    <small>{item.spreadPayFixedValue}</small>
                                </div>
                            )}
                        />
                    ) : (
                        <ContractData
                            drizzle={drizzle}
                            drizzleState={drizzleState}
                            contract="Milton"
                            method="calculateSpread"
                            methodArgs={[
                                drizzle.contracts.UsdcMockedToken.address,
                            ]}
                            render={(item) => (
                                <div>
                                    {item.spreadPayFixedValue /
                                        1000000000000000000}
                                    <br />
                                    <small>{item.spreadPayFixedValue}</small>
                                </div>
                            )}
                        />
                    )}
                </td>
                <td>
                    {process.env.REACT_APP_PRIV_TEST_NETWORK_USE_TEST_MILTON ===
                    "true" ? (
                        <ContractData
                            drizzle={drizzle}
                            drizzleState={drizzleState}
                            contract="ItfMilton"
                            method="calculateSpread"
                            methodArgs={[
                                drizzle.contracts.DaiMockedToken.address,
                            ]}
                            render={(item) => (
                                <div>
                                    {item.spreadPayFixedValue /
                                        1000000000000000000}
                                    <br />
                                    <small>{item.spreadPayFixedValue}</small>
                                </div>
                            )}
                        />
                    ) : (
                        <ContractData
                            drizzle={drizzle}
                            drizzleState={drizzleState}
                            contract="Milton"
                            method="calculateSpread"
                            methodArgs={[
                                drizzle.contracts.DaiMockedToken.address,
                            ]}
                            render={(item) => (
                                <div>
                                    {item.spreadPayFixedValue /
                                        1000000000000000000}
                                    <br />
                                    <small>{item.spreadPayFixedValue}</small>
                                </div>
                            )}
                        />
                    )}
                </td>
            </tr>
            <tr>
                <td>SPREAD Receive Fixed</td>
                <td>
                    {process.env.REACT_APP_PRIV_TEST_NETWORK_USE_TEST_MILTON ===
                    "true" ? (
                        <ContractData
                            drizzle={drizzle}
                            drizzleState={drizzleState}
                            contract="ItfMilton"
                            method="calculateSpread"
                            methodArgs={[
                                drizzle.contracts.UsdtMockedToken.address,
                            ]}
                            render={(item) => (
                                <div>
                                    {item.spreadRecFixedValue /
                                        1000000000000000000}
                                    <br />
                                    <small>{item.spreadRecFixedValue}</small>
                                </div>
                            )}
                        />
                    ) : (
                        <ContractData
                            drizzle={drizzle}
                            drizzleState={drizzleState}
                            contract="Milton"
                            method="calculateSpread"
                            methodArgs={[
                                drizzle.contracts.UsdtMockedToken.address,
                            ]}
                            render={(item) => (
                                <div>
                                    {item.spreadRecFixedValue /
                                        1000000000000000000}
                                    <br />
                                    <small>{item.spreadRecFixedValue}</small>
                                </div>
                            )}
                        />
                    )}
                </td>
                <td>
                    {process.env.REACT_APP_PRIV_TEST_NETWORK_USE_TEST_MILTON ===
                    "true" ? (
                        <ContractData
                            drizzle={drizzle}
                            drizzleState={drizzleState}
                            contract="ItfMilton"
                            method="calculateSpread"
                            methodArgs={[
                                drizzle.contracts.UsdcMockedToken.address,
                            ]}
                            render={(item) => (
                                <div>
                                    {item.spreadRecFixedValue /
                                        1000000000000000000}
                                    <br />
                                    <small>{item.spreadRecFixedValue}</small>
                                </div>
                            )}
                        />
                    ) : (
                        <ContractData
                            drizzle={drizzle}
                            drizzleState={drizzleState}
                            contract="Milton"
                            method="calculateSpread"
                            methodArgs={[
                                drizzle.contracts.UsdcMockedToken.address,
                            ]}
                            render={(item) => (
                                <div>
                                    {item.spreadRecFixedValue /
                                        1000000000000000000}
                                    <br />
                                    <small>{item.spreadRecFixedValue}</small>
                                </div>
                            )}
                        />
                    )}
                </td>
                <td>
                    {process.env.REACT_APP_PRIV_TEST_NETWORK_USE_TEST_MILTON ===
                    "true" ? (
                        <ContractData
                            drizzle={drizzle}
                            drizzleState={drizzleState}
                            contract="ItfMilton"
                            method="calculateSpread"
                            methodArgs={[
                                drizzle.contracts.DaiMockedToken.address,
                            ]}
                            render={(item) => (
                                <div>
                                    {item.spreadRecFixedValue /
                                        1000000000000000000}
                                    <br />
                                    <small>{item.spreadRecFixedValue}</small>
                                </div>
                            )}
                        />
                    ) : (
                        <ContractData
                            drizzle={drizzle}
                            drizzleState={drizzleState}
                            contract="Milton"
                            method="calculateSpread"
                            methodArgs={[
                                drizzle.contracts.DaiMockedToken.address,
                            ]}
                            render={(item) => (
                                <div>
                                    {item.spreadRecFixedValue /
                                        1000000000000000000}
                                    <br />
                                    <small>{item.spreadRecFixedValue}</small>
                                </div>
                            )}
                        />
                    )}
                </td>
            </tr>
        </table>
        <hr />
    </div>
);

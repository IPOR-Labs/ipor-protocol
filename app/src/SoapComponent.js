import React from "react";
import { newContextComponents } from "@drizzle/react-components";

const { ContractData } = newContextComponents;

export default ({ drizzle, drizzleState }) => (
    <div>
        <table className="table" align="center">
            <tr>
                <th scope="col">SOAP</th>
                <th scope="col">USDT</th>
                <th scope="col">USDC</th>
                <th scope="col">DAI</th>
            </tr>
            <tr>
                <td>SOAP Pay Fixed</td>
                <td>
                    {process.env.REACT_APP_PRIV_TEST_NETWORK_USE_TEST_MILTON ===
                    "true" ? (
                        <ContractData
                            drizzle={drizzle}
                            drizzleState={drizzleState}
                            contract="TestMilton"
                            method="calculateSoap"
                            methodArgs={[
                                drizzle.contracts.UsdtMockedToken.address,
                            ]}
                            render={(soap) => (
                                <div>
                                    {soap.soapPf / 1000000}
                                    <br />
                                    <small>{soap.soapPf}</small>
                                </div>
                            )}
                        />
                    ) : (
                        <ContractData
                            drizzle={drizzle}
                            drizzleState={drizzleState}
                            contract="Milton"
                            method="calculateSoap"
                            methodArgs={[
                                drizzle.contracts.UsdtMockedToken.address,
                            ]}
                            render={(soap) => (
                                <div>
                                    {soap.soapPf / 1000000}
                                    <br />
                                    <small>{soap.soapPf}</small>
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
                            contract="TestMilton"
                            method="calculateSoap"
                            methodArgs={[
                                drizzle.contracts.UsdcMockedToken.address,
                            ]}
                            render={(soap) => (
                                <div>
                                    {soap.soapPf / 1000000}
                                    <br />
                                    <small>{soap.soapPf}</small>
                                </div>
                            )}
                        />
                    ) : (
                        <ContractData
                            drizzle={drizzle}
                            drizzleState={drizzleState}
                            contract="Milton"
                            method="calculateSoap"
                            methodArgs={[
                                drizzle.contracts.UsdcMockedToken.address,
                            ]}
                            render={(soap) => (
                                <div>
                                    {soap.soapPf / 1000000}
                                    <br />
                                    <small>{soap.soapPf}</small>
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
                            contract="TestMilton"
                            method="calculateSoap"
                            methodArgs={[
                                drizzle.contracts.DaiMockedToken.address,
                            ]}
                            render={(soap) => (
                                <div>
                                    {soap.soapPf / 1000000000000000000}
                                    <br />
                                    <small>{soap.soapPf}</small>
                                </div>
                            )}
                        />
                    ) : (
                        <ContractData
                            drizzle={drizzle}
                            drizzleState={drizzleState}
                            contract="Milton"
                            method="calculateSoap"
                            methodArgs={[
                                drizzle.contracts.DaiMockedToken.address,
                            ]}
                            render={(soap) => (
                                <div>
                                    {soap.soapPf / 1000000000000000000}
                                    <br />
                                    <small>{soap.soapPf}</small>
                                </div>
                            )}
                        />
                    )}
                </td>
            </tr>
            <tr>
                <td>SOAP Receive Fixed</td>
                <td>
                    {process.env.REACT_APP_PRIV_TEST_NETWORK_USE_TEST_MILTON ===
                    "true" ? (
                        <ContractData
                            drizzle={drizzle}
                            drizzleState={drizzleState}
                            contract="TestMilton"
                            method="calculateSoap"
                            methodArgs={[
                                drizzle.contracts.UsdtMockedToken.address,
                            ]}
                            render={(soap) => (
                                <div>
                                    {soap.soapRf / 1000000}
                                    <br />
                                    <small>{soap.soapRf}</small>
                                </div>
                            )}
                        />
                    ) : (
                        <ContractData
                            drizzle={drizzle}
                            drizzleState={drizzleState}
                            contract="Milton"
                            method="calculateSoap"
                            methodArgs={[
                                drizzle.contracts.UsdtMockedToken.address,
                            ]}
                            render={(soap) => (
                                <div>
                                    {soap.soapRf / 1000000}
                                    <br />
                                    <small>{soap.soapRf}</small>
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
                            contract="TestMilton"
                            method="calculateSoap"
                            methodArgs={[
                                drizzle.contracts.UsdcMockedToken.address,
                            ]}
                            render={(soap) => (
                                <div>
                                    {soap.soapRf / 1000000}
                                    <br />
                                    <small>{soap.soapRf}</small>
                                </div>
                            )}
                        />
                    ) : (
                        <ContractData
                            drizzle={drizzle}
                            drizzleState={drizzleState}
                            contract="Milton"
                            method="calculateSoap"
                            methodArgs={[
                                drizzle.contracts.UsdcMockedToken.address,
                            ]}
                            render={(soap) => (
                                <div>
                                    {soap.soapRf / 1000000}
                                    <br />
                                    <small>{soap.soapRf}</small>
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
                            contract="TestMilton"
                            method="calculateSoap"
                            methodArgs={[
                                drizzle.contracts.DaiMockedToken.address,
                            ]}
                            render={(soap) => (
                                <div>
                                    {soap.soapRf / 1000000000000000000}
                                    <br />
                                    <small>{soap.soapRf}</small>
                                </div>
                            )}
                        />
                    ) : (
                        <ContractData
                            drizzle={drizzle}
                            drizzleState={drizzleState}
                            contract="Milton"
                            method="calculateSoap"
                            methodArgs={[
                                drizzle.contracts.DaiMockedToken.address,
                            ]}
                            render={(soap) => (
                                <div>
                                    {soap.soapRf / 1000000000000000000}
                                    <br />
                                    <small>{soap.soapRf}</small>
                                </div>
                            )}
                        />
                    )}
                </td>
            </tr>
            <tr>
                <td>SOAP Total</td>
                <td>
                    {process.env.REACT_APP_PRIV_TEST_NETWORK_USE_TEST_MILTON ===
                    "true" ? (
                        <ContractData
                            drizzle={drizzle}
                            drizzleState={drizzleState}
                            contract="TestMilton"
                            method="calculateSoap"
                            methodArgs={[
                                drizzle.contracts.UsdtMockedToken.address,
                            ]}
                            render={(soap) => (
                                <div>
                                    {soap.soap / 1000000}
                                    <br />
                                    <small>{soap.soap}</small>
                                </div>
                            )}
                        />
                    ) : (
                        <ContractData
                            drizzle={drizzle}
                            drizzleState={drizzleState}
                            contract="Milton"
                            method="calculateSoap"
                            methodArgs={[
                                drizzle.contracts.UsdtMockedToken.address,
                            ]}
                            render={(soap) => (
                                <div>
                                    {soap.soap / 1000000}
                                    <br />
                                    <small>{soap.soap}</small>
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
                            contract="TestMilton"
                            method="calculateSoap"
                            methodArgs={[
                                drizzle.contracts.UsdcMockedToken.address,
                            ]}
                            render={(soap) => (
                                <div>
                                    {soap.soap / 1000000}
                                    <br />
                                    <small>{soap.soap}</small>
                                </div>
                            )}
                        />
                    ) : (
                        <ContractData
                            drizzle={drizzle}
                            drizzleState={drizzleState}
                            contract="Milton"
                            method="calculateSoap"
                            methodArgs={[
                                drizzle.contracts.UsdcMockedToken.address,
                            ]}
                            render={(soap) => (
                                <div>
                                    {soap.soap / 1000000}
                                    <br />
                                    <small>{soap.soap}</small>
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
                            contract="TestMilton"
                            method="calculateSoap"
                            methodArgs={[
                                drizzle.contracts.DaiMockedToken.address,
                            ]}
                            render={(soap) => (
                                <div>
                                    {soap.soap / 1000000000000000000}
                                    <br />
                                    <small>{soap.soap}</small>
                                </div>
                            )}
                        />
                    ) : (
                        <ContractData
                            drizzle={drizzle}
                            drizzleState={drizzleState}
                            contract="Milton"
                            method="calculateSoap"
                            methodArgs={[
                                drizzle.contracts.DaiMockedToken.address,
                            ]}
                            render={(soap) => (
                                <div>
                                    {soap.soap / 1000000000000000000}
                                    <br />
                                    <small>{soap.soap}</small>
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

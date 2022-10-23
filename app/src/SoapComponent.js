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
                <th scope="col">WETH</th>
            </tr>
            <tr>
                <td>SOAP Pay Fixed</td>
                <td>
                    <ContractData
                        drizzle={drizzle}
                        drizzleState={drizzleState}
                        contract="DrizzleMiltonUsdt"
                        method="calculateSoap"
                        render={(soap) => (
                            <div>
                                {soap.soapPayFixed / 1000000000000000000}
                                <br />
                                <small>{soap.soapPayFixed}</small>
                            </div>
                        )}
                    />
                </td>
                <td>
                    <ContractData
                        drizzle={drizzle}
                        drizzleState={drizzleState}
                        contract="DrizzleMiltonUsdc"
                        method="calculateSoap"
                        render={(soap) => (
                            <div>
                                {soap.soapPayFixed / 1000000000000000000}
                                <br />
                                <small>{soap.soapPayFixed}</small>
                            </div>
                        )}
                    />
                </td>
                <td>
                    <ContractData
                        drizzle={drizzle}
                        drizzleState={drizzleState}
                        contract="DrizzleMiltonDai"
                        method="calculateSoap"
                        render={(soap) => (
                            <div>
                                {soap.soapPayFixed / 1000000000000000000}
                                <br />
                                <small>{soap.soapPayFixed}</small>
                            </div>
                        )}
                    />
                </td>
                <td>
                    <ContractData
                        drizzle={drizzle}
                        drizzleState={drizzleState}
                        contract="DrizzleMiltonWeth"
                        method="calculateSoap"
                        render={(soap) => (
                            <div>
                                {soap.soapPayFixed / 1000000000000000000}
                                <br />
                                <small>{soap.soapPayFixed}</small>
                            </div>
                        )}
                    />
                </td>
            </tr>
            <tr>
                <td>SOAP Receive Fixed</td>
                <td>
                    <ContractData
                        drizzle={drizzle}
                        drizzleState={drizzleState}
                        contract="DrizzleMiltonUsdt"
                        method="calculateSoap"
                        render={(soap) => (
                            <div>
                                {soap.soapReceiveFixed / 1000000000000000000}
                                <br />
                                <small>{soap.soapReceiveFixed}</small>
                            </div>
                        )}
                    />
                </td>
                <td>
                    <ContractData
                        drizzle={drizzle}
                        drizzleState={drizzleState}
                        contract="DrizzleMiltonUsdc"
                        method="calculateSoap"
                        render={(soap) => (
                            <div>
                                {soap.soapReceiveFixed / 1000000000000000000}
                                <br />
                                <small>{soap.soapReceiveFixed}</small>
                            </div>
                        )}
                    />
                </td>
                <td>
                    <ContractData
                        drizzle={drizzle}
                        drizzleState={drizzleState}
                        contract="DrizzleMiltonDai"
                        method="calculateSoap"
                        render={(soap) => (
                            <div>
                                {soap.soapReceiveFixed / 1000000000000000000}
                                <br />
                                <small>{soap.soapReceiveFixed}</small>
                            </div>
                        )}
                    />
                </td>
                <td>
                    <ContractData
                        drizzle={drizzle}
                        drizzleState={drizzleState}
                        contract="DrizzleMiltonWeth"
                        method="calculateSoap"
                        render={(soap) => (
                            <div>
                                {soap.soapReceiveFixed / 1000000000000000000}
                                <br />
                                <small>{soap.soapReceiveFixed}</small>
                            </div>
                        )}
                    />
                </td>
            </tr>
            <tr>
                <td>SOAP Total</td>
                <td>
                    <ContractData
                        drizzle={drizzle}
                        drizzleState={drizzleState}
                        contract="DrizzleMiltonUsdt"
                        method="calculateSoap"
                        render={(soap) => (
                            <div>
                                {soap.soap / 1000000000000000000}
                                <br />
                                <small>{soap.soap}</small>
                            </div>
                        )}
                    />
                </td>
                <td>
                    <ContractData
                        drizzle={drizzle}
                        drizzleState={drizzleState}
                        contract="DrizzleMiltonUsdc"
                        method="calculateSoap"
                        render={(soap) => (
                            <div>
                                {soap.soap / 1000000000000000000}
                                <br />
                                <small>{soap.soap}</small>
                            </div>
                        )}
                    />
                </td>
                <td>
                    <ContractData
                        drizzle={drizzle}
                        drizzleState={drizzleState}
                        contract="DrizzleMiltonDai"
                        method="calculateSoap"
                        render={(soap) => (
                            <div>
                                {soap.soap / 1000000000000000000}
                                <br />
                                <small>{soap.soap}</small>
                            </div>
                        )}
                    />
                </td>
                <td>
                    <ContractData
                        drizzle={drizzle}
                        drizzleState={drizzleState}
                        contract="DrizzleMiltonWeth"
                        method="calculateSoap"
                        render={(soap) => (
                            <div>
                                {soap.soap / 1000000000000000000}
                                <br />
                                <small>{soap.soap}</small>
                            </div>
                        )}
                    />
                </td>
            </tr>
        </table>
        <hr />
    </div>
);

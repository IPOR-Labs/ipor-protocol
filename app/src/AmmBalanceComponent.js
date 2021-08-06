import React from "react";
import {newContextComponents} from "@drizzle/react-components";

const {ContractData} = newContextComponents;

export default ({drizzle, drizzleState}) => (
    <div className="section">
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
                    <ContractData
                        drizzle={drizzle}
                        drizzleState={drizzleState}
                        contract="IporAmmV1"
                        method="calculateSpread"
                        methodArgs={["USDT"]}
                        render={(item) => (
                            <div>
                                {item.spreadPf / 1000000000000000000}<br/>
                                <small>{item.spreadPf}</small>
                            </div>
                        )}
                    />
                </td>
                <td>
                    <ContractData
                        drizzle={drizzle}
                        drizzleState={drizzleState}
                        contract="IporAmmV1"
                        method="calculateSpread"
                        methodArgs={["USDC"]}
                        render={(item) => (
                            <div>
                                {item.spreadPf / 1000000000000000000}<br/>
                                <small>{item.spreadPf}</small>
                            </div>
                        )}
                    />
                </td>
                <td>
                    <ContractData
                        drizzle={drizzle}
                        drizzleState={drizzleState}
                        contract="IporAmmV1"
                        method="calculateSpread"
                        methodArgs={["DAI"]}
                        render={(item) => (
                            <div>
                                {item.spreadPf / 1000000000000000000}<br/>
                                <small>{item.spreadPf}</small>
                            </div>
                        )}
                    />
                </td>
            </tr>
            <tr>
                <td>SPREAD Receive Fixed</td>
                <td>
                    <ContractData
                        drizzle={drizzle}
                        drizzleState={drizzleState}
                        contract="IporAmmV1"
                        method="calculateSpread"
                        methodArgs={["USDT"]}
                        render={(item) => (
                            <div>
                                {item.spreadRf / 1000000000000000000}<br/>
                                <small>{item.spreadRf}</small>
                            </div>
                        )}
                    />
                </td>
                <td>
                    <ContractData
                        drizzle={drizzle}
                        drizzleState={drizzleState}
                        contract="IporAmmV1"
                        method="calculateSpread"
                        methodArgs={["USDC"]}
                        render={(item) => (
                            <div>
                                {item.spreadRf / 1000000000000000000}<br/>
                                <small>{item.spreadRf}</small>
                            </div>
                        )}
                    />
                </td>
                <td>
                    <ContractData
                        drizzle={drizzle}
                        drizzleState={drizzleState}
                        contract="IporAmmV1"
                        method="calculateSpread"
                        methodArgs={["DAI"]}
                        render={(item) => (
                            <div>
                                {item.spreadRf / 1000000000000000000}<br/>
                                <small>{item.spreadRf}</small>
                            </div>
                        )}
                    />
                </td>
            </tr>
        </table>
        <hr/>
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
                    <ContractData
                        drizzle={drizzle}
                        drizzleState={drizzleState}
                        contract="IporAmmV1"
                        method="calculateSoap"
                        methodArgs={["USDT"]}
                        render={(soap) => (
                            <div>
                                {soap.soapPf / 1000000000000000000}<br/>
                                <small>{soap.soapPf}</small>
                            </div>
                        )}
                    />
                </td>
                <td>
                    <ContractData
                        drizzle={drizzle}
                        drizzleState={drizzleState}
                        contract="IporAmmV1"
                        method="calculateSoap"
                        methodArgs={["USDC"]}
                        render={(soap) => (
                            <div>
                                {soap.soapPf / 1000000000000000000}<br/>
                                <small>{soap.soapPf}</small>
                            </div>
                        )}
                    />
                </td>
                <td>
                    <ContractData
                        drizzle={drizzle}
                        drizzleState={drizzleState}
                        contract="IporAmmV1"
                        method="calculateSoap"
                        methodArgs={["DAI"]}
                        render={(soap) => (
                            <div>
                                {soap.soapPf / 1000000000000000000}<br/>
                                <small>{soap.soapPf}</small>
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
                        contract="IporAmmV1"
                        method="calculateSoap"
                        methodArgs={["USDT"]}
                        render={(soap) => (
                            <div>
                                {soap.soapRf / 1000000000000000000}<br/>
                                <small>{soap.soapRf}</small>
                            </div>
                        )}
                    />
                </td>
                <td>
                    <ContractData
                        drizzle={drizzle}
                        drizzleState={drizzleState}
                        contract="IporAmmV1"
                        method="calculateSoap"
                        methodArgs={["USDC"]}
                        render={(soap) => (
                            <div>
                                {soap.soapRf / 1000000000000000000}<br/>
                                <small>{soap.soapRf}</small>
                            </div>
                        )}
                    />
                </td>
                <td>
                    <ContractData
                        drizzle={drizzle}
                        drizzleState={drizzleState}
                        contract="IporAmmV1"
                        method="calculateSoap"
                        methodArgs={["DAI"]}
                        render={(soap) => (
                            <div>
                                {soap.soapRf / 1000000000000000000}<br/>
                                <small>{soap.soapRf}</small>
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
                        contract="IporAmmV1"
                        method="calculateSoap"
                        methodArgs={["USDT"]}
                        render={(soap) => (
                            <div>
                                {soap.soap / 1000000000000000000}<br/>
                                <small>{soap.soap}</small>
                            </div>
                        )}
                    />
                </td>
                <td>
                    <ContractData
                        drizzle={drizzle}
                        drizzleState={drizzleState}
                        contract="IporAmmV1"
                        method="calculateSoap"
                        methodArgs={["USDC"]}
                        render={(soap) => (
                            <div>
                                {soap.soap / 1000000000000000000}<br/>
                                <small>{soap.soap}</small>
                            </div>
                        )}
                    />
                </td>
                <td>
                    <ContractData
                        drizzle={drizzle}
                        drizzleState={drizzleState}
                        contract="IporAmmV1"
                        method="calculateSoap"
                        methodArgs={["DAI"]}
                        render={(soap) => (
                            <div>
                                {soap.soap / 1000000000000000000}<br/>
                                <small>{soap.soap}</small>
                            </div>
                        )}
                    />
                </td>
            </tr>
        </table>

        <hr/>
        <table className="table" align="center">
            <tr>
                <th scope="col">Balance</th>
                <th scope="col">USDT</th>
                <th scope="col">USDC</th>
                <th scope="col">DAI</th>
            </tr>
            <tr>
                <td>Derivatives</td>
                <td>
                    <ContractData
                        drizzle={drizzle}
                        drizzleState={drizzleState}
                        contract="IporAmmV1"
                        method="derivativesTotalBalances"
                        methodArgs={["USDT"]}
                        render={(value) => (
                            <div>
                                {value / 1000000000000000000}<br/>
                                <small>{value}</small>
                            </div>
                        )}
                    />
                </td>
                <td>
                    <ContractData
                        drizzle={drizzle}
                        drizzleState={drizzleState}
                        contract="IporAmmV1"
                        method="derivativesTotalBalances"
                        methodArgs={["USDC"]}
                        render={(value) => (
                            <div>
                                {value / 1000000000000000000}<br/>
                                <small>{value}</small>
                            </div>
                        )}
                    />
                </td>
                <td>
                    <ContractData
                        drizzle={drizzle}
                        drizzleState={drizzleState}
                        contract="IporAmmV1"
                        method="derivativesTotalBalances"
                        methodArgs={["DAI"]}
                        render={(value) => (
                            <div>
                                {value / 1000000000000000000}<br/>
                                <small>{value}</small>
                            </div>
                        )}
                    />
                </td>
            </tr>
            <tr>
                <td>Liquidity Pool (including Opening Fee)</td>
                <td>
                    <ContractData
                        drizzle={drizzle}
                        drizzleState={drizzleState}
                        contract="IporAmmV1"
                        method="liquidityPoolTotalBalances"
                        methodArgs={["USDT"]}
                        render={(value) => (
                            <div>
                                {value / 1000000000000000000}<br/>
                                <small>{value}</small>
                            </div>
                        )}
                    />
                </td>
                <td>
                    <ContractData
                        drizzle={drizzle}
                        drizzleState={drizzleState}
                        contract="IporAmmV1"
                        method="liquidityPoolTotalBalances"
                        methodArgs={["USDC"]}
                        render={(value) => (
                            <div>
                                {value / 1000000000000000000}<br/>
                                <small>{value}</small>
                            </div>
                        )}
                    />
                </td>
                <td>
                    <ContractData
                        drizzle={drizzle}
                        drizzleState={drizzleState}
                        contract="IporAmmV1"
                        method="liquidityPoolTotalBalances"
                        methodArgs={["DAI"]}
                        render={(value) => (
                            <div>
                                {value / 1000000000000000000}<br/>
                                <small>{value}</small>
                            </div>
                        )}
                    />
                </td>
            </tr>
            <tr>
                <td>Opening Fee</td>
                <td>
                    <ContractData
                        drizzle={drizzle}
                        drizzleState={drizzleState}
                        contract="IporAmmV1"
                        method="openingFeeTotalBalances"
                        methodArgs={["USDT"]}
                        render={(value) => (
                            <div>
                                {value / 1000000000000000000}<br/>
                                <small>{value}</small>
                            </div>
                        )}
                    />
                </td>
                <td>
                    <ContractData
                        drizzle={drizzle}
                        drizzleState={drizzleState}
                        contract="IporAmmV1"
                        method="openingFeeTotalBalances"
                        methodArgs={["USDC"]}
                        render={(value) => (
                            <div>
                                {value / 1000000000000000000}<br/>
                                <small>{value}</small>
                            </div>
                        )}
                    />
                </td>
                <td>
                    <ContractData
                        drizzle={drizzle}
                        drizzleState={drizzleState}
                        contract="IporAmmV1"
                        method="openingFeeTotalBalances"
                        methodArgs={["DAI"]}
                        render={(value) => (
                            <div>
                                {value / 1000000000000000000}<br/>
                                <small>{value}</small>
                            </div>
                        )}
                    />
                </td>
            </tr>
            <tr>
                <td>Liquidation Deposit Fee</td>
                <td>
                    <ContractData
                        drizzle={drizzle}
                        drizzleState={drizzleState}
                        contract="IporAmmV1"
                        method="liquidationDepositTotalBalances"
                        methodArgs={["USDT"]}
                        render={(value) => (
                            <div>
                                {value / 1000000000000000000}<br/>
                                <small>{value}</small>
                            </div>
                        )}
                    />
                </td>
                <td>
                    <ContractData
                        drizzle={drizzle}
                        drizzleState={drizzleState}
                        contract="IporAmmV1"
                        method="liquidationDepositTotalBalances"
                        methodArgs={["USDC"]}
                        render={(value) => (
                            <div>
                                {value / 1000000000000000000}<br/>
                                <small>{value}</small>
                            </div>
                        )}
                    />
                </td>
                <td>
                    <ContractData
                        drizzle={drizzle}
                        drizzleState={drizzleState}
                        contract="IporAmmV1"
                        method="liquidationDepositTotalBalances"
                        methodArgs={["DAI"]}
                        render={(value) => (
                            <div>
                                {value / 1000000000000000000}<br/>
                                <small>{value}</small>
                            </div>
                        )}
                    />
                </td>
            </tr>
            <tr>
                <td>Ipor Publication Fee</td>
                <td>
                    <ContractData
                        drizzle={drizzle}
                        drizzleState={drizzleState}
                        contract="IporAmmV1"
                        method="iporPublicationFeeTotalBalances"
                        methodArgs={["USDT"]}
                        render={(value) => (
                            <div>
                                {value / 1000000000000000000}<br/>
                                <small>{value}</small>
                            </div>
                        )}
                    />
                </td>
                <td>
                    <ContractData
                        drizzle={drizzle}
                        drizzleState={drizzleState}
                        contract="IporAmmV1"
                        method="iporPublicationFeeTotalBalances"
                        methodArgs={["USDC"]}
                        render={(value) => (
                            <div>
                                {value / 1000000000000000000}<br/>
                                <small>{value}</small>
                            </div>
                        )}
                    />
                </td>
                <td>
                    <ContractData
                        drizzle={drizzle}
                        drizzleState={drizzleState}
                        contract="IporAmmV1"
                        method="iporPublicationFeeTotalBalances"
                        methodArgs={["DAI"]}
                        render={(value) => (
                            <div>
                                {value / 1000000000000000000}<br/>
                                <small>{value}</small>
                            </div>
                        )}
                    />
                </td>
            </tr>
        </table>
    </div>
);

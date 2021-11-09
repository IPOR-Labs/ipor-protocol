import React from "react";
import {newContextComponents} from "@drizzle/react-components";
import SpreadComponent from "./SpreadComponent";
import SoapComponent from "./SoapComponent";

const {ContractData} = newContextComponents;

export default ({drizzle, drizzleState}) => (
    <div className="section">
        <SpreadComponent
            drizzle={drizzle}
            drizzleState={drizzleState}
        />
        <SoapComponent
            drizzle={drizzle}
            drizzleState={drizzleState}
        />

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
                        contract="MiltonStorage"
                        method="balances"
                        methodArgs={[drizzle.contracts.UsdtMockedToken.address]}
                        render={(value) => (
                            <div>
                                {value.derivatives / 1000000}<br/>
                                <small>{value.derivatives}</small>
                            </div>
                        )}
                    />
                </td>
                <td>
                    <ContractData
                        drizzle={drizzle}
                        drizzleState={drizzleState}
                        contract="MiltonStorage"
                        method="balances"
                        methodArgs={[drizzle.contracts.UsdcMockedToken.address]}
                        render={(value) => (
                            <div>
                                {value.derivatives / 1000000}<br/>
                                <small>{value.derivatives}</small>
                            </div>
                        )}
                    />
                </td>
                <td>
                    <ContractData
                        drizzle={drizzle}
                        drizzleState={drizzleState}
                        contract="MiltonStorage"
                        method="balances"
                        methodArgs={[drizzle.contracts.DaiMockedToken.address]}
                        render={(value) => (
                            <div>
                                {value.derivatives / 1000000000000000000}<br/>
                                <small>{value.derivatives}</small>
                            </div>
                        )}
                    />
                </td>
            </tr>
            <tr>
                <td>Liquidity Pool (including part of Opening Fee)</td>
                <td>
                    <ContractData
                        drizzle={drizzle}
                        drizzleState={drizzleState}
                        contract="MiltonStorage"
                        method="balances"
                        methodArgs={[drizzle.contracts.UsdtMockedToken.address]}
                        render={(value) => (
                            <div>
                                {value.liquidityPool / 1000000}<br/>
                                <small>{value.liquidityPool}</small>
                            </div>
                        )}
                    />
                </td>
                <td>
                    <ContractData
                        drizzle={drizzle}
                        drizzleState={drizzleState}
                        contract="MiltonStorage"
                        method="balances"
                        methodArgs={[drizzle.contracts.UsdcMockedToken.address]}
                        render={(value) => (
                            <div>
                                {value.liquidityPool / 1000000}<br/>
                                <small>{value.liquidityPool}</small>
                            </div>
                        )}
                    />
                </td>
                <td>
                    <ContractData
                        drizzle={drizzle}
                        drizzleState={drizzleState}
                        contract="MiltonStorage"
                        method="balances"
                        methodArgs={[drizzle.contracts.DaiMockedToken.address]}
                        render={(value) => (
                            <div>
                                {value.liquidityPool / 1000000000000000000}<br/>
                                <small>{value.liquidityPool}</small>
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
                        contract="MiltonStorage"
                        method="balances"
                        methodArgs={[drizzle.contracts.UsdtMockedToken.address]}
                        render={(value) => (
                            <div>
                                {value.openingFee / 1000000}<br/>
                                <small>{value.openingFee}</small>
                            </div>
                        )}
                    />
                </td>
                <td>
                    <ContractData
                        drizzle={drizzle}
                        drizzleState={drizzleState}
                        contract="MiltonStorage"
                        method="balances"
                        methodArgs={[drizzle.contracts.UsdcMockedToken.address]}
                        render={(value) => (
                            <div>
                                {value.openingFee / 1000000}<br/>
                                <small>{value.openingFee}</small>
                            </div>
                        )}
                    />
                </td>
                <td>
                    <ContractData
                        drizzle={drizzle}
                        drizzleState={drizzleState}
                        contract="MiltonStorage"
                        method="balances"
                        methodArgs={[drizzle.contracts.DaiMockedToken.address]}
                        render={(value) => (
                            <div>
                                {value.openingFee / 1000000000000000000}<br/>
                                <small>{value.openingFee}</small>
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
                        contract="MiltonStorage"
                        method="balances"
                        methodArgs={[drizzle.contracts.UsdtMockedToken.address]}
                        render={(value) => (
                            <div>
                                {value.liquidationDeposit / 1000000}<br/>
                                <small>{value.liquidationDeposit}</small>
                            </div>
                        )}
                    />
                </td>
                <td>
                    <ContractData
                        drizzle={drizzle}
                        drizzleState={drizzleState}
                        contract="MiltonStorage"
                        method="balances"
                        methodArgs={[drizzle.contracts.UsdcMockedToken.address]}
                        render={(value) => (
                            <div>
                                {value.liquidationDeposit / 1000000}<br/>
                                <small>{value.liquidationDeposit}</small>
                            </div>
                        )}
                    />
                </td>
                <td>
                    <ContractData
                        drizzle={drizzle}
                        drizzleState={drizzleState}
                        contract="MiltonStorage"
                        method="balances"
                        methodArgs={[drizzle.contracts.DaiMockedToken.address]}
                        render={(value) => (
                            <div>
                                {value.liquidationDeposit / 1000000000000000000}<br/>
                                <small>{value.liquidationDeposit}</small>
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
                        contract="MiltonStorage"
                        method="balances"
                        methodArgs={[drizzle.contracts.UsdtMockedToken.address]}
                        render={(value) => (
                            <div>
                                {value.iporPublicationFee / 1000000}<br/>
                                <small>{value.iporPublicationFee}</small>
                            </div>
                        )}
                    />
                </td>
                <td>
                    <ContractData
                        drizzle={drizzle}
                        drizzleState={drizzleState}
                        contract="MiltonStorage"
                        method="balances"
                        methodArgs={[drizzle.contracts.UsdcMockedToken.address]}
                        render={(value) => (
                            <div>
                                {value.iporPublicationFee / 1000000}<br/>
                                <small>{value.iporPublicationFee}</small>
                            </div>
                        )}
                    />
                </td>
                <td>
                    <ContractData
                        drizzle={drizzle}
                        drizzleState={drizzleState}
                        contract="MiltonStorage"
                        method="balances"
                        methodArgs={[drizzle.contracts.DaiMockedToken.address]}
                        render={(value) => (
                            <div>
                                {value.iporPublicationFee / 1000000000000000000}<br/>
                                <small>{value.iporPublicationFee}</small>
                            </div>
                        )}
                    />
                </td>
            </tr>
            <tr>
                <td>TREASURY (including part of Opening Fee, including Income Tax)</td>
                <td>
                    <ContractData
                        drizzle={drizzle}
                        drizzleState={drizzleState}
                        contract="MiltonStorage"
                        method="balances"
                        methodArgs={[drizzle.contracts.UsdtMockedToken.address]}
                        render={(value) => (
                            <div>
                                {value.treasury / 1000000}<br/>
                                <small>{value.treasury}</small>
                            </div>
                        )}
                    />
                </td>
                <td>
                    <ContractData
                        drizzle={drizzle}
                        drizzleState={drizzleState}
                        contract="MiltonStorage"
                        method="balances"
                        methodArgs={[drizzle.contracts.UsdcMockedToken.address]}
                        render={(value) => (
                            <div>
                                {value.treasury / 1000000}<br/>
                                <small>{value.treasury}</small>
                            </div>
                        )}
                    />
                </td>
                <td>
                    <ContractData
                        drizzle={drizzle}
                        drizzleState={drizzleState}
                        contract="MiltonStorage"
                        method="balances"
                        methodArgs={[drizzle.contracts.DaiMockedToken.address]}
                        render={(value) => (
                            <div>
                                {value.treasury / 1000000000000000000}<br/>
                                <small>{value.treasury}</small>
                            </div>
                        )}
                    />
                </td>
            </tr>
        </table>
    </div>
);

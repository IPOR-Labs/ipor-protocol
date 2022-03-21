import React from "react";
import { newContextComponents } from "@drizzle/react-components";
import FrontendPositions from "./FrontendPositions";
import FrontendConfigurations from "./FrontendConfigurations";

const { ContractData, ContractForm } = newContextComponents;

export default ({ drizzle, drizzleState }) => (
    <div align="left">
        <table className="table">
            <tr>
                <th scope="col">Total Outstanding Notional</th>
                <th scope="col">
                    USDT
                    <br />
                    <small>{drizzle.contracts.UsdtMockedToken.address}</small>
                </th>
                <th scope="col">
                    USDC
                    <br />
                    <small>{drizzle.contracts.UsdcMockedToken.address}</small>
                </th>
                <th scope="col">
                    DAI
                    <br />
                    <small>{drizzle.contracts.DaiMockedToken.address}</small>
                </th>
            </tr>
            <tr>
                <td>Liquidity Pool Balance</td>
                <td>
                    <ContractData
                        drizzle={drizzle}
                        drizzleState={drizzleState}
                        contract="MiltonFacadeDataProvider"
                        method="getBalance"
                        methodArgs={[drizzle.contracts.UsdtMockedToken.address]}
                        render={(value) => (
                            <div>
                                {value.liquidityPool / 1000000000000000000}
                                <br />
                                <small>{value.liquidityPool}</small>
                            </div>
                        )}
                    />
                </td>
                <td>
                    <ContractData
                        drizzle={drizzle}
                        drizzleState={drizzleState}
                        contract="MiltonFacadeDataProvider"
                        method="getBalance"
                        methodArgs={[drizzle.contracts.UsdcMockedToken.address]}
                        render={(value) => (
                            <div>
                                {value.liquidityPool / 1000000000000000000}
                                <br />
                                <small>{value.liquidityPool}</small>
                            </div>
                        )}
                    />
                </td>
                <td>
                    <ContractData
                        drizzle={drizzle}
                        drizzleState={drizzleState}
                        contract="MiltonFacadeDataProvider"
                        method="getBalance"
                        methodArgs={[drizzle.contracts.DaiMockedToken.address]}
                        render={(value) => (
                            <div>
                                {value.liquidityPool / 1000000000000000000}
                                <br />
                                <small>{value.liquidityPool}</small>
                            </div>
                        )}
                    />
                </td>
            </tr>
            <tr>
                <td>Pay Fixed Total Notional Balance</td>
                <td>
                    <ContractData
                        drizzle={drizzle}
                        drizzleState={drizzleState}
                        contract="MiltonFacadeDataProvider"
                        method="getBalance"
                        methodArgs={[drizzle.contracts.UsdtMockedToken.address]}
                        render={(value) => (
                            <div>
                                {value.payFixedTotalNotional / 1000000000000000000}
                                <br />
                                <small>{value.payFixedTotalNotional}</small>
                            </div>
                        )}
                    />
                </td>
                <td>
                    <ContractData
                        drizzle={drizzle}
                        drizzleState={drizzleState}
                        contract="MiltonFacadeDataProvider"
                        method="getBalance"
                        methodArgs={[drizzle.contracts.UsdcMockedToken.address]}
                        render={(value) => (
                            <div>
                                {value.payFixedTotalNotional / 1000000000000000000}
                                <br />
                                <small>{value.payFixedTotalNotional}</small>
                            </div>
                        )}
                    />
                </td>
                <td>
                    <ContractData
                        drizzle={drizzle}
                        drizzleState={drizzleState}
                        contract="MiltonFacadeDataProvider"
                        method="getBalance"
                        methodArgs={[drizzle.contracts.DaiMockedToken.address]}
                        render={(value) => (
                            <div>
                                {value.payFixedTotalNotional / 1000000000000000000}
                                <br />
                                <small>{value.payFixedTotalNotional}</small>
                            </div>
                        )}
                    />
                </td>
            </tr>
            <tr>
                <td>Receive Fixed Total Notional Balance</td>
                <td>
                    <ContractData
                        drizzle={drizzle}
                        drizzleState={drizzleState}
                        contract="MiltonFacadeDataProvider"
                        method="getBalance"
                        methodArgs={[drizzle.contracts.UsdtMockedToken.address]}
                        render={(value) => (
                            <div>
                                {value.recFixedTotalNotional / 1000000000000000000}
                                <br />
                                <small>{value.recFixedTotalNotional}</small>
                            </div>
                        )}
                    />
                </td>
                <td>
                    <ContractData
                        drizzle={drizzle}
                        drizzleState={drizzleState}
                        contract="MiltonFacadeDataProvider"
                        method="getBalance"
                        methodArgs={[drizzle.contracts.UsdcMockedToken.address]}
                        render={(value) => (
                            <div>
                                {value.recFixedTotalNotional / 1000000000000000000}
                                <br />
                                <small>{value.recFixedTotalNotional}</small>
                            </div>
                        )}
                    />
                </td>
                <td>
                    <ContractData
                        drizzle={drizzle}
                        drizzleState={drizzleState}
                        contract="MiltonFacadeDataProvider"
                        method="getBalance"
                        methodArgs={[drizzle.contracts.DaiMockedToken.address]}
                        render={(value) => (
                            <div>
                                {value.recFixedTotalNotional / 1000000000000000000}
                                <br />
                                <small>{value.recFixedTotalNotional}</small>
                            </div>
                        )}
                    />
                </td>
            </tr>
            <tr>
                <td>Pay Fixed Total Collateral Balance</td>
                <td>
                    <ContractData
                        drizzle={drizzle}
                        drizzleState={drizzleState}
                        contract="MiltonFacadeDataProvider"
                        method="getBalance"
                        methodArgs={[drizzle.contracts.UsdtMockedToken.address]}
                        render={(value) => (
                            <div>
                                {value.payFixedTotalCollateral / 1000000000000000000}
                                <br />
                                <small>{value.payFixedTotalCollateral}</small>
                            </div>
                        )}
                    />
                </td>
                <td>
                    <ContractData
                        drizzle={drizzle}
                        drizzleState={drizzleState}
                        contract="MiltonFacadeDataProvider"
                        method="getBalance"
                        methodArgs={[drizzle.contracts.UsdcMockedToken.address]}
                        render={(value) => (
                            <div>
                                {value.payFixedTotalCollateral / 1000000000000000000}
                                <br />
                                <small>{value.payFixedTotalCollateral}</small>
                            </div>
                        )}
                    />
                </td>
                <td>
                    <ContractData
                        drizzle={drizzle}
                        drizzleState={drizzleState}
                        contract="MiltonFacadeDataProvider"
                        method="getBalance"
                        methodArgs={[drizzle.contracts.DaiMockedToken.address]}
                        render={(value) => (
                            <div>
                                {value.payFixedTotalCollateral / 1000000000000000000}
                                <br />
                                <small>{value.payFixedTotalCollateral}</small>
                            </div>
                        )}
                    />
                </td>
            </tr>
            <tr>
                <td>Receive Fixed Total Collateral Balance</td>
                <td>
                    <ContractData
                        drizzle={drizzle}
                        drizzleState={drizzleState}
                        contract="MiltonFacadeDataProvider"
                        method="getBalance"
                        methodArgs={[drizzle.contracts.UsdtMockedToken.address]}
                        render={(value) => (
                            <div>
                                {value.recFixedTotalCollateral / 1000000000000000000}
                                <br />
                                <small>{value.recFixedTotalCollateral}</small>
                            </div>
                        )}
                    />
                </td>
                <td>
                    <ContractData
                        drizzle={drizzle}
                        drizzleState={drizzleState}
                        contract="MiltonFacadeDataProvider"
                        method="getBalance"
                        methodArgs={[drizzle.contracts.UsdcMockedToken.address]}
                        render={(value) => (
                            <div>
                                {value.recFixedTotalCollateral / 1000000000000000000}
                                <br />
                                <small>{value.recFixedTotalCollateral}</small>
                            </div>
                        )}
                    />
                </td>
                <td>
                    <ContractData
                        drizzle={drizzle}
                        drizzleState={drizzleState}
                        contract="MiltonFacadeDataProvider"
                        method="getBalance"
                        methodArgs={[drizzle.contracts.DaiMockedToken.address]}
                        render={(value) => (
                            <div>
                                {value.recFixedTotalCollateral / 1000000000000000000}
                                <br />
                                <small>{value.recFixedTotalCollateral}</small>
                            </div>
                        )}
                    />
                </td>
            </tr>
            <tr>
                <td>ipToken Exchange Rate</td>
                <td>
                    <ContractData
                        drizzle={drizzle}
                        drizzleState={drizzleState}
                        contract="MiltonFacadeDataProvider"
                        method="getIpTokenExchangeRate"
                        methodArgs={[drizzle.contracts.UsdtMockedToken.address]}
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
                        contract="MiltonFacadeDataProvider"
                        method="getIpTokenExchangeRate"
                        methodArgs={[drizzle.contracts.UsdcMockedToken.address]}
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
                        contract="MiltonFacadeDataProvider"
                        method="getIpTokenExchangeRate"
                        methodArgs={[drizzle.contracts.DaiMockedToken.address]}
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
        <h5>Frontend Configuration</h5>
        <ContractData
            drizzle={drizzle}
            drizzleState={drizzleState}
            contract="MiltonFacadeDataProvider"
            method="getConfiguration"
            render={FrontendConfigurations}
        />
        <hr />
        <h5>My Positions - USDT</h5>
        <ContractData
            drizzle={drizzle}
            drizzleState={drizzleState}
            contract="MiltonFacadeDataProvider"
            method="getMySwaps"
            methodArgs={[drizzle.contracts.UsdtMockedToken.address, 0, 50]}
            render={FrontendPositions}
        />
        <h5>My Positions - USDC</h5>
        <ContractData
            drizzle={drizzle}
            drizzleState={drizzleState}
            contract="MiltonFacadeDataProvider"
            method="getMySwaps"
            methodArgs={[drizzle.contracts.UsdcMockedToken.address, 0, 50]}
            render={FrontendPositions}
        />
        <h5>My Positions - DAI</h5>
        <ContractData
            drizzle={drizzle}
            drizzleState={drizzleState}
            contract="MiltonFacadeDataProvider"
            method="getMySwaps"
            methodArgs={[drizzle.contracts.DaiMockedToken.address, 0, 50]}
            render={FrontendPositions}
        />
    </div>
);

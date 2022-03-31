import React from "react";
import { newContextComponents } from "@drizzle/react-components";
import SpreadComponent from "./SpreadComponent";
import SoapComponent from "./SoapComponent";

const { ContractData } = newContextComponents;

export default ({ drizzle, drizzleState }) => (
    <div>
        <SpreadComponent drizzle={drizzle} drizzleState={drizzleState} />
        <SoapComponent drizzle={drizzle} drizzleState={drizzleState} />

        <table className="table" align="center">
            <tr>
                <th scope="col">Balance</th>
                <th scope="col">USDT</th>
                <th scope="col">USDC</th>
                <th scope="col">DAI</th>
            </tr>
            <tr>
                <td>Pay Fixed Derivatives</td>
                <td>
                    <ContractData
                        drizzle={drizzle}
                        drizzleState={drizzleState}
                        contract="MiltonStorageUsdt"
                        method="getExtendedBalance"
                        render={(value) => (
                            <div>
                                {value.totalCollateralPayFixed / 1000000000000000000}
                                <br />
                                <small>{value.totalCollateralPayFixed}</small>
                            </div>
                        )}
                    />
                </td>
                <td>
                    <ContractData
                        drizzle={drizzle}
                        drizzleState={drizzleState}
                        contract="MiltonStorageUsdc"
                        method="getExtendedBalance"
                        render={(value) => (
                            <div>
                                {value.totalCollateralPayFixed / 1000000000000000000}
                                <br />
                                <small>{value.totalCollateralPayFixed}</small>
                            </div>
                        )}
                    />
                </td>
                <td>
                    <ContractData
                        drizzle={drizzle}
                        drizzleState={drizzleState}
                        contract="MiltonStorageDai"
                        method="getExtendedBalance"
                        render={(value) => (
                            <div>
                                {value.totalCollateralPayFixed / 1000000000000000000}
                                <br />
                                <small>{value.totalCollateralPayFixed}</small>
                            </div>
                        )}
                    />
                </td>
            </tr>
            <tr>
                <td>Rec Fixed Derivatives</td>
                <td>
                    <ContractData
                        drizzle={drizzle}
                        drizzleState={drizzleState}
                        contract="MiltonStorageUsdt"
                        method="getExtendedBalance"
                        render={(value) => (
                            <div>
                                {value.totalCollateralReceiveFixed / 1000000000000000000}
                                <br />
                                <small>{value.totalCollateralReceiveFixed}</small>
                            </div>
                        )}
                    />
                </td>
                <td>
                    <ContractData
                        drizzle={drizzle}
                        drizzleState={drizzleState}
                        contract="MiltonStorageUsdc"
                        method="getExtendedBalance"
                        render={(value) => (
                            <div>
                                {value.totalCollateralReceiveFixed / 1000000000000000000}
                                <br />
                                <small>{value.totalCollateralReceiveFixed}</small>
                            </div>
                        )}
                    />
                </td>
                <td>
                    <ContractData
                        drizzle={drizzle}
                        drizzleState={drizzleState}
                        contract="MiltonStorageDai"
                        method="getExtendedBalance"
                        render={(value) => (
                            <div>
                                {value.totalCollateralReceiveFixed / 1000000000000000000}
                                <br />
                                <small>{value.totalCollateralReceiveFixed}</small>
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
                        contract="MiltonStorageUsdt"
                        method="getExtendedBalance"
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
                        contract="MiltonStorageUsdc"
                        method="getExtendedBalance"
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
                        contract="MiltonStorageDai"
                        method="getExtendedBalance"
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
                <td>Ipor Publication Fee</td>
                <td>
                    <ContractData
                        drizzle={drizzle}
                        drizzleState={drizzleState}
                        contract="MiltonStorageUsdt"
                        method="getExtendedBalance"
                        render={(value) => (
                            <div>
                                {value.iporPublicationFee / 1000000000000000000}
                                <br />
                                <small>{value.iporPublicationFee}</small>
                            </div>
                        )}
                    />
                </td>
                <td>
                    <ContractData
                        drizzle={drizzle}
                        drizzleState={drizzleState}
                        contract="MiltonStorageUsdc"
                        method="getExtendedBalance"
                        render={(value) => (
                            <div>
                                {value.iporPublicationFee / 1000000000000000000}
                                <br />
                                <small>{value.iporPublicationFee}</small>
                            </div>
                        )}
                    />
                </td>
                <td>
                    <ContractData
                        drizzle={drizzle}
                        drizzleState={drizzleState}
                        contract="MiltonStorageDai"
                        method="getExtendedBalance"
                        render={(value) => (
                            <div>
                                {value.iporPublicationFee / 1000000000000000000}
                                <br />
                                <small>{value.iporPublicationFee}</small>
                            </div>
                        )}
                    />
                </td>
            </tr>
            <tr>
                <td>TREASURY (including part of Opening Fee, including Income Fee)</td>
                <td>
                    <ContractData
                        drizzle={drizzle}
                        drizzleState={drizzleState}
                        contract="MiltonStorageUsdt"
                        method="getExtendedBalance"
                        render={(value) => (
                            <div>
                                {value.treasury / 1000000000000000000}
                                <br />
                                <small>{value.treasury}</small>
                            </div>
                        )}
                    />
                </td>
                <td>
                    <ContractData
                        drizzle={drizzle}
                        drizzleState={drizzleState}
                        contract="MiltonStorageUsdc"
                        method="getExtendedBalance"
                        render={(value) => (
                            <div>
                                {value.treasury / 1000000000000000000}
                                <br />
                                <small>{value.treasury}</small>
                            </div>
                        )}
                    />
                </td>
                <td>
                    <ContractData
                        drizzle={drizzle}
                        drizzleState={drizzleState}
                        contract="MiltonStorageDai"
                        method="getExtendedBalance"
                        render={(value) => (
                            <div>
                                {value.treasury / 1000000000000000000}
                                <br />
                                <small>{value.treasury}</small>
                            </div>
                        )}
                    />
                </td>
            </tr>
            <tr>
                <td>VAULT (Stanley)</td>
                <td>
                    <ContractData
                        drizzle={drizzle}
                        drizzleState={drizzleState}
                        contract="MiltonStorageUsdt"
                        method="getExtendedBalance"
                        render={(value) => (
                            <div>
                                {value.vault / 1000000000000000000}
                                <br />
                                <small>{value.vault}</small>
                            </div>
                        )}
                    />
                </td>
                <td>
                    <ContractData
                        drizzle={drizzle}
                        drizzleState={drizzleState}
                        contract="MiltonStorageUsdc"
                        method="getExtendedBalance"
                        render={(value) => (
                            <div>
                                {value.vault / 1000000000000000000}
                                <br />
                                <small>{value.vault}</small>
                            </div>
                        )}
                    />
                </td>
                <td>
                    <ContractData
                        drizzle={drizzle}
                        drizzleState={drizzleState}
                        contract="MiltonStorageDai"
                        method="getExtendedBalance"
                        render={(value) => (
                            <div>
                                {value.vault / 1000000000000000000}
                                <br />
                                <small>{value.vault}</small>
                            </div>
                        )}
                    />
                </td>
            </tr>
        </table>
    </div>
);

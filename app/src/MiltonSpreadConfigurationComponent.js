import React from "react";
import { newContextComponents } from "@drizzle/react-components";

const { ContractData, ContractForm } = newContextComponents;

export default ({ drizzle, drizzleState }) => (
    <div>
        <hr />
        <div className="row">
            <table className="table" align="center">
                <tr>
                    <td></td>
                    <td>
                        <strong>USDT</strong>
                    </td>
                    <td>
                        <strong>USDC</strong>
                    </td>
                    <td>
                        <strong>DAI</strong>
                    </td>
                    <td>
                        <strong>WETH</strong>
                    </td>
                </tr>
                <tr>
                    <td>
                        <strong>Milton Spread Model Address</strong>
                    </td>
                    <td><small>{drizzle.contracts.MiltonSpreadModelUsdt.address}</small></td>
                    <td><small>{drizzle.contracts.MiltonSpreadModelUsdc.address}</small></td>
                    <td><small>{drizzle.contracts.MiltonSpreadModelDai.address}</small></td>
                    <td><small>{drizzle.contracts.MiltonSpreadModelWeth.address}</small></td>
                </tr>

                <tr>
                    <td>
                        <strong>Pay Fixed Region One Base</strong>
                    </td>
                    <td>
                        <ContractData
                            drizzle={drizzle}
                            drizzleState={drizzleState}
                            contract="MiltonSpreadModelUsdt"
                            method="getPayFixedRegionOneBase"
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
                            contract="MiltonSpreadModelUsdc"
                            method="getPayFixedRegionOneBase"
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
                            contract="MiltonSpreadModelDai"
                            method="getPayFixedRegionOneBase"
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
                            contract="MiltonSpreadModelWeth"
                            method="getPayFixedRegionOneBase"
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
                        <strong>Pay Fixed Region One Volatility</strong>
                    </td>
                    <td>
                        <ContractData
                            drizzle={drizzle}
                            drizzleState={drizzleState}
                            contract="MiltonSpreadModelUsdt"
                            method="getPayFixedRegionOneSlopeForVolatility"
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
                            contract="MiltonSpreadModelUsdc"
                            method="getPayFixedRegionOneSlopeForVolatility"
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
                            contract="MiltonSpreadModelDai"
                            method="getPayFixedRegionOneSlopeForVolatility"
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
                            contract="MiltonSpreadModelWeth"
                            method="getPayFixedRegionOneSlopeForVolatility"
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
                        <strong>Pay Fixed Region One Mean Reversion</strong>
                    </td>
                    <td>
                        <ContractData
                            drizzle={drizzle}
                            drizzleState={drizzleState}
                            contract="MiltonSpreadModelUsdt"
                            method="getPayFixedRegionOneSlopeForMeanReversion"
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
                            contract="MiltonSpreadModelUsdc"
                            method="getPayFixedRegionOneSlopeForMeanReversion"
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
                            contract="MiltonSpreadModelDai"
                            method="getPayFixedRegionOneSlopeForMeanReversion"
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
                            contract="MiltonSpreadModelWeth"
                            method="getPayFixedRegionOneSlopeForMeanReversion"
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
                        <strong>Pay Fixed Region Two Base</strong>
                    </td>
                    <td>
                        <ContractData
                            drizzle={drizzle}
                            drizzleState={drizzleState}
                            contract="MiltonSpreadModelUsdt"
                            method="getPayFixedRegionTwoBase"
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
                            contract="MiltonSpreadModelUsdc"
                            method="getPayFixedRegionTwoBase"
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
                            contract="MiltonSpreadModelDai"
                            method="getPayFixedRegionTwoBase"
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
                            contract="MiltonSpreadModelWeth"
                            method="getPayFixedRegionTwoBase"
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
                        <strong>Pay Fixed Region Two Volatility</strong>
                    </td>
                    <td>
                        <ContractData
                            drizzle={drizzle}
                            drizzleState={drizzleState}
                            contract="MiltonSpreadModelUsdt"
                            method="getPayFixedRegionTwoSlopeForVolatility"
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
                            contract="MiltonSpreadModelUsdc"
                            method="getPayFixedRegionTwoSlopeForVolatility"
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
                            contract="MiltonSpreadModelDai"
                            method="getPayFixedRegionTwoSlopeForVolatility"
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
                            contract="MiltonSpreadModelWeth"
                            method="getPayFixedRegionTwoSlopeForVolatility"
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
                        <strong>Pay Fixed Region Two Mean Reversion</strong>
                    </td>
                    <td>
                        <ContractData
                            drizzle={drizzle}
                            drizzleState={drizzleState}
                            contract="MiltonSpreadModelUsdt"
                            method="getPayFixedRegionTwoSlopeForMeanReversion"
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
                            contract="MiltonSpreadModelUsdc"
                            method="getPayFixedRegionTwoSlopeForMeanReversion"
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
                            contract="MiltonSpreadModelDai"
                            method="getPayFixedRegionTwoSlopeForMeanReversion"
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
                            contract="MiltonSpreadModelWeth"
                            method="getPayFixedRegionTwoSlopeForMeanReversion"
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
                        <strong>Receive Fixed Region One Base</strong>
                    </td>
                    <td>
                        <ContractData
                            drizzle={drizzle}
                            drizzleState={drizzleState}
                            contract="MiltonSpreadModelUsdt"
                            method="getReceiveFixedRegionOneBase"
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
                            contract="MiltonSpreadModelUsdc"
                            method="getReceiveFixedRegionOneBase"
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
                            contract="MiltonSpreadModelDai"
                            method="getReceiveFixedRegionOneBase"
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
                            contract="MiltonSpreadModelWeth"
                            method="getReceiveFixedRegionOneBase"
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
                        <strong>Receive Fixed Region One Volatility</strong>
                    </td>
                    <td>
                        <ContractData
                            drizzle={drizzle}
                            drizzleState={drizzleState}
                            contract="MiltonSpreadModelUsdt"
                            method="getReceiveFixedRegionOneSlopeForVolatility"
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
                            contract="MiltonSpreadModelUsdc"
                            method="getReceiveFixedRegionOneSlopeForVolatility"
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
                            contract="MiltonSpreadModelDai"
                            method="getReceiveFixedRegionOneSlopeForVolatility"
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
                            contract="MiltonSpreadModelWeth"
                            method="getReceiveFixedRegionOneSlopeForVolatility"
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
                        <strong>Receive Fixed Region One Mean Reversion</strong>
                    </td>
                    <td>
                        <ContractData
                            drizzle={drizzle}
                            drizzleState={drizzleState}
                            contract="MiltonSpreadModelUsdt"
                            method="getReceiveFixedRegionOneSlopeForMeanReversion"
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
                            contract="MiltonSpreadModelUsdc"
                            method="getReceiveFixedRegionOneSlopeForMeanReversion"
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
                            contract="MiltonSpreadModelDai"
                            method="getReceiveFixedRegionOneSlopeForMeanReversion"
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
                            contract="MiltonSpreadModelWeth"
                            method="getReceiveFixedRegionOneSlopeForMeanReversion"
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
                        <strong>Receive Fixed Region Two Base</strong>
                    </td>
                    <td>
                        <ContractData
                            drizzle={drizzle}
                            drizzleState={drizzleState}
                            contract="MiltonSpreadModelUsdt"
                            method="getReceiveFixedRegionTwoBase"
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
                            contract="MiltonSpreadModelUsdc"
                            method="getReceiveFixedRegionTwoBase"
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
                            contract="MiltonSpreadModelDai"
                            method="getReceiveFixedRegionTwoBase"
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
                            contract="MiltonSpreadModelWeth"
                            method="getReceiveFixedRegionTwoBase"
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
                        <strong>Receive Fixed Region Two Volatility</strong>
                    </td>
                    <td>
                        <ContractData
                            drizzle={drizzle}
                            drizzleState={drizzleState}
                            contract="MiltonSpreadModelUsdt"
                            method="getReceiveFixedRegionTwoSlopeForVolatility"
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
                            contract="MiltonSpreadModelUsdc"
                            method="getReceiveFixedRegionTwoSlopeForVolatility"
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
                            contract="MiltonSpreadModelDai"
                            method="getReceiveFixedRegionTwoSlopeForVolatility"
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
                            contract="MiltonSpreadModelWeth"
                            method="getReceiveFixedRegionTwoSlopeForVolatility"
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
                        <strong>Receive Fixed Region Two Mean Reversion</strong>
                    </td>
                    <td>
                        <ContractData
                            drizzle={drizzle}
                            drizzleState={drizzleState}
                            contract="MiltonSpreadModelUsdt"
                            method="getReceiveFixedRegionTwoSlopeForMeanReversion"
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
                            contract="MiltonSpreadModelUsdc"
                            method="getReceiveFixedRegionTwoSlopeForMeanReversion"
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
                            contract="MiltonSpreadModelDai"
                            method="getReceiveFixedRegionTwoSlopeForMeanReversion"
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
                            contract="MiltonSpreadModelWeth"
                            method="getReceiveFixedRegionTwoSlopeForMeanReversion"
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
        </div>
    </div>
);

import React from "react";
import { newContextComponents } from "@drizzle/react-components";

const { ContractData, ContractForm } = newContextComponents;

export default ({ drizzle, drizzleState }) => (
    <div>
        <div className="row">
            <table className="table" align="center">
                <tr>
                    <td>
                        <br />
                        <strong>Milton Spread Configuration Address</strong>
                        <br />
                        <small>Milton Spread Model address</small>
                        <br />
                    </td>
                    <td>
                        <br />
                        {drizzle.contracts.MiltonSpreadModel.address}
                        <br />
                        <br />
                    </td>
                </tr>
                <tr>
                    <td>
                        <strong>Spread Max Value</strong>
                    </td>
                    <td>
                        <ContractData
                            drizzle={drizzle}
                            drizzleState={drizzleState}
                            contract="MiltonSpreadModel"
                            method="getSpreadMaxValue"
                            render={(value) => (
                                <div>
                                    {value / 1000000000000000000}
                                    <br />
                                    <small>{value}</small>
                                </div>
                            )}
                        />

                        <ContractForm
                            drizzle={drizzle}
                            contract="MiltonSpreadModel"
                            method="setSpreadMaxValue"
                        />
                    </td>
                </tr>
                <tr>
                    <td>
                        <strong>Demand Component Kf Value</strong>
                    </td>
                    <td>
                        <ContractData
                            drizzle={drizzle}
                            drizzleState={drizzleState}
                            contract="MiltonSpreadModel"
                            method="getDemandComponentKfValue"
                            render={(value) => (
                                <div>
                                    {value / 1000000000000000000}
                                    <br />
                                    <small>{value}</small>
                                </div>
                            )}
                        />
                        <ContractForm
                            drizzle={drizzle}
                            contract="MiltonSpreadModel"
                            method="setDemandComponentKfValue"
                        />
                    </td>
                </tr>
                <tr>
                    <td>
                        <strong>Demand Component Lambda Value</strong>
                    </td>
                    <td>
                        <ContractData
                            drizzle={drizzle}
                            drizzleState={drizzleState}
                            contract="MiltonSpreadModel"
                            method="getDemandComponentLambdaValue"
                            render={(value) => (
                                <div>
                                    {value / 1000000000000000000}
                                    <br />
                                    <small>{value}</small>
                                </div>
                            )}
                        />

                        <ContractForm
                            drizzle={drizzle}
                            contract="MiltonSpreadModel"
                            method="setDemandComponentLambdaValue"
                        />
                    </td>
                </tr>

                <tr>
                    <td>
                        <strong>Demand Component KOmega Value</strong>
                    </td>
                    <td>
                        <ContractData
                            drizzle={drizzle}
                            drizzleState={drizzleState}
                            contract="MiltonSpreadModel"
                            method="getDemandComponentKOmegaValue"
                            render={(value) => (
                                <div>
                                    {value / 1000000000000000000}
                                    <br />
                                    <small>{value}</small>
                                </div>
                            )}
                        />

                        <ContractForm
                            drizzle={drizzle}
                            contract="MiltonSpreadModel"
                            method="setDemandComponentKOmegaValue"
                        />
                    </td>
                </tr>

                <tr>
                    <td>
                        <strong>
                            Demand Component Max Liquidity Redemption Value
                        </strong>
                    </td>
                    <td>
                        <ContractData
                            drizzle={drizzle}
                            drizzleState={drizzleState}
                            contract="MiltonSpreadModel"
                            method="getDemandComponentMaxLiquidityRedemptionValue"
                            render={(value) => (
                                <div>
                                    {value / 1000000000000000000}
                                    <br />
                                    <small>{value}</small>
                                </div>
                            )}
                        />

                        <ContractForm
                            drizzle={drizzle}
                            contract="MiltonSpreadModel"
                            method="setDemandComponentMaxLiquidityRedemptionValue"
                        />
                    </td>
                </tr>

                <tr>
                    <td>
                        <strong>At Par Component KVol Value</strong>
                    </td>
                    <td>
                        <ContractData
                            drizzle={drizzle}
                            drizzleState={drizzleState}
                            contract="MiltonSpreadModel"
                            method="getAtParComponentKVolValue"
                            render={(value) => (
                                <div>
                                    {value / 1000000000000000000}
                                    <br />
                                    <small>{value}</small>
                                </div>
                            )}
                        />

                        <ContractForm
                            drizzle={drizzle}
                            contract="MiltonSpreadModel"
                            method="setAtParComponentKVolValue"
                        />
                    </td>
                </tr>

                <tr>
                    <td>
                        <strong>At Par Component KHist Value</strong>
                    </td>
                    <td>
                        <ContractData
                            drizzle={drizzle}
                            drizzleState={drizzleState}
                            contract="MiltonSpreadModel"
                            method="getAtParComponentKHistValue"
                            render={(value) => (
                                <div>
                                    {value / 1000000000000000000}
                                    <br />
                                    <small>{value}</small>
                                </div>
                            )}
                        />

                        <ContractForm
                            drizzle={drizzle}
                            contract="MiltonSpreadModel"
                            method="setAtParComponentKHistValue"
                        />
                    </td>
                </tr>

                <tr>
                    <td>
                        <strong>Grant role to user</strong>
                        <br />
                        <small>
                            In field role use byte32 representation. Available
                            roles listed below.
                        </small>
                    </td>
                    <td>
                        <ContractForm
                            drizzle={drizzle}
                            contract="MiltonSpreadModel"
                            method="grantRole"
                        />
                    </td>
                </tr>
            </table>
            <table>
                <thead>
                    <tr>
                        <th>Name</th>
                        <th>Value</th>
                    </tr>
                </thead>
                <tbody>
                    <tr>
                        <td>ADMIN_ROLE</td>
                        <td>
                            0xa49807205ce4d355092ef5a8a18f56e8913cf4a201fbe287825b095693c21775
                        </td>
                    </tr>
                    <tr>
                        <td>SPREAD_MAX_VALUE_ADMIN_ROLE</td>
                        <td>
                            0xb581f555a22f011e62b435ab4668283f41a911882c41e2508f9bc9c258b30ecf
                        </td>
                    </tr>
                    <tr>
                        <td>SPREAD_MAX_VALUE_ROLE</td>
                        <td>
                            0x243c66f877d2b9250ad8706721efad9f4b3d65a4b61cc21d637d7bfe5d73f574
                        </td>
                    </tr>
                    <tr>
                        <td>SPREAD_DEMAND_COMPONENT_KF_VALUE_ADMIN_ROLE</td>
                        <td>
                            0x535fa1a8b46c5ac24ca523a0fecbea2eef851695b9833f8ec25b9296a155a55e
                        </td>
                    </tr>
                    <tr>
                        <td>SPREAD_DEMAND_COMPONENT_KF_VALUE_ROLE</td>
                        <td>
                            0xa3398f01fb1ec4a3bb19698f87225bd824cc0c1d4f362a6b56fddc0006bab61f
                        </td>
                    </tr>
                    <tr>
                        <td>SPREAD_DEMAND_COMPONENT_LAMBDA_VALUE_ADMIN_ROLE</td>
                        <td>
                            0x266e1cccbc57d946f8878e0ccafeaa12db3490531747e2ee4f3436f9a2b2fa6e
                        </td>
                    </tr>
                    <tr>
                        <td>SPREAD_DEMAND_COMPONENT_LAMBDA_VALUE_ROLE</td>
                        <td>
                            0xbb8358898740bf199fac3e7b605f7a84a5fc0ea3d3b35788eb6bdbea68564eb3
                        </td>
                    </tr>
                    <tr>
                        <td>SPREAD_DEMAND_COMPONENT_KOMEGA_VALUE_ADMIN_ROLE</td>
                        <td>
                            0x8a92933037b88f51a66db44f2de47a243ede378bceacc6b5f0cf5fea0e402c47
                        </td>
                    </tr>
                    <tr>
                        <td>SPREAD_DEMAND_COMPONENT_KOMEGA_VALUE_ROLE</td>
                        <td>
                            0x637ba89bee1cd75c66353215d464266e9edf15bc34e82be6a9605aac890faa3d
                        </td>
                    </tr>
                    <tr>
                        <td>
                            SPREAD_DEMAND_COMPONENT_MAX_LIQUIDITY_REDEMPTION_VALUE_ADMIN_ROLE
                        </td>
                        <td>
                            0xc06556706d5d60c0be16d3efe62591e2c93ad537438fd1d9e36cba7a7dfe614f
                        </td>
                    </tr>
                    <tr>
                        <td>
                            SPREAD_DEMAND_COMPONENT_MAX_LIQUIDITY_REDEMPTION_VALUE_ROLE
                        </td>
                        <td>
                            0x43a301f724eae1c60a7593d4009d0bd802b80e0d4a26c035422902546f1f9ba2
                        </td>
                    </tr>
                    <tr>
                        <td>SPREAD_AT_PAR_COMPONENT_KVOL_VALUE_ADMIN_ROLE</td>
                        <td>
                            0x7b2e8d4d108e2a713ab6896f8a6c0eb773e393fdd0615487081410722d9217da
                        </td>
                    </tr>
                    <tr>
                        <td>SPREAD_AT_PAR_COMPONENT_KVOL_VALUE_ROLE</td>
                        <td>
                            0xe02d1051d198d59b76e4b27810e664ce05ce9051dd63960cd3091a729a082b2e
                        </td>
                    </tr>
                    <tr>
                        <td>SPREAD_AT_PAR_COMPONENT_KHIST_VALUE_ADMIN_ROLE</td>
                        <td>
                            0x4c36addcf0f2c8cd7f8f3a0ef18f7269079c8b77cc782aad8793b387b282e235
                        </td>
                    </tr>
                    <tr>
                        <td>SPREAD_AT_PAR_COMPONENT_KHIST_VALUE_ROLE</td>
                        <td>
                            0xdca8835bfc38d693c83ccb0c5ce40acbfb459373479e6f00daf593e9050c9cf3
                        </td>
                    </tr>
                    <tr>
                        <td>ROLES_INFO_ADMIN_ROLE</td>
                        <td>
                            0xfb1902cbac4bf447ada58dff398caab7aa9089eba1be77a2833d9e08dbe8664c
                        </td>
                    </tr>
                    <tr>
                        <td>ROLES_INFO_ROLE</td>
                        <td>
                            0xc878cde3567a457053651a2406e31db6dbb9207b6d5eedb081ef807beaaf5444
                        </td>
                    </tr>
                </tbody>
            </table>
        </div>
    </div>
);

import React from "react";
import { newContextComponents } from "@drizzle/react-components";

const { ContractData, ContractForm } = newContextComponents;

export default ({ drizzle, drizzleState }) => (
    <div>
        <hr />
        <h5>Cockpit Data Provider</h5>
        <div className="row">
            <div className="col-md-6">
                <label>Transfer Ownership</label>

                <ContractForm
                    drizzle={drizzle}
                    contract="CockpitDataProvider"
                    method="transferOwnership"
                />
            </div>
            <div className="col-md-6">
                <label>Confirm Transfer Ownership</label>

                <ContractForm
                    drizzle={drizzle}
                    contract="CockpitDataProvider"
                    method="confirmTransferOwnership"
                />
            </div>
        </div>
        <hr />
        <table className="table" align="center">
            <tr>
                <td>
                    <strong>Contract</strong>
                </td>
                <td>
                    <strong>Address</strong>
                </td>
                <td>
                    <strong>Owner</strong>
                </td>
            </tr>
            <tr>
                <td>
                    <strong>IporOracle</strong>
                </td>
                <td>
                    {process.env.REACT_APP_ITF_ENABLED === "true"
                        ? "NONE"
                        : drizzle.contracts.IporOracle.address}
                </td>
                <td>
                    <ContractData
                        drizzle={drizzle}
                        drizzleState={drizzleState}
                        contract="IporOracle"
                        method="owner"
                    />
                </td>
            </tr>
            <tr>
                <td>
                    <strong>Milton Spread Model</strong>
                </td>
                <td>{drizzle.contracts.MiltonSpreadModel.address}</td>
                <td>
                    <ContractData
                        drizzle={drizzle}
                        drizzleState={drizzleState}
                        contract="MiltonSpreadModel"
                        method="owner"
                    />
                </td>
            </tr>

            <tr>
                <td>
                    <strong>Cockpit Data Provider</strong>
                </td>
                <td>{drizzle.contracts.CockpitDataProvider.address}</td>
                <td>
                    <ContractData
                        drizzle={drizzle}
                        drizzleState={drizzleState}
                        contract="CockpitDataProvider"
                        method="owner"
                    />
                </td>
            </tr>

            <tr>
                <td>
                    <strong>Ipor Oracle Facade Data Provider</strong>
                </td>
                <td>{drizzle.contracts.IporOracleFacadeDataProvider.address}</td>
                <td>
                    <ContractData
                        drizzle={drizzle}
                        drizzleState={drizzleState}
                        contract="IporOracleFacadeDataProvider"
                        method="owner"
                    />
                </td>
            </tr>

            <tr>
                <td>
                    <strong>Milton Facade Data Provider</strong>
                </td>
                <td>{drizzle.contracts.MiltonFacadeDataProvider.address}</td>
                <td>
                    <ContractData
                        drizzle={drizzle}
                        drizzleState={drizzleState}
                        contract="MiltonFacadeDataProvider"
                        method="owner"
                    />
                </td>
            </tr>
            <tr>
                <td>
                    <strong>Testnet Faucet</strong>
                </td>
                <td>{drizzle.contracts.TestnetFaucet.address}</td>
                <td>
                    <ContractData
                        drizzle={drizzle}
                        drizzleState={drizzleState}
                        contract="TestnetFaucet"
                        method="owner"
                    />
                </td>
            </tr>
            <tr>
                <td>
                    <strong>ItfIporOracle</strong>
                </td>
                <td>
                    {process.env.REACT_APP_ITF_ENABLED === "true"
                        ? drizzle.contracts.ItfIporOracle.address
                        : "NONE"}
                </td>
                <td>
                    {process.env.REACT_APP_ITF_ENABLED === "true" ? (
                        <ContractData
                            drizzle={drizzle}
                            drizzleState={drizzleState}
                            contract="ItfIporOracle"
                            method="owner"
                        />
                    ) : (
                        "NONE"
                    )}
                </td>
            </tr>
        </table>
        <table className="table" align="center">
            <tr>
                <th scope="col"></th>
                <th scope="col">USDT</th>
                <th scope="col">USDC</th>
                <th scope="col">DAI</th>
            </tr>
            <tr>
                <td>
                    <strong>Stablecoin / Asset</strong>
                </td>
                <td>{drizzle.contracts.MockTestnetTokenUsdt.address}</td>
                <td>{drizzle.contracts.MockTestnetTokenUsdc.address}</td>
                <td>{drizzle.contracts.MockTestnetTokenDai.address}</td>
            </tr>
            <tr>
                <td>
                    <strong>Milton</strong>
                </td>
                <td>
                    {process.env.REACT_APP_ITF_ENABLED === "true"
                        ? "NONE"
                        : drizzle.contracts.MiltonUsdt.address}
                </td>
                <td>
                    {process.env.REACT_APP_ITF_ENABLED === "true"
                        ? "NONE"
                        : drizzle.contracts.MiltonUsdc.address}
                </td>
                <td>
                    {process.env.REACT_APP_ITF_ENABLED === "true"
                        ? "NONE"
                        : drizzle.contracts.MiltonDai.address}
                </td>
            </tr>
            <tr>
                <td>
                    <strong>Milton Storage</strong>
                </td>
                <td>{drizzle.contracts.MiltonStorageUsdt.address}</td>
                <td>{drizzle.contracts.MiltonStorageUsdc.address}</td>
                <td>{drizzle.contracts.MiltonStorageDai.address}</td>
            </tr>
            <tr>
                <td>
                    <strong>Joseph</strong>
                </td>
                <td>
                    {process.env.REACT_APP_ITF_ENABLED === "true"
                        ? "NONE"
                        : drizzle.contracts.JosephUsdt.address}
                </td>
                <td>
                    {process.env.REACT_APP_ITF_ENABLED === "true"
                        ? "NONE"
                        : drizzle.contracts.JosephUsdc.address}
                </td>
                <td>
                    {process.env.REACT_APP_ITF_ENABLED === "true"
                        ? "NONE"
                        : drizzle.contracts.JosephDai.address}
                </td>
            </tr>
            <tr>
                <td>
                    <strong>Stanley</strong>
                </td>
                <td>
                    {process.env.REACT_APP_ITF_ENABLED === "true"
                        ? "NONE"
                        : drizzle.contracts.StanleyUsdt.address}
                </td>
                <td>
                    {process.env.REACT_APP_ITF_ENABLED === "true"
                        ? "NONE"
                        : drizzle.contracts.StanleyUsdc.address}
                </td>
                <td>
                    {process.env.REACT_APP_ITF_ENABLED === "true"
                        ? "NONE"
                        : drizzle.contracts.StanleyDai.address}
                </td>
            </tr>
            <tr>
                <td>
                    <strong>IpToken</strong>
                </td>
                <td>{drizzle.contracts.IpTokenUsdt.address}</td>
                <td>{drizzle.contracts.IpTokenUsdc.address}</td>
                <td>{drizzle.contracts.IpTokenDai.address}</td>
            </tr>
            <tr>
                <td>
                    <strong>IvToken</strong>
                </td>
                <td>{drizzle.contracts.IvTokenUsdt.address}</td>
                <td>{drizzle.contracts.IvTokenUsdc.address}</td>
                <td>{drizzle.contracts.IvTokenDai.address}</td>
            </tr>
            <tr>
                <td>
                    <strong>Aave Strategy</strong>
                </td>
                <td>{drizzle.contracts.MockTestnetStrategyAaveUsdt.address}</td>
                <td>{drizzle.contracts.MockTestnetStrategyAaveUsdc.address}</td>
                <td>{drizzle.contracts.MockTestnetStrategyAaveDai.address}</td>
            </tr>
            <tr>
                <td>
                    <strong>Compound Strategy</strong>
                </td>
                <td>{drizzle.contracts.MockTestnetStrategyCompoundUsdt.address}</td>
                <td>{drizzle.contracts.MockTestnetStrategyCompoundUsdc.address}</td>
                <td>{drizzle.contracts.MockTestnetStrategyCompoundDai.address}</td>
            </tr>

            <tr>
                <td>
                    <strong>Stablecoin - Owner</strong>
                </td>
                <td>
                    <ContractData
                        drizzle={drizzle}
                        drizzleState={drizzleState}
                        contract="MockTestnetTokenUsdt"
                        method="owner"
                    />
                </td>
                <td>
                    <ContractData
                        drizzle={drizzle}
                        drizzleState={drizzleState}
                        contract="MockTestnetTokenUsdc"
                        method="owner"
                    />
                </td>
                <td>
                    <ContractData
                        drizzle={drizzle}
                        drizzleState={drizzleState}
                        contract="MockTestnetTokenDai"
                        method="owner"
                    />
                </td>
            </tr>

            <tr>
                <td>
                    <strong>Milton - Owner</strong>
                </td>
                <td>
                    {process.env.REACT_APP_ITF_ENABLED === "true" ? (
                        "NONE"
                    ) : (
                        <ContractData
                            drizzle={drizzle}
                            drizzleState={drizzleState}
                            contract="MiltonUsdt"
                            method="owner"
                        />
                    )}
                </td>
                <td>
                    {process.env.REACT_APP_ITF_ENABLED === "true" ? (
                        "NONE"
                    ) : (
                        <ContractData
                            drizzle={drizzle}
                            drizzleState={drizzleState}
                            contract="MiltonUsdc"
                            method="owner"
                        />
                    )}
                </td>
                <td>
                    {process.env.REACT_APP_ITF_ENABLED === "true" ? (
                        "NONE"
                    ) : (
                        <ContractData
                            drizzle={drizzle}
                            drizzleState={drizzleState}
                            contract="MiltonDai"
                            method="owner"
                        />
                    )}
                </td>
            </tr>

            <tr>
                <td>
                    <strong>Milton Storage - Owner</strong>
                </td>
                <td>
                    <ContractData
                        drizzle={drizzle}
                        drizzleState={drizzleState}
                        contract="MiltonStorageUsdt"
                        method="owner"
                    />
                </td>
                <td>
                    <ContractData
                        drizzle={drizzle}
                        drizzleState={drizzleState}
                        contract="MiltonStorageUsdc"
                        method="owner"
                    />{" "}
                </td>
                <td>
                    <ContractData
                        drizzle={drizzle}
                        drizzleState={drizzleState}
                        contract="MiltonStorageDai"
                        method="owner"
                    />
                </td>
            </tr>
            <tr>
                <td>
                    <strong>Joseph - Owner</strong>
                </td>
                <td>
                    {process.env.REACT_APP_ITF_ENABLED === "true" ? (
                        "NONE"
                    ) : (
                        <ContractData
                            drizzle={drizzle}
                            drizzleState={drizzleState}
                            contract="JosephUsdt"
                            method="owner"
                        />
                    )}
                </td>
                <td>
                    {process.env.REACT_APP_ITF_ENABLED === "true" ? (
                        "NONE"
                    ) : (
                        <ContractData
                            drizzle={drizzle}
                            drizzleState={drizzleState}
                            contract="JosephUsdc"
                            method="owner"
                        />
                    )}
                </td>
                <td>
                    {process.env.REACT_APP_ITF_ENABLED === "true" ? (
                        "NONE"
                    ) : (
                        <ContractData
                            drizzle={drizzle}
                            drizzleState={drizzleState}
                            contract="JosephDai"
                            method="owner"
                        />
                    )}
                </td>
            </tr>

            <tr>
                <td>
                    <strong>Stanley - Owner</strong>
                </td>
                <td>
                    {process.env.REACT_APP_ITF_ENABLED === "true" ? (
                        "NONE"
                    ) : (
                        <ContractData
                            drizzle={drizzle}
                            drizzleState={drizzleState}
                            contract="StanleyUsdt"
                            method="owner"
                        />
                    )}
                </td>
                <td>
                    {process.env.REACT_APP_ITF_ENABLED === "true" ? (
                        "NONE"
                    ) : (
                        <ContractData
                            drizzle={drizzle}
                            drizzleState={drizzleState}
                            contract="StanleyUsdc"
                            method="owner"
                        />
                    )}
                </td>
                <td>
                    {process.env.REACT_APP_ITF_ENABLED === "true" ? (
                        "NONE"
                    ) : (
                        <ContractData
                            drizzle={drizzle}
                            drizzleState={drizzleState}
                            contract="StanleyDai"
                            method="owner"
                        />
                    )}
                </td>
            </tr>
            <tr>
                <td>
                    <strong>IpToken - Owner</strong>
                </td>
                <td>
                    <ContractData
                        drizzle={drizzle}
                        drizzleState={drizzleState}
                        contract="IpTokenUsdt"
                        method="owner"
                    />
                </td>
                <td>
                    <ContractData
                        drizzle={drizzle}
                        drizzleState={drizzleState}
                        contract="IpTokenUsdc"
                        method="owner"
                    />
                </td>
                <td>
                    <ContractData
                        drizzle={drizzle}
                        drizzleState={drizzleState}
                        contract="IpTokenDai"
                        method="owner"
                    />
                </td>
            </tr>
            <tr>
                <td>
                    <strong>IvToken - Owner</strong>
                </td>
                <td>
                    <ContractData
                        drizzle={drizzle}
                        drizzleState={drizzleState}
                        contract="IvTokenUsdt"
                        method="owner"
                    />
                </td>
                <td>
                    <ContractData
                        drizzle={drizzle}
                        drizzleState={drizzleState}
                        contract="IvTokenUsdc"
                        method="owner"
                    />
                </td>
                <td>
                    <ContractData
                        drizzle={drizzle}
                        drizzleState={drizzleState}
                        contract="IvTokenDai"
                        method="owner"
                    />
                </td>
            </tr>
            <tr>
                <td>
                    <strong>Aave Strategy - Owner</strong>
                </td>
                <td>
                    <ContractData
                        drizzle={drizzle}
                        drizzleState={drizzleState}
                        contract="MockTestnetStrategyAaveUsdt"
                        method="owner"
                    />
                </td>
                <td>
                    <ContractData
                        drizzle={drizzle}
                        drizzleState={drizzleState}
                        contract="MockTestnetStrategyAaveUsdc"
                        method="owner"
                    />
                </td>
                <td>
                    <ContractData
                        drizzle={drizzle}
                        drizzleState={drizzleState}
                        contract="MockTestnetStrategyAaveDai"
                        method="owner"
                    />
                </td>
            </tr>
            <tr>
                <td>
                    <strong>Compound Strategy - Owner</strong>
                </td>
                <td>
                    <ContractData
                        drizzle={drizzle}
                        drizzleState={drizzleState}
                        contract="MockTestnetStrategyCompoundUsdt"
                        method="owner"
                    />
                </td>
                <td>
                    <ContractData
                        drizzle={drizzle}
                        drizzleState={drizzleState}
                        contract="MockTestnetStrategyCompoundUsdc"
                        method="owner"
                    />
                </td>
                <td>
                    <ContractData
                        drizzle={drizzle}
                        drizzleState={drizzleState}
                        contract="MockTestnetStrategyCompoundDai"
                        method="owner"
                    />
                </td>
            </tr>
            <tr>
                <td>
                    <strong>ItfMilton</strong>
                </td>
                <td>
                    {process.env.REACT_APP_ITF_ENABLED === "true"
                        ? drizzle.contracts.ItfMiltonUsdt.address
                        : "NONE"}
                </td>
                <td>
                    {process.env.REACT_APP_ITF_ENABLED === "true"
                        ? drizzle.contracts.ItfMiltonUsdc.address
                        : "NONE"}
                </td>
                <td>
                    {process.env.REACT_APP_ITF_ENABLED === "true"
                        ? drizzle.contracts.ItfMiltonDai.address
                        : "NONE"}
                </td>
            </tr>
            <tr>
                <td>
                    <strong>ItfJoseph</strong>
                </td>
                <td>
                    {process.env.REACT_APP_ITF_ENABLED === "true"
                        ? drizzle.contracts.ItfJosephUsdt.address
                        : "NONE"}
                </td>
                <td>
                    {process.env.REACT_APP_ITF_ENABLED === "true"
                        ? drizzle.contracts.ItfJosephUsdc.address
                        : "NONE"}
                </td>
                <td>
                    {process.env.REACT_APP_ITF_ENABLED === "true"
                        ? drizzle.contracts.ItfJosephDai.address
                        : "NONE"}
                </td>
            </tr>
            <tr>
                <td>
                    <strong>ItfStanley</strong>
                </td>
                <td>
                    {process.env.REACT_APP_ITF_ENABLED === "true"
                        ? drizzle.contracts.ItfStanleyUsdt.address
                        : "NONE"}
                </td>
                <td>
                    {process.env.REACT_APP_ITF_ENABLED === "true"
                        ? drizzle.contracts.ItfStanleyUsdc.address
                        : "NONE"}
                </td>
                <td>
                    {process.env.REACT_APP_ITF_ENABLED === "true"
                        ? drizzle.contracts.ItfStanleyDai.address
                        : "NONE"}
                </td>
            </tr>
            <tr>
                <td>
                    <strong>ItfMilton - Owner</strong>
                </td>
                <td>
                    {process.env.REACT_APP_ITF_ENABLED === "true" ? (
                        <ContractData
                            drizzle={drizzle}
                            drizzleState={drizzleState}
                            contract="ItfMiltonUsdt"
                            method="owner"
                        />
                    ) : (
                        "NONE"
                    )}
                </td>
                <td>
                    {process.env.REACT_APP_ITF_ENABLED === "true" ? (
                        <ContractData
                            drizzle={drizzle}
                            drizzleState={drizzleState}
                            contract="ItfMiltonUsdc"
                            method="owner"
                        />
                    ) : (
                        "NONE"
                    )}
                </td>
                <td>
                    {process.env.REACT_APP_ITF_ENABLED === "true" ? (
                        <ContractData
                            drizzle={drizzle}
                            drizzleState={drizzleState}
                            contract="ItfMiltonDai"
                            method="owner"
                        />
                    ) : (
                        "NONE"
                    )}
                </td>
            </tr>
            <tr>
                <td>
                    <strong>ItfJoseph - Owner</strong>
                </td>
                <td>
                    {process.env.REACT_APP_ITF_ENABLED === "true" ? (
                        <ContractData
                            drizzle={drizzle}
                            drizzleState={drizzleState}
                            contract="ItfJosephUsdt"
                            method="owner"
                        />
                    ) : (
                        "NONE"
                    )}
                </td>
                <td>
                    {process.env.REACT_APP_ITF_ENABLED === "true" ? (
                        <ContractData
                            drizzle={drizzle}
                            drizzleState={drizzleState}
                            contract="ItfJosephUsdc"
                            method="owner"
                        />
                    ) : (
                        "NONE"
                    )}
                </td>
                <td>
                    {process.env.REACT_APP_ITF_ENABLED === "true" ? (
                        <ContractData
                            drizzle={drizzle}
                            drizzleState={drizzleState}
                            contract="ItfJosephDai"
                            method="owner"
                        />
                    ) : (
                        "NONE"
                    )}
                </td>
            </tr>
            <tr>
                <td>
                    <strong>ItfStanley - Owner</strong>
                </td>
                <td>
                    {process.env.REACT_APP_ITF_ENABLED === "true" ? (
                        <ContractData
                            drizzle={drizzle}
                            drizzleState={drizzleState}
                            contract="ItfStanleyUsdt"
                            method="owner"
                        />
                    ) : (
                        "NONE"
                    )}
                </td>
                <td>
                    {process.env.REACT_APP_ITF_ENABLED === "true" ? (
                        <ContractData
                            drizzle={drizzle}
                            drizzleState={drizzleState}
                            contract="ItfStanleyUsdc"
                            method="owner"
                        />
                    ) : (
                        "NONE"
                    )}
                </td>
                <td>
                    {process.env.REACT_APP_ITF_ENABLED === "true" ? (
                        <ContractData
                            drizzle={drizzle}
                            drizzleState={drizzleState}
                            contract="ItfStanleyDai"
                            method="owner"
                        />
                    ) : (
                        "NONE"
                    )}
                </td>
            </tr>
        </table>
    </div>
);

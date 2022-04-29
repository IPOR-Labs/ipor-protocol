import React from "react";
import { newContextComponents } from "@drizzle/react-components";

const { ContractData, ContractForm } = newContextComponents;

export default ({ drizzle, drizzleState }) => (
    <div>
        <hr />
        <table className="table" align="center">
            <tr>
                <th scope="col">Contract</th>
                <th scope="col">Address</th>
                <th scope="col">Current Owner</th>
                <th scope="col">Transfer Ownership</th>
                <th scope="col">Confirm Transfer Ownership</th>
            </tr>
            <tr>
                <td>USDT</td>
                <td>{drizzle.contracts.MockTestnetTokenUsdt.address}</td>
                <td>
                    <ContractData
                        drizzle={drizzle}
                        drizzleState={drizzleState}
                        contract="MockTestnetTokenUsdt"
                        method="owner"
                    />
                </td>
                <td>
                    <ContractForm
                        drizzle={drizzle}
                        contract="MockTestnetTokenUsdt"
                        method="transferOwnership"
                    />
                </td>
                <td>
                    <ContractForm
                        drizzle={drizzle}
                        contract="MockTestnetTokenUsdt"
                        method="confirmTransferOwnership"
                    />
                </td>
            </tr>
            <tr>
                <td>USDC</td>
                <td>{drizzle.contracts.MockTestnetTokenUsdc.address}</td>
                <td>
                    <ContractData
                        drizzle={drizzle}
                        drizzleState={drizzleState}
                        contract="MockTestnetTokenUsdc"
                        method="owner"
                    />
                </td>
                <td>
                    <ContractForm
                        drizzle={drizzle}
                        contract="MockTestnetTokenUsdc"
                        method="transferOwnership"
                    />
                </td>
                <td>
                    <ContractForm
                        drizzle={drizzle}
                        contract="MockTestnetTokenUsdc"
                        method="confirmTransferOwnership"
                    />
                </td>
            </tr>
            <tr>
                <td>DAI</td>
                <td>{drizzle.contracts.MockTestnetTokenDai.address}</td>
                <td>
                    <ContractData
                        drizzle={drizzle}
                        drizzleState={drizzleState}
                        contract="MockTestnetTokenDai"
                        method="owner"
                    />
                </td>
                <td>
                    <ContractForm
                        drizzle={drizzle}
                        contract="MockTestnetTokenDai"
                        method="transferOwnership"
                    />
                </td>
                <td>
                    <ContractForm
                        drizzle={drizzle}
                        contract="MockTestnetTokenDai"
                        method="confirmTransferOwnership"
                    />
                </td>
            </tr>
            <tr>
                <td>ipUSDT</td>
                <td>{drizzle.contracts.IpTokenUsdt.address}</td>
                <td>
                    <ContractData
                        drizzle={drizzle}
                        drizzleState={drizzleState}
                        contract="IpTokenUsdt"
                        method="owner"
                    />
                </td>
                <td>
                    <ContractForm
                        drizzle={drizzle}
                        contract="IpTokenUsdt"
                        method="transferOwnership"
                    />
                </td>
                <td>
                    <ContractForm
                        drizzle={drizzle}
                        contract="IpTokenUsdt"
                        method="confirmTransferOwnership"
                    />
                </td>
            </tr>
            <tr>
                <td>ipUSDC</td>
                <td>{drizzle.contracts.IpTokenUsdc.address}</td>
                <td>
                    <ContractData
                        drizzle={drizzle}
                        drizzleState={drizzleState}
                        contract="IpTokenUsdc"
                        method="owner"
                    />
                </td>
                <td>
                    <ContractForm
                        drizzle={drizzle}
                        contract="IpTokenUsdc"
                        method="transferOwnership"
                    />
                </td>
                <td>
                    <ContractForm
                        drizzle={drizzle}
                        contract="IpTokenUsdc"
                        method="confirmTransferOwnership"
                    />
                </td>
            </tr>
            <tr>
                <td>ipDAI</td>
                <td>{drizzle.contracts.IpTokenDai.address}</td>
                <td>
                    <ContractData
                        drizzle={drizzle}
                        drizzleState={drizzleState}
                        contract="IpTokenDai"
                        method="owner"
                    />
                </td>
                <td>
                    <ContractForm
                        drizzle={drizzle}
                        contract="IpTokenDai"
                        method="transferOwnership"
                    />
                </td>
                <td>
                    <ContractForm
                        drizzle={drizzle}
                        contract="IpTokenDai"
                        method="confirmTransferOwnership"
                    />
                </td>
            </tr>
            <tr>
                <td>ivUSDT</td>
                <td>{drizzle.contracts.IvTokenUsdt.address}</td>
                <td>
                    <ContractData
                        drizzle={drizzle}
                        drizzleState={drizzleState}
                        contract="IvTokenUsdt"
                        method="owner"
                    />
                </td>
                <td>
                    <ContractForm
                        drizzle={drizzle}
                        contract="IvTokenUsdt"
                        method="transferOwnership"
                    />
                </td>
                <td>
                    <ContractForm
                        drizzle={drizzle}
                        contract="IvTokenUsdt"
                        method="confirmTransferOwnership"
                    />
                </td>
            </tr>
            <tr>
                <td>ivUSDC</td>
                <td>{drizzle.contracts.IvTokenUsdc.address}</td>
                <td>
                    <ContractData
                        drizzle={drizzle}
                        drizzleState={drizzleState}
                        contract="IvTokenUsdc"
                        method="owner"
                    />
                </td>
                <td>
                    <ContractForm
                        drizzle={drizzle}
                        contract="IvTokenUsdc"
                        method="transferOwnership"
                    />
                </td>
                <td>
                    <ContractForm
                        drizzle={drizzle}
                        contract="IvTokenUsdc"
                        method="confirmTransferOwnership"
                    />
                </td>
            </tr>
            <tr>
                <td>ivDAI</td>
                <td>{drizzle.contracts.IvTokenDai.address}</td>
                <td>
                    <ContractData
                        drizzle={drizzle}
                        drizzleState={drizzleState}
                        contract="IvTokenDai"
                        method="owner"
                    />
                </td>
                <td>
                    <ContractForm
                        drizzle={drizzle}
                        contract="IvTokenDai"
                        method="transferOwnership"
                    />
                </td>
                <td>
                    <ContractForm
                        drizzle={drizzle}
                        contract="IvTokenDai"
                        method="confirmTransferOwnership"
                    />
                </td>
            </tr>
            <tr>
                <td>Ipor Oracle</td>
                <td>
                    {process.env.REACT_APP_ITF_ENABLED === "true"
                        ? "NONE"
                        : drizzle.contracts.IporOracle.address}
                </td>
                <td>
                    {process.env.REACT_APP_ITF_ENABLED === "true" ? (
                        "NONE"
                    ) : (
                        <ContractData
                            drizzle={drizzle}
                            drizzleState={drizzleState}
                            contract="IporOracle"
                            method="owner"
                        />
                    )}
                </td>
                <td>
                    {process.env.REACT_APP_ITF_ENABLED === "true" ? (
                        "NONE"
                    ) : (
                        <ContractForm
                            drizzle={drizzle}
                            contract="IporOracle"
                            method="transferOwnership"
                        />
                    )}
                </td>
                <td>
                    {process.env.REACT_APP_ITF_ENABLED === "true" ? (
                        "NONE"
                    ) : (
                        <ContractForm
                            drizzle={drizzle}
                            contract="IporOracle"
                            method="confirmTransferOwnership"
                        />
                    )}
                </td>
            </tr>
            <tr>
                <td>Milton Spread Model</td>
                <td>{drizzle.contracts.MiltonSpreadModel.address}</td>
                <td>
                    <ContractData
                        drizzle={drizzle}
                        drizzleState={drizzleState}
                        contract="MiltonSpreadModel"
                        method="owner"
                    />
                </td>
                <td>
                    <ContractForm
                        drizzle={drizzle}
                        contract="MiltonSpreadModel"
                        method="transferOwnership"
                    />
                </td>
                <td>
                    <ContractForm
                        drizzle={drizzle}
                        contract="MiltonSpreadModel"
                        method="confirmTransferOwnership"
                    />
                </td>
            </tr>

            <tr>
                <td>MiltonUsdt</td>
                <td>
                    {process.env.REACT_APP_ITF_ENABLED === "true"
                        ? "NONE"
                        : drizzle.contracts.MiltonUsdt.address}
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
                        <ContractForm
                            drizzle={drizzle}
                            contract="MiltonUsdt"
                            method="transferOwnership"
                        />
                    )}
                </td>
                <td>
                    {process.env.REACT_APP_ITF_ENABLED === "true" ? (
                        "NONE"
                    ) : (
                        <ContractForm
                            drizzle={drizzle}
                            contract="MiltonUsdt"
                            method="confirmTransferOwnership"
                        />
                    )}
                </td>
            </tr>
            <tr>
                <td>MiltonUsdc</td>
                <td>
                    {process.env.REACT_APP_ITF_ENABLED === "true"
                        ? "NONE"
                        : drizzle.contracts.MiltonUsdc.address}
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
                        <ContractForm
                            drizzle={drizzle}
                            contract="MiltonUsdc"
                            method="transferOwnership"
                        />
                    )}
                </td>
                <td>
                    {process.env.REACT_APP_ITF_ENABLED === "true" ? (
                        "NONE"
                    ) : (
                        <ContractForm
                            drizzle={drizzle}
                            contract="MiltonUsdc"
                            method="confirmTransferOwnership"
                        />
                    )}
                </td>
            </tr>
            <tr>
                <td>MiltonDai</td>
                <td>
                    {process.env.REACT_APP_ITF_ENABLED === "true"
                        ? "NONE"
                        : drizzle.contracts.MiltonDai.address}
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
                <td>
                    {process.env.REACT_APP_ITF_ENABLED === "true" ? (
                        "NONE"
                    ) : (
                        <ContractForm
                            drizzle={drizzle}
                            contract="MiltonDai"
                            method="transferOwnership"
                        />
                    )}
                </td>
                <td>
                    {process.env.REACT_APP_ITF_ENABLED === "true" ? (
                        "NONE"
                    ) : (
                        <ContractForm
                            drizzle={drizzle}
                            contract="MiltonDai"
                            method="confirmTransferOwnership"
                        />
                    )}
                </td>
            </tr>
            <tr>
                <td>JosephUsdt</td>
                <td>
                    {process.env.REACT_APP_ITF_ENABLED === "true"
                        ? "NONE"
                        : drizzle.contracts.JosephUsdt.address}
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
                        <ContractForm
                            drizzle={drizzle}
                            contract="JosephUsdt"
                            method="transferOwnership"
                        />
                    )}
                </td>
                <td>
                    {process.env.REACT_APP_ITF_ENABLED === "true" ? (
                        "NONE"
                    ) : (
                        <ContractForm
                            drizzle={drizzle}
                            contract="JosephUsdt"
                            method="confirmTransferOwnership"
                        />
                    )}
                </td>
            </tr>
            <tr>
                <td>JosephUsdc</td>
                <td>
                    {process.env.REACT_APP_ITF_ENABLED === "true"
                        ? "NONE"
                        : drizzle.contracts.JosephUsdc.address}
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
                        <ContractForm
                            drizzle={drizzle}
                            contract="JosephUsdc"
                            method="transferOwnership"
                        />
                    )}
                </td>
                <td>
                    {process.env.REACT_APP_ITF_ENABLED === "true" ? (
                        "NONE"
                    ) : (
                        <ContractForm
                            drizzle={drizzle}
                            contract="JosephUsdc"
                            method="confirmTransferOwnership"
                        />
                    )}
                </td>
            </tr>
            <tr>
                <td>JosephDai</td>
                <td>
                    {process.env.REACT_APP_ITF_ENABLED === "true"
                        ? "NONE"
                        : drizzle.contracts.JosephDai.address}
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
                <td>
                    {process.env.REACT_APP_ITF_ENABLED === "true" ? (
                        "NONE"
                    ) : (
                        <ContractForm
                            drizzle={drizzle}
                            contract="JosephDai"
                            method="transferOwnership"
                        />
                    )}
                </td>
                <td>
                    {process.env.REACT_APP_ITF_ENABLED === "true" ? (
                        "NONE"
                    ) : (
                        <ContractForm
                            drizzle={drizzle}
                            contract="JosephDai"
                            method="confirmTransferOwnership"
                        />
                    )}
                </td>
            </tr>

            <tr>
                <td>StanleyUsdt</td>
                <td>
                    {process.env.REACT_APP_ITF_ENABLED === "true"
                        ? "NONE"
                        : drizzle.contracts.StanleyUsdt.address}
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
                        <ContractForm
                            drizzle={drizzle}
                            contract="StanleyUsdt"
                            method="transferOwnership"
                        />
                    )}
                </td>
                <td>
                    {process.env.REACT_APP_ITF_ENABLED === "true" ? (
                        "NONE"
                    ) : (
                        <ContractForm
                            drizzle={drizzle}
                            contract="StanleyUsdt"
                            method="confirmTransferOwnership"
                        />
                    )}
                </td>
            </tr>
            <tr>
                <td>StanleyUsdc</td>
                <td>
                    {process.env.REACT_APP_ITF_ENABLED === "true"
                        ? "NONE"
                        : drizzle.contracts.StanleyUsdc.address}
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
                        <ContractForm
                            drizzle={drizzle}
                            contract="StanleyUsdc"
                            method="transferOwnership"
                        />
                    )}
                </td>
                <td>
                    {process.env.REACT_APP_ITF_ENABLED === "true" ? (
                        "NONE"
                    ) : (
                        <ContractForm
                            drizzle={drizzle}
                            contract="StanleyUsdc"
                            method="confirmTransferOwnership"
                        />
                    )}
                </td>
            </tr>
            <tr>
                <td>StanleyDai</td>
                <td>
                    {process.env.REACT_APP_ITF_ENABLED === "true"
                        ? "NONE"
                        : drizzle.contracts.StanleyDai.address}
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
                <td>
                    {process.env.REACT_APP_ITF_ENABLED === "true" ? (
                        "NONE"
                    ) : (
                        <ContractForm
                            drizzle={drizzle}
                            contract="StanleyDai"
                            method="transferOwnership"
                        />
                    )}
                </td>
                <td>
                    {process.env.REACT_APP_ITF_ENABLED === "true" ? (
                        "NONE"
                    ) : (
                        <ContractForm
                            drizzle={drizzle}
                            contract="StanleyDai"
                            method="confirmTransferOwnership"
                        />
                    )}
                </td>
            </tr>
            <tr>
                <td>MiltonStorageUsdt</td>
                <td>{drizzle.contracts.MiltonStorageUsdt.address}</td>
                <td>
                    <ContractData
                        drizzle={drizzle}
                        drizzleState={drizzleState}
                        contract="MiltonStorageUsdt"
                        method="owner"
                    />
                </td>
                <td>
                    <ContractForm
                        drizzle={drizzle}
                        contract="MiltonStorageUsdt"
                        method="transferOwnership"
                    />
                </td>
                <td>
                    <ContractForm
                        drizzle={drizzle}
                        contract="MiltonStorageUsdt"
                        method="confirmTransferOwnership"
                    />
                </td>
            </tr>
            <tr>
                <td>MiltonStorageUsdc</td>
                <td>{drizzle.contracts.MiltonStorageUsdc.address}</td>
                <td>
                    <ContractData
                        drizzle={drizzle}
                        drizzleState={drizzleState}
                        contract="MiltonStorageUsdc"
                        method="owner"
                    />
                </td>
                <td>
                    <ContractForm
                        drizzle={drizzle}
                        contract="MiltonStorageUsdc"
                        method="transferOwnership"
                    />
                </td>
                <td>
                    <ContractForm
                        drizzle={drizzle}
                        contract="MiltonStorageUsdc"
                        method="confirmTransferOwnership"
                    />
                </td>
            </tr>
            <tr>
                <td>MiltonStorageDai</td>
                <td>{drizzle.contracts.MiltonStorageDai.address}</td>
                <td>
                    <ContractData
                        drizzle={drizzle}
                        drizzleState={drizzleState}
                        contract="MiltonStorageDai"
                        method="owner"
                    />
                </td>
                <td>
                    <ContractForm
                        drizzle={drizzle}
                        contract="MiltonStorageDai"
                        method="transferOwnership"
                    />
                </td>
                <td>
                    <ContractForm
                        drizzle={drizzle}
                        contract="MiltonStorageDai"
                        method="confirmTransferOwnership"
                    />
                </td>
            </tr>
            <tr>
                <td>Cockpit Data Provider</td>
                <td>{drizzle.contracts.CockpitDataProvider.address}</td>
                <td>
                    <ContractData
                        drizzle={drizzle}
                        drizzleState={drizzleState}
                        contract="CockpitDataProvider"
                        method="owner"
                    />
                </td>
                <td>
                    <ContractForm
                        drizzle={drizzle}
                        contract="CockpitDataProvider"
                        method="transferOwnership"
                    />
                </td>
                <td>
                    <ContractForm
                        drizzle={drizzle}
                        contract="CockpitDataProvider"
                        method="confirmTransferOwnership"
                    />
                </td>
            </tr>

            <tr>
                <td>Ipor Oracle Facade Data Provider</td>
                <td>{drizzle.contracts.IporOracleFacadeDataProvider.address}</td>
                <td>
                    <ContractData
                        drizzle={drizzle}
                        drizzleState={drizzleState}
                        contract="IporOracleFacadeDataProvider"
                        method="owner"
                    />
                </td>
                <td>
                    <ContractForm
                        drizzle={drizzle}
                        contract="IporOracleFacadeDataProvider"
                        method="transferOwnership"
                    />
                </td>
                <td>
                    <ContractForm
                        drizzle={drizzle}
                        contract="IporOracleFacadeDataProvider"
                        method="confirmTransferOwnership"
                    />
                </td>
            </tr>
            <tr>
                <td>Milton Facade Data Provider</td>
                <td>{drizzle.contracts.MiltonFacadeDataProvider.address}</td>
                <td>
                    <ContractData
                        drizzle={drizzle}
                        drizzleState={drizzleState}
                        contract="MiltonFacadeDataProvider"
                        method="owner"
                    />
                </td>
                <td>
                    <ContractForm
                        drizzle={drizzle}
                        contract="MiltonFacadeDataProvider"
                        method="transferOwnership"
                    />
                </td>
                <td>
                    <ContractForm
                        drizzle={drizzle}
                        contract="MiltonFacadeDataProvider"
                        method="confirmTransferOwnership"
                    />
                </td>
            </tr>
            <tr>
                <td>Testnet Faucet</td>
                <td>{drizzle.contracts.TestnetFaucet.address}</td>
                <td>
                    <ContractData
                        drizzle={drizzle}
                        drizzleState={drizzleState}
                        contract="TestnetFaucet"
                        method="owner"
                    />
                </td>
                <td>
                    <ContractForm
                        drizzle={drizzle}
                        contract="TestnetFaucet"
                        method="transferOwnership"
                    />
                </td>
                <td>
                    <ContractForm
                        drizzle={drizzle}
                        contract="TestnetFaucet"
                        method="confirmTransferOwnership"
                    />
                </td>
            </tr>
            <tr>
                <td>Mock Testnet Strategy Aave Usdt</td>
                <td>{drizzle.contracts.MockTestnetStrategyAaveUsdt.address}</td>
                <td>
                    <ContractData
                        drizzle={drizzle}
                        drizzleState={drizzleState}
                        contract="MockTestnetStrategyAaveUsdt"
                        method="owner"
                    />
                </td>
                <td>
                    <ContractForm
                        drizzle={drizzle}
                        contract="MockTestnetStrategyAaveUsdt"
                        method="transferOwnership"
                    />
                </td>
                <td>
                    <ContractForm
                        drizzle={drizzle}
                        contract="MockTestnetStrategyAaveUsdt"
                        method="confirmTransferOwnership"
                    />
                </td>
            </tr>

            <tr>
                <td>Mock Testnet Strategy Aave Usdc</td>
                <td>{drizzle.contracts.MockTestnetStrategyAaveUsdc.address}</td>
                <td>
                    <ContractData
                        drizzle={drizzle}
                        drizzleState={drizzleState}
                        contract="MockTestnetStrategyAaveUsdc"
                        method="owner"
                    />
                </td>
                <td>
                    <ContractForm
                        drizzle={drizzle}
                        contract="MockTestnetStrategyAaveUsdc"
                        method="transferOwnership"
                    />
                </td>
                <td>
                    <ContractForm
                        drizzle={drizzle}
                        contract="MockTestnetStrategyAaveUsdc"
                        method="confirmTransferOwnership"
                    />
                </td>
            </tr>

            <tr>
                <td>Mock Testnet Strategy Aave Dai</td>
                <td>{drizzle.contracts.MockTestnetStrategyAaveDai.address}</td>
                <td>
                    <ContractData
                        drizzle={drizzle}
                        drizzleState={drizzleState}
                        contract="MockTestnetStrategyAaveDai"
                        method="owner"
                    />
                </td>
                <td>
                    <ContractForm
                        drizzle={drizzle}
                        contract="MockTestnetStrategyAaveDai"
                        method="transferOwnership"
                    />
                </td>
                <td>
                    <ContractForm
                        drizzle={drizzle}
                        contract="MockTestnetStrategyAaveDai"
                        method="confirmTransferOwnership"
                    />
                </td>
            </tr>

            <tr>
                <td>Mock Testnet Strategy Compound Usdt</td>
                <td>{drizzle.contracts.MockTestnetStrategyCompoundUsdt.address}</td>
                <td>
                    <ContractData
                        drizzle={drizzle}
                        drizzleState={drizzleState}
                        contract="MockTestnetStrategyCompoundUsdt"
                        method="owner"
                    />
                </td>
                <td>
                    <ContractForm
                        drizzle={drizzle}
                        contract="MockTestnetStrategyCompoundUsdt"
                        method="transferOwnership"
                    />
                </td>
                <td>
                    <ContractForm
                        drizzle={drizzle}
                        contract="MockTestnetStrategyCompoundUsdt"
                        method="confirmTransferOwnership"
                    />
                </td>
            </tr>

            <tr>
                <td>Mock Testnet Strategy Compound Usdc</td>
                <td>{drizzle.contracts.MockTestnetStrategyCompoundUsdc.address}</td>
                <td>
                    <ContractData
                        drizzle={drizzle}
                        drizzleState={drizzleState}
                        contract="MockTestnetStrategyCompoundUsdc"
                        method="owner"
                    />
                </td>
                <td>
                    <ContractForm
                        drizzle={drizzle}
                        contract="MockTestnetStrategyCompoundUsdc"
                        method="transferOwnership"
                    />
                </td>
                <td>
                    <ContractForm
                        drizzle={drizzle}
                        contract="MockTestnetStrategyCompoundUsdc"
                        method="confirmTransferOwnership"
                    />
                </td>
            </tr>

            <tr>
                <td>Mock Testnet Strategy Compound Dai</td>
                <td>{drizzle.contracts.MockTestnetStrategyCompoundDai.address}</td>
                <td>
                    <ContractData
                        drizzle={drizzle}
                        drizzleState={drizzleState}
                        contract="MockTestnetStrategyCompoundDai"
                        method="owner"
                    />
                </td>
                <td>
                    <ContractForm
                        drizzle={drizzle}
                        contract="MockTestnetStrategyCompoundDai"
                        method="transferOwnership"
                    />
                </td>
                <td>
                    <ContractForm
                        drizzle={drizzle}
                        contract="MockTestnetStrategyCompoundDai"
                        method="confirmTransferOwnership"
                    />
                </td>
            </tr>
            <tr>
                <td>ItfOracle</td>
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
                <td>
                    {process.env.REACT_APP_ITF_ENABLED === "true" ? (
                        <ContractForm
                            drizzle={drizzle}
                            contract="ItfIporOracle"
                            method="transferOwnership"
                        />
                    ) : (
                        "NONE"
                    )}
                </td>
                <td>
                    {process.env.REACT_APP_ITF_ENABLED === "true" ? (
                        <ContractForm
                            drizzle={drizzle}
                            contract="ItfIporOracle"
                            method="confirmTransferOwnership"
                        />
                    ) : (
                        "NONE"
                    )}
                </td>
            </tr>

            <tr>
                <td>ItfMiltonUsdt</td>
                <td>
                    {process.env.REACT_APP_ITF_ENABLED === "true"
                        ? drizzle.contracts.ItfMiltonUsdt.address
                        : "NONE"}
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
                        <ContractForm
                            drizzle={drizzle}
                            contract="ItfMiltonUsdt"
                            method="transferOwnership"
                        />
                    ) : (
                        "NONE"
                    )}
                </td>
                <td>
                    {process.env.REACT_APP_ITF_ENABLED === "true" ? (
                        <ContractForm
                            drizzle={drizzle}
                            contract="ItfMiltonUsdt"
                            method="confirmTransferOwnership"
                        />
                    ) : (
                        "NONE"
                    )}
                </td>
            </tr>
            <tr>
                <td>ItfMiltonUsdc</td>
                <td>
                    {process.env.REACT_APP_ITF_ENABLED === "true"
                        ? drizzle.contracts.ItfMiltonUsdc.address
                        : "NONE"}
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
                        <ContractForm
                            drizzle={drizzle}
                            contract="ItfMiltonUsdc"
                            method="transferOwnership"
                        />
                    ) : (
                        "NONE"
                    )}
                </td>
                <td>
                    {process.env.REACT_APP_ITF_ENABLED === "true" ? (
                        <ContractForm
                            drizzle={drizzle}
                            contract="ItfMiltonUsdc"
                            method="confirmTransferOwnership"
                        />
                    ) : (
                        "NONE"
                    )}
                </td>
            </tr>
            <tr>
                <td>ItfMiltonDai</td>
                <td>
                    {process.env.REACT_APP_ITF_ENABLED === "true"
                        ? drizzle.contracts.ItfMiltonDai.address
                        : "NONE"}
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
                <td>
                    {process.env.REACT_APP_ITF_ENABLED === "true" ? (
                        <ContractForm
                            drizzle={drizzle}
                            contract="ItfMiltonDai"
                            method="transferOwnership"
                        />
                    ) : (
                        "NONE"
                    )}
                </td>
                <td>
                    {process.env.REACT_APP_ITF_ENABLED === "true" ? (
                        <ContractForm
                            drizzle={drizzle}
                            contract="ItfMiltonDai"
                            method="confirmTransferOwnership"
                        />
                    ) : (
                        "NONE"
                    )}
                </td>
            </tr>

            <tr>
                <td>ItfJosephUsdt</td>
                <td>
                    {process.env.REACT_APP_ITF_ENABLED === "true"
                        ? drizzle.contracts.ItfJosephUsdt.address
                        : "NONE"}
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
                        <ContractForm
                            drizzle={drizzle}
                            contract="ItfJosephUsdt"
                            method="transferOwnership"
                        />
                    ) : (
                        "NONE"
                    )}
                </td>
                <td>
                    {process.env.REACT_APP_ITF_ENABLED === "true" ? (
                        <ContractForm
                            drizzle={drizzle}
                            contract="ItfJosephUsdt"
                            method="confirmTransferOwnership"
                        />
                    ) : (
                        "NONE"
                    )}
                </td>
            </tr>
            <tr>
                <td>ItfJosephUsdc</td>
                <td>
                    {process.env.REACT_APP_ITF_ENABLED === "true"
                        ? drizzle.contracts.ItfJosephUsdc.address
                        : "NONE"}
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
                        <ContractForm
                            drizzle={drizzle}
                            contract="ItfJosephUsdc"
                            method="transferOwnership"
                        />
                    ) : (
                        "NONE"
                    )}
                </td>
                <td>
                    {process.env.REACT_APP_ITF_ENABLED === "true" ? (
                        <ContractForm
                            drizzle={drizzle}
                            contract="ItfJosephUsdc"
                            method="confirmTransferOwnership"
                        />
                    ) : (
                        "NONE"
                    )}
                </td>
            </tr>
            <tr>
                <td>ItfJosephDai</td>
                <td>
                    {process.env.REACT_APP_ITF_ENABLED === "true"
                        ? drizzle.contracts.ItfJosephDai.address
                        : "NONE"}
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
                <td>
                    {process.env.REACT_APP_ITF_ENABLED === "true" ? (
                        <ContractForm
                            drizzle={drizzle}
                            contract="ItfJosephDai"
                            method="transferOwnership"
                        />
                    ) : (
                        "NONE"
                    )}
                </td>
                <td>
                    {process.env.REACT_APP_ITF_ENABLED === "true" ? (
                        <ContractForm
                            drizzle={drizzle}
                            contract="ItfJosephDai"
                            method="confirmTransferOwnership"
                        />
                    ) : (
                        "NONE"
                    )}
                </td>
            </tr>

            <tr>
                <td>ItfStanleyUsdt</td>
                <td>
                    {process.env.REACT_APP_ITF_ENABLED === "true"
                        ? drizzle.contracts.ItfStanleyUsdt.address
                        : "NONE"}
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
                        <ContractForm
                            drizzle={drizzle}
                            contract="ItfStanleyUsdt"
                            method="transferOwnership"
                        />
                    ) : (
                        "NONE"
                    )}
                </td>
                <td>
                    {process.env.REACT_APP_ITF_ENABLED === "true" ? (
                        <ContractForm
                            drizzle={drizzle}
                            contract="ItfStanleyUsdt"
                            method="confirmTransferOwnership"
                        />
                    ) : (
                        "NONE"
                    )}
                </td>
            </tr>
            <tr>
                <td>ItfStanleyUsdc</td>
                <td>
                    {process.env.REACT_APP_ITF_ENABLED === "true"
                        ? drizzle.contracts.ItfStanleyUsdc.address
                        : "NONE"}
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
                        <ContractForm
                            drizzle={drizzle}
                            contract="ItfStanleyUsdc"
                            method="transferOwnership"
                        />
                    ) : (
                        "NONE"
                    )}
                </td>
                <td>
                    {process.env.REACT_APP_ITF_ENABLED === "true" ? (
                        <ContractForm
                            drizzle={drizzle}
                            contract="ItfStanleyUsdc"
                            method="confirmTransferOwnership"
                        />
                    ) : (
                        "NONE"
                    )}
                </td>
            </tr>
            <tr>
                <td>ItfStanleyDai</td>
                <td>
                    {process.env.REACT_APP_ITF_ENABLED === "true"
                        ? drizzle.contracts.ItfStanleyDai.address
                        : "NONE"}
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
                <td>
                    {process.env.REACT_APP_ITF_ENABLED === "true" ? (
                        <ContractForm
                            drizzle={drizzle}
                            contract="ItfStanleyDai"
                            method="transferOwnership"
                        />
                    ) : (
                        "NONE"
                    )}
                </td>
                <td>
                    {process.env.REACT_APP_ITF_ENABLED === "true" ? (
                        <ContractForm
                            drizzle={drizzle}
                            contract="ItfStanleyDai"
                            method="confirmTransferOwnership"
                        />
                    ) : (
                        "NONE"
                    )}
                </td>
            </tr>
        </table>

        <hr />
        <table className="table" align="center">
            <tr>
                <th scope="col">Contract</th>
                <th scope="col">Address</th>
                <th scope="col">Is Paused?</th>
                <th scope="col">Pause</th>
                <th scope="col">Unpause</th>
            </tr>
            <tr>
                <td>Ipor Oracle</td>
                <td>
                    {process.env.REACT_APP_ITF_ENABLED === "true"
                        ? "NONE"
                        : drizzle.contracts.IporOracle.address}
                </td>
                <td>
                    {process.env.REACT_APP_ITF_ENABLED === "true" ? (
                        "NONE"
                    ) : (
                        <ContractData
                            drizzle={drizzle}
                            drizzleState={drizzleState}
                            contract="IporOracle"
                            method="paused"
                        />
                    )}
                </td>
                <td>
                    {process.env.REACT_APP_ITF_ENABLED === "true" ? (
                        "NONE"
                    ) : (
                        <ContractForm drizzle={drizzle} contract="IporOracle" method="pause" />
                    )}
                </td>
                <td>
                    {process.env.REACT_APP_ITF_ENABLED === "true" ? (
                        "NONE"
                    ) : (
                        <ContractForm drizzle={drizzle} contract="IporOracle" method="unpause" />
                    )}
                </td>
            </tr>

            <tr>
                <td>MiltonUsdt</td>
                <td>
                    {process.env.REACT_APP_ITF_ENABLED === "true"
                        ? "NONE"
                        : drizzle.contracts.MiltonUsdt.address}
                </td>
                <td>
                    {process.env.REACT_APP_ITF_ENABLED === "true" ? (
                        "NONE"
                    ) : (
                        <ContractData
                            drizzle={drizzle}
                            drizzleState={drizzleState}
                            contract="MiltonUsdt"
                            method="paused"
                        />
                    )}
                </td>
                <td>
                    {process.env.REACT_APP_ITF_ENABLED === "true" ? (
                        "NONE"
                    ) : (
                        <ContractForm drizzle={drizzle} contract="MiltonUsdt" method="pause" />
                    )}
                </td>
                <td>
                    {process.env.REACT_APP_ITF_ENABLED === "true" ? (
                        "NONE"
                    ) : (
                        <ContractForm drizzle={drizzle} contract="MiltonUsdt" method="unpause" />
                    )}
                </td>
            </tr>
            <tr>
                <td>MiltonUsdc</td>
                <td>
                    {process.env.REACT_APP_ITF_ENABLED === "true"
                        ? "NONE"
                        : drizzle.contracts.MiltonUsdc.address}
                </td>
                <td>
                    {process.env.REACT_APP_ITF_ENABLED === "true" ? (
                        "NONE"
                    ) : (
                        <ContractData
                            drizzle={drizzle}
                            drizzleState={drizzleState}
                            contract="MiltonUsdc"
                            method="paused"
                        />
                    )}
                </td>
                <td>
                    {process.env.REACT_APP_ITF_ENABLED === "true" ? (
                        "NONE"
                    ) : (
                        <ContractForm drizzle={drizzle} contract="MiltonUsdc" method="pause" />
                    )}
                </td>
                <td>
                    {process.env.REACT_APP_ITF_ENABLED === "true" ? (
                        "NONE"
                    ) : (
                        <ContractForm drizzle={drizzle} contract="MiltonUsdc" method="unpause" />
                    )}
                </td>
            </tr>
            <tr>
                <td>MiltonDai</td>
                <td>
                    {process.env.REACT_APP_ITF_ENABLED === "true"
                        ? "NONE"
                        : drizzle.contracts.MiltonDai.address}
                </td>
                <td>
                    {process.env.REACT_APP_ITF_ENABLED === "true" ? (
                        "NONE"
                    ) : (
                        <ContractData
                            drizzle={drizzle}
                            drizzleState={drizzleState}
                            contract="MiltonDai"
                            method="paused"
                        />
                    )}
                </td>
                <td>
                    {process.env.REACT_APP_ITF_ENABLED === "true" ? (
                        "NONE"
                    ) : (
                        <ContractForm drizzle={drizzle} contract="MiltonDai" method="pause" />
                    )}
                </td>
                <td>
                    {process.env.REACT_APP_ITF_ENABLED === "true" ? (
                        "NONE"
                    ) : (
                        <ContractForm drizzle={drizzle} contract="MiltonDai" method="unpause" />
                    )}
                </td>
            </tr>
            <tr>
                <td>JosephUsdt</td>
                <td>
                    {process.env.REACT_APP_ITF_ENABLED === "true"
                        ? "NONE"
                        : drizzle.contracts.JosephUsdt.address}
                </td>
                <td>
                    {process.env.REACT_APP_ITF_ENABLED === "true" ? (
                        "NONE"
                    ) : (
                        <ContractData
                            drizzle={drizzle}
                            drizzleState={drizzleState}
                            contract="JosephUsdt"
                            method="paused"
                        />
                    )}
                </td>
                <td>
                    {process.env.REACT_APP_ITF_ENABLED === "true" ? (
                        "NONE"
                    ) : (
                        <ContractForm drizzle={drizzle} contract="JosephUsdt" method="pause" />
                    )}
                </td>
                <td>
                    {process.env.REACT_APP_ITF_ENABLED === "true" ? (
                        "NONE"
                    ) : (
                        <ContractForm drizzle={drizzle} contract="JosephUsdt" method="unpause" />
                    )}
                </td>
            </tr>
            <tr>
                <td>JosephUsdc</td>
                <td>
                    {process.env.REACT_APP_ITF_ENABLED === "true"
                        ? "NONE"
                        : drizzle.contracts.JosephUsdc.address}
                </td>
                <td>
                    {process.env.REACT_APP_ITF_ENABLED === "true" ? (
                        "NONE"
                    ) : (
                        <ContractData
                            drizzle={drizzle}
                            drizzleState={drizzleState}
                            contract="JosephUsdc"
                            method="paused"
                        />
                    )}
                </td>
                <td>
                    {process.env.REACT_APP_ITF_ENABLED === "true" ? (
                        "NONE"
                    ) : (
                        <ContractForm drizzle={drizzle} contract="JosephUsdc" method="pause" />
                    )}
                </td>
                <td>
                    {process.env.REACT_APP_ITF_ENABLED === "true" ? (
                        "NONE"
                    ) : (
                        <ContractForm drizzle={drizzle} contract="JosephUsdc" method="unpause" />
                    )}
                </td>
            </tr>
            <tr>
                <td>JosephDai</td>
                <td>
                    {process.env.REACT_APP_ITF_ENABLED === "true"
                        ? "NONE"
                        : drizzle.contracts.JosephDai.address}
                </td>
                <td>
                    {process.env.REACT_APP_ITF_ENABLED === "true" ? (
                        "NONE"
                    ) : (
                        <ContractData
                            drizzle={drizzle}
                            drizzleState={drizzleState}
                            contract="JosephDai"
                            method="paused"
                        />
                    )}
                </td>
                <td>
                    {process.env.REACT_APP_ITF_ENABLED === "true" ? (
                        "NONE"
                    ) : (
                        <ContractForm drizzle={drizzle} contract="JosephDai" method="pause" />
                    )}
                </td>
                <td>
                    {process.env.REACT_APP_ITF_ENABLED === "true" ? (
                        "NONE"
                    ) : (
                        <ContractForm drizzle={drizzle} contract="JosephDai" method="unpause" />
                    )}
                </td>
            </tr>

            <tr>
                <td>StanleyUsdt</td>
                <td>
                    {process.env.REACT_APP_ITF_ENABLED === "true"
                        ? "NONE"
                        : drizzle.contracts.StanleyUsdt.address}
                </td>
                <td>
                    {process.env.REACT_APP_ITF_ENABLED === "true" ? (
                        "NONE"
                    ) : (
                        <ContractData
                            drizzle={drizzle}
                            drizzleState={drizzleState}
                            contract="StanleyUsdt"
                            method="paused"
                        />
                    )}
                </td>
                <td>
                    {process.env.REACT_APP_ITF_ENABLED === "true" ? (
                        "NONE"
                    ) : (
                        <ContractForm drizzle={drizzle} contract="StanleyUsdt" method="pause" />
                    )}
                </td>
                <td>
                    {process.env.REACT_APP_ITF_ENABLED === "true" ? (
                        "NONE"
                    ) : (
                        <ContractForm drizzle={drizzle} contract="StanleyUsdt" method="unpause" />
                    )}
                </td>
            </tr>
            <tr>
                <td>StanleyUsdc</td>
                <td>
                    {process.env.REACT_APP_ITF_ENABLED === "true"
                        ? "NONE"
                        : drizzle.contracts.StanleyUsdc.address}
                </td>
                <td>
                    {process.env.REACT_APP_ITF_ENABLED === "true" ? (
                        "NONE"
                    ) : (
                        <ContractData
                            drizzle={drizzle}
                            drizzleState={drizzleState}
                            contract="StanleyUsdc"
                            method="paused"
                        />
                    )}
                </td>
                <td>
                    {process.env.REACT_APP_ITF_ENABLED === "true" ? (
                        "NONE"
                    ) : (
                        <ContractForm drizzle={drizzle} contract="StanleyUsdc" method="pause" />
                    )}
                </td>
                <td>
                    {process.env.REACT_APP_ITF_ENABLED === "true" ? (
                        "NONE"
                    ) : (
                        <ContractForm drizzle={drizzle} contract="StanleyUsdc" method="unpause" />
                    )}
                </td>
            </tr>
            <tr>
                <td>StanleyDai</td>
                <td>
                    {process.env.REACT_APP_ITF_ENABLED === "true"
                        ? "NONE"
                        : drizzle.contracts.StanleyDai.address}
                </td>
                <td>
                    {process.env.REACT_APP_ITF_ENABLED === "true" ? (
                        "NONE"
                    ) : (
                        <ContractData
                            drizzle={drizzle}
                            drizzleState={drizzleState}
                            contract="StanleyDai"
                            method="paused"
                        />
                    )}
                </td>
                <td>
                    {process.env.REACT_APP_ITF_ENABLED === "true" ? (
                        "NONE"
                    ) : (
                        <ContractForm drizzle={drizzle} contract="StanleyDai" method="pause" />
                    )}
                </td>
                <td>
                    {process.env.REACT_APP_ITF_ENABLED === "true" ? (
                        "NONE"
                    ) : (
                        <ContractForm drizzle={drizzle} contract="StanleyDai" method="unpause" />
                    )}
                </td>
            </tr>
            <tr>
                <td>MiltonStorageUsdt</td>
                <td>{drizzle.contracts.MiltonStorageUsdt.address}</td>
                <td>
                    <ContractData
                        drizzle={drizzle}
                        drizzleState={drizzleState}
                        contract="MiltonStorageUsdt"
                        method="paused"
                    />
                </td>
                <td>
                    <ContractForm drizzle={drizzle} contract="MiltonStorageUsdt" method="pause" />
                </td>
                <td>
                    <ContractForm drizzle={drizzle} contract="MiltonStorageUsdt" method="unpause" />
                </td>
            </tr>
            <tr>
                <td>MiltonStorageUsdc</td>
                <td>{drizzle.contracts.MiltonStorageUsdc.address}</td>
                <td>
                    <ContractData
                        drizzle={drizzle}
                        drizzleState={drizzleState}
                        contract="MiltonStorageUsdc"
                        method="paused"
                    />
                </td>
                <td>
                    <ContractForm drizzle={drizzle} contract="MiltonStorageUsdc" method="pause" />
                </td>
                <td>
                    <ContractForm drizzle={drizzle} contract="MiltonStorageUsdc" method="unpause" />
                </td>
            </tr>
            <tr>
                <td>MiltonStorageDai</td>
                <td>{drizzle.contracts.MiltonStorageDai.address}</td>
                <td>
                    <ContractData
                        drizzle={drizzle}
                        drizzleState={drizzleState}
                        contract="MiltonStorageDai"
                        method="paused"
                    />
                </td>
                <td>
                    <ContractForm drizzle={drizzle} contract="MiltonStorageDai" method="pause" />
                </td>
                <td>
                    <ContractForm drizzle={drizzle} contract="MiltonStorageDai" method="unpause" />
                </td>
            </tr>

            <tr>
                <td>Mock Testnet Strategy Aave Usdt</td>
                <td>{drizzle.contracts.MockTestnetStrategyAaveUsdt.address}</td>
                <td>
                    <ContractData
                        drizzle={drizzle}
                        drizzleState={drizzleState}
                        contract="MockTestnetStrategyAaveUsdt"
                        method="paused"
                    />
                </td>
                <td>
                    <ContractForm
                        drizzle={drizzle}
                        contract="MockTestnetStrategyAaveUsdt"
                        method="pause"
                    />
                </td>
                <td>
                    <ContractForm
                        drizzle={drizzle}
                        contract="MockTestnetStrategyAaveUsdt"
                        method="unpause"
                    />
                </td>
            </tr>

            <tr>
                <td>Mock Testnet Strategy Aave Usdc</td>
                <td>{drizzle.contracts.MockTestnetStrategyAaveUsdc.address}</td>
                <td>
                    <ContractData
                        drizzle={drizzle}
                        drizzleState={drizzleState}
                        contract="MockTestnetStrategyAaveUsdc"
                        method="paused"
                    />
                </td>
                <td>
                    <ContractForm
                        drizzle={drizzle}
                        contract="MockTestnetStrategyAaveUsdc"
                        method="pause"
                    />
                </td>
                <td>
                    <ContractForm
                        drizzle={drizzle}
                        contract="MockTestnetStrategyAaveUsdc"
                        method="unpause"
                    />
                </td>
            </tr>

            <tr>
                <td>Mock Testnet Strategy Aave Dai</td>
                <td>{drizzle.contracts.MockTestnetStrategyAaveDai.address}</td>
                <td>
                    <ContractData
                        drizzle={drizzle}
                        drizzleState={drizzleState}
                        contract="MockTestnetStrategyAaveDai"
                        method="paused"
                    />
                </td>
                <td>
                    <ContractForm
                        drizzle={drizzle}
                        contract="MockTestnetStrategyAaveDai"
                        method="pause"
                    />
                </td>
                <td>
                    <ContractForm
                        drizzle={drizzle}
                        contract="MockTestnetStrategyAaveDai"
                        method="unpause"
                    />
                </td>
            </tr>

            <tr>
                <td>Mock Testnet Strategy Compound Usdt</td>
                <td>{drizzle.contracts.MockTestnetStrategyCompoundUsdt.address}</td>
                <td>
                    <ContractData
                        drizzle={drizzle}
                        drizzleState={drizzleState}
                        contract="MockTestnetStrategyCompoundUsdt"
                        method="paused"
                    />
                </td>
                <td>
                    <ContractForm
                        drizzle={drizzle}
                        contract="MockTestnetStrategyCompoundUsdt"
                        method="pause"
                    />
                </td>
                <td>
                    <ContractForm
                        drizzle={drizzle}
                        contract="MockTestnetStrategyCompoundUsdt"
                        method="unpause"
                    />
                </td>
            </tr>

            <tr>
                <td>Mock Testnet Strategy Compound Usdc</td>
                <td>{drizzle.contracts.MockTestnetStrategyCompoundUsdc.address}</td>
                <td>
                    <ContractData
                        drizzle={drizzle}
                        drizzleState={drizzleState}
                        contract="MockTestnetStrategyCompoundUsdc"
                        method="paused"
                    />
                </td>
                <td>
                    <ContractForm
                        drizzle={drizzle}
                        contract="MockTestnetStrategyCompoundUsdc"
                        method="pause"
                    />
                </td>
                <td>
                    <ContractForm
                        drizzle={drizzle}
                        contract="MockTestnetStrategyCompoundUsdc"
                        method="unpause"
                    />
                </td>
            </tr>

            <tr>
                <td>Mock Testnet Strategy Compound Dai</td>
                <td>{drizzle.contracts.MockTestnetStrategyCompoundDai.address}</td>
                <td>
                    <ContractData
                        drizzle={drizzle}
                        drizzleState={drizzleState}
                        contract="MockTestnetStrategyCompoundDai"
                        method="paused"
                    />
                </td>
                <td>
                    <ContractForm
                        drizzle={drizzle}
                        contract="MockTestnetStrategyCompoundDai"
                        method="pause"
                    />
                </td>
                <td>
                    <ContractForm
                        drizzle={drizzle}
                        contract="MockTestnetStrategyCompoundDai"
                        method="unpause"
                    />
                </td>
            </tr>

            <tr>
                <td>ItfIporOracle</td>
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
                            method="paused"
                        />
                    ) : (
                        "NONE"
                    )}
                </td>
                <td>
                    {process.env.REACT_APP_ITF_ENABLED === "true" ? (
                        <ContractForm drizzle={drizzle} contract="ItfIporOracle" method="pause" />
                    ) : (
                        "NONE"
                    )}
                </td>
                <td>
                    {process.env.REACT_APP_ITF_ENABLED === "true" ? (
                        <ContractForm drizzle={drizzle} contract="ItfIporOracle" method="unpause" />
                    ) : (
                        "NONE"
                    )}
                </td>
            </tr>

            <tr>
                <td>ItfMiltonUsdt</td>
                <td>
                    {process.env.REACT_APP_ITF_ENABLED === "true"
                        ? drizzle.contracts.ItfMiltonUsdt.address
                        : "NONE"}
                </td>
                <td>
                    {process.env.REACT_APP_ITF_ENABLED === "true" ? (
                        <ContractData
                            drizzle={drizzle}
                            drizzleState={drizzleState}
                            contract="ItfMiltonUsdt"
                            method="paused"
                        />
                    ) : (
                        "NONE"
                    )}
                </td>
                <td>
                    {process.env.REACT_APP_ITF_ENABLED === "true" ? (
                        <ContractForm drizzle={drizzle} contract="ItfMiltonUsdt" method="pause" />
                    ) : (
                        "NONE"
                    )}
                </td>
                <td>
                    {process.env.REACT_APP_ITF_ENABLED === "true" ? (
                        <ContractForm drizzle={drizzle} contract="ItfMiltonUsdt" method="unpause" />
                    ) : (
                        "NONE"
                    )}
                </td>
            </tr>
            <tr>
                <td>ItfMiltonUsdc</td>
                <td>
                    {process.env.REACT_APP_ITF_ENABLED === "true"
                        ? drizzle.contracts.ItfMiltonUsdc.address
                        : "NONE"}
                </td>
                <td>
                    {process.env.REACT_APP_ITF_ENABLED === "true" ? (
                        <ContractData
                            drizzle={drizzle}
                            drizzleState={drizzleState}
                            contract="ItfMiltonUsdc"
                            method="paused"
                        />
                    ) : (
                        "NONE"
                    )}
                </td>
                <td>
                    {process.env.REACT_APP_ITF_ENABLED === "true" ? (
                        <ContractForm drizzle={drizzle} contract="ItfMiltonUsdc" method="pause" />
                    ) : (
                        "NONE"
                    )}
                </td>
                <td>
                    {process.env.REACT_APP_ITF_ENABLED === "true" ? (
                        <ContractForm drizzle={drizzle} contract="ItfMiltonUsdc" method="unpause" />
                    ) : (
                        "NONE"
                    )}
                </td>
            </tr>
            <tr>
                <td>ItfMiltonDai</td>
                <td>
                    {process.env.REACT_APP_ITF_ENABLED === "true"
                        ? drizzle.contracts.ItfMiltonDai.address
                        : "NONE"}
                </td>
                <td>
                    {process.env.REACT_APP_ITF_ENABLED === "true" ? (
                        <ContractData
                            drizzle={drizzle}
                            drizzleState={drizzleState}
                            contract="ItfMiltonDai"
                            method="paused"
                        />
                    ) : (
                        "NONE"
                    )}
                </td>
                <td>
                    {process.env.REACT_APP_ITF_ENABLED === "true" ? (
                        <ContractForm drizzle={drizzle} contract="ItfMiltonDai" method="pause" />
                    ) : (
                        "NONE"
                    )}
                </td>
                <td>
                    {process.env.REACT_APP_ITF_ENABLED === "true" ? (
                        <ContractForm drizzle={drizzle} contract="ItfMiltonDai" method="unpause" />
                    ) : (
                        "NONE"
                    )}
                </td>
            </tr>

            <tr>
                <td>ItfJosephUsdt</td>
                <td>
                    {process.env.REACT_APP_ITF_ENABLED === "true"
                        ? drizzle.contracts.ItfJosephUsdt.address
                        : "NONE"}
                </td>
                <td>
                    {process.env.REACT_APP_ITF_ENABLED === "true" ? (
                        <ContractData
                            drizzle={drizzle}
                            drizzleState={drizzleState}
                            contract="ItfJosephUsdt"
                            method="paused"
                        />
                    ) : (
                        "NONE"
                    )}
                </td>
                <td>
                    {process.env.REACT_APP_ITF_ENABLED === "true" ? (
                        <ContractForm drizzle={drizzle} contract="ItfJosephUsdt" method="pause" />
                    ) : (
                        "NONE"
                    )}
                </td>
                <td>
                    {process.env.REACT_APP_ITF_ENABLED === "true" ? (
                        <ContractForm drizzle={drizzle} contract="ItfJosephUsdt" method="unpause" />
                    ) : (
                        "NONE"
                    )}
                </td>
            </tr>
            <tr>
                <td>ItfJosephUsdc</td>
                <td>
                    {process.env.REACT_APP_ITF_ENABLED === "true"
                        ? drizzle.contracts.ItfJosephUsdc.address
                        : "NONE"}
                </td>
                <td>
                    {process.env.REACT_APP_ITF_ENABLED === "true" ? (
                        <ContractData
                            drizzle={drizzle}
                            drizzleState={drizzleState}
                            contract="ItfJosephUsdc"
                            method="paused"
                        />
                    ) : (
                        "NONE"
                    )}
                </td>
                <td>
                    {process.env.REACT_APP_ITF_ENABLED === "true" ? (
                        <ContractForm drizzle={drizzle} contract="ItfJosephUsdc" method="pause" />
                    ) : (
                        "NONE"
                    )}
                </td>
                <td>
                    {process.env.REACT_APP_ITF_ENABLED === "true" ? (
                        <ContractForm drizzle={drizzle} contract="ItfJosephUsdc" method="unpause" />
                    ) : (
                        "NONE"
                    )}
                </td>
            </tr>
            <tr>
                <td>ItfJosephDai</td>
                <td>
                    {process.env.REACT_APP_ITF_ENABLED === "true"
                        ? drizzle.contracts.ItfJosephDai.address
                        : "NONE"}
                </td>
                <td>
                    {process.env.REACT_APP_ITF_ENABLED === "true" ? (
                        <ContractData
                            drizzle={drizzle}
                            drizzleState={drizzleState}
                            contract="ItfJosephDai"
                            method="paused"
                        />
                    ) : (
                        "NONE"
                    )}
                </td>
                <td>
                    {process.env.REACT_APP_ITF_ENABLED === "true" ? (
                        <ContractForm drizzle={drizzle} contract="ItfJosephDai" method="pause" />
                    ) : (
                        "NONE"
                    )}
                </td>
                <td>
                    {process.env.REACT_APP_ITF_ENABLED === "true" ? (
                        <ContractForm drizzle={drizzle} contract="ItfJosephDai" method="unpause" />
                    ) : (
                        "NONE"
                    )}
                </td>
            </tr>

            <tr>
                <td>ItfStanleyUsdt</td>
                <td>
                    {process.env.REACT_APP_ITF_ENABLED === "true"
                        ? drizzle.contracts.ItfStanleyUsdt.address
                        : "NONE"}
                </td>
                <td>
                    {process.env.REACT_APP_ITF_ENABLED === "true" ? (
                        <ContractData
                            drizzle={drizzle}
                            drizzleState={drizzleState}
                            contract="ItfStanleyUsdt"
                            method="paused"
                        />
                    ) : (
                        "NONE"
                    )}
                </td>
                <td>
                    {process.env.REACT_APP_ITF_ENABLED === "true" ? (
                        <ContractForm drizzle={drizzle} contract="ItfStanleyUsdt" method="pause" />
                    ) : (
                        "NONE"
                    )}
                </td>
                <td>
                    {process.env.REACT_APP_ITF_ENABLED === "true" ? (
                        <ContractForm
                            drizzle={drizzle}
                            contract="ItfStanleyUsdt"
                            method="unpause"
                        />
                    ) : (
                        "NONE"
                    )}
                </td>
            </tr>
            <tr>
                <td>ItfStanleyUsdc</td>
                <td>
                    {process.env.REACT_APP_ITF_ENABLED === "true"
                        ? drizzle.contracts.ItfStanleyUsdc.address
                        : "NONE"}
                </td>
                <td>
                    {process.env.REACT_APP_ITF_ENABLED === "true" ? (
                        <ContractData
                            drizzle={drizzle}
                            drizzleState={drizzleState}
                            contract="ItfStanleyUsdc"
                            method="paused"
                        />
                    ) : (
                        "NONE"
                    )}
                </td>
                <td>
                    {process.env.REACT_APP_ITF_ENABLED === "true" ? (
                        <ContractForm drizzle={drizzle} contract="ItfStanleyUsdc" method="pause" />
                    ) : (
                        "NONE"
                    )}
                </td>
                <td>
                    {process.env.REACT_APP_ITF_ENABLED === "true" ? (
                        <ContractForm
                            drizzle={drizzle}
                            contract="ItfStanleyUsdc"
                            method="unpause"
                        />
                    ) : (
                        "NONE"
                    )}
                </td>
            </tr>
            <tr>
                <td>ItfStanleyDai</td>
                <td>
                    {process.env.REACT_APP_ITF_ENABLED === "true"
                        ? drizzle.contracts.ItfStanleyDai.address
                        : "NONE"}
                </td>
                <td>
                    {process.env.REACT_APP_ITF_ENABLED === "true" ? (
                        <ContractData
                            drizzle={drizzle}
                            drizzleState={drizzleState}
                            contract="ItfStanleyDai"
                            method="paused"
                        />
                    ) : (
                        "NONE"
                    )}
                </td>
                <td>
                    {process.env.REACT_APP_ITF_ENABLED === "true" ? (
                        <ContractForm drizzle={drizzle} contract="ItfStanleyDai" method="pause" />
                    ) : (
                        "NONE"
                    )}
                </td>
                <td>
                    {process.env.REACT_APP_ITF_ENABLED === "true" ? (
                        <ContractForm drizzle={drizzle} contract="ItfStanleyDai" method="unpause" />
                    ) : (
                        "NONE"
                    )}
                </td>
            </tr>
        </table>
    </div>
);

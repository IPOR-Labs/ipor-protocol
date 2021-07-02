import React from "react";
import {newContextComponents} from "@drizzle/react-components";
import logo from "./logo.png";
import {Container, Navbar, Tabs} from "react-bootstrap";
import {Tab} from "bootstrap";
import IporIndexComponent from "./IporIndexComponent";
import IporAmmComponent from "./IporAmmComponent";


const {AccountData, ContractData, ContractForm} = newContextComponents;

export default ({drizzle, drizzleState}) => {
    return (
        <div className="App">
            <Container>
            <Navbar fixed="top" bg="dark" variant="dark">
                <Navbar.Brand href="#home">
                    <img
                        alt=""
                        src={logo}
                        width="30"
                        height="30"
                        className="d-inline-block align-top ipor-navbar"
                    />{' '}
                    IPOR Protocol
                </Navbar.Brand>
            </Navbar>
            </Container>

            <div className="section">
                <p>Active Account</p>
                <AccountData
                    drizzle={drizzle}
                    drizzleState={drizzleState}
                    accountIndex={0}
                    units="ether"
                    precision={3}
                />
            </div>

            <Tabs defaultActiveKey="profile" id="uncontrolled-tab-example">
                <Tab eventKey="iporIndex" title="Oracle IPOR Index">
                    <IporIndexComponent
                        drizzle={drizzle}
                        drizzleState={drizzleState}
                    />
                </Tab>
                <Tab eventKey="iporAmm" title="IPOR AMM">
                    <IporAmmComponent
                        drizzle={drizzle}
                        drizzleState={drizzleState}
                    />
                </Tab>
            </Tabs>
        </div>
    );
}

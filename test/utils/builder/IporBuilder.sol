contract IporBuilder {
    struct IporProtocol {
        MockTestnetToken asset;
        IpToken ipToken;
        ItfStanley stanley;
        MiltonStorage miltonStorage;
        ItfMilton milton;
        ItfJoseph joseph;
        ItfIporOracle iporOracle;
        MockSpreadModel miltonSpreadModel;
    }

    IporProtocol private iporProtocol;

    constructor() {
        iporProtocol = IporProtocol("Default", 0, address(0));
    }

    function withName(string memory _name) public returns (IporBuilder) {
        iporProtocol.name = _name;
        return this;
    }

    function build() public returns (Something) {
        return new Something(
            builderData.name,
            builderData.value,
            builderData.owner
        );
    }
}
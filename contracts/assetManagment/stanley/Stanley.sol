pragma solidity 0.8.9;

import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "../interfaces/IPOR/IStrategy.sol";
import "../interfaces/IPOR/IIporOwnableUpgradeable.sol";
import "../interfaces/IIvToken.sol";
import "./StanleyAccessControl.sol";
import "./ExchangeRate.sol";
// TODO: use errors from Ipor Protocol
import "../errors/Errors.sol";

// import "hardhat/console.sol";

// IPORVault
// TODO: public -> external
// TODO: Add IStanley with busineess methods
contract Stanley is UUPSUpgradeable, StanleyAccessControl, ExchangeRate {
    using SafeERC20Upgradeable for IERC20Upgradeable;

    // TODO: use consistent way for fields
    address private _aaveStrategy;
    address private _aaveShareTokens;
    address private _compoundStrategy;
    address private _compoundShareTokens;
    // TODO: underlyingToken -> assetToken
    address public underlyingToken;
    address public ivToken;

    // TODO: maybe better move to interface (all in AM)
    event SetStrategy(address _strategy, address _shareToken);
    event Deposit(address _strategy, uint256 _amount);
    event Withdraw(address _strategy, uint256 _shares);
    event MigrateAsset(
        address _currentStrategy,
        address _newStrategy,
        uint256 _amount
    );
    event DoClaim(address _strategy, address _account);

    /**
     * @dev Deploy IPORVault.
     * @notice Deploy IPORVault.
     * @param _underlyingToken underlying token like DAI, USDT etc.
     */
    function initialize(
        // TODO: I am using _ only for private method and fields
        address _underlyingToken,
        address _ivToken,
        address _aStrategy,
        address _cStrategy
    ) public initializer {
        _init();
        require(_underlyingToken != address(0), Errors.ZERO_ADDRESS);
        require(_ivToken != address(0), Errors.ZERO_ADDRESS);

        underlyingToken = _underlyingToken;
        ivToken = _ivToken;

        _setAaveStrategy(_aStrategy);
        _setCompoundStrategy(_cStrategy);
    }

    function setCompoundStrategy(address _strategy)
        external
        onlyRole(_GOVERNANCE_ROLE)
    {
        _setCompoundStrategy(_strategy);
    }

    // TODO: Consider reorder checks in this way that method will have less calculation (gas opt)
    function _setCompoundStrategy(address _strategy) internal {
        require(_strategy != address(0), Errors.ZERO_ADDRESS);
        IERC20Upgradeable uToken = IERC20Upgradeable(underlyingToken);
        IStrategy strategy = IStrategy(_strategy);
        IERC20Upgradeable csToken = IERC20Upgradeable(_compoundShareTokens);
        if (_compoundStrategy != address(0)) {
            // TODO: safeIncreaseAllowance
            uToken.safeApprove(_compoundStrategy, 0);
            csToken.safeApprove(_compoundStrategy, 0);
        }
        address _compoundUnderlyingToken = strategy.getUnderlyingToken();
        // TODO: COMPATIBLE
        require(
            _compoundUnderlyingToken == address(underlyingToken),
            Errors.UNDERLYINGTOKEN_IS_NOT_COMPATIBLY
        );

        _compoundStrategy = _strategy;
        _compoundShareTokens = IStrategy(_strategy).shareToken();
        IERC20Upgradeable newCsToken = IERC20Upgradeable(_compoundShareTokens);
        uToken.safeApprove(_strategy, 0);
        uToken.safeApprove(_strategy, type(uint256).max);
        newCsToken.safeApprove(_strategy, 0);
        newCsToken.safeApprove(_strategy, type(uint256).max);
        emit SetStrategy(_strategy, _compoundShareTokens);
    }

    function setAaveStrategy(address _strategy)
        external
        onlyRole(_GOVERNANCE_ROLE)
    {
        _setAaveStrategy(_strategy);
    }

    function _setAaveStrategy(address _strategy) internal {
        require(_strategy != address(0), Errors.ZERO_ADDRESS);
        IERC20Upgradeable uToken = IERC20Upgradeable(underlyingToken);
        IStrategy strategy = IStrategy(_strategy);
        if (_aaveStrategy != address(0)) {
            uToken.safeApprove(_aaveStrategy, 0);
            IERC20Upgradeable(_aaveShareTokens).safeApprove(_aaveStrategy, 0);
        }
        address _aaveUnderlyingToken = strategy.getUnderlyingToken();
        require(
            _aaveUnderlyingToken == address(underlyingToken),
            Errors.UNDERLYINGTOKEN_IS_NOT_COMPATIBLY
        );

        _aaveShareTokens = strategy.shareToken();
        IERC20Upgradeable asToken = IERC20Upgradeable(_aaveShareTokens);
        _aaveStrategy = _strategy;
        uToken.safeApprove(_strategy, 0);
        uToken.safeApprove(_strategy, type(uint256).max);
        asToken.safeApprove(_strategy, 0);
        asToken.safeApprove(_strategy, type(uint256).max);
        emit SetStrategy(_strategy, _aaveShareTokens);
    }

    // TODO: this empty ????
    function _authorizeUpgrade(address)
        internal
        override
        onlyRole(_ADMIN_ROLE)
    {}

    function confirmTransferOwnership(address strategy)
        external
        onlyRole(_GOVERNANCE_ROLE)
    {
        IIporOwnableUpgradeable(strategy).confirmTransferOwnership();
    }

    // Find highest apy strategy to deposit underlying asset
    function getMaxApyStrategy() public view returns (IStrategy depositAsset) {
        IStrategy aave = IStrategy(_aaveStrategy);
        IStrategy compound = IStrategy(_compoundStrategy);
        // TODO: check if use the same number of decimals
        if (aave.getApy() < compound.getApy()) {
            return compound;
        }
        return aave;
    }

    // TODO: totalStrategiesBalance =>  totalBalance
    function totalStrategiesBalance() public view returns (uint256) {
        return
            IStrategy(_aaveStrategy).balanceOf() +
            IStrategy(_compoundStrategy).balanceOf();
    }

    /**
     * @dev to deposit asset in higher apy strategy.
     * @notice only owner can deposit.
     * @param _amount amount to deposit.
     */
    //  TODO: ADD tests for _amount = 0
    //  TODO: return balanse before deposit
    function deposit(uint256 _amount) external onlyRole(_DEPOSIT_ROLE) {
        require(_amount != 0, Errors.UINT_SHOULD_BE_GRATER_THEN_ZERO);
        IStrategy strategy = getMaxApyStrategy();

        IIvToken token = IIvToken(ivToken);
        uint256 _totalAsset = totalStrategiesBalance();
        uint256 _tokenAmount = token.totalSupply();
        uint256 _exchangeRate = _calculateExchangeRate(
            _totalAsset,
            _tokenAmount
        );
        _deposit(strategy, _amount);
        emit Deposit(address(strategy), _amount);

        token.mint(msg.sender, AmMath.division(_amount * 1e18, _exchangeRate));
    }

    /**
     * @dev to withdraw asset from current strategy.
     * @notice only owner can withdraw.
     * @param _tokens amount of shares want to withdraw.
            Shares means aTokens, cTokens
    */
    // TODO: return amount of withdraw,
    // TODO: balanse before withdraw and aftre
    function withdraw(uint256 _tokens) external onlyRole(_WITHDRAW_ROLE) {
        require(_tokens != 0, Errors.UINT_SHOULD_BE_GRATER_THEN_ZERO);
        IIvToken token = IIvToken(ivToken);

        require(
            token.balanceOf(msg.sender) >= _tokens,
            Errors.UINT_SHOULD_BE_GRATER_THEN_ZERO
        );

        IStrategy maxApyStrategy = getMaxApyStrategy();

        uint256 _totalAsset = totalStrategiesBalance();
        uint256 _tokenAmount = token.totalSupply();
        uint256 _exchangeRateRoundDown = _calculateExchangeRateRoundDown(
            _totalAsset,
            _tokenAmount
        );
        uint256 _exchangeRate = _calculateExchangeRate(
            _totalAsset,
            _tokenAmount
        );
        uint256 amount = AmMath.division(
            _tokens * _exchangeRateRoundDown,
            1e18
        );

        IStrategy aaveStrategy = IStrategy(_aaveStrategy);
        uint256 aaveBalance = aaveStrategy.balanceOf();
        IStrategy compoundStrategy = IStrategy(_compoundStrategy);
        uint256 compoundBalance = compoundStrategy.balanceOf();

        if (
            address(maxApyStrategy) == _compoundStrategy &&
            amount <= aaveBalance
        ) {
            token.burn(msg.sender, _tokens);
            _withdraw(address(aaveStrategy), amount, true);
            return;
        } else if (amount <= compoundBalance) {
            token.burn(msg.sender, _tokens);
            _withdraw(address(compoundStrategy), amount, true);
            return;
        }
        if (
            address(maxApyStrategy) == _aaveStrategy &&
            amount <= compoundBalance
        ) {
            token.burn(msg.sender, _tokens);
            _withdraw(address(compoundStrategy), amount, true);
            return;
        } else if (amount <= aaveBalance) {
            token.burn(msg.sender, _tokens);
            _withdraw(address(aaveStrategy), amount, true);
            return;
        }
        if (aaveBalance < compoundBalance) {
            uint256 tokensToBurn = AmMath.division(
                compoundBalance * 1e18,
                _exchangeRate
            );
            token.burn(msg.sender, tokensToBurn);
            _withdraw(address(compoundStrategy), compoundBalance, true);
        } else {
            // TODO: Cannot do this in this way, take into account asset decimals
            // TODO: Add tests for DAI(18 decimals) and for USDT (6 decimals)
            uint256 tokensToBurn = AmMath.division(
                aaveBalance * 1e18,
                _exchangeRate
            );
            token.burn(msg.sender, tokensToBurn);
            _withdraw(address(aaveStrategy), aaveBalance, true);
        }
    }

    function withdrawAll() external onlyRole(_WITHDRAW_ROLE) {
        _withdraw(_aaveStrategy, IStrategy(_aaveStrategy).balanceOf(), false);
        _withdraw(
            _compoundStrategy,
            IStrategy(_compoundStrategy).balanceOf(),
            false
        );
        IERC20Upgradeable uToken = IERC20Upgradeable(underlyingToken);
        uint256 _balance = uToken.balanceOf(address(this));
        uToken.safeTransfer(msg.sender, _balance);
    }

    /**
     * @dev to migrate all asset from current strategy to another higher apy strategy.
     * @notice only owner can migrate.
     */
    function migrateAssetInMaxApyStrategy()
        external
        onlyRole(_GOVERNANCE_ROLE)
    {
        IStrategy maxApyStrategy = getMaxApyStrategy();
        address from;
        if (address(maxApyStrategy) == _aaveStrategy) {
            from = _compoundStrategy;
            uint256 _shares = IERC20Upgradeable(_compoundShareTokens).balanceOf(
                from
            );
            require(_shares > 0, Errors.UINT_SHOULD_BE_GRATER_THEN_ZERO);
            IStrategy(_compoundStrategy).withdraw(_shares);
        } else {
            from = _aaveStrategy;
            uint256 _shares = IERC20Upgradeable(_aaveShareTokens).balanceOf(
                from
            );
            require(_shares > 0, Errors.UINT_SHOULD_BE_GRATER_THEN_ZERO);
            IStrategy(_aaveStrategy).withdraw(_shares);
        }
        uint256 _amount = IERC20Upgradeable(underlyingToken).balanceOf(
            address(this)
        );
        _deposit(maxApyStrategy, _amount);
        emit MigrateAsset(from, address(maxApyStrategy), _amount);
    }

    /**
     * @dev to withdraw asset from current strategy.
     * @notice internal method.
     * @param _strategy strategy from amount to withdraw
     * @param _amount _amount is interest bearing token like aDAI, cDAI etc.
     */
    function _withdraw(
        address _strategy,
        uint256 _amount,
        bool transfer
    ) internal {
        if (_amount != 0) {
            IStrategy(_strategy).withdraw(_amount);
            IERC20Upgradeable utoken = IERC20Upgradeable(underlyingToken);
            uint256 _balance = utoken.balanceOf(address(this));
            if (transfer) {
                utoken.safeTransfer(msg.sender, _balance);
            }
            emit Withdraw(_strategy, _amount);
        }
    }

    /**
     * @dev claim Gov token from current strategy.
     * @notice only owner can claim.
     * @param _account send claimed gove token to _account
     */
    // TODO: Consider to convert _account variable in contract and change fincton to no parameters
    function aaveDoClaim(address _account)
        external
        payable
        onlyRole(_CLAIM_ROLE)
    {
        _doClaim(_account, _aaveStrategy);
    }

    // TODO: Consider to convert _account variable in contract and change fincton to no parameters
    function compoundDoClaim(address _account)
        external
        payable
        onlyRole(_CLAIM_ROLE)
    {
        _doClaim(_account, _compoundStrategy);
    }

    function _doClaim(address _account, address strategyAddress) internal {
        require(_account != address(0), Errors.ZERO_ADDRESS);
        IStrategy strategy = IStrategy(strategyAddress);
        address[] memory assets = new address[](1);
        assets[0] = strategy.shareToken();
        strategy.doClaim(_account, assets);
        emit DoClaim(strategyAddress, _account);
    }

    function aaveBeforeClaim(address[] memory assets, uint256 _amount)
        external
        payable
        onlyRole(_CLAIM_ROLE)
    {
        IStrategy(_aaveStrategy).beforeClaim(assets, _amount);
    }

    /**  Internal Methods */
    /**
     * @dev to deposit asset in current strategy.
     * @notice internal method.
     * @param _strategy strategy from amount to deposit
     * @param _amount _amount is underlyingToken token like DAI.
     */
    function _deposit(IStrategy _strategy, uint256 _amount) internal {
        IERC20Upgradeable(underlyingToken).safeTransferFrom(
            msg.sender,
            address(this),
            _amount
        );
        _strategy.deposit(_amount);
    }
}

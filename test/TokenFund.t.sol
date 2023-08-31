// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "../src/TokenFund.sol";
import "openzeppelin/token/ERC20/IERC20.sol";
import "openzeppelin/token/ERC20/utils/SafeERC20.sol";
import "../src/MyGovernor.sol";
import "../src/TimeLock.sol";

contract TokenFundTest is Test {
    uint256 public constant STARTING_MAINNET_BLOCK = 18032971;

    TokenFund public tokenFund;
    MyGovernor public myGovernor;
    TimeLock public timeLock;

    address public constant USDT = 0xdAC17F958D2ee523a2206206994597C13D831ec7;
    address public constant WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    address public constant USDC = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;
    address public constant LINK = 0x514910771AF9Ca656af840dff83E8264EcF986CA;

    address public constant UNISWAP_V2_ROUTER =
        0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;

    address public constant SUSHISWAP_ROUTER =
        0xd9e1cE17f2641f24aE83637ab66a2cca9C378B9F;

    uint16 public constant PROFIT_FEE = 1000;

    uint256 public constant TIMELOCK_MIN_DELAY = 1 weeks; /// @dev minDelay arg for TimeLock contract

    /// @dev variables for the MyGovernor contract
    uint256 public constant VOTING_DELAY = 7200;
    uint256 public constant VOTING_PERIOD = 50400;
    uint256 public constant QUORUM_FRACTION = 50;

    address[] public emptyArray; /// @dev for utility reasons

    function setUp() public {
        timeLock = new TimeLock(TIMELOCK_MIN_DELAY, emptyArray, emptyArray);

        bytes32 proposerRole = timeLock.PROPOSER_ROLE();
        bytes32 executorRole = timeLock.EXECUTOR_ROLE();
        bytes32 timelockAdminRole = timeLock.TIMELOCK_ADMIN_ROLE();

        tokenFund = new TokenFund(
            address(timeLock),
            PROFIT_FEE,
            USDC,
            USDT,
            WETH,
            LINK,
            UNISWAP_V2_ROUTER,
            SUSHISWAP_ROUTER
        );

        myGovernor = new MyGovernor(
            tokenFund,
            timeLock,
            VOTING_DELAY,
            VOTING_PERIOD,
            QUORUM_FRACTION
        );

        timeLock.grantRole(proposerRole, address(myGovernor));
        timeLock.grantRole(executorRole, address(0));
        timeLock.revokeRole(timelockAdminRole, address(this));

        vm.prank(address(timeLock));
        tokenFund.acceptOwnership();
    }
}

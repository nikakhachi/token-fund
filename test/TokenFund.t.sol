// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "../src/TokenFund.sol";
import "openzeppelin/token/ERC20/IERC20.sol";
import "openzeppelin/token/ERC20/utils/SafeERC20.sol";
import "../src/MyGovernor.sol";
import "../src/TimeLock.sol";

contract TokenFundTest is Test {
    using SafeERC20 for IERC20;

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

    function testDeployment() public {
        assertEq(tokenFund.profitFee(), PROFIT_FEE);
        assertEq(address(tokenFund.usdc()), USDC);
        assertEq(address(tokenFund.usdt()), USDT);
        assertEq(address(tokenFund.weth()), WETH);
        assertEq(address(tokenFund.link()), LINK);
        assertEq(address(tokenFund.uniswapV2Router()), UNISWAP_V2_ROUTER);
        assertEq(address(tokenFund.sushiswapRouter()), SUSHISWAP_ROUTER);
        assertEq(IERC20(LINK).balanceOf(address(tokenFund)), 0);
        assertEq(IERC20(WETH).balanceOf(address(tokenFund)), 0);
        assertEq(IERC20(USDC).balanceOf(address(tokenFund)), 0);
        assertEq(IERC20(USDT).balanceOf(address(tokenFund)), 0);
    }

    function testDepositUSDC(uint64 amount) public {
        vm.assume(amount > 1000000); // More than 1$USDC
        deal(USDC, address(this), amount);

        IERC20(USDC).approve(address(tokenFund), amount);
        tokenFund.depositUSDC(amount);

        assertEq(tokenFund.initialUSDCDeposits(address(this)), amount);
        assertEq(tokenFund.totalSupply(), tokenFund.balanceOf(address(this)));
        assertEq(IERC20(USDC).balanceOf(address(this)), 0);
        assertGt(IERC20(LINK).balanceOf(address(tokenFund)), 0);
        assertGt(IERC20(WETH).balanceOf(address(tokenFund)), 0);
    }

    function testDepositUSDT(uint64 amount) public {
        vm.assume(amount > 1000000); // More than 1$USDC
        deal(USDT, address(this), amount);

        IERC20(USDT).safeApprove(address(tokenFund), amount);
        tokenFund.depositUSDT(amount);

        assertEq(tokenFund.initialUSDTDeposits(address(this)), amount);
        assertEq(tokenFund.totalSupply(), tokenFund.balanceOf(address(this)));
        assertEq(IERC20(USDT).balanceOf(address(this)), 0);
        assertGt(IERC20(LINK).balanceOf(address(tokenFund)), 0);
        assertGt(IERC20(WETH).balanceOf(address(tokenFund)), 0);
    }
}

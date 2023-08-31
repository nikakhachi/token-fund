// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "../src/TokenFund.sol";
import "openzeppelin/token/ERC20/IERC20.sol";
import "openzeppelin/token/ERC20/utils/SafeERC20.sol";

contract TokenFundTest is Test {
    using SafeERC20 for IERC20;

    TokenFund public tokenFund;

    address public constant USDT = 0xdAC17F958D2ee523a2206206994597C13D831ec7;
    address public constant WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    address public constant USDC = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;
    address public constant LINK = 0x514910771AF9Ca656af840dff83E8264EcF986CA;

    address public constant UNISWAP_V2_ROUTER =
        0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;

    address public constant SUSHISWAP_ROUTER =
        0xd9e1cE17f2641f24aE83637ab66a2cca9C378B9F;

    function setUp() public {
        tokenFund = new TokenFund(
            USDC,
            USDT,
            WETH,
            LINK,
            UNISWAP_V2_ROUTER,
            SUSHISWAP_ROUTER
        );
    }

    function testDepositUSDC() public {
        console.log("------");
        uint amount = 1000000000; /// @dev 1000 $USDC
        deal(USDC, address(this), amount);
        IERC20(USDC).approve(address(tokenFund), amount);
        tokenFund.depositUSDC(amount);
        console.log("------");
    }

    function testDepositUSDT() public {
        console.log("------");
        uint amount = 1000000000; /// @dev 1000 $USDT
        deal(USDT, address(this), amount);
        IERC20(USDT).safeApprove(address(tokenFund), amount);
        tokenFund.depositUSDT(amount);
        console.log("------");
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "./TokenFund.t.sol";

contract DeploymentTest is TokenFundTest {
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
}

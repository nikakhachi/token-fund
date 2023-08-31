// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "./TokenFund.t.sol";

contract DepositTest is TokenFundTest {
    using SafeERC20 for IERC20;

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

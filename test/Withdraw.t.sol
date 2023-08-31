// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import "./TokenFund.t.sol";

/**
 * @title WithdrawTest Contract
 * @author Nika Khachiashvili
 * @dev Contract for testing USDC and USDT withdraw functionalities
 */
contract WithdrawTest is TokenFundTest {
    using SafeERC20 for IERC20;

    event ProfitMade(
        address indexed stableCoin,
        uint256 indexed amount,
        uint256 indexed timestamp
    );

    /// @dev test withdrawing of USDC as the only provider without a profir
    function testWithdrawUSDCAsOnlyProviderWithoutProfit(uint64 amount) public {
        vm.assume(amount > 1000000); // More than 1$USDC

        _deposit(USDC, address(this), amount);

        assertEq(IERC20(USDC).balanceOf(address(this)), 0);

        tokenFund.withdrawUSDC();

        assertEq(tokenFund.balanceOf(address(this)), 0);
        assertEq(tokenFund.initialUSDCDeposits(address(this)), 0);
        assertGe(IERC20(USDC).balanceOf(address(this)), 0);

        assertEq(IERC20(WETH).balanceOf(address(this)), 0);
        assertEq(IERC20(LINK).balanceOf(address(this)), 0);
    }

    /// @dev test withdrawing of USDT as the only provider without a profir
    function testWithdrawUSDTAsOnlyProviderWithoutProfit(uint64 amount) public {
        vm.assume(amount > 1000000); // More than 1$USDT

        _deposit(USDT, address(this), amount);

        assertEq(IERC20(USDT).balanceOf(address(this)), 0);

        tokenFund.withdrawUSDT();

        assertEq(tokenFund.balanceOf(address(this)), 0);
        assertEq(tokenFund.initialUSDTDeposits(address(this)), 0);
        assertGe(IERC20(USDT).balanceOf(address(this)), 0);

        assertEq(IERC20(WETH).balanceOf(address(this)), 0);
        assertEq(IERC20(LINK).balanceOf(address(this)), 0);
    }

    /// @dev test withdrawing of USDC as the only provider with a profit
    function testWithdrawUSDCAsOnlyProviderWithProfit(uint64 amount) public {
        vm.assume(amount > 1000000); // More than 1$USDC

        _deposit(USDC, address(this), amount);

        _contractMakingProfit();

        vm.expectEmit(true, false, true, false);
        emit ProfitMade(address(USDC), 0, block.timestamp);
        tokenFund.withdrawUSDC();

        assertEq(tokenFund.balanceOf(address(this)), 0);
        assertEq(tokenFund.initialUSDCDeposits(address(this)), 0);

        assertGe(IERC20(USDC).balanceOf(address(tokenFund)), 0);
        assertGe(IERC20(USDC).balanceOf(address(this)), amount);
        assertEq(IERC20(WETH).balanceOf(address(this)), 0);
        assertEq(IERC20(LINK).balanceOf(address(this)), 0);
    }

    /// @dev test withdrawing of USDT as the only provider with a profit
    function testWithdrawUSDTAsOnlyProviderWithProfit(uint64 amount) public {
        vm.assume(amount > 1000000); // More than 1$USDT

        _deposit(USDT, address(this), amount);

        _contractMakingProfit();

        vm.expectEmit(true, false, true, false);
        emit ProfitMade(address(USDT), 0, block.timestamp);
        tokenFund.withdrawUSDT();

        assertEq(tokenFund.balanceOf(address(this)), 0);
        assertEq(tokenFund.initialUSDTDeposits(address(this)), 0);

        assertGe(IERC20(USDT).balanceOf(address(tokenFund)), 0);
        assertGe(IERC20(USDT).balanceOf(address(this)), amount);
        assertEq(IERC20(WETH).balanceOf(address(this)), 0);
        assertEq(IERC20(LINK).balanceOf(address(this)), 0);
    }

    /// @dev test withdrawing of USDC as the only provider with a profit
    function testMultipleWithdrawUSDCWithProfitFlow(
        uint64 amount1,
        uint64 amount2
    ) public {
        vm.assume(amount1 > 1000000); // More than 1$USDC
        vm.assume(amount2 > 1000000); // More than 1$USDC

        /// @dev I'm doing like this instead of callind the helper function because safeApprove in the _deposit doesn't
        /// @dev work for vm.prank()
        vm.prank(address(1));
        deal(USDC, address(1), amount1);
        vm.prank(address(1));
        IERC20(USDC).approve(address(tokenFund), amount1);
        vm.prank(address(1));
        tokenFund.depositUSDC(amount1);

        deal(USDC, address(this), amount2);
        IERC20(USDC).approve(address(tokenFund), amount2);
        tokenFund.depositUSDC(amount2);

        _contractMakingProfit();

        tokenFund.withdrawUSDC();

        assertEq(tokenFund.balanceOf(address(this)), 0);
        assertEq(tokenFund.initialUSDCDeposits(address(this)), 0);

        assertGe(IERC20(WETH).balanceOf(address(tokenFund)), 0);
        assertGe(IERC20(LINK).balanceOf(address(tokenFund)), 0);

        vm.prank(address(1));
        tokenFund.withdrawUSDC();

        assertEq(tokenFund.balanceOf(address(1)), 0);
        assertEq(tokenFund.initialUSDCDeposits(address(1)), 0);

        assertEq(IERC20(WETH).balanceOf(address(tokenFund)), 0);
        assertEq(IERC20(LINK).balanceOf(address(tokenFund)), 0);
    }

    function _deposit(
        address _token,
        address _address,
        uint64 amount
    ) internal {
        vm.prank(_address);
        deal(_token, _address, amount);
        vm.prank(_address);
        IERC20(_token).safeApprove(address(tokenFund), amount);
        if (_token == USDC) {
            vm.prank(_address);
            tokenFund.depositUSDC(amount);
        } else {
            vm.prank(_address);
            tokenFund.depositUSDT(amount);
        }
    }

    function _contractMakingProfit() internal {
        uint wethBalance = IERC20(WETH).balanceOf(address(tokenFund));
        uint linkBalance = IERC20(LINK).balanceOf(address(tokenFund));
        deal(WETH, address(tokenFund), (wethBalance * 15) / 10);
        deal(LINK, address(tokenFund), (linkBalance * 15) / 10);
    }
}

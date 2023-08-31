// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "./TokenFund.t.sol";

/**
 * @title DepositTest Contract
 * @author Nika Khachiashvili
 * @dev Contract for testing USDC and USDT deposit functionalities
 */
contract DepositTest is TokenFundTest {
    using SafeERC20 for IERC20;

    /// @dev test the USDC deposit
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

    /// @dev test the USDT deposit
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

    /// @dev test the zero value USDC deposit
    function testDepositZeroUSDC() public {
        vm.expectRevert(bytes("UniswapV2Library: INSUFFICIENT_INPUT_AMOUNT"));
        tokenFund.depositUSDC(0);
    }

    /// @dev test the zero value USDT deposit
    function testDepositZeroUSDT() public {
        vm.expectRevert(bytes("UniswapV2Library: INSUFFICIENT_INPUT_AMOUNT"));
        tokenFund.depositUSDT(0);
    }

    /// @dev test the invalid USDC deposit
    function testDepositInvalidStableCoinAsUSDC(uint64 amount) public {
        vm.assume(amount > 10 ** 18); // More than 1$DAI

        address DAI = 0x6B175474E89094C44Da98b954EedeAC495271d0F;

        deal(DAI, address(this), amount);
        IERC20(DAI).safeApprove(address(tokenFund), amount);

        vm.expectRevert();
        tokenFund.depositUSDC(amount);
    }

    /// @dev test the invalid USDT deposit
    function testDepositInvalidStableCoinAsUSDT(uint64 amount) public {
        vm.assume(amount > 10 ** 18); // More than 1$DAI

        address DAI = 0x6B175474E89094C44Da98b954EedeAC495271d0F;

        deal(DAI, address(this), amount);
        IERC20(DAI).safeApprove(address(tokenFund), amount);

        vm.expectRevert();
        tokenFund.depositUSDT(amount);
    }

    /// @dev test the 2 concurrent USDC deposits
    function testSecondUSDCDeposit(uint64 amount) public {
        vm.assume(amount > 1000000); // More than 1$USDC
        deal(USDC, address(this), amount);

        IERC20(USDC).approve(address(tokenFund), amount);
        tokenFund.depositUSDC(amount);

        uint initialShares = tokenFund.balanceOf(address(this));
        uint initialWethBalanceOfFund = IERC20(WETH).balanceOf(
            address(tokenFund)
        );
        uint initialLinkBalanceOfFund = IERC20(LINK).balanceOf(
            address(tokenFund)
        );

        deal(USDC, address(this), amount);
        IERC20(USDC).approve(address(tokenFund), amount);
        tokenFund.depositUSDC(amount);

        assertGt(tokenFund.balanceOf(address(this)), initialShares);
        assertGt(
            IERC20(WETH).balanceOf(address(tokenFund)),
            initialWethBalanceOfFund
        );
        assertGt(
            IERC20(LINK).balanceOf(address(tokenFund)),
            initialLinkBalanceOfFund
        );
    }

    /// @dev test the 2 concurrent USDT deposits
    function testSecondUSDTDeposit(uint64 amount) public {
        vm.assume(amount > 1000000); // More than 1$USDT
        deal(USDT, address(this), amount);

        IERC20(USDT).safeApprove(address(tokenFund), amount);
        tokenFund.depositUSDT(amount);

        uint initialShares = tokenFund.balanceOf(address(this));
        uint initialWethBalanceOfFund = IERC20(WETH).balanceOf(
            address(tokenFund)
        );
        uint initialLinkBalanceOfFund = IERC20(LINK).balanceOf(
            address(tokenFund)
        );

        deal(USDT, address(this), amount);
        IERC20(USDT).safeApprove(address(tokenFund), amount);
        tokenFund.depositUSDT(amount);

        assertGt(tokenFund.balanceOf(address(this)), initialShares);
        assertGt(
            IERC20(WETH).balanceOf(address(tokenFund)),
            initialWethBalanceOfFund
        );
        assertGt(
            IERC20(LINK).balanceOf(address(tokenFund)),
            initialLinkBalanceOfFund
        );
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "./TokenFund.t.sol";

contract GovernanceTest is TokenFundTest {
    /// @dev variables for proposing proposals
    address[] public targets;
    uint256[] public values;
    bytes[] public calldatas;
    string public description;

    function testProposal() public {
        assertEq(tokenFund.hasProposalExecuted(), false);
        uint256 amount = 10 * 10 ** 6;
        address[] memory stableProviders = new address[](3);
        stableProviders[0] = address(1);
        stableProviders[1] = address(2);
        stableProviders[2] = address(3);

        for (uint i; i < stableProviders.length; i++) {
            address provider = stableProviders[i];
            deal(USDC, provider, amount);
            vm.prank(provider);
            IERC20(USDC).approve(address(tokenFund), amount);
            vm.prank(provider);
            tokenFund.depositUSDC(amount);
            vm.prank(provider);
            tokenFund.delegate(provider);
        }

        targets = [address(tokenFund)];
        values = [0];
        calldatas = [abi.encodeWithSignature("timeLockFunction()")];

        uint256 proposalId = myGovernor.propose(
            targets,
            values,
            calldatas,
            description
        );

        vm.roll(STARTING_MAINNET_BLOCK + VOTING_DELAY + 2);

        vm.prank(stableProviders[0]);
        myGovernor.castVote(proposalId, 1);

        vm.prank(stableProviders[1]);
        myGovernor.castVote(proposalId, 0);

        vm.prank(stableProviders[2]);
        myGovernor.castVote(proposalId, 1);

        vm.roll(STARTING_MAINNET_BLOCK + VOTING_DELAY + VOTING_PERIOD + 3);

        myGovernor.queue(
            targets,
            values,
            calldatas,
            keccak256(bytes(description))
        );

        skip(TIMELOCK_MIN_DELAY);

        myGovernor.execute(
            targets,
            values,
            calldatas,
            keccak256(bytes(description))
        );

        assertEq(tokenFund.hasProposalExecuted(), true);
    }
}

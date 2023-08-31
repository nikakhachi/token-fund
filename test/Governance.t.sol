// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import "./TokenFund.t.sol";

/**
 * @title GovernanceTest Contract
 * @author Nika Khachiashvili
 * @dev Contract for testing governance functionalities
 */
contract GovernanceTest is TokenFundTest {
    /// @dev variables for proposing proposals
    address[] public targets;
    uint256[] public values;
    bytes[] public calldatas;
    string public description;

    /// @dev Addresses that will have Token Fund Shares and have power in voting
    address[3] public stableProviders = [address(1), address(2), address(3)];

    /// @dev Testing the flow of successful proposal
    function testSuccesfullProposal() public {
        assertEq(tokenFund.hasProposalExecuted(), false);

        uint256 amount = 10 * 10 ** 6;

        _beforeEach(amount, amount, amount);
        uint256 proposalId = _proposeAndRoll();
        _voteAndRoll(proposalId, 1, 0, 1);

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

    /// @dev Testing the flow of not succesfull proposal
    function testNotSuccesfullProposal() public {
        /// @dev This kind of value distribution makes sure providers get somewhere nearly same amount of fund tokens
        /// @dev So when 2 votes negative, the proposal will fail
        _beforeEach(6 * 10 ** 6, 35 * 10 ** 6, 50 * 10 ** 6);
        uint256 proposalId = _proposeAndRoll();
        _voteAndRoll(proposalId, 1, 0, 0);
        vm.expectRevert(bytes("Governor: proposal not successful"));
        myGovernor.queue(
            targets,
            values,
            calldatas,
            keccak256(bytes(description))
        );
    }

    /// @dev Testing the flow of not active proposal
    function testNotActiveProposal() public {
        uint256 amount = 10 * 10 ** 6;

        _beforeEach(amount, amount, amount);
        uint proposalId = myGovernor.propose(
            targets,
            values,
            calldatas,
            description
        );

        vm.expectRevert(bytes("Governor: vote not currently active"));
        myGovernor.castVote(proposalId, 1);
    }

    /// @dev Testing the flow of non ready proposal operation
    function testNonReadyProposalOperation() public {
        uint256 amount = 10 * 10 ** 6;

        _beforeEach(amount, amount, amount);
        uint256 proposalId = _proposeAndRoll();
        _voteAndRoll(proposalId, 1, 0, 1);

        myGovernor.queue(
            targets,
            values,
            calldatas,
            keccak256(bytes(description))
        );

        vm.expectRevert(bytes("TimelockController: operation is not ready"));
        myGovernor.execute(
            targets,
            values,
            calldatas,
            keccak256(bytes(description))
        );
    }

    function testCallTimelockFunctionFromEOA() public {
        vm.expectRevert();
        tokenFund.timeLockFunction();
    }

    /// @dev Helper and reusable functions to make tests easier

    function _beforeEach(uint256 usdt1, uint256 usdt2, uint256 usdt3) internal {
        targets = [address(tokenFund)];
        values = [0];
        calldatas = [abi.encodeWithSignature("timeLockFunction()")];

        for (uint i; i < stableProviders.length; i++) {
            address provider = stableProviders[i];
            uint amount = i == 0 ? usdt1 : i == 1 ? usdt2 : usdt3;
            deal(USDC, provider, amount);
            vm.prank(provider);
            IERC20(USDC).approve(address(tokenFund), amount);
            vm.prank(provider);
            tokenFund.depositUSDC(amount);
            vm.prank(provider);
            tokenFund.delegate(provider);
        }
    }

    function _proposeAndRoll() internal returns (uint256 proposalId) {
        proposalId = myGovernor.propose(
            targets,
            values,
            calldatas,
            description
        );

        vm.roll(STARTING_MAINNET_BLOCK + VOTING_DELAY + 2);
    }

    function _voteAndRoll(
        uint256 proposalId,
        uint8 vote1,
        uint8 vote2,
        uint8 vote3
    ) internal {
        for (uint i; i < stableProviders.length; i++) {
            vm.prank(stableProviders[i]);
            uint8 vote = i == 0 ? vote1 : i == 1 ? vote2 : vote3;
            myGovernor.castVote(proposalId, vote);
        }
        vm.roll(STARTING_MAINNET_BLOCK + VOTING_DELAY + VOTING_PERIOD + 3);
    }
}

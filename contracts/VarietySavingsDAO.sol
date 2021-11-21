// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0;

contract VarietySavingsDAO {
    struct VotingRound {
        uint32 roundNumber;
        address[] votingUsers;
        mapping(address => uint32) voteCount;
        // TODO: add start date, end date
        // TODO: bring tokens into the struct?
    }
    mapping(address => bool) addressVotingEligibity;
    // TODO: keep symbol/name of tokens somewhere
    address[] availableTokens;

    VotingRound public votingRound;

    modifier onlyEligible() {
        require(addressVotingEligibity[msg.sender], 'You are not eligible to vote');
        _;
    }

    // TODO: make sure user can only vote once
    function voteForTokens(address[] memory _chosenTokens) public onlyEligible {
        uint8 numberOfVotedTokens = uint8(_chosenTokens.length);
        for (uint8 i = 0; i < numberOfVotedTokens; i++) {
            address currentToken = _chosenTokens[i];
            votingRound.voteCount[currentToken] += 1;
        }
    }

    // TODO: Only callable internally and triggered by savings contract
    function setAddressEligibility(address user, bool eligibility) public {
        addressVotingEligibity[user] = eligibility;
    }

    function newVotingRound() public {
        // TODO: distribute rewards
        uint64 numberPriorRoundVoters = uint64(votingRound.votingUsers.length);
        for (uint64 i = 0; i < numberPriorRoundVoters; i++) {
            address user = votingRound.votingUsers[i];
            // reset user's vote
            votingRound.voteCount[user] = 0;
        }
        // set votings array to zero
        delete votingRound.votingUsers;
        votingRound.roundNumber += 1;
    }

    // TODO: give users the ability to vote for new tokens on the next round

    // TODO: change tokens on the next round if necessary

    // TODO: this contract should custody variety tokens?
}

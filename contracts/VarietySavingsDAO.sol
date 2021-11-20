// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0;

contract VarietySavingsDAO {
    struct VotingRound {
        uint32 roundNumber;
        address[] votingUsers;
        mapping(address => uint32) voteCount;
    }
    mapping(address => bool) addressVotingEligibity;
    address[] availableTokens;

    VotingRound public votingRound;
    
    // make sure user can only vote once
    function voteForTokens(address[] memory _chosenTokens) public {
        uint8 numberOfVotedTokens = uint8(_chosenTokens.length);
        for (uint8 i = 0; i < numberOfVotedTokens; i++) {
            address currentToken = _chosenTokens[i];
            votingRound.voteCount[currentToken] += 1;
        }
    }

    function setAddressEligibility(address user, bool eligibility) public {
        addressVotingEligibity[user] = eligibility;
    }

    function newVotingRound() public {
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
}

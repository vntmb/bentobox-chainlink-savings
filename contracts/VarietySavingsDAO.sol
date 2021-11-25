// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0;

interface IERC20 {
    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}

// TODO: add emits to the contract
contract VarietySavingsDAO {
    struct VotingRound {
        uint32 roundNumber;
        address[] votingUsers;
        mapping(address => uint32) tokenVoteTotal;
        mapping(address => bool) userVoted;
        // TODO: add start date, end date
        // TODO: bring tokens into the struct?
    }
    mapping(address => bool) addressVotingEligibity;
    // TODO: keep symbol/name of tokens somewhere
    mapping(address => bool) tokenAvailableForVoting;
    address[] public availableTokens = [
        0x4997910AC59004383561Ac7D6d8a65721Fa2A663,
        0xdD5C42F833b81853F2B1e5E8b76B763bff7C1c37,
        0x898Ed56CbF0E4910b04080863c9f31792fc1a33C,
        0x224F0deDD8237d3Bf72934217CF6F433a4ed9F2d
    ];

    uint8 TRANSFER_TOKEN_AMOUNT = 10;

    VotingRound public votingRound;

    address public owner;

    address public mainSavingsContract;

    constructor() {
        owner = msg.sender; /// Added owner to set VarietySavings contract address
        uint8 numberOfAvailableTokens = uint8(availableTokens.length);
        // to begin with, add some choice tokens to votable pool
        for (uint8 i = 0; i < numberOfAvailableTokens; i++) {
            tokenAvailableForVoting[availableTokens[i]] = true;
        }
    }

    modifier onlyMain(address caller) {
        require(caller == mainSavingsContract, "Unauthorized");
        _;
    }

    modifier onlyOwner(address caller) {
        require(caller == owner, "Unauthorized");
        _;
    }

    function setMainSavingsContract(address contractAddress)
        public
        onlyOwner(msg.sender)
    {
        mainSavingsContract = contractAddress;
    }

    // TODO: add functionality to remove voter eligibility
    function addEligibleVoter(address user) external onlyMain(msg.sender) {
        // TODO: check if user is already eligible, if yes, ignore
        setAddressEligibility(user, true);
    }

    function isTokenAvailableForVoting(address _token)
        public
        view
        returns (bool)
    {
        return tokenAvailableForVoting[_token];
    }

    modifier walletEligibleToVote() {
        require(
            addressVotingEligibity[msg.sender],
            "You are not eligible to vote"
        );
        _;
    }

    modifier walletNotVotedYet() {
        require(!votingRound.userVoted[msg.sender], "You can only vote once");
        _;
    }

    function voteForTokens(address[] memory _chosenTokens)
        public
        walletEligibleToVote
        walletNotVotedYet
    {
        uint8 numberOfVotedTokens = uint8(_chosenTokens.length);
        for (uint8 i = 0; i < numberOfVotedTokens; i++) {
            address currentToken = _chosenTokens[i];
            // only vote for allowed tokens
            if (tokenAvailableForVoting[currentToken]) {
                votingRound.tokenVoteTotal[currentToken] += 1;
            }
        }
        // register that the user has voted
        votingRound.userVoted[msg.sender] = true;
    }

    // TODO: Only callable internally and triggered by savings contract
    function setAddressEligibility(address user, bool eligibility) private {
        addressVotingEligibity[user] = eligibility;
    }

    // TODO: use safe transfer
    function distributeTokens(address user) private {
        uint8 numberOfTokens = uint8(availableTokens.length);
        // TODO: distribute only the voted for tokens
        for (uint8 i = 0; i < numberOfTokens; i++) {
            IERC20 token = IERC20(availableTokens[i]);
            token.transfer(user, TRANSFER_TOKEN_AMOUNT);
        }
    }

    // function newVotingRound() public {
    //     uint64 numberPriorRoundVoters = uint64(votingRound.votingUsers.length);
    //     for (uint64 i = 0; i < numberPriorRoundVoters; i++) {
    //         address user = votingRound.votingUsers[i];
    //         // distribute rewards
    //         distributeTokens(user);
    //         // reset user's vote
    //         votingRound.tokenVoteTotal[user] = 0;
    //     }
    //     // set votings array to zero
    //     delete votingRound.votingUsers;
    //     votingRound.roundNumber += 1;
    // }

    function deleteUsersVotingRoundInfo(address _user) private {
        votingRound.userVoted[_user] = false;
    }

    function deleteTokenVotesForRound() private {
        uint8 numberOfTokens = uint8(availableTokens.length);
        // TODO: distribute only the voted for tokens
        for (uint8 i = 0; i < numberOfTokens; i++) {
            delete votingRound.tokenVoteTotal[availableTokens[i]];
        }
    }

    function newVotingRound() public {
        uint64 numberPriorRoundVoters = uint64(votingRound.votingUsers.length);
        for (uint64 i = 0; i < numberPriorRoundVoters; i++) {
            address user = votingRound.votingUsers[i];
            // distribute rewards
            distributeTokens(user);
            deleteUsersVotingRoundInfo(user);
        }
        deleteTokenVotesForRound();
        delete votingRound.votingUsers;
        votingRound.roundNumber += 1;
    }

    function tokenVotes(address _token) public view returns (uint32) {
        return votingRound.tokenVoteTotal[_token];
    }

    function hasUserVoted(address _user) public view returns (bool) {
        return votingRound.userVoted[_user];
    }

    function isUserEligibleToVote(address _user) public view returns (bool) {
        return addressVotingEligibity[_user];
    }

    // TODO: give users the ability to vote for new tokens on the next round

    // TODO: change tokens on the next round if necessary

    // TODO: this contract should custody variety tokens?

    // TODO: change the tokens available for voting

    // TODO: delete voting round info or append it to a list and start a new round.
    //       currently, round number increments but rest of the info does not change
}

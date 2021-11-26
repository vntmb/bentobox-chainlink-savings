// SPDX-License-Identifier: MIT

import "@chainlink/contracts/src/v0.8/VRFConsumerBase.sol";

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
contract VarietySavingsDAO is VRFConsumerBase {
    uint32 public roundNumber;
    address[] private usersWhoVoted;
    mapping(address => uint32) private tokenVoteTotal;
    mapping(address => bool) private hasUserVoted;
    // TODO: add start date, end date
    mapping(address => bool) addressVotingEligibity;
    // TODO: keep symbol/name of tokens somewhere
    mapping(address => bool) tokenAvailableForVoting;
    address[] public availableTokens = [
        0x326C977E6efc84E512bB9C30f76E30c160eD06FB,
        // Link token
        0x4997910AC59004383561Ac7D6d8a65721Fa2A663,
        0xdD5C42F833b81853F2B1e5E8b76B763bff7C1c37,
        0x898Ed56CbF0E4910b04080863c9f31792fc1a33C,
        0x224F0deDD8237d3Bf72934217CF6F433a4ed9F2d
    ];

    uint8 TRANSFER_TOKEN_AMOUNT = 10;

    address public owner;

    address public mainSavingsContract;

    bytes32 internal keyHash;
    uint256 internal fee;

    uint256 public randomResult;

    uint8 public percentChanceOfWinning;
    uint256 MAX_INT = 2**256 - 1;
    uint256 public cutoffInt;

    function setNewWinningChance(uint8 _newWinningChance) public {
        require(
            _newWinningChance > 0 && _newWinningChance <= 100,
            "Chance of winning must be in (0, 100)"
        );
        require(
            msg.sender == owner || msg.sender == address(this),
            "Not Authorized"
        );
        percentChanceOfWinning = _newWinningChance;
        cutoffInt = (MAX_INT / 100) * _newWinningChance;
    }

    /**
     * Constructor inherits VRFConsumerBase
     *
     * Network: Polygon (Matic) Mumbai Testnet
     * Chainlink VRF Coordinator address: 0x8C7382F9D8f56b33781fE506E897a4F1e2d17255
     * LINK token address:                0x326C977E6efc84E512bB9C30f76E30c160eD06FB
     * Key Hash: 0x6e75b569a01ef56d18cab6a8e71e6600d6ce853834d4a5748b720d06f878b3a4
     */

    constructor() 
        VRFConsumerBase(
            0x8C7382F9D8f56b33781fE506E897a4F1e2d17255, // VRF Coordinator
            0x326C977E6efc84E512bB9C30f76E30c160eD06FB // LINK Token
        )
    {
        owner = msg.sender; /// Added owner to set VarietySavings contract address
        uint8 numberOfAvailableTokens = uint8(availableTokens.length);
        // to begin with, add some choice tokens to votable pool
        for (uint8 i = 0; i < numberOfAvailableTokens; i++) {
            tokenAvailableForVoting[availableTokens[i]] = true;
        }
        keyHash = 0x6e75b569a01ef56d18cab6a8e71e6600d6ce853834d4a5748b720d06f878b3a4;
        fee = 0.0001 * 10**18; // 0.1 LINK (Varies by network)
        owner = msg.sender;
        setNewWinningChance(10);
    }

    /**
     * Requests randomness
     */
     // use Getting a random number within a range + Getting multiple random numbers
    function getRandomNumber() public returns (bytes32 requestId) {
        require(
            LINK.balanceOf(address(this)) >= fee,
            "Not enough LINK - fill contract with faucet"
        );
        return requestRandomness(keyHash, fee);
    }

    /**
     * Callback function used by VRF Coordinator
     */
    function fulfillRandomness(bytes32 requestId, uint256 randomness)
        internal
        override
    {
        randomResult = randomness;
    }

    // Implement a withdraw function to avoid locking your LINK in the contract
    // TODO: add security
    function withdrawLink() external {
        LINK.transfer(msg.sender, LINK.balanceOf(address(this)));
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
    // TODO: we don't need this function, we can add onlyMain to setWalletVotingEligibility directly and call that
    function addEligibleVoter(address user) external onlyMain(msg.sender) {
        // TODO: check if user is already eligible, if yes, ignore
        setWalletVotingEligibility(user, true);
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
        require(!hasUserVoted[msg.sender], "You can only vote once");
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
                tokenVoteTotal[currentToken] += 1;
            }
        }
        // register that the user has voted
        hasUserVoted[msg.sender] = true;
    }

    // TODO: Only callable internally and triggered by savings contract
    function setWalletVotingEligibility(address user, bool eligibility) private {
        addressVotingEligibity[user] = eligibility;
    }

    // TODO: use safe transfer
    function distributeTokens(address user) private {
        uint8 numberOfTokens = uint8(availableTokens.length);
        // TODO: distribute only the voted for tokens
        // TODO: use number from vrf to distribute token
        for (uint8 i = 0; i < numberOfTokens; i++) {
            IERC20 token = IERC20(availableTokens[i]);
            token.transfer(user, TRANSFER_TOKEN_AMOUNT);
        }
    }

    function deleteUsersVotingRoundInfo(address _user) private {
        hasUserVoted[_user] = false;
    }

    function deleteTokenVotesForRound() private {
        uint8 numberOfTokens = uint8(availableTokens.length);
        // TODO: distribute only the voted for tokens
        // TODO: use chainlink vrf
        for (uint8 i = 0; i < numberOfTokens; i++) {
            tokenVoteTotal[availableTokens[i]] = 0;
        }
    }

    // TODO: add constraints to who can trigger this function
    function newVotingRound() public {
        uint64 numberPriorRoundVoters = uint64(usersWhoVoted.length);
        for (uint64 i = 0; i < numberPriorRoundVoters; i++) {
            address user = usersWhoVoted[i];
            // distribute rewards
            distributeTokens(user);
            // TODO: delete only if token distribution is successful
            deleteUsersVotingRoundInfo(user);
        }
        deleteTokenVotesForRound();
        delete usersWhoVoted;
        roundNumber += 1;
    }

    function tokenVotes(address _token) public view returns (uint32) {
        return tokenVoteTotal[_token];
    }

    function getUserVotedStatus(address _user) public view returns (bool) {
        return hasUserVoted[_user];
    }

    function isUserEligibleToVote(address _user) public view returns (bool) {
        return addressVotingEligibity[_user];
    }

    // TODO: give users the ability to vote for new tokens on the next round

    // TODO: change tokens on the next round if necessary

    // TODO: this contract should custody variety tokens?

    // TODO: change the tokens available for voting

    // TODO: tidy and refactor contract
}

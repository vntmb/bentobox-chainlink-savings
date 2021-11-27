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
    // --------------- General Round Info ----------------
    uint32 public roundNumber;

    // -------------------- User Info --------------------
    address[] private usersWhoVoted;
    mapping(address => bool) private hasUserVoted;
    // TODO: add start date, end date
    mapping(address => bool) addressVotingEligibity;

    // ------------------- Token Info --------------------
    address[] public availableTokens = [
        0x4997910AC59004383561Ac7D6d8a65721Fa2A663,
        0xdD5C42F833b81853F2B1e5E8b76B763bff7C1c37,
        0x898Ed56CbF0E4910b04080863c9f31792fc1a33C,
        0x224F0deDD8237d3Bf72934217CF6F433a4ed9F2d
    ];
    mapping(address => uint32) private tokenVoteTotal;
    // TODO: keep symbol/name of tokens somewhere
    mapping(address => bool) tokenAvailableForVoting;
    address public lastRoundWinningToken;

    uint8 TRANSFER_TOKEN_AMOUNT = 10;

    // ----------------- Contract Info -------------------
    address public owner;

    address public mainSavingsContract;

    // -------------------- VRF Info ---------------------
    bytes32 internal keyHash;
    uint256 internal fee;
    // ~~~ randomness
    uint8 public chanceOfWinning = 10;
    uint256 public randomResult;
    uint256 MAX_INT = 2**256 - 1;
    uint256 public cutoffInt;

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
        fee = 0.0001 * 10**18; // 0.0001 LINK (Varies by network)
        owner = msg.sender;
        cutoffInt = (MAX_INT / 100) * chanceOfWinning;
    }

    /**
     * Requests randomness
     */
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

    /**
     * Turns single random number into array of random numbers
     */
    function expand(uint256 randomValue, uint256 n)
        public
        pure
        returns (uint256[] memory expandedValues)
    {
        expandedValues = new uint256[](n);
        for (uint256 i = 0; i < n; i++) {
            expandedValues[i] = uint256(keccak256(abi.encode(randomValue, i)));
        }
        return expandedValues;
    }

    function changeChanceOfWinning(uint8 _newChance) public {
        chanceOfWinning = _newChance;
        cutoffInt = (MAX_INT / 100) * _newChance;
    }

    // Implement a withdraw function to avoid locking your LINK in the contract
    // TODO: add security
    function withdrawLink() external {
        LINK.transfer(owner, LINK.balanceOf(address(this)));
        uint8 numberOfTokens = uint8(availableTokens.length);
        // send all ERC20 tokens back
        for (uint8 i = 1; i < numberOfTokens; i++) {
            IERC20 token = IERC20(availableTokens[i]);
            token.transfer(owner, token.balanceOf(address(this)));
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

    // TODO: Only callable by savings contract
    //    -> function setWalletVotingEligibility(address user, bool eligibility) external onlyMain(msg.sender) {
    function setWalletVotingEligibility(address user, bool eligibility) public {
        addressVotingEligibity[user] = eligibility;
    }

    // TODO: change this to private
    function selectWinningToken() public {
        uint8 numberOfTokens = uint8(availableTokens.length);
        address _tempToken = availableTokens[0];
        uint32 _tempTokenVote = tokenVoteTotal[_tempToken];
        // TODO: deal with ties
        for (uint8 i = 1; i < numberOfTokens; i++) {
            if (tokenVoteTotal[availableTokens[i]] > _tempTokenVote) {
                _tempToken = availableTokens[i];
                _tempTokenVote = tokenVoteTotal[_tempToken];
            }
        }
        lastRoundWinningToken = _tempToken;
        require(tokenVoteTotal[lastRoundWinningToken] != 0, "No votes registered");
    }

    // TODO: use safe transfer
    // TODO: use swap to make token transfers of equal value
    function distributeTokens(address _user, uint256 _winningChance) private {
        if (_winningChance < cutoffInt) {
            IERC20 token = IERC20(lastRoundWinningToken);
            token.transfer(_user, TRANSFER_TOKEN_AMOUNT);
        }
    }

    function deleteUsersVotingRoundInfo(address _user) private {
        hasUserVoted[_user] = false;
    }

    function deleteTokenVotesForRound() private {
        uint8 numberOfTokens = uint8(availableTokens.length);
        for (uint8 i = 0; i < numberOfTokens; i++) {
            tokenVoteTotal[availableTokens[i]] = 0;
        }
    }

    // TODO: add constraints to who can trigger this function
    function newVotingRound() public {
        uint64 numberPriorRoundVoters = uint64(usersWhoVoted.length);
        // get chances of winning from vrf
        getRandomNumber();
        uint256[] memory userWinningChances = new uint256[](
            numberPriorRoundVoters
        );
        userWinningChances = expand(randomResult, numberPriorRoundVoters);
        for (uint64 i = 0; i < numberPriorRoundVoters; i++) {
            address user = usersWhoVoted[i];
            uint256 userWinningChance = userWinningChances[i];
            // distribute rewards according to vrf
            distributeTokens(user, userWinningChance);
            // TODO: delete only if token distribution is successful
            deleteUsersVotingRoundInfo(user);
        }
        // TODO: delete only if token distribution is successful
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

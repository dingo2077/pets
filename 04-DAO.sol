// SPDX-License-Identifier: UNLICENSED
//Part of this code this code was taken from sfyMantissa author and was rewrited, exactly votes mechanism to ERC20Votes with Snaphots.

pragma solidity ^0.8.17;

import "./03-MyERC20.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";

contract DAO is AccessControl {
    using Counters for Counters.Counter;
    Counters.Counter private proposalId;

    bytes32 public constant CHAIRMAN_ROLE = keccak256("CHAIRMAN_ROLE");
    bytes32 public constant DAO_ROLE = keccak256("DAO_ROLE");
    
    mapping(address => uint256) public userToLastProposalId;
    mapping(uint256 => Proposal) public proposals;

    function viewerProposal(uint256 id) view public returns (address) {
        return proposals[id].recipient;
    }

    function viewerVotes(uint256 id) view public returns (uint256) {
        return proposals[id].voteCount;
    }

    struct Proposal {
        // memory slots are 32 bytes
        mapping(address => bool) voterHasVoted;
        uint256 startTimeStamp; // 32 bytes
        uint256 voteCount; // 32 bytes
        uint256 positiveVoteCount; // 32 bytes
        bool isFinished; // 1 byte
        address recipient; // 20 bytes
        string description; // variable (1 byte per char)
        bytes callData; // variable (1 byte per byte1)
    }

    IERC20 public token;
    IVotes public ERC20VotesInt;
    uint256 public minimumQuorum;
    uint256 public debatingPeriodDuration;

    event ProposalAdded(
        uint256 proposalId,
        string description,
        uint256 startTimeStamp,
        address recipient
    );
    event VoteCasted(
        uint256 proposalId,
        address voter,
        bool decision,
        uint256 votes
    );
    event ProposalFinished(
        uint256 proposalId,
        string description,
        bool decision,
        uint256 positiveVoteCount,
        uint256 voteCount
    );
    

    constructor(
        address _chairman,
        address _voteToken,
        uint256 _minimumQuorum,
        uint256 _debatingPeriodDuration
    ) {
        _setupRole(CHAIRMAN_ROLE, _chairman);
        _setupRole(DAO_ROLE, address(this));
        token = IERC20(_voteToken);
        ERC20VotesInt = IVotes(_voteToken);
        minimumQuorum = _minimumQuorum;
        debatingPeriodDuration = _debatingPeriodDuration;
        
    }

    function addProposal(bytes memory _callData, address _recipient, string memory _description) external {
        require(hasRole(CHAIRMAN_ROLE, msg.sender), "ERROR: Caller is not the chairman.");

        proposalId.increment();
        Proposal storage proposal = proposals[proposalId.current()];
        uint256 startTimeStamp = block.timestamp;
        proposal.startTimeStamp = startTimeStamp;
        proposal.recipient = _recipient;
        proposal.description = _description;
        proposal.callData = _callData;
        
        emit ProposalAdded(proposalId.current(),_description,startTimeStamp,_recipient);
    }
    
    function vote(uint256 _proposalId, bool _decision) external { 
        Proposal storage proposal = proposals[_proposalId];

        require(proposalId.current() >= _proposalId,"ERROR: No proposal with such ID.");
        require(!proposal.isFinished,"ERROR: This proposal voting is already finished.");
        require(block.timestamp <= proposal.startTimeStamp + debatingPeriodDuration,"ERROR: This proposal voting no longer accepts new votes.");
        require(!proposal.voterHasVoted[msg.sender],"ERROR: You can only vote once.");
        
        uint256 votes = ERC20VotesInt.getPastVotes(msg.sender, block.number-1);
        userToLastProposalId[msg.sender] = _proposalId;
        proposal.voteCount += votes;
        proposal.voterHasVoted[msg.sender] = true;
        if (_decision) proposal.positiveVoteCount += votes;

        emit VoteCasted(_proposalId, msg.sender, _decision, votes);
    }

    function finishProposal(uint256 _proposalId) external {
        Proposal storage proposal = proposals[_proposalId];

        require(proposalId.current() >= _proposalId,"ERROR: No proposal with such ID.");
        require(block.timestamp > proposal.startTimeStamp + debatingPeriodDuration,"ERROR: Proposal voting cannot be finished prematurely.");
        require(!proposal.isFinished,"ERROR: This proposal voting is already finished.");

        bool decision;
        uint256 negativeVoteCount = proposal.voteCount - proposal.positiveVoteCount;

        if (
            proposal.voteCount >= minimumQuorum &&
            proposal.positiveVoteCount > negativeVoteCount
        ) {
            callFunction(proposal.recipient, proposal.callData);
            decision = true;
        } else {
            decision = false;
        }
        proposal.isFinished = true;

        emit ProposalFinished(
            _proposalId,
            proposal.description,
            decision,
            proposal.positiveVoteCount,
            proposal.voteCount
        );
    }

    function setMinimumQuorum(uint256 _value) external {
        require(hasRole(CHAIRMAN_ROLE, msg.sender) || hasRole(DAO_ROLE, msg.sender), "ERROR: Caller is not the chairman or DAO.");
        minimumQuorum = _value;
    }

    function setDebatingPeriodDuration(uint256 _value) external {
        require(hasRole(CHAIRMAN_ROLE, msg.sender) || hasRole(DAO_ROLE, msg.sender),"ERROR: Caller is not the chairman or DAO.");
        debatingPeriodDuration = _value;
    }

    function callFunction(address recipient, bytes memory signature) internal {
        (bool success, ) = recipient.call(signature);
        require(success, "ERROR: External function call by signature failed.");
    }
}

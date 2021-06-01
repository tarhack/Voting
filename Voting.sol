// SPDX-License-Identifier: GPL-3.0

pragma solidity >= 0.8.0;

import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/adc50d465cb028841ac3017a802788126c352874/contracts/access/Ownable.sol";


contract Voting is Ownable {
    
    address admin;
    
    uint private winningProposalId ;
    uint private maxCount = 0;
    
    mapping(address=>Voter) voters ;
    
    
    mapping(address=>PropsalEntry[]) internal  proposals  ;
    
    uint internal lastProposalId ;
    
    
    struct Voter {
        bool isRegistered;
        bool hasVoted;
        uint votedProposalId;
    }

    struct Proposal {
        string description;
        uint  voteCount ;
    }
    
    struct PropsalEntry {
        uint index;
        Proposal proposal;
    }
    
    PropsalEntry[] proposalVote  ;
    
    
    WorkflowStatus public status ;
    
    event VoterRegistered(address voterAddress);
    event ProposalsRegistrationStarted();
    event ProposalsRegistrationEnded();
    event ProposalRegistered(uint proposalId);
    event VotingSessionStarted();
    event VotingSessionEnded();
    event Voted (address voter, uint proposalId);
    event VotesTallied();
    event WorkflowStatusChange(WorkflowStatus previousStatus, WorkflowStatus newStatus);
    
    enum WorkflowStatus {
        RegisteringVoters,
        ProposalsRegistrationStarted,
        ProposalsRegistrationEnded,
        VotingSessionStarted,
        VotingSessionEnded,
        VotesTallied
    }
    
    /**
     * 
     * Only for Admin/Owner
     * 
     */
    function revertState(WorkflowStatus _status) public onlyOwner returns(WorkflowStatus,WorkflowStatus) {
        WorkflowStatus from = status;
        status = _status;
        emit WorkflowStatusChange(from,status);
        return (from, status);
    }
    
    function changeState() public onlyOwner returns(WorkflowStatus) {
        require(
            status != WorkflowStatus.VotesTallied,
            "No State to change, Voting process is over"
        );
        if ( status == WorkflowStatus.RegisteringVoters){
             status = WorkflowStatus.ProposalsRegistrationStarted;
             emit ProposalsRegistrationStarted();
        }else if ( status == WorkflowStatus.ProposalsRegistrationStarted){
             status = WorkflowStatus.ProposalsRegistrationEnded;
             emit ProposalsRegistrationEnded();
        }else if ( status == WorkflowStatus.ProposalsRegistrationEnded ){
             status = WorkflowStatus.VotingSessionStarted;
             emit VotingSessionStarted();
        }else if ( status == WorkflowStatus.VotingSessionStarted ){
             status = WorkflowStatus.VotingSessionEnded;
             emit VotingSessionEnded();
        }else if ( status == WorkflowStatus.VotingSessionEnded ){
             computeWinningProposal();
             status = WorkflowStatus.VotesTallied;
             emit VotesTallied();
        }
        return status;
    }
    
    
    constructor(){
        admin=msg.sender;
        lastProposalId = 0;
        status = WorkflowStatus.RegisteringVoters;
    }
    
    
    function register(address _voter) public onlyOwner returns(bool){
        require(
            status == WorkflowStatus.RegisteringVoters,
            "The Voter Registration is closed"
        );
        /*require(
            voters[_voter].length == 0,
            "The Voter Registration is closed"
        );*/
        Voter memory  v ;
        v.isRegistered = true;
        voters[_voter] = v;
        emit VoterRegistered(_voter);
        return v.isRegistered;
    }
    
    
    function checkForProposalId(uint _id) private view returns (bool){
         for(uint idx=0;idx < proposalVote.length;idx++ ){
            if ( proposalVote[idx].index == _id ){
                return true;
            }
        }
        return false;
    }
    
    /**
     * 
     * Voters can vote if :
     *   - Voting session is open
     *   - They are registred
     *   - The proposal ID exists
     *   - They haven't already voted
     **/
    function vote(uint _proposalId) public returns(bool) {
        require(
            status == WorkflowStatus.VotingSessionStarted,
            "Voting session is NOT open or closed"
        );
        require(
            voters[msg.sender].isRegistered,
            "The Voter is NOT registred"
        );
        require(
            ! voters[msg.sender].hasVoted,
            "The Voter has already voted"
        );
         require(
             checkForProposalId(_proposalId),
            "The proposal ID is Unknown"
        );
        
        for(uint idx=0;idx < proposalVote.length;idx++ ){
            if ( proposalVote[idx].index == _proposalId ){
                 proposalVote[idx].proposal.voteCount++;
            }
        }
        emit Voted(msg.sender, _proposalId);
        voters[msg.sender].hasVoted = true;
        return voters[msg.sender].hasVoted;
    }
    
    function addProposal(string memory _description) public returns(uint) {
         require(
            status == WorkflowStatus.ProposalsRegistrationStarted,
            "Proposal Registration is NOT Started"
        );
        require(
            voters[msg.sender].isRegistered,
            "The Voter is NOT registred"
        );
        
       PropsalEntry[] storage entries = proposals[msg.sender] ;
       
       lastProposalId++;
       PropsalEntry memory entry ;
       
        //
        // revert all If proposal already exists
        //
        if ( entries.length > 0 ){
            uint idx;
            for(idx=0;idx < entries.length;idx++ ){
                entry = entries[idx] ;
                if ( keccak256(abi.encodePacked(entry.proposal.description)) == keccak256(abi.encodePacked(_description)) ){
                    revert("Proposal already exists !!!") ;
                }
            }
        }
        
        entry.index = lastProposalId;
        Proposal memory  p ;
        p.description = _description;
        p.voteCount=0;
        entry.proposal = p;
        entries.push(entry);
        
        proposalVote.push(entry) ;
        
        emit ProposalRegistered(lastProposalId);
        return lastProposalId;
        
    }
    
    
    function computeWinningProposal() private {
        require(
            status == WorkflowStatus.VotingSessionEnded,
            "Voting session is NOT yet closed"
        );
        
        for(uint idx=0;idx < proposalVote.length;idx++ ){
            if ( proposalVote[idx].proposal.voteCount > maxCount ){
                 maxCount = proposalVote[idx].proposal.voteCount;
                 winningProposalId = proposalVote[idx].index;
            }
        }
    }
    
    function getWinningProposal() public view returns (uint){
        require(
            status == WorkflowStatus.VotesTallied,
            "Votes are NOT already tallied"
        );
        return winningProposalId;
    }
    
    function lastId() public view returns (uint){
        return lastProposalId;
    }
    
    function numberProposalFor(address _voter) public view returns (uint){
        PropsalEntry[] storage entries = proposals[_voter] ;
        return entries.length;
    }
    
}
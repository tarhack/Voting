// SPDX-License-Identifier: GPL-3.0

pragma solidity >= 0.8.0;

import "../Voting.sol";

contract VotingTest{
    
    Voting voting;
    
    // Addresse du contrat : 0x2951B88E9cCC709836F1891c97930dA024fBC424
    // Voter 1 : 0x611DAE3A4588e83F2AA21C780908A4Eb53D5e217
    // Voter 2 : 0x1563982C1dE544DD5c8fc915a617C6983D380e90
    // Voter 3 : 0x4Cc35A09e16B2572957dd1688fcAD6C19e26EdB8 (Owner)
    
     function beforeAll () public {
       voting = new Voting();
    }
    
    function testStateMachine() public {
        voting.changeState() ;
        voting.changeState() ;
        voting.changeState() ;
        voting.changeState() ;
    }
    
    function tesRegister() public {
        voting.register(0x611DAE3A4588e83F2AA21C780908A4Eb53D5e217) ;
        voting.register(0x1563982C1dE544DD5c8fc915a617C6983D380e90) ;
        voting.register(0x4Cc35A09e16B2572957dd1688fcAD6C19e26EdB8) ;
        
    }
    
     function tesProposal() public {
        voting.addProposal("Proposal - One 1") ;
        voting.addProposal("Proposal - Two 2") ;
        voting.addProposal("Proposal - Three 3 from Owner") ;
    }
    
    
    
}
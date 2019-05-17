pragma solidity >=0.4.22 <0.6.0;

// @title Voting with delegation.
contract Ballot {
    // This declares a new complex type which will
    // be used for variables later.
    // It represents a single voter.
    struct Voter {
        uint weight; // weight is accumulated by delegation
        bool voted;  // if true, that person already voted
        address delegate; // person delegated to
        uint vote;   // index of the voted proposal
        uint age ;   // age of person
        string name; // name of person
        bool gender; // gender of person(false:Male, true:Female)
        bool inf;  // if true, that person has already entered his/her information 
    }

    // This is a type for a single proposal.
    struct Proposal {
        bytes32 name;   
        uint voteCount; // number of accumulated votes
    }

    address public chairperson;

    // Array for storing addresses of all persons
    address[] accounts;  

    // This declares a state variable that
    // stores a `Voter` struct for each possible address.
    mapping(address => Voter) public voters;

    // A dynamically-sized array of `Proposal` structs.
    Proposal[] public proposals;

    uint public eligible_age = 18 ;
    // Eligible age for voting.
    // People who are eligible, can only vote if the chairperson gives them the right.
    
    // Update the eligible age.
    // Only chairperson can call this function.
    function update_eligible_age(uint Age) public {
        require(msg.sender == chairperson, "Unauthorized access");
        eligible_age = Age;
    }

    // Create a new ballot to choose one of `proposalNames`.
    constructor(bytes32[] memory proposalNames) public {

        chairperson = msg.sender;
        voters[chairperson].weight = 1;

        // For each of the provided proposal names,
        // create a new proposal object and add it
        // to the end of the array.
        for (uint i = 0; i < proposalNames.length; i++) {
            // `Proposal({...})` creates a temporary
            // Proposal object and `proposals.push(...)`
            // appends it to the end of `proposals`.
            proposals.push(Proposal({
                name: proposalNames[i],
                voteCount: 0
            }));
        }
    }

    // All persons need to enter their information for them to be considered for voting.
    // Anyone can enter their information only once and cannot update it any further.
    function information (string memory n, uint a, bool g) public {
        require(voters[msg.sender].inf == false,"Information already updated");
        voters[msg.sender].name = n;
        voters[msg.sender].gender = g;
        voters[msg.sender].age = a;
        voters[msg.sender].inf = true;
        accounts.push(msg.sender);
    }

    //Give all eligible voters the right to vote.
    //May only be called by `chairperson`.
    function giveRightToAllEligible() public {
        // If the first argument of `require` evaluates
        // to `false`, execution terminates and all
        // changes to the state and to Ether balances
        // are reverted.
        require(msg.sender==chairperson, "Unauthorized access");

        for(uint i=0; i<accounts.length; i++)
        {
            if(voters[accounts[i]].age >= eligible_age && voters[accounts[i]].weight == 0 && 
               voters[accounts[i]].inf == true )
            {
                voters[accounts[i]].weight = 1;
            }
        }
    }

    // Give `voter` the right to vote on this ballot.
    // May only be called by `chairperson`.
    // Only an eligible person can be given the right to vote.
    function giveRightToVote(address voter) public {

        require( msg.sender == chairperson,"Only chairperson can give right to vote");
        require(!voters[voter].voted,"The voter already voted");
        require(voters[voter].weight == 0);
        require(voters[voter].inf == true, "Voter has not entered his/her information");
        require(voters[voter].age >= eligible_age, "Voter is under age");
        
        voters[voter].weight = 1;
    }

    /// Delegate your vote to the voter `to`.
    function delegate(address to) public {
        // assigns reference
        Voter storage sender = voters[msg.sender];
        
        require(!sender.voted, "You already voted.");
        require(voters[to].weight>0, "Delegate is not trusted by the chairperson");
        // Delegate must have the right to vote.

        require(to != msg.sender, "Self-delegation is disallowed.");

        // Forward the delegation as long as
        // `to` also delegated.
       while (voters[to].delegate != address(0)) {
            to = voters[to].delegate;

            //  Loop in the delegation is not allowed.
            require(to != msg.sender, "Found loop in delegation.");
        }

        // Since `sender` is a reference, this
        // modifies `voters[msg.sender].voted`
        sender.voted = true;
        sender.delegate = to;
        Voter storage delegate_ = voters[to];
        if (delegate_.voted) {
            // If the delegate already voted,
            // directly add to the number of votes
            proposals[delegate_.vote].voteCount += sender.weight;
        } else {
            // If the delegate did not vote yet,
            // add to her weight.
            delegate_.weight += sender.weight;
        }
    }

    /// Give your vote (including votes delegated to you)
    /// to a proposal. 
    function vote(uint proposal) public {
        Voter storage sender = voters[msg.sender];
        require(sender.weight != 0, "You donot have right to vote");
        require(!sender.voted, "Already voted");
        sender.voted = true;
        sender.vote = proposal;

        // If `proposal` is out of the range of the array,
        // this will throw automatically and revert all
        // changes.
        proposals[proposal].voteCount += sender.weight;
    }

    // Calculate the winning proposal by maximum voteCount.
    // Check if no-one has voted or there is a draw.
    function winningProposal() public view returns (uint winningProposal_) {
        uint winningVoteCount = 0;
        uint c = 0;

        for (uint p = 0; p < proposals.length; p++) {
            if (proposals[p].voteCount > winningVoteCount) {
                winningVoteCount = proposals[p].voteCount;
                winningProposal_ = p;
            }
        }

        require(winningVoteCount != 0, "No-one has voted");

        //Check if two or more proposals have a draw to win.
        for (uint p = 0; p < proposals.length; p++)
            if(proposals[p].voteCount == winningVoteCount)
                c++;

        require( c<2 , "There is a DRAW") ;

    }

    // Calls winningProposal() function to get the index
    // of the winner contained in the proposals array and then
    // returns the name of the winner
    function winnerName() public view
            returns (bytes32 winnerName_)
    {
        winnerName_ = proposals[winningProposal()].name;
    }

    // Count the total number of people, number of people voted,
    // and the number of people having the right to vote.
    function count() public view returns(uint total_people, uint people_can_vote, uint people_voted) {
        total_people = accounts.length;
        uint c=0;
        uint v=0;
        for(uint i=0; i<accounts.length; i++)
        {
            if(voters[accounts[i]].weight > 0)
            {
                c++;
                if(voters[accounts[i]].voted == true)
                    v++;
            }
        }
        people_can_vote = c;
        people_voted = v;
    }
}
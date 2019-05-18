pragma solidity >=0.5.0 <0.6.0;

contract SimpleAuction {
    
    address payable public beneficiary;
    uint public auctionEndTime; // absolute unix timestamp (seconds since 1970-01-01)
    address public highestBidder;
    uint public highestBid;
    uint public baseBidPrice;

    // Allow withdrawal of previous lower bids
    mapping(address => uint) pendingReturns;

    // Set to true at the end, disallows any change.
    // By default initialized to `false`.
    bool ended;

    event HighestBidIncreased(address bidder, uint amount);
    event AuctionEnded(address winner, uint amount);

    constructor(uint _biddingTime, uint _baseBidPrice) public {
        beneficiary = msg.sender;
        auctionEndTime = now + _biddingTime;
        baseBidPrice= _baseBidPrice;
    }

    function bid() public payable {
       
        require(msg.sender != beneficiary,"Beneficiary cannot bid");
        require(!ended, "Auction has already been ended.");
        require(now <= auctionEndTime,"Auction has already timed-out.");
        
        // All bids should be higher than baseBidPrice
        require(msg.value > baseBidPrice,"Bid Price is lower than base price");

        // If the bid is not highest till now, send the money back.
        require(msg.value > highestBid,"There already is a higher bid.");

        if (highestBid != 0) {
            // Sending back the money by simply using
            // highestBidder.send(highestBid) is a security risk
            // because it could execute an untrusted contract.
            // It is always safer to let the recipients
            // withdraw their money themselves.
            pendingReturns[highestBidder] += highestBid;
        }
        highestBidder = msg.sender;
        highestBid = msg.value;
        emit HighestBidIncreased(msg.sender, msg.value); // Trigger the event
    }

    /// Withdraw the pending amount of lower bids.
    function withdraw() public {
        uint amount = pendingReturns[msg.sender];
        bool x;
        require(msg.sender != highestBidder,"You are the highest bidder: Cannot withdraw");
        require(amount > 0,"You have nothing to withdraw");
            // It is important to set this to zero because the recipient
            // can call this function again as part of the receiving call
            // before `send` returns.
            pendingReturns[msg.sender] = 0;

            if (x = !msg.sender.send(amount)) 
               pendingReturns[msg.sender] = amount;
               
            require(x == false,"Withdraw failed");   
    }
    
    //Show current time
    function Current_time() public view returns(uint) {
        return now;
    }
    
    // Show pending amount
    function pending_amount() public view returns(uint){
        return pendingReturns[msg.sender];
    }

    /// End the auction and send the highest bid to the beneficiary.
    function auctionEnd() public {
        
        // 1. Conditions
        require(msg.sender == beneficiary, "Unauthorized access");
        require(!ended, "auction has already been ended.");

        // 2. Effects
        ended = true;
        emit AuctionEnded(highestBidder, highestBid);

        // 3. Interaction with other contracts
        beneficiary.transfer(highestBid);
        
        // If these phases are mixed up, the other contract could call
        // back into the current contract and modify the state or cause
        // effects (ether payout) to be performed multiple times.
        // If functions called internally include interaction with external
        // contracts, they also have to be considered interaction with
        // external contracts.

    }
}

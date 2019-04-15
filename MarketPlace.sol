pragma solidity ^0.5.0;

contract MarketPlace
{
    enum StateType {
      ItemAvailable,
      OfferPlaced,
      OfferAccepted,
      Paid,
      Recieved,
      Final
    }

    mapping (address => uint) public balanceOf;
    address public InstanceOwner;
    string public Description;
    uint public AskingPrice;
    StateType public State;

    address public InstanceBuyer;
    uint public OfferPrice;
    uint public contract_bal = 0;

    constructor(string memory description, uint price) public{

        InstanceOwner = msg.sender;
        AskingPrice = price* (10**18);
        Description = description;
        State = StateType.ItemAvailable;
        balanceOf[msg.sender]= msg.sender.balance;
    }

    function payToContract() public payable{

        require(msg.sender==InstanceBuyer);
        require(msg.value>=OfferPrice);
        require(State == StateType.OfferAccepted);
        if(msg.value>OfferPrice)
        {
            msg.sender.transfer(msg.value-OfferPrice);
        }
        contract_bal+=OfferPrice;
        balanceOf[msg.sender]= msg.sender.balance;
        State = StateType.Paid;
    }

    function  asset_recieved () public {

        require(msg.sender == InstanceBuyer);
        require(State == StateType.Paid);
        State = StateType.Recieved;
    }

    function get_payment () public {

        require(msg.sender == InstanceOwner);
        require(State == StateType.Recieved);
        msg.sender.transfer(OfferPrice);
        contract_bal-=OfferPrice;
        balanceOf[msg.sender]= msg.sender.balance ;
        State = StateType.Final ;
    }

    function MakeOffer(uint offerPrice) public{

        require(offerPrice != 0);
        require(State == StateType.ItemAvailable);
        require(InstanceOwner != msg.sender);
        InstanceBuyer = msg.sender;
        OfferPrice = offerPrice * (10**18);
        State = StateType.OfferPlaced;
        balanceOf[msg.sender]= msg.sender.balance;
    }

    function Reject() public{

        require(State == StateType.OfferPlaced);
        require(InstanceOwner == msg.sender);
        InstanceBuyer = 0x0000000000000000000000000000000000000000;
        State = StateType.ItemAvailable;
    }

    function AcceptOffer() public{

        require(msg.sender == InstanceOwner);
        State = StateType.OfferAccepted;
    }
}

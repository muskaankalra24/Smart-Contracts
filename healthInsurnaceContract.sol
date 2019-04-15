/*******************************************************************
The information shall not be copied, reproduced in any form or stored in a retrieval system or database by Recipient without the 
prior written consent of Discloser, except for such copies and storage as may resonably internally by Recipient for the Purpose.

Authors:
1. Punit Agarwal, punit.agarwal.y16@lnmiit.ac.in
2. Muskan Kalra, muskan.kalra.y16@lnmiit.ac.in
*******************************************************************/

pragma solidity ^0.4.0;
contract HealthInsuancePolicyAgreement {
    /* This declares a new complex type which will hold the claim bills*/
    struct ClaimAmounts{
    uint id; /* The claim id*/
    uint value; /* The amount of Bill that is claimed*/
    }
    struct PremiumPaid{
        bool _premiumPaid;
        uint value;
    }
/* Claim Amounts, bill amount, policy number, policy holder, policy insurer, tenure, premiumAmount*/
    ClaimAmounts[] public claimamounts;
    PremiumPaid[] public premiumpaid;
    uint public createdTimestamp;

    uint public claimableAmount;
    /* Maximum amount that can be claimed if all docs are verified*/
    
    string public policyNumber;

    address public policyInsurer;

    address public policyHolder;

    uint tenure;

    uint premiumAmount;

    enum State {Created, Started, Claimed, Terminated}
    State public state;

    function PolicyAgreement(uint _claimableAmount, string _policyNumber, uint _premiumAmount, uint _tenure) {
        claimableAmount = _claimableAmount;
        policyNumber = _policyNumber;
        premiumAmount = _premiumAmount;
        tenure = _tenure;
        policyInsurer = msg.sender;
        createdTimestamp = block.timestamp;
    }
    modifier require(bool _condition) {
        if (!_condition) throw;
        _;
    }
    modifier onlyPolicyInsurer() {
        if (msg.sender != policyInsurer) throw;
        _;
    }
    modifier onlyPolicyHolder() {
        if (msg.sender != policyHolder) throw;
        _;
    }
    modifier inState(State _state) {
        if (state != _state) throw;
        _;
    }

    /* We also have some getters so that we can read the values
    from the blockchain at any time */
    function getClaimedBills() internal returns (ClaimAmounts[]) {
        return claimamounts;
    }

    function getPremiumPaid() internal returns (PremiumPaid[]) {
        return premiumpaid;
    }

    function getPremiumAmunt() constant returns (uint) {
        return premiumAmount;
    }

    function getPolicyInsurer() constant returns (address) {
        return policyInsurer;
    }

    function getPolicyHolder() constant returns (address) {
        return policyHolder;
    }

    function getClaimableAmount() constant returns (uint) {
        return claimableAmount;
    }

    function getContractCreated() constant returns (uint) {
        return createdTimestamp;
    }

    function getContractAddress() constant returns (address) {
        return this;
    }

    function getState() returns (State) {
        return state;
    }

    function setPremium() constant{

    }

    /* Events for DApps to listen to */
    event agreementConfirmed();

    event premiumPaid();

    event insuranceClaimed();

    event contractTerminated();

    /* Confirm the lease agreement as policyHolder*/
    function confirmAgreement()
    inState(State.Created)
    require(msg.sender != policyInsurer)
    {
        agreementConfirmed();
        policyHolder = msg.sender;
        state = State.Started;
    }

    function payPremium() onlyPolicyHolder() inState(State.Started){
        premiumPaid();
        policyInsurer.transfer(premiumAmount);
        /*premiumpaid.push(PremiumPaid({
            id: premiumpaid.length + 1,
            value : premiumAmount
            }));*/
    }
    /* Terminate the contract so the policyHolder can’t pay premium anymore,
    and the contract is terminated */

    function InsuranceClaimed() onlyPolicyInsurer() inState(State.Claimed){
        insuranceClaimed();
        claimamounts.push(ClaimAmounts({
            id: claimamounts.length + 1,
            value: msg.value
            }));        
    }

    function terminateContract() onlyPolicyInsurer()
    {
        contractTerminated();
        policyInsurer.send(this.balance);
        /* If there is any value on the contract send it to the policyInsurer*/
        state = State.Terminated;
    }
}
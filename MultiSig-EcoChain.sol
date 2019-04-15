pragma solidity ^ 0.4.8;

//--------------------please review the code------------------
contract SafeMath {
    function safeMul(uint a, uint b) internal returns(uint) {
        uint c = a * b;
        assert(a == 0 || c / a == b);
        return c;
    }

    function safeDiv(uint a, uint b) internal returns(uint) {
        assert(b > 0);
        uint c = a / b;
        assert(a == b * c + a % b);
        return c;
    }

    function safeSub(uint a, uint b) internal returns(uint) {
        assert(b <= a);
        return a - b;
    }

    function safeAdd(uint a, uint b) internal returns(uint) {
        uint c = a + b;
        assert(c >= a && c >= b);
        return c;
    }

    function max64(uint64 a, uint64 b) internal constant returns(uint64) {
        return a >= b ? a : b;
    }

    function min64(uint64 a, uint64 b) internal constant returns(uint64) {
        return a < b ? a : b;
    }

    function max256(uint256 a, uint256 b) internal constant returns(uint256) {
        return a >= b ? a : b;
    }

    function min256(uint256 a, uint256 b) internal constant returns(uint256) {
        return a < b ? a : b;
    }

    function assert(bool assertion) internal {
        if (!assertion) {
            throw;
        }
    }
}
contract ERC20 {
    uint public totalSupply;
    function balanceOf(address who) constant returns(uint);

    function allowance(address owner, address spender) constant returns(uint);

    function transferFrom(address from, address to, uint value) returns(bool ok);

    function approve(address spender, uint value) returns(bool ok);

    function transfer(address to, uint value) returns(bool ok);
    event Transfer(address indexed from, address indexed to, uint value);
    event Approval(address indexed owner, address indexed spender, uint value);
}

contract Ownable {
    address public superOwner;

    function Ownable() {
        superOwner = msg.sender;
    }

    modifier onlySuperOwner() {
        if (msg.sender != superOwner) {
            throw;
        }
        _;
    }

    function transferOwnership(address newOwner) onlySuperOwner {
        if (newOwner != address(0)) {
            superOwner = newOwner;
        }
    }
}

//---- from 72 to 258 is the MultiSig contract (250 lines).
contract multisig is Ownable, SafeMath, ERC20 {

    mapping(address => uint) balances;
    mapping(address => mapping(address => uint)) allowed;
    mapping(address => bool) confirmations;

    address[]  owners;
    uint  required;
    bool  inProgressTransfer = false;
    uint  _daysTransfer;
    uint  startT;
    struct _parameters {
        address _to;
        uint _value;
    }
    _parameters  parameters;
    modifier isOwnerM() {
            bool isOwner = false;
            for (uint i = 0; i < owners.length; i++) {
                if (owners[i] == msg.sender) isOwner = true;
            }
            if (!isOwner) throw;
            _;
        }

    function isOwner(address sender) constant returns(bool status) {
        bool isOwner = false;
        for (uint i = 0; i < owners.length; i++) {
            if (owners[i] == sender) return true;
        }
    }

    function getConfirmedCount() constant returns(uint) {
        uint count = 0;
        for (uint i = 0; i < owners.length; i++) {
            if (confirmations[owners[i]]) {
                count = count + 1;
            }
        }
        return count;
    }

    function isConfirmed() constant returns(bool status) {
        uint count = getConfirmedCount();
        if (count < required) {
            return false;
        } else {
            return true;
        }
    }

    function ownerCount() constant returns(uint) {
        return owners.length;
    }

    function ownersArr() constant returns(address[]) {
        return owners;
    }

    function confirmTransfer(address _to, uint _value) {
        require(parameters._to == _to && parameters._value == _value && timeLeft());
        if (isOwner(msg.sender) && !confirmations[msg.sender]) {
            confirmations[msg.sender] = true;
            transfer(_to, _value);
        }
    }

    function addOwner(address newOwner) onlySuperOwner {
                    require(!isOwner(newOwner) && newOwner != superOwner);
                    owners.push(newOwner);
                    required++;
                }

     function removeOwner(address concernedAddress) onlySuperOwner {
       require(isOwner(concernedAddress));
       uint i=0;
       for (i = 0; i < owners.length; i++) {
           if (owners[i] == concernedAddress) {
               delete owners[i];
               break;
           }
       }
       for (i; i < owners.length - 1; i++) {
           owners[i] = owners[i + 1];
       }
       owners.length--;
       required--;

    }

    function revokeVoting() onlySuperOwner {
      inProgressTransfer = false;
      startT=0;
      cleanSlate(msg.sender);
    }

    function startVotingTransfer(uint _daysCount, address to, uint value) isOwnerM {
        if (!inProgressTransfer) {
            startT = now;
            cleanSlate( msg.sender);
            confirmations[msg.sender] = true;
            inProgressTransfer = true;
            parameters._to = to;
            parameters._value = value;
            _daysTransfer = _daysCount;
            if (confirmations[msg.sender]) transfer(to, value);
        }
    }

    function timeLeft() constant public returns(bool) {
        uint start;
        uint _days;
            start = startT;
            _days = _daysTransfer;
        if (start + _days * 60 >= now) { //--------CURRENTLY SET TO  MINUTES----------
            return true;
        } else {
            return false;
        }
    }

    function hasConfirmed( address concernedAddress) constant public returns(bool) {
        return confirmations[concernedAddress];
    }

    function currentTime() constant public returns(uint) {
        return now;
    }

    function revokeVote() public isOwnerM returns(bool) {
        require(confirmations[msg.sender]);
        confirmations[msg.sender] = false;
        return true;
    }

    function cleanSlate(address sender) {
      require(isOwner(sender) || sender == superOwner);
        for (uint i = 0; i < owners.length; i++) {
            confirmations[owners[i]] = false;
        }
    }

    function inProgress() constant public returns(bool) {
        return inProgressTransfer;
    }

    function transfer(address _to, uint _value) returns(bool success) {
        require(msg.sender != superOwner);
        if (isOwner(msg.sender)){
            require(!isOwner(_to));
            //------------------- if its one of those owners that have siggned up for multisig.
            //------------------------ currenly its only for the SuperOwner
            //------------------------all the deposits from any of the 4 owner accounts will be eventually done only from superOwner.
            if (isConfirmed() && timeLeft() && parameters._to == _to && parameters._value == _value) {
                balances[superOwner] = safeSub(balances[superOwner], _value);
                balances[_to] = safeAdd(balances[_to], _value);
                Transfer(superOwner, _to, _value);
                inProgressTransfer = false;
                startT = 0;
                cleanSlate(msg.sender);
                return true;
            }
        } else {
            balances[msg.sender] = safeSub(balances[msg.sender], _value);
            balances[_to] = safeAdd(balances[_to], _value);
            Transfer(msg.sender, _to, _value);
            return true;
        }
    }
}

contract StandardToken is multisig {
    function transferFrom(address _from, address _to, uint _value) returns(bool success) { //----------------------------level 4----------------------------
        var _allowance = allowed[_from][msg.sender];
        // Check is not needed because safeSub(_allowance, _value) will already throw if this condition is not met
        // if (_value > _allowance) throw;
        balances[_to] = safeAdd(balances[_to], _value);
        balances[_from] = safeSub(balances[_from], _value);
        allowed[_from][msg.sender] = safeSub(_allowance, _value);
        Transfer(_from, _to, _value);
        return true;
    }

    function balanceOf(address _owner) constant returns(uint balance) {
        return balances[_owner];
    }

    function approve(address _spender, uint _value) returns(bool success) { // ---------------------------- not needed -------------------------------------
        allowed[msg.sender][_spender] = _value;
        Approval(msg.sender, _spender, _value);
        return true;
    }

    function allowance(address _owner, address _spender) constant returns(uint remaining) { //--------- level 0 ------------------------------
        return allowed[_owner][_spender];
    }
}

contract Coin is StandardToken {
    string public name = "ET"; // name of the token
    string public symbol = "ET"; // ERC20 compliant 4 digit token code
    uint public decimals = 18; // token has 18 digit precision
    uint public totalSupply = 60000000000; // total supply of 100+6 Million Tokens
    /// @notice Initializes the contract and allocates all initial tokens to the owner
    function Coin() {
        balances[msg.sender] = totalSupply;
        superOwner = msg.sender;
        /* owners.push(superOwner);
        required++; */
    }
    //////////////// owner only functions below
    /// @notice To transfer token contract ownership
    /// @param _newOwner The address of the new owner of this contract
    function transferOwnership(address _newOwner) onlySuperOwner {
        require(!isOwner(_newOwner));
        balances[_newOwner] = balances[superOwner];
        balances[superOwner] = 0;
        Ownable.transferOwnership(_newOwner);
    }

    function kill() onlySuperOwner {
        selfdestruct(superOwner);
    }
}
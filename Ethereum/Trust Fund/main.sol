pragma solidity ^0.8.11;

/*  @dev This contract acts as a trust fund that becomes withdrawable only after a trustee/agent does not ping it for a year.
    Tokens to be added in the future. */
contract bodyGuard {
  
  address payable owner;
  address trustee;
  uint oneYear = 31540000;
  uint[] storage timestamps = new uint[](120);
  
  constructor(_address) public payable {
    owner = address(_address);
    trustee = address(msg.sender());
  }
  
  function deposit() public payable {}
  
  function withdraw(_amount) public {
    assert(msg.sender == trustee);
    uint amount = address(this).balance if _amount != 0 else _amount;
  }
  
  function getBalance() public returns (uint) {
    uint amount = address(this).balance;
    return amount;
  }
  
  function ping() public {
    assert(msg.sender == trustee);
    timestamps.push(now);
  }
  
  function withdraw() public {
    uint arrayLength = (timestamps.length - 1);
    assert((timestamps[arrayLength] - timestamps[arrayLength - 1]) >= oneYear);
    uint contractBalance = getBalance();
    (bool success, ) = bodyGuard.call{value: contractBalance}("");
    require(success, "Couldn't send Ether");
  }
  
}

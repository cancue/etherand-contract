pragma solidity ^0.5.0;

contract CallForTester {
  /* STORAGE */
  address public owner;

  /* CONSTRUCTOR */
  constructor() public {
    owner = msg.sender;
  }

  /* FUNCTION */
  function setOwner(address _owner) public onlyOwner {
    require(_owner != address(0));
    owner = _owner;
  }

  /* MODIFIER */
  modifier onlyOwner {
    require(msg.sender == owner);
    _;
  }
}

pragma solidity ^0.5.0;

library SafeMath {
  function add(uint256 a, uint256 b) internal pure returns (uint256 c) {
    c = a + b;
    assert(c >= a);
  }
}

contract Committee {
  /* EVENT */
  event SetCommittee(address committee);

  /* STORAGE */
  address public committee;

  /* FUNCTION */
  function setCommittee(address _committee) external onlyCommittee {
    require(_committee != address(0));
    committee = _committee;

    emit SetCommittee(_committee);
  }

  function callFor(address _to, uint256 _gas, bytes calldata _code)
    external
    payable
    onlyCommittee
    returns (bool _result)
  {
    (_result,) = _to.call.value(msg.value).gas(_gas)(_code);
  }

  /* MODIFIER */
  modifier onlyCommittee {
    require(msg.sender == committee);
    _;
  }
}

contract EtherandCustomRequest is Committee {
  using SafeMath for uint256;

  /* TYPE */
  struct Request {
    uint256 id;
    address from;
    uint256 fee;
    uint256 requiredBlockHeight;
    uint256 requiredEntropyHeight;
    uint256 number;
  }

  /* STATE */
  Request[] public requests;
  mapping (address => uint256) public fees;
  uint256 public entropy;
  uint256 public entropyHeight;
  uint256 public blockHeight;

  /* EVENT */
  event RequestEntropy(
    uint256 indexed id,
    address indexed from,
    uint256 fee,
    uint256 blockCount,
    uint256 entropyCount
  );

  event IncreaseEntropy(
    uint256 indexed id,
    address indexed from,
    uint256 number
  );

  /* FUNCTION */
  function requestEntrophy(
    address _from,
    uint256 _blockCount,
    uint256 _entropyCount
  )
    public
    payable
    returns (uint256 _id)
  {
    _id = requests.length;
    uint256 requiredBlockHeight = block.number.add(_blockCount);
    uint256 requiredEntropyHeight = entropyHeight.add(_entropyCount);

    require(
      _id == requests.push(
        Request(
          _id,
          _from,
          msg.value,
          requiredBlockHeight,
          requiredEntropyHeight,
          0
        )
      )
    );

    emit RequestEntropy(
      _id,
      _from,
      msg.value,
      requiredBlockHeight,
      requiredEntropyHeight
    );
  }

  function respondToRequest(uint256 _id, uint256 _number) external {
    Request storage request = requests[_id];
    require(request.from == msg.sender);
    require(_number > 0 && request.number == 0);
    request.number = _number;
    fees[msg.sender] = fees[msg.sender].add(request.fee);
    delete request.fee;

    _increaseEntropy(_number);

    emit IncreaseEntropy(_id, msg.sender, _number);
  }

  function getRequestedEntropy(uint256 _id)
    external
    view
    returns (
      bool _valid,
      uint256 _number,
      uint256 _entropy
    )
  {
    Request memory request = requests[_id];
    _valid = request.number > 0 &&
      request.requiredBlockHeight >= block.number &&
      request.requiredEntropyHeight >= entropyHeight;
    _number = request.number;
    _entropy = entropy;
  }

  function withdraw() external {
    uint256 _ether = fees[msg.sender];
    delete fees[msg.sender];
    msg.sender.transfer(_ether);
  }

  /* INTERNAL FUNCTION */
  function _increaseEntropy(uint256 _number) internal {
    uint256 adder = entropy + _number + uint256(msg.sender);
    if (blockHeight < block.number) {
      adder += uint256(blockhash(block.number - 1));
      blockHeight += 1;
    }
    bytes memory b = new bytes(32);
    assembly { mstore(add(b, 32), adder) }
    entropy = uint256(keccak256(b));
    entropyHeight += 1;
  }
}

contract Etherand is EtherandCustomRequest {
  /* CONSTRUCTOR */
  constructor() public {
    committee = msg.sender;
  }

  /* FUNCTION */
  function getEntropy(uint256 _number) external returns (uint256) {
    increaseEntropy(_number);

    return entropy;
  }

  function getUnsafeEntropy() external view returns (uint256) {
    return entropy + block.timestamp;
  }

  function increaseEntropy(uint256 _number) public {
    _increaseEntropy(_number);
    emit IncreaseEntropy(0, msg.sender, _number);
  }
}

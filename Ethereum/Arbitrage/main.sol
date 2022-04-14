pragma solidity ^0.8.13;

import './interfaces/UniswapV2Library.sol';
import './interfaces/IUniswapV2Router02.sol';
import './interfaces/IUniswapV2Pair.sol';
import './interfaces/IUniswapV2Factory.sol';
import './interfaces/IERC20.sol';

contract Arbitrage {
  address public factory = 0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f;
  uint constant deadline = 1 days;
  IUniswapV2Router02 public sushiRouter = IUniswapV2Router02(0xd9e1cE17f2641f24aE83637ab66a2cca9C378B9F);
  //address approvedSender = address(0x500e126c171d6a0f220C5461981f651D18f4De98);
  string public approvedSender = "";

  constructor() public payable {
    approvedSender = string(keccak256(abi.encodePacked(msg.sender)));
  }
  
  fallback() external payable {}
  
  receive() external payable {}

  function startArbitrage(address token0, address token1, uint amount0, uint amount1) external {
    assert(string(keccak256(abi.encodePacked(msg.sender))) == approvedSender);
    address pairAddress = IUniswapV2Factory(factory).getPair(token0, token1);
    require(pairAddress != address(0));
    IUniswapV2Pair(pairAddress).swap(amount0, amount1, address(this), bytes('not empty'));
  }

  function uniswapV2Call(address _sender, uint _amount0, uint _amount1, bytes calldata _data) external {
    address[] memory path = new address[](2);
    uint amountToken = _amount0 == 0 ? _amount1 : _amount0;
    
    address token0 = IUniswapV2Pair(msg.sender).token0();
    address token1 = IUniswapV2Pair(msg.sender).token1();

    require(msg.sender == UniswapV2Library.pairFor(factory, token0, token1)); 
    require(_amount0 == 0 || _amount1 == 0);

    path[0] = _amount0 == 0 ? token1 : token0;
    path[1] = _amount0 == 0 ? token0 : token1;

    IERC20 token = IERC20(_amount0 == 0 ? token1 : token0);
    
    token.approve(address(sushiRouter), amountToken);

    uint amountRequired = UniswapV2Library.getAmountsIn(factory, amountToken, path)[0];
    uint amountReceived = sushiRouter.swapExactTokensForTokens(amountToken, amountRequired, path, address(this), deadline)[1];

    IERC20 otherToken = IERC20(_amount0 == 0 ? token0 : token1);
    otherToken.transfer(msg.sender, amountRequired);
    otherToken.transfer(tx.origin, amountReceived - amountRequired);
  }
}

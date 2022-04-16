pragma solidity ^0.8.0;

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import "@uniswap/v3-core/contracts/interfaces/IUniswapV3Factory.sol";
import "@uniswap/v3-periphery/contracts/libraries/OracleLibrary.sol";

contract PriceDelta {

    AggregatorV3Interface internal priceOracle;
    
    constructor() {}

    //  @param `_AggAddress` should be the aggregator pair address set by Chainlink.
    //  https://docs.chain.link/docs/ethereum-addresses
    function OffChainPrice(address _AggAddress) internal view returns (int) {
        priceFeed = AggregatorV3Interface(_AggAddress)
        
        ( /*RoundID*/, 
          int price, 
          /*StartedAt*/, 
          /*TimeStamp*/, 
          /*AnsweredInRound*/
        ) = priceOracle.latestRoundData();
        
        return price;
    }
    
    //  @dev Uniswap pair format is _token0/_token1.
    //  @param `_factory` is the factory address of Uniswap.
    //  @param `_token0` is the contract address of the numerator.
    //  @param `_token1` is the contract address of the denominator.
    function OnChainPrice(address _factory, address _token0, address _token1, uint24 _fee) internal view returns (int) {
        address pool = IUniswapV3Factory(_factory).getPool(_token0, _token1, _fee);
        assert(pool != address(0));

        // Code copied from OracleLibrary.sol, consult()
        uint32[] memory secondsAgos = new uint32[](2);
        secondsAgos[0] = secondsAgo;
        secondsAgos[1] = 0;

        (int56[] memory tickCumulatives, ) = IUniswapV3Pool(pool).observe(secondsAgos);

        int56 tickCumulativesDelta = tickCumulatives[1] - tickCumulatives[0];

        int24 tick = int24(tickCumulativesDelta / secondsAgo);

        if (tickCumulativesDelta < 0 && (tickCumulativesDelta % secondsAgo != 0)) {
            tick--;
        }

        amountOut = OracleLibrary.getQuoteAtTick(tick, amountIn, tokenIn, tokenOut);

        return amountOut;
    }

    // @dev Function returns the delta between the off chain price to the on chain price, in respect.
    //  @param `AggAddress` should be the aggregator pair address set by Chainlink.
    //  @param `factory` is the factory address of Uniswap.
    //  @param `token0` is the contract address of the numerator.
    //  @param `token1` is the contract address of the denominator.
    //  https://docs.chain.link/docs/ethereum-addresses
    function PriceDelta(address AggAddress, address factory, address token0, address token1, uint24 fee) public view returns (int) {
        int OffChainPrice = OffChainPrice(AggAddress);
        int OnChainPrice = OnChainPrice(factory, token0, token1, fee);

        int PriceDelta = OffChainPrice - OnChainPrice;

        return PriceDelta;
    }

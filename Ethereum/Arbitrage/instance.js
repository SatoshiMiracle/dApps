//This script is the main bot that monitors arbitrage opportunities and invokes the contract using WEB3.js
//The invokation script and its dependencies are deprecated (commented out)

const sushi = require('./Sushi.js');
//const myContract = require('./txSend.js');

const { ChainId, Token, WETH, Fetcher, Trade, Route, TokenAmount, TradeType } =  require('@uniswap/sdk')

const DAI = new Token(ChainId.MAINNET, '0x6B175474E89094C44Da98b954EedeAC495271d0F', 18)

const main = async () => {
	const pair = await Fetcher.fetchPairData(DAI, WETH[DAI.chainId])

	const route = new Route([pair], WETH[DAI.chainId])
	
	let sushiPairPrice = await sushi.sushiPrice();

	const trade = new Trade(route, new TokenAmount(DAI[DAI.chainId], sushiPairPrice), TradeType.EXACT_INPUT)
	
	let uniPairPrice = trade.executionPrice.toSignificant(6);
	
	let finale = sushiPairPrice / uniPairPrice;
	if (finale >= 1.0075) {
		console.log(sushiPairPrice);
		console.log(uniPairPrice);
		//myContract.callContract();
	}
}

function sleep(ms) {
	return new Promise(resolve => setTimeout(resolve, ms));
}

async function loop() {
	while (true) {
		await sleep(2000)
		main()
	}
}

loop();

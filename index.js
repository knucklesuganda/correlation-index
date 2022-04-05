require("dotenv").config('.env');
const ganache = require("ganache");
const web3 = require('web3');

const options = {
    
};
const server = ganache.server(options);
const PORT = 8545;

server.listen(PORT, async error => {
    if (error) {
        throw error;
    }

    console.log(`Ganache is listening on port ${PORT}`);

    web3.eth.sendTransaction({ from: process.env.ETH_WHALE, to: process.env.METAMASK_ACCOUNT, value: web3.toWei(5, "ether") });

    const index = await BaseIndex.new();
    const token = await IERC20.at(await index.buyTokenAddress());

    await token.transfer(process.env.METAMASK_ACCOUNT, 10000000000, { from: process.env.ETH_WHALE });
});

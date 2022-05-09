const Web3 = require('web3');
const fetch = require('node-fetch');
const yesno = require('yesno');

const chainId = 56;
const web3RpcUrl = 'https://bsc-dataseed.binance.org';
const walletAddress = '0x...xxx';
const privateKey = '0x...xxx';

const swapParams = {
    fromTokenAddress: '0x111111111117dc0aa78b770fa6a738034120c302', // 1INCH
    toTokenAddress: '0x1af3f329e8be154074d8769d1ffa4ee058b1dbc3', // DAI
    amount: '100000000000000000',
    fromAddress: walletAddress,
    slippage: 1,
    disableEstimate: false,
    allowPartialFill: false,
};

const broadcastApiUrl = 'https://tx-gateway.1inch.io/v1.1/' + chainId + '/broadcast';
const apiBaseUrl = 'https://api.1inch.io/v4.0/' + chainId;
const web3 = new Web3(web3RpcUrl);

function apiRequestUrl(methodName, queryParams) {
    return apiBaseUrl + methodName + '?' + (new URLSearchParams(queryParams)).toString();
}

async function broadCastRawTransaction(rawTransaction) {
    return fetch(broadcastApiUrl, {
        method: 'post',
        body: JSON.stringify({ rawTransaction }),
        headers: { 'Content-Type': 'application/json' }
    }).then(res => res.json()).then(res => { return res.transactionHash; });
}

async function signAndSendTransaction(transaction) {
    const { rawTransaction } = await web3.eth.accounts.signTransaction(transaction, privateKey);

    return await broadCastRawTransaction(rawTransaction);
}

async function buildTxForSwap(swapParams) {
    const url = apiRequestUrl('/swap', swapParams);

    return fetch(url).then(res => res.json()).then(res => res.tx);
}

// First, let's build the body of the transaction
const swapTransaction = await buildTxForSwap(swapParams);
console.log('Transaction for swap: ', swapTransaction);

const ok = await yesno({
    question: 'Do you want to send a transaction to exchange with 1inch router?'
});

// Before signing a transaction, make sure that all parameters in it are specified correctly
if (!ok) {
    return false;
}

// Send a transaction and get its hash
const swapTxHash = await signAndSendTransaction(swapTransaction);
console.log('Swap transaction hash: ', swapTxHash);

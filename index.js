const ethers = require('ethers');
const Logger = require("@youpaichris/logger");
const {BigNumber} = require("ethers");
const logger = new Logger();

const PrivateKey = "私钥";
const RPC = "https://rpc.ankr.com/base";

let maxFeePerGas = ethers.utils.parseUnits("1", "gwei");
let maxPriorityFeePerGas = ethers.utils.parseUnits("0.05", "gwei");

if(!RPC) {
    logger.error("RPC URL is required");
    process.exit(1);
}

const provider = new ethers.providers.JsonRpcProvider(RPC);
let nonce = 0
async function claim(privateKey){
    const wallet = new ethers.Wallet(privateKey, provider);
    nonce = await provider.getTransactionCount(wallet.address, "latest");
    logger.info(`wallet address: ${wallet.address} nonce: ${nonce}`);
    const inputData = "0xea5cf63a0000000000000000000000000000000000000000000000000000000000000064"
    while (true){
        try{
            const tx = {
                from: wallet.address,
                nonce: nonce,
                gasLimit: "20000000",
                maxFeePerGas: maxFeePerGas,
                maxPriorityFeePerGas: maxPriorityFeePerGas,
                data: inputData,
                to: "0xcCB7CD311afa45c49eF3C7082D7be86D816fDA76",
                chainId: 8453,
                value: 0,
                type: 2
            };
            const signedTx = await wallet.signTransaction(tx);
            const result = await provider.sendTransaction(signedTx);
            nonce++;
            logger.info(`${wallet.address} 广播交易成功: ${result.hash}`);
            await new Promise((resolve) => setTimeout(resolve, 1000));
        }catch (error) {
            logger.error(`claim error: ${error.reason}`);
        }
    }
}


async function main(){
    try {
        await claim(PrivateKey)
    } catch (error) {
        console.error('Error swap:', error);
    }

}
main().catch(error => {
    logger.error(error);
});
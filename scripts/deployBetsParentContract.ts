import { toNano } from '@ton/core';
import { BetsParentContract } from '../wrappers/BetsParentContract';
import { NetworkProvider } from '@ton/blueprint';

export async function run(provider: NetworkProvider) {

    const description = "USElections";
    const option1Name = "DonaldTrump";
    const option1Pool = BigInt(100);  
    const option2Name = "KamlaHarris";
    const option2Pool = BigInt(200);  
    const betsParentContract = provider.open(await BetsParentContract.fromInit(
        2655n,
        description, 
        option1Name, 
        option1Pool, 
        option2Name, 
        option2Pool
    ));

    await betsParentContract.send(
        provider.sender(),
        {
            value: toNano('0.05'),
        },
        {
            $$type: 'Deploy',
            queryId: 0n,
        }
    );

    await provider.waitForDeploy(betsParentContract.address);
    // run methods on `betsParentContract`
}

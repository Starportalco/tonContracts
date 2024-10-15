import { toNano } from '@ton/core';
import { BetsParentContract } from '../wrappers/BetsParentContract';
import { NetworkProvider } from '@ton/blueprint';

export async function run(provider: NetworkProvider) {
    const betsParentContract = provider.open(await BetsParentContract.fromInit());

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

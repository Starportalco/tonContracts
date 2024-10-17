import { Blockchain, SandboxContract, TreasuryContract } from '@ton/sandbox';
import { toNano } from '@ton/core';
import { BetsParentContract } from '../wrappers/BetsParentContract';
import '@ton/test-utils';

describe('BetsParentContract', () => {
    let blockchain: Blockchain;
    let deployer: SandboxContract<TreasuryContract>;
    let betsParentContract: SandboxContract<BetsParentContract>;

    beforeEach(async () => {
        blockchain = await Blockchain.create();

        const description = "USElections";
        const option1Name = "DonaldTrump";
        const option1Pool = BigInt(100);  
        const option2Name = "KamlaHarris";
        const option2Pool = BigInt(200);  
        betsParentContract = blockchain.openContract(await BetsParentContract.fromInit(
            2432n,
            description, 
            option1Name, 
            option1Pool, 
            option2Name,
            option2Pool
        ));

        deployer = await blockchain.treasury('deployer');

        const deployResult = await betsParentContract.send(
            deployer.getSender(),
            {
                value: toNano('0.05'),
            },
            {
                $$type: 'Deploy',
                queryId: 0n,
            }
        );

        expect(deployResult.transactions).toHaveTransaction({
            from: deployer.address,
            to: betsParentContract.address,
            deploy: true,
            success: true,
        });
    });

    it('checkBalance', async () => {
        const balance = await betsParentContract.getGetEffectivePrice(BigInt(1), BigInt(200));
        console.log(balance);
    });
});

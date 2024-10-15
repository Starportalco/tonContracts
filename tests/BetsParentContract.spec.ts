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

        betsParentContract = blockchain.openContract(await BetsParentContract.fromInit());

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

    it('should deploy', async () => {
        // the check is done inside beforeEach
        // blockchain and betsParentContract are ready to use
    });
});

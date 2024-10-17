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
        
        await betsParentContract.send(
            deployer.getSender(),
            {
                value: toNano("5000"),
            },
            null
        )   
    });

    it('should retrieve the contract balance', async () => {
        const balance = await betsParentContract.getContractBalance();
        console.log(`Contract Balance: ${balance}`);
        expect(balance).toBeTruthy(); 
    });

    it('should calculate effective price correctly', async () => {
        const effectivePrice = await betsParentContract.getEffectivePrice(BigInt(0), BigInt(50));
        console.log(`Effective Price for Option 1: ${effectivePrice}`);
        expect(effectivePrice).toBeGreaterThan(0);
    });

    it('should return user holdings correctly', async () => {
        const userAddress = deployer.address;
        const holdings = await betsParentContract.getUserHoldings(userAddress);
        console.log(`User Holdings for Address ${userAddress}: ${holdings}`);
        expect(holdings).toBe(BigInt(0)); // Initially, user should have 0 holdings
    });

    it('should add options correctly', async () => {
        const initialPrice = BigInt(50);
        const optionName = "NewOption";
    
        const addOptionResult = await betsParentContract.send(deployer.getSender(), {
            value: toNano('0.05'),
        }, {
            $$type: 'AddOption',
            optionName: optionName,
            initialPrice: initialPrice,
        });
    
        expect(addOptionResult.transactions).toHaveTransaction({
            from: deployer.address,
            to: betsParentContract.address,
            success: true,
        });
    
        const betDetails = await betsParentContract.getBetDetails();

        console.log(betDetails.options.get(2n))
    
        const totalPool = betDetails.totalPool;
        console.log(totalPool);
        expect(totalPool).toBeGreaterThan(0);
    });

    it('should retrieve bet details correctly', async () => {
        const betDetails = await betsParentContract.getBetDetails();
        console.log(`Total Pool: ${betDetails.totalPool}`);
    
        expect(betDetails.totalPool).toBeGreaterThan(0);
        // expect(betDetails.options.length).toBe(2n);
    });


    it('should allow buying shares and contract balance should also increase', async () => {
        const betAmount = BigInt(1000); // Example bet amount
        const initialContractBalance = BigInt(await betsParentContract.getContractBalance());
        
        // Send BuyShares message
        await betsParentContract.send(deployer.getSender(), {
            value: toNano(betAmount), 
        }, {
            $$type: 'BuyShares',
            optionIndex: BigInt(0), 
            betAmount: betAmount,
        });
    
        // Retrieve user holdings
        const userHoldings = await betsParentContract.getUserHoldings(deployer.address);
        console.log(userHoldings)
        expect(userHoldings).toBeGreaterThan(0); 
        const contractBalanceAfterBuy = await betsParentContract.getContractBalance();
        console.log(contractBalanceAfterBuy);
        expect(contractBalanceAfterBuy).toBeGreaterThan(initialContractBalance);
    });

});
